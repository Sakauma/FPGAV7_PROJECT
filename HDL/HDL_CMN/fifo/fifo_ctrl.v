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
// 1.1-0      |  2018-08-01  | support different read and write data width
//---------------------------------------------------------------------
// Main Function   :
// 1. FIFO的控制逻辑
// 2. 读写时钟独立，支持同步和异步模式
// 3. FIFO的数据宽度和地址宽度可参数化
// 4. 支持不同的读写数据位宽
//---------------------------------------------------------------------
`timescale 1ns / 1ps

module fifo_ctrl #
(
    parameter DATA_WIDTH      = 32,//FIFO的数据宽度
    parameter ADDR_WIDTH      = 10,//FIFO的地址宽度
    parameter DIFF_ADDR_WIDTH = 0 ,//表示读地址宽度与写地址宽度的差值（可以为负数）
    parameter SYNC_MODE       = 1 ,//FIFO的模式。1为同步模式，即读时钟和写时钟为同一个时钟；0为异步模式，即读时钟和写时钟不一样
    parameter OVERRIDE        = 1  //当FIFO满时，如果继续写入数据，是否将旧值覆盖（写指针不动）。1：覆盖，0：不覆盖，即将新数据丢弃。为1时更有利于写时序
)
(
    input                                                                       I_wr_rst       ,//FIFO的写同步复位
    input                                                                       I_rd_rst       ,//FIFO的读同步复位
    
    input                                                                       I_fifo_wr_clk  ,//FIFO的写时钟
    input                                                                       I_fifo_wr_en   ,//FIFO的写使能
    input      [DATA_WIDTH-1:0]                                                 I_fifo_wr_data ,//FIFO的写数据,同步于I_fifo_wr_en
    output     [ADDR_WIDTH  :0]                                                 O_fifo_wr_cnt  ,//FIFO中剩余的数据个数,自然数
    output                                                                      O_fifo_full    ,//FIFO满了
    
    input                                                                       I_fifo_rd_clk  ,//FIFO的读时钟
    input                                                                       I_fifo_rd_en   ,//FIFO的读使能
    output reg                                                                  O_fifo_rd_valid,//FIFO的读数据有效指示
    output     [DATA_WIDTH*(2**ADDR_WIDTH)/2**(ADDR_WIDTH+DIFF_ADDR_WIDTH)-1:0] O_fifo_rd_data ,//FIFO的读数据,直接连RAM的输出
    output     [ADDR_WIDTH+DIFF_ADDR_WIDTH:0]                                   O_fifo_rd_cnt  ,//FIFO中剩余的数据个数,自然数
    output                                                                      O_fifo_empty   ,//FIFO空了
    
    output                                                                      O_ram_wr_clk   ,
    output                                                                      O_ram_wr_en    ,
    output     [ADDR_WIDTH-1:0]                                                 O_ram_wr_addr  ,
    output     [DATA_WIDTH-1:0]                                                 O_ram_wr_data  ,
    output                                                                      O_ram_rd_clk   ,
    output                                                                      O_ram_rd_en    ,
    output     [ADDR_WIDTH+DIFF_ADDR_WIDTH-1:0]                                 O_ram_rd_addr  ,
    input      [DATA_WIDTH*(2**ADDR_WIDTH)/2**(ADDR_WIDTH+DIFF_ADDR_WIDTH)-1:0] I_ram_rd_data   
);
    
    reg  [ADDR_WIDTH+DIFF_ADDR_WIDTH:0] rdpt  ;//读指针
    reg  [ADDR_WIDTH:0]                 wrpt  ;//写指针
    wire [ADDR_WIDTH+DIFF_ADDR_WIDTH:0] rdpt_s;//经过跨时钟域同步之后的读指针
    wire [ADDR_WIDTH:0]                 wrpt_s;//经过跨时钟域同步之后的写指针
    
    generate
        if(SYNC_MODE==0)
            begin
                
                gray_code_transfer #
                (
                    .DATA_WIDTH(ADDR_WIDTH+1)
                )
                u_gray_code_transfer_wr
                (
                    .I_src_clk (I_fifo_wr_clk),
                    .I_dst_clk (I_fifo_rd_clk),
                    .I_src_rst (I_wr_rst     ),
                    .I_dst_rst (I_rd_rst     ),
                    .I_src_data(wrpt         ),
                    .O_dst_data(wrpt_s       )
                );
                
                gray_code_transfer #
                (
                    .DATA_WIDTH(ADDR_WIDTH+DIFF_ADDR_WIDTH+1)
                )
                u_gray_code_transfer_rd
                (
                    .I_src_clk (I_fifo_rd_clk),
                    .I_dst_clk (I_fifo_wr_clk),
                    .I_src_rst (I_rd_rst     ),
                    .I_dst_rst (I_wr_rst     ),
                    .I_src_data(rdpt         ),
                    .O_dst_data(rdpt_s       )
                );
                
            end
        else
            begin
                assign rdpt_s = rdpt;
                assign wrpt_s = wrpt;
            end
    endgenerate
    
    localparam N = (DIFF_ADDR_WIDTH>0) ? DIFF_ADDR_WIDTH : -DIFF_ADDR_WIDTH;
    
    wire [ADDR_WIDTH:0]                 rdpt_s1;
    wire [ADDR_WIDTH+DIFF_ADDR_WIDTH:0] wrpt_s1;
    generate
        if(DIFF_ADDR_WIDTH<0)
            begin:WIDE
                assign rdpt_s1 = (rdpt_s<<N)         ;
                assign wrpt_s1 = wrpt_s[ADDR_WIDTH:N];
            end
        else if(DIFF_ADDR_WIDTH>0)
            begin:NARROW
                assign rdpt_s1 = rdpt_s[ADDR_WIDTH+N:N];
                assign wrpt_s1 = (wrpt_s<<N)           ;
            end
        else
            begin:NORMAL
                assign rdpt_s1 = rdpt_s;
                assign wrpt_s1 = wrpt_s;
            end
    endgenerate
    
    assign O_fifo_wr_cnt = wrpt    - rdpt_s1;
    assign O_fifo_rd_cnt = wrpt_s1 - rdpt   ;
    
    assign O_fifo_full  = (rdpt_s1[ADDR_WIDTH]!=wrpt[ADDR_WIDTH]) && (rdpt_s1[ADDR_WIDTH-1:0]==wrpt[ADDR_WIDTH-1:0]);
    assign O_fifo_empty = (rdpt[ADDR_WIDTH+DIFF_ADDR_WIDTH:0]==wrpt_s1[ADDR_WIDTH+DIFF_ADDR_WIDTH:0]);
    
    always @ (posedge I_fifo_wr_clk)
    begin
        if(I_wr_rst)
            wrpt <= 1'b0;
        else if(I_fifo_wr_en&&!O_fifo_full)//尽管加入O_fifo_full的条件会使逻辑更复杂，但出于安全考虑还是加上
            wrpt <= wrpt + 1'b1;
    end
    
    always @ (posedge I_fifo_rd_clk)
    begin
        if(I_rd_rst)
            rdpt <= 1'b0;
        else if(I_fifo_rd_en&&!O_fifo_empty)//尽管加入O_fifo_empty的条件会使逻辑更复杂，但出于安全考虑还是加上
            rdpt <= rdpt + 1'b1;
    end
    
    always @ (posedge I_fifo_rd_clk)
    begin
        if(I_rd_rst)
            O_fifo_rd_valid <= 1'b0;
        else
            O_fifo_rd_valid <= I_fifo_rd_en&&!O_fifo_empty;
    end
    
    assign O_ram_wr_clk  = I_fifo_wr_clk                         ;
    assign O_ram_wr_en   = I_fifo_wr_en&&(OVERRIDE||!O_fifo_full);//OVERRIDE为1时，O_ram_wr_en的逻辑更简单，更有利于RAM的写时序。
    assign O_ram_wr_addr = wrpt[ADDR_WIDTH-1:0]                  ;
    assign O_ram_wr_data = I_fifo_wr_data                        ;
    assign O_ram_rd_clk  = I_fifo_rd_clk                         ;
    assign O_ram_rd_en   = I_fifo_rd_en                          ;
    assign O_ram_rd_addr = rdpt[ADDR_WIDTH+DIFF_ADDR_WIDTH-1:0]  ;
    
    assign O_fifo_rd_data = I_ram_rd_data;
    
endmodule
