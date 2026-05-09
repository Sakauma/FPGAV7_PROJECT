	// `timescale	1ns/1ps
	module	axis_convert_fifo2axs#(
		parameter	DW		=	64		,
		parameter	QW		=	64		
	)(

		input											axsr_info_wr			,
		input		[	64		-	1	:	0	]		axsr_info_di			,
		output											axsr_info_af			,
		output											axsr_info_fu			,
								
		input											axsr_fifo_wl			,
		input											axsr_fifo_wr			,
		input		[	DW		-	1	:	0	]		axsr_fifo_di			,
		output											axsr_fifo_af			,
		output											axsr_fifo_fu			,
	
		input											i_rst					,
		input											i_clk					,
			
		output											axst_tvalid				,
		input											axst_tready				,
		output											axst_tlast				,
		output		[	QW		-	1	:	0	]		axst_tdata				,
		output		[	64		-	1	:	0	]		axst_tuser				,
		output		[	QW/8	-	1	:	0	]		axst_tkeep				,
		output		[	QW/8	-	1	:	0	]		axst_tstrb				,
		output		[	4		-	1	:	0	]		axst_tdest				,
		output		[	4		-	1	:	0	]		axst_tid				,
						
		input											o_rst					,				
		input											o_clk					
	);
		
		wire	clk		=	o_clk	;
		wire	rst		=	i_rst	;
		
		wire					tvalid			;	assign	axst_tvalid	=	tvalid	;
		wire					tready			=	axst_tready					;
		wire					tlast			;	assign	axst_tlast	=	tlast	;
		wire	[QW		-1:0]	tdata			;	assign	axst_tdata	=	tdata	;
		wire	[64		-1:0]	tuser			;	assign	axst_tuser	=	tuser	;
		wire	[QW/8	-1:0]	tkeep			;	assign	axst_tkeep	=	tkeep	;
		wire	[QW/8	-1:0]	tstrb			;	assign	axst_tstrb	= 	tstrb	;
		wire	[4		-1:0]	tdest			;	assign	axst_tdest	= 	tdest	;
		wire	[4		-1:0]	tid				;	assign	axst_tid	= 	tid		;

		assign	tkeep					= 	{(QW/8){1'b1}}					;
		assign	tstrb					= 	{(QW/8){1'b1}}					;
		assign	tdest					= 		0							;
		assign	tid						= 		0							;

		assign	trv		=	tvalid	&&	tready				;
		assign	trvl	=	tvalid	&&	tready	&&	tlast	;
		
		wire											axsr_info_rd			;
		wire		[	64		-	1	:	0	]		axsr_info_do			;
		wire											axsr_info_ae			;
		wire											axsr_info_em			;          
		wire											axsr_fifo_rd			;
		wire		[	QW		-	1	:	0	]		axsr_fifo_do			;
		wire											axsr_fifo_ae			;
		wire											axsr_fifo_em			;
		wire											axsr_fifo_rl			;
		
		localparam	BC	=	QW/32		;	//	double	word count
		localparam	ZW	=	clogb2(BC)	;	//	double	word count
		
		reg		[	64		-	1:0]	axsr_info_do_l		=		{64{1'b1}}				;
		reg		[	16-ZW	-	1:0]	cur_pkg_upsz		=		0						;
	//	wire	[	16-ZW	-	1:0]	cur_pkg_size		=	cur_pkg_upsz				;
		reg		[	16-ZW	-	1:0]	cur_pkg_cunt		=	0							;
		wire							cur_pkg_done										;

		localparam	idle				=	2'b01	;
		localparam	proc				=	2'b10	;
		
		reg	[1:0]	cs	=	idle	,	ns	=	idle	;
		
		wire		cs_idle	=	cs[clogb2(idle)]	;
		wire		cs_proc	=	cs[clogb2(proc)]	;

		always@(posedge	clk)	cs	<=	rst	?	idle	:	ns;
		
		always@(*)	begin
			ns	=	cs		;
			case	(cs)
				idle		:	if(	~	axsr_info_em	)	ns	=	proc		;
				proc		:	if(		trvl			)	ns	=	idle 		;
				default		:								ns	=	idle		;
			endcase
		end

		assign	axsr_info_rd	=	~	axsr_info_em	&&	cs_idle	;
		always@(posedge	clk)	axsr_info_do_l	<=	rst	?	{64{1'b1}}	:	axsr_info_rd	?	axsr_info_do	:	axsr_info_do_l	;
		
		always@(posedge	clk)	begin
			if(rst)	begin
				cur_pkg_upsz	<=	0	;
			end	else	if(	axsr_info_rd	)	begin
				if	(	|axsr_info_do[00+:ZW]	)	cur_pkg_upsz	<=	axsr_info_do[16-01:ZW]	+1	;
				else								cur_pkg_upsz	<=	axsr_info_do[16-01:ZW]		;
			end	else	begin
				cur_pkg_upsz	<=	cur_pkg_upsz	;
			end
		end

		assign	tvalid			=	~	axsr_fifo_em	&&	cs_proc	;
		assign	tlast			=		cur_pkg_done				;
		assign	tdata			=		axsr_fifo_do				;
		assign	tuser			=		axsr_info_do_l				;

		assign	axsr_fifo_rd				=		trv		;
		assign	axsr_fifo_rl				=		trvl	;


		always@(posedge	clk)	begin
			if(rst)	cur_pkg_cunt	<=	0	;
			else	if(	cur_pkg_done	)	cur_pkg_cunt	<=	0						;
		//	else	if(	axsr_fifo_rd	)	cur_pkg_cunt	<=	cur_pkg_cunt	+	BC	;
			else	if(	axsr_fifo_rd	)	cur_pkg_cunt	<=	cur_pkg_cunt	+	1	;
		end
		
	//	assign	cur_pkg_done	=	cur_pkg_cunt	+	BC	>=	cur_pkg_size	&&	axsr_fifo_rd		;
		assign	cur_pkg_done	=	cur_pkg_cunt	+	1	>=	cur_pkg_upsz	&&	axsr_fifo_rd		;
		
		/* synthesis translate_off */
		reg		[	31	:	0]	axst_count_l	;	always@(posedge	clk)	axst_count_l	<=	rst	?	0	:	cur_pkg_done	?	axst_count_l	+	1	:	axst_count_l	;
		assign	axst_count	=	axst_count_l	;
		/* synthesis translate_on */
		
		hdl_eqw_afifo	#(	//	equal	width	async fifo
			.	LOOP_NUM				(	0				)	,
			.	RAM_STYLE				(	"distributed"	)	,
			.	ALMOST_EMPTY_OFFSET		(	'h8				)	,
			.	ALMOST_FULL_OFFSET		(	'h8				)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	5				)	,
			.	DW						(	64				)	
		)axsr_info(
			.	RST					(	rst					)	,	//	input	wire					
			.	WRCLK				(	i_clk				)	,	//	input	wire					
			.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(						)	,	//	output	wire					
			.	WREN				(	axsr_info_wr		)	,	//	input	wire					
			.	DI					(	axsr_info_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	axsr_info_af		)	,	//	output	wire					
			.	FULL				(	axsr_info_fu		)	,	//	output	wire					
			.	RDEN				(	axsr_info_rd		)	,	//	input	wire					
			.	DO					(	axsr_info_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	axsr_info_ae		)	,	//	output	wire					
			.	EMPTY				(	axsr_info_em		)	,	//	output	wire					
			.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(						)	,	//	output	wire					
			.	RDCLK				(	o_clk				)		//	input	wire					
		);
		
		hdl_exw_afifo	#(	//	extended	width	async fifo
			.	LOOP_NUM				(	0				)	,
			.	RAM_STYLE				(	"block"			)	,
			.	ALMOST_EMPTY_OFFSET		(	'h100			)	,
			.	ALMOST_FULL_OFFSET		(	'h100			)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	9				)	,
			.	DW						(	DW				)	,
			.	QW						(	QW				)	
		)axsr_fifo(
			.	RST					(	rst					)	,	//	input	wire					
			.	WRCLK				(	i_clk				)	,	//	input	wire					
			.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(						)	,	//	output	wire					
		//	.	WREN_CLEAR			(	1'b0				)	,	//	input	wire					
			.	WREN_LAST			(	axsr_fifo_wl		)	,	//	input	wire					
			.	WREN				(	axsr_fifo_wr		)	,	//	input	wire					
			.	DI					(	axsr_fifo_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	axsr_fifo_af		)	,	//	output	wire					
			.	FULL				(	axsr_fifo_fu		)	,	//	output	wire					
			.	RDEN				(	axsr_fifo_rd		)	,	//	input	wire					
			.	DO					(	axsr_fifo_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	axsr_fifo_ae		)	,	//	output	wire					
			.	EMPTY				(	axsr_fifo_em		)	,	//	output	wire					
			.	RDEN_LAST			(	axsr_fifo_rl		)	,	//	input	wire					
			.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(						)	,	//	output	wire					
			.	RDCLK				(	o_clk				)		//	input	wire					
		);

		/* synthesis translate_off */ 

			reg	[31:0]	axsr_trvl_cnt	=	0		;	always@(posedge	i_clk)	axsr_trvl_cnt	<=	i_rst	?	0		:	axsr_trvl_cnt	+	axsr_fifo_wl	;
			reg	[31:0]	axsr_trv_cnt	=	0		;	always@(posedge	i_clk)	axsr_trv_cnt	<=	i_rst	?	0		:	axsr_fifo_wl	?	0	:	axsr_trv_cnt	+	axsr_fifo_wr	;
			reg	[31:0]	axsr_rio_type	=	'ha0	;	always@(posedge	i_clk)	axsr_rio_type	<=	i_rst	?	'ha0	:	axsr_trv_cnt==4	&&	axsr_fifo_wr	?	axsr_fifo_di[15:08]	:	axsr_rio_type	;
        
			wire		axsr_type_err	=	(	axsr_rio_type	!=	8'ha0	&&	axsr_rio_type	!=	8'h60	)	;

			reg		[63:0]	fifo_wr_di_64b	=	0	;	always@(posedge	i_clk)	fifo_wr_di_64b	<=		i_rst	?	0	:	axsr_fifo_wr	?	axsr_fifo_di[00+:64]	:	fifo_wr_di_64b;
			wire	axsr_fifo_di_match	=	fifo_wr_di_64b	==	64'h36120000_00000000	;
			
			

			reg	[31:0]	axst_trvl_cnt	=	0		;	always@(posedge	o_clk)	axst_trvl_cnt	<=	o_rst	?	0		:	axst_trvl_cnt	+	(axst_tready	&&	axst_tvalid	&&	axst_tlast)	;
			reg	[31:0]	axst_trv_cnt	=	0		;	always@(posedge	o_clk)	axst_trv_cnt	<=	o_rst	?	0		:	axst_tready	&&	axst_tvalid	&&	axst_tlast	?	0	:	axst_trv_cnt	+	(axst_tready	&&	axst_tvalid)	;
			reg	[31:0]	axst_rio_type	=	'ha0	;	always@(posedge	o_clk)	axst_rio_type	<=	o_rst	?	'ha0	:	axst_trv_cnt==1	&&	axst_tready	&&	axst_tvalid	?	axst_tdata[15:08]	:	axst_rio_type	;

			wire		axst_type_err	=	(	axst_rio_type	!=	8'ha0	&&	axst_rio_type	!=	8'h60	)	;

		/* synthesis translate_on */ 
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