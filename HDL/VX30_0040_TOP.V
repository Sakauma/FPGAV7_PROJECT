`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		DuCHaoMing
//
// Create Date:		2014/6/12 9:49:39
// Design Name:
// Module Name:		module_name.v
// Project Name:
// Target Devices:	XC7Z045FFG600-2L
// Tool versions:	ISE 14.6 or Vivado
// Description:
//
// Dependencies:
//
// Top File:
//
// Inst File：
//
// Revision:
//
////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

//	`include "Global_define.v"
//////////////////////////////////////////////////////////////////////////////////////////////////
 module	LTVX30_0040_TOP	#(
//==================================================================================================
//--parameter Instantation
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	--------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"									,

	/*--------------------------------------------------------------------------------------
	--Version Information
	--------------------------------------------------------------------------------------*/
	parameter		P_Version1_R				= 32'h2026_0416								,
	parameter		P_Version2_R				= 32'h1220_3010								,

	/*--------------------------------------------------------------------------------------
	--SRIO Config
	--------------------------------------------------------------------------------------*/
	parameter		P_Srio_ID_WTH_R				=	`SRIO_ID								,	//=8 or 16 ID
	parameter		P_Srio_CH_NUM_R				=	`SRIO_PHY_LANE	/	`SRIO_CH_LANE		,	//SRIO IP Core number
	parameter		P_Srio_CH_LANE_R			=	`SRIO_CH_LANE							,	//1=1x 2=2x 4=4x per srio IP
	parameter		P_Srio_SPEED_R				=	`SRIO_SPEED								,	//1=1Gbps 2=2.5Gbps 3=3.125Gbps 5=5Gbps 6=6Gbps(not support)
	parameter		P_Srio_PHY_LANE_R			=	`SRIO_PHY_LANE							,	//Physical lane number,board gtx for SRIO
	parameter		P_Srio_BANK_R				=	`SRIO_PHY_LANE	/	`LANE_IN_BANK		,	//physical bank
	parameter		P_BANK_LANE_R	 			=	P_Srio_PHY_LANE_R/P_Srio_BANK_R			,	//per bank has lane num
	parameter		P_BANK_CH_NUM_R				=	P_Srio_CH_NUM_R/P_Srio_BANK_R			,	//per bank has channnel num

	parameter		PCIE_DW						=	256									,	//	C_DATA_WIDTH
	parameter		EXT_PIPE_SIM				=	"FALSE"									,	//	EXT_PIPE_SIM
	parameter		PCIE_LS						=	4										,	//	PL_LINK_CAP_MAX_LINK_SPEED
	parameter		PCIE_LW						=	4										,	//	PL_LINK_CAP_MAX_LINK_WIDTH
	parameter		SRIO_DW						= 	64										,	//	SRIO AXIS DATA WIDTH
	parameter		VIDEO_DMA_CH				= 	1										,
	parameter		VIDEO_FRAME_WIDTH			= 	1920									,
	parameter		VIDEO_FRAME_HEIGHT		= 	1080									,
	parameter		VIDEO_OVERLAP_WIDTH		= 	1920									,
	parameter		VIDEO_RAW10_SHIFT		= 	6										,
	parameter		VIDEO_DUP_SRIO0_ENABLE	= 	1									,
	parameter		VIDEO_TEST_PATTERN_ENABLE = 	1
)(
//==================================================================================================
//--Port Defines

	/*------System Clock and Reset-------*/
 	input										ext_clk										,
	input										sys_rst_n									,

	/*------PCIe Link Port--------*/
	input										pcie_ref_clk_p								,
	input										pcie_ref_clk_n								,

	output			[	PCIE_LW	-	1	:	0]	pci_exp_txp									,
	output			[	PCIE_LW	-	1	:	0]	pci_exp_txn									,
	input			[	PCIE_LW	-	1	:	0]	pci_exp_rxp									,
	input			[	PCIE_LW	-	1	:	0]	pci_exp_rxn									,

	input           							teng_refclk_p    								,  // 156.25m
	input           							teng_refclk_n    								,
	output          							teng_txp         								,
	output          							teng_txn         								,
	input           							teng_rxp         								,
	input           							teng_rxn                      					,


	/*--------------------------------------------------------------------------------------
	--SRIO Link Port
	--------------------------------------------------------------------------------------*/
  	input			[P_Srio_BANK_R	-1:0]		srio_sys_clk_p_125							,
  	input			[P_Srio_BANK_R	-1:0]		srio_sys_clk_n_125							,
  	input			[P_BANK_LANE_R	-1:0]		srio_sys_clk_p_156							,
  	input			[P_BANK_LANE_R	-1:0]		srio_sys_clk_n_156							,

  	input			[P_Srio_PHY_LANE_R	-1:0]	srio_rxn0									,
  	input			[P_Srio_PHY_LANE_R	-1:0]	srio_rxp0									,
  	output			[P_Srio_PHY_LANE_R	-1:0]	srio_txn0									,
  	output			[P_Srio_PHY_LANE_R	-1:0]	srio_txp0									,

	/*--------------------------------------------------------------------------------------
	--debug led
	--------------------------------------------------------------------------------------*/
`ifdef DN_USER_DDR3
	/*--------------------------------------------------------------------------------------
	--DDR3 Signlas
	--------------------------------------------------------------------------------------*/
	input										ddr3_sys_clk_p								,
	input										ddr3_sys_clk_n								,
	output			[15:0]						DDR3_0_addr									,
	output			[2:0]						DDR3_0_ba									,
	output										DDR3_0_cas_n								,
	output			[0:0]						DDR3_0_ck_n									,
	output			[0:0]						DDR3_0_ck_p									,
	output			[0:0]						DDR3_0_cke									,
	output			[0:0]						DDR3_0_cs_n									,
	output			[3:0]						DDR3_0_dm									,
	inout			[31:0]						DDR3_0_dq									,
	inout			[3:0]						DDR3_0_dqs_n								,
	inout			[3:0]						DDR3_0_dqs_p								,
	output			[0:0]						DDR3_0_odt									,
	output										DDR3_0_ras_n								,
	output										DDR3_0_reset_n								,
	output										DDR3_0_we_n									,
`endif
	/*--------------------------------------------------------------------------------------
	--QSPI flash
	--------------------------------------------------------------------------------------*/
//	input										EMCCLK										,
`ifdef		KU
	inout			[3:0]						spi_1_dq									,
	inout										spi_1_ss									,
	inout			[3:0]						spi_0_dq									,
	inout										spi_0_ss									,
`else
    inout			[1:0]						spi_0_dq									,
    inout										spi_0_ss
`endif
	/*------Other Ports-------*/
//	output			[ 2:0]						led
);


	/*--------------------------------------------------------------------------------------
	--FPGA TYPE
	--------------------------------------------------------------------------------------*/
`ifdef	KU	parameter		P_DEVICE_TYPE_R			= "XLNX_KU"							;
`elsif	V7	parameter		P_DEVICE_TYPE_R			= "XLNX_V7"							;
`elsif	K7	parameter		P_DEVICE_TYPE_R			= "XLNX_K7"							;
`endif

	/*--------------------------------------------------------------------------------------
	--Board has ddr3 and use
	--------------------------------------------------------------------------------------*/
`ifdef	DN_USER_DDR3
	parameter		P_Board_MEM_SIZE_R			= 32'h8000_0000								;	//2GB
`else
	parameter		P_Board_MEM_SIZE_R			= 32'hFFFF_FFFF								;	//Not support or not used
`endif

	/*--------------------------------------------------------------------------------------
	--AXI Lite Channel Config
	--------------------------------------------------------------------------------------*/
	parameter		P_AXILITE_CH_NUM_R			= P_Srio_BANK_R + 1 + 1						;	//BANK Num + PCIE Clock + FLash
	/*--------------------------------------------------------------------------------------
	--board cap register
	--------------------------------------------------------------------------------------*/
`ifdef	ENABLE_SIM_ONLY
	parameter		P_Srio_CAP_R				= 32'h0000_0000								;	//00=SIM Only;01=SIM+SRIO BM;10=GT BM;11=SRIO BM Only
`elsif	ENABLE_BM_ONLY
	parameter		P_Srio_CAP_R				= 32'h0000_0003								;
`elsif	ENABLE_BM_SIM
	parameter		P_Srio_CAP_R				= 32'h0000_0001								;
`elsif	ENABLE_GT_ONLY
	parameter		P_Srio_CAP_R				= 32'h0000_0002								;
`elsif	ENABLE_INJECT_ONLY
	parameter		P_Srio_CAP_R				= 32'h0000_0004								;
`elsif	ENABLE_GT_INJECT
	parameter		P_Srio_CAP_R				= 32'h0000_0005								;
`else
	parameter		P_Srio_CAP_R				= 32'h0000_0000								;	//00=SIM Only;01=SIM+SRIO BM;10=GT BM;11=SRIO BM Only
`endif
	parameter		P_Srio_CH0_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h0									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH1_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h1									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH2_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h2									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH3_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h3									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH4_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h4									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH5_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h5									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH6_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h6									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;
	parameter		P_Srio_CH7_R				= FUNC_CH_CAP
												(
													P_Srio_CH_NUM_R[7:0]					,
													8'h7									,
													P_Srio_CAP_R[7:0]						,
													P_Srio_CH_LANE_R[7:0]
												)											;


	/*--------------------------------------------------------------------------------------
	--PCIe DMA Config.
	--------------------------------------------------------------------------------------*/
`ifdef	ENABLE_SIM_ONLY
	parameter		P_DMA_UP_NUM_R				= P_Srio_CH_NUM_R							;	//SIM ONLY DMA=SRIO Chanel
	parameter		P_DMA_DN_NUM_R				= P_Srio_CH_NUM_R							;	//SIM ONLY DMA=SRIO Chanel
`elsif	ENABLE_BM_ONLY
	parameter		P_DMA_UP_NUM_R				= 1											;	//BM ONLY DMA=BM one channel
	parameter		P_DMA_DN_NUM_R				= 1											;	//DMA DN not used
`elsif	ENABLE_GT_ONLY
	parameter		P_DMA_UP_NUM_R				= 1											;	//BM ONLY DMA=BM one channel
	parameter		P_DMA_DN_NUM_R				= 1											;	//DMA DN not used
`elsif	ENABLE_BM_SIM
	parameter		P_DMA_UP_NUM_R				= P_Srio_CH_NUM_R + 1						;	//BMSIM UP + 1
	parameter		P_DMA_DN_NUM_R				= P_Srio_CH_NUM_R							;	//DN keep SRIO Channel
`else
	parameter		P_DMA_UP_NUM_R				= P_Srio_CH_NUM_R							;	//=SIM Only
	parameter		P_DMA_DN_NUM_R				= P_Srio_CH_NUM_R							;	//=SIM Only
`endif

	parameter		P_BM_DMA_R					= FUN_BM_DMA(
														P_Srio_CH_NUM_R[7:0]				,
														0									,
														P_Srio_CAP_R[1:0])					;

	parameter		P_DMA_OFFSET_DSC_R			= "TRUE"									;
	parameter		P_DMA_DPR_FIFO_NUM_R		= 1											;
	/*--------------------------------------------------------------------------------------
	--zt_cross config.
	--------------------------------------------------------------------------------------*/
	parameter		P_AXI_CHANNEL_R				= P_BANK_CH_NUM_R							;	//per bank has ony croos
	parameter		P_CH_LOW_BIT_R				= 12										;
	parameter		P_CH_Start_Addr_R			= 0											;


////////////////////	localparam ///////////////
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

		localparam			PCIE_FREQ_MHZ		=	PCIE_LS	==	4	?	8000	*	10/10	*	PCIE_LW	/	PCIE_DW	:	//	GEN	3
													PCIE_LS	==	2	?	5000	*	8/10	*	PCIE_LW	/	PCIE_DW	:	//	GEN	2
																		2500	*	8/10	*	PCIE_LW	/	PCIE_DW	;	//	GEN	1



		wire										vio_rst										;
		wire										pcie_rst									;
		wire										pcie_clk									;
		wire										user_lnk_up									;
		wire										phy_rdy_out									;



//==================================================================================================
//--信号定义
	/*--------------------------------------------------------------------------------------
	--DMA Channel AXI Stream Inteface
	--------------------------------------------------------------------------------------*/
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_aclk								;
		wire			[P_DMA_UP_NUM_R*DW-1:0]		dma_s_axis_tdata							;
		wire			[P_DMA_UP_NUM_R*4-1	:0]		dma_s_axis_tid								;
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tready							;
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tvalid							;
		wire			[P_DMA_UP_NUM_R*DW/8-1	:0]	dma_s_axis_tstrb							;
		wire			[P_DMA_UP_NUM_R*DW/8-1	:0]	dma_s_axis_tkeep							;
		wire			[P_DMA_UP_NUM_R*1-1	:0]		dma_s_axis_tlast							;
		wire			[P_DMA_UP_NUM_R*64-1:0]		dma_s_axis_tuser							;
		wire			[P_DMA_UP_NUM_R*4-1	:0]		dma_s_axis_tdest							;

		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_aclk								;
		wire			[P_DMA_DN_NUM_R*DW-1:0]		dma_m_axis_tdata							;
		wire			[P_DMA_DN_NUM_R*4-1	:0]		dma_m_axis_tid								;
		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tready							;
		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tvalid							;
		wire			[P_DMA_DN_NUM_R*DW/8-1	:0]	dma_m_axis_tstrb							;
		wire			[P_DMA_DN_NUM_R*DW/8-1	:0]	dma_m_axis_tkeep							;
		wire			[P_DMA_DN_NUM_R*1-1	:0]		dma_m_axis_tlast							;
		wire			[P_DMA_DN_NUM_R*64-1:0]		dma_m_axis_tuser							;
		wire			[P_DMA_DN_NUM_R*4-1	:0]		dma_m_axis_tdest							;

		assign	dma_s_axis_aclk			=	{P_DMA_UP_NUM_R{pcie_clk}}							;	//	sysc	to pcei	user_clk
		assign	dma_m_axis_aclk			=	{P_DMA_DN_NUM_R{pcie_clk}}							;	//	sysc	to pcei	user_clk

`ifdef	DN_USER_DDR3
		wire			[P_DMA_DN_NUM_R*1-1	:0]		zt_dma_m_axis_aclk							;
		wire			[P_DMA_DN_NUM_R*64-1:0]		zt_dma_m_axis_tdata							;
		wire			[P_DMA_DN_NUM_R*4-1	:0]		zt_dma_m_axis_tid							;
		wire			[P_DMA_DN_NUM_R*1-1	:0]		zt_dma_m_axis_tready						;
		wire			[P_DMA_DN_NUM_R*1-1	:0]		zt_dma_m_axis_tvalid						;
		wire			[P_DMA_DN_NUM_R*8-1	:0]		zt_dma_m_axis_tstrb							;
		wire			[P_DMA_DN_NUM_R*8-1	:0]		zt_dma_m_axis_tkeep							;
		wire			[P_DMA_DN_NUM_R*1-1	:0]		zt_dma_m_axis_tlast							;
		wire			[P_DMA_DN_NUM_R*64-1:0]		zt_dma_m_axis_tuser							;
		wire			[P_DMA_DN_NUM_R*4-1	:0]		zt_dma_m_axis_tdest							;
`endif

	/*-----PCIE AXI Lite Master Interface----*/
		wire			[32-1:0] 					pab_axi_awaddr								;	//				output			[32-1:0]
		wire			[ 3-1:0]					pab_axi_awprot								;	//				output			[3-1:0]
		wire			[ 1-1:0]					pab_axi_awvalid								;	//				output			[1-1:0]
		wire			[ 1-1:0]					pab_axi_awready								;	//	=1'b1		input			[1-1:0]
		wire			[32-1:0]					pab_axi_wdata								;	//				output			[32-1:0]
		wire			[ 4-1:0]					pab_axi_wstrb								;	//				output			[32/8-1:0]
		wire			[ 1-1:0]					pab_axi_wvalid								;	//				output			[1-1:0]
		wire			[ 1-1:0]					pab_axi_wready								;	//	=1'b1		input			[1-1:0]
		wire			[ 2-1:0]					pab_axi_bresp								;	//	=2'b00		input			[2-1:0]
		wire			[ 1-1:0]					pab_axi_bvalid								;	//	=1'b1		input			[1-1:0]
		wire			[ 1-1:0]					pab_axi_bready								;	//				output			[1-1:0]
		wire			[32-1:0]					pab_axi_araddr								;	//				output			[32-1:0]
		wire			[ 3-1:0]					pab_axi_arprot								;	//				output			[3-1:0]
		wire			[ 1-1:0]					pab_axi_arvalid								;	//				output			[1-1:0]
		wire			[ 1-1:0]					pab_axi_arready								;	//	=1'b1		input			[1-1:0]
		wire			[32-1:0]					pab_axi_rdata								;	//	=32'h0		input			[32-1:0]
		wire			[ 2-1:0]					pab_axi_rresp								;	//	=2'b00		input			[2-1:0]
		wire			[ 1-1:0]					pab_axi_rvalid								;	//	=1'b1		input			[1-1:0]
		wire			[ 1-1:0]					pab_axi_rready								;	//				output			[1-1:0]




//==================================================================================================
//--SRIO信号定义
	/*--------------------------------------------------------------------------------------
	-- all clocks as out
	--------------------------------------------------------------------------------------*/
	wire            [P_Srio_BANK_R-1:0]			log_clk	   									;	// LOG interface clock
	wire            [P_Srio_BANK_R-1:0]			phy_clk		   								;	// PHY interface clock
	wire            [P_Srio_BANK_R-1:0]			gt_clk_out    								;
	wire            [P_Srio_BANK_R-1:0]			gt_pcs_clk									;	// GT fabric interface clock
	wire            [P_Srio_BANK_R-1:0]			drpclk	    								;
	wire            [P_Srio_BANK_R-1:0]			refclk	    								;
	wire			[P_Srio_BANK_R-1:0]			clk_lock	  								;
	wire										xgmii_clk									;
	//wire			[P_Srio_CH_NUM_R-1:0]		sp_log_clk									;
	/*--------------------------------------------------------------------------------------
	--all resets as out
	--------------------------------------------------------------------------------------*/
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_log_rst		   						;	// Reset for LOG clock Domain
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_phy_rst		   						;	// Reset for PHY clock Domain
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_buf_rst		   						;
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_cfg_rst		   						;
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_gt_pcs_rst								;

	/*--------------------------------------------------------------------------------------
	-- QPLL outputs
	--------------------------------------------------------------------------------------*/
//	wire            [P_Srio_BANK_R-1:0]			gt0_qpll_clk	       						;
//	wire            [P_Srio_BANK_R-1:0]			gt0_qpll_out_refclk							;

	wire             							sim_train_en				= 0				;	// Reduce timers for inialization for simulation
	/*--------------------------------------------------------------------------------------
	--PHY control signals
	--------------------------------------------------------------------------------------*/
	wire            [P_Srio_CH_NUM_R* 1-1:0] 	srio_force_reinit							;	// Force reinitialization	//2018/11/16 14:45:05 Link Reset
	wire            [P_Srio_CH_NUM_R* 1-1:0] 	srio_phy_mce				= 0				;	// Send MCE control symbol
	wire            [P_Srio_CH_NUM_R* 1-1:0] 	srio_phy_link_reset			= 0				;	// Send link reset control symbols

	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_phy_rcvd_mce							;	// MCE control symbol received
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_phy_rcvd_link_reset					;	// Received 4 consecutive reset symbols
	wire     		[P_Srio_CH_NUM_R*224-1:0]	srio_phy_debug								;	// Useful debug signals
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_gtrx_disperr_or						;	// GT disparity error (reduce ORed)
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_gtrx_notintable_or						;	// GT not in table error (reduce ORed)

	/*--------------------------------------------------------------------------------------
	--side bank signals
	--------------------------------------------------------------------------------------*/

	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_port_error                   			;	// In Port Error State
	wire 		  	[P_Srio_CH_NUM_R*24-1:0]	srio_port_timeout                 			;	// Timeout occurred
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_srio_host                    			;	// Endpoint is the system host
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_port_decode_error            			;	// No valid output port for the RX transaction
	wire			[P_Srio_CH_NUM_R*16-1:0]	srio_deviceid                     			;	// Device ID
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_idle2_selected               			;	// The PHY is operating in IDLE2 mode

	/*--------------------------------------------------------------------------------------
	--PHY Informational signals in support logic
	--------------------------------------------------------------------------------------*/
	wire			[P_Srio_CH_NUM_R* P_Srio_PHY_LANE_R-1:0]	gt_txpmaresetdone_out		;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	gtx_debug_signal							;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	rmv_fifo_afu_cnt							;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	par_fifo_afu_cnt							;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	sopdat_match_cnt							;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	sft_gtrx_sop_cnt							;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	rmv_gtrx_sop_cnt							;	//
	wire			[P_Srio_CH_NUM_R* 32-1:0]	par_gtrx_sop_cnt							;	//
	(*mark_debug="TRUE"*)
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_port_initialized						;	// Port is intialized
	(*mark_debug="TRUE"*)
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_link_initialized						;	// Ready to transmit data
	(*mark_debug="TRUE"*)
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_idle_selected   						;	// The IDLE sequence has been selected
	wire            [P_Srio_CH_NUM_R* 1-1:0]	srio_mode_1x         						;	// Link is trained down to 1x mode

	/*--------------------------------------------------------------------------------------
	--SRIO maintr IO Port
	--------------------------------------------------------------------------------------*/

	wire            [P_Srio_CH_NUM_R* 1-1:0] 	srio_maintr_rst								;	// Reset for maintr interface, on LOG clk domain

	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_awvalid							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_awready							;
    wire			[P_Srio_CH_NUM_R*32-1:0]    srio_maintr_awaddr							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_wvalid							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_wready							;
    wire			[P_Srio_CH_NUM_R*32-1:0] 	srio_maintr_wdata							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_bvalid							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_bready							;
    wire			[P_Srio_CH_NUM_R* 2-1:0]	srio_maintr_bresp							;

    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_arvalid							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_arready							;
    wire			[P_Srio_CH_NUM_R*32-1:0] 	srio_maintr_araddr							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_rvalid							;
    wire	        [P_Srio_CH_NUM_R* 1-1:0]	srio_maintr_rready							;
    wire			[P_Srio_CH_NUM_R*32-1:0] 	srio_maintr_rdata							;
    wire			[P_Srio_CH_NUM_R* 2-1:0]	srio_maintr_rresp							;
	/*--------------------------------------------------------------------------------------
	--SRIO IP Core Hello foramt IO Port
	--------------------------------------------------------------------------------------*/
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iotx_tready							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iotx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iotx_tlast								;
	wire			[P_Srio_CH_NUM_R*64-1:0]	srio_iotx_tdata								;
	wire			[P_Srio_CH_NUM_R* 8-1:0]	srio_iotx_tkeep								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	srio_iotx_tuser								;

	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iorx_tready							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iorx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iorx_tlast								;
	wire			[P_Srio_CH_NUM_R*64-1:0]	srio_iorx_tdata								;
	wire			[P_Srio_CH_NUM_R* 8-1:0]	srio_iorx_tkeep								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	srio_iorx_tuser								;


	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_vdrx_tready							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_vdrx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_vdrx_tlast								;
	wire			[P_Srio_CH_NUM_R*64-1:0]	srio_vdrx_tdata								;
	wire			[P_Srio_CH_NUM_R* 8-1:0]	srio_vdrx_tkeep								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	srio_vdrx_tuser								;

	wire			[P_Srio_CH_NUM_R*32-1:0]	srgt_data_tcnt								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	srgt_k_sc_tcnt								;

	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_sprx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_sprx_tready							;

	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_bmrx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_bmrx_tready							;

	wire			[P_Srio_CH_NUM_R* 1-1:0]	sp_rx_tready											;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	sp_rx_tvalid											;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	sp_rx_tlast											;
	wire			[P_Srio_CH_NUM_R*64-1:0]	sp_rx_tdata											;
	wire			[P_Srio_CH_NUM_R* 8-1:0]	sp_rx_tkeep											;
	wire			[P_Srio_CH_NUM_R*32-1:0]	sp_rx_tuser											;

	wire												video_srio0_tready									;
	wire												video_axis_tvalid									;
	wire												video_axis_tready									;
	wire												video_axis_tlast									;
	wire		[63:0]								video_axis_tdata									;
	wire		[7:0]									video_axis_tkeep									;
	wire		[63:0]							video_axis_tuser									;
	wire		[31:0]							video_feature_match_count					;
	wire signed	[15:0]						video_stitch_dx								;
	wire signed	[15:0]						video_stitch_dy								;
	wire		[15:0]							video_stitch_confidence					;
	wire		[31:0]							video_drop_count								;

`ifdef	ENABLE_SIM_ONLY
		assign			srio_bmrx_tready	=	{{P_Srio_CH_NUM_R* 1}	{1'b1}}				;
`endif

	assign			srio_sprx_tvalid	=	srio_iorx_tvalid	&	srio_bmrx_tready	;
	assign			srio_bmrx_tvalid	=	srio_iorx_tvalid	&	srio_sprx_tready	;

	assign			srio_iorx_tready	=	srio_sprx_tready	&	srio_bmrx_tready	;

	assign			srio_sprx_tready	[0* 1+: 1]	=	video_srio0_tready					;
	assign			sp_rx_tvalid		[0* 1+: 1]	=	srio_vdrx_tvalid	[0* 1+: 1]		;
	assign			srio_vdrx_tready	[0* 1+: 1]	=	sp_rx_tready		[0* 1+: 1]		;
	assign			sp_rx_tlast		[0* 1+: 1]	=	srio_vdrx_tlast		[0* 1+: 1]		;
	assign			sp_rx_tdata		[0*64+:64]	=	srio_vdrx_tdata		[0*64+:64]		;
	assign			sp_rx_tkeep		[0* 8+: 8]	=	srio_vdrx_tkeep		[0* 8+: 8]		;
	assign			sp_rx_tuser		[0*32+:32]	=	srio_vdrx_tuser		[0*32+:32]		;

	generate if(P_Srio_CH_NUM_R > 1) begin : i_SP_RX_PASS_G
		assign		srio_sprx_tready	[P_Srio_CH_NUM_R* 1-1:1]	=	sp_rx_tready	[P_Srio_CH_NUM_R* 1-1:1]	;
		assign		sp_rx_tvalid		[P_Srio_CH_NUM_R* 1-1:1]	=	srio_sprx_tvalid[P_Srio_CH_NUM_R* 1-1:1]	;
		assign		sp_rx_tlast		[P_Srio_CH_NUM_R* 1-1:1]	=	srio_iorx_tlast	[P_Srio_CH_NUM_R* 1-1:1]	;
		assign		sp_rx_tdata		[P_Srio_CH_NUM_R*64-1:64]	=	srio_iorx_tdata	[P_Srio_CH_NUM_R*64-1:64]	;
		assign		sp_rx_tkeep		[P_Srio_CH_NUM_R* 8-1: 8]	=	srio_iorx_tkeep	[P_Srio_CH_NUM_R* 8-1: 8]	;
		assign		sp_rx_tuser		[P_Srio_CH_NUM_R*32-1:32]	=	srio_iorx_tuser	[P_Srio_CH_NUM_R*32-1:32]	;
	end endgenerate

	/*--------------------------------------------------------------------------------------
	--dma dn/up packet
	--------------------------------------------------------------------------------------*/
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_sp_up_cnt									;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_sp_dn_cnt									;

	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_recv_cnt							;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_up_cnt								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_lost_cnt							;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_terr_cnt							;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_derr_cnt							;
	wire			[P_Srio_CH_NUM_R*01-1:0]	c_gt_ksc_enab								;
	wire			[P_Srio_CH_NUM_R*01-1:0]	c_gt_dat_byps								;
	wire			[P_Srio_CH_NUM_R*01-1:0]	c_bm_rtready_en								;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	c_bm_ch_en									;
	wire			[	1			*32-1:0]	c_bm_up_cnt									;

	wire			[63:0]						c_bm_timestamp								;
	wire										c_bm_timestamp_rf							;

	wire			[	1			* 32-1:0]	dma_size_set								;	//	= 4096-1024
	wire			[	1			* 32-1:0]	dma_wait_set								;	//	= 32'hffffffff

	wire			[31:0]						reg_ch0_mem_addr_c							;
	wire			[31:0]						reg_ch0_mem_size_c							;
	wire			[31:0]						reg_ch1_mem_addr_c							;
	wire			[31:0]						reg_ch1_mem_size_c							;
	wire			[31:0]						reg_ch2_mem_addr_c							;
	wire			[31:0]						reg_ch2_mem_size_c							;
	wire			[31:0]						reg_ch3_mem_addr_c							;
	wire			[31:0]						reg_ch3_mem_size_c							;
	wire			[31:0]						reg_ch4_mem_addr_c							;
	wire			[31:0]						reg_ch4_mem_size_c							;
	wire			[31:0]						reg_ch5_mem_addr_c							;
	wire			[31:0]						reg_ch5_mem_size_c							;
	wire			[31:0]						reg_ch6_mem_addr_c							;
	wire			[31:0]						reg_ch6_mem_size_c							;
	wire			[31:0]						reg_ch7_mem_addr_c							;
	wire			[31:0]						reg_ch7_mem_size_c							;

//==================================================================================================
//--寄存器总线时序转换信号定义
	wire			[P_AXILITE_CH_NUM_R*32-1:0] master_axi_awaddr							;
  	wire			[P_AXILITE_CH_NUM_R* 3-1:0]	master_axi_awprot							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_awvalid							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_awready							;

  	wire			[P_AXILITE_CH_NUM_R*32-1:0]	master_axi_wdata							;
  	wire			[P_AXILITE_CH_NUM_R* 4-1:0]	master_axi_wstrb							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_wvalid							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_wready							;

  	wire			[P_AXILITE_CH_NUM_R* 2-1:0]	master_axi_bresp							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_bvalid							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_bready							;

  	wire			[P_AXILITE_CH_NUM_R*32-1:0]	master_axi_araddr							;
  	wire			[P_AXILITE_CH_NUM_R* 3-1:0]	master_axi_arprot							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_arvalid							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_arready							;

  	wire			[P_AXILITE_CH_NUM_R*32-1:0]	master_axi_rdata							;
  	wire			[P_AXILITE_CH_NUM_R* 2-1:0]	master_axi_rresp							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_rvalid							;
  	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_rready                           ;

	/*--------------------------------------------------------------------------------------
	--Slave Write Data Command Signals for axi lite
	--------------------------------------------------------------------------------------*/
	wire			[P_Srio_CH_NUM_R*32-1:0]	log_axi_awaddr		;	//	=	{{P_Srio_CH_NUM_R	*	32	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*3-1 :0]	log_axi_awprot		;	//	=	{{P_Srio_CH_NUM_R	*	3	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_awvalid		;	//	=	{{P_Srio_CH_NUM_R	*	1	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_awready		;	//
  	wire			[P_Srio_CH_NUM_R*32-1:0]	log_axi_wdata		;	//	=	{{P_Srio_CH_NUM_R	*	32	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*4-1 :0]	log_axi_wstrb		;	//	=	{{P_Srio_CH_NUM_R	*	4	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_wvalid		;	//	=	{{P_Srio_CH_NUM_R	*	1	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_wready		;	//
  	wire			[P_Srio_CH_NUM_R*2-1 :0]	log_axi_bresp		;	//
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_bvalid		;	//
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_bready		;	//	=	{{P_Srio_CH_NUM_R	*	1	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*32-1:0]	log_axi_araddr		;	//	=	{{P_Srio_CH_NUM_R	*	32	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*3-1 :0]	log_axi_arprot		;	//	=	{{P_Srio_CH_NUM_R	*	3	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_arvalid		;	//	=	{{P_Srio_CH_NUM_R	*	1	}{1'b0}	}
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_arready		;	//
  	wire			[P_Srio_CH_NUM_R*32-1:0]	log_axi_rdata		;	//
  	wire			[P_Srio_CH_NUM_R*2-1 :0]	log_axi_rresp		;	//
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_rvalid		;	//
  	wire			[P_Srio_CH_NUM_R*1-1 :0]	log_axi_rready      ;	//	=   {{P_Srio_CH_NUM_R	*	1	}{1'b0}	}
//	wire										pcie_clk									;
//	wire										pcie_lnk_up									;
 	wire										pcie_reset									;

	wire										flash_clk									;
	/*--------------------------------------------------------------------------------------
	--Interrupt Bus interface
	--------------------------------------------------------------------------------------*/
		wire										interrupt_bus_clk		= pcie_clk			;
		wire										mmcm_lock									;
		wire										interrupt_bus_req		= 1'b0				;
		wire										interrupt_bus_gnt							;
		wire		[31:16]							interrupt_bus_vector	= 16'b0				;

	/*--------------------------------------------------------------------------------------
	--Clock And Reset
	--------------------------------------------------------------------------------------*/



	wire					sys_rst																;

	assign	sys_rst			= pcie_reset	;


    wire										clk_50M											;
    wire										clk_50Mgt										;
	wire			[P_Srio_CH_NUM_R-1:0]		sp_log_clk										;

	genvar k;
	generate for(k=0;k<P_Srio_BANK_R;k=k+1) begin:FAST_CLK_400M
	assign	sp_log_clk[k*P_BANK_CH_NUM_R+:P_BANK_CH_NUM_R]	=	{{P_BANK_CH_NUM_R}{log_clk[k]}}	;
	end		endgenerate

	wire	fst_clk	;
	wire	fst_rst	;
	wire	clk_locked					;
	assign	fst_rst	=	~	clk_locked	;

	localparam		TOT_LANE_SPEED	=	P_Srio_CH_LANE_R*P_Srio_SPEED_R	;

//	localparam		TIMER_PERIOD =	TOT_LANE_SPEED	>=	20	?	8'h23	:	//	400M
	localparam		TIMER_PERIOD =	TOT_LANE_SPEED	>=	20	?	8'h33	:	//	333M
									TOT_LANE_SPEED	>=	8	?	8'h44	:	//	250M
																8'h88	;	//	125M
//    BUFG_GT BUFG_GT_inst (
//       .O(clk_50Mgt),             // 1-bit output: Buffer
//       .CE(1		  ),           // 1-bit input: Buffer enable
//       .CEMASK(1	  ),   // 1-bit input: CE Mask
//       .CLR(0),         // 1-bit input: Asynchronous clear
//       .CLRMASK(1), // 1-bit input: CLR Mask
//       .DIV(1),         // 3-bit input: Dynamic divide Value
//       .I(clk_50M)              // 1-bit input: Buffer
//    );

//   BUFG BUFG_inst (
//      .O(clk_50Mgt), // 1-bit output: Clock output
//      .I(clk_50M)  // 1-bit input: Clock input
//   );
	clk_wiz_1 clk_wiz_fast   (
	.	clk_out1	(	fst_clk		)	,	//	output
	.	clk_out2	(	flash_clk	)	,	//	output
	.	locked		(	clk_locked	)	,	//	output
	.	clk_in1		(	ext_clk		)		//	100MHz
	);

  /*
	generate if(TOT_LANE_SPEED	>=	20) begin		//	400M
		clk_wiz_0 clk_wiz_fast   (
			.	clk_out1	(	fst_clk		)	,	//	output
			.	clk_out2	(	flash_clk	)	,	//	output
			.	locked		(	clk_locked	)	,	//	output
			.	clk_in1		(	ext_clk		)		//	250MHz
		);
	end	else	if(TOT_LANE_SPEED	>=	8) begin	//	250M





		);
	end	else	begin								//	125M
		clk_wiz_2 clk_wiz_fast   (
			.	clk_out1	(	fst_clk		)	,	//	output
			.	clk_out2	(	flash_clk	)	,	//	output
			.	locked		(	clk_locked	)	,	//	output
			.	clk_in1		(	ext_clk		)		//	100MHz
		);
	end	endgenerate*/


//==================================================================================================
//--LED控制实现
	/*--------------------------------------------------------------------------------------
	--LED[1:0]分配给PCIE时钟域
	--------------------------------------------------------------------------------------*/
//	(*mark_debug="TRUE"*)
//	wire 										init_calib_complete							;
//	(*mark_debug="TRUE"*)
//	wire 										mmcm_locked									;
//reg		[27:0]	emcc_clk_cnt	= 0	;	always @(posedge EMCCLK)	emcc_clk_cnt	<=	emcc_clk_cnt + 1'b1					;
reg		[27:0]	pcie_clk_cnt	= 0	;	always @(posedge pcie_clk)	pcie_clk_cnt	<=	pcie_clk_cnt + 1'b1						;

////assign	led[0]							 	=	pcie_clk_cnt[27]						;
////assign	led[1]								=	emcc_clk_cnt[27]						;
////assign	led[2]								=	user_lnk_up							;


////////////////////	pcie ipcore	inerface begin	///////////////
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


		wire			[2:0]						cfg_max_payload								;	//
		wire			[2:0]						cfg_max_read_req							;	//

		wire			[2:0]						pl_initial_link_width			=	3'b000	;	//	no used in pcie gen3
		wire										pl_link_gen2_cap				=	1'b0	;   //	no used in pcie gen3
		wire										pl_link_partner_gen2_supported	=	1'b0	;	//	no used in pcie gen3


		wire		[15:0]							pcie_far_id									;	//output			[1-1:0]
		wire		[15:0]							pcie_dev_id									;	//output			[1-1:0]

		wire										c_os_config									;	//output			[1-1:0]
		wire										c_os_big_endian								;	//output			[1-1:0]

////////////////////	pcie ipcore	inerface end	///////////////


////////////////////	rio 2 dma signal	begin	///////////////

	wire	[P_DMA_UP_NUM_R*64	-1:00]	dma_rio_gt_tdata		;
	wire	[P_DMA_UP_NUM_R* 4	-1:00]	dma_rio_gt_tid			;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_gt_tready		;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_gt_tvalid		;
	wire	[P_DMA_UP_NUM_R* 8	-1:00]	dma_rio_gt_tstrb		;
	wire	[P_DMA_UP_NUM_R* 8	-1:00]	dma_rio_gt_tkeep		;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_gt_tlast		;
	wire	[P_DMA_UP_NUM_R*64	-1:00]	dma_rio_gt_tuser		;
	wire	[P_DMA_UP_NUM_R* 4	-1:00]	dma_rio_gt_tdest		;

	wire	[P_DMA_UP_NUM_R*64	-1:00]	dma_rio_vd_tdata		;
	wire	[P_DMA_UP_NUM_R* 4	-1:00]	dma_rio_vd_tid			;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_vd_tready		;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_vd_tvalid		;
	wire	[P_DMA_UP_NUM_R* 8	-1:00]	dma_rio_vd_tstrb		;
	wire	[P_DMA_UP_NUM_R* 8	-1:00]	dma_rio_vd_tkeep		;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_vd_tlast		;
	wire	[P_DMA_UP_NUM_R*64	-1:00]	dma_rio_vd_tuser		;
	wire	[P_DMA_UP_NUM_R* 4	-1:00]	dma_rio_vd_tdest		;



	wire	[P_DMA_UP_NUM_R*64	-1:00]	dma_rio_rx_tdata		;
	wire	[P_DMA_UP_NUM_R* 4	-1:00]	dma_rio_rx_tid			;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_rx_tready		;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_rx_tvalid		;
	wire	[P_DMA_UP_NUM_R* 8	-1:00]	dma_rio_rx_tstrb		;
	wire	[P_DMA_UP_NUM_R* 8	-1:00]	dma_rio_rx_tkeep		;
	wire	[P_DMA_UP_NUM_R* 1	-1:00]	dma_rio_rx_tlast		;
	wire	[P_DMA_UP_NUM_R*64	-1:00]	dma_rio_rx_tuser		;
	wire	[P_DMA_UP_NUM_R* 4	-1:00]	dma_rio_rx_tdest		;

	wire	[P_DMA_DN_NUM_R*64	-1:00]	dma_rio_tx_tdata		;
	wire	[P_DMA_DN_NUM_R* 4	-1:00]	dma_rio_tx_tid			;
	wire	[P_DMA_DN_NUM_R* 1	-1:00]	dma_rio_tx_tready		;
	wire	[P_DMA_DN_NUM_R* 1	-1:00]	dma_rio_tx_tvalid		;
	wire	[P_DMA_DN_NUM_R* 8	-1:00]	dma_rio_tx_tstrb		;
	wire	[P_DMA_DN_NUM_R* 8	-1:00]	dma_rio_tx_tkeep		;
	wire	[P_DMA_DN_NUM_R* 1	-1:00]	dma_rio_tx_tlast		;
	wire	[P_DMA_DN_NUM_R*64	-1:00]	dma_rio_tx_tuser		;
	wire	[P_DMA_DN_NUM_R* 4	-1:00]	dma_rio_tx_tdest		;

////////////////////	rio 2 dma signal	end	///////////////

//==================================================================================================
//--
	wire 	[63:0]					udp_axis_tdata		;
	wire 	                        udp_axis_tready	    ;
	wire 	                        udp_axis_tvalid	    ;
	wire 	[7 :0]                  udp_axis_tkeep		;
	wire 	                        udp_axis_tlast		;
	wire 	[31:0]                  udp_axis_tuser		;

	assign	udp_axis_tdata		=	64'd0		;
	assign	udp_axis_tvalid		=	1'b0		;
	assign	udp_axis_tkeep		=	8'd0			;
	assign	udp_axis_tlast		=	1'b0		;
	assign	udp_axis_tuser		=	32'd0		;





	 pcie_dma_top #
    (
        .P_Version1_R                           ( P_Version1_R	                             ),
        .P_Version2_R                           ( P_Version2_R	                             ),
        .P_DMA_UP_NUM_R                         ( P_DMA_UP_NUM_R	                                ),
        .P_DMA_DN_NUM_R                         ( P_DMA_DN_NUM_R	                                  ),
        .DW                                     ( PCIE_DW                                   ),  //  RX/TX   interface   data    width
        .EXT_PIPE_SIM                           ( EXT_PIPE_SIM                              ),  //This    Parameter   has effect  on  selecting   Enable  External    PIPE    Interface   in  GUI.
        .PCIE_LS                                ( PCIE_LS                                   ),  //1->GEN1 , 2->GEN2 , 4->GEN3
        .PCIE_LW                                ( PCIE_LW                                   )   //1->X1   , 2->X2   , 4->X4   , 8->X8
    )
    u_pcie_dma_top
    (
        .pci_exp_txp                            ( pci_exp_txp                               ),   //  output
        .pci_exp_txn                            ( pci_exp_txn                               ),   //  output
        .pci_exp_rxp                            ( pci_exp_rxp                               ),   //  input
        .pci_exp_rxn                            ( pci_exp_rxn                               ),   //  input
        .pcie_ref_clk_p                         ( pcie_ref_clk_p                            ),   //  input
        .pcie_ref_clk_n                         ( pcie_ref_clk_n                            ),   //  input

        .dma_s_axis_aclk                        ( dma_s_axis_aclk                           ),
        .dma_s_axis_tdata                       ( dma_s_axis_tdata                          ),
        .dma_s_axis_tid                         ( dma_s_axis_tid                            ),
        .dma_s_axis_tready                      ( dma_s_axis_tready                         ),
        .dma_s_axis_tvalid                      ( dma_s_axis_tvalid                         ),
        .dma_s_axis_tstrb                       ( dma_s_axis_tstrb                          ),
        .dma_s_axis_tkeep                       ( dma_s_axis_tkeep                          ),
        .dma_s_axis_tlast                       ( dma_s_axis_tlast                          ),
        .dma_s_axis_tuser                       ( dma_s_axis_tuser                          ),
        .dma_s_axis_tdest                       ( dma_s_axis_tdest                          ),

        .dma_m_axis_aclk                        ( dma_m_axis_aclk                           ),
        .dma_m_axis_tdata                       ( dma_m_axis_tdata                          ),
        .dma_m_axis_tid                         ( dma_m_axis_tid                            ),
        .dma_m_axis_tready                      ( dma_m_axis_tready                         ),
        .dma_m_axis_tvalid                      ( dma_m_axis_tvalid                         ),
        .dma_m_axis_tstrb                       ( dma_m_axis_tstrb                          ),
        .dma_m_axis_tkeep                       ( dma_m_axis_tkeep                          ),
        .dma_m_axis_tlast                       ( dma_m_axis_tlast                          ),
        .dma_m_axis_tuser                       ( dma_m_axis_tuser                          ),
        .dma_m_axis_tdest                       ( dma_m_axis_tdest                          ),

        .pab_axi_awaddr                         ( pab_axi_awaddr                            ),
        .pab_axi_awprot                         ( pab_axi_awprot                            ),
        .pab_axi_awvalid                        ( pab_axi_awvalid                           ),
        .pab_axi_awready                        ( pab_axi_awready                           ),

        .pab_axi_wdata                          ( pab_axi_wdata                             ),
        .pab_axi_wstrb                          ( pab_axi_wstrb                             ),
        .pab_axi_wvalid                         ( pab_axi_wvalid                            ),
        .pab_axi_wready                         ( pab_axi_wready                            ),

        .pab_axi_bresp                          ( pab_axi_bresp                             ),
        .pab_axi_bvalid                         ( pab_axi_bvalid                            ),
        .pab_axi_bready                         ( pab_axi_bready                            ),

        .pab_axi_araddr                         ( pab_axi_araddr                            ),
        .pab_axi_arprot                         ( pab_axi_arprot                            ),
        .pab_axi_arvalid                        ( pab_axi_arvalid                           ),
        .pab_axi_arready                        ( pab_axi_arready                           ),

        .pab_axi_rdata                          ( pab_axi_rdata                             ),
        .pab_axi_rresp                          ( pab_axi_rresp                             ),
        .pab_axi_rvalid                         ( pab_axi_rvalid                            ),
        .pab_axi_rready                         ( pab_axi_rready                            ),

        .o_pcie_clk                             ( pcie_clk                                  ),
        .o_pcie_rst                             ( pcie_reset                                ),
        .o_gt_refclk                            ( pcie_gt_refclk                            ),    //  output
        .sys_rst_n                              ( pcie_rstn                                 )
    );

//--xr2000_axilite_top Instantation
	wire	[P_AXILITE_CH_NUM_R-1:0]			master_clk									;

	assign	master_clk							=	{
											//		`ifdef	ENABLE_GT_ONLY
											//			srgt_phy_clk						,
											//		`else
											//			log_clk								,
											//		`endif
														log_clk								,
														flash_clk							,
													//	pcie_clk
														fst_clk
													}										;
	xr2000_axilite_top	#(
		.P_SIMULATION_R							( P_SIMULATION_R							),
		.P_AXILITE_CH_NUM_R						( P_AXILITE_CH_NUM_R						)
	)
	u_axilite_top (
		.rst									( sys_rst									),
		.slave_clk								( pcie_clk									),
		.master_clk								( master_clk								),

		.slave_axi_awaddr						( pab_axi_awaddr							),
		.slave_axi_awprot						( pab_axi_awprot							),
		.slave_axi_awvalid						( pab_axi_awvalid							),
		.slave_axi_awready						( pab_axi_awready							),
		.slave_axi_wdata						( pab_axi_wdata								),
		.slave_axi_wstrb						( pab_axi_wstrb								),
		.slave_axi_wvalid						( pab_axi_wvalid							),
		.slave_axi_wready						( pab_axi_wready							),
		.slave_axi_bresp						( pab_axi_bresp								),
		.slave_axi_bvalid						( pab_axi_bvalid							),
		.slave_axi_bready						( pab_axi_bready							),
		.slave_axi_araddr						( pab_axi_araddr							),
		.slave_axi_arprot						( pab_axi_arprot							),
		.slave_axi_arvalid						( pab_axi_arvalid							),
		.slave_axi_arready						( pab_axi_arready							),
		.slave_axi_rdata						( pab_axi_rdata								),
		.slave_axi_rresp						( pab_axi_rresp								),
		.slave_axi_rvalid						( pab_axi_rvalid							),
		.slave_axi_rready						( pab_axi_rready							),

		.master_axi_awaddr						( master_axi_awaddr							),
		.master_axi_awprot						( master_axi_awprot							),
		.master_axi_awvalid						( master_axi_awvalid						),
		.master_axi_awready						( master_axi_awready						),
		.master_axi_wdata						( master_axi_wdata							),
		.master_axi_wstrb						( master_axi_wstrb							),
		.master_axi_wvalid						( master_axi_wvalid							),
		.master_axi_wready						( master_axi_wready							),
		.master_axi_bresp						( master_axi_bresp							),
		.master_axi_bvalid						( master_axi_bvalid							),
		.master_axi_bready						( master_axi_bready							),
		.master_axi_araddr						( master_axi_araddr							),
		.master_axi_arprot						( master_axi_arprot							),
		.master_axi_arvalid						( master_axi_arvalid						),
		.master_axi_arready						( master_axi_arready						),
		.master_axi_rdata						( master_axi_rdata							),
		.master_axi_rresp						( master_axi_rresp							),
		.master_axi_rvalid						( master_axi_rvalid							),
		.master_axi_rready						( master_axi_rready							)
	);

