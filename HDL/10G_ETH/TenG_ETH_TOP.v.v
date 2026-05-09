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
// Inst File£º							
// 										
// Revision:							
// 										
////////////////////////////////////////////////////////////////////////////////////////////////////
module TenG_ETH_TOP	#(					
	parameter       P_SOURCE_IP   = {8'd192,8'd168,8'd100,8'd100}   ,    
	parameter       P_TARGET_IP   = {8'd192,8'd168,8'd100,8'd99 }   ,    
	parameter       P_SOURCE_PORT = 16'd8080                        ,    
	parameter       P_TARGET_PORT = 16'd8080                        ,    
	parameter       P_SOURCE_MAC  = 48'h01_02_03_04_05_06           ,    
	parameter       P_TARGET_MAC  = 48'h0a_0b_0c_0d_0e_0f                
	)(
//---selfdefine Interface-----------------------
	wire [63:0]     wm_axis_user_data   ,
	wire [31:0]     wm_axis_user_user   ,
	wire [7 :0]     wm_axis_user_keep   ,
	wire            wm_axis_user_last   ,
	wire            wm_axis_user_valid  ,
	wire            wm_axis_user_ready  ,
	
	wire [63:0]     ws_axis_user_data   ,
	wire [31:0]     ws_axis_user_user   ,
	wire [7 :0]     ws_axis_user_keep   ,
	wire            ws_axis_user_last   ,
	wire            ws_axis_user_valid  ,																		 
	wire            ws_axis_user_ready  ,																		 

//---Common Interface---------------------------
 	input       i_gt_clk_p          ,
    input       i_gt_clk_n          ,
    input       i_sys_clk_p         ,
    input       i_sys_clk_n         ,

    output      o_gt_txp            ,
    output      o_gt_txn            ,
    input       i_gt_rxp            ,
    input       i_gt_rxn            ,
    output      o_sfp_disable       ,
    input		dclk				,
    output		w_xgmii_clk 		,
    input		w_xgmii_rst 
);


wire  [63:0]    wm_axis_mac_data        ;
wire  [79:0]    wm_axis_mac_user        ;
wire  [7 :0]    wm_axis_mac_keep        ;
wire            wm_axis_mac_last        ;
wire            wm_axis_mac_valid       ;
wire  [63:0]    ws_axis_mac_data        ;
wire  [79:0]    ws_axis_mac_user        ;
wire  [7 :0]    ws_axis_mac_keep        ;
wire            ws_axis_mac_last        ;
wire            ws_axis_mac_valid       ;
wire            w_crc_error             ;
wire            w_crc_valid             ;



  wire	 [63:0]   w_xgmii_rxd       ; 
  wire	 [7 :0]   w_xgmii_rxc       ; 
  wire	 [63:0]   w_xgmii_txd       ; 
  wire	 [7 :0]   w_xgmii_txc       ; 

UDP_10G_Stack#(
    .P_SOURCE_IP                    (P_SOURCE_IP                        ),
    .P_TARGET_IP                    (P_TARGET_IP                        ),
    .P_SOURCE_PORT                  (P_SOURCE_PORT                      ),
    .P_TARGET_PORT                  (P_TARGET_PORT                      ),
    .P_SOURCE_MAC                   (P_SOURCE_MAC                       ),
    .P_TARGET_MAC                   (P_TARGET_MAC                       )  
)
UDP_10G_Stack_u0
(
    .i_clk                          (w_xgmii_clk                        ),
    .i_rst                          (w_xgmii_rst                        ),
    .i_set_source_ip                (0                                  ),
    .i_set_source_ip_valid          (0                                  ),
    .i_set_target_ip                (0                                  ),
    .i_set_target_ip_valid          (0                                  ),
    .i_set_source_port              (0                                  ),
    .i_set_source_port_valid        (0                                  ),
    .i_set_target_port              (0                                  ),
    .i_set_target_port_valid        (0                                  ),
    .i_set_source_mac               (0                                  ),
    .i_set_source_mac_valid         (0                                  ),
    .i_arp_active                   (0                                  ),

    .s_axis_user_data               (wm_axis_user_data                  ),
    .s_axis_user_user               (wm_axis_user_user                  ),
    .s_axis_user_keep               (wm_axis_user_keep                  ),
    .s_axis_user_last               (wm_axis_user_last                  ),
    .s_axis_user_valid              (wm_axis_user_valid                 ),
    .s_axis_user_ready              (wm_axis_user_ready                 ),
    .m_axis_user_data               (ws_axis_user_data                  ),
    .m_axis_user_user               (ws_axis_user_user                  ),
    .m_axis_user_keep               (ws_axis_user_keep                  ),
    .m_axis_user_last               (ws_axis_user_last                  ),
    .m_axis_user_valid              (ws_axis_user_valid                 ),

    .m_axis_mac_data                (ws_axis_mac_data                   ),
    .m_axis_mac_user                (ws_axis_mac_user                   ),
    .m_axis_mac_keep                (ws_axis_mac_keep                   ),
    .m_axis_mac_last                (ws_axis_mac_last                   ),
    .m_axis_mac_valid               (ws_axis_mac_valid                  ),
    .s_axis_mac_data                (wm_axis_mac_data                   ),
    .s_axis_mac_user                (wm_axis_mac_user                   ),
    .s_axis_mac_keep                (wm_axis_mac_keep                   ),
    .s_axis_mac_last                (wm_axis_mac_last                   ),
    .s_axis_mac_valid               (wm_axis_mac_valid                  )
);

