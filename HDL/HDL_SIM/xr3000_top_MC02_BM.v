`timescale 1ns/1ns











//	`define	PCI_AXIS_LOOPBACK
//	`define	DMA_AXIS_LOOPBACK
//	`define	RIO_AXIS_LOOPBACK
//	`define	DN_USER_DDR3
//	`define	ENABLE_SIM_ONLY
//	`define	ENABLE_BM_ONLY
	`define	ENABLE_BM_SIM

//	`include "xr3000_top_MC02_BM_define.v"
//////////////////////////////////////////////////////////////////////////////////////////////////
module	xr3000_top_MC02_BM	#(
//==================================================================================================
//--parameter Instantation
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	--------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"									,

	/*--------------------------------------------------------------------------------------
	--Version Information
	--------------------------------------------------------------------------------------*/
	parameter		P_Version1_R				= 32'h2021_0106								,
	parameter		P_Version2_R				= 32'h1208_1000								,

	/*--------------------------------------------------------------------------------------
	--SRIO Config
	--------------------------------------------------------------------------------------*/
	parameter		P_Srio_ID_WTH_R				= 16										,	//=8 or 16 ID
	parameter		P_Srio_CH_NUM_R				= 2		,	//	8		,	//				,	//SRIO IP Core number
	parameter		P_Srio_CH_LANE_R			= 4		,	//	1		,	//				,	//1=1x 2=2x 4=4x per srio IP
	parameter		P_Srio_SPEED_R				= 5 										,	//1=1Gbps 2=2.5Gbps 3=3.125Gbps 5=5Gbps 6=6Gbps(not support)
	parameter		P_Srio_PHY_LANE_R			= 8											,	//Physical lane number,board gtx for SRIO
	parameter		P_Srio_BANK_R				= 2											,	//physical bank
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
//==================================================================================================
//--Port Defines

	/*------System Clock and Reset-------*/
	input										sys_rst_n									,

	/*------PCIe Link Port--------*/
	input										pcie_ref_clk_p								,
	input										pcie_ref_clk_n								,

	output			[	PCIE_LW	-	1	:	0]	pci_exp_txp									,
	output			[	PCIE_LW	-	1	:	0]	pci_exp_txn									,
	input			[	PCIE_LW	-	1	:	0]	pci_exp_rxp									,
	input			[	PCIE_LW	-	1	:	0]	pci_exp_rxn									,

	/*--------------------------------------------------------------------------------------
	--SRIO Link Port
	--------------------------------------------------------------------------------------*/
	input			[P_Srio_BANK_R-1:0]			srio_sys_clk_p								,
	input			[P_Srio_BANK_R-1:0]			srio_sys_clk_n								,


	input			[P_Srio_PHY_LANE_R-1:0]		srio_rxn0									,
	input			[P_Srio_PHY_LANE_R-1:0]		srio_rxp0									,
	output			[P_Srio_PHY_LANE_R-1:0]		srio_txn0									,
	output			[P_Srio_PHY_LANE_R-1:0]		srio_txp0									,
	
	output			[	4			-1:0]		bk228_tx_disable							,
	
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
	input										EMCCLK										,
//	inout			[3:0]						flash_data									,
//	output										flash_csn									,
	/*------Other Ports-------*/
	output			[ 2:0]						led											
);
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
		
		localparam			EMCCLK_FREQ_MHZ		=	90	;


		wire										pcie_rst									;
		wire										pcie_clk									;		
		wire										user_lnk_up									;
		wire										phy_rdy_out									;
		
		assign	bk228_tx_disable	=	4'h0	;
		
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
		assign	dma_m_axis_aclk			=	{P_DMA_UP_NUM_R{pcie_clk}}							;	//	sysc	to pcei	user_clk	
		
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
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iotx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iotx_tready							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iotx_tlast								;
	wire			[P_Srio_CH_NUM_R*64-1:0]	srio_iotx_tdata								;
	wire			[P_Srio_CH_NUM_R* 8-1:0]	srio_iotx_tkeep								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	srio_iotx_tuser								;

	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iorx_tvalid							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iorx_tready							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	srio_iorx_tlast								;
	wire			[P_Srio_CH_NUM_R*64-1:0]	srio_iorx_tdata								;
	wire			[P_Srio_CH_NUM_R* 8-1:0]	srio_iorx_tkeep								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	srio_iorx_tuser								;

	/*--------------------------------------------------------------------------------------
	--dma dn/up packet
	--------------------------------------------------------------------------------------*/
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_sp_up_cnt									;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_sp_dn_cnt									;
	
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_recv_cnt							;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_up_cnt								;
	wire			[P_Srio_CH_NUM_R*32-1:0]	c_bm_ch_lost_cnt							;
	wire			[P_Srio_CH_NUM_R* 1-1:0]	c_bm_ch_en									;
	wire			[	1			*32-1:0]	c_bm_up_cnt									;
	
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
//	wire										pcie_reset									;

	wire										flash_clk									;
	/*--------------------------------------------------------------------------------------
	--Interrupt Bus interface
	--------------------------------------------------------------------------------------*/
		wire										interrupt_bus_clk		= pcie_clk			;		
		wire										interrupt_bus_req		= 1'b0				;		
		wire										interrupt_bus_gnt							;		
		wire		[31:16]							interrupt_bus_vector	= 16'b0				;
		
	/*--------------------------------------------------------------------------------------
	--Clock And Reset
	--------------------------------------------------------------------------------------*/
	wire										sys_rst										;
	wire										sys_rst_n_in_c								;

	IBUF   sys_reset_ibuf 						(.O(sys_rst_n_in_c), .I(sys_rst_n))			;

	assign	sys_rst								= ~sys_rst_n_in_c | pcie_rst				;		
	
