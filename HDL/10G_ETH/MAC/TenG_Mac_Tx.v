`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/06 11:06:44
// Design Name: 
// Module Name: TenG_Mac_Tx
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


module TenG_Mac_Tx#(
    parameter       P_SOURCE_MAC  = 48'h00_00_00_00_00_00   ,
    parameter       P_TARGET_MAC  = 48'h00_00_00_00_00_00   
)(
    input           i_clk               ,
    input           i_rst               ,

    input  [47:0]   i_set_source_mac    ,
    input           i_set_source_valid  ,
    input  [47:0]   i_set_target_mac    ,
    input           i_set_target_valid  ,

    input  [63:0]   s_axis_data         ,
    input  [79:0]   s_axis_user         ,
    input  [7 :0]   s_axis_keep         ,
    input           s_axis_last         ,
    input           s_axis_valid        ,

    output [63:0]   o_xgmii_txd         ,
    output [7 :0]   o_xgmii_txc         
);

reg  [47:0]         ri_set_source_mac   ;
reg  [47:0]         ri_set_target_mac   ;
reg  [63:0]         rs_axis_data        ;
reg  [79:0]         rs_axis_user        ;
reg  [7 :0]         rs_axis_keep        ;
reg                 rs_axis_last        ;
reg                 rs_axis_valid       ;
reg  [63:0]         ro_xgmii_txd        ;
reg  [7 :0]         ro_xgmii_txc        ;
reg  [63:0]         r_xgmii_txd         ;
reg  [63:0]         r_xgmii_txd_1d      ;
reg                 r_fifo_data_rden    ;
reg                 r_fifo_len_rden     ;
reg                 r_fifo_len_rden_1d  ;
reg                 r_fifo_type_rden    ;
reg                 r_fifo_keep_rden    ;
reg                 r_fifo_len_lock     ;
reg  [15:0]         r_cnt               ;
reg  [63:0]         r_fifo_data_dout    ;
reg                 r_crc_en            ;
reg  [63:0]         r_crc_data          ;
reg  [15:0]         r_crc_cnt           ;
reg                 r_sof               ;
reg                 r_sof_1d            ;
reg                 r_sof_2d            ;
reg                 r_eof               ;
reg                 r_eof_1d            ;
reg                 r_eof_2d            ;
reg                 r_eof_3d            ;
reg  [31:0]         r_crc               ;
reg  [31:0]         r_crc_1             ;
reg  [31:0]         r_crc_2             ;
reg  [31:0]         r_crc_3             ;
reg  [31:0]         r_crc_4             ;
reg  [31:0]         r_crc_5             ;
reg  [31:0]         r_crc_6             ;
reg  [31:0]         r_crc_7             ;

wire [63:0]         w_fifo_data_dout    ;
wire [15:0]         w_fifo_len_dout     ;
wire [15:0]         w_fifo_type_dout    ;
wire [7 :0]         w_fifo_keep_dout    ;
wire                w_fifo_data_full    ;
wire                w_fifo_data_empty   ;
wire                w_fifo_len_full     ;
wire                w_fifo_len_empty    ;
wire                w_fifo_type_full    ;
wire                w_fifo_type_empty   ;
wire                w_fifo_keep_full    ;
wire                w_fifo_keep_empty   ;
wire                w_sof               ;
wire                w_eof               ;
wire                w_eof_s2            ;
wire [31:0]         w_crc_z             ;
wire [31:0]         w_crc_z_1           ;
wire [31:0]         w_crc_z_2           ;
wire [31:0]         w_crc_z_3           ;
wire [31:0]         w_crc_z_4           ;
wire [31:0]         w_crc_z_5           ;
wire [31:0]         w_crc_z_6           ;
wire [31:0]         w_crc_z_7           ;
wire [31:0]         w_crc               ;
wire [31:0]         w_crc_1             ;
wire [31:0]         w_crc_2             ;
wire [31:0]         w_crc_3             ;
wire [31:0]         w_crc_4             ;
wire [31:0]         w_crc_5             ;
wire [31:0]         w_crc_6             ;
wire [31:0]         w_crc_7             ;

assign o_xgmii_txd = ro_xgmii_txd       ;
assign o_xgmii_txc = ro_xgmii_txc       ;
assign w_sof       = (!w_fifo_len_empty && !r_fifo_len_rden && !r_fifo_len_lock);
assign w_eof       = r_cnt > 2 && r_cnt == w_fifo_len_dout + 2;
assign w_eof_s2    = r_cnt > 2 && r_cnt == w_fifo_len_dout + 0;
assign w_crc       = {w_crc_z[7 :0],w_crc_z[15:8],w_crc_z[23:16],w_crc_z[31:24]};
assign w_crc_1     = {w_crc_z_1[7 :0],w_crc_z_1[15:8],w_crc_z_1[23:16],w_crc_z_1[31:24]};
assign w_crc_2     = {w_crc_z_2[7 :0],w_crc_z_2[15:8],w_crc_z_2[23:16],w_crc_z_2[31:24]};
assign w_crc_3     = {w_crc_z_3[7 :0],w_crc_z_3[15:8],w_crc_z_3[23:16],w_crc_z_3[31:24]};
assign w_crc_4     = {w_crc_z_4[7 :0],w_crc_z_4[15:8],w_crc_z_4[23:16],w_crc_z_4[31:24]};
assign w_crc_5     = {w_crc_z_5[7 :0],w_crc_z_5[15:8],w_crc_z_5[23:16],w_crc_z_5[31:24]};
assign w_crc_6     = {w_crc_z_6[7 :0],w_crc_z_6[15:8],w_crc_z_6[23:16],w_crc_z_6[31:24]};
assign w_crc_7     = {w_crc_z_7[7 :0],w_crc_z_7[15:8],w_crc_z_7[23:16],w_crc_z_7[31:24]};

FIFO_64X256 FIFO_64X256_U0 (
  .clk              (i_clk                  ), 
  .srst             (i_rst                  ),
  .din              (rs_axis_data           ), 
  .wr_en            (rs_axis_valid          ), 
  .rd_en            (r_fifo_data_rden       ),
  .dout             (w_fifo_data_dout       ),
  .full             (w_fifo_data_full       ),
  .empty            (w_fifo_data_empty      ) 
);

FIFO_16X32 FIFO_16X32_u0 (
  .clk              (i_clk                  ),
  .srst             (i_rst                  ),
  .din              (rs_axis_user[79:64]    ),
  .wr_en            (rs_axis_last           ),
  .rd_en            (r_fifo_len_rden        ), 
  .dout             (w_fifo_len_dout        ), 
  .full             (w_fifo_len_full        ), 
  .empty            (w_fifo_len_empty       )  
);

FIFO_16X32 FIFO_16X32_u1 (
  .clk              (i_clk                  ),
  .srst             (i_rst                  ),
  .din              (rs_axis_user[15: 0]    ),
  .wr_en            (rs_axis_last           ),
  .rd_en            (r_fifo_type_rden       ),
  .dout             (w_fifo_type_dout       ),
  .full             (w_fifo_type_full       ),
  .empty            (w_fifo_type_empty      ) 
);

FIFO_8X32 FIFO_64X256_U2 (
  .clk              (i_clk                  ),
  .srst             (i_rst                  ),
  .din              (rs_axis_keep           ),
  .wr_en            (rs_axis_last           ),
  .rd_en            (r_fifo_keep_rden       ), 
  .dout             (w_fifo_keep_dout       ), 
  .full             (w_fifo_keep_full       ), 
  .empty            (w_fifo_keep_empty      )  
);

CRC32_64bKEEP CRC32_64bKEEP_u0(
  .i_clk            (i_clk              ),
  .i_rst            (i_rst              ),
  .i_en             (r_crc_en           ),
  .i_data           (r_crc_data[63:56]  ),
  .i_data_1         (r_crc_data[55:48]  ),
  .i_data_2         (r_crc_data[47:40]  ),
  .i_data_3         (r_crc_data[39:32]  ),
  .i_data_4         (r_crc_data[31:24]  ),
  .i_data_5         (r_crc_data[23:16]  ),
  .i_data_6         (r_crc_data[15: 8]  ),
  .i_data_7         (r_crc_data[7 : 0]  ),
  .o_crc            (w_crc_z            ),
  .o_crc_1          (w_crc_z_1          ),
  .o_crc_2          (w_crc_z_2          ),
  .o_crc_3          (w_crc_z_3          ),
  .o_crc_4          (w_crc_z_4          ),
  .o_crc_5          (w_crc_z_5          ),
  .o_crc_6          (w_crc_z_6          ),
  .o_crc_7          (w_crc_z_7          )
);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_source_mac <= P_SOURCE_MAC;
    else if(i_set_source_valid)
        ri_set_source_mac <= i_set_source_mac;
    else 
        ri_set_source_mac <= ri_set_source_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_target_mac <= P_TARGET_MAC;
    else if(i_set_target_valid)
        ri_set_target_mac <= i_set_target_mac;
    else if(s_axis_valid && !rs_axis_valid)
        ri_set_target_mac <= s_axis_user[63:16];
    else 
        ri_set_target_mac <= ri_set_target_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_data  <= 'd0;
        rs_axis_user  <= 'd0;
        rs_axis_keep  <= 'd0;
        rs_axis_last  <= 'd0;
        rs_axis_valid <= 'd0;
        r_fifo_len_rden_1d <= 'd0;
        r_fifo_data_dout   <= 'd0;
        r_sof         <= 'd0;
        r_eof         <= 'd0;
        r_eof_1d      <= 'd0;
        r_crc         <= 'd0;
        r_crc_1       <= 'd0;
        r_crc_2       <= 'd0;
        r_crc_3       <= 'd0;
        r_crc_4       <= 'd0;
        r_crc_5       <= 'd0;
        r_crc_6       <= 'd0;
        r_crc_7       <= 'd0;
        r_sof_1d <= 'd0;
        r_sof_2d <= 'd0;
        r_eof_2d <= 'd0;
        r_eof_3d <= 'd0;
        r_xgmii_txd_1d <= 'd0;
    end else begin
        rs_axis_data  <= s_axis_data ;
        rs_axis_user  <= s_axis_user ;
        rs_axis_keep  <= s_axis_keep ;
        rs_axis_last  <= s_axis_last ;
        rs_axis_valid <= s_axis_valid;
        r_fifo_len_rden_1d <= r_fifo_len_rden;
        r_fifo_data_dout   <= w_fifo_data_dout;
        r_sof         <= w_sof;
        r_eof         <= w_eof;
        r_eof_1d      <= r_eof;
        r_crc         <= w_crc  ;
        r_crc_1       <= w_crc_1;
        r_crc_2       <= w_crc_2;
        r_crc_3       <= w_crc_3;
        r_crc_4       <= w_crc_4;
        r_crc_5       <= w_crc_5;
        r_crc_6       <= w_crc_6;
        r_crc_7       <= w_crc_7;
        r_sof_1d <= r_sof;
        r_eof_2d <= r_eof_1d;
        r_xgmii_txd_1d <= r_xgmii_txd;
        r_eof_3d <= r_eof_2d;
        r_sof_2d <= r_sof_1d;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_len_rden <= 'd0;
    else if(!w_fifo_len_empty && !r_fifo_len_rden && !r_fifo_len_lock)
        r_fifo_len_rden <= 'd1;
    else 
        r_fifo_len_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_len_lock <= 'd0;
    else if(r_eof)
        r_fifo_len_lock <= 'd0;
    else if(!w_fifo_len_empty && !r_fifo_len_rden && !r_fifo_len_lock)
        r_fifo_len_lock <= 'd1;
    else 
        r_fifo_len_lock <= r_fifo_len_lock;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_fifo_type_rden <= 'd0;
        r_fifo_keep_rden <= 'd0;
    end else if(!w_fifo_len_empty && !r_fifo_len_rden && !r_fifo_len_lock) begin
        r_fifo_type_rden <= 'd1;
        r_fifo_keep_rden <= 'd1;
    end else begin
        r_fifo_type_rden <= 'd0;
        r_fifo_keep_rden <= 'd0;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(w_eof)
        r_cnt <= 'd0;
    else if(w_sof || r_cnt)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_data_rden <= 'd0;
    else if(w_eof_s2)
        r_fifo_data_rden <= 'd0;
    else if(w_sof)
        r_fifo_data_rden <= 'd1;
    else    
        r_fifo_data_rden <= r_fifo_data_rden;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_cnt <= 'd0;
    else if(r_crc_cnt == w_fifo_len_dout + 2)
        r_crc_cnt <= 'd0;
    else if(r_sof || r_crc_cnt)
        r_crc_cnt <= r_crc_cnt + 1;
    else 
        r_crc_cnt <= r_crc_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_en <= 'd0;
    else if(( w_fifo_keep_dout  == 8'b1100_0000 || w_fifo_keep_dout  == 8'b1000_0000) &&r_crc_cnt == w_fifo_len_dout + 1)
        r_crc_en <= 'd0;
    else if(r_crc_cnt == w_fifo_len_dout + 2)
        r_crc_en <= 'd0;
    else if(r_sof)
        r_crc_en <= 'd1;
    else 
        r_crc_en <= r_crc_en;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_data <= 'd0;
    else case(r_crc_cnt)
        0           :r_crc_data <= {ri_set_target_mac,ri_set_source_mac[47:32]};
        1           :r_crc_data <= {ri_set_source_mac[31:0],w_fifo_type_dout,w_fifo_data_dout[63:48]};
        default     :r_crc_data <= {r_fifo_data_dout[47: 0],w_fifo_data_dout[63:48]};
    endcase
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_xgmii_txd <= 'd0;
    else if(w_sof || r_cnt)
        case(r_cnt)
            0           :r_xgmii_txd <= 64'hFB555555_55555555;
            1           :r_xgmii_txd <= {8'hD5,ri_set_target_mac,ri_set_source_mac[47:40]};
            2           :r_xgmii_txd <= {ri_set_source_mac[39:0],w_fifo_type_dout,w_fifo_data_dout[63:56]};
            default     :r_xgmii_txd <= {r_fifo_data_dout[55:0],w_fifo_data_dout[63:56]};
        endcase
    else 
        r_xgmii_txd <= 64'h07070707_07070707;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_xgmii_txd <= 'd0;
    else if(r_eof_2d)
        case(w_fifo_keep_dout)
            8'b1111_1111:ro_xgmii_txd <= {r_crc_6[23:0],8'hFD,32'h07070707};
            8'b1111_1110:ro_xgmii_txd <= {r_crc_5[15:0],8'hFD,40'h07070707_07};
            8'b1111_1100:ro_xgmii_txd <= {r_crc_4[7 :0],8'hFD,48'h07070707_0707};
            8'b1111_1000:ro_xgmii_txd <= {8'hFD,56'h07070707_070707};
            default     :ro_xgmii_txd <= 64'h07070707_07070707;
        endcase
    else if(r_eof_1d)
        case(w_fifo_keep_dout)
            8'b1111_1111:ro_xgmii_txd <= {r_xgmii_txd_1d[63:8],w_crc_6[31:24]};
            8'b1111_1110:ro_xgmii_txd <= {r_xgmii_txd_1d[63:16],w_crc_5[31:16]};
            8'b1111_1100:ro_xgmii_txd <= {r_xgmii_txd_1d[63:24],w_crc_4[31:8]};
            8'b1111_1000:ro_xgmii_txd <= {r_xgmii_txd_1d[63:32],w_crc_3[31:0]};
            8'b1111_0000:ro_xgmii_txd <= {r_xgmii_txd_1d[63:40],w_crc_2[31:0],8'hFD};
            8'b1110_0000:ro_xgmii_txd <= {r_xgmii_txd_1d[63:48],w_crc_1[31:0],8'hFD,8'h07};
            8'b1100_0000:ro_xgmii_txd <= {r_xgmii_txd_1d[63:56],r_crc[31:0],8'hFD,16'h0707};
            8'b1000_0000:ro_xgmii_txd <= {r_crc_7[31:0],8'hFD,24'h070707};
            default     :ro_xgmii_txd <= 'd0;
        endcase
    else 
        ro_xgmii_txd <= r_xgmii_txd_1d;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_xgmii_txc <= 8'b1111_1111;
    else if(r_sof_1d)
        ro_xgmii_txc <= 8'b1000_0000;
    // else if(r_eof && (w_fifo_keep_dout <= 8'b1111_0000 && w_fifo_keep_dout >= 8'b1000_0000))
    //     ro_xgmii_txc <= 8'b1111_1111;
    else if(r_eof_2d)
        case(w_fifo_keep_dout)
            8'b1111_1111:ro_xgmii_txc <= 8'b0001_1111;
            8'b1111_1110:ro_xgmii_txc <= 8'b0011_1111;
            8'b1111_1100:ro_xgmii_txc <= 8'b0111_1111;
            default     :ro_xgmii_txc <= 8'b1111_1111;
        endcase
    else if(r_eof_1d)
        case(w_fifo_keep_dout)
            8'b1111_0000:ro_xgmii_txc <= 8'b0000_0001;
            8'b1110_0000:ro_xgmii_txc <= 8'b0000_0011;
            8'b1100_0000:ro_xgmii_txc <= 8'b0000_0111;
            8'b1000_0000:ro_xgmii_txc <= 8'b0000_1111;
            default     :ro_xgmii_txc <= 8'b0000_0000;
        endcase
    else if(r_eof_3d)
        ro_xgmii_txc <= 8'b1111_1111;
    else if(r_sof_2d)
        ro_xgmii_txc <= 8'b0000_0000;
    else 
        ro_xgmii_txc <= ro_xgmii_txc;
end

endmodule
