
//	`include "xr3000_top_MC02_BM_define.v"

module	xr3000_top_MC02_DMA	#(
//==================================================================================================
//--parameter Instantation
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	--------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"									,

	/*--------------------------------------------------------------------------------------
	--Version Information
	--------------------------------------------------------------------------------------*/
	parameter		P_Version1_R				= 32'h2020_0105								,
	parameter		P_Version2_R				= 32'h1425_1000								,

	/*--------------------------------------------------------------------------------------
	--SRIO Config
	--------------------------------------------------------------------------------------*/
	parameter		P_Srio_ID_WTH_R				= 16										,	//=8 or 16 ID
	parameter		P_Srio_CH_NUM_R				= 1		,	//	8		,	//				,	//SRIO IP Core number
	parameter		P_Srio_CH_LANE_R			= 4		,	//	1		,	//				,	//1=1x 2=2x 4=4x per srio IP
	parameter		P_Srio_SPEED_R				= 5 										,	//1=1Gbps 2=2.5Gbps 3=3.125Gbps 5=5Gbps 6=6Gbps(not support)
	parameter		P_Srio_PHY_LANE_R			= 8											,	//Physical lane number,board gtx for SRIO
	parameter		P_Srio_BANK_R				= 1											,	//physical bank
	parameter		P_BANK_LANE_R	 			= P_Srio_PHY_LANE_R/P_Srio_BANK_R			,	//per bank has lane num
	parameter		P_BANK_CH_NUM_R				= P_Srio_CH_NUM_R/P_Srio_BANK_R				,	//per bank has channnel num
	
	/*--------------------------------------------------------------------------------------
	--Board has ddr3 and use
	--------------------------------------------------------------------------------------*/	
`ifdef	DN_USER_DDR3
	parameter		P_Board_MEM_SIZE_R			= 32'h8000_0000								,	//2GB
`else
	parameter		P_Board_MEM_SIZE_R			= 32'hFFFF_FFFF								,	//Not support or not used
`endif
	
	/*--------------------------------------------------------------------------------------
	--AXI Lite Channel Config
	--------------------------------------------------------------------------------------*/
	parameter		P_AXILITE_CH_NUM_R			= P_Srio_BANK_R + 1 + 1						,	//BANK Num + PCIE Clock + FLash
	/*--------------------------------------------------------------------------------------
	--board cap register
	--------------------------------------------------------------------------------------*/
`ifdef	ENABLE_SIM_ONLY
	parameter		P_Srio_CAP_R				= 32'h0000_0000								,	//00=SIM Only;01=SIM+SRIO BM;10=GT BM;11=SRIO BM Only
`elsif	ENABLE_BM_ONLY
	parameter		P_Srio_CAP_R				= 32'h0000_0003								,
`elsif	ENABLE_BM_SIM
	parameter		P_Srio_CAP_R				= 32'h0000_0001								,
`else
	parameter		P_Srio_CAP_R				= 32'h0000_0000								,	//00=SIM Only;01=SIM+SRIO BM;10=GT BM;11=SRIO BM Only
`endif
	parameter		P_Srio_CH0_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h0									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH1_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h1									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH2_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h2									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH3_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h3									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH4_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h4									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH5_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h5									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH6_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h6									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,
	parameter		P_Srio_CH7_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h7									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											,


	/*--------------------------------------------------------------------------------------
	--PCIe DMA Config.
	--------------------------------------------------------------------------------------*/
`ifdef	ENABLE_SIM_ONLY
	parameter		P_DMA_UP_NUM_R				= P_Srio_CH_NUM_R							,	//SIM ONLY DMA=SRIO Chanel
	parameter		P_DMA_DN_NUM_R				= P_Srio_CH_NUM_R							,	//SIM ONLY DMA=SRIO Chanel
`elsif	ENABLE_BM_ONLY
	parameter		P_DMA_UP_NUM_R				= 1											,	//BM ONLY DMA=BM one channel
	parameter		P_DMA_DN_NUM_R				= 1											,	//DMA DN not used
`elsif	ENABLE_BM_SIM
	parameter		P_DMA_UP_NUM_R				= P_Srio_CH_NUM_R + 1						,	//BMSIM UP + 1
	parameter		P_DMA_DN_NUM_R				= P_Srio_CH_NUM_R							,	//DN keep SRIO Channel
`else
	parameter		P_DMA_UP_NUM_R				= P_Srio_CH_NUM_R							,	//=SIM Only
	parameter		P_DMA_DN_NUM_R				= P_Srio_CH_NUM_R							,	//=SIM Only
