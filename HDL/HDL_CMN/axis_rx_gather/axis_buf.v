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
		output	reg										axst_tvalid		=0		,
		output	reg										axst_tlast		=0		,
		output	reg	[	DW		-	1	:	0	]		axst_tdata		=0		,
		output	reg	[	64		-	1	:	0	]		axst_tuser		=0		,
		output	reg	[	DW/8	-	1	:	0	]		axst_tkeep		=0		,
		output	reg	[	DW/8	-	1	:	0	]		axst_tstrb		=0		,
		output	reg	[	4		-	1	:	0	]		axst_tdest		=0		,
		output	reg	[	4		-	1	:	0	]		axst_tid		=0		,
		output	reg	[	32		-	1	:	0	]		axst_count		=0		,
		
		input											o_rst					,				
		input											o_clk					
	);
	
		wire	rst	=	o_rst	;
		wire	clk	=	o_clk	;
		
	always@(posedge	clk)	axst_tvalid	<=	axsr_tvalid	&&	axsr_tready	?	1			:	axst_tready	&&	axst_tvalid		?	0	:	axst_tvalid	;
	always@(posedge	clk)	axst_tlast	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tlast	:	axst_tready	&&	axst_tvalid		?	0	:	axst_tlast	;
	always@(posedge	clk)	axst_tdata	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tdata	:	axst_tdata		;
	always@(posedge	clk)	axst_tuser	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tuser	:	axst_tuser		;
	always@(posedge	clk)	axst_tkeep	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tkeep	:	axst_tkeep		;
	always@(posedge	clk)	axst_tstrb	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tstrb	:	axst_tstrb		;
	always@(posedge	clk)	axst_tdest	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tdest	:	axst_tdest		;
	always@(posedge	clk)	axst_tid	<=	axsr_tvalid	&&	axsr_tready	?	axsr_tid	:	axst_tid		;
	
	assign	axsr_tready	=	~axst_tvalid	||	axst_tready	;

	always@(posedge	clk)	axst_count	<=	axst_count	+	axst_tvalid	&&	axst_tready	&&	axst_tlast	;

	endmodule
