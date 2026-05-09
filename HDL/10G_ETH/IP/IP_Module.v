`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/21 10:38:41
// Design Name: 
// Module Name: IP_Module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: //16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IP_Module#(
    parameter       P_SOURCE_IP = {8'd192,8'd168,8'd100,8'd100} ,
    parameter       P_TARGET_IP = {8'd192,8'd168,8'd100,8'd99 }
)(
    input           i_clk               ,
    input           i_rst               ,

    input  [31:0]   i_set_source_ip     ,
    input           i_set_source_valid  ,
    input  [31:0]   i_set_target_ip     ,
    input           i_set_target_valid  ,

    /*----mac axis----*/
    output [63:0]   m_axis_mac_data     ,
    output [79:0]   m_axis_mac_user     ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]   m_axis_mac_keep     ,
    output          m_axis_mac_last     ,
    output          m_axis_mac_valid    ,
    input           m_axis_mac_ready    ,
    
    input  [63:0]   s_axis_mac_data     ,
    input  [79:0]   s_axis_mac_user     ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]   s_axis_mac_keep     ,
    input           s_axis_mac_last     ,
    input           s_axis_mac_valid    ,
    /*----out aixs----*/           
    output [63:0]   m_axis_out_data     ,
    output [54:0]   m_axis_out_user     ,//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    output [7 :0]   m_axis_out_keep     ,
    output          m_axis_out_last     ,
    output          m_axis_out_valid    ,
    
    input  [63:0]   s_axis_out_data     ,
    input  [70:0]   s_axis_out_user     ,//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    input  [7 :0]   s_axis_out_keep     ,
    input           s_axis_out_last     ,
    input           s_axis_out_valid    ,
    output          s_axis_out_ready    ,

    output [31:0]   o_query_ip          ,
    output          o_query_valid       ,
    input  [47:0]   i_read_mac          ,
    input           i_read_valid        
);

IP_TX#(
    .P_SOURCE_IP            (P_SOURCE_IP        ),
    .P_TARGET_IP            (P_TARGET_IP        )
)IP_TX_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_set_source_ip        (i_set_source_ip    ),
    .i_set_source_valid     (i_set_source_valid ),
    .i_set_target_ip        (i_set_target_ip    ),
    .i_set_target_valid     (i_set_target_valid ),

    .s_axis_out_data        (s_axis_out_data    ),
    .s_axis_out_user        (s_axis_out_user    ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .s_axis_out_keep        (s_axis_out_keep    ),
    .s_axis_out_last        (s_axis_out_last    ),
    .s_axis_out_valid       (s_axis_out_valid   ),
    .s_axis_out_ready       (s_axis_out_ready   ),

    .m_axis_mac_data        (m_axis_mac_data    ),
    .m_axis_mac_user        (m_axis_mac_user    ),//16'dlen,48'dsource_mac,16'dtype
    .m_axis_mac_keep        (m_axis_mac_keep    ),
    .m_axis_mac_last        (m_axis_mac_last    ),
    .m_axis_mac_valid       (m_axis_mac_valid   ),
    .m_axis_mac_ready       (m_axis_mac_ready   ),
    .o_query_ip             (o_query_ip         ),
    .o_query_valid          (o_query_valid      ),
    .i_read_mac             (i_read_mac         ),
    .i_read_valid           (i_read_valid       )
);

IP_RX#(
    .P_SOURCE_IP            (P_SOURCE_IP        )
)
IP_RX_u0
(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_set_source_ip        (i_set_source_ip    ),
    .i_set_source_valid     (i_set_source_valid ),

    .s_axis_mac_data        (s_axis_mac_data    ),
    .s_axis_mac_user        (s_axis_mac_user    ),//16'dlen,48'dsource_mac,16'dtype
    .s_axis_mac_keep        (s_axis_mac_keep    ),
    .s_axis_mac_last        (s_axis_mac_last    ),
    .s_axis_mac_valid       (s_axis_mac_valid   ),

    .m_axis_out_data        (m_axis_out_data    ),
    .m_axis_out_user        (m_axis_out_user    ),//16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .m_axis_out_keep        (m_axis_out_keep    ),
    .m_axis_out_last        (m_axis_out_last    ),
    .m_axis_out_valid       (m_axis_out_valid   )
);
endmodule
