`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/21 10:38:41
// Design Name: 
// Module Name: IP_TX
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


module IP_TX#(
    parameter       P_SOURCE_IP = {8'd192,8'd168,8'd100,8'd100} ,
    parameter       P_TARGET_IP = {8'd192,8'd168,8'd100,8'd99 }
)(
    input           i_clk               ,
    input           i_rst               ,

    input  [31:0]   i_set_source_ip     ,
    input           i_set_source_valid  ,
    input  [31:0]   i_set_target_ip     ,
    input           i_set_target_valid  ,

    input  [63:0]   s_axis_out_data     ,
    input  [70:0]   s_axis_out_user     ,//16’dByteLen,1'bMF,16'dlen,1'bsplit,8'dtype,13'doffset,16'dID
    input  [7 :0]   s_axis_out_keep     ,
    input           s_axis_out_last     ,
    input           s_axis_out_valid    ,
    output          s_axis_out_ready    ,

    output [63:0]   m_axis_mac_data     ,
    output [79:0]   m_axis_mac_user     ,//16'dlen,48'dtarget_mac,16'dtype
    output [7 :0]   m_axis_mac_keep     ,
    output          m_axis_mac_last     ,
    output          m_axis_mac_valid    ,
    input           m_axis_mac_ready    ,

    output [31:0]   o_query_ip          ,
    output          o_query_valid       ,
    input  [47:0]   i_read_mac          ,
    input           i_read_valid            
);

reg  [63:0]         rs_axis_out_data    ;
reg  [70:0]         rs_axis_out_user    ;
reg  [7 :0]         rs_axis_out_keep    ;
reg                 rs_axis_out_last    ;
reg                 rs_axis_out_valid   ;
reg                 rs_axis_out_ready   ;
reg  [63:0]         rm_axis_mac_data    ;
reg  [79:0]         rm_axis_mac_user    ;
reg  [7 :0]         rm_axis_mac_keep    ;
reg                 rm_axis_mac_last    ;
reg                 rm_axis_mac_valid   ;
reg  [31:0]         ri_set_source_ip    ;   
reg  [31:0]         ri_set_target_ip    ;   
reg                 r_fifo_data_rden    ;
reg                 r_fifo_data_rden_1d ;
reg                 r_fifo_data_rden_2d ;
reg  [15:0]         r_in_cnt            ;
reg  [15:0]         r_cnt               ;
reg  [31:0]         r_header_check      ;
reg  [63:0]         r_fifo_data_dout    ;
reg  [7 :0]         r_last_keep         ;
reg  [31:0]         ro_query_ip         ;
reg                 ro_query_valid      ;
reg  [47:0]         ri_read_mac         ;
reg                 r_fifo_data_empty   ;

wire [63:0]         w_fifo_data_dout    ;
wire                w_fifo_data_full    ;
wire                w_fifo_data_empty   ;
wire                w_fifo_rden_neg_1d  ;
wire                w_fifo_rden_neg     ;
wire                w_fifo_rden_neg_1s  ;

assign s_axis_out_ready = rs_axis_out_ready;
assign m_axis_mac_data  = rm_axis_mac_data ;
assign m_axis_mac_user  = rm_axis_mac_user ;
assign m_axis_mac_keep  = rm_axis_mac_keep ;
assign m_axis_mac_last  = rm_axis_mac_last ;
assign m_axis_mac_valid = rm_axis_mac_valid;
assign w_fifo_rden_neg_1d = !r_fifo_data_rden_1d & r_fifo_data_rden_2d  ;
assign w_fifo_rden_neg    = !r_fifo_data_rden    & r_fifo_data_rden_1d  ;
assign w_fifo_rden_neg_1s = r_fifo_data_rden & w_fifo_data_empty & !r_fifo_data_empty;
assign o_query_ip         = ro_query_ip     ;
assign o_query_valid      = ro_query_valid  ;

FIFO_64X16 FIFO_64X16_U0 (
  .clk              (i_clk              ),
  .srst             (i_rst              ),
  .din              (rs_axis_out_data   ),
  .wr_en            (rs_axis_out_valid  ),
  .rd_en            (r_fifo_data_rden   ),
  .dout             (w_fifo_data_dout   ),
  .full             (w_fifo_data_full   ),
  .empty            (w_fifo_data_empty  ) 
);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_out_data  <= 'd0;
        rs_axis_out_user  <= 'd0;
        rs_axis_out_keep  <= 'd0;
        rs_axis_out_last  <= 'd0;
        rs_axis_out_valid <= 'd0;
        r_fifo_data_dout  <= 'd0;
        r_fifo_data_rden_1d <= 'd0;
        r_fifo_data_rden_2d <= 'd0;
        r_fifo_data_empty <= 'd0;
    end else begin
        rs_axis_out_data  <= s_axis_out_data ;
        rs_axis_out_user  <= s_axis_out_user ;
        rs_axis_out_keep  <= s_axis_out_keep ;
        rs_axis_out_last  <= s_axis_out_last ;
        rs_axis_out_valid <= s_axis_out_valid;
        r_fifo_data_dout  <= w_fifo_data_dout;
        r_fifo_data_rden_1d <= r_fifo_data_rden;
        r_fifo_data_rden_2d <= r_fifo_data_rden_1d;
        r_fifo_data_empty <= w_fifo_data_empty;
    end     
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_last_keep <= 'd0;
    else if(s_axis_out_last)
        r_last_keep <= s_axis_out_keep;
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
        ri_set_target_ip <= P_TARGET_IP;
    else if(i_set_target_valid)
        ri_set_target_ip <= i_set_target_ip;
    else 
        ri_set_target_ip <= ri_set_target_ip;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(w_fifo_rden_neg)
        r_cnt <= 'd0;
    else if((!w_fifo_data_empty && r_cnt == 0 && m_axis_mac_ready) || r_cnt)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_mac_data <= 'd0;
    else case(r_cnt)
        0           :rm_axis_mac_data <= {4'b0100,4'b0101,8'd0,(rs_axis_out_user[70:55] + 16'd20),
                        rs_axis_out_user[15:0],{rs_axis_out_user[54],~rs_axis_out_user[37],1'b0},rs_axis_out_user[28:16]};
        1           :rm_axis_mac_data <= {8'd128,rs_axis_out_user[36:29],~r_header_check[15:0],ri_set_source_ip};
        2           :rm_axis_mac_data <= {ri_set_target_ip,w_fifo_data_dout[63:32]};
        default     :rm_axis_mac_data <= {r_fifo_data_dout[31:0],w_fifo_data_dout[63:32]};
    endcase
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_in_cnt <= 'd0;
    else if(s_axis_out_valid)
        r_in_cnt <= r_in_cnt + 1;
    else 
        r_in_cnt <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_header_check <= 'd0;
    else if(r_in_cnt == 0)
        r_header_check <= 'd0;
    else if(r_in_cnt == 1)
        r_header_check <= 16'h4500 + (rs_axis_out_user[70:55] + 16'd20) + rs_axis_out_user[15:0] + 
        {{rs_axis_out_user[54],~rs_axis_out_user[37],1'b0},rs_axis_out_user[28:16]} + {8'd128,rs_axis_out_user[36:29]}+
        + ri_set_source_ip[31:16] + ri_set_source_ip[15:0] + ri_set_target_ip[31:16] + ri_set_target_ip[15:0];
    else if(r_in_cnt == 2)
        r_header_check <= r_header_check[31:16] + r_header_check[15:0];
    else if(r_in_cnt == 3)
        r_header_check <= r_header_check[31:16] + r_header_check[15:0];
    else 
        r_header_check <= r_header_check;

end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_data_rden <= 'd0;
    else if(w_fifo_data_empty)
        r_fifo_data_rden <= 'd0;
    else if((!w_fifo_data_empty && r_cnt == 0))
        r_fifo_data_rden <= 'd1;
    else 
        r_fifo_data_rden <= r_fifo_data_rden;
end
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_mac_user <= 'd0;
    else if(i_read_valid)
        rm_axis_mac_user <= {((rs_axis_out_user[70:55] + 16'd19) >> 3) + 1,i_read_mac,16'h0800};
    else 
        rm_axis_mac_user <= rm_axis_mac_user;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_mac_keep <= 'd0;
    else if(w_fifo_rden_neg && r_last_keep >= 8'b1111_1000)
        case(r_last_keep)
            8'b1111_1111:rm_axis_mac_keep <= 8'b1111_0000;
            8'b1111_1110:rm_axis_mac_keep <= 8'b1110_0000;
            8'b1111_1100:rm_axis_mac_keep <= 8'b1100_0000;
            8'b1111_1000:rm_axis_mac_keep <= 8'b1000_0000;
            8'b1111_0000:rm_axis_mac_keep <= 8'b1111_1111;//提前�?个周�?
            8'b1110_0000:rm_axis_mac_keep <= 8'b1111_1110;//提前�?个周�?
            8'b1100_0000:rm_axis_mac_keep <= 8'b1111_1100;//提前�?个周�?
            8'b1000_0000:rm_axis_mac_keep <= 8'b1111_1000;//提前�?个周�?
            default     :rm_axis_mac_keep <= 8'b1111_0000;
        endcase
    else if(w_fifo_rden_neg_1s && r_last_keep < 8'b1111_1000)
        case(r_last_keep)
            8'b1111_1111:rm_axis_mac_keep <= 8'b1111_0000;
            8'b1111_1110:rm_axis_mac_keep <= 8'b1110_0000;
            8'b1111_1100:rm_axis_mac_keep <= 8'b1100_0000;
            8'b1111_1000:rm_axis_mac_keep <= 8'b1000_0000;
            8'b1111_0000:rm_axis_mac_keep <= 8'b1111_1111;//提前�?个周�?
            8'b1110_0000:rm_axis_mac_keep <= 8'b1111_1110;//提前�?个周�?
            8'b1100_0000:rm_axis_mac_keep <= 8'b1111_1100;//提前�?个周�?
            8'b1000_0000:rm_axis_mac_keep <= 8'b1111_1000;//提前�?个周�?
            default     :rm_axis_mac_keep <= 8'b1111_0000;
        endcase
    else 
        rm_axis_mac_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_mac_last <= 'd0;
    else if(w_fifo_rden_neg && r_last_keep >= 8'b1111_1000)
        rm_axis_mac_last <= 'd1;
    else if(w_fifo_rden_neg_1s && r_last_keep < 8'b1111_1000)
        rm_axis_mac_last <= 'd1;
    else 
        rm_axis_mac_last <= 'd0;
end
 
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_mac_valid <= 'd0;
    else if(rm_axis_mac_last)
        rm_axis_mac_valid <= 'd0;
    else if(!w_fifo_data_empty && r_cnt == 0)
        rm_axis_mac_valid <= 'd1;
    else 
        rm_axis_mac_valid <= rm_axis_mac_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rs_axis_out_ready <= 'd1;
    else if(s_axis_out_last || !m_axis_mac_ready)
        rs_axis_out_ready <= 'd0;
    else if(rm_axis_mac_last || (!rm_axis_mac_valid && m_axis_mac_ready))
        rs_axis_out_ready <= 'd1;
    else 
        rs_axis_out_ready <= rs_axis_out_ready;
end
   
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_query_ip <= 'd0;
    else 
        ro_query_ip <= ri_set_target_ip;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_query_valid <= 'd0;
    else if(s_axis_out_valid && !rs_axis_out_valid)
        ro_query_valid <= 'd1;
    else    
        ro_query_valid <= 'd0;
end
   
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_read_mac <= 48'hff_ff_ff_ff_ff_ff;
    else if(i_read_valid)
        ri_read_mac <= i_read_mac;
    else 
        ri_read_mac <= ri_read_mac;
end


endmodule
