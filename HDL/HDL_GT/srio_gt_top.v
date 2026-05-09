
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2021年11月30日20:25:08
//	Design	Name		:	
//	Module	Name		:	
//	Project	Name		:	
//	Target	Devices		:	all	Xilinx device
//	Tool	versions	:	all
//	Description		:	顶层例化
//	Editor			:	Npp,	tab	size	(4)
//	Dependencies		:	
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	TOP file for srio gt monitor
//
//		Revision	1.01	-	File	Modified	by	:	xxx
//		Description							:
//	
//	Additional	Comments:	
//
//////////////////////////////////////////////////////////////////////////////////

//	`timescale	1ns/1ps

module	srio_gt_top
	#(	
		parameter	P_DEVICE_TYPE_R						=	"XLNX_V7"			,	//	in	ps
		parameter	TCQ									=	100					,	//	in	ps
		parameter	IPCORE_NUM							=	1					,	//	Number	of	IP	Cores	{1,	2,	4}
		parameter	LINK_WIDTH							=	`SRIO_CH_LANE		,	//	Number	of	GT	lanes	{1,	2,	4}
		parameter	GT_BYTES							=	4					,	//	Bytes	on	the	GT	Interface
		parameter	GT_SPD								=	`SRIO_SPEED			,	//	Line	rates	{1/1.25,	2/2.5,	3/3.125,	5/5,	6/6.25}
		parameter	IDLE1								=	`IDLE_1				,	//	Include	the	IDLE1	sequence	{0,1}
		parameter	IDLE2								=	`IDLE_2					//	Include	the	IDLE2	sequence	{0,1}
	)
	(
		input	wire													sys_clkp			,
		input	wire													sys_clkn			,
		input	wire													sys_rst				,
			                                                    
		input	wire	[	IPCORE_NUM	*	LINK_WIDTH	-1:0]			srio_rxn			,
		input	wire	[	IPCORE_NUM	*	LINK_WIDTH	-1:0]			srio_rxp			,
		output	wire	[	IPCORE_NUM	*	LINK_WIDTH	-1:0]			srio_txn			,
		output	wire	[	IPCORE_NUM	*	LINK_WIDTH	-1:0]			srio_txp			,
		
		output	wire													gt_pcs_clk			,
		output	wire													gt_pcs_rst			,
			
		output	wire													phy_clk				,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			phy_rst				,

		output	wire													log_clk				,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			log_rst				,
		
		output	wire	[	IPCORE_NUM	*	01			-1:0]			gt_clk				,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			gt_rst				,
		
		input	wire	[	IPCORE_NUM	*	01			-1:0]			set_link_1x			,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			any_gtrxaligned		,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			all_gtrxaligned		,
		input	wire	[	IPCORE_NUM	*	01			-1:0]			force_reinit		,
		input	wire	[	IPCORE_NUM	*	01			-1:0]			c_gt_ksc_enab		,
		input	wire	[	IPCORE_NUM	*	01			-1:0]			c_gt_dat_byps		,

		input	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_iorx_tready	,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_iorx_tvalid	,
		output	wire	[	IPCORE_NUM	*	64			-1:0]			srgt_iorx_tdata		,
		output	wire	[	IPCORE_NUM	*	08			-1:0]			srgt_iorx_tkeep		,
		output	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_iorx_tlast		,
		output	wire	[	IPCORE_NUM	*	64			-1:0]			srgt_iorx_tuser		,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			srgt_data_tcnt		,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			srgt_k_sc_tcnt		,
		
		output	wire	[	IPCORE_NUM	*	32			-1:0]			r1r_gtrx_kpd_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			sft_gtrx_sop_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			rmv_gtrx_sop_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			par_gtrx_sop_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			par_byte_kpd_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			sopdat_match_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			par_fifo_afu_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			rmv_fifo_afu_cnt	,
		output	wire	[	IPCORE_NUM	*	32			-1:0]			gtx_debug_signal	,
		
		
		input	wire													dma_rst				,
		input	wire													dma_clk				


	);	//srio_gen2_bm_top

	//------------------------clk&rst----------------------
		wire	itf_rst	=	dma_rst	;	//	dma_rst	;	//	
		wire	itf_clk	=	dma_clk	;	//	dma_clk	;	//	

	//------------------------Parameter----------------------
	localparam		GT_PCS_DW	=	32					;
	localparam		GT_PHY_DW	=	64					;
	localparam		GT_LOG_DW	=	64					;

	//------------------------Local	signal-------------------
		
