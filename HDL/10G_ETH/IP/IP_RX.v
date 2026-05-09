`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/21 10:38:41
// Design Name: 
// Module Name: IP_RX
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


module IP_RX#(
    parameter       P_SOURCE_IP = {8'd192,8'd168,8'd100,8'd100}
)(
    input           i_clk               ,
    input           i_rst               ,

    input  [31:0]   i_set_source_ip     ,
    input           i_set_source_valid  ,

    input  [63:0]   s_axis_mac_data     ,
    input  [79:0]   s_axis_mac_user     ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]   s_axis_mac_keep     ,
    input           s_axis_mac_last     ,
    input           s_axis_mac_valid    ,

    output [63:0]   m_axis_out_data     ,
    output [54:0]   m_axis_out_user     ,//16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    output [7 :0]   m_axis_out_keep     ,
    output          m_axis_out_last     ,
    output          m_axis_out_valid    
);

(* MARK_DEBUG = "TRUE" *)reg  [63:0]         rs_axis_mac_data    ;
(* MARK_DEBUG = "TRUE" *)reg  [79:0]         rs_axis_mac_user    ;
(* MARK_DEBUG = "TRUE" *)reg  [7 :0]         rs_axis_mac_keep    ;
(* MARK_DEBUG = "TRUE" *)reg                 rs_axis_mac_last    ;
(* MARK_DEBUG = "TRUE" *)reg                 rs_axis_mac_valid   ;
reg  [7 :0]         r_last_keep         ;
reg  [63:0]         rm_axis_out_data    ;
reg  [54:0]         rm_axis_out_user    ;
reg  [7 :0]         rm_axis_out_keep    ;
reg                 rm_axis_out_last    ;
reg                 rm_axis_out_valid   ;
(* MARK_DEBUG = "TRUE" *)reg  [15:0]         r_len               ;
(* MARK_DEBUG = "TRUE" *)reg  [15:0]         r_ID                ;
(* MARK_DEBUG = "TRUE" *)reg                 r_split             ;
(* MARK_DEBUG = "TRUE" *)reg  [12:0]         r_offset            ;
(* MARK_DEBUG = "TRUE" *)reg  [31:0]         r_source_ip         ;
(* MARK_DEBUG = "TRUE" *)reg  [31:0]         r_target_ip         ;
(* MARK_DEBUG = "TRUE" *)reg                 r_ip_check          ;
(* MARK_DEBUG = "TRUE" *)reg  [7 :0]         r_type              ;    
(* MARK_DEBUG = "TRUE" *)reg  [15:0]         r_cnt               ;
reg                 r_MF                ;
reg  [31:0]         ri_set_source_ip    ;
(* MARK_DEBUG = "TRUE" *)reg                 r_ip_flag           ;


assign m_axis_out_data  = rm_axis_out_data  ;
assign m_axis_out_user  = rm_axis_out_user  ;
assign m_axis_out_keep  = rm_axis_out_keep  ;
assign m_axis_out_last  = rm_axis_out_last  ;
assign m_axis_out_valid = rm_axis_out_valid ;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_mac_data  <= 'd0;
        rs_axis_mac_user  <= 'd0;
        rs_axis_mac_keep  <= 'd0;
        rs_axis_mac_last  <= 'd0;
        rs_axis_mac_valid <= 'd0;
    end else begin
        rs_axis_mac_data  <= s_axis_mac_data ;
        rs_axis_mac_user  <= s_axis_mac_user ;
        rs_axis_mac_keep  <= s_axis_mac_keep ;
        rs_axis_mac_last  <= s_axis_mac_last ;
        rs_axis_mac_valid <= s_axis_mac_valid;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_last_keep <= 'd0;
    else if(s_axis_mac_last)
        r_last_keep <= s_axis_mac_keep;
    else 
        r_last_keep <= r_last_keep;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_source_ip <= P_SOURCE_IP;
    else if(i_set_source_valid)
        ri_set_source_ip <= i_set_source_ip;
    else 
        ri_set_source_ip <= ri_set_source_ip;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(rs_axis_mac_valid)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_len <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 0)
        r_len <= rs_axis_mac_data[47:32] - 20;
    else 
        r_len <= r_len;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_ID <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 0)
        r_ID <= rs_axis_mac_data[31:16];
    else 
        r_ID <= r_ID;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_split <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 0)
        r_split <= ~rs_axis_mac_data[14];
    else 
        r_split <= r_split;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_MF <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 0)
        r_MF <= rs_axis_mac_data[15];
    else 
        r_MF <= r_MF;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_offset <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 0)
        r_offset <= rs_axis_mac_data[12:0];
    else 
        r_offset <= r_offset;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_type <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 1)
        r_type <= rs_axis_mac_data[55:48];
    else 
        r_type <= r_type;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_source_ip <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 1)
        r_source_ip <= rs_axis_mac_data[31: 0];
    else 
        r_source_ip <= r_source_ip;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_target_ip <= 'd0;
    else if(rs_axis_mac_valid && r_cnt == 2)
        r_target_ip <= rs_axis_mac_data[63:32];
    else 
        r_target_ip <= r_target_ip;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_ip_check <= 'd0;
    else if(r_cnt == 1 && s_axis_mac_data[63:32] != ri_set_source_ip)
        r_ip_check <= 'd0;
    else if(r_cnt == 1 && s_axis_mac_data[63:32] == ri_set_source_ip)
        r_ip_check <= 'd1;
    else 
        r_ip_check <= r_ip_check;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_out_data <= 'd0;
    else
        rm_axis_out_data <= {rs_axis_mac_data[31:0],s_axis_mac_data[63:32]};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_out_user <= 'd0;
    else
        rm_axis_out_user <= {r_MF,r_len,r_split,r_type,r_offset,r_ID};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_out_keep <= 'd0;
    else if(rs_axis_mac_last && r_last_keep >= 8'b1111_1000)
        case(r_last_keep)
            8'b1111_1111:rm_axis_out_keep <= 8'b1111_0000;
            8'b1111_1110:rm_axis_out_keep <= 8'b1110_0000;
            8'b1111_1100:rm_axis_out_keep <= 8'b1100_0000;
            8'b1111_1000:rm_axis_out_keep <= 8'b1000_0000;
            8'b1111_0000:rm_axis_out_keep <= 8'b1111_1111;//提前�?个周期结�?
            8'b1110_0000:rm_axis_out_keep <= 8'b1111_1110;//提前�?个周期结�?
            8'b1100_0000:rm_axis_out_keep <= 8'b1111_1100;//提前�?个周期结�?
            8'b1000_0000:rm_axis_out_keep <= 8'b1111_1000;//提前�?个周期结�?
            default     :rm_axis_out_keep <= 8'b1111_1111;
        endcase
    else if(s_axis_mac_last &&  s_axis_mac_keep <  8'b1111_1000)
        case(s_axis_mac_keep)
            8'b1111_1111:rm_axis_out_keep <= 8'b1111_0000;
            8'b1111_1110:rm_axis_out_keep <= 8'b1110_0000;
            8'b1111_1100:rm_axis_out_keep <= 8'b1100_0000;
            8'b1111_1000:rm_axis_out_keep <= 8'b1000_0000;
            8'b1111_0000:rm_axis_out_keep <= 8'b1111_1111;//提前�?个周期结�?
            8'b1110_0000:rm_axis_out_keep <= 8'b1111_1110;//提前�?个周期结�?
            8'b1100_0000:rm_axis_out_keep <= 8'b1111_1100;//提前�?个周期结�?
            8'b1000_0000:rm_axis_out_keep <= 8'b1111_1000;//提前�?个周期结�?
            default     :rm_axis_out_keep <= 8'b1111_1111;
        endcase
    else 
        rm_axis_out_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        rm_axis_out_last <= 'd0;
    else if(rs_axis_mac_last && r_last_keep >= 8'b1111_1000 && rm_axis_out_valid)
        rm_axis_out_last <= 'd1;
    else if(s_axis_mac_last  && s_axis_mac_keep <  8'b1111_1000 && rm_axis_out_valid)
        rm_axis_out_last <= 'd1;
    else    
        rm_axis_out_last <= 'd0;
end
 
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        rm_axis_out_valid <= 'd0;
    else if(rm_axis_out_last)
        rm_axis_out_valid <= 'd0;
    else if(r_cnt == 2 && r_ip_flag && r_ip_check)
        rm_axis_out_valid <= 'd1;
    else 
        rm_axis_out_valid <= rm_axis_out_valid;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_ip_flag <= 'd0;
    else if(s_axis_mac_valid && rs_axis_mac_valid && s_axis_mac_user[15:0] == 16'h0806)
        r_ip_flag <= 'd0;
    else if(s_axis_mac_valid && rs_axis_mac_valid && s_axis_mac_user[15:0] == 16'h0800)
        r_ip_flag <= 'd1;
    else 
        r_ip_flag <= r_ip_flag;
end

endmodule
