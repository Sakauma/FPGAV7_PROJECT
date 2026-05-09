`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/22 14:19:39
// Design Name: 
// Module Name: ARP_TX
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


module ARP_TX#(
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

    input  [47:0]   i_target_mac        ,
    input  [31:0]   i_target_ip         ,
    input           i_target_valid      ,

    output [63:0]   m_axis_data         ,
    output [79:0]   m_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]   m_axis_keep         ,
    output          m_axis_last         ,
    output          m_axis_valid        
);

reg  [47:0]         ri_set_source_mac   ; 
reg  [31:0]         ri_set_source_ip    ; 
reg  [47:0]         ri_target_mac       ;
reg  [31:0]         ri_target_ip        ;
reg                 ri_target_valid     ;
reg                 ri_arp_active       ;
reg  [15:0]         r_op                ;
reg  [15:0]         r_cnt               ;
reg  [63:0]         rm_axis_data        ;
reg  [79:0]         rm_axis_user        ;
reg  [7 :0]         rm_axis_keep        ;
reg                 rm_axis_last        ;
reg                 rm_axis_valid       ;

assign m_axis_data  = rm_axis_data      ;
assign m_axis_user  = rm_axis_user      ;
assign m_axis_keep  = rm_axis_keep      ;
assign m_axis_last  = rm_axis_last      ;
assign m_axis_valid = rm_axis_valid     ;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_target_mac   <= 'd0;
        ri_target_ip    <= 'd0;
        ri_target_valid <= 'd0;
    end else begin
        ri_target_mac   <= i_target_mac  ;
        ri_target_ip    <= i_target_ip   ;
        ri_target_valid <= i_target_valid;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_source_mac <= P_SOURCE_MAC;
    else if(i_set_smac_valid)
        ri_set_source_mac <= i_set_source_mac;
    else 
        ri_set_source_mac <= ri_set_source_mac;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_source_ip <= P_SOURCE_IP;
    else if(i_set_sip_valid)
        ri_set_source_ip <= i_set_source_ip;
    else 
        ri_set_source_ip <= ri_set_source_ip;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == 5)
        r_cnt <= 'd0;
    else if(ri_target_valid || ri_arp_active || r_cnt)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= r_cnt;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_arp_active <= 'd0;
    else 
        ri_arp_active <= i_arp_active;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_op <= 'd0;
    else if(ri_target_valid)
        r_op <= 'd2;
    else if(ri_arp_active)
        r_op <= 'd1;
    else 
        r_op <= r_op;
end         

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_data <= 'd0;
    else case(r_cnt)     
        0           :rm_axis_data <= ri_target_valid ? {16'd1,16'h0800,16'h0604,16'd2} : {16'd1,16'h0800,16'h0604,16'd1};
        1           :rm_axis_data <= {ri_set_source_mac,ri_set_source_ip[31:16]};
        2           :rm_axis_data <= r_op == 1 ? {ri_set_source_ip[15:0],48'h00_00_00_00_00_00} : {ri_set_source_ip[15:0],ri_target_mac};
        3           :rm_axis_data <= r_op == 1 ? {64'h00_00_00_00_00_00_00_00} : {ri_target_ip,32'h00_00_00_00};
        4           :rm_axis_data <= {64'h00_00_00_00_00_00_00_00};
        5           :rm_axis_data <= {64'h00_00_00_00_00_00_00_00};
        default     :rm_axis_data <= 'd0;
    endcase
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_keep <= 8'b1111_1111;
    else 
        rm_axis_keep <= 8'b1111_1111;
end

//16'dlen,48'dtarget_mac,16'dtype
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user <= 'd0;
    else 
        rm_axis_user <= {16'd8,48'hff_ff_ff_ff_ff_ff,16'h0806};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_last <= 'd0;
    else if(r_cnt == 5)
        rm_axis_last <= 'd1;
    else 
        rm_axis_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_valid <= 'd0;
    else if(rm_axis_last)   
        rm_axis_valid <= 'd0;
    else if(ri_target_valid || ri_arp_active)
        rm_axis_valid <= 'd1;
    else 
        rm_axis_valid <= rm_axis_valid;
end

endmodule