//==================================================================================================
//--SRIO_DUT instantation -----------------
	/*--------------------------------------------------------------------------------------
	--2018/11/5 19:04:42
	--增加link检测复位实现，信号采用srio_rst，由srio_rst模块控制复位
	--------------------------------------------------------------------------------------*/
	wire										sa_link_rst									;
	wire										sb_link_rst									;

`ifdef	RIO_AXIS_LOOPBACK	localparam		P_RIO_AXIS_LOOPBACK	=	1	;
`else						localparam		P_RIO_AXIS_LOOPBACK	=	0	;
`endif

`ifdef	ENABLE_SIM
	parameter	PARAM_ENABLE_SIM	=	1	;
`else
	parameter	PARAM_ENABLE_SIM	=	0	;
`endif
`ifdef	ENABLE_BM
	parameter	PARAM_ENABLE_BM	=	1	;
`else
	parameter	PARAM_ENABLE_BM	=	0	;
`endif
`ifdef	ENABLE_GT
	parameter	PARAM_ENABLE_GT	=	1	;
`else
	parameter	PARAM_ENABLE_GT	=	0	;
`endif

genvar jj;

generate for(jj=0;jj<P_Srio_BANK_R;jj=jj+1) begin : i_SUPPT_G

if(PARAM_ENABLE_GT==0) begin
	srio_support	#(
		.P_RIO_AXIS_LOOPBACK					( P_RIO_AXIS_LOOPBACK													),
		.P_Srio_ID_WTH_R						( P_Srio_ID_WTH_R														),
		.P_Srio_CH_NUM_R						( P_BANK_CH_NUM_R														),
		.P_Srio_CH_LANE_R						( P_Srio_CH_LANE_R	        											),
		.P_Srio_SPEED_R							( P_Srio_SPEED_R		    											),
		.P_Srio_PHY_LANE_R						( P_BANK_LANE_R															)
	)
	i_srio_support	(
`ifdef	REF_CLK_156
		.sys_clkp                				( srio_sys_clk_p_156	[jj]											),
		.sys_clkn                				( srio_sys_clk_n_156	[jj]											),
`else
		.sys_clkp                				( srio_sys_clk_p_125	[jj]											),
		.sys_clkn                				( srio_sys_clk_n_125	[jj]											),
`endif
		.sys_rst                 				( sys_rst																),
      // all clocks as output in shared logic mode
		.log_clk_out             				( log_clk   			[jj]											),
		.phy_clk_out             				( phy_clk   			[jj]											),
		.gt_clk_out              				( gt_clk_out   			[jj]											),
		.gt_pcs_clk_out          				( gt_pcs_clk			[jj]											),
		.drpclk_out              				( drpclk    			[jj]											),
		.refclk_out              				( refclk    			[jj]											),
		.clk_lock_out            				( clk_lock  			[jj]											),
      // all resets as output in shared logic mode
		.log_rst_out           					( srio_log_rst   		[jj*P_BANK_CH_NUM_R* 1   +: P_BANK_CH_NUM_R* 1]	),
		.phy_rst_out           					( srio_phy_rst   		[jj*P_BANK_CH_NUM_R* 1   +: P_BANK_CH_NUM_R* 1]	),
		.buf_rst_out           					( srio_buf_rst   		[jj*P_BANK_CH_NUM_R* 1   +: P_BANK_CH_NUM_R* 1]	),
		.cfg_rst_out           					( srio_cfg_rst   		[jj*P_BANK_CH_NUM_R* 1   +: P_BANK_CH_NUM_R* 1]	),
		.gt_pcs_rst_out        					( srio_gt_pcs_rst		[jj*P_BANK_CH_NUM_R* 1   +: P_BANK_CH_NUM_R* 1]	),

//---------------------------------------------------------------
	//	.gt0_qpll_clk_out        				( gt0_qpll_clk	       	[jj]											),
	//	.gt0_qpll_out_refclk_out 				( gt0_qpll_out_refclk	[jj]											),

// //---------------------------------------------------------------
		.srio_rxn0               				( srio_rxn0				[jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		),
		.srio_rxp0               				( srio_rxp0				[jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		),
		.srio_txn0               				( srio_txn0				[jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		),
		.srio_txp0               				( srio_txp0				[jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		),

		.s_axis_iotx_tready            			( srio_iotx_tready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axis_iotx_tvalid            			( srio_iotx_tvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axis_iotx_tlast             			( srio_iotx_tlast		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axis_iotx_tdata             			( srio_iotx_tdata		[jj*P_BANK_CH_NUM_R*64 +: P_BANK_CH_NUM_R*64]	),
		.s_axis_iotx_tkeep             			( srio_iotx_tkeep		[jj*P_BANK_CH_NUM_R* 8 +: P_BANK_CH_NUM_R* 8]	),
		.s_axis_iotx_tuser             			( srio_iotx_tuser		[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),

		.m_axis_iorx_tvalid            			( srio_iorx_tvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.m_axis_iorx_tready            			( srio_iorx_tready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.m_axis_iorx_tlast             			( srio_iorx_tlast		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.m_axis_iorx_tdata             			( srio_iorx_tdata		[jj*P_BANK_CH_NUM_R*64 +: P_BANK_CH_NUM_R*64]	),
		.m_axis_iorx_tkeep             			( srio_iorx_tkeep		[jj*P_BANK_CH_NUM_R* 8 +: P_BANK_CH_NUM_R* 8]	),
		.m_axis_iorx_tuser             			( srio_iorx_tuser		[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),

		.s_axi_maintr_rst     	         		( srio_maintr_rst		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.s_axi_maintr_awvalid          			( srio_maintr_awvalid	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_awready          			( srio_maintr_awready	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_awaddr           			( srio_maintr_awaddr	[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_maintr_wvalid           			( srio_maintr_wvalid	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_wready           			( srio_maintr_wready	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_wdata            			( srio_maintr_wdata		[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_maintr_bvalid           			( srio_maintr_bvalid	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_bready           			( srio_maintr_bready	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_bresp            			( srio_maintr_bresp		[jj*P_BANK_CH_NUM_R* 2 +: P_BANK_CH_NUM_R* 2]	),

		.s_axi_maintr_arvalid          			( srio_maintr_arvalid	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_arready          			( srio_maintr_arready	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_araddr           			( srio_maintr_araddr	[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_maintr_rvalid           			( srio_maintr_rvalid	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_rready           			( srio_maintr_rready	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_maintr_rdata            			( srio_maintr_rdata		[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_maintr_rresp            			( srio_maintr_rresp		[jj*P_BANK_CH_NUM_R* 2 +: P_BANK_CH_NUM_R* 2]	),

		.sim_train_en                  			( sim_train_en															),
		.phy_mce           	            		( srio_phy_mce			[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.phy_link_reset    	            		( srio_phy_link_reset	[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.force_reinit      	            		( srio_force_reinit		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.phy_rcvd_mce                  			( srio_phy_rcvd_mce     [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.phy_rcvd_link_reset           			( srio_phy_rcvd_link_reset[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.phy_debug                     			( srio_phy_debug        [jj*P_BANK_CH_NUM_R*224+: P_BANK_CH_NUM_R*224]	),
		.gtrx_disperr_or               			( srio_gtrx_disperr_or  [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.gtrx_notintable_or            			( srio_gtrx_notintable_or[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.port_error                    			( srio_port_error       [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.port_timeout                  			( srio_port_timeout     [jj*P_BANK_CH_NUM_R*24 +: P_BANK_CH_NUM_R*24]	),
		.srio_host                     			( srio_srio_host        [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.port_decode_error             			( srio_port_decode_error[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.deviceid                      			( srio_deviceid         [jj*P_BANK_CH_NUM_R*16 +: P_BANK_CH_NUM_R*16]	),
		.idle2_selected                			( srio_idle2_selected   [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.phy_lcl_master_enable_out     			( 																		), // these are side band output only signals
		.buf_lcl_response_only_out     			( 																		),
		.buf_lcl_tx_flow_control_out   			( 																		),
		.buf_lcl_phy_buf_stat_out      			( 																		),
		.phy_lcl_phy_next_fm_out       			( 																		),
		.phy_lcl_phy_last_ack_out      			( 																		),
		.phy_lcl_phy_rewind_out        			( 																		),
		.phy_lcl_phy_rcvd_buf_stat_out 			( 																		),
		.phy_lcl_maint_only_out        			( 																		),

	//	.gt_txpmaresetdone_out        			( gt_txpmaresetdone_out	[jj* P_BANK_LANE_R* 1 +:  P_BANK_LANE_R* 1]		),

		.port_initialized              			( srio_port_initialized [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.link_initialized              			( srio_link_initialized [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.idle_selected                 			( srio_idle_selected    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.mode_1x                       			( srio_mode_1x          [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)
	);
end	else	if(PARAM_ENABLE_GT==1) begin
	srio_gt_top	#(
		.	P_DEVICE_TYPE_R							(		P_DEVICE_TYPE_R															)	,
		.	LINK_WIDTH								(		P_Srio_CH_LANE_R														)	,
		.	IPCORE_NUM								(		P_BANK_CH_NUM_R			    											)	,
		.	GT_BYTES								(		4						    											)	,
		.	GT_SPD									(		P_Srio_SPEED_R			    											)	,
		.	IDLE1									(		`IDLE_1					    											)	,
		.	IDLE2									(		`IDLE_2					    											)
	)	i_srgt_support	(
`ifdef	REF_CLK_156
		.	sys_clkp                				(		srio_sys_clk_p_156		    [jj]											)	,
		.	sys_clkn                				(		srio_sys_clk_n_156		    [jj]											)	,
`else
		.	sys_clkp                				(		srio_sys_clk_p_125		    [jj]											)	,
		.	sys_clkn                				(		srio_sys_clk_n_125		    [jj]											)	,
`endif
		.	sys_rst									(		sys_rst																		)	,
		.	srio_rxn								(		srio_rxn0				    [jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		)	,
		.	srio_rxp								(		srio_rxp0				    [jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		)	,
		.	srio_txn								(		srio_txn0				    [jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		)	,
		.	srio_txp								(		srio_txp0				    [jj*P_BANK_LANE_R* 1   +: P_BANK_LANE_R* 1]		)	,

		.	gt_pcs_clk								(		gt_pcs_clk				    [jj]											)	,
		.	gt_pcs_rst								(		srio_gt_pcs_rst				[jj]											)	,
		.	phy_clk									(		phy_clk					    [jj]											)	,
		.	phy_rst									(		srio_phy_rst				[jj]											)	,
		.	log_clk									(		log_clk					    [jj]											)	,
		.	log_rst									(		srio_log_rst				[jj]											)	,
		.	set_link_1x								(		1'b0																		)	,
		.	any_gtrxaligned							(		srio_port_initialized	    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	all_gtrxaligned							(		srio_link_initialized	    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	force_reinit							(		srio_force_reinit			[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	c_gt_ksc_enab							(		c_gt_ksc_enab				[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	c_gt_dat_byps							(		c_gt_dat_byps				[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,

		.	srgt_iorx_tready						(		srio_iorx_tready		    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	srgt_iorx_tvalid						(		srio_iorx_tvalid		    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	srgt_iorx_tdata							(		srio_iorx_tdata			    [jj*P_BANK_CH_NUM_R*64 +: P_BANK_CH_NUM_R*64]	)	,
		.	srgt_iorx_tkeep							(		srio_iorx_tkeep			    [jj*P_BANK_CH_NUM_R*08 +: P_BANK_CH_NUM_R*08]	)	,
		.	srgt_iorx_tlast							(		srio_iorx_tlast			    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)	,
		.	srgt_iorx_tuser							(		srio_iorx_tuser			    [jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,

		.	srgt_data_tcnt							(		srgt_data_tcnt			    [jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	srgt_k_sc_tcnt							(		srgt_k_sc_tcnt			    [jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,

		.	sft_gtrx_sop_cnt						(		sft_gtrx_sop_cnt		    [jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	rmv_gtrx_sop_cnt						(		rmv_gtrx_sop_cnt		    [jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	par_gtrx_sop_cnt						(		par_gtrx_sop_cnt	    	[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	rmv_fifo_afu_cnt						(		rmv_fifo_afu_cnt	    	[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	par_fifo_afu_cnt						(		par_fifo_afu_cnt	    	[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	sopdat_match_cnt						(		sopdat_match_cnt	    	[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	gtx_debug_signal						(		gtx_debug_signal		    [jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	)	,
		.	dma_rst									(		fst_rst																		)	,
		.	dma_clk									(		fst_clk																		)
	);	//srio_gen2_gt_top
end
end
endgenerate
video_stitch_pcie_top #(
	.	SIM										( 	0						),
	.	BUS_DW									( 	64						),
	.	DW										( 	64						),
	.	TARGET_SRC_ID						( 	16'h0000				),
	.	FRAME_WIDTH							( 	VIDEO_FRAME_WIDTH		),
	.	FRAME_HEIGHT						( 	VIDEO_FRAME_HEIGHT		),
	.	OVERLAP_WIDTH						( 	VIDEO_OVERLAP_WIDTH	),
	.	RAW10_SHIFT							( 	VIDEO_RAW10_SHIFT		),
	.	DUP_SRIO0_ENABLE					( 	VIDEO_DUP_SRIO0_ENABLE	),
	.	TEST_PATTERN_ENABLE				( 	VIDEO_TEST_PATTERN_ENABLE )
) u_video_stitch_pcie_top (
	.srio0_tvalid							( 	srio_sprx_tvalid		[0* 1+: 1]	),
	.srio0_tready							( 	video_srio0_tready				),
	.srio0_tlast							( 	srio_iorx_tlast		[0* 1+: 1]	),
	.srio0_tdata							( 	srio_iorx_tdata		[0*64+:64]	),
	.srio0_tkeep							( 	srio_iorx_tkeep		[0* 8+: 8]	),
	.srio0_tuser							( 	srio_iorx_tuser		[0*32+:32]	),

	.srio0_nontarget_tvalid				( 	srio_vdrx_tvalid		[0* 1+: 1]	),
	.srio0_nontarget_tready				( 	srio_vdrx_tready		[0* 1+: 1]	),
	.srio0_nontarget_tlast				( 	srio_vdrx_tlast		[0* 1+: 1]	),
	.srio0_nontarget_tdata				( 	srio_vdrx_tdata		[0*64+:64]	),
	.srio0_nontarget_tkeep				( 	srio_vdrx_tkeep		[0* 8+: 8]	),
	.srio0_nontarget_tuser				( 	srio_vdrx_tuser		[0*32+:32]	),

	.m_axis_tdata							( 	video_axis_tdata				),
	.m_axis_tready							( 	video_axis_tready				),
	.m_axis_tvalid							( 	video_axis_tvalid				),
	.m_axis_tkeep							( 	video_axis_tkeep				),
	.m_axis_tlast							( 	video_axis_tlast				),
	.m_axis_tuser							( 	video_axis_tuser				),

	.feature_match_count				( 	video_feature_match_count		),
	.stitch_dx							( 	video_stitch_dx				),
	.stitch_dy							( 	video_stitch_dy				),
	.stitch_confidence					( 	video_stitch_confidence		),
	.drop_count							( 	video_drop_count				),

	.clk									( 	sp_log_clk			[0]		),
	.rst_n									( 	~sys_rst					)
);

axis_convert_top #(
	.	LOOP_NUM							( 	VIDEO_DMA_CH			),
	.	DW										( 	64						),
	.	QW										( 	PCIE_DW				)
) u_video_pcie_convert (
	.axsr_tvalid						( 	video_axis_tvalid							),
	.axsr_tready						( 	video_axis_tready							),
	.axsr_tlast						( 	video_axis_tlast							),
	.axsr_tdata						( 	video_axis_tdata							),
	.axsr_tuser						( 	video_axis_tuser							),
	.axsr_tkeep						( 	video_axis_tkeep							),
	.axsr_tstrb						( 	video_axis_tkeep							),
	.axsr_tdest						( 	4'd0									),
	.axsr_tid							( 	4'd0									),
	.i_rst								( 	sys_rst								),
	.i_clk								( 	sp_log_clk			[0]				),
	.axst_tvalid						( 	dma_s_axis_tvalid	[VIDEO_DMA_CH*1+:1]	),
	.axst_tready						( 	dma_s_axis_tready	[VIDEO_DMA_CH*1+:1]	),
	.axst_tlast						( 	dma_s_axis_tlast	[VIDEO_DMA_CH*1+:1]	),
	.axst_tdata						( 	dma_s_axis_tdata	[VIDEO_DMA_CH*PCIE_DW+:PCIE_DW]	),
	.axst_tuser						( 	dma_s_axis_tuser	[VIDEO_DMA_CH*64+:64]	),
	.axst_tkeep						( 	dma_s_axis_tkeep	[VIDEO_DMA_CH*PCIE_DW/8+:PCIE_DW/8]	),
	.axst_tstrb						( 	dma_s_axis_tstrb	[VIDEO_DMA_CH*PCIE_DW/8+:PCIE_DW/8]	),
	.axst_tdest						( 	dma_s_axis_tdest	[VIDEO_DMA_CH*4+:4]	),
	.axst_tid						( 	dma_s_axis_tid		[VIDEO_DMA_CH*4+:4]	),
	.o_rst								( 	pcie_rst								),
	.o_clk								( 	pcie_clk								)
);
wire [63:0]      udp_test_tdata		;
wire       		 udp_test_tready	;
wire 		     udp_test_tvalid	;
wire  [7 :0]     udp_test_tkeep		;
wire             udp_test_tlast		;
wire  [31:0]           udp_test_tuser		;

wire [63:0]      udp_test_rdata		;
wire [31:0]      udp_test_rready	;
wire [7 :0]      udp_test_rvalid	;
wire             udp_test_rkeep		;
wire             udp_test_rlast		;
wire             udp_test_ruser		;


 User_Data_Test datatest(
     . i_clk              (		xgmii_clk			) ,// input
     . i_rst              (		sys_rst				) ,// input

     . m_axis_data        (		udp_test_tdata  	 ) ,// output [63:0]
     . m_axis_user        (		udp_test_tuser   	 ) ,// output [31:0] //16'dlen,48'dsource_mac,16'dtype
     . m_axis_keep        (		udp_test_tkeep   	 ) ,// output [7 :0]
     . m_axis_last        (		udp_test_tlast  	 ) ,// output
     . m_axis_valid       (		udp_test_tvalid 	 ) ,// output
     . m_axis_ready       (		udp_test_tready 	 ) ,// input

     . s_axis_data        (		udp_test_rdata 	) ,// input  [63:0]
     . s_axis_user        (		udp_test_ruser    ) ,// input  [31:0] //16'dlen,48'dsource_mac,16'dtype
     . s_axis_keep        (		udp_test_rkeep   ) ,// input  [7 :0]
     . s_axis_last        (		udp_test_rlast 	) ,// input
     . s_axis_valid       (		udp_test_rvalid	)  // input
);


	TenG_ETH_TOP	#(
		.  P_SOURCE_IP   ( {8'd192,8'd168,8'd100,8'd100}  ),
		.  P_TARGET_IP   ( {8'd192,8'd168,8'd100,8'd99 }  ),
		.  P_SOURCE_PORT ( 16'd8080                       ),
		.  P_TARGET_PORT ( 16'd8080                       ),
		.  P_SOURCE_MAC  ( 48'h01_02_03_04_05_06          ),
		.  P_TARGET_MAC  ( 48'h0a_0b_0c_0d_0e_0f          )
		)u_TenG_ETH_TOP	(
	//---selfdefine Interface-----------------------
		. wm_axis_user_data   					(	udp_axis_tdata  					),//wire [63:0]      udp_axis_tdata
		. wm_axis_user_user   					(	udp_axis_tuser      				),//wire [31:0]      udp_axis_tready
		. wm_axis_user_keep   					(	udp_axis_tkeep      				),//wire [7 :0]      udp_axis_tvalid
		. wm_axis_user_last   					(	udp_axis_tlast  					),//wire             udp_axis_tkeep
		. wm_axis_user_valid  					(	udp_axis_tvalid 					),//wire             udp_axis_tlast
		. wm_axis_user_ready  					(	udp_axis_tready 					),//wire             udp_axis_tuser

		. ws_axis_user_data   					(					),//wire [63:0]
		. ws_axis_user_user   					(					),//wire [31:0]
		. ws_axis_user_keep   					(					),//wire [7 :0]
		. ws_axis_user_last   					(					),//wire
		. ws_axis_user_valid  					(					),//wire
		. ws_axis_user_ready  					(		1'b1		),//wire

	//---Common Interface---------------------------
	 	.	i_gt_clk_p      					(		teng_refclk_p  			)    ,
	    .	i_gt_clk_n      					(		teng_refclk_n  			)    ,
	    .	i_sys_clk_p     					(					)    ,
	    .	i_sys_clk_n     					(					)    ,

	    .	o_gt_txp        					(		teng_txp 		)    ,
	    .	o_gt_txn        					(		teng_txn 		)    ,
	    .	i_gt_rxp        					(		teng_rxp       	)    ,
	    .	i_gt_rxn        					(		teng_rxn       	)    ,
	    .	o_sfp_disable       				(		      			)	 ,

	    .	dclk								( 		flash_clk		)	,
	    .	w_xgmii_clk 						(		xgmii_clk		)	,//output
	    .	w_xgmii_rst         				(		sys_rst			)
	);


//==================================================================================================
//--zt_axilite_cross Instantation
generate for(jj=0;jj<P_Srio_BANK_R;jj=jj+1) begin : i_CROSS_G
	zt_axilite_cross	#(
		.P_SIMULATION_R							( P_SIMULATION_R														),
		.P_AXI_CHANNEL_R						( P_AXI_CHANNEL_R														),
		.P_CH_LOW_BIT_R							( P_CH_LOW_BIT_R														),
		.P_CH_Start_Addr_R						( P_CH_Start_Addr_R														)
	)
	i_log_axi_cross (
//	`ifdef	ENABLE_SIM
//		.clk									( log_clk				[jj]											),
//	`elsif	ENABLE_GT
//		.clk									( srgt_phy_clk			[jj]											),
//	`endif

		.clk									( log_clk				[jj]											),
		.rst									( sys_rst				 												),

		.sys_axi_awaddr							( master_axi_awaddr		[(jj+2)*32 +: 32]								),
		.sys_axi_awprot							( master_axi_awprot		[(jj+2)* 3 +:  3]								),
		.sys_axi_awvalid						( master_axi_awvalid	[(jj+2)* 1 +:  1]								),
		.sys_axi_awready						( master_axi_awready	[(jj+2)* 1 +:  1]								),

		.sys_axi_wdata							( master_axi_wdata		[(jj+2)*32 +: 32]								),
		.sys_axi_wstrb							( master_axi_wstrb		[(jj+2)* 4 +:  4]								),
		.sys_axi_wvalid							( master_axi_wvalid		[(jj+2)* 1 +:  1]								),
		.sys_axi_wready							( master_axi_wready		[(jj+2)* 1 +:  1]								),

		.sys_axi_bresp							( master_axi_bresp		[(jj+2)* 2 +:  2]								),
		.sys_axi_bvalid							( master_axi_bvalid		[(jj+2)* 1 +:  1]								),
		.sys_axi_bready							( master_axi_bready		[(jj+2)* 1 +:  1]								),

		.sys_axi_araddr							( master_axi_araddr		[(jj+2)*32 +: 32]								),
		.sys_axi_arprot							( master_axi_arprot		[(jj+2)* 3 +:  3]								),
		.sys_axi_arvalid						( master_axi_arvalid	[(jj+2)* 1 +:  1]								),
		.sys_axi_arready						( master_axi_arready	[(jj+2)* 1 +:  1]								),

		.sys_axi_rdata							( master_axi_rdata		[(jj+2)*32 +: 32]								),
		.sys_axi_rresp							( master_axi_rresp		[(jj+2)* 2 +:  2]								),
		.sys_axi_rvalid							( master_axi_rvalid		[(jj+2)* 1 +:  1]								),
		.sys_axi_rready							( master_axi_rready		[(jj+2)* 1 +:  1]								),

		.s_axi_awaddr							( log_axi_awaddr		[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_awprot							( log_axi_awprot		[jj*P_BANK_CH_NUM_R* 3 +: P_BANK_CH_NUM_R* 3]	),
		.s_axi_awvalid							( log_axi_awvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_awready							( log_axi_awready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.s_axi_wdata							( log_axi_wdata			[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_wstrb							( log_axi_wstrb			[jj*P_BANK_CH_NUM_R* 4 +: P_BANK_CH_NUM_R* 4]	),
		.s_axi_wvalid							( log_axi_wvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_wready							( log_axi_wready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.s_axi_bresp							( log_axi_bresp			[jj*P_BANK_CH_NUM_R* 2 +: P_BANK_CH_NUM_R* 2]	),
		.s_axi_bvalid							( log_axi_bvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_bready							( log_axi_bready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.s_axi_araddr							( log_axi_araddr		[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_arprot							( log_axi_arprot		[jj*P_BANK_CH_NUM_R* 3 +: P_BANK_CH_NUM_R* 3]	),
		.s_axi_arvalid							( log_axi_arvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_arready							( log_axi_arready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),

		.s_axi_rdata							( log_axi_rdata			[jj*P_BANK_CH_NUM_R*32 +: P_BANK_CH_NUM_R*32]	),
		.s_axi_rresp							( log_axi_rresp			[jj*P_BANK_CH_NUM_R* 2 +: P_BANK_CH_NUM_R* 2]	),
		.s_axi_rvalid							( log_axi_rvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axi_rready							( log_axi_rready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)
	);
end
endgenerate

//==================================================================================================
//--regfile_sim_top Instantation
	regfile_sim_top	#(
		.P_SIMULATION_R							( P_SIMULATION_R							),
		.P_Srio_CH_NUM_R						( P_Srio_CH_NUM_R							),
		.P_Srio_CAP_R							( P_Srio_CAP_R								),
	//	.P_Srio_CAP_R							( 32'h5										),
		.P_Srio_ID_WTH_R						( P_Srio_ID_WTH_R							),
		.P_Srio_SPEED_R							( P_Srio_SPEED_R							),
		.P_Srio_BANK_R							( P_Srio_BANK_R-1							),	//寄存器约定
		.P_Board_MEM_SIZE_R						( P_Board_MEM_SIZE_R						),
		.P_Srio_CH0_R							( P_Srio_CH0_R								),
		.P_Srio_CH1_R							( P_Srio_CH1_R								),
		.P_Srio_CH2_R							( P_Srio_CH2_R								),
		.P_Srio_CH3_R							( P_Srio_CH3_R								),
		.P_Srio_CH4_R							( P_Srio_CH4_R								),
		.P_Srio_CH5_R							( P_Srio_CH5_R								),
		.P_Srio_CH6_R							( P_Srio_CH6_R								),
		.P_Srio_CH7_R							( P_Srio_CH7_R								)
	)
	i_regfile_sim_top (
		.rst									( sys_rst									),
		.clk									( fst_clk									),


		.c_bm_timestamp							( c_bm_timestamp							),
		.c_bm_timestamp_rf						( c_bm_timestamp_rf							),
		.c_bm_up_cnt							( c_bm_up_cnt								),
		.dma_size_set							( dma_size_set								),
		.dma_wait_set							( dma_wait_set								),

		.sys_axi_awaddr							( master_axi_awaddr	    	[0*32 +: 32]	),
		.sys_axi_awprot							( master_axi_awprot	    	[0* 3 +:  3]	),
		.sys_axi_awvalid						( master_axi_awvalid		[0* 1 +:  1]	),
		.sys_axi_awready						( master_axi_awready		[0* 1 +:  1]	),

		.sys_axi_wdata							( master_axi_wdata	    	[0*32 +: 32]	),
		.sys_axi_wstrb							( master_axi_wstrb	    	[0* 4 +:  4]	),
		.sys_axi_wvalid							( master_axi_wvalid	    	[0* 1 +:  1]	),
		.sys_axi_wready							( master_axi_wready	    	[0* 1 +:  1]	),

		.sys_axi_bresp							( master_axi_bresp	    	[0* 2 +:  2]	),
		.sys_axi_bvalid							( master_axi_bvalid	    	[0* 1 +:  1]	),
		.sys_axi_bready							( master_axi_bready	    	[0* 1 +:  1]	),

		.sys_axi_araddr							( master_axi_araddr	    	[0*32 +: 32]	),
		.sys_axi_arprot							( master_axi_arprot	    	[0* 3 +:  3]	),
		.sys_axi_arvalid						( master_axi_arvalid		[0* 1 +:  1]	),
		.sys_axi_arready						( master_axi_arready		[0* 1 +:  1]	),

		.sys_axi_rdata							( master_axi_rdata	    	[0*32 +: 32]	),
		.sys_axi_rresp							( master_axi_rresp	    	[0* 2 +:  2]	),
		.sys_axi_rvalid							( master_axi_rvalid	    	[0* 1 +:  1]	),
		.sys_axi_rready							( master_axi_rready     	[0* 1 +:  1]	),

		.reg_ch0_mem_addr_c						( reg_ch0_mem_addr_c						),
		.reg_ch0_mem_size_c						( reg_ch0_mem_size_c						),
		.reg_ch1_mem_addr_c						( reg_ch1_mem_addr_c						),
		.reg_ch1_mem_size_c						( reg_ch1_mem_size_c						),
		.reg_ch2_mem_addr_c						( reg_ch2_mem_addr_c						),
		.reg_ch2_mem_size_c						( reg_ch2_mem_size_c						),
		.reg_ch3_mem_addr_c						( reg_ch3_mem_addr_c						),
		.reg_ch3_mem_size_c						( reg_ch3_mem_size_c						),
		.reg_ch4_mem_addr_c						( reg_ch4_mem_addr_c						),
		.reg_ch4_mem_size_c						( reg_ch4_mem_size_c						),
		.reg_ch5_mem_addr_c						( reg_ch5_mem_addr_c						),
		.reg_ch5_mem_size_c						( reg_ch5_mem_size_c						),
		.reg_ch6_mem_addr_c						( reg_ch6_mem_addr_c						),
		.reg_ch6_mem_size_c						( reg_ch6_mem_size_c						),
		.reg_ch7_mem_addr_c						( reg_ch7_mem_addr_c						),
		.reg_ch7_mem_size_c						( reg_ch7_mem_size_c						),

		.c_sp_up_cnt							( {{{16-P_Srio_CH_NUM_R}{32'b0}},c_sp_up_cnt}),	//max 8 channel
		.c_sp_dn_cnt							( {{{16-P_Srio_CH_NUM_R}{32'b0}},c_sp_dn_cnt})
	);

//==================================================================================================


//==================================================================================================
//--SIM Channel inst


genvar i;
generate for(i=0;i<P_Srio_CH_NUM_R;i=i+1) begin:i_SP_G
	sp_top	#(
		.P_SIMULATION_R							(	P_SIMULATION_R									)	,
		.P_BIG_CACHE_R							(   "FALSE"											)
	)
	i_sp_top (
		.clk									(   fst_clk											)	,

		.log_clk								(   sp_log_clk				[i*1+: 1]				)	,
		.rst									(   sys_rst											)	,
		.srio_rst								(   1'b0											)	,

		.port_error								(   srio_port_error			[i* 1+: 1]				)	,
		.port_initialized						(   srio_port_initialized	[i* 1+: 1]				)	,
		.link_initialized						(   srio_link_initialized	[i* 1+: 1]				)	,
		.mode_1x								(   srio_mode_1x			[i* 1+: 1]				)	,
		.force_reinit							(   srio_force_reinit		[i* 1+: 1]				)	,

		.sys_axi_awaddr							(   log_axi_awaddr			[i*32+:32]				)	,
		.sys_axi_awprot							(   log_axi_awprot			[i* 3+: 3]				)	,
		.sys_axi_awvalid						(   log_axi_awvalid			[i* 1+: 1]				)	,
		.sys_axi_awready						(   log_axi_awready			[i* 1+: 1]				)	,
		.sys_axi_wdata							(   log_axi_wdata			[i*32+:32]				)	,
		.sys_axi_wstrb							(   log_axi_wstrb			[i* 4+: 4]				)	,
		.sys_axi_wvalid							(   log_axi_wvalid			[i* 1+: 1]				)	,
		.sys_axi_wready							(   log_axi_wready			[i* 1+: 1]				)	,
		.sys_axi_bresp							(   log_axi_bresp			[i* 2+: 2]				)	,
		.sys_axi_bvalid							(   log_axi_bvalid			[i* 1+: 1]				)	,
		.sys_axi_bready							(   log_axi_bready			[i* 1+: 1]				)	,
		.sys_axi_araddr							(   log_axi_araddr			[i*32+:32]				)	,
		.sys_axi_arprot							(   log_axi_arprot			[i* 3+: 3]				)	,
		.sys_axi_arvalid						(   log_axi_arvalid			[i* 1+: 1]				)	,
		.sys_axi_arready						(   log_axi_arready			[i* 1+: 1]				)	,
		.sys_axi_rdata							(   log_axi_rdata			[i*32+:32]				)	,
		.sys_axi_rresp							(   log_axi_rresp			[i* 2+: 2]				)	,
		.sys_axi_rvalid							(   log_axi_rvalid			[i* 1+: 1]				)	,
		.sys_axi_rready							(   log_axi_rready			[i* 1+: 1]				)	,
	`ifdef	ENABLE_SIM
	//	.dma_s_axis_aclk						(   dma_s_axis_aclk			[i* 1+: 1]				)	,
		.dma_s_axis_tdata						(   dma_rio_rx_tdata		[i*64+:64]				)	,
		.dma_s_axis_tid							(   dma_rio_rx_tid			[i* 4+: 4]				)	,
		.dma_s_axis_tready						(   dma_rio_rx_tready		[i* 1+: 1]				)	,
		.dma_s_axis_tvalid						(   dma_rio_rx_tvalid		[i* 1+: 1]				)	,
		.dma_s_axis_tstrb						(   dma_rio_rx_tstrb		[i* 8+: 8]				)	,
		.dma_s_axis_tkeep						(   dma_rio_rx_tkeep		[i* 8+: 8]				)	,
		.dma_s_axis_tlast						(   dma_rio_rx_tlast		[i* 1+: 1]				)	,
		.dma_s_axis_tuser						(   dma_rio_rx_tuser		[i*64+:64]				)	,
		.dma_s_axis_tdest						(   dma_rio_rx_tdest		[i* 4+: 4]				)	,

	//	.dma_m_axis_aclk						(   dma_m_axis_aclk			[i* 1+: 1]				)	,
		.dma_m_axis_tdata						(   dma_rio_tx_tdata		[i*64+:64]				)	,
		.dma_m_axis_tid							(   dma_rio_tx_tid			[i* 4+: 4]				)	,
		.dma_m_axis_tready						(   dma_rio_tx_tready		[i* 1+: 1]				)	,
		.dma_m_axis_tvalid						(   dma_rio_tx_tvalid		[i* 1+: 1]				)	,
		.dma_m_axis_tstrb						(   dma_rio_tx_tstrb		[i* 8+: 8]				)	,
		.dma_m_axis_tkeep						(   dma_rio_tx_tkeep		[i* 8+: 8]				)	,
		.dma_m_axis_tlast						(   dma_rio_tx_tlast		[i* 1+: 1]				)	,
		.dma_m_axis_tuser						(   dma_rio_tx_tuser		[i*64+:64]				)	,

		.c_sp_dn_cnt							(   c_sp_dn_cnt				[i*32+:32]				)	,
		.c_sp_up_cnt							(   c_sp_up_cnt				[i*32+:32]				)	,
	`endif
		.c_bm_recv_cnt							(   c_bm_ch_recv_cnt		[i*32+:32]				)	,
		.c_bm_up_cnt							(   c_bm_ch_up_cnt			[i*32+:32]				)	,
		.c_bm_lost_cnt							(   c_bm_ch_lost_cnt		[i*32+:32]				)	,
		.c_bm_terr_cnt							(   c_bm_ch_terr_cnt		[i*32+:32]				)	,
		.c_bm_derr_cnt							(   c_bm_ch_derr_cnt		[i*32+:32]				)	,
		.c_bm_en								(   c_bm_ch_en				[i* 1+: 1]				)	,
		.c_bm_rtready_en						(   c_bm_rtready_en			[i* 1+: 1]				)	,
		.	c_gt_ksc_enab						(   c_gt_ksc_enab			[i* 1+: 1]				)	,
		.	c_gt_dat_byps						(   c_gt_dat_byps			[i* 1+: 1]				)	,

		.	srgt_data_tcnt						(   srgt_data_tcnt			[i*32+:32]				)	,
		.	srgt_k_sc_tcnt						(   srgt_k_sc_tcnt			[i*32+:32]				)	,
		.	gtx_debug_signal					(   gtx_debug_signal		[i*32+:32]				)	,
		.	rmv_fifo_afu_cnt					(   rmv_fifo_afu_cnt		[i*32+:32]				)	,
		.	par_fifo_afu_cnt					(   par_fifo_afu_cnt		[i*32+:32]				)	,
		.	sopdat_match_cnt					(   sopdat_match_cnt		[i*32+:32]				)	,
		.	sft_gtrx_sop_cnt					(   sft_gtrx_sop_cnt		[i*32+:32]				)	,
		.	rmv_gtrx_sop_cnt					(   rmv_gtrx_sop_cnt		[i*32+:32]				)	,
		.	par_gtrx_sop_cnt					(   par_gtrx_sop_cnt		[i*32+:32]				)	,

		.sr_iotx_tvalid							(   srio_iotx_tvalid		[i* 1+: 1]				)	,
		.sr_iotx_tready							(   srio_iotx_tready		[i* 1+: 1]				)	,
		.sr_iotx_tlast							(   srio_iotx_tlast			[i* 1+: 1]				)	,
		.sr_iotx_tdata							(   srio_iotx_tdata			[i*64+:64]				)	,
		.sr_iotx_tkeep							(   srio_iotx_tkeep			[i* 8+: 8]				)	,
		.sr_iotx_tuser							(   srio_iotx_tuser			[i*32+:32]				)	,

	//	.sr_iorx_tvalid							(   srio_iorx_tvalid		[i* 1+: 1]				)	,
	//	.sr_iorx_tready							(   srio_iorx_tready		[i* 1+: 1]				)	,
		.sr_iorx_tvalid							(	sp_rx_tvalid		[i* 1+: 1]				)	,
		.sr_iorx_tready							(	sp_rx_tready		[i* 1+: 1]				)	,
		.sr_iorx_tlast							(	sp_rx_tlast			[i* 1+: 1]				)	,
		.sr_iorx_tdata							(	sp_rx_tdata			[i*64+:64]				)	,
		.sr_iorx_tkeep							(	sp_rx_tkeep			[i* 8+: 8]				)	,
		.sr_iorx_tuser							(	sp_rx_tuser			[i*32+:32]				)	,

		.maintr_rst								(   srio_maintr_rst			[i* 1+: 1]				)	,
		.maintr_awvalid							(   srio_maintr_awvalid	    [i* 1+: 1]				)	,
		.maintr_awready  						(   srio_maintr_awready	    [i* 1+: 1]				)	,
		.maintr_awaddr   						(   srio_maintr_awaddr	    [i*32+:32]				)	,
		.maintr_wvalid   						(   srio_maintr_wvalid	    [i* 1+: 1]				)	,
		.maintr_wready   						(   srio_maintr_wready	    [i* 1+: 1]				)	,
		.maintr_wdata    						(   srio_maintr_wdata		[i*32+:32]				)	,
		.maintr_bvalid   						(   srio_maintr_bvalid	    [i* 1+: 1]				)	,
		.maintr_bready   						(   srio_maintr_bready	    [i* 1+: 1]				)	,
		.maintr_bresp    						(   srio_maintr_bresp		[i* 2+: 2]				)	,
		.maintr_arvalid  						(   srio_maintr_arvalid	    [i* 1+: 1]				)	,
		.maintr_arready  						(   srio_maintr_arready	    [i* 1+: 1]				)	,
		.maintr_araddr   						(   srio_maintr_araddr	    [i*32+:32]				)	,
		.maintr_rvalid   						(   srio_maintr_rvalid	    [i* 1+: 1]				)	,
		.maintr_rready   						(   srio_maintr_rready	    [i* 1+: 1]				)	,
		.maintr_rdata    						(   srio_maintr_rdata		[i*32+:32]				)	,
		.maintr_rresp    						(   srio_maintr_rresp		[i* 2+: 2]				)
	);
	`ifdef	ENABLE_SIM
	axis_rx_gather_top#(
		.	DW		(	SRIO_DW		)	,
		.	QW		(	SRIO_DW		)
	)sp_gather(
		.	dma_size_set		(	dma_size_set													)			,	//	input		[	31				:	0	]
		.	dma_wait_set		(	dma_wait_set													)			,	//	input		[	31				:	0	]
		.	axsr_tdata			(	dma_rio_rx_tdata	[	i	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	input		[	63				:	0	]
		.	axsr_tid			(	dma_rio_rx_tid		[	i	*	4			+:	4			]	)			,	//	input		[	3				:	0	]
		.	axsr_tready			(	dma_rio_rx_tready	[	i	*	1			+:	1			]	)			,	//	output
		.	axsr_tvalid			(	dma_rio_rx_tvalid	[	i	*	1			+:	1			]	)			,	//	input
		.	axsr_tstrb			(	dma_rio_rx_tstrb	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]
		.	axsr_tkeep			(	dma_rio_rx_tkeep	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]
		.	axsr_tlast			(	dma_rio_rx_tlast	[	i	*	1			+:	1			]	)			,	//	input
		.	axsr_tuser			(	dma_rio_rx_tuser	[	i	*	64			+:	64			]	)			,	//	input		[	63				:	0	]
		.	axsr_tdest			(	dma_rio_rx_tdest	[	i	*	4			+:	4			]	)			,	//	input		[	3				:	0	]
		.	i_rst				(	sys_rst															)			,	//	input
		.	i_clk				(	fst_clk															)			,	//	input
		.	axst_tdata			(	dma_rio_gt_tdata	[	i	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	output		[	QW		-	1	:	0	]
		.	axst_tid			(	dma_rio_gt_tid		[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]
		.	axst_tready			(	dma_rio_gt_tready	[	i	*	1			+:	1			]	)			,	//	input
		.	axst_tvalid			(	dma_rio_gt_tvalid	[	i	*	1			+:	1			]	)			,	//	output
		.	axst_tstrb			(	dma_rio_gt_tstrb	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]
		.	axst_tkeep			(	dma_rio_gt_tkeep	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]
		.	axst_tlast			(	dma_rio_gt_tlast	[	i	*	1			+:	1			]	)			,	//	output
		.	axst_tuser			(	dma_rio_gt_tuser	[	i	*	64			+:	64			]	)			,	//	output		[	64		-	1	:	0	]
		.	axst_tdest			(	dma_rio_gt_tdest	[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]
		.	o_rst				(	sys_rst															)			,	//	input
		.	o_clk				(	fst_clk															)			 	//	input
	);

	if(i != VIDEO_DMA_CH) begin : i_SP_RX_CONVERT_G
	axis_convert_top#(
		.	LOOP_NUM(  i			)	,
		.	DW		(	SRIO_DW	)	,
		.	QW		(	PCIE_DW	)
	)sp_rx_convert(
		.	axsr_tvalid			(	dma_rio_gt_tvalid	[	i	*	1			+:	1			]	)			,	//	input
		.	axsr_tready			(	dma_rio_gt_tready	[	i	*	1			+:	1			]	)			,	//	output
		.	axsr_tlast			(	dma_rio_gt_tlast	[	i	*	1			+:	1			]	)			,	//	input
		.	axsr_tdata			(	dma_rio_gt_tdata	[	i	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	input		[	63				:	0	]
		.	axsr_tuser			(	dma_rio_gt_tuser	[	i	*	64			+:	64			]	)			,	//	input		[	63				:	0	]
		.	axsr_tkeep			(	dma_rio_gt_tkeep	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]
		.	axsr_tstrb			(	dma_rio_gt_tstrb	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]
		.	axsr_tdest			(	dma_rio_gt_tdest	[	i	*	4			+:	4			]	)			,	//	input		[	3				:	0	]
		.	axsr_tid			(	dma_rio_gt_tid		[	i	*	4			+:	4			]	)			,	//	input		[	3				:	0	]
		.	i_rst				(	sys_rst															)			,	//	input
		.	i_clk				(	fst_clk															)			,	//	input
		.	axst_tvalid			(	dma_s_axis_tvalid	[	i	*	1			+:	1			]	)			,	//	output
		.	axst_tready			(	dma_s_axis_tready	[	i	*	1			+:	1			]	)			,	//	input
		.	axst_tlast			(	dma_s_axis_tlast	[	i	*	1			+:	1			]	)			,	//	output
		.	axst_tdata			(	dma_s_axis_tdata	[	i	*	PCIE_DW		+:	PCIE_DW		]	)			,	//	output		[	QW		-	1	:	0	]
		.	axst_tuser			(	dma_s_axis_tuser	[	i	*	64			+:	64			]	)			,	//	output		[	QW		-	1	:	0	]
		.	axst_tkeep			(	dma_s_axis_tkeep	[	i	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]
		.	axst_tstrb			(	dma_s_axis_tstrb	[	i	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]
		.	axst_tdest			(	dma_s_axis_tdest	[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]
		.	axst_tid			(	dma_s_axis_tid		[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]
		.	o_rst				(	pcie_rst														)			,	//	input
		.	o_clk				(	pcie_clk														)			 	//	input
	);
	end else begin : i_VIDEO_DMA_SKIP_G
		assign dma_rio_gt_tready[i*1+:1] = 1'b1;
	end

	axis_convert_top#(
		.	DW		(	PCIE_DW		)	,
		.	QW		(	SRIO_DW		)
	)sp_tx_convert(
		.	axsr_tvalid			(	dma_m_axis_tvalid	[	i	*	1			+:	1			]	)			,	//	input
		.	axsr_tready			(	dma_m_axis_tready	[	i	*	1			+:	1			]	)			,	//	output
		.	axsr_tlast			(	dma_m_axis_tlast	[	i	*	1			+:	1			]	)			,	//	input
		.	axsr_tdata			(	dma_m_axis_tdata	[	i	*	PCIE_DW		+:	PCIE_DW		]	)			,	//	input		[	DW		-	1	:	0	]
		.	axsr_tuser			(	dma_m_axis_tuser	[	i	*	64			+:	64			]	)			,	//	input		[	64		-	1	:	0	]
		.	axsr_tkeep			(	dma_m_axis_tkeep	[	i	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	input		[	DW/8	-	1	:	0	]
		.	axsr_tstrb			(	dma_m_axis_tstrb	[	i	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	input		[	DW/8	-	1	:	0	]
		.	axsr_tdest			(	dma_m_axis_tdest	[	i	*	4			+:	4			]	)			,	//	input		[	4		-	1	:	0	]
		.	axsr_tid			(	dma_m_axis_tid		[	i	*	4			+:	4			]	)			,	//	input		[	4		-	1	:	0	]
		.	i_rst				(	pcie_rst														)			,	//	input
		.	i_clk				(	pcie_clk														)			,	//	input
		.	axst_tvalid			(	dma_rio_tx_tvalid	[	i	*	1			+:	1			]	)			,	//	output
		.	axst_tready			(	dma_rio_tx_tready	[	i	*	1			+:	1			]	)			,	//	input
		.	axst_tlast			(	dma_rio_tx_tlast	[	i	*	1			+:	1			]	)			,	//	output
		.	axst_tdata			(	dma_rio_tx_tdata	[	i	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	output		[	QW		-	1	:	0	]
		.	axst_tuser			(	dma_rio_tx_tuser	[	i	*	64			+:	64			]	)			,	//	output		[	64		-	1	:	0	]
		.	axst_tkeep			(	dma_rio_tx_tkeep	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]
		.	axst_tstrb			(	dma_rio_tx_tstrb	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]
		.	axst_tdest			(	dma_rio_tx_tdest	[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]
		.	axst_tid			(	dma_rio_tx_tid		[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]
		.	o_rst				(	sys_rst															)			,	//	input
		.	o_clk				(	fst_clk															)			 	//	input
	);
	`endif
end
endgenerate



//==================================================================================================
//--BM Instance

generate if(PARAM_ENABLE_BM==1||PARAM_ENABLE_GT==1) begin:i_BM_G
	bm_top	#(
		.	DMA_DW								(	PCIE_DW																	)	,
		.	TIMER_PERIOD						(	TIMER_PERIOD															)	,
		.	P_SIMULATION_R						(	P_SIMULATION_R															)	,
		.	P_Srio_CH_NUM_R						(	P_Srio_CH_NUM_R															)
	)
	i_bm_top (
		.	clk									( fst_clk																	),
		.	dma_clk								( pcie_clk																	),
		.	rst									( sys_rst																	),
		.	srio_rst							( 1'b0																		),
		.	c_bm_timestamp						( c_bm_timestamp															),
		.	c_bm_timestamp_rf					( c_bm_timestamp_rf															),

		.	c_bm_en								( c_bm_ch_en				[	0	+:	P_Srio_CH_NUM_R	*	1	]			),
		.	c_bm_up_cnt							( c_bm_up_cnt				[	0	+:	1				*	32	]			),
		.	c_bm_ch_recv_cnt					( c_bm_ch_recv_cnt			[	0	+:	P_Srio_CH_NUM_R	*	32	]			),
		.	c_bm_ch_up_cnt						( c_bm_ch_up_cnt			[	0	+:	P_Srio_CH_NUM_R	*	32	]			),
		.	c_bm_ch_lost_cnt					( c_bm_ch_lost_cnt			[	0	+:	P_Srio_CH_NUM_R	*	32	]			),
		.	c_bm_ch_terr_cnt					( c_bm_ch_terr_cnt			[	0	+:	P_Srio_CH_NUM_R	*	32	]			),
		.	c_bm_ch_derr_cnt					( c_bm_ch_derr_cnt			[	0	+:	P_Srio_CH_NUM_R	*	32	]			),
		.	c_bm_rtready_en						( c_bm_rtready_en			[	0	+:	P_Srio_CH_NUM_R	*	1	]			),

		.	dma_size_set						( dma_size_set				[31:0]					),
		.	dma_wait_set						( dma_wait_set				[31:0]					),

		.	dma_s_axis_tdata					( dma_s_axis_tdata			[P_BM_DMA_R*	PCIE_DW		+:	PCIE_DW		]	),
		.	dma_s_axis_tid						( dma_s_axis_tid			[P_BM_DMA_R*	 4			+:	 4			]	),
		.	dma_s_axis_tready					( dma_s_axis_tready			[P_BM_DMA_R*	 1			+:	 1			]	),
		.	dma_s_axis_tvalid					( dma_s_axis_tvalid			[P_BM_DMA_R*	 1			+:	 1			]	),
		.	dma_s_axis_tstrb					( dma_s_axis_tstrb			[P_BM_DMA_R*	PCIE_DW/8	+:	PCIE_DW/8	]	),
		.	dma_s_axis_tkeep					( dma_s_axis_tkeep			[P_BM_DMA_R*	PCIE_DW/8	+:	PCIE_DW/8	]	),
		.	dma_s_axis_tlast					( dma_s_axis_tlast			[P_BM_DMA_R*	 1			+:	 1			]	),
		.	dma_s_axis_tuser					( dma_s_axis_tuser			[P_BM_DMA_R*	64			+:	64			]	),
		.	dma_s_axis_tdest					( dma_s_axis_tdest			[P_BM_DMA_R*	 4			+:	 4			]	),

`ifdef	ENABLE_BM
		.	log_clk								( sp_log_clk				[0+:P_Srio_CH_NUM_R* 1]							),
`else
		.	log_clk								( {{P_Srio_CH_NUM_R}{fst_clk}}												),
`endif
	//	.	rx_tvalid							( srio_iorx_tvalid			[0+:P_Srio_CH_NUM_R* 1]							),
	//	.	rx_tready							( srio_iorx_tready			[0+:P_Srio_CH_NUM_R* 1]							),
		.	rx_tvalid							( srio_bmrx_tvalid			[0+:P_Srio_CH_NUM_R* 1]							),
		.	rx_tready							( srio_bmrx_tready			[0+:P_Srio_CH_NUM_R* 1]							),
		.	rx_tlast							( srio_iorx_tlast			[0+:P_Srio_CH_NUM_R* 1]							),
		.	rx_tdata							( srio_iorx_tdata			[0+:P_Srio_CH_NUM_R*64]							),
		.	rx_tkeep							( srio_iorx_tkeep			[0+:P_Srio_CH_NUM_R* 8]							),
		.	rx_tuser							( srio_iorx_tuser			[0+:P_Srio_CH_NUM_R*32]							)
	);
end	endgenerate

	reg		[	1	*	32	-1:0]	log_clk_cnt	=	0			;	always@(posedge	sp_log_clk[0])	log_clk_cnt	<=	log_clk_cnt	+	1	;
	wire	[	1	*	4	-1:0]	srio_clk_cnt				;	assign	srio_clk_cnt	=	log_clk_cnt[31:28]	;
	reg		[	1	*	12	-1:0]	srio_iotx_trvl_cnt	=	0	;
	reg		[	1	*	12	-1:0]	srio_iorx_trvl_cnt	=	0	;
	always@(posedge	sp_log_clk[0])	srio_iotx_trvl_cnt	<=	sys_rst	?	0	:	srio_iotx_tvalid[0]&&srio_iotx_tready[0]&&srio_iotx_tlast[0]	?	srio_iotx_trvl_cnt+1	:	srio_iotx_trvl_cnt	;
	always@(posedge	sp_log_clk[0])	srio_iorx_trvl_cnt	<=	sys_rst	?	0	:	srio_iorx_tvalid[0]&&srio_iorx_tready[0]&&srio_iorx_tlast[0]	?	srio_iorx_trvl_cnt+1	:	srio_iorx_trvl_cnt	;

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
		.	led								(									)	,	//		output	[	3		-	1	:	0]
		.	c_os_config						(		c_os_config					)	,	//		input
		.	c_os_big_endian					(		c_os_big_endian				)	,	//		input
		.	pcie_far_id						(		pcie_far_id					)	,	//		input
		.	pcie_dev_id						(		pcie_dev_id					)	,	//		input
		.	mmcm_lock                        (		mmcm_lock					)	,
		.	srio_clk_cnt					(		srio_clk_cnt				)	,	//		input	[	16		-	1	:	0]
		.	srio_iotx_trvl_cnt				(		srio_iotx_trvl_cnt			)	,	//		input	[	16		-	1	:	0]
		.	srio_iorx_trvl_cnt				(		srio_iorx_trvl_cnt			)	,	//		input	[	16		-	1	:	0]
		.	srio_port_error					(		srio_port_error				)	,	//		input
		.	srio_port_initialized			(		srio_port_initialized		)	,	//		input
		.	srio_link_initialized			(		srio_link_initialized		)	,	//		input
		.	srio_mode_1x					(		srio_mode_1x				)	,	//		input
		.	srio_force_reinit				(		srio_force_reinit			)	,	//		input
		.	sys_rst							(		sys_rst						)	,	//		input
		.	sys_rst_n_in_c					(		sys_rst_n					)	,	//		input

		.	sys_rst_n_c						(		sys_rst_n_c					)	,
		.	soft_rst						(		vio_rst						)	,
		.	pcie_clk						(		pcie_clk					)	,	//		input
		.	pcie_rst						(		pcie_rst					)		//		input

	);

//==================================================================================================
//--Flash
	wire			[3:0]					spi_0_dq_i 			,		spi_1_dq_i 			;
	wire			[3:0]					spi_0_dq_o			,		spi_1_dq_o			;
	wire			[3:0]					spi_0_dq_t 			,		spi_1_dq_t 			;
	wire									spi_0_sck_i			,		spi_1_sck_i			;
	wire									spi_0_sck_o			,		spi_1_sck_o			;
	wire									spi_0_sck_t			,		spi_1_sck_t			;
	wire									spi_0_ss_i			,		spi_1_ss_i			;
	wire									spi_0_ss_o			,		spi_1_ss_o			;
	wire									spi_0_ss_t			,		spi_1_ss_t			;

//	IBUF   EMCCLK_IBUF_inst 				(.O(flash_clk), .I(EMCCLK))						;
`ifdef		KU
	axi_quad_spi_0	axi_quad_spi_0	(
		.	ext_spi_clk		(		flash_clk									)	,	//	input	wire	ext_spi_clk
		.	s_axi_aclk		(		flash_clk									)	,	//	input	wire	s_axi_aclk
		.	s_axi_aresetn	(	~	pcie_rst									)	,	//	input	wire	s_axi_aresetn
		.	s_axi_awaddr	(	master_axi_awaddr	[	1	*	32	+: 32	]	)	,	//	input	wire	[6	:	0]	s_axi_awaddr
		.	s_axi_awvalid	(	master_axi_awvalid	[	1	*	1	+: 1	]	)	,	//	input	wire				s_axi_awvalid
		.	s_axi_awready	(	master_axi_awready	[	1	*	1	+: 1	]	)	,	//	output	wire				s_axi_awready
		.	s_axi_wdata		(	master_axi_wdata	[	1	*	32	+: 32	]	)	,	//	input	wire	[31	:	0]	s_axi_wdata
		.	s_axi_wstrb		(	master_axi_wstrb	[	1	*	4	+: 4	]	)	,	//	input	wire	[3	:	0]	s_axi_wstrb
		.	s_axi_wvalid	(	master_axi_wvalid	[	1	*	1	+: 1	]	)	,	//	input	wire				s_axi_wvalid
		.	s_axi_wready	(	master_axi_wready	[	1	*	1	+: 1	]	)	,	//	output	wire				s_axi_wready
		.	s_axi_bresp		(	master_axi_bresp	[	1	*	2	+: 2	]	)	,	//	output	wire	[1	:	0]	s_axi_bresp
		.	s_axi_bvalid	(	master_axi_bvalid	[	1	*	1	+: 1	]	)	,	//	output	wire				s_axi_bvalid
		.	s_axi_bready	(	master_axi_bready	[	1	*	1	+: 1	]	)	,	//	input	wire				s_axi_bready
		.	s_axi_araddr	(	master_axi_araddr	[	1	*	32	+: 32	]	)	,	//	input	wire	[6	:	0]	s_axi_araddr
		.	s_axi_arvalid	(	master_axi_arvalid	[	1	*	1	+: 1	]	)	,	//	input	wire				s_axi_arvalid
		.	s_axi_arready	(	master_axi_arready	[	1	*	1	+: 1	]	)	,	//	output	wire				s_axi_arready
		.	s_axi_rdata		(	master_axi_rdata	[	1	*	32	+: 32	]	)	,	//	output	wire	[31	:	0]	s_axi_rdata
		.	s_axi_rresp		(	master_axi_rresp	[	1	*	2	+: 2	]	)	,	//	output	wire	[1	:	0]	s_axi_rresp
		.	s_axi_rvalid	(	master_axi_rvalid	[	1	*	1	+: 1	]	)	,	//	output	wire				s_axi_rvalid
		.	s_axi_rready	(	master_axi_rready	[	1	*	1	+: 1	]	)	,	//	input	wire				s_axi_rready
		.	io0_i			(		spi_0_dq_i[0]								)	,	//	input	wire	io0_i
		.	io0_o			(		spi_0_dq_o[0]								)	,	//	output	wire	io0_o
		.	io0_t			(		spi_0_dq_t[0]								)	,	//	output	wire	io0_t
		.	io1_i			(		spi_0_dq_i[1]								)	,	//	input	wire	io1_i
		.	io1_o			(		spi_0_dq_o[1]								)	,	//	output	wire	io1_o
		.	io1_t			(		spi_0_dq_t[1]								)	,	//	output	wire	io1_t
		.	io2_i			(		spi_0_dq_i[2]								)	,	//	input	wire	io2_i
		.	io2_o			(		spi_0_dq_o[2]								)	,	//	output	wire	io2_o
		.	io2_t			(		spi_0_dq_t[2]								)	,	//	output	wire	io2_t
		.	io3_i			(		spi_0_dq_i[3]								)	,	//	input	wire	io3_i
		.	io3_o			(		spi_0_dq_o[3]								)	,	//	output	wire	io3_o
		.	io3_t			(		spi_0_dq_t[3]								)	,	//	output	wire	io3_t

		.	io0_1_i			(		spi_1_dq_i[0]								)	,	//	input	wire	io0_1_i
		.	io0_1_o			(		spi_1_dq_o[0]								)	,	//	output	wire	io0_1_o
		.	io0_1_t			(		spi_1_dq_t[0]								)	,	//	output	wire	io0_1_t
		.	io1_1_i			(		spi_1_dq_i[1]								)	,	//	input	wire	io1_1_i
		.	io1_1_o			(		spi_1_dq_o[1]								)	,	//	output	wire	io1_1_o
		.	io1_1_t			(		spi_1_dq_t[1]								)	,	//	output	wire	io1_1_t
		.	io2_1_i			(		spi_1_dq_i[2]								)	,	//	input	wire	io2_1_i
		.	io2_1_o			(		spi_1_dq_o[2]								)	,	//	output	wire	io2_1_o
		.	io2_1_t			(		spi_1_dq_t[2]								)	,	//	output	wire	io2_1_t
		.	io3_1_i			(		spi_1_dq_i[3]								)	,	//	input	wire	io3_1_i
		.	io3_1_o			(		spi_1_dq_o[3]								)	,	//	output	wire	io3_1_o
		.	io3_1_t			(		spi_1_dq_t[3]								)	,	//	output	wire	io3_1_t

		.	sck_i			(		spi_0_sck_i									)	,	//	input	wire	sck_i
		.	sck_o			(		spi_0_sck_o									)	,	//	output	wire	sck_o
		.	sck_t			(		spi_0_sck_t									)	,	//	output	wire	sck_t
		.	ss_i			(		spi_0_ss_i									)	,	//	input	wire	[0	:	0]	ss_i
		.	ss_o			(		spi_0_ss_o									)	,	//	output	wire	[0	:	0]	ss_o
		.	ss_t			(		spi_0_ss_t									)	,	//	output	wire	ss_t

		.	ss_1_i			(		spi_1_ss_i									)	,	//	input	wire	ss_1_i
		.	ss_1_o			(		spi_1_ss_o									)	,	//	output	wire	ss_1_o
		.	ss_1_t			(		spi_1_ss_t									)	,	//	output	wire	ss_1_t

		.	ip2intc_irpt	(													)		//	output	wire	ip2intc_irpt
	)	;

	STARTUPE3	#(
		.PROG_USR			(	"FALSE"	)	,	//	Activate program event security feature. Requires encrypted bitstreams.
		.SIM_CCLK_FREQ		(	0.0		)		//	Set the Configuration Clock Frequency ( ns  ) for simulation
	)
	STARTUPE3_inst	(
			.	CFGCLK		(					)	,	//	1-bit output: Configuration main clock output
			.	CFGMCLK		(					)	,	//	1-bit output: Configuration internal oscillator clock output
			.	DI			(	spi_0_dq_i		)	,	//	4-bit output: Allow receiving on the D input pin
			.	EOS			(					)	,	//	1-bit output: Active-High output signal indicating the End Of Startup
			.	PREQ		(					)	,	//	1-bit output: PROGRAM request to fabric output
			.	DO			(	spi_0_dq_o		)	,	//	4-bit input: Allows control of the D pin output
			.	DTS			(	spi_0_dq_t		)	,	//	4-bit input: Allows tristate of the D pin
			.	FCSBO		(	spi_0_ss_o		)	,	//	1-bit input: Controls the FCS_B pin for flash access
			.	FCSBTS		(	spi_0_ss_t		)	,	//	1-bit input: Tristate the FCS_B pin
			.	GSR			(	0				)	,	//	1-bit input: Global Set/Reset input    ( GSR cannot be used for the port  )
			.	GTS			(	0				)	,	//	1-bit input: Global 3-state input    ( GTS cannot be used for the port name  )
			.	KEYCLEARB	(	1				)	,	//	1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM    ( BBRAM  )
			.	PACK		(	0				)	,	//	1-bit input: PROGRAM acknowledge input
			.	USRCCLKO	(	spi_0_sck_o		)	,	//	1-bit input: User CCLK input
			.	USRCCLKTS	(	spi_0_sck_t		)	,	//	1-bit input: User CCLK 3-state enable input
			.	USRDONEO	(	1				)	,	//	1-bit input: User DONE pin output control
			.	USRDONETS	(	1				)		//	1-bit input: User DONE 3-state enable output
	);


	generate
	genvar  j;
		for (j = 0; j <= 3; j = j + 1)
			begin : SPI_1_IO
			IOBUF IOBUF_io (
				.	IO   (	spi_1_dq	[j]		)	,
				.	I    (	spi_1_dq_o	[j]		)	,
				.	O    (	spi_1_dq_i	[j]		)	,
				.	T    (	spi_1_dq_t	[j]		)	?
			);
		end
	endgenerate

			IOBUF IOBUF_ss (
				.	IO   (	spi_1_ss			)	,
				.	I    (	spi_1_ss_o			)	,
				.	O    (	spi_1_ss_i			)	,
				.	T    (	spi_1_ss_t			)
			);

//	ila__d1024 ila_w32_d1024_spi (
//		.	clk		(	flash_clk	)	,	// input wire clk
//		.	probe0	(	{
//
//							spi_0_dq_i		,
//							spi_0_dq_o		,
//							spi_0_dq_t		,
//
//							spi_1_dq_i		,
//							spi_1_dq_o		,
//							spi_1_dq_t		,
//
//							spi_0_sck_i		,
//							spi_0_sck_o		,
//							spi_0_sck_t		,
//							spi_0_ss_i		,
//							spi_0_ss_o		,
//							spi_0_ss_t		,
//
//							spi_1_ss_i		,
//							spi_1_ss_o		,
//							spi_1_ss_t
//
//						}
//		)		// input wire [31:0] probe0
//	);

`else	//	K7Z7
	axi_quad_spi_0 axi_quad_spi_0	(

		.	ext_spi_clk						(		flash_clk								)	,
		.	s_axi_aclk						(		flash_clk								)	,
		.	s_axi_aresetn					(	~	pcie_rst								)	,

		.	s_axi_awaddr					(	master_axi_awaddr	    	[1*32 +: 32]	)	,
		.	s_axi_awvalid					(	master_axi_awvalid			[1* 1 +:  1]	)	,
		.	s_axi_awready					(	master_axi_awready			[1* 1 +:  1]	)	,

		.	s_axi_wdata						(	master_axi_wdata	    	[1*32 +: 32]	)	,
		.	s_axi_wstrb						(	master_axi_wstrb	    	[1* 4 +:  4]	)	,
		.	s_axi_wvalid					(	master_axi_wvalid	    	[1* 1 +:  1]	)	,
		.	s_axi_wready					(	master_axi_wready	    	[1* 1 +:  1]	)	,

		.	s_axi_bresp						(	master_axi_bresp	    	[1* 2 +:  2]	)	,
		.	s_axi_bvalid					(	master_axi_bvalid	    	[1* 1 +:  1]	)	,
		.	s_axi_bready					(	master_axi_bready	    	[1* 1 +:  1]	)	,

		.	s_axi_araddr					(	master_axi_araddr	    	[1*32 +: 32]	)	,
		.	s_axi_arvalid					(	master_axi_arvalid			[1* 1 +:  1]	)	,
		.	s_axi_arready					(	master_axi_arready			[1* 1 +:  1]	)	,

		.	s_axi_rdata						(	master_axi_rdata	    	[1*32 +: 32]	)	,
		.	s_axi_rresp						(	master_axi_rresp	    	[1* 2 +:  2]	)	,
		.	s_axi_rvalid					(	master_axi_rvalid	    	[1* 1 +:  1]	)	,
		.	s_axi_rready					(	master_axi_rready     		[1* 1 +:  1]	)	,

		.	io0_i							(	spi_0_dq_i[0]								)	,
		.	io0_o							(	spi_0_dq_o[0]								)	,
		.	io0_t							(	spi_0_dq_t[0]								)	,
		.	io1_i							(	spi_0_dq_i[1]								)	,
		.	io1_o							(	spi_0_dq_o[1]								)	,
		.	io1_t							(	spi_0_dq_t[1]								)	,
	//	.	io2_i							(	spi_0_dq_i[2]								)	,
	//	.	io2_o							(	spi_0_dq_o[2]								)	,
	//	.	io2_t							(	spi_0_dq_t[2]								)	,
	//	.	io3_i							(	spi_0_dq_i[3]								)	,
	//	.	io3_o							(	spi_0_dq_o[3]								)	,
	//	.	io3_t							(	spi_0_dq_t[3]								)	,
		.	ss_i							(	spi_0_ss_i									)	,
		.	ss_o							(	spi_0_ss_o									)	,
		.	ss_t							(	spi_0_ss_t									)	,

		.	cfgclk							(												)	,
		.	cfgmclk							(												)	,
		.	eos								(												)	,
		.	preq							(												)	,
		.	ip2intc_irpt					(												)

	);

	generate
	genvar  j;
		for (j = 0; j <= 1; j = j + 1)
			begin : bidir_IO
			IOBUF IOBUF_i (
				.	IO   (	spi_0_dq	[j]		)	,	//flash_data
				.	I    (	spi_0_dq_o	[j]		)	,
				.	O    (	spi_0_dq_i	[j]		)	,
				.	T    (	spi_0_dq_t	[j]		)		//高阻位
			);
		end
	endgenerate

			IOBUF IOBUF_ss (
				.	IO   (	spi_0_ss			)	,//flash_csn
				.	I    (	spi_0_ss_o			)	,
				.	O    (	spi_0_ss_i			)	,
				.	T    (	spi_0_ss_t			)
			);

	reg				[1:0]				reg_spi_0_dq_i 			;	always@(posedge	flash_clk)	reg_spi_0_dq_i	<=	spi_0_dq_i	;
	reg				[1:0]				reg_spi_0_dq_o			;	always@(posedge	flash_clk)	reg_spi_0_dq_o	<=	spi_0_dq_o	;
	reg				[1:0]				reg_spi_0_dq_t 			;	always@(posedge	flash_clk)	reg_spi_0_dq_t	<=	spi_0_dq_t	;
	reg									reg_spi_0_ss_i			;	always@(posedge	flash_clk)	reg_spi_0_ss_i	<=	spi_0_ss_i	;
	reg									reg_spi_0_ss_o			;	always@(posedge	flash_clk)	reg_spi_0_ss_o	<=	spi_0_ss_o	;
	reg									reg_spi_0_ss_t			;	always@(posedge	flash_clk)	reg_spi_0_ss_t	<=	spi_0_ss_t	;



/*

   	ila_576X1024 ila_w32_d1024_dma (
   		.	clk		(	pcie_clk	)	,	// input wire clk
   		.	probe0	(
   						{

   					dma_m_axis_tdata	 	[1*DW-1 : 0]	,
   				//	dma_m_axis_tid		 	[1*4-1  : 0]	,
   					dma_m_axis_tready	 	[1*1-1	: 0]	,
   					dma_m_axis_tvalid	 	[1*1-1	: 0]	,
   					dma_m_axis_tstrb	 	[1*8-1	: 0]	,
   				//	dma_m_axis_tkeep	 	[1*8-1	: 0]	,
   					dma_m_axis_tlast	 	[1*1-1	: 0]	,
   					dma_m_axis_tuser	 	[1*64-1	: 0]	,
   				//	dma_m_axis_tdest	 	[1*4-1	: 0]	,

   					dma_s_axis_tdata	 	[1*DW-1 : 0]	,
   					//dma_s_axis_tid		[1*4-1  : 0]	,
   					dma_s_axis_tready	 	[1*1-1	: 0]	,
   					dma_s_axis_tvalid	 	[1*1-1	: 0]	,
   					//dma_s_axis_tstrb	 	[1*8-1	: 0]	,
   					dma_s_axis_tkeep	 	[1*8-1	: 0]	,
   					dma_s_axis_tlast	 	[1*1-1	: 0]	,
   					dma_s_axis_tuser	 	[1*64-1	: 0]
   					//dma_s_axis_tdest	 	[1*4-1	: 0]	,


   						}
   		)		// input wire [31:0] probe0
   	);


   	ila_576X1024 ila_w32_d1024_srio (
   		.	clk		(	fst_clk	)	,	// input wire clk
   		.	probe0	(
   						{

   					 dma_rio_tx_tvalid			[0* 1+: 1]		,
   					 dma_rio_tx_tready			[0* 1+: 1]		,
   					 dma_rio_tx_tlast			[0* 1+: 1]		,
   					 dma_rio_tx_tdata			[0*64+:64]	 	,
   					 dma_rio_tx_tkeep			[0* 8+: 8]		,
   					 dma_rio_tx_tuser			[0*32+:32]		,


   				 	dma_rio_gt_tvalid			[0* 1+: 1]		,
   					dma_rio_gt_tready			[0* 1+: 1]		,
   					dma_rio_gt_tlast			[0* 1+: 1]		,
   					dma_rio_gt_tdata			[0*64+:64]		,
   					dma_rio_gt_tkeep			[0* 8+: 8]		,
   					dma_rio_gt_tuser			[0*32+:32]		,

   					 dma_rio_rx_tvalid			[0* 1+: 1]		,
   					 dma_rio_rx_tready			[0* 1+: 1]		,
   					 dma_rio_rx_tlast			[0* 1+: 1]		,
   					 dma_rio_rx_tdata			[0*64+:64]	 	,
   					 dma_rio_rx_tkeep			[0* 8+: 8]		,
   					 dma_rio_rx_tuser			[0*32+:32]


   						}
   		)		// input wire [31:0] probe0
   	);




   	*/



`endif


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
