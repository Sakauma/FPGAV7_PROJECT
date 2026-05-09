//-----------------------------------------------------------------------------
// Title      : Core Support level wrapper
// Project    : 10GBASE-R
//-----------------------------------------------------------------------------
// File       : ten_gig_eth_pcs_pma_0_support.v
//-----------------------------------------------------------------------------
// Description: This file is a wrapper for the 10GBASE-R/KR Core Support level
// It contains the block level for the core which a user would instance in
// their own design, along with various modules which can be shared between
// several block levels.
//-----------------------------------------------------------------------------
// (c) Copyright 2009 - 2014 Xilinx, Inc. All rights reserved.
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
// PART OF THIS FILE AT ALL TIMES.

`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings="yes" *)
module ten_gig_eth_pcs_pma_0_support
  (
  input           refclk_p			,
  input           refclk_n			,
  input           dclk				,
  input           reset,
  input           sim_speedup_control,
  output          o_xgmii_clk         ,
  input  [63 : 0] xgmii_txd	,
  input  [7 : 0]  xgmii_txc	,
  output [63 : 0] xgmii_rxd			  ,
  output [7 : 0]  xgmii_rxc			  ,
  output          xgmii_rx_clk		  ,
  output          txp				  ,
  output          txn				  ,
  input           rxp				  ,
  input           rxn				  ,     
  output          o_block_sync        ,
  output          o_rst_done          ,
  output          o_pma_link          ,
  output          o_pcs_rx_link       ,   
  
  output [7:0]    core_status			,


  input           tx_fault,
  output          tx_disable);
  
  /*
  input           refclk_p                 ,
  input           refclk_n                 ,
  input           dclk                     ,
  output          coreclk_out              ,
  input           reset                    ,
  input           sim_speedup_control      ,
  output          qplloutclk_out           ,
  output          qplloutrefclk_out        ,
  output          qplllock_out             ,
  output          areset_datapathclk_out   ,
  output          txusrclk_out             ,
  output          txusrclk2_out            ,
  output          gttxreset_out            ,
  output          gtrxreset_out            ,
  output          txuserrdy_out            ,
  output          rxrecclk_out             ,
  output          reset_counter_done_out   ,
  input  [63 : 0] xgmii_txd                ,
  input  [7 : 0]  xgmii_txc                ,
  output [63 : 0] xgmii_rxd                ,
  output [7 : 0]  xgmii_rxc                ,
  output          txp                      ,
  output          txn                      ,
  input           rxp                      ,
  input           rxn                      ,
  input [535:0]   configuration_vector     ,
  output [447:0]  status_vector            ,
  output [7:0]    core_status              ,
  output          resetdone_out            ,
  input           signal_detect            ,
  input           tx_fault                 ,
  input [2:0]     pma_pmd_type             ,
  output          tx_disable);              
*/
 // Signal declarations
  wire coreclk;
  wire qplloutclk_out;
  wire qplloutrefclk_out;
  wire qplllock_out;
  wire txusrclk_out;
  wire txusrclk2_out;
  wire gttxreset_out;
  wire gtrxreset_out;
  wire txuserrdy_out;
  wire areset_datapathclk_out;
  wire reset_counter_done_out;

  
  
  wire [63:0] xgmii_rxd_int;
  wire [7:0] xgmii_rxc_int;
  wire dclk_buf;
   wire [535:0] configuration_vector;
   wire [535:0] w_configuration_vector;
   wire [447:0] status_vector;
   
   	//-----------------------------------///
  	//--------configuration_vector--///
  wire pma_loopback         ;
  wire pma_reset            ;
  wire global_tx_disable    ;
  wire pcs_loopback         ;
  wire pcs_reset            ;
  wire [57:0] test_patt_a_b ;
  wire data_patt_sel        ;
  wire test_patt_sel        ;
  wire rx_test_patt_en      ;
  wire tx_test_patt_en      ;
  wire prbs31_tx_en         ;
  wire prbs31_rx_en         ;
  wire set_pma_link_status  ;
  wire set_pcs_link_status  ;
  wire clear_pcs_status2    ;
  wire clear_test_patt_err_count    ;

   assign configuration_vector[0]   = pma_loopback;
   assign configuration_vector[14:1] = 0;
   assign configuration_vector[15]  = pma_reset;
   assign configuration_vector[16]  = global_tx_disable;
   assign configuration_vector[79:17] = 0;
   assign configuration_vector[83:80] = 0;
   assign configuration_vector[109:84] = 0;
   assign configuration_vector[110] = pcs_loopback;
   assign configuration_vector[111] = pcs_reset;
   assign configuration_vector[169:112] = 0;//test_patt_a_b
   assign configuration_vector[175:170] = 0;
   assign configuration_vector[233:176] = 0;//test_patt_a_b
   assign configuration_vector[239:234] = 0;
   assign configuration_vector[240] = 0;//data_patt_sel
   assign configuration_vector[241] = 0;//test_patt_sel
   assign configuration_vector[242] = 0;//rx_test_patt_en
   assign configuration_vector[243] = 0;//tx_test_patt_en
   assign configuration_vector[244] = 0;//prbs31_tx_en
   assign configuration_vector[245] = 0;//prbs31_rx_en
   assign configuration_vector[269:246] = 0;
   assign configuration_vector[271:270] = 0;
   assign configuration_vector[383:272] = 0;
   assign configuration_vector[399:384] = 16'h4C4B;
   assign configuration_vector[511:400] = 0;
   assign configuration_vector[512] = 1;//set_pma_link_status
   assign configuration_vector[515:513] = 0;
   assign configuration_vector[516] = 1;//set_pcs_link_status
   assign configuration_vector[517] = 0;
   assign configuration_vector[518] = 0;//clear_pcs_status2
   assign configuration_vector[519] = 0;//clear_test_patt_err_count
   assign configuration_vector[535:520] = 0;
  	
  	   assign w_configuration_vector[535:517] = 136'd0;
assign w_configuration_vector[516] = 1;
assign w_configuration_vector[515:513] = 136'd0;
assign w_configuration_vector[512] = 1;
assign w_configuration_vector[511:400] = 136'd0;
assign w_configuration_vector[399:384] = 16'h4C4B;
assign w_configuration_vector[383:1] = 384'd0;
assign w_configuration_vector[0:0] = 1;//PMA LOOPBACK

  	
  	wire pma_link_status                  ;
  	wire rx_sig_det                       ;
  	wire pcs_rx_link_status               ;
  	wire pcs_rx_locked                    ;
  	wire pcs_hiber                        ;
  	wire teng_pcs_rx_link_status          ;
  	wire [279:272] pcs_err_block_count    ;
  	wire [285:280] pcs_ber_count          ;
  	wire pcs_rx_hiber_lh                  ;
  	wire pcs_rx_locked_ll                 ;
  	wire [303:288] pcs_test_patt_err_count;
   assign pma_link_status = status_vector[18];
   assign rx_sig_det = status_vector[48];
   assign pcs_rx_link_status = status_vector[226];
   assign pcs_rx_locked = status_vector[256];
   assign pcs_hiber = status_vector[257];
   assign teng_pcs_rx_link_status = status_vector[268];
   assign pcs_err_block_count = status_vector[279:272];
   assign pcs_ber_count = status_vector[285:280];
   assign pcs_rx_hiber_lh = status_vector[286];
   assign pcs_rx_locked_ll = status_vector[287];
   assign pcs_test_patt_err_count = status_vector[303:288];

   assign o_pma_link    = status_vector[18]  ;
   assign o_pcs_rx_link = status_vector[226] ;
   assign o_block_sync  = core_status[0]     ;
    
   



  // Signal declarations
  wire coreclk;
  wire txoutclk;
  wire rxrecclk_out_int;
  wire qplloutclk;
  wire qplloutrefclk;
  wire qplllock;
  wire drp_gnt;
  wire drp_req;
  wire drp_den_o;
  wire drp_dwe_o;
  wire [15 : 0] drp_daddr_o;
  wire [15 : 0] drp_di_o;
  wire drp_drdy_o;
  wire [15 : 0] drp_drpdo_o;
  wire drp_den_i;
  wire drp_dwe_i;
  wire [15 : 0] drp_daddr_i;
  wire [15 : 0] drp_di_i;
  wire drp_drdy_i;
  wire [15 : 0] drp_drpdo_i;

  wire tx_resetdone_int;
  wire rx_resetdone_int;

  wire areset_coreclk;
  wire gttxreset;
  wire gtrxreset;
  wire qpllreset;
  wire txuserrdy;
  wire reset_counter_done;

  wire txusrclk;
  wire txusrclk2;
  wire areset_txusrclk2;
  wire refclk;         
  
  
   wire [63 : 0] xgmii_txdv   ;
   wire [7 : 0]  xgmii_txcv   ;
  
  reg	[31:0]	core_clk_cnt ;
  reg	[31:0]	dclk_cnt ;
  always @( posedge coreclk ) begin 
		if ( reset )  begin
  			core_clk_cnt		<= 32'd0 			;
  		end else begin 
  			core_clk_cnt		<= core_clk_cnt +1		;
  		end
  end
  always @( posedge dclk ) begin 
		if ( reset )  begin
  			dclk_cnt		<= 32'd0 			;
  		end else begin 
  			dclk_cnt		<= dclk_cnt +1		;
  		end
  end
  
  
  
  

  assign o_xgmii_clk = coreclk;   
  assign xgmii_rx_clk= coreclk;
  assign o_rst_done = tx_resetdone  && rx_resetdone ;

  // If no arbitration is required on the GT DRP ports then connect REQ to GNT
  // and connect other signals i <= o;
  assign drp_gnt = drp_req;
  assign drp_den_i = drp_den_o;
  assign drp_dwe_i = drp_dwe_o;
  assign drp_daddr_i = drp_daddr_o;
  assign drp_di_i = drp_di_o;
  assign drp_drdy_i = drp_drdy_o;
  assign drp_drpdo_i = drp_drpdo_o;
  assign qplloutclk_out = qplloutclk;
  assign qplloutrefclk_out = qplloutrefclk;
  assign qplllock_out = qplllock;
  assign txusrclk_out = txusrclk;
  assign txusrclk2_out = txusrclk2;
  assign areset_datapathclk_out = areset_coreclk;
  assign gttxreset_out = gttxreset;
  assign gtrxreset_out = gtrxreset;
  assign txuserrdy_out = txuserrdy;
  assign reset_counter_done_out = reset_counter_done;

  // Instantiate the 10GBASER/KR GT Common block
 
 
 
 
 
  ten_gig_eth_pcs_pma_0_gt_common # (
      .WRAPPER_SIM_GTRESET_SPEEDUP("TRUE") ) //Does not affect hardware
  ten_gig_eth_pcs_pma_gt_common_block
    (
     .refclk(refclk),
     .qpllreset(qpllreset),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk)
    );

  
  // Instantiate the 10GBASER/KR shared clock/reset block





  ten_gig_eth_pcs_pma_0_shared_clock_and_reset ten_gig_eth_pcs_pma_shared_clock_reset_block
    (
     .areset(reset),
     .refclk_p(refclk_p),
     .refclk_n(refclk_n),
     .refclk(refclk),
     .coreclk(coreclk),
     .txoutclk(txoutclk),
     .qplllock(qplllock),
     .areset_coreclk(areset_coreclk),
     .gttxreset(gttxreset),
     .gtrxreset(gtrxreset),
     .txuserrdy(txuserrdy),
     .txusrclk(txusrclk),
     .txusrclk2(txusrclk2),
     .qpllreset(qpllreset),
     .reset_counter_done(reset_counter_done)
    );

  // Instantiate the 10GBASER/KR Block Level
    
    
    
    
    
  ten_gig_eth_pcs_pma_0 ten_gig_eth_pcs_pma_i
                                (
      .coreclk               (  coreclk               ),  																																												
      .dclk                  (  dclk	              ),  																																												
      .txusrclk              (  txusrclk              ),  																																												
      .txusrclk2             (  txusrclk2             ),  																																												
      .txoutclk              (  txoutclk              ),  																																												
      .areset_coreclk        (  areset_coreclk        ),  																																												
      .txuserrdy             (  txuserrdy             ),  																																												
      .rxrecclk_out          (  rxrecclk_out          ),  																																												
     .areset                 (  reset                 ),  																																												
      .gttxreset             (  gttxreset             ),  																																												
      .gtrxreset             (  gtrxreset             ),  																																												
     .sim_speedup_control    (  0					    ),  																																												
      .qplllock              (  qplllock              ),  																																												
      .qplloutclk            (  qplloutclk            ),  																																												
      .qplloutrefclk         (  qplloutrefclk         ),  																																												
      .reset_counter_done    (  reset_counter_done    ),  																																												
      .xgmii_txd             (  xgmii_txd              ), //xgmii_txd																																												
      .xgmii_txc             (  xgmii_txc              ), //xgmii_txc																																												
      .xgmii_rxd             (  xgmii_rxd             ),  																																												
      .xgmii_rxc             (  xgmii_rxc             ),  																																												
      .txp                   (  txp                   ),  																																												
      .txn                   (  txn                   ),  																																												
      .rxp                   (  rxp                   ),  																																												
      .rxn                   (  rxn                   ),  																																												
      .configuration_vector  (  w_configuration_vector  ),  																																												
      .status_vector         (  status_vector         ),  																																												
      .core_status           (  core_status           ),  																																												
      .tx_resetdone          (  tx_resetdone          ),  																																												
      .rx_resetdone          (  rx_resetdone          ),  																																												
      .signal_detect         (  1			          ),  																																												
      .tx_fault              (  0		              ),  																																												
      .drp_req               (  drp_req               ),  																																												
      .drp_gnt               (  drp_gnt               ),  																																												
      .drp_den_o             (                        ),  																																												
      .drp_dwe_o             (                        ),  																																												
      .drp_daddr_o           (                        ),  																																												
      .drp_di_o              (                        ),  																																												
      .drp_drdy_o            (                        ),  																																												
      .drp_drpdo_o           (                        ),  																																												
      .drp_den_i             (    0                   ),  																																												
      .drp_dwe_i             (    0                   ),  																																												
      .drp_daddr_i           (    0                   ),  																																												
      .drp_di_i              (    0                   ),  																																												
      .drp_drdy_i            (    0                   ),  																																												
      .drp_drpdo_i           (    0                   ),  																																												
      .pma_pmd_type          (  3'b101	       		  ),  																																												
      .tx_disable            (  tx_disable            )   																																												
      );                                                  																																												
/* 
   	ila_576X1024 ila_w32_d1024_spi (
   		.	clk		(	coreclk	)	,	// input wire clk
   		.	probe0	(	
   						{
   				 				
   				 o_pma_link    				
   				,o_pcs_rx_link 				
   				,o_block_sync 	
   				,reset_counter_done
   				,xgmii_txd         
   				,xgmii_txc         
   				,xgmii_rxd         
   				,xgmii_rxc 
   				,core_status
   				,tx_resetdone        
   				,rx_resetdone
 //  				,dclk_cnt
   				,core_clk_cnt
   				//,pma_link_status
 
   						}	
   		)		// input wire [31:0] probe0
   	);
   	
  	
   	vio_2 your_instance_name (
  .clk(coreclk),                // input wire clk
  .probe_in0(probe_in0),    // input wire [31 : 0] probe_in0
  .probe_out0({
    xgmii_txdv,
  xgmii_txcv,  
  pma_reset,  
  pcs_reset,
  global_tx_disable,
  pcs_loopback

  }
  
  
  )  // output wire [63 : 0] probe_out0
);
   	*/
   	
endmodule
