// HongXin Copyright 2010~2019
// HongXin Company Confidential
// Company : HongXin Telecom .Inc
// Copyright(c) 2019, HongXin Telecom .Inc, All right reserved

//---------------------------------------------------------------------
// AUTHOR          : Tang Dongsheng
//---------------------------------------------------------------------
// Tool version    : ISE14.7 / Vivado 2018
//---------------------------------------------------------------------
// Release History :
//---------------------------------------------------------------------
// Version    |    Date      | Description
//---------------------------------------------------------------------
// 1.0-0      |  2020-09-09  | first edit
//---------------------------------------------------------------------
// Main Function   :
// 1. 用URAM288_BASE实现简单双口RAM
//---------------------------------------------------------------------
`timescale 1ns / 1ps

module ram_sdp_base_uram #
(//sdp : Simple Dual Port
    parameter DATA_WIDTH        =     72,//DATA_WIDTH*COL_NUM should be less or equal to 72,and DATA_WIDTH/8 or DATA_WIDTH/9 is an interger
    parameter REG_OUT           =      1,//1<=REG_OUT<=2
    parameter USE_RD_EN         =      0,//If USE_RD_EN = 1, user should drive I_rd_en port as read enable. Otherwise, this port is unused, left it un-conected or assign it with any value.
    parameter COL_NUM           =      1 //Number of byte write enable bit
)
(
    input                I_wr_clk ,
    input  [COL_NUM-1:0] I_wr_en  ,
    input  [11:0]        I_wr_addr,
    input  [71:0]        I_wr_data,
    input                I_rd_clk ,
    input                I_rd_en  ,
    input  [11:0]        I_rd_addr,
    output [71:0]        O_rd_data
);
    
    localparam BYTE_SIZE = (DATA_WIDTH%9==0) ? 9 : 8;
    localparam N = DATA_WIDTH/BYTE_SIZE;//设计要求DATA_WIDTH一定是BYTE_SIZE的整数倍
    
    localparam BWE_MODE = (BYTE_SIZE==9) ? "PARITY_INTERLEAVED" : "PARITY_INDEPENDENT";
    localparam OREG_B   = (REG_OUT==2) ? "TRUE" : "FALSE";
    
    wire [8:0] byte_wr_en;
    
    genvar i;
    generate
        for(i=0;i<9;i=i+1)                          //这段代码可能不易理解
        begin:bwr                                   //其效果是：
            if((i/N)<COL_NUM)                       //将I_wr_en的每个bit扩展W份，
                assign byte_wr_en[i] = I_wr_en[i/N];//作为URAM的写字节使能，
            else                                    //
                assign byte_wr_en[i] = 1'b0;        //扩展后位宽不够的，高位补0
        end
    endgenerate
    
    
    wire [71:0]  wr_data;
    wire [71:0]  rd_data;
    generate
        if(BYTE_SIZE==9)
            begin:interleaved
                
                assign wr_data[0*8+:8] = I_wr_data[0*9+:8];
                assign wr_data[1*8+:8] = I_wr_data[1*9+:8];
                assign wr_data[2*8+:8] = I_wr_data[2*9+:8];
                assign wr_data[3*8+:8] = I_wr_data[3*9+:8];
                assign wr_data[4*8+:8] = I_wr_data[4*9+:8];
                assign wr_data[5*8+:8] = I_wr_data[5*9+:8];
                assign wr_data[6*8+:8] = I_wr_data[6*9+:8];
                assign wr_data[7*8+:8] = I_wr_data[7*9+:8];
                assign wr_data[8*8+:8] = {I_wr_data[71],I_wr_data[62],I_wr_data[53],I_wr_data[44],
                                           I_wr_data[35],I_wr_data[26],I_wr_data[17],I_wr_data[8]};
                
                assign O_rd_data[0*9+:8] = rd_data[0*8+:8];
                assign O_rd_data[1*9+:8] = rd_data[1*8+:8];
                assign O_rd_data[2*9+:8] = rd_data[2*8+:8];
                assign O_rd_data[3*9+:8] = rd_data[3*8+:8];
                assign O_rd_data[4*9+:8] = rd_data[4*8+:8];
                assign O_rd_data[5*9+:8] = rd_data[5*8+:8];
                assign O_rd_data[6*9+:8] = rd_data[6*8+:8];
                assign O_rd_data[7*9+:8] = rd_data[7*8+:8];
                assign {O_rd_data[71],O_rd_data[62],O_rd_data[53],O_rd_data[44],
                         O_rd_data[35],O_rd_data[26],O_rd_data[17],O_rd_data[8]} = rd_data[8*8+:8];
                
            end
        else
            begin:independent
                assign wr_data   = I_wr_data;
                assign O_rd_data = rd_data  ;
            end

    endgenerate
    
    assign rd_en = USE_RD_EN  ? I_rd_en  : 1'b1;
    
    URAM288_BASE #
    (
        .AUTO_SLEEP_LATENCY      (8 ),   // Latency requirement to enter sleep mode
        .AVG_CONS_INACTIVE_CYCLES(10),   // Average concecutive inactive cycles when is SLEEP mode for power
                                         // estimation
        .BWE_MODE_A          (BWE_MODE), // Port A Byte write control
        .BWE_MODE_B          (BWE_MODE), // Port B Byte write control
        .EN_AUTO_SLEEP_MODE  ("FALSE"),  // Enable to automatically enter sleep mode
        .EN_ECC_RD_A         ("FALSE"),  // Port A ECC encoder
        .EN_ECC_RD_B         ("FALSE"),  // Port B ECC encoder
        .EN_ECC_WR_A         ("FALSE"),  // Port A ECC decoder
        .EN_ECC_WR_B         ("FALSE"),  // Port B ECC decoder
        .IREG_PRE_A          ("FALSE"),  // Optional Port A input pipeline registers
        .IREG_PRE_B          ("FALSE"),  // Optional Port B input pipeline registers
        .IS_CLK_INVERTED     (1'b0   ),  // Optional inverter for CLK
        .IS_EN_A_INVERTED    (1'b0   ),  // Optional inverter for Port A enable
        .IS_EN_B_INVERTED    (1'b0   ),  // Optional inverter for Port B enable
        .IS_RDB_WR_A_INVERTED(1'b0   ),  // Optional inverter for Port A read/write select
        .IS_RDB_WR_B_INVERTED(1'b0   ),  // Optional inverter for Port B read/write select
        .IS_RST_A_INVERTED   (1'b0   ),  // Optional inverter for Port A reset
        .IS_RST_B_INVERTED   (1'b0   ),  // Optional inverter for Port B reset
        .OREG_A              ("FALSE"),  // Optional Port A output pipeline registers
        .OREG_B              (OREG_B ),  // Optional Port B output pipeline registers
        .OREG_ECC_A          ("FALSE"),  // Port A ECC decoder output
        .OREG_ECC_B          ("FALSE"),  // Port B output ECC decoder
        .RST_MODE_A          ("SYNC" ),  // Port A reset mode
        .RST_MODE_B          ("SYNC" ),  // Port B reset mode
        .USE_EXT_CE_A        ("FALSE"),  // Enable Port A external CE inputs for output registers
        .USE_EXT_CE_B        ("FALSE")   // Enable Port B external CE inputs for output registers
    )
    u_URAM288
    (
        .DBITERR_A       (),                 // 1-bit output: Port A double-bit error flag status
        .DBITERR_B       (),                 // 1-bit output: Port B double-bit error flag status
        .DOUT_A          (),                 // 72-bit output: Port A read data output
        .DOUT_B          (rd_data   ),       // 72-bit output: Port B read data output
        .SBITERR_A       (),                 // 1-bit output: Port A single-bit error flag status
        .SBITERR_B       (),                 // 1-bit output: Port B single-bit error flag status
        .ADDR_A          ({11'b0,I_wr_addr}),// 23-bit input: Port A address
        .ADDR_B          ({11'b0,I_rd_addr}),// 23-bit input: Port B address
        .BWE_A           (byte_wr_en),       // 9-bit input: Port A Byte-write enable
        .BWE_B           (9'b0      ),       // 9-bit input: Port B Byte-write enable
        .CLK             (I_wr_clk  ),       // 1-bit input: Clock source
        .DIN_A           (wr_data   ),       // 72-bit input: Port A write data input
        .DIN_B           (72'b0     ),       // 72-bit input: Port B write data input
        .EN_A            (1'b1      ),       // 1-bit input: Port A enable
        .EN_B            (rd_en     ),       // 1-bit input: Port B enable
        .INJECT_DBITERR_A(1'b0      ),       // 1-bit input: Port A double-bit error injection
        .INJECT_DBITERR_B(1'b0      ),       // 1-bit input: Port B double-bit error injection
        .INJECT_SBITERR_A(1'b0      ),       // 1-bit input: Port A single-bit error injection
        .INJECT_SBITERR_B(1'b0      ),       // 1-bit input: Port B single-bit error injection
        .OREG_CE_A       (1'b0      ),       // 1-bit input: Port A output register clock enable
        .OREG_CE_B       (1'b0      ),       // 1-bit input: Port B output register clock enable
        .OREG_ECC_CE_A   (1'b0      ),       // 1-bit input: Port A ECC decoder output register clock enable
        .OREG_ECC_CE_B   (1'b0      ),       // 1-bit input: Port B ECC decoder output register clock enable
        .RDB_WR_A        (1'b1      ),       // 1-bit input: Port A read/write select
        .RDB_WR_B        (1'b0      ),       // 1-bit input: Port B read/write select
        .RST_A           (1'b0      ),       // 1-bit input: Port A asynchronous or synchronous reset for output
                                             // registers
        
        .RST_B(1'b0),                        // 1-bit input: Port B asynchronous or synchronous reset for output
                                             // registers
        
        .SLEEP(1'b0)                         // 1-bit input: Dynamic power gating control
    );
    
endmodule
