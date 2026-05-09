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
// 1. 实现了FIFO的First Word Fall Through逻辑
//---------------------------------------------------------------------
`timescale 1ns / 1ps

module fwft_ctrl #
(
    parameter DATA_WIDTH = 32,//FIFO的数据宽度
    parameter ADDR_WIDTH = 10 //FIFO的地址宽度
)
(
    input I_rst,
    input I_clk,
    
    output                      O_fifo_rd_en   ,
    input                       I_fifo_rd_valid,
    input      [DATA_WIDTH-1:0] I_fifo_rd_data ,
    input      [ADDR_WIDTH  :0] I_fifo_rd_cnt  ,
    input                       I_fifo_empty   ,
    
    input                       I_fwft_rd_en   ,
    output                      O_fwft_rd_valid,
    output     [DATA_WIDTH-1:0] O_fwft_rd_data ,
    output reg [ADDR_WIDTH  :0] O_fwft_rd_cnt  ,
    output reg                  O_fwft_empty   
);
    
    //数据总是优先存到q0，然后再存到q1
    reg [DATA_WIDTH-1:0] q0;
    reg [DATA_WIDTH-1:0] q1;
    reg [1:0] cnt;//cnt可以反映q0,q1是否有有效数据.cnt[0]对应q0，cnt[1]对应q1
    
    always @ (posedge I_clk)
    begin
        if(I_rst)
            cnt <= 2'b00;
        else
            case(cnt)
                2'b00://q0、q1中都没有有效数据
                    if(I_fifo_rd_valid)//数据到q0
                        cnt <= 2'b01;
                    else
                        cnt <= 2'b00;
                2'b01://q0中存储的是有效数据，q1中不是
                    if(I_fwft_rd_en)//用户取数据
                        begin
                            if(I_fifo_rd_valid)//前面的FIFO正好有数据送出，则数据还是存到q0
                                cnt <= 2'b01;
                            else//前面的FIFO没有数据送出，q0将被读空
                                cnt <= 2'b00;
                        end
                    else//用户不取数据
                        begin
                            if(I_fifo_rd_valid)//前面的FIFO正好有数据送出，数据存到q1，q0不变
                                cnt <= 2'b11;
                            else//前面的FIFO没有数据送出，保持这个状态
                                cnt <= 2'b01;
                        end
                2'b11://q0、和q1中都是有效数据
                      //在这个状态下，设计应保证I_fifo_rd_valid不可能有效
                    if(I_fwft_rd_en)//用户取数据,q0被读出，同时从q1加载下一个数据，q1变成无效
                        cnt <= 2'b01;
                    else//用户不取数据，保持这个状态
                        cnt <= 2'b11;
                default:
                    cnt <= 2'b00;
            endcase
    end
    
    always @ (posedge I_clk)
    begin
        if(I_rst)
            q0 <= 1'b0;
        else
            case(cnt)
                2'b00://q0、q1中都没有有效数据
                    if(I_fifo_rd_valid)//数据到q0
                        q0 <= I_fifo_rd_data;
                2'b01://q0中存储的是有效数据，q1中不是
                    if(I_fwft_rd_en)//用户取数据
                        begin
                            if(I_fifo_rd_valid)//前面的FIFO正好有数据送出，则数据还是存到q0
                                q0 <= I_fifo_rd_data;//如果没有有效数据的话，q0一定要保持上一个值
                        end
                2'b11://q0、和q1中都是有效数据
                    if(I_fwft_rd_en)//用户取数据
                        q0 <= q1;
            endcase
    end
    
    always @ (posedge I_clk)
    begin
        if(I_rst)
            q1 <= 1'b0;
        else if(cnt==2'b01)//q0中存储的是有效数据，q1中不是
            begin
                if(!I_fwft_rd_en && I_fifo_rd_valid)
                    q1 <= I_fifo_rd_data;
            end
    end
    
    assign O_fwft_rd_data = q0;
    
    //我们设计的目的是为了尽量让把cnt往2'b11推。但是，如果不加克制地去读FIFO，它返回的数据就没地方存储了
    //只有两个寄存器，q0和q1来缓存FIFO的读数据。所以，要杜绝丢数的情况。
    reg rd_mask;
    assign O_fifo_rd_en = (!I_fifo_empty) && (!rd_mask || I_fwft_rd_en);//(!I_fifo_empty)这个条件可以去掉，为保险起见还是加上了。为什么？
                                                                        //1.虽然我自己写的FIFO有读保护机制，但并不代表别人写的FIFO也有。
                                                                        //2.如果前面的FIFO有读保护机制，则加上(!I_fifo_empty)条件也不会使逻辑更复杂；反之，(!I_fifo_empty)会增加FIFO的逻辑，但是更安全。
    
    always @ (posedge I_clk)
    begin
        if(I_rst)
            rd_mask <= 1'b0;
        else
            case(cnt)
                2'b00://q0、q1中都没有有效数据
                    if(I_fifo_rd_valid)
                        rd_mask <= 1'b1;//及时拉高mask，防止多读了。
                    else
                        rd_mask <= 1'b0;
                2'b01://q0中存储的是有效数据，q1中不是
                    if(I_fwft_rd_en)//用户取数据
                                    //此时，我们必然会去试图读FIFO（不考虑I_fifo_empty）
                        begin
                            //rd_mask <= 1'b1;//为什么不这样写？如果此时I_fifo_rd_valid无效，则q0被读空，而你接下来又不去主动读FIFO，显然是不行的
                            //rd_mask <= 1'b0;//为什么不这样写？如果此时I_fifo_rd_valid有效，则q0中将继续是有效数据，下一拍如果I_fifo_rd_valid继续有效，而你当时可能还在读FIFO，就不安全了
                            //看来我们要根据I_fifo_rd_valid的状态来判断
                            if(I_fifo_rd_valid)//前面的FIFO正好有数据送出，则数据还是存到q0
                                rd_mask <= 1'b1;
                            else//前面的FIFO没有数据送出，q0将被读空
                                rd_mask <= 1'b0;
                        end
                    else//用户不取数据
                        //此时，我们可能正在试图读FIFO，也可能没读。（根据mask的情况而定）
                        begin
                            if(I_fifo_rd_valid)//此条件一旦满足，cnt将被推至2'b11,rd_mask要及时拉高
                                rd_mask <= 1'b1;
                            else
                                rd_mask <= ~rd_mask;//翻转的目的，是为了杜绝连续的读请求，导致多读了
                        end
                2'b11://q0、和q1中都是有效数据
                    rd_mask <= 1'b1;
            endcase
    end
    
    always @ (posedge I_clk)
    begin
        if(I_rst)
            O_fwft_empty <= 1'b1;
        else
            case(cnt)
                2'b00://q0、q1中都没有有效数据
                    if(I_fifo_rd_valid)
                        O_fwft_empty <= 1'b0;
                    else
                        O_fwft_empty <= 1'b1;
                2'b01://q0中存储的是有效数据，q1中不是
                    if(I_fwft_rd_en && !I_fifo_rd_valid)
                        O_fwft_empty <= 1'b1;
                    else
                        O_fwft_empty <= 1'b0;
                default:
                    O_fwft_empty <= 1'b0;
            endcase
    end
    assign O_fwft_rd_valid = I_fwft_rd_en && !O_fwft_empty;
    
    always @ (posedge I_clk)
    begin
        if(I_rst)
            O_fwft_rd_cnt <= 1'd0;
        else
            case(cnt)
                2'b00://q0、q1中都没有有效数据
                    if(I_fifo_rd_valid)
                        O_fwft_rd_cnt <= I_fifo_rd_cnt + 1'd1;
                    else
                        O_fwft_rd_cnt <= 1'd0;
                2'b01://q0中存储的是有效数据，q1中不是
                    if(I_fwft_rd_en)//用户取数据
                        begin
                            if(I_fifo_rd_valid)//前面的FIFO正好有数据送出，则数据还是存到q0
                                O_fwft_rd_cnt <= I_fifo_rd_cnt + 1'd1;
                            else//前面的FIFO没有数据送出，q0将被读空
                                O_fwft_rd_cnt <= 1'd0;
                        end
                    else//用户不取数据
                        begin
                            if(I_fifo_rd_valid)//前面的FIFO正好有数据送出，数据存到q1，q0不变
                                O_fwft_rd_cnt <= I_fifo_rd_cnt + 2'd2;
                            else//前面的FIFO没有数据送出，保持这个状态
                                O_fwft_rd_cnt <= I_fifo_rd_cnt + 1'd1;
                        end
                2'b11://q0、和q1中都是有效数据
                    if(I_fwft_rd_en)
                        O_fwft_rd_cnt <= I_fifo_rd_cnt + 1'd1;
                    else
                        O_fwft_rd_cnt <= I_fifo_rd_cnt + 2'd2;
            endcase
    end
    
endmodule
