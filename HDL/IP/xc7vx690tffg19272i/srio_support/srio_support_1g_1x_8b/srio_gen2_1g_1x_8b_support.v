//
// (c) Copyright 2010 - 2014 Xilinx, Inc. All rights reserved.
//
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// 	PART OF THIS FILE AT ALL TIMES.
`timescale 1ps/1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
   // port/parameter declarations in support file ----------------

  module srio_gen2_1g_1x_8b_support
  #(
  
 	/*--------------------------------------------------------------------------------------
	--SRIO Config 
	--------------------------------------------------------------------------------------*/
	parameter		P_Srio_CH_NUM_R				= 4											,
	parameter		P_Srio_PHY_LANE_R			= 4												//--Physical lane number
   // Parameter declarations -----------
	)(
	/*--------------------------------------------------------------------------------------
	--port declarations ----------------
	--------------------------------------------------------------------------------------*/
    // Clocks and Resets
    input             							sys_clkp 									,// System reference clock
    input             							sys_clkn 									,// MMCM reference clock
    input             							sys_rst  									,// Global reset signal

    // all clocks as out
    output            							log_clk_out   								,// LOG interface clock
    output            							phy_clk_out   								,// PHY interface clock
    output            							gt_clk_out    								,
    output            							gt_pcs_clk_out								,// GT fabric interface clock
    output            							drpclk_out    								,
    output            							refclk_out    								,

    output            							clk_lock_out  								,
    /*--------------------------------------------------------------------------------------
	--all resets as out
	--------------------------------------------------------------------------------------*/
	output            [P_Srio_CH_NUM_R* 1-1:0]	log_rst_out			   						,	// Reset for LOG clock Domain
	output            [P_Srio_CH_NUM_R* 1-1:0]	phy_rst_out		   							,	// Reset for PHY clock Domain
	output            [P_Srio_CH_NUM_R* 1-1:0]	buf_rst_out		   							,
	output            [P_Srio_CH_NUM_R* 1-1:0]	cfg_rst_out		   							,
	output            [P_Srio_CH_NUM_R* 1-1:0]	gt_pcs_rst_out								,
    
    // QPLL outputs
    output            							gt0_qpll_clk_out       						,
    output            							gt0_qpll_out_refclk_out						,
    output            							gt0_qpll_lock_out							,
//---------------------------------------------------------------
    input            [P_Srio_CH_NUM_R-1:0]	s_axi_maintr_rst							,// Reset for maintr interface, on LOG clk domain
    

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
   
    // PHY Informational signals in support logic
    output          [P_Srio_CH_NUM_R* 1-1:0]	port_initialized							,  // Port is intialized
    output          [P_Srio_CH_NUM_R* 1-1:0]	link_initialized							,  // Ready to transmit data
    output          [P_Srio_CH_NUM_R* 1-1:0]	idle_selected   							,  // The IDLE sequence has been selected
    output          [P_Srio_CH_NUM_R* 1-1:0]  	mode_1x         							    // Link is trained down to 1x mode
   );
	/*--------------------------------------------------------------------------------------
	--wire declarations ----------------
	--------------------------------------------------------------------------------------*/
	wire            [P_Srio_CH_NUM_R* 1-1:0]  	controlled_force_reinit						; // Force reinitialization
//==================================================================================================
//--BY ZYL SRIO Channel-A SID==AB 2018/5/10 12:48:21
  // start of SRIO_WRAPPER instantation ----------------
    wire	[P_Srio_CH_NUM_R* 1 -1:00]     mx_axis_iorx_tvalid   ;	
wire	[P_Srio_CH_NUM_R* 1 -1:00]     mx_axis_iorx_tready   ;	
wire	[P_Srio_CH_NUM_R* 1 -1:00]     mx_axis_iorx_tlast    ;	
wire	[P_Srio_CH_NUM_R*64 -1:00]     mx_axis_iorx_tdata    ;	
wire	[P_Srio_CH_NUM_R* 8 -1:00]     mx_axis_iorx_tkeep    ;	
wire	[P_Srio_CH_NUM_R*32 -1:00]     mx_axis_iorx_tuser    ;	



genvar ii;
generate for(ii=0;ii<P_Srio_CH_NUM_R;ii=ii+1)
begin : i_srio
		srio_gen2_1g_1x_8b u_srio
	 (

			.log_clk_in                 			( log_clk_out          						),
			.phy_clk_in                 			( phy_clk_out          						),
			.gt_clk_in                  			( gt_clk_out           						),
			.gt_pcs_clk_in              			( gt_pcs_clk_out       						),

			.drpclk_in                  			( drpclk_out           						),

			.refclk_in                  			( refclk_out           						),
			.clk_lock_in                			( clk_lock_out         						),

			.cfg_rst_in                 			( cfg_rst_out          		[ii* 1 +: 1]	),
			.log_rst_in                 			( log_rst_out          		[ii* 1 +: 1]	),
			.buf_rst_in                 			( buf_rst_out          		[ii* 1 +: 1]	),
			.phy_rst_in                 			( phy_rst_out          		[ii* 1 +: 1]	),
			.gt_pcs_rst_in              			( gt_pcs_rst_out       		[ii* 1 +: 1]	),
`ifndef	SRIO_1_LANE
			.gt0_qpll_lock_in		      			( gt0_qpll_lock_out							),
