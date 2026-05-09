
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
		
		localparam	MAX_RIO_PKG_SIZE	=	256+64	;
		
		localparam		P_DMA_GOOD_SIZE	=	16'h0E00	;
		localparam		P_DMA_TIME_SIZE	=	16'h0C00	;
		
		reg		[15:0]	dma_good_time	=	'h200		;
		reg		[15:0]	dma_good_size	=	4096-1024	;
		
		wire	cur_data_done	;
		wire	cur_time_done	;
		wire	cur_pkg_done	;
		
		reg		cur_dat_will_done	=	0	;
		reg		cur_dat_will_done_pre	=	0	;
		
		reg		wait_size_en	=	0	;
		reg		wait_time_en	=	0	;
		reg		dma_gather_en	=	0	;
		
		reg		[	12	-	1	:	0	]	cur_axi_byte	=	0	;
		reg		[	16	-	1	:	0	]	cur_pkg_byte	=	0	;
		reg		[	16	-	1	:	0	]	wait_time_cnt	=	0	;
		
		wire	tv		;	assign	tv					=	axsr_tvalid			;
		wire	tr		;	assign	axsr_tready	=	tr							;
		wire	tl		;	assign	tl					=	axsr_tlast			;
		
		wire	[DW-1:0]		tdata	;	assign	tdata	=	axsr_tdata		;
		wire	[DW/8-1:0]		tkeep	;	assign	tkeep	=	axsr_tkeep		;
		wire	[64-1:0]		tuser	;	assign	tuser	=	axsr_tuser		;
		
		wire	trv			=	tr			&&	tv			;
		wire	trvl		=	tr			&&	tv	&&	tl	;
		
	//	assign	tr		=	~	axsr_info_fu	&&	~	axsr_fifo_fu	;
		assign	tr		=	~	axsr_info_af	&&	~	axsr_fifo_af	;

		reg		pkg_idle	=	1'b1	;	always@(posedge	clk)	pkg_idle	<=	rst	?	1	:	cur_pkg_done	?	1	:	trv	?	0	:	pkg_idle	;
	//	reg		axi_idle	=	1'b1	;	always@(posedge	clk)	axi_idle	<=	rst	?	1	:	trvl			?	1	:	trv	?	0	:	axi_idle	;
		reg		trvl_l		=	1'b0	;	always@(posedge	clk)	trvl_l		<=	rst	?	0	:	cur_pkg_done	?	0	:	trvl?	1	:	trvl_l		;
		
		always@(posedge	clk)	begin
			if(rst)	cur_axi_byte	<=	0	;
			else	if(		trvl			)	cur_axi_byte	<=	0	;
			else	if(		trv				)	cur_axi_byte	<=	cur_axi_byte	+	DW/8	;
		end


		always@(posedge	clk)	begin
			if(rst)	cur_pkg_byte	<=	0	;
			else	if(		cur_data_done	)	cur_pkg_byte	<=	0	;
			else	if(		cur_time_done	)	cur_pkg_byte	<=	cur_axi_byte	;
			else	if(		trv				)	cur_pkg_byte	<=	cur_pkg_byte	+	DW/8	;
		end
		
		always@(posedge	clk)	cur_dat_will_done_pre	<=	cur_pkg_byte	>=	dma_good_size	;
		
		always@(posedge	clk)	begin
			if(rst)	cur_dat_will_done	<=	0	;
			else	if(	!	dma_gather_en					)	cur_dat_will_done	<=	1	;	//	transmit length	>=	1	
			else	if(		cur_pkg_done					)	cur_dat_will_done	<=	0	;	//	transmit length	>=	1	
			else	if(		cur_dat_will_done_pre			)	cur_dat_will_done	<=	1	;	//	transmit length	>=	1	
		end
		
		always@(posedge	clk)	begin
			if(rst)	wait_time_cnt	<=	'hc00	;
			else	if(		cur_pkg_done					)	wait_time_cnt	<=	dma_good_time			;
			else	if(		pkg_idle						)	wait_time_cnt	<=	dma_good_time			;
			else	if(		1			>=	wait_time_cnt	)	wait_time_cnt	<=	wait_time_cnt			;
			else												wait_time_cnt	<=	wait_time_cnt	-	1	;
		end
		
		reg		[15:0]	cur_pkg_byte_l	=	0	;
		always@(posedge	clk)	begin
			if(rst)	cur_pkg_byte_l	<=	0	;
		//	else	if(cur_pkg_done)	cur_pkg_byte_l	<=	0	;
			else	if(trvl)	cur_pkg_byte_l	<=	cur_pkg_byte	+	DW/8	;
		end
		
		always@(posedge	clk)	wait_size_en	<=	dma_size_set	!=	0											;
		always@(posedge	clk)	wait_time_en	<=	dma_wait_set	!=	0											;
	//	always@(posedge	clk)	dma_gather_en	<=	wait_size_en	&&		wait_time_en							;
		always@(posedge	clk)	begin
			if(rst)	dma_gather_en	<=	0	;
			else	if(	cur_pkg_done		)	dma_gather_en	<=	wait_size_en	&&		wait_time_en	;//	dma_size_set	:	DW/8	;
			else	if(	pkg_idle	&&	!tv	)	dma_gather_en	<=	wait_size_en	&&		wait_time_en	;//	dma_size_set	:	DW/8	;
		end
		
		reg		timer_match		=	0	;	always@(posedge	clk)	timer_match		<=	cur_pkg_done	?	0	:	1				>=	wait_time_cnt	;
		reg		wait_time_ok	=	0	;	always@(posedge	clk)	wait_time_ok	<=	cur_pkg_done	?	0	:	timer_match		&&	trvl_l			;
		
		assign	cur_time_done	=	wait_time_ok	&&	tr	&&	!tv		;
		
		assign	cur_data_done	=	trvl	&&	cur_dat_will_done		;
		
		assign	cur_pkg_done	=	cur_data_done	||	cur_time_done	;
		
	//	wire	[15:0]	cur_pkg_size	=	cur_data_done	?	cur_pkg_byte	+	DW/8	:	cur_pkg_byte_l	;
	//	assign	axsr_info_wr	=	cur_pkg_done			;
	//	assign	axsr_info_di	=	{48'h0,cur_pkg_size/UB}	;
		
		reg					cur_pkg_done_dly	=	0	;	always@(posedge	clk)	cur_pkg_done_dly	<=	cur_pkg_done		;
		reg		[15:0]		cur_pkg_byte_dly	=	0	;	always@(posedge	clk)	cur_pkg_byte_dly	<=	cur_data_done	?	cur_pkg_byte	+	DW/8	:	cur_pkg_byte_l	;
		assign	axsr_info_wr	=	cur_pkg_done_dly			;
		assign	axsr_info_di	=	{48'h0,cur_pkg_byte_dly/UB}	;
		
		reg					trv_dly		=	0	;	always@(posedge	clk)	trv_dly		<=	trv		;
		reg		[DW-1:0]	tdata_dly	=	0	;	always@(posedge	clk)	tdata_dly	<=	tdata	;
		assign	axsr_fifo_wr	=	trv_dly			;
		assign	axsr_fifo_di	=	tdata_dly		;	
		
		
		always@(posedge	clk)	begin
			if(rst)	dma_good_size	<=	0	;
			else	if(	cur_pkg_done		)	dma_good_size	<=	dma_size_set	;	//	dma_wait_set	:	DW/8	;//	
			else	if(	pkg_idle	&&	!tv	)	dma_good_size	<=	dma_size_set	;	//	dma_wait_set	:	DW/8	;//	
		end
		
		always@(posedge	clk)	begin
			if(rst)	dma_good_time	<=	'hC00	;
			else	if(	cur_pkg_done		)	dma_good_time	<=	dma_wait_set	;
			else	if(	pkg_idle	&&	!tv	)	dma_good_time	<=	dma_wait_set	;
		end
		
		/* synthesis translate_off */
		
		reg	[15:0]	cur_axi_size			;	always@(posedge	clk)	cur_axi_size	<=	rst	?	0	:	cur_pkg_done	?	cur_pkg_byte	+	DW/8	:	cur_axi_size	;
		reg	[15:0]	cur_pkg_max		=	0	;	always@(posedge	clk)	cur_pkg_max		<=	rst	?	0	:	axsr_info_wr	?	(axsr_info_di	>	cur_pkg_max	?	axsr_info_di	:	cur_pkg_max)	:	cur_pkg_max	;
		/* synthesis translate_on
	ila_576X1024  gather_ila (
   		.	clk		(	clk	)	,	// input wire clk
   		.	probe0	(	
   						{
   				 
   					axsr_info_wr	 ,
   				 	axsr_info_di	 ,
   					cur_data_done		 ,
   					cur_pkg_byte		 ,
   					axsr_fifo_wr		 ,
   				 	axsr_fifo_di		 ,
   					cur_axi_size		 ,
   				 	cur_pkg_max			 ,
   				//	axst_tid		 ,
   					axsr_fifo_em	,
   				      cs   			,                                       
   				   cur_pkg_upsz                                             
   				                                             				
   					
   						}	
   		)		// input wire [31:0] probe0
   	); 
		  */
		
	endmodule
