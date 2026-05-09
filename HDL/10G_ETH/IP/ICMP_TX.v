`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/23 10:45:36
// Design Name: 
// Module Name: ICMP_TX
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


module ICMP_TX(
    input           i_clk               ,
    input           i_rst               ,

    output [63:0]   m_axis_ip_data      ,
    output [70:0]   m_axis_ip_user      ,//16'dByteLen,1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    output [7 :0]   m_axis_ip_keep      ,
    output          m_axis_ip_last      ,
    output          m_axis_ip_valid     ,
    input           m_axis_ip_ready     ,

    input  [15:0]   i_Identifier        ,
    input  [15:0]   i_Sequence          ,
    input           i_trigger           
);

reg  [63:0]         rm_axis_ip_data     ;
reg  [70:0]         rm_axis_ip_user     ;
reg  [7 :0]         rm_axis_ip_keep     ;
reg                 rm_axis_ip_last     ;
reg                 rm_axis_ip_valid    ;
reg  [15:0]         r_cnt               ;
reg  [15:0]         ri_Identifier       ;
reg  [15:0]         ri_Sequence         ;
reg                 ri_trigger          ;
reg                 ri_trigger_1d       ;
reg  [31:0]         r_header_check      ;

assign m_axis_ip_data  = rm_axis_ip_data    ;
assign m_axis_ip_user  = rm_axis_ip_user    ;
assign m_axis_ip_keep  = rm_axis_ip_keep    ;
assign m_axis_ip_last  = rm_axis_ip_last    ;
assign m_axis_ip_valid = rm_axis_ip_valid   ;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_trigger    <= 'd0; 
    end else begin
        ri_trigger    <= i_trigger      ;
        ri_trigger_1d <= ri_trigger     ;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_Identifier <= 'd0;
    else if(i_trigger)   
        ri_Identifier <= i_Identifier   ;
    else 
        ri_Identifier <= ri_Identifier   ;
end
        
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_Sequence <= 'd0;
    else if(i_trigger)
        ri_Sequence   <= i_Sequence     ;
    else 
        ri_Sequence   <= ri_Sequence     ;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_header_check <= 'd0;
    else if(i_trigger)
        r_header_check <= i_Identifier + i_Sequence + 16'h6162 + 16'h6364 + 16'h6566 +16'h6768 + 16'h696a
            + 16'h6b6c + 16'h6d6e + 16'h6f70 + 16'h7172 + 16'h7374 + 16'h7576 + 16'h7761 + 16'h6263 + 16'h6465
            + 16'h6667 + 16'h6869;
    else if(ri_trigger)
        r_header_check <= r_header_check[31:16] + r_header_check[15:0];
    else 
        r_header_check <= r_header_check;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == 4)
        r_cnt <= 'd0;
    else if(ri_trigger_1d || r_cnt)
        r_cnt <= r_cnt + 'd1;
    else 
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_data <= 'd0;
    else case(r_cnt)
        0           :rm_axis_ip_data <= {16'h0000,~r_header_check[15:0],ri_Identifier,ri_Sequence};
        1           :rm_axis_ip_data <= {64'h6162636465666768};
        2           :rm_axis_ip_data <= {64'h696a6b6c6d6e6f70};
        3           :rm_axis_ip_data <= {64'h7172737475767761};
        4           :rm_axis_ip_data <= {64'h6263646566676869};
        default     :rm_axis_ip_data <= {64'h0000000000000000};
    endcase
end

//16'dByteLen,1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_user <= 'd0;
    else 
        rm_axis_ip_user <= {16'd40,1'b0,16'd5,1'b0,8'd1,13'd0,16'd1};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_keep <= 8'b1111_1111;
    else 
        rm_axis_ip_keep <= 8'b1111_1111;
end     

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_last <= 'd0;
    else if(r_cnt == 4)
        rm_axis_ip_last <= 'd1;
    else 
        rm_axis_ip_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_valid <= 'd0;
    else if(rm_axis_ip_last)
        rm_axis_ip_valid <= 'd0;
    else if(ri_trigger_1d)
        rm_axis_ip_valid <= 'd1;
    else 
        rm_axis_ip_valid <= rm_axis_ip_valid;
end


endmodule
