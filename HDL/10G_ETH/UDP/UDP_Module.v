`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/24 14:03:07
// Design Name: 
// Module Name: UDP_Module
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


module UDP_Module#(
    parameter           P_SOURCE_PORT = 16'd8080    ,
    parameter           P_TARGET_PORT = 16'd8080    
)(
    input               i_clk                       ,
    input               i_rst                       ,

    input  [15:0]       i_set_source_port           ,
    input               i_set_source_valid          ,
    input  [15:0]       i_set_target_port           ,
    input               i_set_target_valid          ,

    /*----IP----*/
    input  [63:0]       s_axis_ip_data              ,
    input  [54:0]       s_axis_ip_user              ,//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    input  [7 :0]       s_axis_ip_keep              ,
    input               s_axis_ip_last              ,
    input               s_axis_ip_valid             ,
    output [63:0]       m_axis_ip_data              ,
    output [70:0]       m_axis_ip_user              ,//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    output [7 :0]       m_axis_ip_keep              ,
    output              m_axis_ip_last              ,
    output              m_axis_ip_valid             ,
    input               m_axis_ip_ready             ,

    /*----user----*/
    input  [63:0]       s_axis_user_data            ,
    input  [31:0]       s_axis_user_user            ,
    input  [7 :0]       s_axis_user_keep            ,
    input               s_axis_user_last            ,
    input               s_axis_user_valid           ,
    output              s_axis_user_ready           ,
    output [63:0]       m_axis_user_data            ,
    output [31:0]       m_axis_user_user            ,
    output [7 :0]       m_axis_user_keep            ,
    output              m_axis_user_last            ,
    output              m_axis_user_valid           
);

UDP_RX#(
    .P_SOURCE_PORT      (P_SOURCE_PORT          ),
    .P_TARGET_PORT      (P_TARGET_PORT          )
)
UDP_RX_u0
(
    .i_clk              (i_clk                  ),
    .i_rst              (i_rst                  ),
    .i_set_source_port  (i_set_source_port      ),
    .i_set_source_valid (i_set_source_valid     ),
    .i_set_target_port  (i_set_target_port      ),
    .i_set_target_valid (i_set_target_valid     ),
    .s_axis_ip_data     (s_axis_ip_data         ),
    .s_axis_ip_user     (s_axis_ip_user         ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .s_axis_ip_keep     (s_axis_ip_keep         ),
    .s_axis_ip_last     (s_axis_ip_last         ),
    .s_axis_ip_valid    (s_axis_ip_valid        ),
    .m_axis_user_data   (m_axis_user_data       ),
    .m_axis_user_user   (m_axis_user_user       ),
    .m_axis_user_keep   (m_axis_user_keep       ),
    .m_axis_user_last   (m_axis_user_last       ),
    .m_axis_user_valid  (m_axis_user_valid      )
);

UDP_TX#(
    .P_SOURCE_PORT      (P_SOURCE_PORT          ),
    .P_TARGET_PORT      (P_TARGET_PORT          )
)
UDP_TX_u0
(
    .i_clk              (i_clk                  ),
    .i_rst              (i_rst                  ),
    .i_set_source_port  (i_set_source_port      ),
    .i_set_source_valid (i_set_source_valid     ),
    .i_set_target_port  (i_set_target_port      ),
    .i_set_target_valid (i_set_target_valid     ),
    .s_axis_user_data   (s_axis_user_data       ),
    .s_axis_user_user   (s_axis_user_user       ),
    .s_axis_user_keep   (s_axis_user_keep       ),
    .s_axis_user_last   (s_axis_user_last       ),
    .s_axis_user_valid  (s_axis_user_valid      ),
    .s_axis_user_ready  (s_axis_user_ready      ),
    .m_axis_ip_data     (m_axis_ip_data         ),
    .m_axis_ip_user     (m_axis_ip_user         ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .m_axis_ip_keep     (m_axis_ip_keep         ),
    .m_axis_ip_last     (m_axis_ip_last         ),
    .m_axis_ip_valid    (m_axis_ip_valid        ),
    .m_axis_ip_ready    (m_axis_ip_ready        )
);

endmodule