`endif
			.gt0_qpll_clk_in             			( gt0_qpll_clk_out       					),
			.gt0_qpll_out_refclk_in      			( gt0_qpll_out_refclk_out					),

			.s_axi_maintr_rst           			( s_axi_maintr_rst			[ii* 1 +: 1]	),

			.	srio_rxn0						(				srio_rxn0						[ii* `SRIO_CH_LANE+0+: 1]	)	,	
			.	srio_rxp0						(				srio_rxp0						[ii* `SRIO_CH_LANE+0+: 1]	)	,	
			.	srio_txn0						(				srio_txn0						[ii* `SRIO_CH_LANE+0+: 1]	)	,	
			.	srio_txp0						(				srio_txp0						[ii* `SRIO_CH_LANE+0+: 1]	)	,	
	`ifdef	SRIO_2_LANE                                                              			        	     
			.	srio_rxn1						(				srio_rxn0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_rxp1						(				srio_rxp0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_txn1						(				srio_txn0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_txp1						(				srio_txp0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
	`elsif	SRIO_4_LANE	                                                             			        	     
			.	srio_rxn1						(				srio_rxn0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_rxp1						(				srio_rxp0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_txn1						(				srio_txn0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_txp1						(				srio_txp0						[ii* `SRIO_CH_LANE+1+: 1]	)	,	
			.	srio_rxn2						(				srio_rxn0						[ii* `SRIO_CH_LANE+2+: 1]	)	,	
			.	srio_rxp2						(				srio_rxp0						[ii* `SRIO_CH_LANE+2+: 1]	)	,	
			.	srio_txn2						(				srio_txn0						[ii* `SRIO_CH_LANE+2+: 1]	)	,	
			.	srio_txp2						(				srio_txp0						[ii* `SRIO_CH_LANE+2+: 1]	)	,
			.	srio_rxn3						(				srio_rxn0						[ii* `SRIO_CH_LANE+3+: 1]	)	,	
			.	srio_rxp3						(				srio_rxp0						[ii* `SRIO_CH_LANE+3+: 1]	)	,	
			.	srio_txn3						(				srio_txn0						[ii* `SRIO_CH_LANE+3+: 1]	)	,	
			.	srio_txp3						(				srio_txp0						[ii* `SRIO_CH_LANE+3+: 1]	)	,	
	`endif

			.s_axis_iotx_tvalid            			( mx_axis_iorx_tvalid     	[ii* 1 +: 1]	),
			.s_axis_iotx_tready            			( mx_axis_iorx_tready     	[ii* 1 +: 1]	),
			.s_axis_iotx_tlast             			( mx_axis_iorx_tlast      	[ii* 1 +: 1]	),
			.s_axis_iotx_tdata             			( mx_axis_iorx_tdata      	[ii*64 +:64]	),
			.s_axis_iotx_tkeep             			( mx_axis_iorx_tkeep      	[ii* 8 +: 8]	),
			.s_axis_iotx_tuser             			( mx_axis_iorx_tuser      	[ii*32 +:32]	),
																								
			.m_axis_iorx_tvalid            			( mx_axis_iorx_tvalid    	[ii* 1 +: 1]	),
			.m_axis_iorx_tready            			( mx_axis_iorx_tready    	[ii* 1 +: 1]	),
			.m_axis_iorx_tlast             			( mx_axis_iorx_tlast     	[ii* 1 +: 1]	),
			.m_axis_iorx_tdata             			( mx_axis_iorx_tdata     	[ii*64 +:64]	),
			.m_axis_iorx_tkeep             			( mx_axis_iorx_tkeep     	[ii* 8 +: 8]	),
			.m_axis_iorx_tuser             			( mx_axis_iorx_tuser     	[ii*32 +:32]	),

			.s_axi_maintr_awvalid          			( s_axi_maintr_awvalid     [ii* 1 +: 1]		),
			.s_axi_maintr_awready          			( s_axi_maintr_awready     [ii* 1 +: 1]		),
			.s_axi_maintr_awaddr           			( s_axi_maintr_awaddr      [ii*32 +:32]		),
			.s_axi_maintr_wvalid           			( s_axi_maintr_wvalid      [ii* 1 +: 1]		),
			.s_axi_maintr_wready           			( s_axi_maintr_wready      [ii* 1 +: 1]		),
			.s_axi_maintr_wdata            			( s_axi_maintr_wdata       [ii*32 +:32]		),
			.s_axi_maintr_bvalid           			( s_axi_maintr_bvalid      [ii* 1 +: 1]		),
			.s_axi_maintr_bready           			( s_axi_maintr_bready      [ii* 1 +: 1]		),
			.s_axi_maintr_bresp            			( s_axi_maintr_bresp       [ii* 2 +: 2]		),
																								
			.s_axi_maintr_arvalid          			( s_axi_maintr_arvalid     [ii* 1 +: 1]		),
			.s_axi_maintr_arready          			( s_axi_maintr_arready     [ii* 1 +: 1]		),
			.s_axi_maintr_araddr           			( s_axi_maintr_araddr      [ii*32 +:32]		),
			.s_axi_maintr_rvalid           			( s_axi_maintr_rvalid      [ii* 1 +: 1]		),
			.s_axi_maintr_rready           			( s_axi_maintr_rready      [ii* 1 +: 1]		),
			.s_axi_maintr_rdata            			( s_axi_maintr_rdata       [ii*32 +:32]		),
			.s_axi_maintr_rresp            			( s_axi_maintr_rresp       [ii* 2 +: 2]		),
																				
																				
			.sim_train_en                  			( sim_train_en      						),
			.force_reinit                  			( controlled_force_reinit	[ii* 1 +: 1]	),
			.phy_mce                       			( phy_mce           		[ii* 1 +: 1]	),
			.phy_link_reset                			( phy_link_reset    		[ii* 1 +: 1]	),

			.phy_rcvd_mce                  			( phy_rcvd_mce      		[ii* 1 +: 1]	),
			.phy_rcvd_link_reset           			( phy_rcvd_link_reset		[ii* 1 +: 1]	),
			.phy_debug                     			( phy_debug         		[ii*224+:224]	),
			.gtrx_disperr_or               			( gtrx_disperr_or   		[ii* 1 +: 1]	),
			.gtrx_notintable_or            			( gtrx_notintable_or		[ii* 1 +: 1]	),

			.port_error                      		( port_error        		[ii* 1 +: 1]	),
			.port_timeout                    		( port_timeout      		[ii*24 +:24]	),
			.srio_host                       		( srio_host         		[ii* 1 +: 1]	),
			.port_decode_error               		( port_decode_error 		[ii* 1 +: 1]	),
			.deviceid                        		( deviceid          		[ii*16 +:16]	),
			.idle2_selected                  		( idle2_selected    		[ii* 1 +: 1]	),

			.phy_lcl_master_enable_out       		( phy_lcl_master_enable_out    [ii* 1+:1]	),
			.buf_lcl_response_only_out       		( buf_lcl_response_only_out    [ii* 1+:1]	),
			.buf_lcl_tx_flow_control_out     		( buf_lcl_tx_flow_control_out  [ii* 1+:1]	),
			.buf_lcl_phy_buf_stat_out        		( buf_lcl_phy_buf_stat_out     [ii* 6+:6]	),
			.phy_lcl_phy_next_fm_out         		( phy_lcl_phy_next_fm_out      [ii* 6+:6]	),
			.phy_lcl_phy_last_ack_out        		( phy_lcl_phy_last_ack_out     [ii* 6+:6]	),
			.phy_lcl_phy_rewind_out          		( phy_lcl_phy_rewind_out       [ii* 1+:1]	),
			.phy_lcl_phy_rcvd_buf_stat_out   		( phy_lcl_phy_rcvd_buf_stat_out[ii* 6+:6]	),
			.phy_lcl_maint_only_out          		( phy_lcl_maint_only_out       [ii* 1+:1]	),

	//-------------newly added signals as per gt interface requirements-------------

			.port_initialized           			( port_initialized  		[ii* 1 +: 1]	),
			.link_initialized           			( link_initialized  		[ii* 1 +: 1]	),

			.idle_selected              			( idle_selected     		[ii* 1 +: 1]	),
			.mode_1x                    			( mode_1x           		[ii* 1 +: 1]	)
		 );
		 
		srio_gen2_1g_1x_8b_srio_rst
		srio_rst_inst (
			.cfg_clk                 				( log_clk_out     							),// input to the reset module
			.log_clk                 				( log_clk_out     							),// input to the reset module
			.phy_clk                 				( phy_clk_out     							),// input to the reset module
			.gt_pcs_clk              				( gt_pcs_clk_out  							),// input to the reset module

			.sys_rst                 				( sys_rst   | force_reinit	[ii* 1 +: 1]	),// input to the reset module
			.port_initialized        				( port_initialized		 	[ii* 1 +: 1]	),// input to the reset module
			.phy_rcvd_link_reset     				( phy_rcvd_link_reset	 	[ii* 1 +: 1]	),
			.force_reinit            				( 1'b0										),// input to the reset module
			.clk_lock                				( clk_lock_out    							),// input to the reset module

			.controlled_force_reinit 				( controlled_force_reinit	[ii* 1 +: 1]	),
			
			.cfg_rst                 				( cfg_rst_out     			[ii* 1 +: 1]	),// output from reset module
			.log_rst                 				( log_rst_out     			[ii* 1 +: 1]	),// output from reset module
			.buf_rst                 				( buf_rst_out     			[ii* 1 +: 1]	),// output from reset module
			.phy_rst                 				( phy_rst_out     			[ii* 1 +: 1]	),// output from reset module
			.gt_pcs_rst              				( gt_pcs_rst_out  			[ii* 1 +: 1]	) // output from reset module
		 );
end
endgenerate
//----------------------------------------------------------------------------//
  // SRIO_CLK Instantiaton --------------------
	srio_gen2_1g_1x_8b_srio_clk
	srio_clk_inst (
		.sys_clkp                				( sys_clkp        							),// input to the clock module
		.sys_clkn                				( sys_clkn        							),// input to the clock module
		.sys_rst                 				( sys_rst   								),// input to the clock module
		.mode_1x                 				( mode_1x       			[0]				),// input to the clock module

		.log_clk                 				( log_clk_out     							),// output from clock module
		.phy_clk                 				( phy_clk_out     							),// output from clock module
		.gt_clk                  				( gt_clk_out      							),// output from clock module
		.gt_pcs_clk              				( gt_pcs_clk_out  							),// output from clock module
		.refclk                  				( refclk_out      							),// output from clock module


		.drpclk                  				( drpclk_out								),// output from clock module

		.clk_lock                				( clk_lock_out								)// output from clock module
     );
  // End of SRIO_CLK instantiation ------------

	wire gt_pcs_rst 							= gt_pcs_rst_out[0]							;
`ifdef	K7
	srio_gen2_1g_1x_8b_k7_v7_gtxe2_common   k7_v7_gtxe2_common_inst(
		.gt0_gtrefclk0_common_in         		( refclk_out             					),// input   connect to refclk
		.gt0_qplllockdetclk_in           		( drpclk_out             					),// input   connect to drpclk
		.gt0_qpllreset_in                		( gt_pcs_rst	         					),// input   connect to gt_pcs_rst
		.qpll_clk_out                    		( gt0_qpll_clk_out       					),// output
		.qpll_out_refclk_out             		( gt0_qpll_out_refclk_out					),// output
		.gt0_qpll_lock_out               		( 					      					) // output  use only when 2x or 4x or 6G
	);
`else
    srio_gen2_1g_1x_8b_v7_gthe2_common  v7_gthe2_common_inst
    (
           .GTREFCLK0_IN        (refclk_out),           // input      GTREFCLK0_IN
           .QPLLLOCKDETCLK_IN   (drpclk_out),           // input      QPLLLOCKDETCLK_IN
           .QPLLRESET_IN        (gt_pcs_rst_out),       // input      QPLLRESET_IN
           .QPLLLOCK_OUT        (gt0_qpll_lock_out),    // output     QPLLLOCK_OUT
           .QPLLOUTCLK_OUT      (gt0_qpll_clk_out),     // output     QPLLOUTCLK_OUT
           .QPLLOUTREFCLK_OUT   (gt0_qpll_out_refclk_out),  // output     QPLLOUTREFCLK_OUT
           .QPLLREFCLKLOST_OUT  ()                      // output     QPLLREFCLKLOST_OUT
    );
`endif
//----------------------------------------------------------------------------//
// end of srio support module
ila_w32_d1024 your_instance_name (
	.clk(log_clk_out), // input wire clk


	.probe0(
	{
	mx_axis_iorx_tvalid     	[00* 1 +: 1]	,
	mx_axis_iorx_tready     	[00* 1 +: 1]	,
	mx_axis_iorx_tlast      	[00* 1 +: 1]	,
	mx_axis_iorx_tdata      	[00*64 +:64]	,
	mx_axis_iorx_tkeep      	[00* 8 +: 8]	,
	mx_axis_iorx_tuser      	[00*32 +:32]	,
	
	mx_axis_iorx_tvalid     	[01* 1 +: 1]	,
	mx_axis_iorx_tready     	[01* 1 +: 1]	,
	mx_axis_iorx_tlast      	[01* 1 +: 1]	,
	mx_axis_iorx_tdata      	[01*64 +:64]	,
	mx_axis_iorx_tkeep      	[01* 8 +: 8]	,
	mx_axis_iorx_tuser      	[01*32 +:32]	,
	
	
	port_decode_error,
	 port_initialized , 	   
	 link_initialized , 	   
	                
	 idle_selected ,    	   
	 mode_1x           	   
	}
	
	
	
	) // input wire [255:0] probe0
);

endmodule