//==================================================================================================
//--LED控制实现
	/*--------------------------------------------------------------------------------------
	--LED[1:0]分配给PCIE时钟域
	--------------------------------------------------------------------------------------*/
//	(*mark_debug="TRUE"*)
//	wire 										init_calib_complete							;
//	(*mark_debug="TRUE"*)
//	wire 										mmcm_locked									;
//	reg				[27:0]						flash_clk_cnt				= 0				;
//	always @(posedge flash_clk) flash_clk_cnt	<= flash_clk_cnt + 1'b1						;

//	assign	led[0]							 	= flash_clk_cnt[27]							;
//	assign	led[1]								= mmcm_locked								;
//	assign	led[2]								= init_calib_complete						;
//	assign	led[3]								= user_lnk_up 								;
	
	
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
	
//--xr2000_axilite_top Instantation
	wire	[P_AXILITE_CH_NUM_R-1:0]			master_clk									;

	assign	master_clk							=	{
														log_clk[1]							,
														log_clk[0]							,
														flash_clk							,
														pcie_clk
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

genvar jj;

generate for(jj=0;jj<P_Srio_BANK_R;jj=jj+1) begin : i_SUPPT_G
	srio_support	#(
		.P_RIO_AXIS_LOOPBACK					( P_RIO_AXIS_LOOPBACK													),
		.P_Srio_ID_WTH_R						( P_Srio_ID_WTH_R														),
		.P_Srio_CH_NUM_R						( P_BANK_CH_NUM_R														),
		.P_Srio_CH_LANE_R						( P_Srio_CH_LANE_R	        											),
		.P_Srio_SPEED_R							( P_Srio_SPEED_R		    											),
		.P_Srio_PHY_LANE_R						( P_BANK_LANE_R															)
	)
	i_srio_support	(
		.sys_clkp                				( srio_sys_clk_p		[jj]											),
		.sys_clkn                				( srio_sys_clk_n		[jj]											),
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

		.s_axis_iotx_tvalid            			( srio_iotx_tvalid		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.s_axis_iotx_tready            			( srio_iotx_tready		[jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
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

		.gt_txpmaresetdone_out        			( gt_txpmaresetdone_out	[jj* P_BANK_LANE_R* 1 +:  P_BANK_LANE_R* 1]		),

		.port_initialized              			( srio_port_initialized [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.link_initialized              			( srio_link_initialized [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.idle_selected                 			( srio_idle_selected    [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	),
		.mode_1x                       			( srio_mode_1x          [jj*P_BANK_CH_NUM_R* 1 +: P_BANK_CH_NUM_R* 1]	)
	);
end
endgenerate

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
		.clk									( pcie_clk									),
		
			
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

		.c_sp_up_cnt							( {{{8-P_Srio_CH_NUM_R}{32'b0}},c_sp_up_cnt}),	//max 8 channel
		.c_sp_dn_cnt							( {{{8-P_Srio_CH_NUM_R}{32'b0}},c_sp_dn_cnt})
	);

//==================================================================================================
//--BM Instance
`ifdef	ENABLE_BM_ONLY
	bm_top	#(
		.P_SIMULATION_R							( P_SIMULATION_R								)
	)	
	i_bm_top (	
		.clk									( pcie_clk										),
		.rst									( sys_rst										),
		.srio_rst								( 1'b0											),
		.c_bm_timestamp							( c_bm_timestamp								),
		.c_bm_timestamp_rf						( c_bm_timestamp_rf								),
			
		.c_bm_en								( c_bm_ch_en			[ 1:0]					),
		.c_bm_up_cnt							( c_bm_up_cnt			[31:0]					),
		.c_bm_ch_recv_cnt						( c_bm_ch_recv_cnt		[63:0]					),
		.c_bm_ch_up_cnt							( c_bm_ch_up_cnt		[63:0]					),
		.c_bm_ch_lost_cnt						( c_bm_ch_lost_cnt		[63:0]					),
			
		.dma_size_set							( dma_size_set			[31:0]					),
		.dma_wait_set							( dma_wait_set			[31:0]					),
	
		.dma_s_axis_tdata						( dma_rio_rx_tdata		[P_BM_DMA_R*64+:64]		),
		.dma_s_axis_tid							( dma_rio_rx_tid		[P_BM_DMA_R* 4+: 4]		),
		.dma_s_axis_tready						( dma_rio_rx_tready		[P_BM_DMA_R* 1+: 1]		),
		.dma_s_axis_tvalid						( dma_rio_rx_tvalid		[P_BM_DMA_R* 1+: 1]		),
		.dma_s_axis_tstrb						( dma_rio_rx_tstrb		[P_BM_DMA_R* 8+: 8]		),
		.dma_s_axis_tkeep						( dma_rio_rx_tkeep		[P_BM_DMA_R* 8+: 8]		),
		.dma_s_axis_tlast						( dma_rio_rx_tlast		[P_BM_DMA_R* 1+: 1]		),
		.dma_s_axis_tuser						( dma_rio_rx_tuser		[P_BM_DMA_R*64+:64]		),
		.dma_s_axis_tdest						( dma_rio_rx_tdest		[P_BM_DMA_R* 4+: 4]		),
		
		.log_clk								( log_clk										),
		.rx_tvalid								( srio_iorx_tvalid		[0+:P_Srio_CH_NUM_R* 1]	),
		.rx_tready								( srio_iorx_tready		[0+:P_Srio_CH_NUM_R* 1]	),
		.rx_tlast								( srio_iorx_tlast		[0+:P_Srio_CH_NUM_R* 1]	),
		.rx_tdata								( srio_iorx_tdata		[0+:P_Srio_CH_NUM_R*64]	),
		.rx_tkeep								( srio_iorx_tkeep		[0+:P_Srio_CH_NUM_R* 8]	),
		.rx_tuser								( srio_iorx_tuser		[0+:P_Srio_CH_NUM_R*32]	)
	);
	
	axis_rx_gather_top#(
		.	DW		(	SRIO_DW		)	,
		.	QW		(	SRIO_DW		)	
	)bm_gather(
		.	dma_size_set		(	dma_size_set															)			,	//	input		[	31				:	0	]		
		.	dma_wait_set		(	dma_wait_set															)			,	//	input		[	31				:	0	]		
		.	axsr_tdata			(	dma_rio_rx_tdata	[	P_BM_DMA_R	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	input		[	63				:	0	]		
		.	axsr_tid			(	dma_rio_rx_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	axsr_tready			(	dma_rio_rx_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axsr_tvalid			(	dma_rio_rx_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tstrb			(	dma_rio_rx_tstrb	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	dma_rio_rx_tkeep	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	dma_rio_rx_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tuser			(	dma_rio_rx_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	dma_rio_rx_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	i_rst				(	sys_rst																	)			,	//	input											
	//	.	i_clk				(	sp_log_clk			[	0			*	1			+:	1			]	)			,	//	input											
		.	i_clk				(	pcie_clk																)			,	//	input											
		.	axst_tdata			(	dma_rio_gt_tdata	[	P_BM_DMA_R	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	dma_rio_gt_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	dma_rio_gt_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axst_tvalid			(	dma_rio_gt_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tstrb			(	dma_rio_gt_tstrb	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	dma_rio_gt_tkeep	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	dma_rio_gt_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tuser			(	dma_rio_gt_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	output		[	64		-	1	:	0	]		
		.	axst_tdest			(	dma_rio_gt_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
	//	.	axst_count			(	c_sp_up_cnt_afgt	[	P_BM_DMA_R	*	32			+:	32			]	)			,	//	output		[	32		-	1	:	0	]		
		.	o_rst				(	sys_rst																	)			,	//	input											
	//	.	o_clk				(	sp_log_clk			[	0			*	1			+:	1			]	)			 	//	input											
		.	o_clk				(	pcie_clk																)			 	//	input											
	);
	
	axis_convert_top#(
		.	DW		(	SRIO_DW	)	,
		.	QW		(	PCIE_DW	)	
	)bm_rx_convert(
		.	axsr_tdata			(	dma_rio_gt_tdata	[	P_BM_DMA_R	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	input		[	63				:	0	]		
		.	axsr_tid			(	dma_rio_gt_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	axsr_tready			(	dma_rio_gt_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axsr_tvalid			(	dma_rio_gt_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tstrb			(	dma_rio_gt_tstrb	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	dma_rio_gt_tkeep	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	dma_rio_gt_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tuser			(	dma_rio_gt_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	dma_rio_gt_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	i_rst				(	sys_rst																	)			,	//	input											
	//	.	i_clk				(	sp_log_clk			[	0			*	1			+:	1			]	)			,	//	input											
		.	i_clk				(	pcie_clk																)			,	//	input											
		.	axst_tdata			(	dma_s_axis_tdata	[	P_BM_DMA_R	*	PCIE_DW		+:	PCIE_DW		]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	dma_s_axis_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	dma_s_axis_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axst_tvalid			(	dma_s_axis_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tstrb			(	dma_s_axis_tstrb	[	P_BM_DMA_R	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	dma_s_axis_tkeep	[	P_BM_DMA_R	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	dma_s_axis_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tuser			(	dma_s_axis_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tdest			(	dma_s_axis_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	o_rst				(	pcie_rst																)			,	//	input											
		.	o_clk				(	pcie_clk																)			 	//	input											
	);
	
`endif
`ifdef	ENABLE_BM_SIM
//==================================================================================================
//--bm_dma Instantation
	bm_top	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_bm_top (
	//	.clk									( log_clk[0]								),
		.clk									( pcie_clk									),
		.rst									( sys_rst									),
		.srio_rst								( 1'b0										),
		.c_bm_timestamp							( c_bm_timestamp							),
		.c_bm_timestamp_rf						( c_bm_timestamp_rf							),
		
		.c_bm_en								( c_bm_ch_en			[ 1:0]				),
		.c_bm_up_cnt							( c_bm_up_cnt			[31:0]				),
		.c_bm_ch_recv_cnt						( c_bm_ch_recv_cnt		[63:0]				),
		.c_bm_ch_up_cnt							( c_bm_ch_up_cnt		[63:0]				),
		.c_bm_ch_lost_cnt						( c_bm_ch_lost_cnt		[63:0]				),
		
		.dma_size_set							( dma_size_set			[31:0]				),
		.dma_wait_set							( dma_wait_set			[31:0]				),

		.dma_s_axis_tdata						( dma_rio_rx_tdata		[P_BM_DMA_R*64+:64]	),
		.dma_s_axis_tid							( dma_rio_rx_tid		[P_BM_DMA_R* 4+: 4]	),
		.dma_s_axis_tready						( dma_rio_rx_tready		[P_BM_DMA_R* 1+: 1]	),
		.dma_s_axis_tvalid						( dma_rio_rx_tvalid		[P_BM_DMA_R* 1+: 1]	),
		.dma_s_axis_tstrb						( dma_rio_rx_tstrb		[P_BM_DMA_R* 8+: 8]	),
		.dma_s_axis_tkeep						( dma_rio_rx_tkeep		[P_BM_DMA_R* 8+: 8]	),
		.dma_s_axis_tlast						( dma_rio_rx_tlast		[P_BM_DMA_R* 1+: 1]	),
		.dma_s_axis_tuser						( dma_rio_rx_tuser		[P_BM_DMA_R*64+:64]	),
		.dma_s_axis_tdest						( dma_rio_rx_tdest		[P_BM_DMA_R* 4+: 4]	),
		
		.log_clk								( log_clk									),
		.rx_tvalid								( srio_iorx_tvalid			[0* 1+:2* 1]	),
		.rx_tready								( srio_iorx_tready			[0* 1+:2* 1]	),
		.rx_tlast								( srio_iorx_tlast			[0* 1+:2* 1]	),
		.rx_tdata								( srio_iorx_tdata			[0*64+:2*64]	),
		.rx_tkeep								( srio_iorx_tkeep			[0* 8+:2* 8]	),
		.rx_tuser								( srio_iorx_tuser			[0*32+:2*32]	)
	);
	
	axis_rx_gather_top#(
		.	DW		(	SRIO_DW		)	,
		.	QW		(	SRIO_DW		)	
	)bm_gather(
		.	dma_size_set		(	dma_size_set															)			,	//	input		[	31				:	0	]		
		.	dma_wait_set		(	dma_wait_set															)			,	//	input		[	31				:	0	]		
		.	axsr_tdata			(	dma_rio_rx_tdata	[	P_BM_DMA_R	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	input		[	63				:	0	]		
		.	axsr_tid			(	dma_rio_rx_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	axsr_tready			(	dma_rio_rx_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axsr_tvalid			(	dma_rio_rx_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tstrb			(	dma_rio_rx_tstrb	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	dma_rio_rx_tkeep	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	dma_rio_rx_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tuser			(	dma_rio_rx_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	dma_rio_rx_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	i_rst				(	sys_rst																	)			,	//	input											
	//	.	i_clk				(	sp_log_clk			[	0			*	1			+:	1			]	)			,	//	input											
		.	i_clk				(	pcie_clk																)			,	//	input											
		.	axst_tdata			(	dma_rio_gt_tdata	[	P_BM_DMA_R	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	dma_rio_gt_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	dma_rio_gt_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axst_tvalid			(	dma_rio_gt_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tstrb			(	dma_rio_gt_tstrb	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	dma_rio_gt_tkeep	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	dma_rio_gt_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tuser			(	dma_rio_gt_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	output		[	64		-	1	:	0	]		
		.	axst_tdest			(	dma_rio_gt_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
	//	.	axst_count			(	c_sp_up_cnt_afgt	[	P_BM_DMA_R	*	32			+:	32			]	)			,	//	output		[	32		-	1	:	0	]		
		.	o_rst				(	sys_rst																	)			,	//	input											
	//	.	o_clk				(	sp_log_clk			[	0			*	1			+:	1			]	)			 	//	input											
		.	o_clk				(	pcie_clk																)			 	//	input											
	);
	
	axis_convert_top#(
		.	DW		(	SRIO_DW	)	,
		.	QW		(	PCIE_DW	)	
	)bm_rx_convert(
		.	axsr_tdata			(	dma_rio_gt_tdata	[	P_BM_DMA_R	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	input		[	63				:	0	]		
		.	axsr_tid			(	dma_rio_gt_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	axsr_tready			(	dma_rio_gt_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axsr_tvalid			(	dma_rio_gt_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tstrb			(	dma_rio_gt_tstrb	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tkeep			(	dma_rio_gt_tkeep	[	P_BM_DMA_R	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	input		[	7				:	0	]		
		.	axsr_tlast			(	dma_rio_gt_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axsr_tuser			(	dma_rio_gt_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	input		[	63				:	0	]		
		.	axsr_tdest			(	dma_rio_gt_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	input		[	3				:	0	]		
		.	i_rst				(	sys_rst																	)			,	//	input											
	//	.	i_clk				(	sp_log_clk			[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	i_clk				(	pcie_clk																)			,	//	input											
		.	axst_tdata			(	dma_s_axis_tdata	[	P_BM_DMA_R	*	PCIE_DW		+:	PCIE_DW		]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	dma_s_axis_tid		[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	dma_s_axis_tready	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	input											
		.	axst_tvalid			(	dma_s_axis_tvalid	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tstrb			(	dma_s_axis_tstrb	[	P_BM_DMA_R	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	dma_s_axis_tkeep	[	P_BM_DMA_R	*	PCIE_DW/8	+:	PCIE_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	dma_s_axis_tlast	[	P_BM_DMA_R	*	1			+:	1			]	)			,	//	output											
		.	axst_tuser			(	dma_s_axis_tuser	[	P_BM_DMA_R	*	64			+:	64			]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tdest			(	dma_s_axis_tdest	[	P_BM_DMA_R	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	o_rst				(	pcie_rst																)			,	//	input											
		.	o_clk				(	pcie_clk																)			 	//	input											
	);
	
`endif


//==================================================================================================
	
	
//==================================================================================================
//--SIM Channel inst
	wire			[P_Srio_CH_NUM_R-1:0]		sp_log_clk									;

	assign	sp_log_clk							= 	{
														{{P_BANK_CH_NUM_R}{log_clk[1]}}		,
														{{P_BANK_CH_NUM_R}{log_clk[0]}}
													}										;

genvar i;
generate for(i=0;i<P_Srio_CH_NUM_R;i=i+1) begin:i_SP_G
	sp_top	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)	,
		.P_BIG_CACHE_R							( "FALSE"									)	
	)
	i_sp_top (
		.clk									( pcie_clk									),
	//	.clk									( sp_log_clk				[i*1+: 1]		),

		.log_clk								( sp_log_clk				[i*1+: 1]		),
		.rst									( sys_rst									),
		.srio_rst								( 1'b0										),

		.port_error								( srio_port_error			[i* 1+: 1]		),
		.port_initialized						( srio_port_initialized		[i* 1+: 1]		),
		.link_initialized						( srio_link_initialized		[i* 1+: 1]		),
		.mode_1x								( srio_mode_1x				[i* 1+: 1]		),
		.force_reinit							( srio_force_reinit			[i* 1+: 1]		),

	//	.dma_s_axis_aclk						( dma_s_axis_aclk			[i* 1+: 1]		),
		.dma_s_axis_tdata						( dma_rio_rx_tdata			[i*64+:64]		),
		.dma_s_axis_tid							( dma_rio_rx_tid			[i* 4+: 4]		),
		.dma_s_axis_tready						( dma_rio_rx_tready			[i* 1+: 1]		),
		.dma_s_axis_tvalid						( dma_rio_rx_tvalid			[i* 1+: 1]		),
		.dma_s_axis_tstrb						( dma_rio_rx_tstrb			[i* 8+: 8]		),
		.dma_s_axis_tkeep						( dma_rio_rx_tkeep			[i* 8+: 8]		),
		.dma_s_axis_tlast						( dma_rio_rx_tlast			[i* 1+: 1]		),
		.dma_s_axis_tuser						( dma_rio_rx_tuser			[i*64+:64]		),
		.dma_s_axis_tdest						( dma_rio_rx_tdest			[i* 4+: 4]		),
`ifdef	DN_USER_DDR3
	//	.dma_m_axis_aclk						( dma_m_axis_aclk			[i* 1+: 1]		),
		.dma_m_axis_tdata						( zt_dma_m_axis_tdata		[i*64+:64]		),
		.dma_m_axis_tid							( zt_dma_m_axis_tid			[i* 4+: 4]		),
		.dma_m_axis_tready						( zt_dma_m_axis_tready		[i* 1+: 1]		),
		.dma_m_axis_tvalid						( zt_dma_m_axis_tvalid		[i* 1+: 1]		),
		.dma_m_axis_tstrb						( zt_dma_m_axis_tstrb		[i* 8+: 8]		),
		.dma_m_axis_tkeep						( zt_dma_m_axis_tkeep		[i* 8+: 8]		),
		.dma_m_axis_tlast						( zt_dma_m_axis_tlast		[i* 1+: 1]		),
		.dma_m_axis_tuser						( zt_dma_m_axis_tuser		[i*64+:64]		),
		.dma_m_axis_tdest						( zt_dma_m_axis_tdest		[i* 4+: 4]		),
`else
	//	.dma_m_axis_aclk						( dma_m_axis_aclk			[i* 1+: 1]		),
		.dma_m_axis_tdata						( dma_rio_tx_tdata			[i*64+:64]		),
		.dma_m_axis_tid							( dma_rio_tx_tid			[i* 4+: 4]		),
		.dma_m_axis_tready						( dma_rio_tx_tready			[i* 1+: 1]		),
		.dma_m_axis_tvalid						( dma_rio_tx_tvalid			[i* 1+: 1]		),
		.dma_m_axis_tstrb						( dma_rio_tx_tstrb			[i* 8+: 8]		),
		.dma_m_axis_tkeep						( dma_rio_tx_tkeep			[i* 8+: 8]		),
		.dma_m_axis_tlast						( dma_rio_tx_tlast			[i* 1+: 1]		),
		.dma_m_axis_tuser						( dma_rio_tx_tuser			[i*64+:64]		),
		.dma_m_axis_tdest						( dma_rio_tx_tdest			[i* 4+: 4]		),
`endif
		.sys_axi_awaddr							( log_axi_awaddr			[i*32+:32]		),
		.sys_axi_awprot							( log_axi_awprot			[i* 3+: 3]		),
		.sys_axi_awvalid						( log_axi_awvalid			[i* 1+: 1]		),
		.sys_axi_awready						( log_axi_awready			[i* 1+: 1]		),
		.sys_axi_wdata							( log_axi_wdata				[i*32+:32]		),
		.sys_axi_wstrb							( log_axi_wstrb				[i* 4+: 4]		),
		.sys_axi_wvalid							( log_axi_wvalid			[i* 1+: 1]		),
		.sys_axi_wready							( log_axi_wready			[i* 1+: 1]		),
		.sys_axi_bresp							( log_axi_bresp				[i* 2+: 2]		),
		.sys_axi_bvalid							( log_axi_bvalid			[i* 1+: 1]		),
		.sys_axi_bready							( log_axi_bready			[i* 1+: 1]		),
		.sys_axi_araddr							( log_axi_araddr			[i*32+:32]		),
		.sys_axi_arprot							( log_axi_arprot			[i* 3+: 3]		),
		.sys_axi_arvalid						( log_axi_arvalid			[i* 1+: 1]		),
		.sys_axi_arready						( log_axi_arready			[i* 1+: 1]		),
		.sys_axi_rdata							( log_axi_rdata				[i*32+:32]		),
		.sys_axi_rresp							( log_axi_rresp				[i* 2+: 2]		),
		.sys_axi_rvalid							( log_axi_rvalid			[i* 1+: 1]		),
		.sys_axi_rready							( log_axi_rready			[i* 1+: 1]		),

		.c_sp_dn_cnt							( c_sp_dn_cnt				[i*32+:32]		),
		.c_sp_up_cnt							( c_sp_up_cnt				[i*32+:32]		),
		
	//	.dma_size_set							( dma_size_set				[0*32+:32]		),
	//	.dma_wait_set							( dma_wait_set				[0*32+:32]		),
		
		.c_bm_recv_cnt							( c_bm_ch_recv_cnt			[i*32+:32]		),
		.c_bm_up_cnt							( c_bm_ch_up_cnt			[i*32+:32]		),
		.c_bm_lost_cnt							( c_bm_ch_lost_cnt			[i*32+:32]		),
		.c_bm_en								( c_bm_ch_en				[i* 1+: 1]		),

		.sr_iotx_tvalid							( srio_iotx_tvalid			[i* 1+: 1]		),
		.sr_iotx_tready							( srio_iotx_tready			[i* 1+: 1]		),
		.sr_iotx_tlast							( srio_iotx_tlast			[i* 1+: 1]		),
		.sr_iotx_tdata							( srio_iotx_tdata			[i*64+:64]		),
		.sr_iotx_tkeep							( srio_iotx_tkeep			[i* 8+: 8]		),
		.sr_iotx_tuser							( srio_iotx_tuser			[i*32+:32]		),

		.sr_iorx_tvalid							( srio_iorx_tvalid			[i* 1+: 1]		),
		.sr_iorx_tready							( srio_iorx_tready			[i* 1+: 1]		),
		.sr_iorx_tlast							( srio_iorx_tlast			[i* 1+: 1]		),
		.sr_iorx_tdata							( srio_iorx_tdata			[i*64+:64]		),
		.sr_iorx_tkeep							( srio_iorx_tkeep			[i* 8+: 8]		),
		.sr_iorx_tuser							( srio_iorx_tuser			[i*32+:32]		),
												
		.maintr_rst								( srio_maintr_rst			[i* 1+: 1]		),
		.maintr_awvalid							( srio_maintr_awvalid	    [i* 1+: 1]		),
		.maintr_awready  						( srio_maintr_awready	    [i* 1+: 1]		),
		.maintr_awaddr   						( srio_maintr_awaddr	    [i*32+:32]		),
		.maintr_wvalid   						( srio_maintr_wvalid	    [i* 1+: 1]		),
		.maintr_wready   						( srio_maintr_wready	    [i* 1+: 1]		),
		.maintr_wdata    						( srio_maintr_wdata			[i*32+:32]		),
		.maintr_bvalid   						( srio_maintr_bvalid	    [i* 1+: 1]		),
		.maintr_bready   						( srio_maintr_bready	    [i* 1+: 1]		),
		.maintr_bresp    						( srio_maintr_bresp			[i* 2+: 2]		),
		.maintr_arvalid  						( srio_maintr_arvalid	    [i* 1+: 1]		),
		.maintr_arready  						( srio_maintr_arready	    [i* 1+: 1]		),
		.maintr_araddr   						( srio_maintr_araddr	    [i*32+:32]		),
		.maintr_rvalid   						( srio_maintr_rvalid	    [i* 1+: 1]		),
		.maintr_rready   						( srio_maintr_rready	    [i* 1+: 1]		),
		.maintr_rdata    						( srio_maintr_rdata			[i*32+:32]		),
		.maintr_rresp    						( srio_maintr_rresp			[i* 2+: 2]		)
	);
	
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
	//	.	i_clk				(	sp_log_clk			[	i	*	1			+:	1			]	)			,	//	input											
		.	i_clk				(	pcie_clk														)			,	//	input											
		.	axst_tdata			(	dma_rio_gt_tdata	[	i	*	SRIO_DW		+:	SRIO_DW		]	)			,	//	output		[	QW		-	1	:	0	]		
		.	axst_tid			(	dma_rio_gt_tid		[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
		.	axst_tready			(	dma_rio_gt_tready	[	i	*	1			+:	1			]	)			,	//	input											
		.	axst_tvalid			(	dma_rio_gt_tvalid	[	i	*	1			+:	1			]	)			,	//	output											
		.	axst_tstrb			(	dma_rio_gt_tstrb	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tkeep			(	dma_rio_gt_tkeep	[	i	*	SRIO_DW/8	+:	SRIO_DW/8	]	)			,	//	output		[	QW/8	-	1	:	0	]		
		.	axst_tlast			(	dma_rio_gt_tlast	[	i	*	1			+:	1			]	)			,	//	output											
		.	axst_tuser			(	dma_rio_gt_tuser	[	i	*	64			+:	64			]	)			,	//	output		[	64		-	1	:	0	]		
		.	axst_tdest			(	dma_rio_gt_tdest	[	i	*	4			+:	4			]	)			,	//	output		[	4		-	1	:	0	]		
	//	.	axst_count			(	c_sp_up_cnt_afgt	[	i	*	32			+:	32			]	)			,	//	output		[	32		-	1	:	0	]		
		.	o_rst				(	sys_rst															)			,	//	input											
	//	.	o_clk				(	sp_log_clk			[	i	*	1			+:	1			]	)			 	//	input											
		.	o_clk				(	pcie_clk														)			 	//	input											
	);
	
	axis_convert_top#(
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
	//	.	i_clk				(	sp_log_clk			[	i	*	1			+:	1			]	)			,	//	input											
		.	i_clk				(	pcie_clk														)			,	//	input											
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
	//	.	o_clk				(	sp_log_clk			[	i	*	1			+:	1			]	)			 	//	input											
		.	o_clk				(	pcie_clk														)			 	//	input											
	);
	
end
endgenerate

	pcie3_ep_wrap	#	(
		.	C_DATA_WIDTH					(	PCIE_DW		)			,	//	RX/TX	interface	data	width
		.	EXT_PIPE_SIM					(	"FALSE"		)			,	//	This	Parameter	has	effect	on	selecting	Enable	External	PIPE	Interface	in	GUI.
		.	PL_LINK_CAP_MAX_LINK_SPEED		(	PCIE_LS		)			,	//	1->GEN1	,	2->GEN2	,	4->GEN3
		.	PL_LINK_CAP_MAX_LINK_WIDTH		(	PCIE_LW		)				//	1->X1	,	2->X2	,	4->X4	,	8->X8
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
		.	c_os_config							(		c_os_config							)	,	//	input										
		.	c_os_big_endian						(		c_os_big_endian						)	,	//	input										
		.	user_lnk_up							(		user_lnk_up							)	,	//	output	wire											
		.	phy_rdy_out							(		phy_rdy_out							)	,	//	output	wire																				
		.	user_clk							(		pcie_clk							)	,	//	output	wire											
		.	user_reset							(		pcie_rst							)	,	//	output	wire											
		.	sys_clk_p							(		pcie_ref_clk_p						)	,	//	input													
		.	sys_clk_n							(		pcie_ref_clk_n						)	,	//	input													
		.	sys_rst_n							(		sys_rst_n_in_c						)		//	input													
	);
	reg		[	1	*	32	-1:0]	log_clk_cnt	=	0			;	always@(posedge	log_clk[0])	log_clk_cnt	<=	log_clk_cnt	+	1	;
	wire	[	1	*	4	-1:0]	srio_clk_cnt				;	assign	srio_clk_cnt	=	log_clk_cnt[31:28]	;
	reg		[	1	*	12	-1:0]	srio_iotx_trvl_cnt	=	0	;
	reg		[	1	*	12	-1:0]	srio_iorx_trvl_cnt	=	0	;
	always@(posedge	log_clk[0])	srio_iotx_trvl_cnt	<=	sys_rst	?	0	:	srio_iotx_tvalid[0]&&srio_iotx_tready[0]&&srio_iotx_tlast[0]	?	srio_iotx_trvl_cnt+1	:	srio_iotx_trvl_cnt	;
	always@(posedge	log_clk[0])	srio_iorx_trvl_cnt	<=	sys_rst	?	0	:	srio_iorx_tvalid[0]&&srio_iorx_tready[0]&&srio_iorx_tlast[0]	?	srio_iorx_trvl_cnt+1	:	srio_iorx_trvl_cnt	;
	
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
		
		.	srio_clk_cnt					(		srio_clk_cnt				)	,	//		input	[	16		-	1	:	0]
		.	srio_iotx_trvl_cnt				(		srio_iotx_trvl_cnt			)	,	//		input	[	16		-	1	:	0]
		.	srio_iorx_trvl_cnt				(		srio_iorx_trvl_cnt			)	,	//		input	[	16		-	1	:	0]
		.	srio_port_error					(		srio_port_error				)	,	//		input								
		.	srio_port_initialized			(		srio_port_initialized		)	,	//		input								
		.	srio_link_initialized			(		srio_link_initialized		)	,	//		input								
		.	srio_mode_1x					(		srio_mode_1x				)	,	//		input								
		.	srio_force_reinit				(		srio_force_reinit			)	,	//		input								
		.	sys_rst							(		sys_rst						)	,	//		input								


		
		.	pcie_clk						(		pcie_clk					)	,	//		input										
		.	pcie_rst						(		pcie_rst					)		//		input										

	);

//==================================================================================================
//--Flash
	wire			[ 3:0]						data_in 									;
	wire			[ 3:0]						data_out									;
	wire										data_en 									;
	wire										fclk	 									;

//	assign									flash_clk	=	pcie_clk						;
	IBUF   EMCCLK_IBUF_inst 				(.O(flash_clk), .I(EMCCLK))						;
	
	n25qx_qspi_top #(
		.	EEPROM_ZONE 	( 16'h0002			)	,
		.	FREQ_MHZ 		( EMCCLK_FREQ_MHZ	)
	//	.	FREQ_MHZ 		( PCIE_FREQ_MHZ		)
	)
	i_n25qx_qspi_top	(
		.clk									( flash_clk									),
		.rst_n									( ~pcie_reset								),

		.power_cfg_en							( 											),

		.s_axi_awaddr							( master_axi_awaddr	    	[1*32 +: 32]	),
		.s_axi_awvalid							( master_axi_awvalid		[1* 1 +:  1]	),
		.s_axi_awprot							( master_axi_awprot	    	[1* 3 +:  3]	),
		.s_axi_awready							( master_axi_awready		[1* 1 +:  1]	),

		.s_axi_wdata							( master_axi_wdata	    	[1*32 +: 32]	),
		.s_axi_wvalid							( master_axi_wvalid	    	[1* 1 +:  1]	),
		.s_axi_wstrb 							( master_axi_wstrb	    	[1* 4 +:  4]	),
		.s_axi_wready 							( master_axi_wready	    	[1* 1 +:  1]	),

		.s_axi_bresp							( master_axi_bresp	    	[1* 2 +:  2]	),
		.s_axi_bvalid							( master_axi_bvalid	    	[1* 1 +:  1]	),
		.s_axi_bready 							( master_axi_bready	    	[1* 1 +:  1]	),

		.s_axi_araddr							( master_axi_araddr	    	[1*32 +: 32]	),
		.s_axi_arprot							( master_axi_arprot	    	[1* 3 +:  3]	),
		.s_axi_arvalid							( master_axi_arvalid		[1* 1 +:  1]	),
		.s_axi_arready							( master_axi_arready		[1* 1 +:  1]	),

		.s_axi_rdata							( master_axi_rdata	    	[1*32 +: 32]	),
		.s_axi_rresp							( master_axi_rresp	    	[1* 2 +:  2]	),
		.s_axi_rvalid							( master_axi_rvalid	    	[1* 1 +:  1]	),
		.s_axi_rready							( master_axi_rready     	[1* 1 +:  1]	),

		.data_in								( data_in									),
		.data_out								( data_out									),
		.data_en 								( data_en									),

		.flash_clk								( fclk          							),
		.flash_csn								( flash_csn									)
	);

//	generate
//	genvar  j;
//		for (j = 0; j <= 3; j = j + 1)
//			begin : bidir_IO
//			IOBUF IOBUF_i (
//				.IO   (flash_data[j]),
//				.I    (data_out[j]),
//				.O    (data_in[j]),
//				.T    (data_en)
//			);
//		end
//	endgenerate

	STARTUPE3	#(	
		.PROG_USR			(	"FALSE"	)	,	//	Activate program event security feature. Requires encrypted bitstreams.
		.SIM_CCLK_FREQ		(	0.0		)		//	Set the Configuration Clock Frequency ( ns  ) for simulation
	)
	STARTUPE3_inst	(	
			.	CFGCLK		(				)	,	//	1-bit output: Configuration main clock output
			.	CFGMCLK		(				)	,	//	1-bit output: Configuration internal oscillator clock output
			.	DI			(	data_in		)	,	//	4-bit output: Allow receiving on the D input pin
			.	EOS			(				)	,	//	1-bit output: Active-High output signal indicating the End Of Startup
			.	PREQ		(				)	,	//	1-bit output: PROGRAM request to fabric output
			.	DO			(	data_out	)	,	//	4-bit input: Allows control of the D pin output
			.	DTS			(	data_en		)	,	//	4-bit input: Allows tristate of the D pin
			.	FCSBO		(	flash_csn	)	,	//	1-bit input: Controls the FCS_B pin for flash access
			.	FCSBTS		(	0			)	,	//	1-bit input: Tristate the FCS_B pin
			.	GSR			(	0			)	,	//	1-bit input: Global Set/Reset input    ( GSR cannot be used for the port  )
			.	GTS			(	0			)	,	//	1-bit input: Global 3-state input    ( GTS cannot be used for the port name  )
			.	KEYCLEARB	(	1			)	,	//	1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM    ( BBRAM  )
			.	PACK		(	1			)	,	//	1-bit input: PROGRAM acknowledge input
			.	USRCCLKO	(	fclk		)	,	//	1-bit input: User CCLK input
			.	USRCCLKTS	(	0			)	,	//	1-bit input: User CCLK 3-state enable input
			.	USRDONEO	(	1			)	,	//	1-bit input: User DONE pin output control
			.	USRDONETS	(	1			)		//	1-bit input: User DONE 3-state enable output
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