TenG_Mac_Module#(
    .P_SOURCE_MAC                   (P_SOURCE_MAC       ),
    .P_TARGET_MAC                   (P_TARGET_MAC       )
)TenG_Mac_Module_u0(
    .i_xgmii_clk                    (w_xgmii_clk        ),
    .i_xgmii_rst                    (w_xgmii_rst        ),
    .i_xgmii_rxd                    (w_xgmii_rxd        ),
    .i_xgmii_rxc                    (w_xgmii_rxc        ),
    .o_xgmii_txd                    (w_xgmii_txd        ),
    .o_xgmii_txc                    (w_xgmii_txc        ),

    .i_set_source_mac               (0                  ),
    .i_set_source_valid             (0                  ),
    .i_set_target_mac               (0                  ),
    .i_set_target_valid             (0                  ),
    .m_axis_data                    (wm_axis_mac_data   ),
    .m_axis_user                    (wm_axis_mac_user   ),//16'dlen,48d'dsource_mac,16'dtype
    .m_axis_keep                    (wm_axis_mac_keep   ),
    .m_axis_last                    (wm_axis_mac_last   ),
    .m_axis_valid                   (wm_axis_mac_valid  ),
    .o_crc_error                    (w_crc_error        ),
    .o_crc_valid                    (w_crc_valid        ),
    .s_axis_data                    (ws_axis_mac_data   ),
    .s_axis_user                    (ws_axis_mac_user   ),//16'dlen,48d'dsource_mac,16'dtype
    .s_axis_keep                    (ws_axis_mac_keep   ),
    .s_axis_last                    (ws_axis_mac_last   ),
    .s_axis_valid                   (ws_axis_mac_valid  )
);
  /*
TenG_ETH_PCSPMA TenG_ETH_PCSPMA_u0(
    .i_gtref_clk                    (w_gtref_clk        ),
    .i_system_clk                   (w_sys_clk          ),
    .i_rst                          (0                  ),
    .i_sim_true                     (0                  ),
    .o_qpllreset                    (w_qpllreset        ),
    .i_qplllock                     (w_qplllock         ),
    .i_qplloutclk                   (w_qplloutclk       ),
    .i_qplloutrefclk                (w_qplloutrefclk    ),
    .i_gt_rxp                       (i_gt_rxp           ),
    .i_gt_rxn                       (i_gt_rxn           ),
    .o_gt_txp                       (o_gt_txp           ),
    .o_gt_txn                       (o_gt_txn           ),
    .o_block_sync                   (w_block_sync       ),
    .o_rst_done                     (w_rst_done         ),
    .o_pma_link                     (w_pma_link         ),
    .o_pcs_rx_link                  (w_pcs_rx_link      ),
    .o_xgmii_clk                    (w_xgmii_clk        ),   
    .o_xgmii_rxd                    (w_xgmii_rxd        ),
    .o_xgmii_rxc                    (w_xgmii_rxc        ),
    .i_xgmii_txd                    (w_xgmii_txd        ),
    .i_xgmii_txc                    (w_xgmii_txc        ),

    .o_sfp_disable                  (                   )        
);
*/

ten_gig_eth_pcs_pma_0_support
  
 ten_gig_eth_support  (
    
  	.refclk_p						(	i_gt_clk_p 		),
  	.refclk_n						(	i_gt_clk_n 		),
  	.dclk							(	dclk			),
  	 
  	.reset							(	reset			),
  	.sim_speedup_control			(	0				),
  	.o_xgmii_clk        			(	w_xgmii_clk		),
  	.xgmii_txd			 			(	w_xgmii_txd	 	),
  	.xgmii_txc			 			(	w_xgmii_txc	 	),
  	.xgmii_rxd			 			(	w_xgmii_rxd		),
  	.xgmii_rxc			 			(	w_xgmii_rxc		),
  	.xgmii_rx_clk		 			(	 			  	),
  	.txp				 			(	 	o_gt_txp 	),
  	.txn				 			(	 	o_gt_txn	),
  	.rxp				 			(	i_gt_rxp  		),
  	.rxn				 			(	i_gt_rxn 		),     
  	.o_block_sync       			(	w_block_sync  	),
  	.o_rst_done         			(	w_rst_done    	),
  	.o_pma_link         			(	w_pma_link    	),
  	.o_pcs_rx_link      			(	w_pcs_rx_link 	),   
  	.core_status					(					),
 
  	.tx_fault						(					) ,
  	.tx_disable						(					)
  
  );
  
  /*
 ila_576X1024 ila_w32_d1024_spi (
   		.	clk		(	w_xgmii_clk	)	,	// input wire clk
   		.	probe0	(	
   						{
   				 				
   				wm_axis_user_data 		
   				,wm_axis_user_user 		
   				,wm_axis_user_keep 
   				,wm_axis_user_last 
   				,wm_axis_user_valid
   				,wm_axis_user_ready    
   				,ws_axis_user_data  
   				,ws_axis_user_user  
   				,ws_axis_user_keep  
   				,ws_axis_user_last  
   				,ws_axis_user_valid 
   				,ws_axis_user_ready 
   				,wm_axis_mac_data  
   				,wm_axis_mac_user  
   				,wm_axis_mac_keep  
   				,wm_axis_mac_last  
   				,wm_axis_mac_valid 
   				,ws_axis_mac_data    
   				,ws_axis_mac_user
   				,ws_axis_mac_keep
   				,ws_axis_mac_last      
   				,ws_axis_mac_valid
   				,w_xgmii_txd                     
   				,w_xgmii_txc                     
   				                     
 
   						}	
   		)		// input wire [31:0] probe0
   	);
  
   */
  

endmodule
