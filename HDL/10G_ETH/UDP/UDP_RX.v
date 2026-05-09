`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/24 14:03:07
// Design Name: 
// Module Name: UDP_RX
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


module UDP_RX#(
    parameter           P_SOURCE_PORT = 16'd8080    ,
    parameter           P_TARGET_PORT = 16'd8080    
)(
    input               i_clk                       ,
    input               i_rst                       ,

    input  [15:0]       i_set_source_port           ,
    input               i_set_source_valid          ,
    input  [15:0]       i_set_target_port           ,
    input               i_set_target_valid          ,

    input  [63:0]       s_axis_ip_data              ,
    input  [54:0]       s_axis_ip_user              ,//1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    input  [7 :0]       s_axis_ip_keep              ,
    input               s_axis_ip_last              ,
    input               s_axis_ip_valid             ,

    output [63:0]       m_axis_user_data            ,
    output [31:0]       m_axis_user_user            ,
    output [7 :0]       m_axis_user_keep            ,
    output              m_axis_user_last            ,
    output              m_axis_user_valid           
);

reg  [15:0]             ri_set_source_port          ;
reg  [15:0]             ri_set_target_port          ;
reg  [63:0]             rs_axis_ip_data             ;
reg  [54:0]             rs_axis_ip_user             ;
reg  [7 :0]             rs_axis_ip_keep             ;
reg                     rs_axis_ip_last             ;
reg                     rs_axis_ip_valid            ;
reg  [63:0]             rm_axis_user_data           ;
reg  [31:0]             rm_axis_user_user           ;
reg  [7 :0]             rm_axis_user_keep           ;
reg                     rm_axis_user_last           ;
reg                     rm_axis_user_valid          ;
reg  [15:0]             r_cnt                       ;
reg  [15:0]             r_source_port               ;
reg  [15:0]             r_target_port               ;
reg  [15:0]             r_len                       ;
reg  [7 :0]             r_last_keep                 ;   
reg                     r_udp_flag                  ;
reg                     r_port_check                ;

assign m_axis_user_data  = rm_axis_user_data        ;
assign m_axis_user_user  = rm_axis_user_user        ;
assign m_axis_user_keep  = rm_axis_user_keep        ;
assign m_axis_user_last  = rm_axis_user_last        ;
assign m_axis_user_valid = rm_axis_user_valid       ;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_ip_data  <= 'd0;
        rs_axis_ip_user  <= 'd0;
        rs_axis_ip_keep  <= 'd0;
        rs_axis_ip_last  <= 'd0;
        rs_axis_ip_valid <= 'd0;
    end else begin
        rs_axis_ip_data  <= s_axis_ip_data ;
        rs_axis_ip_user  <= s_axis_ip_user ;
        rs_axis_ip_keep  <= s_axis_ip_keep ;
        rs_axis_ip_last  <= s_axis_ip_last ;
        rs_axis_ip_valid <= s_axis_ip_valid;
    end    
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_source_port <= P_SOURCE_PORT;
    else if(i_set_source_valid)
        ri_set_source_port <= i_set_source_port;
    else 
        ri_set_source_port <= ri_set_source_port;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_target_port <= 'd0;
    else if(i_set_target_valid)
        ri_set_target_port <= i_set_target_port;
    else 
        ri_set_target_port <= ri_set_target_port;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_last_keep <= 'd0;
    else if(s_axis_ip_last)
        r_last_keep <= s_axis_ip_keep;
    else 
        r_last_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(rs_axis_ip_valid)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_source_port <= 'd0;
    else if(rs_axis_ip_valid && r_cnt == 0)
        r_source_port <= rs_axis_ip_data[63:48];
    else 
        r_source_port <= r_source_port;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_target_port <= 'd0;
    else if(rs_axis_ip_valid && r_cnt == 0)
        r_target_port <= rs_axis_ip_data[47:32];
    else 
        r_target_port <= r_target_port;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_port_check <= 'd0;
    else if(s_axis_ip_valid && !rs_axis_ip_valid &&  s_axis_ip_data[47:32] != ri_set_source_port)       
        r_port_check <= 'd0;
    else if(s_axis_ip_valid && !rs_axis_ip_valid &&  s_axis_ip_data[47:32] == ri_set_source_port)
        r_port_check <= 'd1;
    else 
        r_port_check <= r_port_check;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_len <= 'd0;
    else if(rs_axis_ip_valid && r_cnt == 0)
        r_len <= rs_axis_ip_data[31:16] - 16'd8;
    else 
        r_len <= r_len;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user_data <= 'd0;
    else
        rm_axis_user_data <= rs_axis_ip_data;
end
 
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user_user <= 'd0;
    else 
        rm_axis_user_user <= {r_len,((r_len - 16'd1) >> 16'd3) + 16'd1};
end 
 
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user_keep <= 'd0;
    else if(rs_axis_ip_last)
        rm_axis_user_keep <= r_last_keep;
    else 
        rm_axis_user_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        rm_axis_user_last <= 'd0;
    else if(rs_axis_ip_last && rm_axis_user_valid)
        rm_axis_user_last <= 'd1;
    else 
        rm_axis_user_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)  
        rm_axis_user_valid <= 'd0;
    else if(rm_axis_user_last)
        rm_axis_user_valid <= 'd0;
    else if(rs_axis_ip_valid && r_cnt == 1 && r_port_check && r_udp_flag)
        rm_axis_user_valid <= 'd1;
    else 
        rm_axis_user_valid <= rm_axis_user_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)  
        r_udp_flag <= 'd0;
    else if(s_axis_ip_valid && !rs_axis_ip_valid && s_axis_ip_user[36:29] != 17)
        r_udp_flag <= 'd0;
    else if(s_axis_ip_valid && !rs_axis_ip_valid && s_axis_ip_user[36:29] == 17)
        r_udp_flag <= 'd1;
    else 
        r_udp_flag <= r_udp_flag;
end

endmodule
