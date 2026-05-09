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
		
		wire		[	DW		-	1	:	0	]		af_fifo_tdata				;
		wire		[	4		-	1	:	0	]		af_fifo_tid					;
		wire											af_fifo_tready				;
		wire											af_fifo_tvalid				;
		wire		[	DW/8	-	1	:	0	]		af_fifo_tstrb				;
		wire		[	DW/8	-	1	:	0	]		af_fifo_tkeep				;
		wire											af_fifo_tlast				;
		wire		[	DW		-	1	:	0	]		af_fifo_tuser				;
		wire		[	4		-	1	:	0	]		af_fifo_tdest				;


	axis_buf#(
		.	DW	(		DW	)	
	)axis_buf(
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
		.	axst_tdata			(	af_fifo_tdata		)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	af_fifo_tid			)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	af_fifo_tready		)			,	//	input											
		.	axst_tvalid			(	af_fifo_tvalid		)			,	//	output											
		.	axst_tstrb			(	af_fifo_tstrb		)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	af_fifo_tkeep		)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	af_fifo_tlast		)			,	//	output											
		.	axst_tuser			(	af_fifo_tuser		)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tdest			(	af_fifo_tdest		)			,	//	output		[	4		-	1	:	0	]		
		.	o_rst				(	i_rst				)			,	//	input											
		.	o_clk				(	i_clk				)			 	//	input											
	);


	axis_rx_gather_axs2fifo#(
		.	DW		(	DW	)	
	)axis_rx_gather_axs2fifo(
		.	dma_size_set		(	dma_size_set		)	,	//	input		[	31				:	0	]		
		.	dma_wait_set		(	dma_wait_set		)	,	//	input		[	31				:	0	]		
		.	axsr_tdata			(	af_fifo_tdata		)	,	//	input		[	63				:	0	]		
		.	axsr_tid			(	af_fifo_tid			)	,	//	input		[	3				:	0	]		
		.	axsr_tready			(	af_fifo_tready		)	,	//	output											
		.	axsr_tvalid			(	af_fifo_tvalid		)	,	//	input											
		.	axsr_tstrb			(	af_fifo_tstrb		)	,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	af_fifo_tkeep		)	,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	af_fifo_tlast		)	,	//	input											
		.	axsr_tuser			(	af_fifo_tuser		)	,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	af_fifo_tdest		)	,	//	input		[	3				:	0	]		
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
		.	axst_tdata			(	axst_tdata			)			,	//	output		[	QW		-	1	:	0	]	
		.	axst_tid			(	axst_tid			)			,	//	output		[	4		-	1	:	0	]	
		.	axst_tready			(	axst_tready			)			,	//	input										
		.	axst_tvalid			(	axst_tvalid			)			,	//	output										
		.	axst_tstrb			(	axst_tstrb			)			,	//	output		[	QW/8	-	1	:	0	]	
		.	axst_tkeep			(	axst_tkeep			)			,	//	output		[	QW/8	-	1	:	0	]	
		.	axst_tlast			(	axst_tlast			)			,	//	output										
		.	axst_tuser			(	axst_tuser			)			,	//	output		[	QW		-	1	:	0	]	
		.	axst_tdest			(	axst_tdest			)			,	//	output		[	4		-	1	:	0	]	
		.	axst_count			(	axst_count			)			,	//	output		[	4		-	1	:	0	]	
		.	o_rst				(	o_rst				)			,	//	input												
		.	o_clk				(	o_clk				)				//	input										
	);

	endmodule

