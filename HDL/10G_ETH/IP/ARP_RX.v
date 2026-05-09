`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/22 14:19:39
// Design Name: 
// Module Name: ARP_RX
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


module ARP_RX(
    input           i_clk               ,
    input           i_rst               ,

    input  [63:0]   s_axis_data         ,
    input  [79:0]   s_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]   s_axis_keep         ,
    input           s_axis_last         ,
    input           s_axis_valid        ,

    output [47:0]   o_target_mac        ,
    output [31:0]   o_target_ip         ,
    output          o_target_valid      ,
    output          o_replay_valid      
);

reg  [63:0]         rs_axis_data        ;
reg  [79:0]         rs_axis_user        ;
reg  [7 :0]         rs_axis_keep        ;
reg                 rs_axis_last        ;
reg                 rs_axis_valid       ;
reg                 r_arp               ;
reg  [15:0]         r_op                ;
reg  [47:0]         r_target_mac        ;
reg  [31:0]         r_target_ip         ;
reg  [15:0]         r_cnt               ;
reg                 ro_target_valid     ;
reg                 ro_replay_valid     ;

assign o_replay_valid = ro_replay_valid ;
assign o_target_valid = ro_target_valid ;
assign o_target_mac   = r_target_mac    ;
assign o_target_ip    = r_target_ip     ; 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_data  <= 'd0;
        rs_axis_user  <= 'd0;
        rs_axis_keep  <= 'd0;
        rs_axis_last  <= 'd0;
        rs_axis_valid <= 'd0;
    end else begin
        rs_axis_data  <= s_axis_data ;
        rs_axis_user  <= s_axis_user ;
        rs_axis_keep  <= s_axis_keep ;
        rs_axis_last  <= s_axis_last ;
        rs_axis_valid <= s_axis_valid;
    end 
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_arp <= 'd0;
    else if(s_axis_valid && !rs_axis_valid && s_axis_user[15:0] == 16'h0806)
        r_arp <= 'd1;
    else if(s_axis_valid && !rs_axis_valid && s_axis_user[15:0] != 16'h0806)
        r_arp <= 'd0;
    else
        r_arp <= r_arp;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(rs_axis_valid)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_op <= 'd0;
    else if(rs_axis_valid && r_cnt == 0)
        r_op <= rs_axis_data[15:0];
    else 
        r_op <= r_op;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_target_mac <= 'd0;
    else if(rs_axis_valid && r_cnt == 1)
        r_target_mac <= rs_axis_data[63:16];
    else 
        r_target_mac <= r_target_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_target_ip <= 'd0;
    else if(rs_axis_valid && r_cnt == 1)
        r_target_ip <= {rs_axis_data[15:0],s_axis_data[63:48]};
    else 
        r_target_ip <= r_target_ip;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_target_valid <= 'd0;
    else if(r_op == 1 && rs_axis_valid && r_cnt == 1 && r_arp == 1)
        ro_target_valid <= 'd1;
    else 
        ro_target_valid <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_replay_valid <= 'd0;
    else if(rs_axis_valid && r_cnt == 1 && r_arp == 1)
        ro_replay_valid <= 'd1;
    else 
        ro_replay_valid <= 'd0;
end
endmodule
