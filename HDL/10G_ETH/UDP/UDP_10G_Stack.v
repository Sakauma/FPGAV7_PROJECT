`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/21 10:38:41
// Design Name: 
// Module Name: UDP_10G_Stack
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


module UDP_10G_Stack#(
    parameter       P_SOURCE_IP   = {8'd192,8'd168,8'd100,8'd100}   ,
    parameter       P_TARGET_IP   = {8'd192,8'd168,8'd100,8'd99 }   ,
    parameter       P_SOURCE_PORT = 16'd8080                        ,
    parameter       P_TARGET_PORT = 16'd8080                        ,
    parameter       P_SOURCE_MAC  = 48'h00_00_00_00_00_00           ,
    parameter       P_TARGET_MAC  = 48'h00_00_00_00_00_00   

)(
    input               i_clk                       ,
    input               i_rst                       ,

    input  [31:0]       i_set_source_ip             ,
    input               i_set_source_ip_valid       ,
    input  [31:0]       i_set_target_ip             ,
    input               i_set_target_ip_valid       ,
    input  [15:0]       i_set_source_port           ,
    input               i_set_source_port_valid     ,
    input  [15:0]       i_set_target_port           ,
    input               i_set_target_port_valid     ,
    input  [47:0]       i_set_source_mac            ,
    input               i_set_source_mac_valid      ,

    input               i_arp_active                ,

    /*----USER----*/
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
    output              m_axis_user_valid           ,

    /*----MAC----*/
    output [63:0]       m_axis_mac_data             ,
    output [79:0]       m_axis_mac_user             ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]       m_axis_mac_keep             ,
    output              m_axis_mac_last             ,
    output              m_axis_mac_valid            ,
    input  [63:0]       s_axis_mac_data             ,
    input  [79:0]       s_axis_mac_user             ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]       s_axis_mac_keep             ,
    input               s_axis_mac_last             ,
    input               s_axis_mac_valid            
);

wire [31:0]             w_query_ip                  ;            
wire                    w_query_valid               ;            
wire [47:0]             w_read_mac                  ;            
wire                    w_read_valid                ;            
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)(* DONT_TOUCH = "TRUE" *)wire [63:0]             wm_axis_ip2mac_data         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)(* DONT_TOUCH = "TRUE" *)wire [79:0]             wm_axis_ip2mac_user         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)(* DONT_TOUCH = "TRUE" *)wire [7 :0]             wm_axis_ip2mac_keep         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)(* DONT_TOUCH = "TRUE" *)wire                    wm_axis_ip2mac_last         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)(* DONT_TOUCH = "TRUE" *)wire                    wm_axis_ip2mac_valid        ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)(* DONT_TOUCH = "TRUE" *)wire                    wm_axis_ip2mac_ready        ;
wire [63:0]             wm_axis_arp2mac_data        ;
wire [79:0]             wm_axis_arp2mac_user        ;
wire [7 :0]             wm_axis_arp2mac_keep        ;
wire                    wm_axis_arp2mac_last        ;
wire                    wm_axis_arp2mac_valid       ;
wire [63:0]             wm_axis_ipout_data          ;
wire [54:0]             wm_axis_ipout_user          ;
wire [7 :0]             wm_axis_ipout_keep          ;
wire                    wm_axis_ipout_last          ;
wire                    wm_axis_ipout_valid         ;
wire [63:0]             ws_axis_ipout_data          ;
wire [70:0]             ws_axis_ipout_user          ;
wire [7 :0]             ws_axis_ipout_keep          ;
wire                    ws_axis_ipout_last          ;
wire                    ws_axis_ipout_valid         ;
wire                    ws_axis_ipout_ready         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)wire [63:0]             wm_axis_udp2ip_data         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)wire [70:0]             wm_axis_udp2ip_user         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)wire [7 :0]             wm_axis_udp2ip_keep         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)wire                    wm_axis_udp2ip_last         ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)wire                    wm_axis_udp2ip_valid        ;
(* MARK_DEBUG = "TRUE" *)(* KEEP = "TRUE" *)wire                    wm_axis_udp2ip_ready        ;
wire [63:0]             wm_axis_icmp2ip_data        ;
wire [70:0]             wm_axis_icmp2ip_user        ;
wire [7 :0]             wm_axis_icmp2ip_keep        ;
wire                    wm_axis_icmp2ip_last        ;
wire                    wm_axis_icmp2ip_valid       ;
wire                    wm_axis_icmp2ip_ready       ;

UDP_Module#(
    .P_SOURCE_PORT          (P_SOURCE_PORT              ),
    .P_TARGET_PORT          (P_TARGET_PORT              )
)
UDP_Module_u0
(
    .i_clk                  (i_clk                     ),
    .i_rst                  (i_rst                     ),
    .i_set_source_port      (i_set_source_port         ),
    .i_set_source_valid     (i_set_source_port_valid   ),
    .i_set_target_port      (i_set_target_port         ),
    .i_set_target_valid     (i_set_target_port_valid   ),

    .s_axis_ip_data         (wm_axis_ipout_data        ),
    .s_axis_ip_user         (wm_axis_ipout_user        ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .s_axis_ip_keep         (wm_axis_ipout_keep        ),
    .s_axis_ip_last         (wm_axis_ipout_last        ),
    .s_axis_ip_valid        (wm_axis_ipout_valid       ),
    .m_axis_ip_data         (wm_axis_udp2ip_data       ),
    .m_axis_ip_user         (wm_axis_udp2ip_user       ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .m_axis_ip_keep         (wm_axis_udp2ip_keep       ),
    .m_axis_ip_last         (wm_axis_udp2ip_last       ),
    .m_axis_ip_valid        (wm_axis_udp2ip_valid      ),
    .m_axis_ip_ready        (wm_axis_udp2ip_ready      ),

    .s_axis_user_data       (s_axis_user_data          ),
    .s_axis_user_user       (s_axis_user_user          ),
    .s_axis_user_keep       (s_axis_user_keep          ),
    .s_axis_user_last       (s_axis_user_last          ),
    .s_axis_user_valid      (s_axis_user_valid         ),
    .s_axis_user_ready      (s_axis_user_ready         ),
    .m_axis_user_data       (m_axis_user_data          ),
    .m_axis_user_user       (m_axis_user_user          ),
    .m_axis_user_keep       (m_axis_user_keep          ),
    .m_axis_user_last       (m_axis_user_last          ),
    .m_axis_user_valid      (m_axis_user_valid         )
);

ICMP_Module ICMP_Module_u0(
    .i_clk                  (i_clk                      ),
    .i_rst                  (i_rst                      ),

    .s_axis_ip_data         (wm_axis_ipout_data         ),
    .s_axis_ip_user         (wm_axis_ipout_user         ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .s_axis_ip_keep         (wm_axis_ipout_keep         ),
    .s_axis_ip_last         (wm_axis_ipout_last         ),
    .s_axis_ip_valid        (wm_axis_ipout_valid        ),
    .m_axis_ip_data         (wm_axis_icmp2ip_data       ),
    .m_axis_ip_user         (wm_axis_icmp2ip_user       ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .m_axis_ip_keep         (wm_axis_icmp2ip_keep       ),
    .m_axis_ip_last         (wm_axis_icmp2ip_last       ),
    .m_axis_ip_valid        (wm_axis_icmp2ip_valid      ),
    .m_axis_ip_ready        (wm_axis_icmp2ip_ready      )
);

Arbiter_2To1#(
    .P_ARBITER_TYPE         ("UDP"                      )   
)
Arbiter_2To1_u0
(
    .i_clk                  (i_clk                      ),
    .i_rst                  (i_rst                      ),

    .s_axis_c0_data         (wm_axis_icmp2ip_data       ),
    .s_axis_c0_user         ({10'd0,wm_axis_icmp2ip_user} ),
    .s_axis_c0_keep         (wm_axis_icmp2ip_keep       ),
    .s_axis_c0_last         (wm_axis_icmp2ip_last       ),
    .s_axis_c0_valid        (wm_axis_icmp2ip_valid      ),
    .s_axis_c0_ready        (wm_axis_icmp2ip_ready      ),

    .s_axis_c1_data         (wm_axis_udp2ip_data        ),
    .s_axis_c1_user         ({10'd0,wm_axis_udp2ip_user}  ),
    .s_axis_c1_keep         (wm_axis_udp2ip_keep        ),
    .s_axis_c1_last         (wm_axis_udp2ip_last        ),
    .s_axis_c1_valid        (wm_axis_udp2ip_valid       ),
    .s_axis_c1_ready        (wm_axis_udp2ip_ready       ),

    .m_axis_o0_data         (ws_axis_ipout_data         ),
    .m_axis_o0_user         (ws_axis_ipout_user         ),
    .m_axis_o0_keep         (ws_axis_ipout_keep         ),
    .m_axis_o0_last         (ws_axis_ipout_last         ),
    .m_axis_o0_valid        (ws_axis_ipout_valid        ),
    .m_axis_o0_ready        (1                          )
);

IP_Module#(
    .P_SOURCE_IP            (P_SOURCE_IP                ),
    .P_TARGET_IP            (P_TARGET_IP                )
)
IP_Module_u0
(
    .i_clk                  (i_clk                      ),
    .i_rst                  (i_rst                      ),
    
    .i_set_source_ip        (i_set_source_ip            ),
    .i_set_source_valid     (i_set_source_ip_valid      ),
    .i_set_target_ip        (i_set_target_ip            ),
    .i_set_target_valid     (i_set_target_ip_valid      ),
   
    .m_axis_mac_data        (wm_axis_ip2mac_data        ),
    .m_axis_mac_user        (wm_axis_ip2mac_user        ),//16'dlen,48'dsource_mac,16'dtype
    .m_axis_mac_keep        (wm_axis_ip2mac_keep        ),
    .m_axis_mac_last        (wm_axis_ip2mac_last        ),
    .m_axis_mac_valid       (wm_axis_ip2mac_valid       ),
    .m_axis_mac_ready       (wm_axis_ip2mac_ready       ),
    .s_axis_mac_data        (s_axis_mac_data            ),
    .s_axis_mac_user        (s_axis_mac_user            ),//16'dlen,48'dsource_mac,16'dtype
    .s_axis_mac_keep        (s_axis_mac_keep            ),
    .s_axis_mac_last        (s_axis_mac_last            ),
    .s_axis_mac_valid       (s_axis_mac_valid           ),

    .m_axis_out_data        (wm_axis_ipout_data         ),
    .m_axis_out_user        (wm_axis_ipout_user         ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .m_axis_out_keep        (wm_axis_ipout_keep         ),
    .m_axis_out_last        (wm_axis_ipout_last         ),
    .m_axis_out_valid       (wm_axis_ipout_valid        ),
    .s_axis_out_data        (ws_axis_ipout_data         ),
    .s_axis_out_user        (ws_axis_ipout_user         ),//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    .s_axis_out_keep        (ws_axis_ipout_keep         ),
    .s_axis_out_last        (ws_axis_ipout_last         ),
    .s_axis_out_valid       (ws_axis_ipout_valid        ),
    .s_axis_out_ready       (ws_axis_ipout_ready        ),
    .o_query_ip             (w_query_ip                 ),
    .o_query_valid          (w_query_valid              ),
    .i_read_mac             (w_read_mac                 ),
    .i_read_valid           (w_read_valid               )
);

ARP_Module#(
    .P_SOURCE_IP            (P_SOURCE_IP                ),
    .P_SOURCE_MAC           (P_SOURCE_MAC               )
)
ARP_Module_u0
(
    .i_clk                  (i_clk                      ),
    .i_rst                  (i_rst                      ),

    .i_set_source_mac       (i_set_source_mac           ),
    .i_set_smac_valid       (i_set_source_mac_valid     ),
    .i_set_source_ip        (i_set_source_ip            ),
    .i_set_sip_valid        (i_set_source_ip_valid      ),  
    .i_arp_active           (i_arp_active               ),

    .m_axis_data            (wm_axis_arp2mac_data       ),
    .m_axis_user            (wm_axis_arp2mac_user       ),//16'dlen,48'dsource_mac,16'dtype
    .m_axis_keep            (wm_axis_arp2mac_keep       ),
    .m_axis_last            (wm_axis_arp2mac_last       ),
    .m_axis_valid           (wm_axis_arp2mac_valid      ),
    .s_axis_data            (s_axis_mac_data            ),
    .s_axis_user            (s_axis_mac_user            ),//16'dlen,48'dsource_mac,16'dtype
    .s_axis_keep            (s_axis_mac_keep            ),
    .s_axis_last            (s_axis_mac_last            ),
    .s_axis_valid           (s_axis_mac_valid           ),

    .i_query_ip             (w_query_ip                 ),
    .i_query_valid          (w_query_valid              ),
    .o_read_mac             (w_read_mac                 ),
    .o_read_valid           (w_read_valid               )
);

Arbiter_2To1#(
    .P_ARBITER_TYPE         ("IP"                       )   
)
Arbiter_2To1_u1
(
    .i_clk                  (i_clk                      ),
    .i_rst                  (i_rst                      ),

    .s_axis_c0_data         (wm_axis_arp2mac_data       ),
    .s_axis_c0_user         (wm_axis_arp2mac_user       ),
    .s_axis_c0_keep         (wm_axis_arp2mac_keep       ),
    .s_axis_c0_last         (wm_axis_arp2mac_last       ),
    .s_axis_c0_valid        (wm_axis_arp2mac_valid      ),
    .s_axis_c0_ready        (),

    .s_axis_c1_data         (wm_axis_ip2mac_data        ),
    .s_axis_c1_user         (wm_axis_ip2mac_user        ),
    .s_axis_c1_keep         (wm_axis_ip2mac_keep        ),
    .s_axis_c1_last         (wm_axis_ip2mac_last        ),
    .s_axis_c1_valid        (wm_axis_ip2mac_valid       ),
    .s_axis_c1_ready        (wm_axis_ip2mac_ready       ),

    .m_axis_o0_data         (m_axis_mac_data            ),
    .m_axis_o0_user         (m_axis_mac_user            ),
    .m_axis_o0_keep         (m_axis_mac_keep            ),
    .m_axis_o0_last         (m_axis_mac_last            ),
    .m_axis_o0_valid        (m_axis_mac_valid           ),
    .m_axis_o0_ready        (1                          )
);
endmodule
