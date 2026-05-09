`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/24 14:03:07
// Design Name: 
// Module Name: UDP_TX
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


module UDP_TX#(
    parameter           P_SOURCE_PORT = 16'd8080    ,
    parameter           P_TARGET_PORT = 16'd8080    
)(
    input               i_clk                       ,
    input               i_rst                       ,

    input  [15:0]       i_set_source_port           ,
    input               i_set_source_valid          ,
    input  [15:0]       i_set_target_port           ,
    input               i_set_target_valid          ,

    input  [63:0]       s_axis_user_data            ,
    input  [31:0]       s_axis_user_user            ,//16'dByteLen,16'dBrust
    input  [7 :0]       s_axis_user_keep            ,
    input               s_axis_user_last            ,
    input               s_axis_user_valid           ,
    output              s_axis_user_ready           ,

    output [63:0]       m_axis_ip_data              ,
    output [70:0]       m_axis_ip_user              ,//16'dByteLen,1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    output [7 :0]       m_axis_ip_keep              ,
    output              m_axis_ip_last              ,
    output              m_axis_ip_valid             ,
    input               m_axis_ip_ready             
);

reg  [15:0]             ri_set_source_port          ;
reg  [15:0]             ri_set_target_port          ;
reg  [63:0]             rs_axis_user_data           ;
reg  [31:0]             rs_axis_user_user           ;
reg  [7 :0]             rs_axis_user_keep           ;
reg                     rs_axis_user_last           ;
reg                     rs_axis_user_valid          ;
reg                     rs_axis_user_ready          ;
reg  [63:0]             rm_axis_ip_data             ;
reg  [70:0]             rm_axis_ip_user             ;
reg  [7 :0]             rm_axis_ip_keep             ;
reg                     rm_axis_ip_last             ;
reg                     rm_axis_ip_valid            ;
reg                     r_fifo_data_rden            ;
reg  [15:0]             r_cnt                       ;
reg  [7 :0]             r_last_keep                 ;
reg                     r_fifo_data_empty           ;
reg                     r_fifo_data_empty_1d        ;

wire [63:0]             w_fifo_data_dout            ;
wire                    w_fifo_data_full            ;
wire                    w_fifo_data_empty           ;

assign s_axis_user_ready = rs_axis_user_ready       ;
assign m_axis_ip_data  = rm_axis_ip_data            ;
assign m_axis_ip_user  = rm_axis_ip_user            ;
assign m_axis_ip_keep  = rm_axis_ip_keep            ;
assign m_axis_ip_last  = rm_axis_ip_last            ;
assign m_axis_ip_valid = rm_axis_ip_valid           ;

FIFO_64X16 FIFO_64X16_u0 (
  .clk                  (i_clk                      ), 
  .srst                 (i_rst                      ),
  .din                  (rs_axis_user_data          ), 
  .wr_en                (rs_axis_user_valid         ),
  .rd_en                (r_fifo_data_rden           ),
  .dout                 (w_fifo_data_dout           ),
  .full                 (w_fifo_data_full           ),
  .empty                (w_fifo_data_empty          )
);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_fifo_data_empty <= 'd0;
        r_fifo_data_empty_1d <= 'd0;
    end else begin
        r_fifo_data_empty <= w_fifo_data_empty;
        r_fifo_data_empty_1d <= r_fifo_data_empty;
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
        ri_set_target_port <= P_TARGET_PORT;
    else if(i_set_target_valid)
        ri_set_target_port <= i_set_target_port;
    else 
        ri_set_target_port <= ri_set_target_port;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_user_data  <= 'd0;
        rs_axis_user_keep  <= 'd0;
        rs_axis_user_last  <= 'd0;
        rs_axis_user_valid <= 'd0;
    end else begin
        rs_axis_user_data  <= s_axis_user_data ;
        rs_axis_user_keep  <= s_axis_user_keep ;
        rs_axis_user_last  <= s_axis_user_last ;
        rs_axis_user_valid <= s_axis_user_valid;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rs_axis_user_user <= 'd0;
    else if(s_axis_user_valid)
        rs_axis_user_user  <= s_axis_user_user ;
    else 
        rs_axis_user_user <= rs_axis_user_user;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rs_axis_user_ready <= 'd1;
    else if(s_axis_user_last)
        rs_axis_user_ready <= 'd0;
    else if(r_fifo_data_empty_1d)
        rs_axis_user_ready <= 'd1;
    else 
        rs_axis_user_ready <= rs_axis_user_ready;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_last_keep <= 'd0;
    else if(s_axis_user_last)
        r_last_keep <= s_axis_user_keep;
    else 
        r_last_keep <= r_last_keep;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == rs_axis_user_user[15:0])
        r_cnt <= 'd0;
    else if(r_fifo_data_rden || r_cnt)
        r_cnt <= r_cnt + + 1;
    else 
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_data_rden <= 'd0;
    else if(r_cnt == rs_axis_user_user[15:0] - 1)
        r_fifo_data_rden <= 'd0;
    else if(!w_fifo_data_empty)
        r_fifo_data_rden <= 'd1;
    else         
        r_fifo_data_rden <= r_fifo_data_rden;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_data <= 'd0;
    else case(r_cnt)
        0           :rm_axis_ip_data <= {ri_set_source_port,ri_set_target_port,rs_axis_user_user[31:16] + 16'd8,16'd0};
        default     :rm_axis_ip_data <= w_fifo_data_dout;
    endcase
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_keep <= 'd0;
    else if(r_cnt && r_cnt == rs_axis_user_user[15:0] - 0)
        rm_axis_ip_keep <= r_last_keep;
    else 
        rm_axis_ip_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_last <= 'd0;
    else if(r_cnt && r_cnt == rs_axis_user_user[15:0] - 0)
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
    else if(r_fifo_data_rden)
        rm_axis_ip_valid <= 'd1;
    else        
        rm_axis_ip_valid <= rm_axis_ip_valid;
end

//16'dByteLen,1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_ip_user <= 'd0;
    else 
        rm_axis_ip_user <= {rs_axis_user_user[31:16] + 16'd8,1'b0,rs_axis_user_user[15:0] + 16'd1,1'b0,8'd17,13'd0,16'd0};
end

endmodule
