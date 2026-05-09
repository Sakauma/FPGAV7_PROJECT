`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/06 11:05:36
// Design Name: 
// Module Name: CRC_Process
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


module CRC_Process(
    input           i_clk               ,
    input           i_rst               ,

    input  [63:0]   s_axis_data         ,
    input  [79:0]   s_axis_user         ,//10'd0,6'dsource_mac,16'dtype
    input  [7 :0]   s_axis_keep         ,
    input           s_axis_last         ,
    input           s_axis_valid        ,
    input           i_crc_error         ,
    input           i_crc_valid         ,

    output [63:0]   m_axis_data         ,
    output [79:0]   m_axis_user         ,//10'd0,6'dsource_mac,16'dtype
    output [7 :0]   m_axis_keep         ,
    output          m_axis_last         ,
    output          m_axis_valid        
);

reg  [63:0]         rs_axis_data        ;
reg  [79:0]         rs_axis_user        ;
reg  [7 :0]         rs_axis_keep        ;
reg                 rs_axis_last        ;
reg                 rs_axis_valid       ;
reg                 rs_axis_valid_1d    ;
reg  [7 :0]         r_bram_data_addra   ;
reg  [7 :0]         r_bram_data_addrb   ;
reg                 r_bram_data_enb     ;
reg                 r_bram_data_enb_1d  ;
reg  [4 :0]         r_bram_len_addra    ;
reg  [4 :0]         r_bram_len_addrb    ;
reg                 r_bram_len_enb      ;
reg  [4 :0]         r_bram_keep_addra   ;
reg  [4 :0]         r_bram_keep_addrb   ;
reg                 r_bram_keep_enb     ;
reg  [4 :0]         r_bram_user_addra   ;
reg  [4 :0]         r_bram_user_addrb   ;
reg                 r_bram_user_enb     ;
reg                 r_out_run           ;
reg  [15:0]         r_cnt               ;
reg                 r_len_valid         ;
reg  [15:0]         r_out_len           ;
reg  [63:0]         rm_axis_data        ;
reg  [79:0]         rm_axis_user        ;
reg  [7 :0]         rm_axis_keep        ;
reg                 rm_axis_last        ;
reg                 rm_axis_valid       ;
reg                 r_fifo_crc_rden     ;
reg                 r_fifo_crc_lock     ;
reg                 r_fifo_crc_rden_1d  ;
reg                 r_fifo_init_rden    ;

wire                w_fifo_crc_dout     ;
wire                w_fifo_crc_full     ;
wire                w_fifo_init_empty   ;
wire                w_fifo_init_full    ;
wire                w_fifo_crc_empty    ;
wire [63:0]         w_bram_data_doutb   ;
wire [15:0]         w_bram_len_doutb    ;
wire [7 :0]         w_bram_keep_doutb   ;
wire [63:0]         w_bram_user_doutb   ;
wire [7 :0]         w_data_init_dout    ;
wire [4 :0]         w_len_init_dout     ;
wire [4 :0]         w_keep_init_dout    ;
wire [4 :0]         w_user_init_dout    ;

assign m_axis_data  = rm_axis_data      ;
assign m_axis_user  = rm_axis_user      ;
assign m_axis_keep  = rm_axis_keep      ;
assign m_axis_last  = rm_axis_last      ;
assign m_axis_valid = rm_axis_valid     ;

BRAM_64X256_SD BRAM_64X256_SD_DATA_U0 (
  .clka     (i_clk                  ),
  .ena      (rs_axis_valid          ),
  .wea      (rs_axis_valid          ),
  .addra    (r_bram_data_addra      ),
  .dina     (rs_axis_data           ),
  .clkb     (i_clk                  ),
  .enb      (r_bram_data_enb        ),
  .addrb    (r_bram_data_addrb      ),
  .doutb    (w_bram_data_doutb      ) 
);

BRAM_16X32_SD BRAM_16X32_SD_LEN_U0 (
  .clka     (i_clk                  ),
  .ena      (rs_axis_last           ),
  .wea      (rs_axis_last           ),
  .addra    (r_bram_len_addra       ),
  .dina     (rs_axis_user[79:64]    ),
  .clkb     (i_clk                  ),
  .enb      (r_bram_len_enb         ),
  .addrb    (r_bram_len_addrb       ),
  .doutb    (w_bram_len_doutb       ) 
);

BRAM_8X32_SD BRAM_8X32_SD_KEEP_U0 (
  .clka     (i_clk                  ),
  .ena      (rs_axis_last           ),
  .wea      (rs_axis_last           ),
  .addra    (r_bram_keep_addra      ),
  .dina     (rs_axis_keep            ),
  .clkb     (i_clk                  ),
  .enb      (r_bram_keep_enb        ),
  .addrb    (r_bram_keep_addrb      ),
  .doutb    (w_bram_keep_doutb      ) 
);

BRAM_64X32_SD BRAM_64X32_SD_U0 (
  .clka     (i_clk                  ),    // input wire clka
  .ena      (rs_axis_last           ),      // input wire ena
  .wea      (rs_axis_last           ),      // input wire [0 : 0] wea
  .addra    (r_bram_user_addra      ),  // input wire [4 : 0] addra
  .dina     (rs_axis_user[63:0]     ),    // input wire [21 : 0] dina
  .clkb     (i_clk                  ),    // input wire clkb
  .enb      (r_bram_user_enb        ),      // input wire enb
  .addrb    (r_bram_user_addrb      ),  // input wire [4 : 0] addrb
  .doutb    (w_bram_user_doutb      )  // output wire [21 : 0] doutb
);

FIFO_1X32 FIFO_1X32_U0 (
  .clk      (i_clk                  ), 
  .srst     (i_rst                  ),
  .din      (i_crc_error            ), 
  .wr_en    (i_crc_valid            ), 
  .rd_en    (r_fifo_crc_rden        ),
  .dout     (w_fifo_crc_dout        ),
  .full     (w_fifo_crc_full        ),
  .empty    (w_fifo_crc_empty       ) 
);

FIFO_8X32 FIFO_8X32_U0 (
  .clk      (i_clk                  ),
  .srst     (i_rst                  ),
  .din      (r_bram_data_addra      ),
  .wr_en    (rs_axis_valid & !rs_axis_valid_1d),
  .rd_en    (r_fifo_init_rden       ),
  .dout     (w_data_init_dout       ),
  .full     (w_fifo_init_full       ),
  .empty    (w_fifo_init_empty      ) 
);

FIFO_8X32 FIFO_8X32_U1 (
  .clk      (i_clk                  ),
  .srst     (i_rst                  ),
  .din      ({3'd0,r_bram_len_addra}),
  .wr_en    (rs_axis_last           ),
  .rd_en    (r_fifo_init_rden       ),
  .dout     (w_len_init_dout        ),
  .full     (),
  .empty    () 
);

FIFO_8X32 FIFO_8X32_U2 (
  .clk      (i_clk                  ),
  .srst     (i_rst                  ),
  .din      ({3'd0,r_bram_keep_addra}),
  .wr_en    (rs_axis_last           ),
  .rd_en    (r_fifo_init_rden       ),
  .dout     (w_keep_init_dout       ),
  .full     (),
  .empty    () 
);

FIFO_8X32 FIFO_8X32_U3 (
  .clk      (i_clk                  ),
  .srst     (i_rst                  ),
  .din      ({3'd0,r_bram_user_addra}),
  .wr_en    (rs_axis_last           ),
  .rd_en    (r_fifo_init_rden       ),
  .dout     (w_user_init_dout       ),
  .full     (),
  .empty    () 
);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_data        <= 'd0;
        rs_axis_user        <= 'd0;
        rs_axis_keep        <= 'd0;
        rs_axis_last        <= 'd0;
        rs_axis_valid       <= 'd0;
        rs_axis_valid_1d    <= 'd0;
        r_bram_data_enb_1d  <= 'd0;
        r_fifo_crc_rden_1d  <= 'd0;
    end else begin
        rs_axis_data        <= s_axis_data ;
        rs_axis_user        <= s_axis_user ;
        rs_axis_keep        <= s_axis_keep ;
        rs_axis_last        <= s_axis_last ;
        rs_axis_valid       <= s_axis_valid;
        rs_axis_valid_1d    <= rs_axis_valid;
        r_bram_data_enb_1d  <= r_bram_data_enb;
        r_fifo_crc_rden_1d  <= r_fifo_crc_rden;
    end
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_crc_rden <= 'd0;
    else if(!w_fifo_crc_empty && !r_fifo_crc_rden && !r_fifo_crc_lock)
        r_fifo_crc_rden <= 'd1;
    else    
        r_fifo_crc_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_init_rden <= 'd0;
    else if(!w_fifo_crc_empty && !r_fifo_crc_rden && !r_fifo_crc_lock)
        r_fifo_init_rden <= 'd1;
    else 
        r_fifo_init_rden <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_fifo_crc_lock <= 'd0;
    else if(r_fifo_crc_rden_1d && w_fifo_crc_dout)
        r_fifo_crc_lock <= 'd0;
    else if(r_cnt > 2 && r_cnt == r_out_len - 1)
        r_fifo_crc_lock <= 'd0;
    else if(!w_fifo_crc_empty && !r_fifo_crc_rden && !r_fifo_crc_lock)
        r_fifo_crc_lock <= 'd1;
    else        
        r_fifo_crc_lock <= r_fifo_crc_lock;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_data_addra <= 'd0;
    else if(r_fifo_crc_rden_1d && w_fifo_crc_dout)
        r_bram_data_addra <= w_data_init_dout;
    else if(rs_axis_valid)
        r_bram_data_addra <= r_bram_data_addra + 1;
    else 
        r_bram_data_addra <= r_bram_data_addra;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_len_addra <= 'd0;
    else if(r_fifo_crc_rden_1d && w_fifo_crc_dout)
        r_bram_len_addra <= w_len_init_dout;
    else if(rs_axis_last)
        r_bram_len_addra <= r_bram_len_addra + 1;
    else 
        r_bram_len_addra <= r_bram_len_addra;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_keep_addra <= 'd0;
    else if(r_fifo_crc_rden_1d && w_fifo_crc_dout)
        r_bram_keep_addra <= w_keep_init_dout;
    else if(rs_axis_last)
        r_bram_keep_addra <= r_bram_keep_addra + 1;
    else 
        r_bram_keep_addra <= r_bram_keep_addra;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_user_addra <= 'd0;
    else if(r_fifo_crc_rden_1d && w_fifo_crc_dout)
        r_bram_user_addra <= w_user_init_dout;
    else if(rs_axis_last)
        r_bram_user_addra <= r_bram_user_addra + 1;
    else 
        r_bram_user_addra <= r_bram_user_addra;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_out_run <= 'd0;
    else if(r_cnt > 2 && r_cnt == r_out_len - 1)
        r_out_run <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_out_run <= 'd1;
    else 
        r_out_run <= r_out_run;
end
      
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_len_enb <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_bram_len_enb <= 'd1;
    else        
        r_bram_len_enb <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_len_addrb <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_bram_len_addrb <= w_len_init_dout;
    else 
        r_bram_len_addrb <= r_bram_len_addrb;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_keep_enb <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_bram_keep_enb <= 'd1;
    else 
        r_bram_keep_enb <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_bram_keep_addrb <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_bram_keep_addrb <= w_keep_init_dout;
    else 
        r_bram_keep_addrb <= r_bram_keep_addrb;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_user_enb <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_bram_user_enb <= 'd1;
    else 
        r_bram_user_enb <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_bram_user_addrb <= 'd0;
    else if(r_fifo_crc_rden_1d && !w_fifo_crc_dout)
        r_bram_user_addrb <= w_user_init_dout;
    else 
        r_bram_user_addrb <= r_bram_user_addrb;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_len_valid <= 'd0;
    else 
        r_len_valid <= r_bram_len_enb;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_out_len <= 'd0;
    else if(r_len_valid)
        r_out_len <= w_bram_len_doutb;
    else        
        r_out_len <= r_out_len;
end
  
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_data_enb <= 'd0;
    else if(r_cnt > 2 && r_cnt == r_out_len - 1)
        r_bram_data_enb <= 'd0;
    else if(r_len_valid)
        r_bram_data_enb <= 'd1;
    else 
        r_bram_data_enb <= r_bram_data_enb;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_bram_data_addrb <= 'd0;
    else if(r_len_valid)
        r_bram_data_addrb <= w_data_init_dout;
    else if(r_bram_data_enb)
        r_bram_data_addrb <= r_bram_data_addrb + 1;
    else 
        r_bram_data_addrb <= r_bram_data_addrb;
end     


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt > 2 && r_cnt == r_out_len - 1)
        r_cnt <= 'd0;
    else if(r_bram_data_enb)
        r_cnt <= r_cnt + 1;
    else    
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_data <= 'd0;
    else 
        rm_axis_data <= w_bram_data_doutb;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user <= 'd0;
    else 
        rm_axis_user <= {r_out_len,w_bram_user_doutb};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_keep <= 'd0;
    else if(!r_bram_data_enb && r_bram_data_enb_1d)
        rm_axis_keep <= w_bram_keep_doutb;
    else 
        rm_axis_keep <= 8'hff;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_last <= 'd0;
    else if(!r_bram_data_enb && r_bram_data_enb_1d)
        rm_axis_last <= 'd1;
    else 
        rm_axis_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_valid <= 'd0;
    else 
        rm_axis_valid <= r_bram_data_enb_1d;
end 


endmodule
