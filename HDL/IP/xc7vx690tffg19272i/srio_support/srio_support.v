`timescale 1ns/1ns
//`include "./BOARD_MC01.vh"
//////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZhengYunLong
//
// Create Date:		2020/3/19 10:00:37
// Design Name:
// Module Name:		srio_gen2_1g_16b
// Project Name:	SR21000
// Target Devices:	FPGA-K7-Series
// Tool versions:	Vivado 2016.4
// Description:
//	这个模块用于例化srio IP Core
// Revision:
//
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////////////////////

//	`define	SRIO_SIM_MODE

module	srio_support #(
	/*--------------------------------------------------------------------------------------
	--SRIO Config
	--------------------------------------------------------------------------------------*/
	parameter		P_RIO_AXIS_LOOPBACK			= 0											,	//--ID SEL =0,8BIT IP;=1,16 BIT ID IP Core
	parameter		P_Srio_ID_WTH_R				= 8											,	//--ID SEL =0,8BIT IP;=1,16 BIT ID IP Core
	parameter		P_Srio_CH_NUM_R				= 4											,
	parameter		P_Srio_CH_LANE_R			= 1											,	//1=1x 2=2x 4=4x
	parameter		P_Srio_SPEED_R				= 3 										,	//1=1Gbps 2=2.5Gbps 3=3.125Gbps 5=5Gbps 6=6Gbps
	parameter		P_Srio_PHY_LANE_R			= 4												//Physical lane number
	)(
	/*--------------------------------------------------------------------------------------
	--port declarations ----------------
	--------------------------------------------------------------------------------------*/
    // Clocks and Resets
	input             							sys_clkp 									,// System reference clock
	input             							sys_clkn 									,// MMCM reference clock
	input             							sys_rst  									,// Global reset signal

    // all clocks as out
	output           [P_Srio_CH_NUM_R* 1-1:0]	log_clk_out   								,// LOG interface clock
	output           [P_Srio_CH_NUM_R* 1-1:0]	phy_clk_out   								,// PHY interface clock
	output           [P_Srio_CH_NUM_R* 1-1:0]	gt_clk_out    								,
	output           [P_Srio_CH_NUM_R* 1-1:0]	gt_pcs_clk_out								,// GT fabric interface clock
	output           [P_Srio_CH_NUM_R* 1-1:0]	drpclk_out    								,
	output            							refclk_out    								,

	output          [P_Srio_CH_NUM_R* 1-1:0]	clk_lock_out  								,
    /*--------------------------------------------------------------------------------------
	--all resets as out
	--------------------------------------------------------------------------------------*/
	output           [P_Srio_CH_NUM_R* 1-1:0]	log_rst_out			   						,	// Reset for LOG clock Domain
	output           [P_Srio_CH_NUM_R* 1-1:0]	phy_rst_out		   							,	// Reset for PHY clock Domain
	output           [P_Srio_CH_NUM_R* 1-1:0]	buf_rst_out		   							,
	output           [P_Srio_CH_NUM_R* 1-1:0]	cfg_rst_out		   							,
	output           [P_Srio_CH_NUM_R* 1-1:0]	gt_pcs_rst_out								,

    // QPLL outputs
	output            							gt0_qpll_clk_out       						,
	output            							gt0_qpll_out_refclk_out						,													   

//---------------------------------------------------------------
	input            [P_Srio_CH_NUM_R-1:0]		s_axi_maintr_rst							,// Reset for maintr interface, on LOG clk domain


    // high-speed IO
 	input			[P_Srio_PHY_LANE_R-1:0]		srio_rxn0									,
	input			[P_Srio_PHY_LANE_R-1:0]		srio_rxp0									,
	output			[P_Srio_PHY_LANE_R-1:0]		srio_txn0									,
	output			[P_Srio_PHY_LANE_R-1:0]		srio_txp0									,


	// Maintenance Port
	input     		[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_awvalid						,// Write Command Valid
	output    		[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_awready						,// Write Port Ready
	input     		[P_Srio_CH_NUM_R*32-1:0]    s_axi_maintr_awaddr							,// Write Address
	input     		[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_wvalid							,// Write Data Valid
	output    		[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_wready							,// Write Port Ready
	input     		[P_Srio_CH_NUM_R*32-1:0] 	s_axi_maintr_wdata							,// Write Data
	output    		[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_bvalid							,// Write Response Valid
	input     		[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_bready							,// Write Response Fabric Ready
	output    		[P_Srio_CH_NUM_R* 2-1:0]	s_axi_maintr_bresp							, // Write Response

	input           [P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_arvalid						,// Read Command Valid
	output          [P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_arready						,// Read Port Ready
	input  			[P_Srio_CH_NUM_R*32-1:0] 	s_axi_maintr_araddr							,// Read Address
	output 			[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_rvalid							,// Read Response Valid
	input  			[P_Srio_CH_NUM_R* 1-1:0]	s_axi_maintr_rready							,// Read Response Fabric Ready
	output 			[P_Srio_CH_NUM_R*32-1:0] 	s_axi_maintr_rdata							,// Read Data
	output 			[P_Srio_CH_NUM_R* 2-1:0]	s_axi_maintr_rresp							,// Read Response


	// I/O Port
	input           [P_Srio_CH_NUM_R* 1-1:0]	s_axis_iotx_tvalid							,// Indicates Valid Input on the Request Channel
	output          [P_Srio_CH_NUM_R* 1-1:0]	s_axis_iotx_tready							,// Beat has been accepted
	input           [P_Srio_CH_NUM_R* 1-1:0]	s_axis_iotx_tlast							,// Indicates last beat
	input  		    [P_Srio_CH_NUM_R*64-1:0]	s_axis_iotx_tdata							,// Req Data Bus
	input  		    [P_Srio_CH_NUM_R* 8-1:0]	s_axis_iotx_tkeep							,// Req Keep Bus
	input  		    [P_Srio_CH_NUM_R*32-1:0]	s_axis_iotx_tuser							,// Req User Bus

	output  		[P_Srio_CH_NUM_R* 1-1:0]	m_axis_iorx_tvalid							,// Indicates Valid Output on the Response Channel
	input   		[P_Srio_CH_NUM_R* 1-1:0]	m_axis_iorx_tready							,// Beat has been accepted
	output  		[P_Srio_CH_NUM_R* 1-1:0]	m_axis_iorx_tlast							,// Indicates last beat
	output  		[P_Srio_CH_NUM_R*64-1:0]	m_axis_iorx_tdata							,// Resp Data Bus
	output  		[P_Srio_CH_NUM_R* 8-1:0]	m_axis_iorx_tkeep							,// Resp Keep Bus
	output  		[P_Srio_CH_NUM_R*32-1:0]	m_axis_iorx_tuser							,// Resp User Bus


    // PHY control signals
	input          								sim_train_en								,// Reduce timers for inialization for simulation
	input           [P_Srio_CH_NUM_R* 1-1:0]	force_reinit								,// Force reinitialization
	input           [P_Srio_CH_NUM_R* 1-1:0]	phy_mce										,// Send MCE control symbol
	input           [P_Srio_CH_NUM_R* 1-1:0]	phy_link_reset								,// Send link reset control symbols

 	output          [P_Srio_CH_NUM_R* 1-1:0]	phy_rcvd_mce								,// MCE control symbol received
	output          [P_Srio_CH_NUM_R* 1-1:0]	phy_rcvd_link_reset							,// Received 4 consecutive reset symbols
	output    		[P_Srio_CH_NUM_R*224-1:0]	phy_debug									,// Useful debug signals
	output          [P_Srio_CH_NUM_R* 1-1:0]	gtrx_disperr_or								,// GT disparity error (reduce ORed)
	output          [P_Srio_CH_NUM_R* 1-1:0]	gtrx_notintable_or							,// GT not in table error (reduce ORed)


   // ------------------------------------------------
   // side band signals
	output          [P_Srio_CH_NUM_R* 1-1:0]  	port_error                   				,// In Port Error State
	output 		   	[P_Srio_CH_NUM_R*24-1:0] 	port_timeout                 				,// Timeout occurred
	output          [P_Srio_CH_NUM_R* 1-1:0]  	srio_host                    				,// Endpoint is the system host
	output          [P_Srio_CH_NUM_R* 1-1:0]  	port_decode_error            				,// No valid output port for the RX transaction
	output   		[P_Srio_CH_NUM_R*16-1:0]  	deviceid                     				,// Device ID
	output          [P_Srio_CH_NUM_R* 1-1:0]  	idle2_selected               				,// The PHY is operating in IDLE2 mode

	output          [P_Srio_CH_NUM_R* 1-1:0]	phy_lcl_master_enable_out    				,
	output          [P_Srio_CH_NUM_R* 1-1:0]	buf_lcl_response_only_out    				,
	output          [P_Srio_CH_NUM_R* 1-1:0]	buf_lcl_tx_flow_control_out  				,
	output      	[P_Srio_CH_NUM_R* 6-1:0]	buf_lcl_phy_buf_stat_out     				,
	output      	[P_Srio_CH_NUM_R* 6-1:0]	phy_lcl_phy_next_fm_out      				,
	output      	[P_Srio_CH_NUM_R* 6-1:0]	phy_lcl_phy_last_ack_out     				,
	output          [P_Srio_CH_NUM_R* 1-1:0]	phy_lcl_phy_rewind_out       				,
	output      	[P_Srio_CH_NUM_R* 6-1:0]	phy_lcl_phy_rcvd_buf_stat_out				,
	output          [P_Srio_CH_NUM_R* 1-1:0]	phy_lcl_maint_only_out       				,

//	output 			[P_Srio_PHY_LANE_R-1:0]		gt_txpmaresetdone_out						,

    // PHY Informational signals in support logic
	output          [P_Srio_CH_NUM_R* 1-1:0]	port_initialized							,  // Port is intialized
	output          [P_Srio_CH_NUM_R* 1-1:0]	link_initialized							,  // Ready to transmit data
	output          [P_Srio_CH_NUM_R* 1-1:0]	idle_selected   							,  // The IDLE sequence has been selected
	output          [P_Srio_CH_NUM_R* 1-1:0]  	mode_1x         							    // Link is trained down to 1x mode
   );

`ifdef	SRIO_SIM_MODE
	
	wire	log_clk	;
	reg	[5-1:0]	gen_ip_clk_cnt	=	0	;
	reg	ipc_clk_reg	=	0	;	
	
	generate	if(	P_Srio_CH_LANE_R	==	1	)	begin
					always@(posedge	sys_clkp)	gen_ip_clk_cnt	<=	gen_ip_clk_cnt==4/2-1	?	0	:	gen_ip_clk_cnt	+	1	;
					always@(posedge	sys_clkp)	ipc_clk_reg		<=	gen_ip_clk_cnt==4/2-1	?	~	ipc_clk_reg	:	ipc_clk_reg	;
					assign	log_clk	=	ipc_clk_reg	;
				end	else	if(	P_Srio_CH_LANE_R	==	2	)	begin
					always@(posedge	sys_clkp)	gen_ip_clk_cnt	<=	gen_ip_clk_cnt==4/4-1	?	0	:	gen_ip_clk_cnt	+	1	;
					always@(posedge	sys_clkp)	ipc_clk_reg		<=	gen_ip_clk_cnt==4/4-1	?	~	ipc_clk_reg	:	ipc_clk_reg	;
					assign	log_clk	=	ipc_clk_reg	;
				end	else	if(	P_Srio_CH_LANE_R	==	4	)	begin
					assign	log_clk	=	sys_clkp		;
				end
	endgenerate
	
	assign	log_clk_out	=	log_clk	;
	
	reg	sys_rst_q	=	1	;
	always@(posedge	log_clk	)	sys_rst_q	<=	sys_rst	;

		assign	m_axis_iorx_tdata		=	s_axis_iotx_tdata		;
		assign	m_axis_iorx_tvalid		=	s_axis_iotx_tvalid		;
	//	assign	m_axis_iorx_tready		=	s_axis_iotx_tready		;
		assign	m_axis_iorx_tlast		=	s_axis_iotx_tlast		;
		assign	m_axis_iorx_tkeep		=	s_axis_iotx_tkeep		;
		assign	m_axis_iorx_tuser		=	s_axis_iotx_tuser		;
		
		assign	s_axis_iotx_tready		=	m_axis_iorx_tready		;
	
	//assign	port_initialized		=	{	P_Srio_CH_NUM_R	{~	sys_rst_q	}	}		;
	//assign	link_initialized		=	{	P_Srio_CH_NUM_R	{~	sys_rst_q	}	}		;
	//assign	mode_1x					=	{	P_Srio_CH_NUM_R	{	1'b0		}	}		;
	
	assign	srio_txn0	=	srio_rxn0	;
	assign	srio_txp0	=	srio_rxp0	;
	
	assign	port_error              =	{(P_Srio_CH_NUM_R* 1){1'b0}}	;
	assign	port_timeout            =	{(P_Srio_CH_NUM_R*24){1'b0}}	;
	assign	srio_host               =	{(P_Srio_CH_NUM_R* 1){1'b0}}	;
	assign	port_decode_error       =	{(P_Srio_CH_NUM_R* 1){1'b0}}	;
	assign	deviceid                =	{(P_Srio_CH_NUM_R* 1){16'h25}}	;
	assign	idle2_selected          =	{(P_Srio_CH_NUM_R* 1){1'b0}}	;
	
`else	

	wire			[P_Srio_CH_NUM_R* 1-1:0]	rio_ip_iotx_tvalid							;// Indicates Valid Input on the Request Channel
	wire			[P_Srio_CH_NUM_R* 1-1:0]	rio_ip_iotx_tready							;// Beat has been accepted
	wire			[P_Srio_CH_NUM_R* 1-1:0]	rio_ip_iotx_tlast							;// Indicates last beat
	wire			[P_Srio_CH_NUM_R*64-1:0]	rio_ip_iotx_tdata							;// Req Data Bus
	wire			[P_Srio_CH_NUM_R* 8-1:0]	rio_ip_iotx_tkeep							;// Req Keep Bus
	wire			[P_Srio_CH_NUM_R*32-1:0]	rio_ip_iotx_tuser							;// Req User Bus

    wire			[P_Srio_CH_NUM_R* 1-1:0]	rio_ip_iorx_tvalid							;// Indicates Valid Output on the Response Channel
    wire			[P_Srio_CH_NUM_R* 1-1:0]	rio_ip_iorx_tready							;// Beat has been accepted
    wire			[P_Srio_CH_NUM_R* 1-1:0]	rio_ip_iorx_tlast							;// Indicates last beat
    wire			[P_Srio_CH_NUM_R*64-1:0]	rio_ip_iorx_tdata							;// Resp Data Bus
    wire			[P_Srio_CH_NUM_R* 8-1:0]	rio_ip_iorx_tkeep							;// Resp Keep Bus
    wire			[P_Srio_CH_NUM_R*32-1:0]	rio_ip_iorx_tuser							;// Resp User Bus

generate 
	if(P_RIO_AXIS_LOOPBACK==1)		begin :	axis_loopback

		assign			m_axis_iorx_tvalid			=		s_axis_iotx_tvalid					;
	//	assign			m_axis_iorx_tready			=		s_axis_iotx_tready					;
		assign			m_axis_iorx_tlast			=		s_axis_iotx_tlast					;
		assign			m_axis_iorx_tdata			=		s_axis_iotx_tdata					;
		assign			m_axis_iorx_tkeep			=		s_axis_iotx_tkeep					;
		assign			m_axis_iorx_tuser			=		s_axis_iotx_tuser					;
		
		assign			s_axis_iotx_tready			=		m_axis_iorx_tready					;
		
		assign			rio_ip_iotx_tvalid			=		0									;
	//	assign			rio_ip_iotx_tready			=		0									;
		assign			rio_ip_iotx_tlast			=		0									;
		assign			rio_ip_iotx_tdata			=		0									;
		assign			rio_ip_iotx_tkeep			=		0									;
		assign			rio_ip_iotx_tuser			=		0									;
		
		assign			rio_ip_iorx_tready			=		{P_Srio_CH_NUM_R{1'b1}}				;
	
	end else begin :	normal

		assign			rio_ip_iotx_tvalid			=		s_axis_iotx_tvalid					;
	//	assign			rio_ip_iotx_tready			=		s_axis_iotx_tready					;
		assign			rio_ip_iotx_tlast			=		s_axis_iotx_tlast					;
		assign			rio_ip_iotx_tdata			=		s_axis_iotx_tdata					;
		assign			rio_ip_iotx_tkeep			=		s_axis_iotx_tkeep					;
		assign			rio_ip_iotx_tuser			=		s_axis_iotx_tuser					;
		
		assign			s_axis_iotx_tready			=		rio_ip_iotx_tready					;

		assign			m_axis_iorx_tvalid			=		rio_ip_iorx_tvalid					;
	//	assign			m_axis_iorx_tready			=		rio_ip_iorx_tready					;
		assign			m_axis_iorx_tlast			=		rio_ip_iorx_tlast					;
		assign			m_axis_iorx_tdata			=		rio_ip_iorx_tdata					;
		assign			m_axis_iorx_tkeep			=		rio_ip_iorx_tkeep					;
		assign			m_axis_iorx_tuser			=		rio_ip_iorx_tuser					;
		
		assign			rio_ip_iorx_tready			=		m_axis_iorx_tready					;
	
	`ifdef	SRIO_TYPE_1G1X8B		srio_gen2_1g_1x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif	
	`ifdef	SRIO_TYPE_1G1X16B		srio_gen2_1g_1x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_1G2X8B		srio_gen2_1g_2x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_1G2X16B		srio_gen2_1g_2x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_1G4X8B		srio_gen2_1g_4x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_1G4X16B		srio_gen2_1g_4x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_2G1X8B		srio_gen2_2g_1x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_2G1X16B		srio_gen2_2g_1x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_2G2X8B		srio_gen2_2g_2x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_2G2X16B		srio_gen2_2g_2x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_2G4X8B		srio_gen2_2g_4x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_2G4X16B		srio_gen2_2g_4x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_3G1X8B		srio_gen2_3g_1x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_3G1X16B		srio_gen2_3g_1x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_3G2X8B		srio_gen2_3g_2x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_3G2X16B		srio_gen2_3g_2x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_3G4X8B		srio_gen2_3g_4x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_3G4X16B		srio_gen2_3g_4x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_5G1X8B		srio_gen2_5g_1x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_5G1X16B		srio_gen2_5g_1x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_5G2X8B		srio_gen2_5g_2x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_5G2X16B		srio_gen2_5g_2x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_5G4X8B		srio_gen2_5g_4x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_5G4X16B		srio_gen2_5g_4x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_6G1X8B		srio_gen2_6g_1x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_6G1X16B		srio_gen2_6g_1x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_6G2X8B		srio_gen2_6g_2x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_6G2X16B		srio_gen2_6g_2x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_6G4X8B		srio_gen2_6g_4x_8b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    
	`ifdef	SRIO_TYPE_6G4X16B		srio_gen2_6g_4x_16b_support		#(.P_Srio_CH_NUM_R( P_Srio_CH_NUM_R),.P_Srio_PHY_LANE_R( P_Srio_PHY_LANE_R))	`endif    

//	#(	.P_Srio_CH_NUM_R						( P_Srio_CH_NUM_R							)	,
//		.P_Srio_PHY_LANE_R						( P_Srio_PHY_LANE_R					        )    
//	)	
	u_srio_support (
  //---------------------------------------------------------------
		.sys_clkp                				( sys_clkp									),
		.sys_clkn                				( sys_clkn									),
		.sys_rst                 				( sys_rst									),
      // all clocks as output in shared logic mode
		.log_clk_out             				( log_clk_out   							),
		.phy_clk_out             				( phy_clk_out   							),
		.gt_clk_out              				( gt_clk_out    							),
		.gt_pcs_clk_out          				( gt_pcs_clk_out							),
		.drpclk_out              				( drpclk_out    							),
		.refclk_out              				( refclk_out    							),
		.clk_lock_out            				( clk_lock_out  							),
      // all resets as output in shared logic mode
		.log_rst_out           					( log_rst_out   							),
		.phy_rst_out           					( phy_rst_out   							),
		.buf_rst_out           					( buf_rst_out   							),
		.cfg_rst_out           					( cfg_rst_out   							),
		.gt_pcs_rst_out        					( gt_pcs_rst_out							),

//---------------------------------------------------------------
		.gt0_qpll_clk_out        				( gt0_qpll_clk_out        					),
		.gt0_qpll_out_refclk_out 				( gt0_qpll_out_refclk_out 					),

// //---------------------------------------------------------------
		.srio_rxn0               				( srio_rxn0 								),
		.srio_rxp0               				( srio_rxp0 								),
		.srio_txn0               				( srio_txn0 								),
		.srio_txp0               				( srio_txp0 								),

		.s_axis_iotx_tvalid            			( s_axis_iotx_tvalid						),
		.s_axis_iotx_tready            			( s_axis_iotx_tready						),
		.s_axis_iotx_tlast             			( s_axis_iotx_tlast 						),
		.s_axis_iotx_tdata             			( s_axis_iotx_tdata 						),
		.s_axis_iotx_tkeep             			( s_axis_iotx_tkeep 						),
		.s_axis_iotx_tuser             			( s_axis_iotx_tuser 						),

		.m_axis_iorx_tvalid            			( m_axis_iorx_tvalid            			),
		.m_axis_iorx_tready            			( m_axis_iorx_tready            			),
		.m_axis_iorx_tlast             			( m_axis_iorx_tlast             			),
		.m_axis_iorx_tdata             			( m_axis_iorx_tdata             			),
		.m_axis_iorx_tkeep             			( m_axis_iorx_tkeep             			),
		.m_axis_iorx_tuser             			( m_axis_iorx_tuser             			),

		.s_axi_maintr_rst     	         		( s_axi_maintr_rst     	            		),

		.s_axi_maintr_awvalid          			( s_axi_maintr_awvalid          			),
		.s_axi_maintr_awready          			( s_axi_maintr_awready          			),
		.s_axi_maintr_awaddr           			( s_axi_maintr_awaddr           			),
		.s_axi_maintr_wvalid           			( s_axi_maintr_wvalid           			),
		.s_axi_maintr_wready           			( s_axi_maintr_wready           			),
		.s_axi_maintr_wdata            			( s_axi_maintr_wdata            			),
		.s_axi_maintr_bvalid           			( s_axi_maintr_bvalid           			),
		.s_axi_maintr_bready           			( s_axi_maintr_bready           			),
		.s_axi_maintr_bresp            			( s_axi_maintr_bresp            			),

		.s_axi_maintr_arvalid          			( s_axi_maintr_arvalid          			),
		.s_axi_maintr_arready          			( s_axi_maintr_arready          			),
		.s_axi_maintr_araddr           			( s_axi_maintr_araddr           			),
		.s_axi_maintr_rvalid           			( s_axi_maintr_rvalid           			),
		.s_axi_maintr_rready           			( s_axi_maintr_rready           			),
		.s_axi_maintr_rdata            			( s_axi_maintr_rdata            			),
		.s_axi_maintr_rresp            			( s_axi_maintr_rresp            			),

		.sim_train_en                  			( sim_train_en                  			),
		.phy_mce           	            		( phy_mce           	            		),
		.phy_link_reset    	            		( phy_link_reset    	            		),
		.force_reinit      	            		( force_reinit      	            		),

		.phy_rcvd_mce                  			( phy_rcvd_mce                  			),
		.phy_rcvd_link_reset           			( phy_rcvd_link_reset           			),
		.phy_debug                     			( phy_debug                     			),
		.gtrx_disperr_or               			( gtrx_disperr_or               			),
		.gtrx_notintable_or            			( gtrx_notintable_or            			),

		.port_error                    			( port_error                    			),
		.port_timeout                  			( port_timeout                  			),
		.srio_host                     			( srio_host                     			),
		.port_decode_error             			( port_decode_error             			),
		.deviceid                      			( deviceid                      			),
		.idle2_selected                			( idle2_selected                			),

		.phy_lcl_master_enable_out     			( phy_lcl_master_enable_out     			),
		.buf_lcl_response_only_out     			( buf_lcl_response_only_out     			),
		.buf_lcl_tx_flow_control_out   			( buf_lcl_tx_flow_control_out   			),
		.buf_lcl_phy_buf_stat_out      			( buf_lcl_phy_buf_stat_out      			),
		.phy_lcl_phy_next_fm_out       			( phy_lcl_phy_next_fm_out       			),
		.phy_lcl_phy_last_ack_out      			( phy_lcl_phy_last_ack_out      			),
		.phy_lcl_phy_rewind_out        			( phy_lcl_phy_rewind_out        			),
		.phy_lcl_phy_rcvd_buf_stat_out 			( phy_lcl_phy_rcvd_buf_stat_out 			),
		.phy_lcl_maint_only_out        			( phy_lcl_maint_only_out        			),

		.port_initialized              			( port_initialized              			),
		.link_initialized              			( link_initialized              			),
		.idle_selected                 			( idle_selected                 			),
		.mode_1x                       			( mode_1x                       			)
	);
	
	end	
endgenerate
`endif
endmodule