//	wire	[	IPCORE_NUM	*	01				-1:0]		force_reinit				;
	wire	[	IPCORE_NUM	*	01				-1:0]		controlled_force_reinit		;
//	wire	[	IPCORE_NUM	*	01				-1:0]		gt_pcs_rst					;
//	wire													gt_pcs_clk					;
	wire	[	IPCORE_NUM	*	LINK_WIDTH*4*8	-1:0]		gtrx_data					;	
	wire	[	IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_charisk				;
	wire	[	IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_chariscomma			;
	wire	[	IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_disperr				;
	wire	[	IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_notintable				;
	wire	[	IPCORE_NUM	*	LINK_WIDTH		-1:0]		gtrx_chanisaligned			;
	wire	[	IPCORE_NUM	*	01				-1:0]		gtrx_reset_req				;
	wire	[	IPCORE_NUM	*	LINK_WIDTH		-1:0]		gtrx_reset_done				;
	wire	[	IPCORE_NUM	*	01				-1:0]		gtrx_reset					;
	wire	[	IPCORE_NUM	*	01				-1:0]		gtrx_chanbonden				;
	wire	[	IPCORE_NUM	*	01				-1:0]		gtrx_align_rst				;

	//------------------------Body---------------------------

//	assign	controlled_force_reinit		=	{{IPCORE_NUM}{1'b0}}	;

	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_dat_info_wr			;
	wire	[	IPCORE_NUM	*			12	-1:0]		gtrx_dat_info_di			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_dat_info_af			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_dat_info_fu			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_dat_fifo_wr			;
	wire	[	IPCORE_NUM	*	GT_PHY_DW	-1:0]		gtrx_dat_fifo_di			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_dat_fifo_af			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_dat_fifo_fu			;
	
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_ksc_fifo_wr			;
	wire	[	IPCORE_NUM	*	GT_PHY_DW	-1:0]		gtrx_ksc_fifo_di			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_ksc_fifo_af			;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_ksc_fifo_fu			;

	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_pcs_tready				;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_pcs_tvalid				;
	wire	[	IPCORE_NUM	*			1	-1:0]		gtrx_pcs_tlast				;
	wire	[	IPCORE_NUM	*	GT_PHY_DW	-1:0]		gtrx_pcs_tdata				;
	wire	[	IPCORE_NUM	*			64	-1:0]		gtrx_pcs_tuser				;
	wire	[	IPCORE_NUM	*	GT_PHY_DW/8	-1:0]		gtrx_pcs_tkeep				;
	wire	[	IPCORE_NUM	*	GT_PHY_DW/8	-1:0]		gtrx_pcs_tstrb				;
	wire	[	IPCORE_NUM	*			4	-1:0]		gtrx_pcs_tdest				;
	wire	[	IPCORE_NUM	*			4	-1:0]		gtrx_pcs_tid				;

	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_data_tready	;
	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_data_tvalid	;
	wire	[	IPCORE_NUM	*	64			-1:0]			srgt_data_tdata		;
	wire	[	IPCORE_NUM	*	08			-1:0]			srgt_data_tkeep		;
	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_data_tlast		;
	wire	[	IPCORE_NUM	*	64			-1:0]			srgt_data_tuser		;

	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_k_sc_tready	;
	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_k_sc_tvalid	;
	wire	[	IPCORE_NUM	*	64			-1:0]			srgt_k_sc_tdata		;
	wire	[	IPCORE_NUM	*	08			-1:0]			srgt_k_sc_tkeep		;
	wire	[	IPCORE_NUM	*	01			-1:0]			srgt_k_sc_tlast		;
	wire	[	IPCORE_NUM	*	64			-1:0]			srgt_k_sc_tuser		;

	wire	[	IPCORE_NUM	*	32			-1:0]			gtrx_error_cnt		;
	wire	[	IPCORE_NUM	*	01			-1:0]			gtrx_error_or		;
	wire	[	IPCORE_NUM	*	LINK_WIDTH	-1:0]			gtxchanisaligned	;
	wire	[	IPCORE_NUM	*	01			-1:0]			idle2_detected		;
	wire	[	IPCORE_NUM	*	LINK_WIDTH	-1:0]			desc_verify_ok		;
	wire	[	IPCORE_NUM	*	LINK_WIDTH*4-1:0]			desc_verify_err_cnt	;


	//------------------------Instantiation------------------

	srio_gt_support
	#(
		.P_DEVICE_TYPE_R				(	P_DEVICE_TYPE_R			)	,
		.TCQ							(	TCQ						)	,
		.IPCORE_NUM						(	IPCORE_NUM				)	,
		.LINK_WIDTH						(	LINK_WIDTH				)	
	)                                                               	
	i_srio_gt_support                                    	
	(                                                               	
		.sys_clkp						(	sys_clkp				)	,
		.sys_clkn						(	sys_clkn				)	,
		.sys_rst						(	sys_rst					)	,
                                                                    	
		.srio_rxn						(	srio_rxn				)	,
		.srio_rxp						(	srio_rxp				)	,
		.srio_txn						(	srio_txn				)	,
		.srio_txp						(	srio_txp				)	,
                                                                    	
		.any_gtrxaligned				(	any_gtrxaligned			)	,
		.force_reinit					(	force_reinit	|	gtrx_align_rst		)	,
		.controlled_force_reinit		(	controlled_force_reinit	)	,
                                                                    	
		.	gt_rst						(	gt_rst					)	,
		.	gt_clk						(	gt_clk					)	,
		.log_rst						(	log_rst					)	,
		.log_clk						(	log_clk					)	,
		.phy_rst						(	phy_rst					)	,
		.phy_clk						(	phy_clk					)	,
		.gt_pcs_rst						(	gt_pcs_rst				)	,
		.gt_pcs_clk						(	gt_pcs_clk				)	,
		.gtrx_data						(	gtrx_data				)	,
		.gtrx_charisk					(	gtrx_charisk			)	,
		.gtrx_chariscomma				(	gtrx_chariscomma		)	,
		.gtrx_disperr					(	gtrx_disperr			)	,
		.gtrx_notintable				(	gtrx_notintable			)	,
                                                                    	
		.gtrx_chanisaligned				(	gtrx_chanisaligned		)	,
		.gtrx_reset_req					(	gtrx_reset_req			)	,
		.gtrx_reset_done				(	gtrx_reset_done			)	,
		.gtrx_reset						(	gtrx_reset				)	,
		.gtrx_chanbonden				(	gtrx_chanbonden			)	
	);

	genvar k;
genvar ii;
generate for(ii=0;ii<IPCORE_NUM;ii=ii+1)
begin : i_macgt
	
		srio_gtrx_pcs_itf	#(
			.	LINK_WIDTH		(	LINK_WIDTH	)	,					
			.	GT_PCS_DW		(	GT_PCS_DW	)	,					
			.	GT_PHY_DW		(	GT_PHY_DW	)						
		)i_srio_gtrx_pcs_itf(
			.	gt_pcs_rst			(	gt_pcs_rst																		)	,	//	input	wire											
			.	gt_pcs_clk			(	gt_pcs_clk																		)	,	//	input	wire											
			.	force_reinit		(	controlled_force_reinit	[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	gtrx_data			(	gtrx_data				[	ii		*	LINK_WIDTH*4*8	+:	LINK_WIDTH*4*8	]	)	,	//	input	wire	[	1		*	LINK_WIDTH*4*8	-1:0]	
			.	gtrx_charisk		(	gtrx_charisk			[	ii		*	LINK_WIDTH*4	+:	LINK_WIDTH*4	]	)	,	//	input	wire	[	1		*	LINK_WIDTH*4	-1:0]	
			.	gtrx_chariscomma	(	gtrx_chariscomma		[	ii		*	LINK_WIDTH*4	+:	LINK_WIDTH*4	]	)	,	//	input	wire	[	1		*	LINK_WIDTH*4	-1:0]	
			.	gtrx_disperr		(	gtrx_disperr			[	ii		*	LINK_WIDTH*4	+:	LINK_WIDTH*4	]	)	,	//	input	wire	[	1		*	LINK_WIDTH*4	-1:0]	
			.	gtrx_notintable		(	gtrx_notintable			[	ii		*	LINK_WIDTH*4	+:	LINK_WIDTH*4	]	)	,	//	input	wire	[	1		*	LINK_WIDTH*4	-1:0]	
			.	gtrx_chanisaligned	(	gtrx_chanisaligned		[	ii		*	LINK_WIDTH		+:	LINK_WIDTH		]	)	,	//	input	wire	[	1		*	LINK_WIDTH		-1:0]	
			.	gtrx_reset_done		(	gtrx_reset_done			[	ii		*	LINK_WIDTH		+:	LINK_WIDTH		]	)	,	//	input	wire	[	1		*	LINK_WIDTH		-1:0]	
			.	gtrx_reset_req		(	gtrx_reset_req			[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	gtrx_reset			(	gtrx_reset				[	ii		*		01			+:		01			]	)	,	//	output	wire											
			.	gtrx_chanbonden		(	gtrx_chanbonden			[	ii		*		01			+:		01			]	)	,	//	output	wire											
			.	gtrx_align_rst		(	gtrx_align_rst			[	ii		*		01			+:		01			]	)	,	//	output	wire											
			.	set_link_1x			(	set_link_1x				[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	any_gtrxaligned		(	any_gtrxaligned			[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	all_gtrxaligned		(	all_gtrxaligned			[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	gtrx_dat_info_wr	(	gtrx_dat_info_wr		[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	gtrx_dat_info_di	(	gtrx_dat_info_di		[	ii		*		12			+:		12			]	)	,	//	input	wire	[	1		*		01			-1:0]	
			.	gtrx_dat_info_af	(	gtrx_dat_info_af		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		01			-1:0]	
			.	gtrx_dat_info_fu	(	gtrx_dat_info_fu		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	gtrx_dat_fifo_wr	(	gtrx_dat_fifo_wr		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		08			-1:0]	
			.	gtrx_dat_fifo_di	(	gtrx_dat_fifo_di		[	ii		*	GT_PHY_DW		+:	GT_PHY_DW		]	)	,	//	input	wire	[	1		*		08			-1:0]	
			.	gtrx_dat_fifo_af	(	gtrx_dat_fifo_af		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		01			-1:0]	
			.	gtrx_dat_fifo_fu	(	gtrx_dat_fifo_fu		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		64			-1:0]	
	
			.	gtrx_ksc_fifo_wr	(	gtrx_ksc_fifo_wr		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		08			-1:0]	
			.	gtrx_ksc_fifo_di	(	gtrx_ksc_fifo_di		[	ii		*	GT_PHY_DW		+:	GT_PHY_DW		]	)	,	//	input	wire	[	1		*		08			-1:0]	
			.	gtrx_ksc_fifo_af	(	gtrx_ksc_fifo_af		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		01			-1:0]	
			.	gtrx_ksc_fifo_fu	(	gtrx_ksc_fifo_fu		[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	sopdat_match_cnt	(	sopdat_match_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	par_gtrx_sop_cnt	(	par_gtrx_sop_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	par_byte_kpd_cnt	(	par_byte_kpd_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	par_fifo_afu_cnt	(	par_fifo_afu_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	rmv_fifo_afu_cnt	(	rmv_fifo_afu_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	sft_gtrx_sop_cnt	(	sft_gtrx_sop_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	rmv_gtrx_sop_cnt	(	rmv_gtrx_sop_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	r1r_gtrx_kpd_cnt	(	r1r_gtrx_kpd_cnt		[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	gtrx_error_cnt		(	gtrx_error_cnt			[	ii		*		32			+:		32			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	gtrx_error_or		(	gtrx_error_or			[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	gtxchanisaligned	(	gtxchanisaligned		[	ii		*	LINK_WIDTH		+:	LINK_WIDTH		]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	idle2_detected		(	idle2_detected			[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	desc_verify_ok		(	desc_verify_ok			[	ii		*	LINK_WIDTH		+:	LINK_WIDTH		]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	desc_verify_err_cnt	(	desc_verify_err_cnt		[	ii		*	LINK_WIDTH*4	+:	LINK_WIDTH*4	]	)	,	//	input	wire	[	1		*		64			-1:0]	
			.	itf_rst				(	itf_rst																			)	,	//	input	wire	[	1		*		64			-1:0]	
			.	itf_clk				(	itf_clk																			)		//	input	wire	[	1		*		64			-1:0]	
		);


		srio_gtrx_axis	#(
			.	LINK_WIDTH		(	LINK_WIDTH	)	,						
			.	DW				(	GT_PHY_DW	)							
		)i_srio_gtrx_axis(
			.	gtrx_dat_info_wr	(	gtrx_dat_info_wr	[	ii		*		01			+:		01			]	)	,	//	input	wire											
			.	gtrx_dat_info_di	(	gtrx_dat_info_di	[	ii		*		12			+:		12			]	)	,	//	input	wire	[	1		*		01			-1:0]	
			.	gtrx_dat_info_af	(	gtrx_dat_info_af	[	ii		*		01			+:		01			]	)	,	//	input	wire	[	1		*		01			-1:0]	
			.	gtrx_dat_info_fu	(	gtrx_dat_info_fu	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		64			-1:0]	
			.	gtrx_dat_fifo_wr	(	gtrx_dat_fifo_wr	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		08			-1:0]	
			.	gtrx_dat_fifo_di	(	gtrx_dat_fifo_di	[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	)	,	//	input	wire	[	1		*		08			-1:0]	
			.	gtrx_dat_fifo_af	(	gtrx_dat_fifo_af	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		01			-1:0]	
			.	gtrx_dat_fifo_fu	(	gtrx_dat_fifo_fu	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		32			-1:0]	
			
			.	gtrx_ksc_fifo_wr	(	gtrx_ksc_fifo_wr	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		08			-1:0]	
			.	gtrx_ksc_fifo_di	(	gtrx_ksc_fifo_di	[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	)	,	//	input	wire	[	1		*		08			-1:0]	
			.	gtrx_ksc_fifo_af	(	gtrx_ksc_fifo_af	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		01			-1:0]	
			.	gtrx_ksc_fifo_fu	(	gtrx_ksc_fifo_fu	[	ii		*		01			+:		01			]	)	,	//	output	wire	[	1		*		32			-1:0]	

			.	srgt_iorx_tready	(	srgt_iorx_tready	[	ii		*		01			+:		01			]	)	,	//	output	wire										
			.	srgt_iorx_tvalid	(	srgt_iorx_tvalid	[	ii		*		01			+:		01			]	)	,	//	output	wire										
		    .	srgt_iorx_tlast		(	srgt_iorx_tlast		[	ii		*		01			+:		01			]	)	,   //	output	wire										
		    .	srgt_iorx_tdata		(	srgt_iorx_tdata		[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	)	,   //	output	wire	[	1	*	32		-1:0]			
		    .	srgt_iorx_tkeep		(	srgt_iorx_tkeep		[	ii		*		GT_PHY_DW/8	+:		GT_PHY_DW/8	]	)	,   //	output	wire										
		    .	srgt_iorx_tuser		(	srgt_iorx_tuser		[	ii		*		64			+:		64			]	)	,   //	output	wire	[	1	*	32		-1:0]		

//			.	gtrx_phy_tready		(	srgt_data_tready	[	ii		*		01			+:		01			]	)	,	//	output	wire										
//			.	gtrx_phy_tvalid		(	srgt_data_tvalid	[	ii		*		01			+:		01			]	)	,	//	output	wire										
//		    .	gtrx_phy_tlast		(	srgt_data_tlast		[	ii		*		01			+:		01			]	)	,   //	output	wire										
//		    .	gtrx_phy_tdata		(	srgt_data_tdata		[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	)	,   //	output	wire	[	1	*	32		-1:0]			
//		    .	gtrx_phy_tkeep		(	srgt_data_tkeep		[	ii		*		GT_PHY_DW/8	+:		GT_PHY_DW/8	]	)	,   //	output	wire										
//		    .	gtrx_phy_tuser		(	srgt_data_tuser		[	ii		*		64			+:		64			]	)	,   //	output	wire	[	1	*	32		-1:0]			
//
//			.	gtrx_ksc_tready		(	srgt_k_sc_tready	[	ii		*		01			+:		01			]	)	,	//	output	wire										
//			.	gtrx_ksc_tvalid		(	srgt_k_sc_tvalid	[	ii		*		01			+:		01			]	)	,	//	output	wire										
//		    .	gtrx_ksc_tlast		(	srgt_k_sc_tlast		[	ii		*		01			+:		01			]	)	,   //	output	wire										
//		    .	gtrx_ksc_tdata		(	srgt_k_sc_tdata		[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	)	,   //	output	wire	[	1	*	32		-1:0]			
//		    .	gtrx_ksc_tkeep		(	srgt_k_sc_tkeep		[	ii		*		GT_PHY_DW/8	+:		GT_PHY_DW/8	]	)	,   //	output	wire										
//		    .	gtrx_ksc_tuser		(	srgt_k_sc_tuser		[	ii		*		64			+:		64			]	)	,   //	output	wire	[	1	*	32		-1:0]			

			.	srgt_data_tcnt		(	srgt_data_tcnt		[	ii		*		32			+:		32			]	)	,   //	output	wire	[	1	*	32		-1:0]			
			.	srgt_k_sc_tcnt		(	srgt_k_sc_tcnt		[	ii		*		32			+:		32			]	)	,   //	output	wire	[	1	*	32		-1:0]			
		//	.	gtrx_error_or		(	gtrx_error_or		[	ii		*		1			+:		1			]	)	,   //	output	wire	[	1	*	32		-1:0]			
			.	gtrx_error_or		(	1'b0																		)	,   //	output	wire	[	1	*	32		-1:0]			
			.	c_gt_ksc_enab		(	c_gt_ksc_enab		[	ii		*		1			+:		1			]	)	,   //	output	wire	[	1	*	32		-1:0]			
			.	c_gt_dat_byps		(	c_gt_dat_byps		[	ii		*		1			+:		1			]	)	,   //	output	wire	[	1	*	32		-1:0]			
			.	itf_rst				(	itf_rst																		)	,   //	input	wire										
			.	itf_clk				(	itf_clk																		)	    //	input	wire										
		);
			
//		axis_comb#(
//			.	CH		(	2				)	,
//			.	DW		(	GT_PHY_DW		)	
//		)i_axis_comb(
//			.	axsr_tready		(	{	srgt_k_sc_tready	[	ii		*		01			+:		01			]	,	srgt_data_tready	[	ii		*		01			+:		01			]	}	)	,	//	output	wire	[	CH*	1		-	1	:	0	]	
//			.	axsr_tvalid		(	{	srgt_k_sc_tvalid	[	ii		*		01			+:		01			]	,	srgt_data_tvalid	[	ii		*		01			+:		01			]	}	)	,	//	input	wire	[	CH*	1		-	1	:	0	]	
//			.	axsr_tlast		(	{	srgt_k_sc_tlast		[	ii		*		01			+:		01			]	,	srgt_data_tlast		[	ii		*		01			+:		01			]	}	)	,	//	input	wire	[	CH*	1		-	1	:	0	]	
//			.	axsr_tdata		(	{	srgt_k_sc_tdata		[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	,	srgt_data_tdata		[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]	}	)	,	//	input	wire	[	CH*	DW		-	1	:	0	]	
//			.	axsr_tkeep		(	{	srgt_k_sc_tkeep		[	ii		*		GT_PHY_DW/8	+:		GT_PHY_DW/8	]	,	srgt_data_tkeep		[	ii		*		GT_PHY_DW/8	+:		GT_PHY_DW/8	]	}	)	,	//	input	wire	[	CH*	64		-	1	:	0	]	
//			.	axsr_tuser		(	{	srgt_k_sc_tuser		[	ii		*		64			+:		64			]	,	srgt_data_tuser		[	ii		*		64			+:		64			]	}	)	,	//	input	wire	[	CH*	DW/8	-	1	:	0	]	
//			.	axsr_tstrb		(	{	{{	GT_PHY_DW	/8	}{1'b0}}												,	{{	GT_PHY_DW	/8	}{1'b0}}												}	)	,	//	input	wire	[	CH*	DW/8	-	1	:	0	]	
//			.	axsr_tdest		(	{	{{		4			}{1'b0}}												,	{{		4			}{1'b0}}												}	)	,	//	input	wire	[	CH*	4		-	1	:	0	]	
//			.	axsr_tid		(	{	{{		4			}{1'b0}}												,	{{		4			}{1'b0}}												}	)	,	//	input	wire	[	CH*	4		-	1	:	0	]	
//			.	axst_tready		(		srgt_iorx_tready	[	ii		*		01			+:		01			]																						)	,	//	input	wire										
//			.	axst_tvalid		(		srgt_iorx_tvalid	[	ii		*		01			+:		01			]																						)	,	//	output	wire										
//			.	axst_tlast		(		srgt_iorx_tlast		[	ii		*		01			+:		01			]																						)	,	//	output	wire										
//			.	axst_tdata		(		srgt_iorx_tdata		[	ii		*		GT_PHY_DW	+:		GT_PHY_DW	]																						)	,	//	output	wire	[	DW		-	1	:	0	]		
//			.	axst_tkeep		(		srgt_iorx_tkeep		[	ii		*		GT_PHY_DW/8	+:		GT_PHY_DW/8	]																						)	,	//	output	wire	[	64		-	1	:	0	]		
//			.	axst_tuser		(		srgt_iorx_tuser		[	ii		*		64			+:		64			]																						)	,	//	output	wire	[	DW/8	-	1	:	0	]		
//			.	axst_tstrb		(																																										)	,	//	output	wire	[	DW/8	-	1	:	0	]		
//			.	axst_tdest		(																																										)	,	//	output	wire	[	4		-	1	:	0	]		
//			.	axst_tid		(																																										)	,	//	output	wire	[	4		-	1	:	0	]		
//			.	rst				(		itf_rst																																							)	,	//	input												
//			.	clk				(		itf_clk																																							)		//	input												
//		);


	assign	gtx_debug_signal	[ii*32+28+:04]	=	LINK_WIDTH	>=	4	?		desc_verify_err_cnt	[	ii	*		3*4		+:		1*4		]	:	4'b0	;
	assign	gtx_debug_signal	[ii*32+24+:04]	=	LINK_WIDTH	>=	3	?		desc_verify_err_cnt	[	ii	*		2*4		+:		1*4		]	:	4'b0	;
	assign	gtx_debug_signal	[ii*32+20+:04]	=	LINK_WIDTH	>=	2	?		desc_verify_err_cnt	[	ii	*		1*4		+:		1*4		]	:	4'b0	;
	assign	gtx_debug_signal	[ii*32+16+:04]	=	LINK_WIDTH	>=	0	?		desc_verify_err_cnt	[	ii	*		0*4		+:		1*4		]	:	4'b0	;
	assign	gtx_debug_signal	[ii*32+12+:04]	=	LINK_WIDTH	==	4	?		desc_verify_ok		[	ii	*	LINK_WIDTH	+:	LINK_WIDTH	]	:	{{{4-LINK_WIDTH}{1'b0}},	desc_verify_ok		[	ii	*	LINK_WIDTH	+:	LINK_WIDTH	]}	;
	assign	gtx_debug_signal	[ii*32+08+:04]	=	LINK_WIDTH	==	4	?		gtxchanisaligned	[	ii	*	LINK_WIDTH	+:	LINK_WIDTH	]	:	{{{4-LINK_WIDTH}{1'b0}},	gtxchanisaligned	[	ii	*	LINK_WIDTH	+:	LINK_WIDTH	]}	;
	assign	gtx_debug_signal	[ii*32+00+:08]	={	idle2_detected	[ii]	,	gtrx_error_cnt		[	ii	*		32		+:		07		]	};


end
endgenerate


//	`ifdef	DBG_ILA
//	wire	ila_clk	=	LINK_WIDTH	==	4	?	itf_clk	:	gt_pcs_clk	;
//		ila_288X1024 ila_288X1024_phy (
//			.	clk		(	ila_clk	)	,	// input wire clk
//			.	probe0	(	
//							{
//	
//								sft_gtrx_sop_cnt[00+:08]	,
//								rmv_gtrx_sop_cnt[00+:08]	,
//								par_gtrx_sop_cnt[00+:08]	,
//								par_byte_kpd_cnt[00+:08]	,
//								gtrx_data					,			
//								gtrx_charisk				,							
//
//								gtrx_dat_info_wr			,
//								gtrx_dat_info_di			,
//								gtrx_dat_info_af			,
//								gtrx_dat_info_fu			,
//								gtrx_dat_fifo_wr			,
//								gtrx_dat_fifo_di			,
//								gtrx_dat_fifo_af			,
//								gtrx_dat_fifo_fu			,
//								
//								gtrx_ksc_fifo_wr			,
//								gtrx_ksc_fifo_di			,
//								gtrx_ksc_fifo_af			,
//								gtrx_ksc_fifo_fu			,
//										
//								any_gtrxaligned				,
//								all_gtrxaligned				,
//								gtrx_disperr				,
//								gtrx_notintable				,
//								gtrx_chanisaligned			,
//								idle2_detected				,
//								desc_verify_ok				
//								
//							}	
//						)		// input wire [31:0] probe0
//		);
//	`endif
endmodule
