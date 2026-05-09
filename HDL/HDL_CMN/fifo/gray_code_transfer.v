// HongXin Copyright 2010~2019
// HongXin Company Confidential
// Company : HongXin Telecom .Inc
// Copyright(c) 2019, HongXin Telecom .Inc, All right reserved

//---------------------------------------------------------------------
// AUTHOR          : Tang Dongsheng
//---------------------------------------------------------------------
// Tool version    : ISE14.7 / Vivado 2015
//---------------------------------------------------------------------
// Release History :
//---------------------------------------------------------------------
// Version    |    Date      | Description
//---------------------------------------------------------------------
// 1.0-0      |  2015-05-15  | first edit
//---------------------------------------------------------------------
// Main Function   :
// 1. 用格雷码实现跨时钟域counter信号的传递
// 2. 格雷码的编码与解码
// 3. 位宽可参数化
//---------------------------------------------------------------------
`timescale 1ns / 1ps

module gray_code_transfer #
(
    parameter DATA_WIDTH = 8
)
(
    input                       I_src_clk ,
    input                       I_dst_clk ,
    input                       I_src_rst ,
    input                       I_dst_rst ,
    input      [DATA_WIDTH-1:0] I_src_data,
    output reg [DATA_WIDTH-1:0] O_dst_data
);
    
    reg [DATA_WIDTH-1:0] gray_code;
    always @ (posedge I_src_clk)
    begin
        if(I_src_rst)
            gray_code <= 1'b0;
        else
            gray_code <= I_src_data ^ {1'b0,I_src_data[DATA_WIDTH-1:1]};
    end
    
    reg [DATA_WIDTH-1:0] gray_code_buf1;
    always @ (posedge I_dst_clk)
    begin
        if(I_dst_rst)
            gray_code_buf1 <= 1'b0;
        else
            gray_code_buf1 <= gray_code;
    end
    
    reg [DATA_WIDTH-1:0] gray_code_buf2;
    always @ (posedge I_dst_clk)
    begin
        if(I_dst_rst)
            gray_code_buf2 <= 1'b0;
        else
            gray_code_buf2 <= gray_code_buf1;
    end
    
    genvar i;
    generate
        for(i=0;i<DATA_WIDTH;i=i+1)
        begin: gen_data
            always @ (posedge I_dst_clk)
            begin
                if(I_dst_rst)
                    O_dst_data[i] <= 1'b0;
                else
                    O_dst_data[i] <= ^gray_code_buf2[DATA_WIDTH-1:i];
            end
        end
    endgenerate

endmodule
