`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/23 14:56:53
// Design Name: 
// Module Name: Arbiter_2To1
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


module Arbiter_2To1#(
    parameter       P_ARBITER_TYPE = "IP"      
)(
    input           i_clk               ,
    input           i_rst               ,

    input  [63:0]   s_axis_c0_data      ,
    input  [79:0]   s_axis_c0_user      ,
    input  [7 :0]   s_axis_c0_keep      ,
    input           s_axis_c0_last      ,
    input           s_axis_c0_valid     ,
    output          s_axis_c0_ready     ,

    input  [63:0]   s_axis_c1_data      ,
    input  [79:0]   s_axis_c1_user      ,
    input  [7 :0]   s_axis_c1_keep      ,
    input           s_axis_c1_last      ,
    input           s_axis_c1_valid     ,
    output          s_axis_c1_ready     ,

    output [63:0]   m_axis_o0_data      ,
    output [79:0]   m_axis_o0_user      ,
    output [7 :0]   m_axis_o0_keep      ,
    output          m_axis_o0_last      ,
    output          m_axis_o0_valid     ,
    input           m_axis_o0_ready     
);

reg                 r_fifo_data_rden_1d     ;
reg                 rs_axis_c0_valid        ;
reg                 rs_axis_c1_valid        ;
reg                 r_fifo_c0_data_rden     ;
reg                 r_fifo_c0_keep_rden     ;
reg                 r_fifo_c0_user_rden     ;
reg                 r_fifo_c1_data_rden     ;
reg                 r_fifo_c1_keep_rden     ;
reg                 r_fifo_c1_user_rden     ;
reg                 r_arbiter               ;
reg                 r_arbiter_lock          ;
reg  [63:0]         rm_axis_o0_data         ;
reg  [79:0]         rm_axis_o0_user         ;
reg  [7 :0]         rm_axis_o0_keep         ;
reg                 rm_axis_o0_last         ;
reg                 rm_axis_o0_valid        ;
reg  [15:0]         r_cnt                   ;
reg                 rs_axis_c0_ready        ;
reg                 rs_axis_c1_ready        ;

(* MARK_DEBUG = "TRUE" *)wire [15:0]         w_len                   ;
wire [63:0]         w_fifo_c0_data_dout     ;
wire                w_fifo_c0_data_empty    ;
wire                w_fifo_c0_data_full     ;
wire [7 :0]         w_fifo_c0_keep_dout     ;
wire                w_fifo_c0_keep_empty    ;
wire                w_fifo_c0_keep_full     ;
wire [79:0]         w_fifo_c0_user_dout     ;
wire                w_fifo_c0_user_empty    ;
wire                w_fifo_c0_user_full     ;
wire [63:0]         w_fifo_c1_data_dout     ;
wire                w_fifo_c1_data_empty    ;
wire                w_fifo_c1_data_full     ;
wire [7 :0]         w_fifo_c1_keep_dout     ;
wire                w_fifo_c1_keep_empty    ;
wire                w_fifo_c1_keep_full     ;
wire [79:0]         w_fifo_c1_user_dout     ;
wire                w_fifo_c1_user_empty    ;
wire                w_fifo_c1_user_full     ;
wire                w_c0_valid_pos          ;
wire                w_c1_valid_pos          ;   

assign s_axis_c0_ready = rs_axis_c0_ready   ;
assign s_axis_c1_ready = rs_axis_c1_ready   ;
assign w_c0_valid_pos  = s_axis_c0_valid & !rs_axis_c0_valid   ;
assign w_c1_valid_pos  = s_axis_c1_valid & !rs_axis_c1_valid   ;
assign m_axis_o0_data  = rm_axis_o0_data    ;
assign m_axis_o0_user  = rm_axis_o0_user    ;
assign m_axis_o0_keep  = rm_axis_o0_keep    ;
assign m_axis_o0_last  = rm_axis_o0_last    ;
assign m_axis_o0_valid = rm_axis_o0_valid   ;
assign w_len           = P_ARBITER_TYPE == "IP" ?
                                r_arbiter ? w_fifo_c1_user_dout[79:64] : w_fifo_c0_user_dout[79:64] :
                                r_arbiter ? w_fifo_c1_user_dout[53:38] : w_fifo_c0_user_dout[53:38] ;
/*----c0----*/
FIFO_64X256 FIFO_64X256_u0 (
  .clk              (i_clk                  ),
  .srst             (i_rst                  ),
  .din              (s_axis_c0_data         ),
  .wr_en            (s_axis_c0_valid        ),
  .rd_en            (r_fifo_c0_data_rden    ),
  .dout             (w_fifo_c0_data_dout    ),
  .full             (w_fifo_c0_data_full    ),
  .empty            (w_fifo_c0_data_empty   ) 
);

FIFO_8X32 FIFO_8X32_u0 (
  .clk              (i_clk                  ), 
  .srst             (i_rst                  ), 
  .din              (s_axis_c0_keep         ), 
  .wr_en            (s_axis_c0_last         ), 
  .rd_en            (r_fifo_c0_keep_rden    ), 
  .dout             (w_fifo_c0_keep_dout    ), 
  .full             (w_fifo_c0_keep_full    ), 
  .empty            (w_fifo_c0_keep_empty   )  
);

FIFO_80X32 FIFO_80X32_u0 (
  .clk              (i_clk                  ), 
  .srst             (i_rst                  ), 
  .din              (s_axis_c0_user         ), 
  .wr_en            (w_c0_valid_pos         ), 
  .rd_en            (r_fifo_c0_user_rden    ), 
  .dout             (w_fifo_c0_user_dout    ), 
  .full             (w_fifo_c0_user_full    ), 
  .empty            (w_fifo_c0_user_empty   )  
);
/*----c1----*/
FIFO_64X256 FIFO_64X256_u1 (
  .clk              (i_clk                  ),
  .srst             (i_rst                  ),
  .din              (s_axis_c1_data         ),
  .wr_en            (s_axis_c1_valid        ),
  .rd_en            (r_fifo_c1_data_rden    ),
  .dout             (w_fifo_c1_data_dout    ),
  .full             (w_fifo_c1_data_full    ),
  .empty            (w_fifo_c1_data_empty   ) 
);

FIFO_8X32 FIFO_8X32_u1 (
  .clk              (i_clk                  ), 
  .srst             (i_rst                  ), 
  .din              (s_axis_c1_keep         ), 
  .wr_en            (s_axis_c1_last         ), 
  .rd_en            (r_fifo_c1_keep_rden    ), 
  .dout             (w_fifo_c1_keep_dout    ), 
  .full             (w_fifo_c1_keep_full    ), 
  .empty            (w_fifo_c1_keep_empty   )  
);

FIFO_80X32 FIFO_80X32_u1 (
  .clk              (i_clk                  ), 
  .srst             (i_rst                  ), 
  .din              (s_axis_c1_user         ), 
  .wr_en            (w_c1_valid_pos         ), 
  .rd_en            (r_fifo_c1_user_rden    ), 
  .dout             (w_fifo_c1_user_dout    ), 
  .full             (w_fifo_c1_user_full    ), 
  .empty            (w_fifo_c1_user_empty   )  
);


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_c0_valid <= 'd0;
        rs_axis_c1_valid <= 'd0;
    end else begin
        rs_axis_c0_valid <= s_axis_c0_valid;
        rs_axis_c1_valid <= s_axis_c1_valid;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_arbiter <= 'd0;
    else if(!r_arbiter_lock & !w_fifo_c0_data_empty)
        r_arbiter <= 'd0;
    else if(!r_arbiter_lock & !w_fifo_c1_data_empty)
        r_arbiter <= 'd1;
    else 
        r_arbiter <= r_arbiter;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_arbiter_lock <= 'd0;
    else if(r_cnt && r_cnt == w_len - 0)
        r_arbiter_lock <= 'd0;
    else if(!r_arbiter_lock && !r_arbiter && !w_fifo_c0_user_empty && m_axis_o0_ready && (!rm_axis_o0_valid || rm_axis_o0_last))
        r_arbiter_lock <= 'd1;
    else if(!r_arbiter_lock && r_arbiter && !w_fifo_c1_user_empty && w_fifo_c0_user_empty && m_axis_o0_ready && (!rm_axis_o0_valid || rm_axis_o0_last))
        r_arbiter_lock <= 'd1;
    else 
        r_arbiter_lock <= r_arbiter_lock;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_fifo_c0_user_rden <= 'd0;
    else if(r_fifo_c0_user_rden)
        r_fifo_c0_user_rden <= 'd0;
    else if(!r_arbiter_lock && !r_arbiter && !w_fifo_c0_user_empty && m_axis_o0_ready && (!rm_axis_o0_valid || rm_axis_o0_last))
        r_fifo_c0_user_rden <= 'd1;
    else 
        r_fifo_c0_user_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_fifo_c1_user_rden <= 'd0;
    else if(r_fifo_c1_user_rden)
        r_fifo_c1_user_rden <= 'd0;
    else if(!r_arbiter_lock && r_arbiter && !w_fifo_c1_user_empty && m_axis_o0_ready && w_fifo_c0_user_empty  && (!rm_axis_o0_valid || rm_axis_o0_last))
        r_fifo_c1_user_rden <= 'd1;
    else 
        r_fifo_c1_user_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)  
        r_fifo_c0_keep_rden <= 'd0;
    else if(r_arbiter == 0 && r_cnt == w_len - 2)
        r_fifo_c0_keep_rden <= 'd1;
    else
        r_fifo_c0_keep_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)  
        r_fifo_c1_keep_rden <= 'd0;
    else if(r_arbiter == 1 && r_cnt == w_len - 2)
        r_fifo_c1_keep_rden <= 'd1;
    else
        r_fifo_c1_keep_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_fifo_c0_data_rden <= 'd0;
    else if(r_cnt == w_len - 1)
        r_fifo_c0_data_rden <= 'd0;
    else if(r_fifo_c0_user_rden)
        r_fifo_c0_data_rden <= 'd1;
    else 
        r_fifo_c0_data_rden <= r_fifo_c0_data_rden; 
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_fifo_c1_data_rden <= 'd0;
    else if(r_cnt == w_len - 1)
        r_fifo_c1_data_rden <= 'd0;
    else if(r_fifo_c1_user_rden)
        r_fifo_c1_data_rden <= 'd1;
    else 
        r_fifo_c1_data_rden <= r_fifo_c1_data_rden; 
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_fifo_data_rden_1d <= 'd0;
    else            
        r_fifo_data_rden_1d <= r_fifo_c0_data_rden | r_fifo_c1_data_rden;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_cnt <= 'd0;
    else if(r_cnt && r_cnt == w_len - 0)
        r_cnt <= 'd0;
    else if(r_fifo_c0_data_rden)
        r_cnt <= r_cnt + 'd1;
    else if(r_fifo_c1_data_rden)
        r_cnt <= r_cnt + 'd1;
    else 
        r_cnt <= r_cnt;
end

/*----output----*/
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rm_axis_o0_data <= 'd0;
    else if(r_arbiter == 0)
        rm_axis_o0_data <= w_fifo_c0_data_dout;
    else 
        rm_axis_o0_data <= w_fifo_c1_data_dout;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rm_axis_o0_user <= 'd0;
    else if(r_arbiter == 0)
        rm_axis_o0_user <= w_fifo_c0_user_dout;
    else 
        rm_axis_o0_user <= w_fifo_c1_user_dout;
end
 
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rm_axis_o0_keep <= 'd0;
    else if(r_cnt == w_len - 0 && r_arbiter == 0)
        rm_axis_o0_keep <= w_fifo_c0_keep_dout;
    else if(r_cnt == w_len - 0 && r_arbiter == 1)
        rm_axis_o0_keep <= w_fifo_c1_keep_dout;
    else 
        rm_axis_o0_keep <= 8'b1111_1111;
end
 
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rm_axis_o0_last <= 'd0;
    else if(r_cnt && r_cnt == w_len - 0)
        rm_axis_o0_last <= 'd1;
    else 
        rm_axis_o0_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rm_axis_o0_valid <= 'd0;
    else if(rm_axis_o0_last)
        rm_axis_o0_valid <= 'd0;
    else if(r_fifo_data_rden_1d)
        rm_axis_o0_valid <= 'd1;
    else 
        rm_axis_o0_valid <= rm_axis_o0_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rs_axis_c0_ready <= 'd0;
    else 
        rs_axis_c0_ready <= 'd1;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        rs_axis_c1_ready <= 'd0;
    else if(!w_fifo_c0_data_empty)
        rs_axis_c1_ready <= 'd0;
    else
        rs_axis_c1_ready <= 'd1; 
end 

endmodule
