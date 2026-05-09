	`timescale	1ns/1ps
	module	axis_rx_gather_top#(
		parameter	DW			=	64		,
		parameter	QW			=	64		
	)(

		input		[	31				:	0	]		dma_size_set			,
		input		[	31				:	0	]		dma_wait_set			,
		input											axsr_tvalid				,
		output											axsr_tready				,
		input											axsr_tlast				,
		input		[	DW		-	1	:	0	]		axsr_tdata				,
		input		[	64		-	1	:	0	]		axsr_tuser				,
		input		[	DW/8	-	1	:	0	]		axsr_tkeep				,
		input		[	DW/8	-	1	:	0	]		axsr_tstrb				,
		input		[	4		-	1	:	0	]		axsr_tdest				,
		input		[	4		-	1	:	0	]		axsr_tid				,
		
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
		output		[	32		-	1	:	0	]		axst_count				,
		
		input											o_rst					,				
		input											o_clk					
	);

		wire											axsr_info_wr			;
		wire		[	64		-	1	:	0	]		axsr_info_di			;
		wire											axsr_info_af			;
		wire											axsr_info_fu			;
			
		wire											axsr_fifo_wr			;
		wire		[	DW		-	1	:	0	]		axsr_fifo_di			;
		wire											axsr_fifo_af			;
		wire											axsr_fifo_fu			;
		
		wire		[	DW		-	1	:	0	]		ibuf_tdata				;
		wire		[	4		-	1	:	0	]		ibuf_tid				;
		wire											ibuf_tready				;
		wire											ibuf_tvalid				;
		wire		[	DW/8	-	1	:	0	]		ibuf_tstrb				;
		wire		[	DW/8	-	1	:	0	]		ibuf_tkeep				;
		wire											ibuf_tlast				;
		wire		[	64		-	1	:	0	]		ibuf_tuser				;
		wire		[	4		-	1	:	0	]		ibuf_tdest				;

		wire		[	DW		-	1	:	0	]		obuf_tdata				;
		wire		[	4		-	1	:	0	]		obuf_tid				;
		wire											obuf_tready			    ;
		wire											obuf_tvalid			    ;
		wire		[	DW/8	-	1	:	0	]		obuf_tstrb			    ;
		wire		[	DW/8	-	1	:	0	]		obuf_tkeep			    ;
		wire											obuf_tlast			    ;
		wire		[	64		-	1	:	0	]		obuf_tuser			    ;
		wire		[	4		-	1	:	0	]		obuf_tdest			    ;

	axis_buf#(
		.	DW	(		DW	)	
	)i_axis_buf_i(
		.	axsr_tdata			(	axsr_tdata			)			,	//	input		[	63				:	0	]		
		.	axsr_tid			(	axsr_tid			)			,	//	input		[	3				:	0	]		
		.	axsr_tready			(	axsr_tready			)			,	//	output											
		.	axsr_tvalid			(	axsr_tvalid			)			,	//	input											
		.	axsr_tstrb			(	axsr_tstrb			)			,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	axsr_tkeep			)			,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	axsr_tlast			)			,	//	input											
		.	axsr_tuser			(	axsr_tuser			)			,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	axsr_tdest			)			,	//	input		[	3				:	0	]		
		.	i_rst				(	i_rst				)			,	//	input											
		.	i_clk				(	i_clk				)			,	//	input											
		.	axst_tdata			(	ibuf_tdata			)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	ibuf_tid			)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	ibuf_tready			)			,	//	input											
		.	axst_tvalid			(	ibuf_tvalid			)			,	//	output											
		.	axst_tstrb			(	ibuf_tstrb			)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	ibuf_tkeep			)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	ibuf_tlast			)			,	//	output											
		.	axst_tuser			(	ibuf_tuser			)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tdest			(	ibuf_tdest			)			,	//	output		[	4		-	1	:	0	]		
		.	o_rst				(	i_rst				)			,	//	input											
		.	o_clk				(	i_clk				)			 	//	input											
	);


	axis_rx_gather_axs2fifo#(
		.	DW		(	DW	)	
	)axis_rx_gather_axs2fifo(
		.	dma_size_set		(	dma_size_set		)	,	//	input		[	31				:	0	]		
		.	dma_wait_set		(	dma_wait_set		)	,	//	input		[	31				:	0	]		
		.	axsr_tdata			(	ibuf_tdata			)	,	//	input		[	63				:	0	]		
		.	axsr_tid			(	ibuf_tid			)	,	//	input		[	3				:	0	]		
		.	axsr_tready			(	ibuf_tready			)	,	//	output											
		.	axsr_tvalid			(	ibuf_tvalid			)	,	//	input											
		.	axsr_tstrb			(	ibuf_tstrb			)	,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	ibuf_tkeep			)	,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	ibuf_tlast			)	,	//	input											
		.	axsr_tuser			(	ibuf_tuser			)	,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	ibuf_tdest			)	,	//	input		[	3				:	0	]		
		.	axsr_info_wr		(	axsr_info_wr		)	,   //	output											
		.	axsr_info_di		(	axsr_info_di		)	,   //	output		[	32		-	1	:	0	]		
		.	axsr_info_af		(	axsr_info_af		)	,   //	input											
		.	axsr_info_fu		(	axsr_info_fu		)	,   //	input											
		.	axsr_fifo_wr		(	axsr_fifo_wr		)	,   //	output											
		.	axsr_fifo_di		(	axsr_fifo_di		)	,   //	output		[	DW		-	1	:	0	]		
		.	axsr_fifo_af		(	axsr_fifo_af		)	,   //	input											
		.	axsr_fifo_fu		(	axsr_fifo_fu		)	,   //	input											
		.	rst					(	i_rst				)	,   //	input											
		.	clk					(	i_clk				)		//	input											
	);

	axis_rx_gather_fifo2axs#(
		.	DW	(		DW	)	,
		.	QW	(		QW	)	
	)axis_rx_gather_fifo2axs(
		.	axsr_info_wr		(	axsr_info_wr		)			,	//	input										
		.	axsr_info_di		(	axsr_info_di		)			,	//	input		[	32		-	1	:	0	]	
		.	axsr_info_af		(	axsr_info_af		)			,	//	output										
		.	axsr_info_fu		(	axsr_info_fu		)			,	//	output												
		.	axsr_fifo_wr		(	axsr_fifo_wr		)			,	//	input										
		.	axsr_fifo_di		(	axsr_fifo_di		)			,	//	input		[	DW		-	1	:	0	]	
		.	axsr_fifo_af		(	axsr_fifo_af		)			,	//	output										
		.	axsr_fifo_fu		(	axsr_fifo_fu		)			,	//	output										
		.	i_rst				(	i_rst				)			,	//	input										
		.	i_clk				(	i_clk				)			,	//	input										
		.	axst_tdata			(	obuf_tdata			)			,	//	output		[	QW		-	1	:	0	]	
		.	axst_tid			(	obuf_tid			)			,	//	output		[	4		-	1	:	0	]	
		.	axst_tready			(	obuf_tready			)			,	//	input										
		.	axst_tvalid			(	obuf_tvalid			)			,	//	output										
		.	axst_tstrb			(	obuf_tstrb			)			,	//	output		[	QW/8	-	1	:	0	]	
		.	axst_tkeep			(	obuf_tkeep			)			,	//	output		[	QW/8	-	1	:	0	]	
		.	axst_tlast			(	obuf_tlast			)			,	//	output										
		.	axst_tuser			(	obuf_tuser			)			,	//	output		[	QW		-	1	:	0	]	
		.	axst_tdest			(	obuf_tdest			)			,	//	output		[	4		-	1	:	0	]	
		.	axst_count			(						)			,	//	output		[	4		-	1	:	0	]	
		.	o_rst				(	o_rst				)			,	//	input												
		.	o_clk				(	o_clk				)				//	input										
	);

	axis_buf#(
		.	DW	(		DW	)	
	)o_axis_buf_i(
		.	axsr_tdata			(	obuf_tdata			)			,	//	input		[	63				:	0	]		
		.	axsr_tid			(	obuf_tid			)			,	//	input		[	3				:	0	]		
		.	axsr_tready			(	obuf_tready			)			,	//	output											
		.	axsr_tvalid			(	obuf_tvalid			)			,	//	input											
		.	axsr_tstrb			(	obuf_tstrb			)			,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	obuf_tkeep			)			,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	obuf_tlast			)			,	//	input											
		.	axsr_tuser			(	obuf_tuser			)			,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	obuf_tdest			)			,	//	input		[	3				:	0	]		
		.	i_rst				(	o_rst				)			,	//	input											
		.	i_clk				(	o_clk				)			,	//	input											
		.	axst_tdata			(	axst_tdata			)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	axst_tid			)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	axst_tready			)			,	//	input											
		.	axst_tvalid			(	axst_tvalid			)			,	//	output											
		.	axst_tstrb			(	axst_tstrb			)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	axst_tkeep			)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	axst_tlast			)			,	//	output											
		.	axst_tuser			(	axst_tuser			)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tdest			(	axst_tdest			)			,	//	output		[	4		-	1	:	0	]		
		.	axst_count			(	axst_count			)			,	//	output		[	32		-	1	:	0	]		
		.	o_rst				(	o_rst				)			,	//	input											
		.	o_clk				(	o_clk				)			 	//	input											
	);
		/* synthesis translate_off */ 

			reg	[31:0]	ibuf_trvl_cnt	=	0		;	always@(posedge	o_clk)	ibuf_trvl_cnt	<=	o_rst	?	0		:	ibuf_trvl_cnt	+	(ibuf_tready	&&	ibuf_tvalid	&&	ibuf_tlast)	;
			reg	[31:0]	ibuf_trv_cnt	=	0		;	always@(posedge	o_clk)	ibuf_trv_cnt	<=	o_rst	?	0		:	ibuf_tready	&&	ibuf_tvalid	&&	ibuf_tlast	?	0	:	ibuf_trv_cnt	+	(ibuf_tready	&&	ibuf_tvalid)	;
			reg	[31:0]	ibuf_rio_type	=	'ha0	;	always@(posedge	o_clk)	ibuf_rio_type	<=	o_rst	?	'ha0	:	ibuf_trv_cnt==4	&&	ibuf_tready	&&	ibuf_tvalid	?	ibuf_tdata[15:08]	:	ibuf_rio_type	;

			wire		ibuf_type_err	=	(	ibuf_rio_type	!=	8'ha0	&&	ibuf_rio_type	!=	8'h60	)	;

			reg	[31:0]	obuf_trvl_cnt	=	0		;	always@(posedge	o_clk)	obuf_trvl_cnt	<=	o_rst	?	0		:	obuf_trvl_cnt	+	(obuf_tready	&&	obuf_tvalid	&&	obuf_tlast)	;
			reg	[31:0]	obuf_trv_cnt	=	0		;	always@(posedge	o_clk)	obuf_trv_cnt	<=	o_rst	?	0		:	obuf_tready	&&	obuf_tvalid	&&	obuf_tlast	?	0	:	obuf_trv_cnt	+	(obuf_tready	&&	obuf_tvalid)	;
			reg	[31:0]	obuf_rio_type	=	'ha0	;	always@(posedge	o_clk)	obuf_rio_type	<=	o_rst	?	'ha0	:	obuf_trv_cnt==4	&&	obuf_tready	&&	obuf_tvalid	?	obuf_tdata[15:08]	:	obuf_rio_type	;

			wire		obuf_type_err	=	(	obuf_rio_type	!=	8'ha0	&&	obuf_rio_type	!=	8'h60	)	;

		/* synthesis translate_on */ 

	endmodule