`endif
	
	parameter		P_BM_DMA_R					= FUN_BM_DMA(
														P_Srio_CH_NUM_R[7:0]				,
														0									,
														P_Srio_CAP_R[1:0])					,
														
	parameter		P_DMA_OFFSET_DSC_R			= "TRUE"									,
	parameter		P_DMA_Dpr_FIFO_NUM_R		= 1											,
	/*--------------------------------------------------------------------------------------
	--zt_cross config.
	--------------------------------------------------------------------------------------*/
	parameter		P_AXI_CHANNEL_R				= P_BANK_CH_NUM_R							,	//per bank has ony croos
	parameter		P_CH_LOW_BIT_R				= 12										,
	parameter		P_CH_Start_Addr_R			= 0											,
	
	
	
	parameter		PCIE_DW						=	256										,	//	C_DATA_WIDTH					
	parameter		EXT_PIPE_SIM				=	"FALSE"									,	//	EXT_PIPE_SIM					
	parameter		PCIE_LS						=	4										,	//	PL_LINK_CAP_MAX_LINK_SPEED		
	parameter		PCIE_LW						=	8										,	//	PL_LINK_CAP_MAX_LINK_WIDTH		
	parameter		SRIO_DW						=	64											//	SRIO AXIS DATA WIDTH					
)(

//	input				[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_aclk								,	//	input	[PR_UP_NUM*1-1  : 0]
//	input				[P_DMA_UP_NUM_R*DW-1:0]		dma_s_axis_tdata							,	//	input	[PR_UP_NUM*DW-1 : 0]
//	input				[P_DMA_UP_NUM_R*4-1	:0]		dma_s_axis_tid								,	//	input	[PR_UP_NUM*4-1  : 0]
//	output				[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tready							,	//	output	[PR_UP_NUM*1-1	: 0]
//	input				[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tvalid							,	//	input	[PR_UP_NUM*1-1	: 0]
//	input				[P_DMA_UP_NUM_R*8-1	:0]		dma_s_axis_tstrb							,	//	input	[PR_UP_NUM*8-1	: 0]
//	input				[P_DMA_UP_NUM_R*8-1	:0]		dma_s_axis_tkeep							,	//	input	[PR_UP_NUM*8-1	: 0]
//	input				[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tlast							,	//	input	[PR_UP_NUM*1-1	: 0]
//	input				[P_DMA_UP_NUM_R*64-1:0]		dma_s_axis_tuser							,	//	input	[PR_UP_NUM*64-1	: 0]
//	input				[P_DMA_UP_NUM_R*4-1	:0]		dma_s_axis_tdest							,	//	input	[PR_UP_NUM*4-1	: 0]
//    
//	input				[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_aclk								,	//	input	[PR_DN_NUM*1-1	: 0]
//	output				[P_DMA_DN_NUM_R*DW-1:0]		dma_m_axis_tdata							,	//  output	[PR_DN_NUM*DW-1	: 0]
//	output				[P_DMA_DN_NUM_R*4-1	:0]		dma_m_axis_tid								,	//  output	[PR_DN_NUM*4-1	: 0]
//	input				[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tready							,	//  input	[PR_DN_NUM*1-1	: 0]
//	output				[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tvalid							,	//  output	[PR_DN_NUM*1-1	: 0]
//	output				[P_DMA_DN_NUM_R*8-1	:0]		dma_m_axis_tstrb							,	//  output	[PR_DN_NUM*8-1	: 0]
//	output				[P_DMA_DN_NUM_R*8-1	:0]		dma_m_axis_tkeep							,	//  output	[PR_DN_NUM*8-1	: 0]
//	output				[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tlast							,	//  output	[PR_DN_NUM*1-1	: 0]
//	output				[P_DMA_DN_NUM_R*64-1:0]		dma_m_axis_tuser							,	//  output	[PR_DN_NUM*64-1	: 0]
//	output				[P_DMA_DN_NUM_R*4-1	:0]		dma_m_axis_tdest							,	//  output	[PR_DN_NUM*4-1	: 0]


	output	[	PCIE_LW	-	1	:	0]	pci_exp_txp											,
	output	[	PCIE_LW	-	1	:	0]	pci_exp_txn											,
	input	[	PCIE_LW	-	1	:	0]	pci_exp_rxp											,
	input	[	PCIE_LW	-	1	:	0]	pci_exp_rxn											,
	
	input								pcie_ref_clk_p										,
	input								pcie_ref_clk_n										,
	
	output	[	3		-	1	:	0]	led													,
	input								sys_rst_n		
);

		localparam			AXISTEN_IF_CQ_ALIGNMENT_MODE	=	"FALSE"				;
		localparam			AXISTEN_IF_RC_ALIGNMENT_MODE	=	"FALSE"				;
		localparam			AXISTEN_IF_RC_STRADDLE			=	0					;
		localparam			AXISTEN_IF_ENABLE_RX_MSG_INTFC	=	0					;
		localparam			AXISTEN_IF_RQ_ALIGNMENT_MODE	=	"FALSE"				;
		localparam			AXISTEN_IF_CC_ALIGNMENT_MODE	=	"FALSE"				;
		localparam			AXISTEN_IF_ENABLE_CLIENT_TAG	=	1					;
		localparam			AXISTEN_IF_RQ_PARITY_CHECK		=	0					;
		localparam			AXISTEN_IF_CC_PARITY_CHECK		=	0					;
		localparam	[17:0]	AXISTEN_IF_ENABLE_MSG_ROUTE		=	18'h2FFFF			;
		localparam			DW								=	PCIE_DW				;
		localparam			CQH_DW							=	32*4				;	//	axis_cq_* head bit
		localparam			CCH_DW							=	32*3				;
		localparam			RQH_DW							=	32*4				;
		localparam			RCH_DW							=	32*3				;

////////////////////	pcie ipcore	inerface ///////////////
		wire										m_axis_rc_tready							;
		wire										m_axis_rc_tvalid							;
		wire										m_axis_rc_tlast								;
		wire	[	DW			-	1	:	0	]	m_axis_rc_tdata								;
		wire	[	DW	/	32	-	1	:	0	]	m_axis_rc_tkeep								;
		wire	[	75			-	1	:	0	]	m_axis_rc_tuser								;
    
		wire										s_axis_cc_tvalid							;
		wire										s_axis_cc_tready							;
		wire	[	DW			-	1	:	0	]	s_axis_cc_tdata								;
		wire	[	DW	/	32	-	1	:	0	]	s_axis_cc_tkeep								;
		wire										s_axis_cc_tlast								;
		wire	[	33			-	1	:	0	]	s_axis_cc_tuser								;
		
		wire										s_axis_rq_tvalid							;
		wire										s_axis_rq_tready							;
		wire	[	DW			-	1	:	0	]	s_axis_rq_tdata								;
		wire	[	DW	/	32	-	1	:	0	]	s_axis_rq_tkeep								;
		wire										s_axis_rq_tlast								;
		wire	[	60			-	1	:	0	]	s_axis_rq_tuser								;
		
		wire	[	6			-	1	:	0	]  	pcie_rq_tag									;
		wire										pcie_rq_tag_vld								;
		wire	[	2			-	1	:	0	]  	pcie_rq_tag_av								;
		wire	[	2			-	1	:	0	]  	pcie_tfc_nph_av								;
		wire	[	2			-	1	:	0	]  	pcie_tfc_npd_av								;
		wire	[	4			-	1	:	0	]  	pcie_rq_seq_num								;
		wire										pcie_rq_seq_num_vld							;
    
		wire										m_axis_cq_tready							;
		wire										m_axis_cq_tvalid							;
		wire										m_axis_cq_tlast								;
		wire	[	DW			-	1	:	0	]	m_axis_cq_tdata								;
		wire	[	DW	/	32	-	1	:	0	]	m_axis_cq_tkeep								;
		wire	[	85			-	1	:	0	]	m_axis_cq_tuser								;
		wire	[	6			-	1	:	0	]	pcie_cq_np_req_count						;
		wire										pcie_cq_np_req								;

		wire	[3:0]								cfg_interrupt_msi_enable					;
		wire	[11:0]								cfg_interrupt_msi_mmenable					;
		wire	[31:0]								cfg_interrupt_msi_int						;
		wire										cfg_interrupt_msi_sent						;
		wire										cfg_interrupt_msi_fail						;
		wire	[01:0]								inter_req_cnt								;
		wire	[01:0]								inter_send_cnt								;
		wire	[01:0]								inter_fail_cnt								;
		wire	[31:0]								inter_int_latch								;

		wire			[2:0]						cfg_current_speed							;	
		wire			[3:0]						cfg_negotiated_width						;		
		wire										cfg_phy_link_down							;		
		wire			[1:0]						cfg_phy_link_status							;		

		wire										cfg_err_cor_out								;
		wire										cfg_err_nonfatal_out						;
		wire										cfg_err_fatal_out							;
		wire										cfg_local_error								;
		wire										user_lnk_up									;
		wire										phy_rdy_out									;
		
		wire										pcie_rst									;
		wire										pcie_clk									;
		
		
		wire			[2:0]						cfg_max_payload								;	//
		wire			[2:0]						cfg_max_read_req							;	//
		
		wire			[2:0]						pl_initial_link_width			=	3'b000	;	//	no used in pcie gen3
		wire										pl_link_gen2_cap				=	1'b0	;   //	no used in pcie gen3
		wire										pl_link_partner_gen2_supported	=	1'b0	;	//	no used in pcie gen3

////////////////////	pcie ipcore	inerface ///////////////	
		
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_aclk								;	//	input	[PR_UP_NUM*1-1  : 0]
		wire			[P_DMA_UP_NUM_R*DW-1:0]		dma_s_axis_tdata							;	//	input	[PR_UP_NUM*DW-1 : 0]
		wire			[P_DMA_UP_NUM_R*4-1	:0]		dma_s_axis_tid								;	//	input	[PR_UP_NUM*4-1  : 0]
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tready							;	//	output	[PR_UP_NUM*1-1	: 0]
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tvalid							;	//	input	[PR_UP_NUM*1-1	: 0]
		wire			[P_DMA_UP_NUM_R*DW/8-1	:0]	dma_s_axis_tstrb							;	//	input	[PR_UP_NUM*8-1	: 0]
		wire			[P_DMA_UP_NUM_R*DW/8-1	:0]	dma_s_axis_tkeep							;	//	input	[PR_UP_NUM*8-1	: 0]
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tlast							;	//	input	[PR_UP_NUM*1-1	: 0]
		wire			[P_DMA_UP_NUM_R*64-1:0]		dma_s_axis_tuser							;	//	input	[PR_UP_NUM*64-1	: 0]
		wire			[P_DMA_UP_NUM_R*4-1	:0]		dma_s_axis_tdest							;	//	input	[PR_UP_NUM*4-1	: 0]

		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_aclk								;	//	input	[PR_DN_NUM*1-1	: 0]
		wire			[P_DMA_DN_NUM_R*DW-1:0]		dma_m_axis_tdata							;	//  output	[PR_DN_NUM*DW-1	: 0]
		wire			[P_DMA_DN_NUM_R*4-1	:0]		dma_m_axis_tid								;	//  output	[PR_DN_NUM*4-1	: 0]
		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tready							;	//  input	[PR_DN_NUM*1-1	: 0]
		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tvalid							;	//  output	[PR_DN_NUM*1-1	: 0]
		wire			[P_DMA_DN_NUM_R*DW/8-1	:0]	dma_m_axis_tstrb							;	//  output	[PR_DN_NUM*8-1	: 0]
		wire			[P_DMA_DN_NUM_R*DW/8-1	:0]	dma_m_axis_tkeep							;	//  output	[PR_DN_NUM*8-1	: 0]
		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tlast							;	//  output	[PR_DN_NUM*1-1	: 0]
		wire			[P_DMA_DN_NUM_R*64-1:0]		dma_m_axis_tuser							;	//  output	[PR_DN_NUM*64-1	: 0]
		wire			[P_DMA_DN_NUM_R*4-1	:0]		dma_m_axis_tdest							;	//  output	[PR_DN_NUM*4-1	: 0]

		assign	dma_s_axis_aclk			=	{P_DMA_UP_NUM_R{pcie_clk}}							;	//	input	
		assign	dma_m_axis_aclk			=	{P_DMA_UP_NUM_R{pcie_clk}}							;	//	input	
////////////////	for axis loop simulator	///////////////

//	`define	EXT_SIMU
	`define	LOOP_SIMU
`ifdef	EXT_SIMU
	genvar	i;
	generate
		for(i=0;i<P_DMA_UP_NUM_R;i=i+1) begin: axst_loop
		axis_tx_simulator	#(
			.	UW	(	64	)	,
			.	DW	(	DW	)	
		)axis_tx_simulator(
			.	axst_tvalid		(	dma_s_axis_tvalid	[i*	1	+:	1	]	)	,	//	output	wire					
			.	axst_tready		(	dma_s_axis_tready	[i*	1	+:	1	]	)	,	//	input	wire					
			.	axst_tlast		(	dma_s_axis_tlast	[i*	1	+:	1	]	)	,	//	output	wire					
			.	axst_tdata		(	dma_s_axis_tdata	[i*	DW+:	DW	]	)	,	//	output	wire	[DW-1:0]		
			.	axst_tkeep		(	dma_s_axis_tkeep	[i*	DW/8+:	DW/8]	)	,	//	output	wire	[DW/8-1:0]		
			.	axst_tstrb		(	dma_s_axis_tstrb	[i*	DW/8+:	DW/8]	)	,	//	output	wire	[DW/8-1:0]		
			.	axst_tuser		(	dma_s_axis_tuser	[i*	64	+:	64	]	)	,	//	output	wire	[UW-1:0]		
			.	axst_tid		(	dma_s_axis_tid		[i*	4	+:	4	]	)	,	//	output	wire	[4-1:0]		
			.	axst_tdest		(	dma_s_axis_tdest	[i*	4	+:	4	]	)	,	//	output	wire	[4-1:0]		
			.	link_done		(	user_lnk_up								)	,	//	input							
			.	rst				(	pcie_rst								)	,	//	input							
			.	clk				(	pcie_clk								)		//	input							
		);
		end
	endgenerate
	
	assign	dma_m_axis_tready	=	{P_DMA_UP_NUM_R{1'b1}}		;
	
`elsif	LOOP_SIMU
		assign	dma_s_axis_tvalid		=		dma_m_axis_tvalid								;	//	input	
	//	assign	dma_s_axis_tready		=		dma_m_axis_tready								;	//	output	
		assign	dma_s_axis_tlast		=		dma_m_axis_tlast								;	//	input	
		assign	dma_s_axis_tdata		=		dma_m_axis_tdata								;	//	input	
		assign	dma_s_axis_tstrb		=		dma_m_axis_tstrb								;	//	input	
		assign	dma_s_axis_tkeep		=		dma_m_axis_tkeep								;	//	input	
		assign	dma_s_axis_tuser		=		dma_m_axis_tuser								;	//	input	
		assign	dma_s_axis_tdest		=		dma_m_axis_tdest								;	//	input	
		assign	dma_s_axis_tid			=		dma_m_axis_tid									;	//	input	


		assign	dma_m_axis_tready		=		dma_s_axis_tready								;	//	output	
`endif

////////////////	for axis loop simulator	///////////////



		wire			[32-1:0] 					pab_axi_awaddr								;	//	output			[32-1:0] 	
		wire			[ 3-1:0]					pab_axi_awprot								;	//	output			[3-1:0]		
		wire			[ 1-1:0]					pab_axi_awvalid								;	//	output			[1-1:0]		
		wire			[ 1-1:0]					pab_axi_awready		=1'b1					;	//	input			[1-1:0]		
		wire			[32-1:0]					pab_axi_wdata								;	//	output			[32-1:0]	
		wire			[ 4-1:0]					pab_axi_wstrb								;	//	output			[32/8-1:0]	
		wire			[ 1-1:0]					pab_axi_wvalid								;	//	output			[1-1:0]		
		wire			[ 1-1:0]					pab_axi_wready		=1'b1					;	//	input			[1-1:0]		
		wire			[ 2-1:0]					pab_axi_bresp		=2'b00					;	//	input			[2-1:0]	
		wire			[ 1-1:0]					pab_axi_bvalid		=1'b1					;	//	input			[1-1:0]	
		wire			[ 1-1:0]					pab_axi_bready								;	//	output			[1-1:0]	
		wire			[32-1:0]					pab_axi_araddr								;	//	output			[32-1:0]	
		wire			[ 3-1:0]					pab_axi_arprot								;	//	output			[3-1:0]		
		wire			[ 1-1:0]					pab_axi_arvalid								;	//	output			[1-1:0]		
		wire			[ 1-1:0]					pab_axi_arready		=1'b1					;	//	input			[1-1:0]		
		wire			[32-1:0]					pab_axi_rdata		=32'h0					;	//	input			[32-1:0]	
		wire			[ 2-1:0]					pab_axi_rresp		=2'b00					;	//	input			[2-1:0]		
		wire			[ 1-1:0]					pab_axi_rvalid		=1'b1					;	//	input			[1-1:0]		
		wire			[ 1-1:0]					pab_axi_rready								;	//	output			[1-1:0]		
		
		wire										interrupt_bus_clk		= pcie_clk			;	//input			[32-1:0]		
		wire										interrupt_bus_req		= 1'b0				;	//input			[2-1:0]			
		wire										interrupt_bus_gnt							;	//input			[1-1:0]			
		wire		[31:16]							interrupt_bus_vector	= 16'b0				;	//output			[1-1:0]			
		
		wire		[15:0]							pcie_far_id									;	//output			[1-1:0]			
		wire		[15:0]							pcie_dev_id									;	//output			[1-1:0]			
	
		wire										c_os_config								;	//output			[1-1:0]			
		wire										c_os_big_endian							;	//output			[1-1:0]			
		
	pcie3_dma_top	#(
		.	AXISTEN_IF_CQ_ALIGNMENT_MODE	(		AXISTEN_IF_CQ_ALIGNMENT_MODE	)	,
		.	AXISTEN_IF_RC_ALIGNMENT_MODE	(		AXISTEN_IF_RC_ALIGNMENT_MODE	)	,
		.	AXISTEN_IF_RC_STRADDLE			(		AXISTEN_IF_RC_STRADDLE			)	,
		.	AXISTEN_IF_ENABLE_RX_MSG_INTFC	(		AXISTEN_IF_ENABLE_RX_MSG_INTFC	)	,
		.	AXISTEN_IF_RQ_ALIGNMENT_MODE	(		AXISTEN_IF_RQ_ALIGNMENT_MODE	)	,		
		.	AXISTEN_IF_CC_ALIGNMENT_MODE	(		AXISTEN_IF_CC_ALIGNMENT_MODE	)	,		
		.	AXISTEN_IF_ENABLE_CLIENT_TAG	(		AXISTEN_IF_ENABLE_CLIENT_TAG	)	,		
		.	AXISTEN_IF_RQ_PARITY_CHECK		(		AXISTEN_IF_RQ_PARITY_CHECK		)	,		
		.	AXISTEN_IF_CC_PARITY_CHECK		(		AXISTEN_IF_CC_PARITY_CHECK		)	,
		.	AXISTEN_IF_ENABLE_MSG_ROUTE		(		AXISTEN_IF_ENABLE_MSG_ROUTE		)	,
		.	DW								(		DW								)	,
		.	CQH_DW							(		CQH_DW							)	,
		.	CCH_DW							(		CCH_DW							)	,
		.	RQH_DW							(		RQH_DW							)	,
		.	RCH_DW							(		RCH_DW							)	,
		.	PRJ_VERSION1					(		P_Version1_R					)	,
		.	PRJ_VERSION2					(		P_Version2_R					)	,       
		.	PR_SIM							(		P_SIMULATION_R					)	,
		.	PR_UP_NUM						(		P_DMA_UP_NUM_R					)	,
		.	PR_DN_NUM						(		P_DMA_DN_NUM_R					)	, 
		.	DMA_DPR_FIFO_NUM				(		P_DMA_Dpr_FIFO_NUM_R			)	,
		.	PR_OFFSET_DSC					(		P_DMA_OFFSET_DSC_R				)	        
	)pcie3_dma_top(
		.	user_lnk_up							(		user_lnk_up							)	,	//	input	wire										
		.	phy_rdy_out							(		phy_rdy_out							)	,	//	input	wire										
		.	m_axis_rc_tvalid					(		m_axis_rc_tvalid					)	,	//	input	wire										
		.	m_axis_rc_tready					(		m_axis_rc_tready					)	,	//	output	wire										
		.	m_axis_rc_tlast						(		m_axis_rc_tlast						)	,	//	input	wire										
		.	m_axis_rc_tdata						(		m_axis_rc_tdata						)	,	//	input	wire	[	DW			-	1	:	0	]	
		.	m_axis_rc_tkeep						(		m_axis_rc_tkeep						)	,	//	input	wire	[	DW	/	32	-	1	:	0	]	
		.	m_axis_rc_tuser						(		m_axis_rc_tuser						)	,	//	input	wire	[	75			-	1	:	0	]	
		.	s_axis_cc_tvalid					(		s_axis_cc_tvalid					)	,	//	output	wire										
		.	s_axis_cc_tready					(		s_axis_cc_tready					)	,	//	input	wire										
		.	s_axis_cc_tdata						(		s_axis_cc_tdata						)	,	//	output	wire	[	DW			-	1	:	0	]	
		.	s_axis_cc_tkeep						(		s_axis_cc_tkeep						)	,	//	output	wire	[	DW	/	32	-	1	:	0	]	
		.	s_axis_cc_tlast						(		s_axis_cc_tlast						)	,	//	output	wire										
		.	s_axis_cc_tuser						(		s_axis_cc_tuser						)	,	//	output	wire	[	33			-	1	:	0	]	
		.	s_axis_rq_tvalid					(		s_axis_rq_tvalid					)	,	//	output	wire										
		.	s_axis_rq_tready					(		s_axis_rq_tready					)	,	//	input	wire										
		.	s_axis_rq_tdata						(		s_axis_rq_tdata						)	,	//	output	wire	[	DW			-	1	:	0	]	
		.	s_axis_rq_tkeep						(		s_axis_rq_tkeep						)	,	//	output	wire	[	DW	/	32	-	1	:	0	]	
		.	s_axis_rq_tlast						(		s_axis_rq_tlast						)	,	//	output	wire										
		.	s_axis_rq_tuser						(		s_axis_rq_tuser						)	,	//	output	wire	[	60			-	1	:	0	]	
		.	pcie_rq_tag							(		pcie_rq_tag							)	,	//	input	wire	[	6			-	1	:	0	]	
		.	pcie_rq_tag_vld						(		pcie_rq_tag_vld						)	,	//	input	wire										
		.	pcie_rq_tag_av						(		pcie_rq_tag_av						)	,	//	input	wire	[	2			-	1	:	0	]	
		.	pcie_tfc_nph_av						(		pcie_tfc_nph_av						)	,	//	input	wire	[	2			-	1	:	0	]	
		.	pcie_tfc_npd_av						(		pcie_tfc_npd_av						)	,	//	input	wire	[	2			-	1	:	0	]	
		.	pcie_rq_seq_num						(		pcie_rq_seq_num						)	,	//	input	wire	[	4			-	1	:	0	]	
		.	pcie_rq_seq_num_vld					(		pcie_rq_seq_num_vld					)	,	//	input	wire										
		.	m_axis_cq_tvalid					(		m_axis_cq_tvalid					)	,	//	input	wire										
		.	m_axis_cq_tready					(		m_axis_cq_tready					)	,	//	output	wire										
		.	m_axis_cq_tlast						(		m_axis_cq_tlast						)	,	//	input	wire										
		.	m_axis_cq_tdata						(		m_axis_cq_tdata						)	,	//	input	wire	[	DW			-	1	:	0	]	
		.	m_axis_cq_tkeep						(		m_axis_cq_tkeep						)	,	//	input	wire	[	DW	/	32	-	1	:	0	]	
		.	m_axis_cq_tuser						(		m_axis_cq_tuser						)	,	//	input	wire	[	85			-	1	:	0	]	
		.	pcie_cq_np_req_count				(		pcie_cq_np_req_count				)	,	//	input	wire	[	6			-	1	:	0	]	
		.	pcie_cq_np_req						(		pcie_cq_np_req						)	,	//	output	wire										
		
		.	cfg_interrupt_msi_enable			(		cfg_interrupt_msi_enable[0]			)	,	//	input	wire										
		.	cfg_interrupt_msi_mmenable			(		cfg_interrupt_msi_mmenable[5:0]		)	,	//	input	wire	[5:0] 							
		.	cfg_interrupt_msi_sent				(		cfg_interrupt_msi_sent				)	,	//	input	wire           								
		.	cfg_interrupt_msi_fail				(		cfg_interrupt_msi_fail				)	,	//	input	wire           								
		.	cfg_interrupt_msi_int				(		cfg_interrupt_msi_int				)	,	//	output	reg		[31:0] 								
		.	inter_req_cnt						(		inter_req_cnt						)	,	//	output	reg		[01:0] 								
		.	inter_send_cnt						(		inter_send_cnt						)	,	//	output	reg		[01:0] 								
		.	inter_fail_cnt						(		inter_fail_cnt						)	,	//	output	reg		[01:0] 								
		.	inter_int_latch						(		inter_int_latch						)	,	//	output	reg		[31:0] 								
		.	max_pay_size						(		cfg_max_payload						)	,	//	input	wire	[	3			-	1	:	0	]	
		.	max_req_size						(		cfg_max_read_req					)	,	//	input	wire	[	3			-	1	:	0	]	
		.	cfg_current_speed					(		cfg_current_speed					)	,	//	input			[2:0]									
		.	cfg_negotiated_width				(		cfg_negotiated_width				)	,	// 	input			[3:0]									
		.	pl_initial_link_width				(		pl_initial_link_width				)	,	// 	input			[2:0]									
		.	pl_link_gen2_cap					(		pl_link_gen2_cap					)	,	// 	input													
		.	pl_link_partner_gen2_supported		(		pl_link_partner_gen2_supported		)	,	// 	input													
		.	dma_s_axis_aclk						(		dma_s_axis_aclk						)	,	//	input			[PR_UP_NUM*1-1  : 0]				
		.	dma_s_axis_tdata					(		dma_s_axis_tdata					)	,	//	input			[PR_UP_NUM*DW-1 : 0]				
		.	dma_s_axis_tid						(		dma_s_axis_tid						)	,	//	input			[PR_UP_NUM*4-1  : 0]				
		.	dma_s_axis_tready					(		dma_s_axis_tready					)	,	//	output			[PR_UP_NUM*1-1	: 0]				
		.	dma_s_axis_tvalid					(		dma_s_axis_tvalid					)	,	//	input			[PR_UP_NUM*1-1	: 0]				
		.	dma_s_axis_tstrb					(		dma_s_axis_tstrb					)	,	//	input			[PR_UP_NUM*8-1	: 0]				
		.	dma_s_axis_tkeep					(		dma_s_axis_tkeep					)	,	//	input			[PR_UP_NUM*8-1	: 0]				
		.	dma_s_axis_tlast					(		dma_s_axis_tlast					)	,	//	input			[PR_UP_NUM*1-1	: 0]				
		.	dma_s_axis_tuser					(		dma_s_axis_tuser					)	,	//	input			[PR_UP_NUM*64-1	: 0]				
		.	dma_s_axis_tdest					(		dma_s_axis_tdest					)	,	//	input			[PR_UP_NUM*4-1	: 0]				
		.	dma_m_axis_aclk						(		dma_m_axis_aclk						)	,	//	input			[PR_DN_NUM*1-1	: 0]				
		.	dma_m_axis_tdata					(		dma_m_axis_tdata					)	,	//	output			[PR_DN_NUM*DW-1	: 0]				
		.	dma_m_axis_tid						(		dma_m_axis_tid						)	,	//	output			[PR_DN_NUM*4-1	: 0]				
		.	dma_m_axis_tready					(		dma_m_axis_tready					)	,	//	input			[PR_DN_NUM*1-1	: 0]				
		.	dma_m_axis_tvalid					(		dma_m_axis_tvalid					)	,	//	output			[PR_DN_NUM*1-1	: 0]				
		.	dma_m_axis_tstrb					(		dma_m_axis_tstrb					)	,	//	output			[PR_DN_NUM*8-1	: 0]				
		.	dma_m_axis_tkeep					(		dma_m_axis_tkeep					)	,	//	output			[PR_DN_NUM*8-1	: 0]				
		.	dma_m_axis_tlast					(		dma_m_axis_tlast					)	,	//	output			[PR_DN_NUM*1-1	: 0]				
		.	dma_m_axis_tuser					(		dma_m_axis_tuser					)	,	//	output			[PR_DN_NUM*64-1	: 0]				
		.	dma_m_axis_tdest					(		dma_m_axis_tdest					)	,	//	output			[PR_DN_NUM*4-1	: 0]				
		.	dma_up_int_req						(	{P_DMA_UP_NUM_R{1'b0}}					)	,	//	input			[PR_UP_NUM*1-1	: 0]				
		.	dma_up_int_gnt						(											)	,	//	output			[PR_UP_NUM*1-1	: 0]				
		.	pab_axi_awaddr						(		pab_axi_awaddr						)	,	//	output			[32-1:0] 							
		.	pab_axi_awprot						(		pab_axi_awprot						)	,	//	output			[3-1:0]								
		.	pab_axi_awvalid						(		pab_axi_awvalid						)	,	//	output			[1-1:0]								
		.	pab_axi_awready						(		pab_axi_awready						)	,	//	input			[1-1:0]								
		.	pab_axi_wdata						(		pab_axi_wdata						)	,	//	output			[32-1:0]							
		.	pab_axi_wstrb						(		pab_axi_wstrb						)	,	//	output			[32/8-1:0]							
		.	pab_axi_wvalid						(		pab_axi_wvalid						)	,	//	output			[1-1:0]								
		.	pab_axi_wready						(		pab_axi_wready						)	,	//	input			[1-1:0]								
		.	pab_axi_bresp						(		pab_axi_bresp						)	,	//	input			[2-1:0]								
		.	pab_axi_bvalid						(		pab_axi_bvalid						)	,	//	input			[1-1:0]								
		.	pab_axi_bready						(		pab_axi_bready						)	,	//	output			[1-1:0]								
		.	pab_axi_araddr						(		pab_axi_araddr						)	,	//	output			[32-1:0]							
		.	pab_axi_arprot						(		pab_axi_arprot						)	,	//	output			[3-1:0]								
		.	pab_axi_arvalid						(		pab_axi_arvalid						)	,	//	output			[1-1:0]								
		.	pab_axi_arready						(		pab_axi_arready						)	,	//	input			[1-1:0]								
		.	pab_axi_rdata						(		pab_axi_rdata						)	,	//	input			[32-1:0]							
		.	pab_axi_rresp						(		pab_axi_rresp						)	,	//	input			[2-1:0]								
		.	pab_axi_rvalid						(		pab_axi_rvalid						)	,	//	input			[1-1:0]								
		.	pab_axi_rready						(		pab_axi_rready						)	,	//	output			[1-1:0]								
		.	interrupt_bus_clk					(		interrupt_bus_clk					)	,	//	input												
		.	interrupt_bus_req					(		interrupt_bus_req					)	,	//	input												
		.	interrupt_bus_gnt					(		interrupt_bus_gnt					)	,	//	output												
		.	interrupt_bus_vector				(		interrupt_bus_vector				)	,	//	input			[31:16]								
		.	c_os_config							(		c_os_config							)	,	//	output												
		.	c_os_big_endian						(		c_os_big_endian						)	,	//	output												
		.	pcie_far_id							(		pcie_far_id							)	,	//	output			[15:00]								
		.	pcie_dev_id							(		pcie_dev_id							)	,	//	output			[15:00]								
		.	rst									(		pcie_rst							)	,	//	input												
		.	clk									(		pcie_clk							)		//	input												
	);

	pcie3_ep_wrap	#	(
		.	C_DATA_WIDTH					(	PCIE_DW		)			,	//	RX/TX	interface	data	width
		.	EXT_PIPE_SIM					(	"FALSE"		)			,	//	This	Parameter	has	effect	on	selecting	Enable	External	PIPE	Interface	in	GUI.
		.	PL_LINK_CAP_MAX_LINK_SPEED		(	4			)			,	//	1-	GEN1,	2	-	GEN2,	4	-	GEN3
		.	PL_LINK_CAP_MAX_LINK_WIDTH		(	8			)				//	1-	X1,	2	-	X2,	4	-	X4,	8	-	X8
	)pcie3_ep_wrap(
		.	pci_exp_txp							(		pci_exp_txp							)	,	//	output	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1)	:	0]	
		.	pci_exp_txn							(		pci_exp_txn							)	,	//  output	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1)	:	0]	
		.	pci_exp_rxp							(		pci_exp_rxp							)	,	//  input	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1)	:	0]	
		.	pci_exp_rxn							(		pci_exp_rxn							)	,	//  input	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1)	:	0]	
		.	s_axis_rq_tlast						(		s_axis_rq_tlast						)	,	//  input	wire											
		.	s_axis_rq_tdata						(		s_axis_rq_tdata						)	,	//  input	wire		[C_DATA_WIDTH-1:0]					
		.	s_axis_rq_tuser						(		s_axis_rq_tuser						)	,	//  input	wire					[59:0]					
		.	s_axis_rq_tkeep						(		s_axis_rq_tkeep						)	,	//  input	wire		[KEEP_WIDTH-1:0]					
		.	s_axis_rq_tready					(		s_axis_rq_tready					)	,	//  output	wire											
		.	s_axis_rq_tvalid					(		s_axis_rq_tvalid					)	,	//  input	wire											
		.	m_axis_rc_tdata						(		m_axis_rc_tdata						)	,	//  output	wire		[C_DATA_WIDTH-1:0]					
		.	m_axis_rc_tuser						(		m_axis_rc_tuser						)	,	//  output	wire					[74:0]					
		.	m_axis_rc_tlast						(		m_axis_rc_tlast						)	,	//  output	wire											
		.	m_axis_rc_tkeep						(		m_axis_rc_tkeep						)	,	//  output	wire		[KEEP_WIDTH-1:0]					
		.	m_axis_rc_tvalid					(		m_axis_rc_tvalid					)	,	//  output	wire											
		.	m_axis_rc_tready					(		m_axis_rc_tready					)	,	//  input	wire											
		.	m_axis_cq_tdata						(		m_axis_cq_tdata						)	,	//  output	wire		[C_DATA_WIDTH-1:0]					
		.	m_axis_cq_tuser						(		m_axis_cq_tuser						)	,	//  output	wire					[84:0]					
		.	m_axis_cq_tlast						(		m_axis_cq_tlast						)	,	//  output	wire											
		.	m_axis_cq_tkeep						(		m_axis_cq_tkeep						)	,	//  output	wire		[KEEP_WIDTH-1:0]					
		.	m_axis_cq_tvalid					(		m_axis_cq_tvalid					)	,	//  output	wire											
		.	m_axis_cq_tready					(		m_axis_cq_tready					)	,	//  input	wire											
		.	s_axis_cc_tdata						(		s_axis_cc_tdata						)	,	//  input	wire		[C_DATA_WIDTH-1:0]					
		.	s_axis_cc_tuser						(		s_axis_cc_tuser						)	,	//  input	wire					[32:0]					
		.	s_axis_cc_tlast						(		s_axis_cc_tlast						)	,	//  input	wire											
		.	s_axis_cc_tkeep						(		s_axis_cc_tkeep						)	,	//  input	wire		[KEEP_WIDTH-1:0]					
		.	s_axis_cc_tvalid					(		s_axis_cc_tvalid					)	,	//  input	wire											
		.	s_axis_cc_tready					(		s_axis_cc_tready					)	,	//  output	wire											
		.	pcie_tfc_nph_av						(		pcie_tfc_nph_av						)	,	//  output	wire					[1:0]					
		.	pcie_tfc_npd_av						(		pcie_tfc_npd_av						)	,	//  output	wire					[1:0]					
		.	cfg_interrupt_msi_enable			(		cfg_interrupt_msi_enable			)	,	//	input					[3:0]					
		.	cfg_interrupt_msi_mmenable			(		cfg_interrupt_msi_mmenable			)	,	//	input					[11:0]					
		.	cfg_interrupt_msi_int				(		cfg_interrupt_msi_int				)	,	//	input					[31:0]					
		.	cfg_interrupt_msi_sent				(		cfg_interrupt_msi_sent				)	,	//	output											
		.	cfg_interrupt_msi_fail				(		cfg_interrupt_msi_fail				)	,	//	output																						
		.	pcie_rq_seq_num						(		pcie_rq_seq_num						)	,	//	output	wire					[3:0]					
		.	pcie_rq_seq_num_vld					(		pcie_rq_seq_num_vld					)	,	//	output	wire											
		.	pcie_rq_tag							(		pcie_rq_tag							)	,	//	output	wire					[5:0]					
		.	pcie_rq_tag_vld						(		pcie_rq_tag_vld						)	,	//	output	wire											
		.	pcie_rq_tag_av						(		pcie_rq_tag_av						)	,	//	output	wire					[1:0]					
		.	pcie_cq_np_req						(		pcie_cq_np_req						)	,	//	input	wire											
		.	pcie_cq_np_req_count				(		pcie_cq_np_req_count				)	,	//	output	wire					[5:0]					
		.	cfg_max_payload						(		cfg_max_payload						)	,	//	output	wire					[2:0]					
		.	cfg_max_read_req					(		cfg_max_read_req					)	,	//	output	wire					[2:0]					
		.	cfg_current_speed					(		cfg_current_speed					)	,	//	output	wire					[2:0]					
		.	cfg_negotiated_width				(		cfg_negotiated_width				)	,	//	output	wire					[3:0]					
		.	cfg_phy_link_down					(		cfg_phy_link_down					)	,	//	output	wire										
		.	cfg_phy_link_status					(		cfg_phy_link_status					)	,	//	output	wire					[1:0]					
		.	cfg_err_cor_out						(		cfg_err_cor_out						)	,	//	output	wire											
		.	cfg_err_nonfatal_out				(		cfg_err_nonfatal_out				)	,	//	output	wire											
		.	cfg_err_fatal_out					(		cfg_err_fatal_out					)	,	//	output	wire											
		.	cfg_local_error						(		cfg_local_error						)	,	//	output	wire											
		.	c_os_config							(		c_os_config							)	,	//		input										
		.	c_os_big_endian						(		c_os_big_endian						)	,	//		input										
		.	user_lnk_up							(		user_lnk_up							)	,	//	output	wire											
		.	phy_rdy_out							(		phy_rdy_out							)	,	//	output	wire																				
		.	user_clk							(		pcie_clk							)	,	//	output	wire											
		.	user_reset							(		pcie_rst							)	,	//	output	wire											
		.	sys_clk_p							(		pcie_ref_clk_p						)	,	//	input													
		.	sys_clk_n							(		pcie_ref_clk_n						)	,	//	input													
		.	sys_rst_n							(		sys_rst_n_c							)		//	input													
	);


	IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

	pcie_itf_dbg		#(
		.	DW								(		DW							)
	)pcie_itf_dbg(
		.	m_axis_rc_tready				(		m_axis_rc_tready			)	,	//		input										
		.	m_axis_rc_tvalid				(		m_axis_rc_tvalid			)	,	//		input										
		.	m_axis_rc_tlast					(		m_axis_rc_tlast				)	,	//		input										
		.	m_axis_rc_tdata					(		m_axis_rc_tdata				)	,	//		input	[	DW			-	1	:	0	]	
		.	m_axis_rc_tkeep					(		m_axis_rc_tkeep				)	,	//		input	[	DW	/	32	-	1	:	0	]	
		.	m_axis_rc_tuser					(		m_axis_rc_tuser				)	,	//		input	[	75			-	1	:	0	]	
		.	s_axis_cc_tvalid				(		s_axis_cc_tvalid			)	,	//		input										
		.	s_axis_cc_tready				(		s_axis_cc_tready			)	,	//		input										
		.	s_axis_cc_tdata					(		s_axis_cc_tdata				)	,	//		input	[	DW			-	1	:	0	]	
		.	s_axis_cc_tkeep					(		s_axis_cc_tkeep				)	,	//		input	[	DW	/	32	-	1	:	0	]	
		.	s_axis_cc_tlast					(		s_axis_cc_tlast				)	,	//		input										
		.	s_axis_cc_tuser					(		s_axis_cc_tuser				)	,	//		input	[	33			-	1	:	0	]	
		.	s_axis_rq_tvalid				(		s_axis_rq_tvalid			)	,	//		input										
		.	s_axis_rq_tready				(		s_axis_rq_tready			)	,	//		input										
		.	s_axis_rq_tdata					(		s_axis_rq_tdata				)	,	//		input	[	DW			-	1	:	0	]	
		.	s_axis_rq_tkeep					(		s_axis_rq_tkeep				)	,	//		input	[	DW	/	32	-	1	:	0	]	
		.	s_axis_rq_tlast					(		s_axis_rq_tlast				)	,	//		input										
		.	s_axis_rq_tuser					(		s_axis_rq_tuser				)	,	//		input	[	60			-	1	:	0	]	
		.	pcie_rq_tag						(		pcie_rq_tag					)	,	//		input	[	6			-	1	:	0	]  	
		.	pcie_rq_tag_vld					(		pcie_rq_tag_vld				)	,	//		input										
		.	pcie_rq_tag_av					(		pcie_rq_tag_av				)	,	//		input	[	2			-	1	:	0	]  	
		.	pcie_tfc_nph_av					(		pcie_tfc_nph_av				)	,	//		input	[	2			-	1	:	0	]  	
		.	pcie_tfc_npd_av					(		pcie_tfc_npd_av				)	,	//		input	[	2			-	1	:	0	]  	
		.	pcie_rq_seq_num					(		pcie_rq_seq_num				)	,	//		input	[	4			-	1	:	0	]  	
		.	pcie_rq_seq_num_vld				(		pcie_rq_seq_num_vld			)	,	//		input										
		.	m_axis_cq_tready				(		m_axis_cq_tready			)	,	//		input										
		.	m_axis_cq_tvalid				(		m_axis_cq_tvalid			)	,	//		input										
		.	m_axis_cq_tlast					(		m_axis_cq_tlast				)	,	//		input										
		.	m_axis_cq_tdata					(		m_axis_cq_tdata				)	,	//		input	[	DW			-	1	:	0	]	
		.	m_axis_cq_tkeep					(		m_axis_cq_tkeep				)	,	//		input	[	DW	/	32	-	1	:	0	]	
		.	m_axis_cq_tuser					(		m_axis_cq_tuser				)	,	//		input	[	85			-	1	:	0	]	
		.	pcie_cq_np_req_count			(		pcie_cq_np_req_count		)	,	//		input	[	6			-	1	:	0	]	
		.	pcie_cq_np_req					(		pcie_cq_np_req				)	,	//		input										
		.	cfg_interrupt_msi_enable		(		cfg_interrupt_msi_enable	)	,	//		input	[3:0]								
		.	cfg_interrupt_msi_mmenable		(		cfg_interrupt_msi_mmenable	)	,	//		input	[11:0]								
		.	cfg_interrupt_msi_int			(		cfg_interrupt_msi_int		)	,	//		input	[31:0]								
		.	cfg_interrupt_msi_sent			(		cfg_interrupt_msi_sent		)	,	//		input										
		.	cfg_interrupt_msi_fail			(		cfg_interrupt_msi_fail		)	,	//		input										
		.	inter_req_cnt					(		inter_req_cnt				)	,	//		input	[01:0]								
		.	inter_send_cnt					(		inter_send_cnt				)	,	//		input	[01:0]								
		.	inter_fail_cnt					(		inter_fail_cnt				)	,	//		input	[01:0]								
		.	inter_int_latch					(		inter_int_latch				)	,	//		input	[31:0]								
		.	cfg_current_speed				(		cfg_current_speed			)	,	//		input			[2:0]						
		.	cfg_negotiated_width			(		cfg_negotiated_width		)	,	//		input			[3:0]							
		.	cfg_phy_link_down				(		cfg_phy_link_down			)	,	//		input											
		.	cfg_phy_link_status				(		cfg_phy_link_status			)	,	//		input			[1:0]							
		.	cfg_err_cor_out					(		cfg_err_cor_out				)	,	//		input										
		.	cfg_err_nonfatal_out			(		cfg_err_nonfatal_out		)	,	//		input										
		.	cfg_err_fatal_out				(		cfg_err_fatal_out			)	,	//		input										
		.	cfg_local_error					(		cfg_local_error				)	,	//		input										
		.	user_lnk_up						(		user_lnk_up					)	,	//		input										
		.	phy_rdy_out						(		phy_rdy_out					)	,	//		input										
		.	cfg_max_payload					(		cfg_max_payload				)	,	//		input			[2:0]						
		.	cfg_max_read_req				(		cfg_max_read_req			)	,	//		input			[2:0]						
		.	led								(		led							)	,	//		output	[	3		-	1	:	0]	
		.	c_os_config						(		c_os_config					)	,	//		input										
		.	c_os_big_endian					(		c_os_big_endian				)	,	//		input										
		.	pcie_far_id						(		pcie_far_id					)	,	//		input										
		.	pcie_dev_id						(		pcie_dev_id					)	,	//		input										
		.	pcie_clk						(		pcie_clk					)	,	//		input										
		.	pcie_rst						(		pcie_rst					)		//		input										

	);

//--function定义
function	[7:0] FUN_BM_DMA;
	input	[7:0]	_ch_num;
	input	[7:0]	_ch;
	input	[1:0]	_cap;
	begin
		FUN_BM_DMA	= (_cap[1:0]==2'b00)?8'hFF		//不支持BM
					: (_cap[1:0]==2'b01)?_ch_num	//SIM+BM sim后的第一个通道作为BM DMA通道,_ch_num+1-1=ch_num
					: (_cap[1:0]==2'b10)?_ch		//GT模式下独立占用通道
					: 8'h00;						//Only SRIO BM,使用DMA通道0
	end
endfunction

function	[31:0] FUNC_CH_CAP;
	input	[7:0]	_ch_num;
	input	[7:0]	_ch;
	input	[7:0]	_cap;
	input	[7:0]	_x;
	reg		[7:0]	bm_dma;
	reg		[7:0]	sim_dma;
	reg		[7:0]	cap;
	begin
		bm_dma		= FUN_BM_DMA(_ch_num[7:0],_ch,_cap[1:0]);
		sim_dma		= (_ch_num>_ch)?(_cap[1]==1'b0)?_ch:8'hFF:8'hFF;	//8'h00为DMA通道 CH1=DMA Ch1
		FUNC_CH_CAP	= (_ch_num<=_ch)?32'hFFFF_FFFF:{bm_dma[7:0],sim_dma[7:0],_x[7:0],_cap[7:0]};
	end
endfunction

endmodule