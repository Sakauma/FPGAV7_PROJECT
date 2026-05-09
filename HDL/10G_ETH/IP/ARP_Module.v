`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/22 14:19:39
// Design Name: 
// Module Name: ARP_Module
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


module ARP_Module#(
    parameter       P_SOURCE_IP  = {8'd192,8'd168,8'd100,8'd100}    ,
    parameter       P_SOURCE_MAC = 48'h00_01_02_03_04_05            
)(
    input           i_clk               ,
    input           i_rst               ,
    
    input  [47:0]   i_set_source_mac    ,
    input           i_set_smac_valid    ,
    input  [31:0]   i_set_source_ip     ,
    input           i_set_sip_valid     ,  

    input           i_arp_active        ,
    
    /*-ARP_TX*/
    output [63:0]   m_axis_data         ,
    output [79:0]   m_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]   m_axis_keep         ,
    output          m_axis_last         ,
    output          m_axis_valid        ,
    
    /*-ARP_RX*/
    input  [63:0]   s_axis_data         ,
    input  [79:0]   s_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]   s_axis_keep         ,
    input           s_axis_last         ,
    input           s_axis_valid        ,

    /*-Query*/
    input  [31:0]   i_query_ip          ,
    input           i_query_valid       ,
    output [47:0]   o_read_mac          ,
    output          o_read_valid        
);

wire [47:0]         w_target_mac        ;  
wire [31:0]         w_target_ip         ;
wire                w_target_valid      ;
wire                w_replay_valid      ;

ARP_Table ARP_Table_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),
        
    .i_write_mac            (w_target_mac       ),
    .i_write_ip             (w_target_ip        ),
    .i_write_valid          (w_replay_valid     ),
        
    .i_query_ip             (i_query_ip         ),
    .i_query_valid          (i_query_valid      ),
    .o_read_mac             (o_read_mac         ),
    .o_read_valid           (o_read_valid       )
);

ARP_RX ARP_RX_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .s_axis_data            (s_axis_data        ),
    .s_axis_user            (s_axis_user        ),//16'dlen,48'dsource_mac,16'dtype
    .s_axis_keep            (s_axis_keep        ),
    .s_axis_last            (s_axis_last        ),
    .s_axis_valid           (s_axis_valid       ),

    .o_target_mac           (w_target_mac       ),
    .o_target_ip            (w_target_ip        ),
    .o_target_valid         (w_target_valid     ),
    .o_replay_valid         (w_replay_valid     )
);

ARP_TX#(
    .P_SOURCE_IP            (P_SOURCE_IP        ),
    .P_SOURCE_MAC           (P_SOURCE_MAC       ) 
)
ARP_TX_u0
(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_set_source_mac       (i_set_source_mac   ),
    .i_set_smac_valid       (i_set_smac_valid   ),
    .i_set_source_ip        (i_set_source_ip    ),
    .i_set_sip_valid        (i_set_sip_valid    ),  

    .i_arp_active           (i_arp_active       ),
    .i_target_mac           (w_target_mac       ),
    .i_target_ip            (w_target_ip        ),
    .i_target_valid         (w_target_valid     ),

    .m_axis_data            (m_axis_data        ),
    .m_axis_user            (m_axis_user        ),//16'dlen,48'dsource_mac,16'dtype
    .m_axis_keep            (m_axis_keep        ),
    .m_axis_last            (m_axis_last        ),
    .m_axis_valid           (m_axis_valid       )
);
endmodule
