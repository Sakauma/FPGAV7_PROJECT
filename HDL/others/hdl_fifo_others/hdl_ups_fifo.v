
	module	hdl_ups_fifo	#(
		parameter	LOOP_NUM				= 	0			,
		parameter	DEVICE					= 	"7SERIES"	,
		parameter	ALMOST_EMPTY_OFFSET		=	256			,
		parameter	ALMOST_FULL_OFFSET		=	256			,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
		parameter	AW						=	9			,
		parameter	DW						=	16			,
		parameter	QW						=	DW			
	)(
		input								WREN			,
		input			[DW	-1:0]			DI				,
		output								ALMOSTFULL		,
		output								FULL			,

		input								WREN_LAST		,
		output			[AW-1:0]			WRCOUNT			,
		output								WRERR			,

		input								RDEN			,
		output			[QW	-1:0]			DO				,
		output								ALMOSTEMPTY		,
		output								EMPTY			,
		output			[AW-1:0]			RDCOUNT			,
		output								RDERR			,

		input								RST				,
		input								CLK				
	);

	wire							buf_wr			;
	wire	[QW	-1:0]				buf_di			;
	wire							buf_af			;	//	[FIFO_NUM	-1:0]
	wire							buf_fu			;	//	[FIFO_NUM	-1:0]
	wire							buf_ae			;	//	[FIFO_NUM	-1:0]
	wire							buf_em			;	//	[FIFO_NUM	-1:0]

	// reg		[QW-1:0]		buf_di_reg	=0	;
	// reg		[QW-DW-1:0]		buf_di_l	=0	;

	assign					ALMOSTFULL	=	buf_af	;		//	buf_af[0]	;
	assign					FULL		=	buf_fu	;		//	buf_af[0]	;	//	buf_fu[0]	;
	assign					ALMOSTEMPTY	=	buf_ae	;		//	buf_ae[0]	;
	assign					EMPTY		=	buf_em	;		//	buf_em[0]	;

	wire	dw_align	;

	reg	[clogb2(QW/DW)-1:0]	wr_cnt	;
	always@(posedge	CLK)	begin
		if(RST)	begin
			wr_cnt	<=	0	;
		end	else	if(buf_wr)begin
			wr_cnt	<=	0	;
		end	else	begin
			wr_cnt	<=	WREN	&&	!FULL	?	wr_cnt	+	1	:	wr_cnt	;	//buf_wr	?	0:
		end
	end

	assign	dw_align	=	wr_cnt	==	QW/DW	-1	;

	assign	buf_wr	=	(dw_align	||	WREN_LAST	)	&&	WREN	&&	!FULL;

	reg		[	QW	-	1	:	0	]	buf_di_reg	=	0	;	always@(posedge	CLK)	buf_di_reg	<=	buf_wr	?	0	:	buf_di	;

	genvar k;
	generate	for ( k=0; k<QW/DW; k=k+1 ) begin: dw_convert
		
		assign	buf_di[	k	*	DW	+:	DW	]	=	wr_cnt	==	k	?	DI	:	buf_di_reg[	k	*	DW	+:	DW	]	;
			
	end	endgenerate

	localparam	RAM_STYLE	=	DEVICE == "DRAM"	?	"distributed"	:	"block"	;

	wire	 [COUNT_WIDTH:0] cnt_used;	assign	WRCOUNT	=cnt_used[COUNT_WIDTH-1:0]	;
	wire	 [COUNT_WIDTH:0] cnt_free;	assign	RDCOUNT	=cnt_free[COUNT_WIDTH-1:0]	;
	
	hdl_sfifo_top #(
		.	RAM_STYLE  	(	RAM_STYLE					)	,	//	Specify RAM style: auto/block/distributed
		.	FWFT       	(	FIRST_WORD_FALL_THROUGH		)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
		.	DWID       	(	QW							)	,
		.	AWID       	(	AW							)	, 
		.	AFULL_TH   	(	ALMOST_FULL_OFFSET			)	, 
		.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET 		)	, 
		.	DBG_WID    	(	32							)		
	)hdl_sfifo_top(
		.	clk			(	CLK				)	,   	// input						write clock
		.	rst			(	RST				)	,   	// input						write reset
		.	wen			(	buf_wr			)	,   	// input						Write enable
		.	wdata		(	buf_di			)	,   	// input		[DWID-1:0]		RAM input data
		.	afull		(	buf_af			)	,   	// output						
		.	full		(	buf_fu			)	,   	// output						
		.	nafull		(					)	,   	// output						
		.	nfull		(					)	,   	// output						
		.	cnt_used	(	cnt_used		)	,   	// output		[AWID:0]		the counter used in fifo for write clock domain
		.	woverflow	(	WRERR			)	,   	// output						
		.	ren			(	RDEN			)	,   	// input						Read Enable
		.	rdata		(	DO				)	,   	// output		[DWID-1:0]		RAM output data
		.	aempty		(	buf_ae			)	,   	// output						
		.	empty		(	buf_em			)	,   	// output						
		.	naempty		(					)	,   	// output						
		.	nempty		(					)	,   	// output						
		.	cnt_free	(	cnt_free		)	,   	// output		[AWID:0]		the counter used in fifo for read clock domain 
		.	roverflow	(	RDERR			)	,   	// output						
		.	dbg_sig		(					)			// output		[DBG_WID-1:0]	debug signal
	);
	

//  The following function calculates the address width based on specified RAM depth
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
/*
if	(LOOP_NUM	==	0	)	generate
vio_2	vio_2_inst(
.clk	(CLK)	,
.probe_in0	(
			{
				buf_af			,
				buf_fu			,
				buf_ae			,
				buf_em			,
				wr_cnt			,
				ALMOSTFULL		,
				FULL			,
				WREN_LAST		,
				RDEN			,
				ALMOSTEMPTY		,
				EMPTY			
			}
		)
);
endgenerate
*/

endmodule	
