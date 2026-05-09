
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2021年11月30日20:25:08
//	Design	Name		:	
//	Module	Name		:	
//	Project	Name		:	
//	Target	Devices		:	all	Xilinx device
//	Tool	versions	:	all
//	Description		:	
//	Editor			:	Npp,	tab	size	(4)
//	Dependencies		:	
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	TOP file for srio gt monitor
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description		:	RX PHY 子模块例化					:
//	
//	Additional	Comments:	
//

`timescale 1ns/1ns

module	srio_gtrx_pcs_itf	#(
	parameter		LINK_WIDTH		=	1				,	//	SRIO GT LANE WIDTH					
	parameter		GT_BYTES		=	4				,	//	SRIO GT BYTE WIDTH					
	parameter		IDLE1			=	0				,	//	SRIO GT BYTE WIDTH					
	parameter		IDLE2			=	1				,	//	SRIO GT BYTE WIDTH					
	parameter		GT_PCS_DW		=	32*LINK_WIDTH	,	//	SRIO PCS	 WIDTH					
	parameter		GT_PHY_DW		=	64					//	SRIO PHY	 WIDTH					
)(
		input	wire								gt_pcs_rst					,
		input	wire								gt_pcs_clk					,
		input	wire								force_reinit				,
		input	wire	[	LINK_WIDTH*4*8	-1:0]	gtrx_data					,	
		input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_charisk				,
		input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_chariscomma			,
		input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_disperr				,
		input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_notintable				,
		input	wire	[	LINK_WIDTH		-1:0]	gtrx_chanisaligned			,
		input	wire	[	LINK_WIDTH		-1:0]	gtrx_reset_done				,
		input	wire								gtrx_reset_req				,
		output	wire								gtrx_reset					,
		output	wire								gtrx_chanbonden				,
		output	wire								gtrx_align_rst				,
		
		input	wire								set_link_1x					,
		output	wire								any_gtrxaligned				,
		output	wire								all_gtrxaligned				,
		
		output	wire								gtrx_dat_info_wr			,
		output	wire	[	12			-1:0]		gtrx_dat_info_di			,
		input	wire								gtrx_dat_info_af			,
		input	wire								gtrx_dat_info_fu			,
		output	wire								gtrx_dat_fifo_wr			,
		output	wire	[	GT_PHY_DW	-1:0]		gtrx_dat_fifo_di			,
		input	wire								gtrx_dat_fifo_af			,
		input	wire								gtrx_dat_fifo_fu			,
		
		output	wire								gtrx_ksc_fifo_wr			,
		output	wire	[	GT_PHY_DW	-1:0]		gtrx_ksc_fifo_di			,
		input	wire								gtrx_ksc_fifo_af			,
		input	wire								gtrx_ksc_fifo_fu			,
		
		output	wire	[	32			-1:0]		r1r_gtrx_kpd_cnt			,
		output	wire	[	32			-1:0]		gtx_gtrx_sof_cnt			,
		output	wire	[	32			-1:0]		sft_gtrx_sop_cnt			,
		output	wire	[	32			-1:0]		rmv_gtrx_sop_cnt			,
		output	wire	[	32			-1:0]		par_gtrx_sop_cnt			,
		output	wire	[	32			-1:0]		par_byte_kpd_cnt			,
		output	wire	[	32			-1:0]		sopdat_match_cnt			,
		output	wire	[	32			-1:0]		rmv_fifo_afu_cnt			,
		output	wire	[	32			-1:0]		par_fifo_afu_cnt			,
	
		output	wire	[	32			-1:0]		gtrx_error_cnt				,
		output	wire								gtrx_error_or				,
		output	wire	[	LINK_WIDTH	-1:0]		gtxchanisaligned			,
		output	wire								idle2_detected				,
		output	wire	[	LINK_WIDTH	-1:0]		desc_verify_ok				,
		output	wire	[	LINK_WIDTH*4-1:0]		desc_verify_err_cnt			,
		
		input	wire								itf_rst						,			
		input	wire								itf_clk									

	);	
		
	wire	[	LINK_WIDTH*4*8	-1:0]	r1rx_data					;	
	wire	[	LINK_WIDTH*4	-1:0]	r1rx_charisk				;
	wire	[	LINK_WIDTH*4	-1:0]	r1rx_chariscomma			;
	wire	[	LINK_WIDTH*1	-1:0]	r1rx_chanisaligned			;

	wire	[	LINK_WIDTH*32	-1:0]	desc_data					;
	wire	[	LINK_WIDTH*4	-1:0]	desc_charisk				;
	wire	[	LINK_WIDTH*4	-1:0]	desc_chariscomma			;
		
	wire	[	LINK_WIDTH*32	-1:0]	flag_data					;
	wire	[	LINK_WIDTH*4	-1:0]	flag_charisk				;
	wire	[	LINK_WIDTH*4	-1:0]	flag_chariscomma			;
	
	wire	[	LINK_WIDTH*32	-1:0]	idle_data					;
	wire	[	LINK_WIDTH*4	-1:0]	idle_charisk				;
	wire	[	LINK_WIDTH*4	-1:0]	idle_chariscomma			;	
			
	wire								gtrx_cvt_buf_naf			;
	wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_cvt_spd_vlu			;	
	wire								gtrx_cvt_spd_vld			;
	
	wire								gtrx_rdy_64					;
	wire								gtrx_vld_64					;
	wire	[	64				-1:0]	gtrx_dat_64					;
	wire	[	8				-1:0]	gtrx_isk_64					;
	
	wire	[	LINK_WIDTH*GT_BYTES-1:0]idle2_cs_break_o			;

	gtrx_char_pipe	#(
					.	LINK_WIDTH	(	LINK_WIDTH	)	,	//	Number	of	GT	lanes	{1,	2,	4}
					.	GT_BYTES	(	GT_BYTES	)		//	Bytes	on	the	GT	Interface			
	)i_gtrx_char_pipe(
		.	gtrx_data			(		gtrx_data			)			,	//	input	wire	[	LINK_WIDTH*4*8	-1:0]	
		.	gtrx_charisk		(		gtrx_charisk		)			,	//	input	wire	[	LINK_WIDTH*4	-1:0]	
		.	gtrx_chariscomma	(		gtrx_chariscomma	)			,	//	input	wire	[	LINK_WIDTH*4	-1:0]	
		.	gtrx_disperr		(		gtrx_disperr		)			,	//	input	wire	[	LINK_WIDTH*4	-1:0]	
		.	gtrx_notintable		(		gtrx_notintable		)			,	//	input	wire	[	LINK_WIDTH*4	-1:0]	
		.	gtrx_chanisaligned	(		gtrx_chanisaligned	)			,	//	input	wire	[	LINK_WIDTH		-1:0]	
		.	gtrx_reset_done		(		gtrx_reset_done		)			,	//	input	wire	[	LINK_WIDTH		-1:0]	
		.	gtrx_reset_req		(		gtrx_reset_req		)			,	//	input	wire								
		.	gtrx_reset			(		gtrx_reset			)			,	//	output	wire								
		.	gtrx_chanbonden		(		gtrx_chanbonden		)			,	//	output	wire								
		.	gtrx_align_rst		(		gtrx_align_rst		)			,	//	output	wire								
		.	gtxchanisaligned	(		gtxchanisaligned	)			,	//	output	reg									
		.	gtrx_error_or		(		gtrx_error_or		)			,	//	output	reg									
		.	gtrx_error_cnt		(		gtrx_error_cnt		)			,	//	output	reg		[	32				-1:0]	
		.	r1r_gtrx_kpd_cnt	(		r1r_gtrx_kpd_cnt	)			,	//	output	reg		[	32				-1:0]	
		.	gtx_gtrx_sof_cnt	(		gtx_gtrx_sof_cnt	)			,	//	output	reg		[	32				-1:0]	
		.	set_link_1x			(		set_link_1x			)			,	//	input	wire								
		.	any_gtrxaligned		(		any_gtrxaligned		)			,	//	output	wire								
		.	all_gtrxaligned		(		all_gtrxaligned		)			,	//	output	wire								
		.	idle2_detected		(		idle2_detected		)			,	//	output	wire								
		.	r1rx_data			(		r1rx_data			)			,	//	output	reg		[	LINK_WIDTH*4*8	-1:0]	
		.	r1rx_charisk		(		r1rx_charisk		)			,	//	output	reg		[	LINK_WIDTH*4*1	-1:0]	
		.	r1rx_chariscomma	(		r1rx_chariscomma	)			,	//	output	reg		[	LINK_WIDTH*4*1	-1:0]	
		.	r1rx_chanisaligned	(		r1rx_chanisaligned	)			,	//	output	reg		[	LINK_WIDTH*1*1	-1:0]	
		.	gt_pcs_rst			(		gt_pcs_rst			)			,	//	input	wire								
		.	gt_pcs_clk			(		gt_pcs_clk			)				//	input	wire								
	);	
	
	genvar	i,j;
	generate 		
		for	(i=0;	i	<	LINK_WIDTH;	i=i+1)	begin	:	SRIO_DESCRAM
			srio_descram_top	#(
				.	LOOP_NUM	(	i			)	,	//	数据位宽		
				.	D_WIDTH		(	32			)	,	//	数据位宽		
				.	P_WIDTH		(	17			)	,	//	方程式位宽		
				.	SEED		(	17'h1FFFF	)	,	//	初始化种子		
				.	POLY		(	17'h10081	)	,	//	方程式掩码		
				.	LINK_WIDTH	(	LINK_WIDTH	)	,	//	Number	of	GT	lanes	{1,	2,	4}
				.	GT_BYTES	(	GT_BYTES	)		//	Bytes	on	the	GT	Interface
			)i_srio_descram_top(
				.	ensc_data			(	r1rx_data			[	i*	GT_BYTES	*08	+:	GT_BYTES	*08	]	)	,	//	input	wire	
				.	ensc_charisk		(	r1rx_charisk		[	i*	GT_BYTES	*01	+:	GT_BYTES	*01	]	)	,	//	input	wire	
				.	ensc_chariscomma	(	r1rx_chariscomma	[	i*	GT_BYTES	*01	+:	GT_BYTES	*01	]	)	,	//	input	wire	
				.	desc_data			(	desc_data			[	i*	GT_BYTES	*08	+:	GT_BYTES	*08	]	)	,	//	input	wire	
				.	desc_charisk		(	desc_charisk		[	i*	GT_BYTES	*01	+:	GT_BYTES	*01	]	)	,	//	input	wire	
				.	desc_chariscomma	(	desc_chariscomma	[	i*	GT_BYTES	*01	+:	GT_BYTES	*01	]	)	,	//	input	wire	
				.	desc_verify_ok		(	desc_verify_ok		[	i*	01			*01	+:	01			*01	]	)	,	//	input	reg		
				.	desc_verify_err_cnt	(	desc_verify_err_cnt	[	i*	01			*04	+:	01			*04	]	)	,	//	input	reg		
				.	idle2_cs_break_i	(	idle2_cs_break_o	[	0*	GT_BYTES	*01	+:	GT_BYTES	*01	]	)	,	//	input	wire	
				.	idle2_cs_break_o	(	idle2_cs_break_o	[	i*	GT_BYTES	*01	+:	GT_BYTES	*01	]	)	,	//	output	wire	
				.	gt_pcs_rst			(	gt_pcs_rst			||		gtrx_error_or							)	,	//	input	wire	
				.	gt_pcs_clk			(	gt_pcs_clk															)		//	input	wire	
			);
		end
	endgenerate
			
		srio_idle2_detc	#(
			.	LINK_WIDTH	(	LINK_WIDTH	)	,	//	SRIO GT LANE WIDTH					
			.	GT_BYTES	(	GT_BYTES	)		//	SRIO GT BYTE NUMBER					
		)i_srio_idle2_detc(
			.	desc_data			(	desc_data				)	,	//	input	wire	[	LINK_WIDTH*4*8	-1:0]	
			.	desc_charisk		(	desc_charisk			)	,   //	input	wire	[	LINK_WIDTH*4	-1:0]	
			.	desc_chariscomma	(	desc_chariscomma		)	,   //	input	wire	[	LINK_WIDTH*4	-1:0]	
			.	flag_data			(	flag_data				)	,	//	output	wire	[	LINK_WIDTH*4*8	-1:0]	
			.	flag_charisk		(	flag_charisk			)	,   //	output	wire	[	LINK_WIDTH*4	-1:0]	
			.	flag_chariscomma	(	flag_chariscomma		)	,   //	output	wire	[	LINK_WIDTH*4	-1:0]	
			.	gt_pcs_rst			(	gt_pcs_rst				)	,   //	input	wire								
			.	gt_pcs_clk			(	gt_pcs_clk				)	    //	input	wire								
		);	
	
	assign	idle_data			=		idle2_detected	?	flag_data			:	r1rx_data			;
	assign	idle_charisk		=		idle2_detected	?	flag_charisk		:	r1rx_charisk		;
	assign	idle_chariscomma	=		idle2_detected	?	flag_chariscomma	:	r1rx_chariscomma	;
	
	gtrx_rm_idle	#(
		.	LINK_WIDTH		(	LINK_WIDTH	)
	)i_gtrx_rm_idle(
	//	.	gt_pcs_rst				(	gt_pcs_rst	||gtrx_error_or	)	,	//	input	wire								
		.	gt_pcs_rst				(	gt_pcs_rst					)	,	//	input	wire								
		.	gt_pcs_clk				(	gt_pcs_clk					)	,	//	input	wire								
		.	idle2_detected			(	idle2_detected				)	,	//	input	wire	[	LINK_WIDTH*4*8	-1:0]	
		.	gtrx_data				(	idle_data					)	,	//	input	wire	[	LINK_WIDTH*4*8	-1:0]	
		.	gtrx_charisk			(	idle_charisk				)	,	//	input	wire	[	LINK_WIDTH*4	-1:0]	
		.	gtrx_chariscomma		(	idle_chariscomma			)	,	//	input	wire	[	LINK_WIDTH*4	-1:0]	
		.	gtx_gtrx_sop_cnt		(	sft_gtrx_sop_cnt			)	,	//	output	wire	[	32				-1:0]	
		.	rmv_gtrx_sop_cnt		(	rmv_gtrx_sop_cnt			)	,	//	output	wire	[	32				-1:0]	
		.	rmv_fifo_afu_cnt		(	rmv_fifo_afu_cnt			)	,	//	output	wire	[	32				-1:0]	
		.	gtrx_cvt_buf_naf		(	gtrx_cvt_buf_naf			)	,	//	output	wire	[	LINK_WIDTH*4*9	-1:0]	
		.	gtrx_cvt_spd_vlu		(	gtrx_cvt_spd_vlu			)	,	//	output	wire	[	LINK_WIDTH*4*9	-1:0]	
		.	gtrx_cvt_spd_vld		(	gtrx_cvt_spd_vld			)		//	output	wire								
	);	

	srio_gtrx_64	#(
		.	LINK_WIDTH		(	LINK_WIDTH	)			
	)i_srio_gtrx_64(
		.	gtrx_cvt_buf_naf		(	gtrx_cvt_buf_naf			)	,	//	input	wire	[	LINK_WIDTH*4*9	-1:0]		
		.	gtrx_cvt_spd_vlu		(	gtrx_cvt_spd_vlu			)	,	//	input	wire	[	LINK_WIDTH*4*9	-1:0]		
		.	gtrx_cvt_spd_vld		(	gtrx_cvt_spd_vld			)	,	//	input	wire								
		.	gt_pcs_rst				(	gt_pcs_rst					)	,	//	input	wire								
		.	gt_pcs_clk				(	gt_pcs_clk					)	,	//	input	wire								
		.	gtrx_rdy_64				(	gtrx_rdy_64					)	,	//	input	reg									
		.	gtrx_vld_64				(	gtrx_vld_64					)	,	//	output	reg									
		.	gtrx_dat_64				(	gtrx_dat_64					)	,	//	output	reg									
		.	gtrx_isk_64				(	gtrx_isk_64					)	,	//	output	reg									
		.	itf_rst					(	itf_rst						)	,	//	input	wire								
		.	itf_clk					(	itf_clk						)		//	input	wire								
	);	

	srio_gtrx_parse 	#(
		.	LINK_WIDTH	(	LINK_WIDTH	)	,	//	SRIO GT LANE WIDTH					
		.	FIFO_WIDTH	(	GT_PHY_DW	)		//	SRIO GT LANE WIDTH					
	)i_srio_gtrx_parse(
	//	.	gtrx_error_or				(	gtrx_error_or			)	,	//		output	wire								
		.	gtrx_error_or				(	1'b0					)	,	//		output	wire								
		.	idle2_detected				(	idle2_detected			)	,	//		input	wire							
		.	gtrx_rdy_64					(	gtrx_rdy_64				)	,	//		output	wire								
		.	gtrx_vld_64					(	gtrx_vld_64				)	,	//		input	wire								
		.	gtrx_dat_64					(	gtrx_dat_64				)	,	//		input	wire	[	64				-1:0]	
		.	gtrx_isk_64					(	gtrx_isk_64				)	,	//		input	wire	[	8				-1:0]	
		.	gtrx_dat_info_wr			(	gtrx_dat_info_wr		)	,	//		output	wire								
		.	gtrx_dat_info_di			(	gtrx_dat_info_di		)	,	//		output	wire	[	12				-1:0]	
		.	gtrx_dat_info_af			(	gtrx_dat_info_af		)	,	//		input	wire								
		.	gtrx_dat_info_fu			(	gtrx_dat_info_fu		)	,	//		input	wire								
		.	gtrx_dat_fifo_wr			(	gtrx_dat_fifo_wr		)	,	//		output	wire								
		.	gtrx_dat_fifo_di			(	gtrx_dat_fifo_di		)	,	//		output	wire	[	64				-1:0]	
		.	gtrx_dat_fifo_af			(	gtrx_dat_fifo_af		)	,	//		input	wire								
		.	gtrx_dat_fifo_fu			(	gtrx_dat_fifo_fu		)	,	//		input	wire								
		.	gtrx_ksc_fifo_wr			(	gtrx_ksc_fifo_wr		)	,	//		output	wire								
		.	gtrx_ksc_fifo_di			(	gtrx_ksc_fifo_di		)	,	//		output	wire	[	64				-1:0]	
		.	gtrx_ksc_fifo_af			(	gtrx_ksc_fifo_af		)	,	//		input	wire								
		.	gtrx_ksc_fifo_fu			(	gtrx_ksc_fifo_fu		)	,	//		input	wire								
		.	sopdat_match_cnt			(	sopdat_match_cnt		)	,	//		input	wire								
		.	par_gtrx_sop_cnt			(	par_gtrx_sop_cnt		)	,	//		input	wire								
		.	par_byte_kpd_cnt			(	par_byte_kpd_cnt		)	,	//		input	wire								
		.	par_fifo_afu_cnt			(	par_fifo_afu_cnt		)	,	//		input	wire								
		.	itf_rst						(	itf_rst					)	,	//		input	wire								
		.	itf_clk						(	itf_clk					)		//		input	wire								
	);


	`ifdef	DBG_ILA
			wire	[4*8-1:0]	ln0_gtrx_data			=		gtrx_data		[0*4*8+:4*8]	;
			wire	[4*1-1:0]	ln0_gtrx_charisk		=		gtrx_charisk	[0*4*1+:4*1]	;
			wire	[4*1-1:0]	ln0_gtrx_disperr		=		gtrx_disperr	[0*4*1+:4*1]	;
			wire	[4*1-1:0]	ln0_gtrx_notintable		=		gtrx_notintable	[0*4*1+:4*1]	;
			wire	[4*8-1:0]	ln0_desc_data			=		desc_data		[0*4*8+:4*8]	;
			wire	[4*1-1:0]	ln0_desc_charisk		=		desc_charisk	[0*4*1+:4*1]	;
		`ifndef	SRIO_1_LANE
			wire	[4*8-1:0]	ln1_gtrx_data			=		gtrx_data		[1*4*8+:4*8]	;
			wire	[4*1-1:0]	ln1_gtrx_charisk		=		gtrx_charisk	[1*4*1+:4*1]	;
			wire	[4*1-1:0]	ln1_gtrx_disperr		=		gtrx_disperr	[1*4*1+:4*1]	;
			wire	[4*1-1:0]	ln1_gtrx_notintable		=		gtrx_notintable	[1*4*1+:4*1]	;
			wire	[4*8-1:0]	ln1_desc_data			=		desc_data		[1*4*8+:4*8]	;
			wire	[4*1-1:0]	ln1_desc_charisk		=		desc_charisk	[1*4*1+:4*1]	;
		`endif
		
		`ifdef	SRIO_4_LANE
			wire	[4*8-1:0]	ln2_gtrx_data			=		gtrx_data		[2*4*8+:4*8]	;
			wire	[4*1-1:0]	ln2_gtrx_charisk		=		gtrx_charisk	[2*4*1+:4*1]	;
			wire	[4*1-1:0]	ln2_gtrx_disperr		=		gtrx_disperr	[2*4*1+:4*1]	;
			wire	[4*1-1:0]	ln2_gtrx_notintable		=		gtrx_notintable	[2*4*1+:4*1]	;
			wire	[4*8-1:0]	ln2_desc_data			=		desc_data		[2*4*8+:4*8]	;
			wire	[4*1-1:0]	ln2_desc_charisk		=		desc_charisk	[2*4*1+:4*1]	;
	
			wire	[4*8-1:0]	ln3_gtrx_data			=		gtrx_data		[3*4*8+:4*8]	;
			wire	[4*1-1:0]	ln3_gtrx_charisk		=		gtrx_charisk	[3*4*1+:4*1]	;
			wire	[4*1-1:0]	ln3_gtrx_disperr		=		gtrx_disperr	[3*4*1+:4*1]	;
			wire	[4*1-1:0]	ln3_gtrx_notintable		=		gtrx_notintable	[3*4*1+:4*1]	;
			wire	[4*8-1:0]	ln3_desc_data			=		desc_data		[3*4*8+:4*8]	;
			wire	[4*1-1:0]	ln3_desc_charisk		=		desc_charisk	[3*4*1+:4*1]	;
		`endif
	
		reg		[31:0]	gtx_gtrx_sof_cnt_q1	=	0	;	always@(posedge	gt_pcs_clk)	gtx_gtrx_sof_cnt_q1	<=	gtx_gtrx_sof_cnt	;
		reg		[31:0]	gtx_gtrx_sof_cnt_q2	=	0	;	always@(posedge	gt_pcs_clk)	gtx_gtrx_sof_cnt_q2	<=	gtx_gtrx_sof_cnt_q1	;
		reg		[31:0]	gtx_gtrx_sof_cnt_q3	=	0	;	always@(posedge	gt_pcs_clk)	gtx_gtrx_sof_cnt_q3	<=	gtx_gtrx_sof_cnt_q2	;
		reg		[31:0]	gtx_gtrx_sof_cnt_q4	=	0	;	always@(posedge	gt_pcs_clk)	gtx_gtrx_sof_cnt_q4	<=	gtx_gtrx_sof_cnt_q3	;
		reg		[31:0]	gtx_sft_cnt_calc	=	0	;
		reg				gtx_sft_cnt_error	=	0	;
		always@(posedge	gt_pcs_clk)	gtx_sft_cnt_calc	<=	gt_pcs_rst	?	0	:	gtx_gtrx_sof_cnt_q4	-	sft_gtrx_sop_cnt	;
		always@(posedge	gt_pcs_clk)	gtx_sft_cnt_error	<=	gtx_sft_cnt_calc	>	1	;
	
		reg				gtrx_align_rst_q			=	1'b0			;
		always@(posedge	gt_pcs_clk)	gtrx_align_rst_q	<=	gtrx_align_rst	;
		reg		[32-1:0]gtx_ali_rst_cnt			=	0				;
		always@(posedge	gt_pcs_clk)	gtx_ali_rst_cnt	<=	&gtrx_chanisaligned	?	0	:	gtx_ali_rst_cnt+(gtrx_align_rst&&~gtrx_align_rst_q)	;
		
		reg		[4-1:0]	ln0_idle2_cs_break_o=0	;	always@(posedge	gt_pcs_clk)	ln0_idle2_cs_break_o	<=	idle2_cs_break_o[0+:4]	;
		
		ila_576X1024 ila_576X1024_pcs (
			.	clk		(	gt_pcs_clk	)	,	// input wire clk
			.	probe0	(	
							{
	
								//	r1r_gtrx_kpd_cnt		,
								//	par_byte_kpd_cnt		,
									any_gtrxaligned			,
									all_gtrxaligned			,
									gtrx_align_rst			,
									gtx_ali_rst_cnt	[31:0]	,
									gtrx_error_or			,
									desc_verify_ok			,
									desc_verify_err_cnt		,
									ln0_idle2_cs_break_o	,
									
									gtx_sft_cnt_calc[3:0]	,
									gtx_sft_cnt_error		,
									
									gtx_gtrx_sof_cnt		,
									sft_gtrx_sop_cnt		,
									ln0_gtrx_data			,
									ln0_gtrx_charisk		,
									ln0_gtrx_disperr		,
									ln0_gtrx_notintable		,
									ln0_desc_data			,
									ln0_desc_charisk		,
								`ifndef	SRIO_1_LANE         
									ln1_gtrx_data			,
									ln1_gtrx_charisk		,
									ln1_gtrx_disperr		,
									ln1_gtrx_notintable		,
									ln1_desc_data			,
									ln1_desc_charisk		,
								`endif                      

								`ifdef	SRIO_4_LANE         
									ln2_gtrx_data			,
									ln2_gtrx_charisk		,
									ln2_gtrx_disperr		,
									ln2_gtrx_notintable		,
									ln2_desc_data			,
									ln2_desc_charisk		,
									ln3_gtrx_data			,
									ln3_gtrx_charisk		,
									ln3_gtrx_disperr		,
									ln3_gtrx_notintable		,
									ln3_desc_data			,
									ln3_desc_charisk		,
								`endif

								gtxchanisaligned			
								
							}	
						)		// input wire [31:0] probe0
		);
	`endif

endmodule