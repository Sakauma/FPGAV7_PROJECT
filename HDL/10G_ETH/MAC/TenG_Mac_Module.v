`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/06 11:06:44
// Design Name: 
// Module Name: TenG_Mac_Module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TenG_Mac_Module#(
    parameter       P_SOURCE_MAC  = 48'h00_00_00_00_00_00   ,
    parameter       P_TARGET_MAC  = 48'h00_00_00_00_00_00   
)(
    input           i_xgmii_clk         ,
    input           i_xgmii_rst         ,
    input  [63:0]   i_xgmii_rxd         ,
    input  [7 :0]   i_xgmii_rxc         ,
    output [63:0]   o_xgmii_txd         ,
    output [7 :0]   o_xgmii_txc         ,

    input  [47:0]   i_set_source_mac    ,
    input           i_set_source_valid  ,
    input  [47:0]   i_set_target_mac    ,
    input           i_set_target_valid  ,

    output [63:0]   m_axis_data         ,
    output [79:0]   m_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]   m_axis_keep         ,
    output          m_axis_last         ,
    output          m_axis_valid        ,
    output          o_crc_error         ,
    output          o_crc_valid         ,

    input  [63:0]   s_axis_data         ,
    input  [79:0]   s_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]   s_axis_keep         ,
    input           s_axis_last         ,
    input           s_axis_valid        
);

wire  [63:0]        w_xgmii_rxd         ;
wire  [7 :0]        w_xgmii_rxc         ;
wire  [63:0]        w_xgmii_rxd_7h55    ;
wire  [7 :0]        w_xgmii_rxc_7h55    ;
wire  [63:0]        w_xgmii_txd         ;
wire  [7 :0]        w_xgmii_txc         ;
wire  [63:0]        w_xgmii_txd_7h55    ;
wire  [7 :0]        w_xgmii_txc_7h55    ;
wire  [63:0]        wm_axis_data        ;
wire  [79:0]        wm_axis_user        ;
wire  [7 :0]        wm_axis_keep        ;
wire                wm_axis_last        ;
wire                wm_axis_valid       ;
wire                w_crc_error         ;
wire                w_crc_valid         ;

assign o_crc_error = w_crc_error        ;
assign o_crc_valid = w_crc_valid        ;
assign w_xgmii_rxd   = {i_xgmii_rxd[7 :0],i_xgmii_rxd[15:8],i_xgmii_rxd[23:16],i_xgmii_rxd[31:24],i_xgmii_rxd[39:32],i_xgmii_rxd[47:40],i_xgmii_rxd[55:48],i_xgmii_rxd[63:56]};
assign w_xgmii_rxc   = {i_xgmii_rxc[0],i_xgmii_rxc[1],i_xgmii_rxc[2],i_xgmii_rxc[3],i_xgmii_rxc[4],i_xgmii_rxc[5],i_xgmii_rxc[6],i_xgmii_rxc[7]};
assign o_xgmii_txd = {w_xgmii_txd[7 :0],w_xgmii_txd[15:8],w_xgmii_txd[23:16],w_xgmii_txd[31:24],w_xgmii_txd[39:32],w_xgmii_txd[47:40],w_xgmii_txd[55:48],w_xgmii_txd[63:56]};
assign o_xgmii_txc = {w_xgmii_txc[0],w_xgmii_txc[1],w_xgmii_txc[2],w_xgmii_txc[3],w_xgmii_txc[4],w_xgmii_txc[5],w_xgmii_txc[6],w_xgmii_txc[7]};

Mac_Tx_Header Mac_Tx_Header_u0(
    .i_clk                          (i_xgmii_clk            ),
    .i_rst                          (i_xgmii_rst            ),

    .i_xgmii_txd                    (w_xgmii_txd_7h55       ),
    .i_xgmii_txc                    (w_xgmii_txc_7h55       ),

    .o_xgmii_txd                    (w_xgmii_txd            ),
    .o_xgmii_txc                    (w_xgmii_txc            )
);

TenG_Mac_Tx#(
    .P_SOURCE_MAC                   (P_SOURCE_MAC           ),
    .P_TARGET_MAC                   (P_TARGET_MAC           )
)
TenG_Mac_Tx_u0
(
    .i_clk                          (i_xgmii_clk            ),
    .i_rst                          (i_xgmii_rst            ),

    .i_set_source_mac               (i_set_source_mac       ),
    .i_set_source_valid             (i_set_source_valid     ),
    .i_set_target_mac               (i_set_target_mac       ),
    .i_set_target_valid             (i_set_target_valid     ),

    .s_axis_data                    (s_axis_data            ),
    .s_axis_user                    (s_axis_user            ),
    .s_axis_keep                    (s_axis_keep            ),
    .s_axis_last                    (s_axis_last            ),
    .s_axis_valid                   (s_axis_valid           ),

    .o_xgmii_txd                    (w_xgmii_txd_7h55       ),
    .o_xgmii_txc                    (w_xgmii_txc_7h55       )
);

CRC_Process CRC_Process_u0(
    .i_clk                          (i_xgmii_clk            ),
    .i_rst                          (i_xgmii_rst            ),

    .s_axis_data                    (wm_axis_data           ),
    .s_axis_user                    (wm_axis_user           ),
    .s_axis_keep                    (wm_axis_keep           ),
    .s_axis_last                    (wm_axis_last           ),
    .s_axis_valid                   (wm_axis_valid          ),
    .i_crc_error                    (w_crc_error            ),
    .i_crc_valid                    (w_crc_valid            ),

    .m_axis_data                    (m_axis_data            ),
    .m_axis_user                    (m_axis_user            ),
    .m_axis_keep                    (m_axis_keep            ),
    .m_axis_last                    (m_axis_last            ),
    .m_axis_valid                   (m_axis_valid           )
);

TenG_Mac_Rx#(
    .P_SOURCE_MAC                   (P_SOURCE_MAC           ),
    .P_TARGET_MAC                   (P_TARGET_MAC           )
)
TenG_Mac_Rx_u0
(
    .i_clk                          (i_xgmii_clk            ),
    .i_rst                          (i_xgmii_rst            ),
    .i_xgmii_rxd                    (w_xgmii_rxd_7h55       ),
    .i_xgmii_rxc                    (w_xgmii_rxc_7h55       ),

    .i_set_source_mac               (i_set_source_mac       ),
    .i_set_source_valid             (i_set_source_valid     ),
    .i_set_target_mac               (i_set_target_mac       ),
    .i_set_target_valid             (i_set_target_valid     ),
    
    .m_axis_data                    (wm_axis_data           ),
    .m_axis_user                    (wm_axis_user           ),
    .m_axis_keep                    (wm_axis_keep           ),
    .m_axis_last                    (wm_axis_last           ),
    .m_axis_valid                   (wm_axis_valid          ),
    .o_crc_error                    (w_crc_error            ),
    .o_crc_valid                    (w_crc_valid            )
);

Mac_Rx_Header Mac_Rx_Header_u0(
    .i_clk                          (i_xgmii_clk            ),
    .i_rst                          (i_xgmii_rst            ),

    .i_xgmii_rxd                    (w_xgmii_rxd            ),
    .i_xgmii_rxc                    (w_xgmii_rxc            ),

    .o_xgmii_rxd                    (w_xgmii_rxd_7h55       ),
    .o_xgmii_rxc                    (w_xgmii_rxc_7h55       )
);
/* 
 ila_576X1024 ila_w32_d1024_spi (
   		.	clk		(	i_xgmii_clk	)	,	// input wire clk
   		.	probe0	(	
   						{
   				 				
   				 s_axis_data  
   				,s_axis_user  
   				,s_axis_keep  
   				,s_axis_last  
   				,s_axis_valid 
   				,w_xgmii_txd_7h55
   				,w_xgmii_txc_7h55   
   				,w_xgmii_txd 
   				,w_xgmii_txc   
   				,o_xgmii_txd 
   				,o_xgmii_txc                      
   				                  
   				                     
   				                     
   				                     
 
   						}	
   		)		// input wire [31:0] probe0
   	);
  */
   











endmodule
