
	// `timescale	1ns/1ps
	module	axis_rx_gather_axs2fifo#(
		parameter	DW			=	64		
	)(

		input		[	31				:	0	]		dma_size_set			,	//	
		input		[	31				:	0	]		dma_wait_set			,	//	
		input											axsr_tvalid				,	//	
		output											axsr_tready				,	//	
		input											axsr_tlast				,	//	
		input		[	DW		-	1	:	0	]		axsr_tdata				,	//	
		input		[	64		-	1	:	0	]		axsr_tuser				,	//	
		input		[	DW/8	-	1	:	0	]		axsr_tkeep				,	//	0
		input		[	DW/8	-	1	:	0	]		axsr_tstrb				,	//	0
		input		[	4		-	1	:	0	]		axsr_tdest				,	//	0
		input		[	4		-	1	:	0	]		axsr_tid				,	//	0
			
		output											axsr_info_wr			,
		output		[	64		-	1	:	0	]		axsr_info_di			,
		input											axsr_info_af			,
		input											axsr_info_fu			,
			
		output											axsr_fifo_wr			,
		output		[	DW		-	1	:	0	]		axsr_fifo_di			,
		input											axsr_fifo_af			,
		input											axsr_fifo_fu			,
		
		input											rst						,
		input											clk								
	);

		localparam	BC	=	DW/32	;	//	double	word count	in bus
		localparam	UB	=	32/8	;	//	byte number in double
		
		reg				com_wait_en		=	1'b0		;
		reg		[31:0]	com_wait_num	=	{32{1'b1}}	;
		reg		[31:0]	dma_good_size	=	4096-1024	;
		
		wire	cur_data_done	;
		wire	cur_time_done	;
		wire	cur_pkg_done	;
		reg		[	12	-	1	:	0	]	cur_axi_byte	=	0	;
		reg		[	16	-	1	:	0	]	cur_pkg_byte	=	0	;
		reg		[	32	-	1	:	0	]	wait_time_cnt	=	0	;
		
		wire	tv		;	assign	tv					=	axsr_tvalid			;
		wire	tr		;	assign	axsr_tready	=	tr							;
		wire	tl		;	assign	tl					=	axsr_tlast			;
		
		wire	[DW-1:0]		tdata	;	assign	tdata	=	axsr_tdata		;
		wire	[DW/8-1:0]		tkeep	;	assign	tkeep	=	axsr_tkeep		;
		wire	[64-1:0]		tuser	;	assign	tuser	=	axsr_tuser		;
		
		wire	trv			=	tr			&&	tv			;
		wire	trvl		=	tr			&&	tv	&&	tl	;
		
		assign	tr		=	~	axsr_info_fu	&&	~	axsr_fifo_fu	;

		reg		sof_idle	=0	;	always@(posedge	clk)	sof_idle	<=	rst	||	trvl	?	1'b1	:	trv	?	0	:	sof_idle	;
		
		reg		[64-1:0]	tuser_l	=0	;	always@(posedge	clk)	tuser_l	<=	sof_idle	?	tuser	:	tuser_l	;

		assign	axsr_fifo_wr	=	trv					;
		assign	axsr_fifo_di	=	{	tkeep,tdata	}	;	
		
		always@(posedge	clk)	begin
			if(rst)	cur_axi_byte	<=	0	;
			else	if(		trvl			)	cur_axi_byte	<=	0							;
			else	if(		trv				)	cur_axi_byte	<=	cur_axi_byte	+	DW/8	;
		end
		
		always@(posedge	clk)	begin
			if(rst)	cur_pkg_byte	<=	0	;
			else	if(		cur_pkg_done	)	cur_pkg_byte	<=	0	;
			else	if(		trvl			)	cur_pkg_byte	<=	cur_pkg_byte	+	cur_axi_byte	+	DW/8	;
		//	else	if(		trv				)	cur_pkg_byte	<=	cur_pkg_byte	+	DW/8	;
		end
		
		always@(posedge	clk)	begin
			if(rst)	wait_time_cnt	<=	0	;
			else	if(		cur_pkg_done							)	wait_time_cnt	<=	0						;
			else	if(	~	com_wait_en								)	wait_time_cnt	<=	0						;
			else	if(		wait_time_cnt	==	com_wait_num		)	wait_time_cnt	<=	wait_time_cnt			;
			else	if(		cur_pkg_byte	!=	0					)	wait_time_cnt	<=	wait_time_cnt	+	1	;
		end
		
		assign	cur_time_done	=	com_wait_en	&&	wait_time_cnt	==	com_wait_num	&&	~	(tv&&tl)	&&	tr	;
		
		assign	cur_data_done	=	trvl	&&	(	~	com_wait_en	||	cur_pkg_byte	+	cur_axi_byte	+	DW/8	>=	dma_good_size	)	;
		
		assign	cur_pkg_done	=	cur_data_done	||	cur_time_done	;
		
		assign	axsr_info_wr	=	cur_pkg_done		;
	//	assign	axsr_info_di	=	sof_idle	?	tuser	:	tuser_l	;
		wire	[63:0]	axsr_info_di_byte	=	cur_data_done	?	cur_pkg_byte	+	cur_axi_byte	+	DW/8	:	cur_pkg_byte	;
		assign	axsr_info_di	=	axsr_info_di_byte/UB	;

		always@(posedge	clk)	begin
			if(rst)	com_wait_en	<=	1'b0	;
			else	if(	cur_pkg_done	)	com_wait_en	<=	dma_wait_set	!=	0	;
			else	if(	cur_pkg_byte	==	0	&&	~trvl	)	com_wait_en	<=	dma_wait_set	!=	0	;
		end
		
		always@(posedge	clk)	begin
			if(rst)	dma_good_size	<=	4096-1024	;
			else	if(	cur_pkg_done	)	dma_good_size	<=	dma_size_set		;
			else	if(	cur_pkg_byte	==	0	&&	~trvl	)	dma_good_size	<=	dma_size_set	;
		end
		
		always@(posedge	clk)	begin
			if(rst)	com_wait_num	<=	4*(256+8+8)/8	;
			else	if(	cur_pkg_done	)	com_wait_num	<=	dma_wait_set		;
			else	if(	cur_pkg_byte	==	0	&&	~trvl	)	com_wait_num	<=	dma_wait_set	;
		end
		
		/* synthesis translate_off */
		
		reg	[15:0]	cur_axi_size	;	always@(posedge	clk)	cur_axi_size	<=	rst	?	0	:	trvl	?	cur_pkg_byte	+	DW/8	:	cur_axi_size	;
		
		/* synthesis translate_on */

	endmodule
