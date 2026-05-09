
// `timescale	1ns/1ps
module	axis_convert_axs2fifo#(
	parameter	DW			=	64		
)(

	input											axsr_tvalid				,
	output											axsr_tready				,
	input											axsr_tlast				,
	input		[	DW		-	1	:	0	]		axsr_tdata				,
	input		[	64		-	1	:	0	]		axsr_tuser				,
	input		[	DW/8	-	1	:	0	]		axsr_tkeep				,
	input		[	DW/8	-	1	:	0	]		axsr_tstrb				,
	input		[	4		-	1	:	0	]		axsr_tdest				,
	input		[	4		-	1	:	0	]		axsr_tid				,
		
	output											axsr_info_wr			,
	output		[	64		-	1	:	0	]		axsr_info_di			,
	input											axsr_info_af			,
	input											axsr_info_fu			,
		
	output											axsr_fifo_wl			,
	output											axsr_fifo_wr			,
	output		[	DW		-	1	:	0	]		axsr_fifo_di			,
	input											axsr_fifo_af			,
	input											axsr_fifo_fu			,
	
	input											rst						,
	input											clk								
);
	
	localparam	BC	=	DW/32	;	//	//	double	word count	in BUS

	wire	tvalid		;	assign	tvalid					=	axsr_tvalid	;
	wire	tready		;	assign	axsr_tready				=	tready		;
	wire	tlast		;	assign	tlast					=	axsr_tlast	;

	wire	[DW-1:0]		tdata	;	assign	tdata	=	axsr_tdata		;
	wire	[DW/8-1:0]		tkeep	;	assign	tkeep	=	axsr_tkeep		;
	wire	[64-1:0]		tuser	;	assign	tuser	=	axsr_tuser		;

	wire	trv			=	tready			&&	tvalid				;
	wire	trvl		=	tready			&&	tvalid	&&	tlast	;

	reg		sof_idle	=	1	;
	always@(posedge	clk)	sof_idle	<=	rst	||	trvl	?	1'b1	:	trv	?	0	:	sof_idle	;
	

	reg		[64-1:0]	tuser_l	=0	;	always@(posedge	clk)	tuser_l	<=	sof_idle	?	tuser	:	tuser_l	;

	assign	axsr_info_wr	=	trvl	;
	assign	axsr_info_di	=	sof_idle	?	tuser	:	tuser_l	;

	assign	axsr_fifo_wl	=	trvl	;
	assign	axsr_fifo_wr	=	trv		;
	assign	axsr_fifo_di	=	tdata	;
	
	assign	tready	=	~	axsr_info_fu	&&	~	axsr_fifo_fu	;
		
endmodule
