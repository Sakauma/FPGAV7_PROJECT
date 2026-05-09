
`timescale	1ns/1ps
module	fifo_wr_comb	#(
	parameter	BS			=	0		,
	parameter	DW			=	64		,
	parameter	SW			=	24		,
	parameter	IW			=	4		,
	parameter	CH			=	10		
)(
	
	input			[CH-1:0]			iso_info_wr					,
	input			[CH*32-1:0]			iso_info_di					,
	output			[CH-1:0]			iso_info_af					,
	output			[CH-1:0]			iso_info_fu					,
	input			[CH-1:0]			iso_fifo_wr					,
	input			[CH*DW-1:0]			iso_fifo_di					,
	output			[CH-1:0]			iso_fifo_af					,	
	output			[CH-1:0]			iso_fifo_fu					,

	output								com_info_wr					,
	output			[32-1:0]			com_info_di					,
	input								com_info_af					,
	input								com_info_fu					,
	output								com_fifo_wr					,
	output			[DW	-1:0]			com_fifo_di					,
	input								com_fifo_af					,
	input								com_fifo_fu					,
	input			[CH-1:0]			iso_rst						,
	input			[CH-1:0]			iso_clk						,
	input								com_rst						,
	input								com_clk						
);

wire	rst	=	com_rst		;
wire	clk	=	com_clk		;

	wire		[CH-1:0]				iso_info_rd					;
	wire		[CH*32	-1:0]			iso_info_do					;
	wire		[CH-1:0]				iso_info_ae					;
	wire		[CH-1:0]				iso_info_em					;
	wire		[CH-1:0]				iso_fifo_rd					;
	wire		[CH*DW-1:0]				iso_fifo_do					;
	wire		[CH-1:0]				iso_fifo_ae					;
	wire		[CH-1:0]				iso_fifo_em					;

reg	[clogb2(CH)-1:0]	ch_num	=	0	;
reg	[CH-1:0]			ch_mrk	=	0	;
	
	wire	all_fifo_ready		=	~&iso_info_em	&&	~com_info_fu	;
	
localparam	idle				=	0					;
localparam	GET_PKG_INFO		=	idle			+1	;
localparam	GET_PKG_DATA		=	GET_PKG_INFO	+1	;

	reg		[CH*SW	-1:0]		cur_pkg_size	;
	reg		[CH*SW	-1:0]		cur_pkg_byte	;
	wire	[CH-1:0]			cur_pkg_done	;

	
	reg	[1:0]	cs	,ns	;

	always@(posedge	clk)	begin
		if(rst)	cs	<=	0;
		else	cs	<=	ns	;
	end
	
	always@(*)	begin
		if(rst)	begin
			ns	=	0;
		end	else	begin
			ns	=	cs	;
			case	(cs)
				idle				:	if(all_fifo_ready)	ns	=	GET_PKG_INFO		;
				GET_PKG_INFO		:						ns	=	GET_PKG_DATA		;
				GET_PKG_DATA		:	if(cur_pkg_done)	ns	=	idle 				;
				default				:						ns	=	idle				;
			endcase
		end
	end

integer k;
always @ ( posedge clk ) begin
    if ( rst ) begin
		ch_num = 0;
        ch_mrk = 0;
    end	else if ( cs==	idle	&&	all_fifo_ready	) begin
        for ( k=0; k<CH; k=k+1 ) begin
            ch_num	=	~iso_info_em[k]	?	k		: ch_num	;
			ch_mrk	=	~iso_info_em[k]	?	1<<k	: ch_mrk	;	
        end
    end
end

// wire	[IW/2-1:0]	IP_ID	=	ch_num	>=	CH/2	?	1	:	0	;
// wire	[IW/2-1:0]	CH_ID	=	ch_num	>=	CH/2	?	ch_num-5	:	ch_num	;
wire	[IW-1:0]	CH_ID	=	ch_num	+	BS	;

genvar i;
generate
	for ( i=0; i<CH; i=i+1 ) begin: multi_signal_gen
	
	assign	iso_info_rd[i]	=	cur_pkg_done[i]		;
	
	assign	cur_pkg_done[i]		=	cur_pkg_byte[i*SW	+:SW	]+	DW/8	>=	cur_pkg_size[i*SW	+:SW	]	&&	iso_fifo_rd[i]	&&	ch_mrk[i]	;
	
	always@(posedge	clk)	begin
		if(rst)	cur_pkg_size[i*SW	+:SW	]	<=	0	;
		else	if(cs	==	idle)	cur_pkg_size[i*SW	+:SW	]	<=	iso_info_do[i*32	+:SW	]	;
	end

	always@(posedge	clk)	begin
		if(rst)	begin
			cur_pkg_byte[i*SW	+:SW	]	<=	0	;
		end	else	if(cur_pkg_done[i])	begin
			cur_pkg_byte[i*SW	+:SW	]	<=	0	;
		end	else	if(iso_fifo_rd[i])	begin
			cur_pkg_byte[i*SW	+:SW	]	<=	cur_pkg_byte[i*SW	+:SW	]	+	(DW/8)	;
		end
	end
	
	assign	iso_fifo_rd[i]	=	cs	==	GET_PKG_DATA	&&	~iso_fifo_em[i]	&&	~com_fifo_fu	&&	ch_mrk[i]	;

FIFO_DUALCLOCK_MACRO	#(
	.DEVICE					(	"7SERIES"	),		//	Target	Device:	"7SERIES"	
	.ALMOST_EMPTY_OFFSET	(	9'h100		),		//	Sets	the	almost	empty	threshold
	.ALMOST_FULL_OFFSET		(	9'h100		),		//	Sets	almost	full	threshold
	.DATA_WIDTH				(	32			),		//	Valid	values	are	1-72	(37-72	only	valid	when	FIFO_SIZE="36Kb")
	.FIFO_SIZE				(	"18Kb"		),		//	Target	BRAM:	"18Kb"	or	"36Kb"	
	.FIRST_WORD_FALL_THROUGH(	"TRUE"		)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
)	iso_info_inst	(
	.ALMOSTEMPTY			(	iso_info_ae[i]			),		//	1-bit	wire	almost	empty
	.ALMOSTFULL				(	iso_info_af[i]			),		//	1-bit	wire	almost	full
	.DO						(	iso_info_do[i*32+:32]	),		//	Output	data,	width	defined	by	DATA_WIDTH	parameter
	.EMPTY					(	iso_info_em[i]			),		//	1-bit	wire	empty
	.FULL					(	iso_info_fu[i]			),		//	1-bit	wire	full
	.RDCOUNT				(							),		//	Output	read	count,	width	determined	by	FIFO	depth
	.RDERR					(							),		//	1-bit	wire	read	error
	.WRCOUNT				(							),		//	Output	write	count,	width	determined	by	FIFO	depth
	.WRERR					(							),		//	1-bit	wire	write	error
	.RDCLK					(	clk						),		//	1-bit	input	clock
	.WRCLK					(	iso_clk[i]				),		//	1-bit	input	clock
	.DI						(	iso_info_di[i*32+:32]	),		//	Input	data,	width	defined	by	DATA_WIDTH	parameter
	.RDEN					(	iso_info_rd[i]			),		//	1-bit	input	read	enable
	.RST					(	rst						),		//	1-bit	input	reset
	.WREN					(	iso_info_wr[i]			)		//	1-bit	input	write	enable
);

FIFO_DUALCLOCK_MACRO	#(
	.DEVICE					(	"7SERIES"	),		//	Target	Device:	"7SERIES"	
	.ALMOST_EMPTY_OFFSET	(	9'h100		),		//	Sets	the	almost	empty	threshold
	.ALMOST_FULL_OFFSET		(	'h100		),		//	Sets	almost	full	threshold
	.DATA_WIDTH				(	DW			),		//	Valid	values	are	1-72	(37-72	only	valid	when	FIFO_SIZE="36Kb")
	.FIFO_SIZE				(	"36Kb"		),		//	Target	BRAM:	"18Kb"	or	"36Kb"	
	.FIRST_WORD_FALL_THROUGH(	"TRUE"		)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
)	iso_fifo_inst_L	(
	.ALMOSTEMPTY			(	iso_fifo_ae[i]			),		//	1-bit	wire	almost	empty
	.ALMOSTFULL				(	iso_fifo_af[i]			),		//	1-bit	wire	almost	full
	.DO						(	iso_fifo_do[i*DW+:DW]	),		//	Output	data,	width	defined	by	DATA_WIDTH	parameter
	.EMPTY					(	iso_fifo_em[i]			),		//	1-bit	wire	empty
	.FULL					(	iso_fifo_fu[i]			),		//	1-bit	wire	full
	.RDCOUNT				(							),		//	Output	read	count,	width	determined	by	FIFO	depth
	.RDERR					(							),		//	1-bit	wire	read	error
	.WRCOUNT				(							),		//	Output	write	count,	width	determined	by	FIFO	depth
	.WRERR					(							),		//	1-bit	wire	write	error
	.RDCLK					(	clk						),		//	1-bit	input	clock
	.WRCLK					(	iso_clk[i]				),		//	1-bit	input	clock
	.DI						(	iso_fifo_di[i*DW+:DW]	),		//	Input	data,	width	defined	by	DATA_WIDTH	parameter
	.RDEN					(	iso_fifo_rd[i]			),		//	1-bit	input	read	enable
	.RST					(	rst						),		//	1-bit	input	reset
	.WREN					(	iso_fifo_wr[i]			)		//	1-bit	input	write	enable
);
	
end		// end of for generate
endgenerate


	assign	com_fifo_wr	=	iso_fifo_rd[ch_num]		;
	assign	com_fifo_di	=	iso_fifo_do[ch_num*DW+:DW]	;
	
	assign	com_info_wr	=	iso_info_rd[ch_num]		;
	// assign	com_info_di	=	{IP_ID,CH_ID,iso_info_do[ch_num*SW	+:SW	]}	;
	assign	com_info_di	=	{CH_ID,iso_info_do[ch_num*32	+:SW	]}	;

function integer clogb2;
  input integer depth;
  integer depth_reg;
	begin
        depth_reg = depth;
        for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
          depth_reg = depth_reg >> 1;
        end
        if( 2**clogb2 >= depth*2 )begin
          clogb2 = clogb2 - 1;
        end
	end 
endfunction
endmodule
