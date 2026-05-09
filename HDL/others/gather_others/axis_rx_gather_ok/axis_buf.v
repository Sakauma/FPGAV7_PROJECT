	// `timescale	1ns/1ps
	module	axis_buf#(
		parameter	DW			=	64		
	)(
		input											axsr_tvalid				,	//	
		output											axsr_tready				,	//	
		input											axsr_tlast				,	//	
		input		[	DW		-	1	:	0	]		axsr_tdata				,	//	
		input		[	64		-	1	:	0	]		axsr_tuser				,	//	
		input		[	DW/8	-	1	:	0	]		axsr_tkeep				,	//	0
		input		[	DW/8	-	1	:	0	]		axsr_tstrb				,	//	0
		input		[	4		-	1	:	0	]		axsr_tdest				,	//	0
		input		[	4		-	1	:	0	]		axsr_tid				,	//	0
		
		input											i_rst					,
		input											i_clk					,
		
		input											axst_tready				,
		output	reg										axst_tvalid				,
		output	reg										axst_tlast				,
		output	reg	[	DW		-	1	:	0	]		axst_tdata				,
		output	reg	[	64		-	1	:	0	]		axst_tuser				,
		output	reg	[	DW/8	-	1	:	0	]		axst_tkeep				,
		output	reg	[	DW/8	-	1	:	0	]		axst_tstrb				,
		output	reg	[	4		-	1	:	0	]		axst_tdest				,
		output	reg	[	4		-	1	:	0	]		axst_tid				,
		
		input											o_rst					,				
		input											o_clk					
	);
	
		wire											data_fifo_wr			;
		wire		[	DW+1	-	1	:	0	]		data_fifo_di			;
		wire											data_fifo_af			;
		wire											data_fifo_fu			;
		wire											data_fifo_rd			;
		wire		[	DW+1	-	1	:	0	]		data_fifo_do			;
		wire											data_fifo_ae			;
		wire											data_fifo_em			;
		
		wire	rst	=	o_rst	;
		wire	clk	=	o_clk	;
		
	always@(posedge	clk)	axst_tvalid	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tvalid	:	axsr_tvalid		;
	always@(posedge	clk)	axst_tlast	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tlast	:	axsr_tlast		;
	always@(posedge	clk)	axst_tdata	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tdata	:	axsr_tdata		;
	always@(posedge	clk)	axst_tuser	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tuser	:	axsr_tuser		;
	always@(posedge	clk)	axst_tkeep	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tkeep	:	axsr_tkeep		;
	always@(posedge	clk)	axst_tstrb	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tstrb	:	axsr_tstrb		;
	always@(posedge	clk)	axst_tdest	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tdest	:	axsr_tdest		;
	always@(posedge	clk)	axst_tid	<=	rst	?	0	:	axst_tvalid	&&	~axst_tready	?	axst_tid	:	axsr_tid		;
	
	
	assign	axsr_tready	=	axst_tready	;
		
//	assign	axsr_tready		=	~	data_fifo_fu		;
//	
//	assign	data_fifo_wr	=		axsr_tready	&&	axsr_tvalid		;
//	assign	data_fifo_di	=	{	axsr_tlast	,	axsr_tdata	}	;
//
//	
//	assign	axst_tvalid		=	~	data_fifo_em							;
//	assign	data_fifo_rd	=		axst_tready		&&		axst_tvalid		;
//	
//	assign	axst_tdata		=		data_fifo_do[	0	+:	DW		]		;	
//	assign	axst_tlast		=		data_fifo_do[	DW	+:	1		]		;	
//
//
//	assign	axst_tid					= 0									;
//	assign	axst_tdest					= 0									;
//	assign	axst_tkeep					= 0									;
//	assign	axst_tstrb					= 0									;
//	
//	assign	axst_tuser					= 0									;
//
//
//	FIFO_DUALCLOCK_MACRO	#(
//		.DEVICE					(	"7SERIES"	)	,	//	Target	Device:	"7SERIES"	
//		.ALMOST_EMPTY_OFFSET	(	'h040		)	,	//	Sets	the	almost	empty	threshold
//		.ALMOST_FULL_OFFSET		(	'h100		)	,	//	Sets	almost	full	threshold
//		.DATA_WIDTH				(	DW+1		)	,	//	Valid	values	are	1-72	(37-72	only	valid	when	FIFO_SIZE="36Kb")
//		.FIFO_SIZE				(	"36Kb"		)	,	//	Target	BRAM:	"18Kb"	or	"36Kb"	
//		.FIRST_WORD_FALL_THROUGH(	"TRUE"		)		// Sets the FIfor FWFT to "TRUE" or "FALSE"
//	)	datafifo_inst1	(
//		.WRCOUNT				(											),		//	Output	write	count,	width	determined	by	FIFO	depth
//		.WRERR					(											),		//	1-bit	wire	write	error
//		.RST					(	i_rst	||	o_rst						),		//	1-bit	input	reset
//		.WRCLK					(	i_clk									),		//	1-bit	input	clock
//		.WREN					(	data_fifo_wr							),		//	1-bit	input	write	enable
//		.EMPTY					(	data_fifo_em							),		//	1-bit	wire	empty
//		.ALMOSTFULL				(	data_fifo_af							),		//	1-bit	wire	almost	full
//		.FULL					(	data_fifo_fu							),		//	1-bit	wire	full
//		.DI						(	data_fifo_di							),		//	Input	data,	width	defined	by	DATA_WIDTH	parameter
//		.RDEN					(	data_fifo_rd							),		//	1-bit	input	read	enable
//		.DO						(	data_fifo_do							),		//	Output	data,	width	defined	by	DATA_WIDTH	parameter
//		.ALMOSTEMPTY			(	data_fifo_ae							),		//	1-bit	wire	almost	empty
//		.RDCOUNT				(											),		//	Output	read	count,	width	determined	by	FIFO	depth
//		.RDERR					(											),		//	1-bit	wire	read	error
//		.RDCLK					(	o_clk									)		//	1-bit	input	clock
//	);

	endmodule
