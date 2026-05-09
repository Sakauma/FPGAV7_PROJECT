module CRC32_64bKEEP(
  input             i_clk       ,
  input             i_rst       ,
  input             i_en        ,
  input  [7 :0]     i_data      ,
  input  [7 :0]     i_data_1    ,
  input  [7 :0]     i_data_2    ,
  input  [7 :0]     i_data_3    ,
  input  [7 :0]     i_data_4    ,
  input  [7 :0]     i_data_5    ,
  input  [7 :0]     i_data_6    ,
  input  [7 :0]     i_data_7    ,
  output [31:0]     o_crc       ,
  output [31:0]     o_crc_1     ,
  output [31:0]     o_crc_2     ,
  output [31:0]     o_crc_3     ,
  output [31:0]     o_crc_4     ,
  output [31:0]     o_crc_5     ,
  output [31:0]     o_crc_6     ,
  output [31:0]     o_crc_7     
);

  

    reg  [31:0] crc;

    wire [7 :0] d[0:7];

    wire [31:0] c[0:7];

    wire [31:0] newcrc[0:7];
    reg  [31:0] ro_crc[0:7];
    
    assign o_crc   = ro_crc[7];
    assign o_crc_1 = ro_crc[0];
    assign o_crc_2 = ro_crc[1];
    assign o_crc_3 = ro_crc[2];
    assign o_crc_4 = ro_crc[3];
    assign o_crc_5 = ro_crc[4];
    assign o_crc_6 = ro_crc[5];
    assign o_crc_7 = ro_crc[6];
    // assign o_crc_1 = ~{
    //               crc[0],crc[1],crc[2],crc[3],crc[4],crc[5],crc[6],crc[7],
    //               crc[8],crc[9],crc[10],crc[11],crc[12],crc[13],crc[14],crc[15],
    //               crc[16],crc[17],crc[18],crc[19],crc[20],crc[21],crc[22],crc[23],
    //               crc[24],crc[25],crc[26],crc[27],crc[28],crc[29],crc[30],crc[31]
    //               };
    assign d[0] = {i_data[0],i_data[1],i_data[2],i_data[3],i_data[4],i_data[5],i_data[6],i_data[7]}; 
    assign d[1] = {i_data_1[0],i_data_1[1],i_data_1[2],i_data_1[3],i_data_1[4],i_data_1[5],i_data_1[6],i_data_1[7]};
    assign d[2] = {i_data_2[0],i_data_2[1],i_data_2[2],i_data_2[3],i_data_2[4],i_data_2[5],i_data_2[6],i_data_2[7]};
    assign d[3] = {i_data_3[0],i_data_3[1],i_data_3[2],i_data_3[3],i_data_3[4],i_data_3[5],i_data_3[6],i_data_3[7]};
    assign d[4] = {i_data_4[0],i_data_4[1],i_data_4[2],i_data_4[3],i_data_4[4],i_data_4[5],i_data_4[6],i_data_4[7]};
    assign d[5] = {i_data_5[0],i_data_5[1],i_data_5[2],i_data_5[3],i_data_5[4],i_data_5[5],i_data_5[6],i_data_5[7]};
    assign d[6] = {i_data_6[0],i_data_6[1],i_data_6[2],i_data_6[3],i_data_6[4],i_data_6[5],i_data_6[6],i_data_6[7]};
    assign d[7] = {i_data_7[0],i_data_7[1],i_data_7[2],i_data_7[3],i_data_7[4],i_data_7[5],i_data_7[6],i_data_7[7]};

    assign c[0]  = crc;
    // assign c1 = ~{
    //               newcrc[0],newcrc[1],newcrc[2],newcrc[3],newcrc[4],newcrc[5],newcrc[6],newcrc[7],
    //               newcrc[8],newcrc[9],newcrc[10],newcrc[11],newcrc[12],newcrc[13],newcrc[14],newcrc[15],
    //               newcrc[16],newcrc[17],newcrc[18],newcrc[19],newcrc[20],newcrc[21],newcrc[22],newcrc[23],
    //               newcrc[24],newcrc[25],newcrc[26],newcrc[27],newcrc[28],newcrc[29],newcrc[30],newcrc[31]
    //               };
    // assign c2 = ~{
    //               newcrc1[0],newcrc1[1],newcrc1[2],newcrc1[3],newcrc1[4],newcrc1[5],newcrc1[6],newcrc1[7],
    //               newcrc1[8],newcrc1[9],newcrc1[10],newcrc1[11],newcrc1[12],newcrc1[13],newcrc1[14],newcrc1[15],
    //               newcrc1[16],newcrc1[17],newcrc1[18],newcrc1[19],newcrc1[20],newcrc1[21],newcrc1[22],newcrc1[23],
    //               newcrc1[24],newcrc1[25],newcrc1[26],newcrc1[27],newcrc1[28],newcrc1[29],newcrc1[30],newcrc1[31]
    //               };
    // assign c3 = ~{
    //               newcrc2[0],newcrc2[1],newcrc2[2],newcrc2[3],newcrc2[4],newcrc2[5],newcrc2[6],newcrc2[7],
    //               newcrc2[8],newcrc2[9],newcrc2[10],newcrc2[11],newcrc2[12],newcrc2[13],newcrc2[14],newcrc2[15],
    //               newcrc2[16],newcrc2[17],newcrc2[18],newcrc2[19],newcrc2[20],newcrc2[21],newcrc2[22],newcrc2[23],
    //               newcrc2[24],newcrc2[25],newcrc2[26],newcrc2[27],newcrc2[28],newcrc2[29],newcrc2[30],newcrc2[31]
    //               };
    // assign c4 = ~{
    //               newcrc3[0],newcrc3[1],newcrc3[2],newcrc3[3],newcrc3[4],newcrc3[5],newcrc3[6],newcrc3[7],
    //               newcrc3[8],newcrc3[9],newcrc3[10],newcrc3[11],newcrc3[12],newcrc3[13],newcrc3[14],newcrc3[15],
    //               newcrc3[16],newcrc3[17],newcrc3[18],newcrc3[19],newcrc3[20],newcrc3[21],newcrc3[22],newcrc3[23],
    //               newcrc3[24],newcrc3[25],newcrc3[26],newcrc3[27],newcrc3[28],newcrc3[29],newcrc3[30],newcrc3[31]
    //               };
    // assign c5 = ~{
    //               newcrc4[0],newcrc4[1],newcrc4[2],newcrc4[3],newcrc4[4],newcrc4[5],newcrc4[6],newcrc4[7],
    //               newcrc4[8],newcrc4[9],newcrc4[10],newcrc4[11],newcrc4[12],newcrc4[13],newcrc4[14],newcrc4[15],
    //               newcrc4[16],newcrc4[17],newcrc4[18],newcrc4[19],newcrc4[20],newcrc4[21],newcrc4[22],newcrc4[23],
    //               newcrc4[24],newcrc4[25],newcrc4[26],newcrc4[27],newcrc4[28],newcrc4[29],newcrc4[30],newcrc4[31]
    //               };
    // assign c6 = ~{
    //               newcrc5[0],newcrc5[1],newcrc5[2],newcrc5[3],newcrc5[4],newcrc5[5],newcrc5[6],newcrc5[7],
    //               newcrc5[8],newcrc5[9],newcrc5[10],newcrc5[11],newcrc5[12],newcrc5[13],newcrc5[14],newcrc5[15],
    //               newcrc5[16],newcrc5[17],newcrc5[18],newcrc5[19],newcrc5[20],newcrc5[21],newcrc5[22],newcrc5[23],
    //               newcrc5[24],newcrc5[25],newcrc5[26],newcrc5[27],newcrc5[28],newcrc5[29],newcrc5[30],newcrc5[31]
    //               };
    // assign c7 = ~{
    //               newcrc6[0],newcrc6[1],newcrc6[2],newcrc6[3],newcrc6[4],newcrc6[5],newcrc6[6],newcrc6[7],
    //               newcrc6[8],newcrc6[9],newcrc6[10],newcrc6[11],newcrc6[12],newcrc6[13],newcrc6[14],newcrc6[15],
    //               newcrc6[16],newcrc6[17],newcrc6[18],newcrc6[19],newcrc6[20],newcrc6[21],newcrc6[22],newcrc6[23],
    //               newcrc6[24],newcrc6[25],newcrc6[26],newcrc6[27],newcrc6[28],newcrc6[29],newcrc6[30],newcrc6[31]
    //               };
                  
genvar i ;
generate for(i = 0 ; i < 8 ; i = i + 1)
begin

    assign newcrc[i][0]  = i_en ? d[i][6] ^ d[i][0] ^ c[i][24] ^ c[i][30] : 'd0;
    assign newcrc[i][1]  = i_en ? d[i][7] ^ d[i][6] ^ d[i][1] ^ d[i][0] ^ c[i][24] ^ c[i][25] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][2]  = i_en ? d[i][7] ^ d[i][6] ^ d[i][2] ^ d[i][1] ^ d[i][0] ^ c[i][24] ^ c[i][25] ^ c[i][26] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][3]  = i_en ? d[i][7] ^ d[i][3] ^ d[i][2] ^ d[i][1] ^ c[i][25] ^ c[i][26] ^ c[i][27] ^ c[i][31]: 'd0;
    assign newcrc[i][4]  = i_en ? d[i][6] ^ d[i][4] ^ d[i][3] ^ d[i][2] ^ d[i][0] ^ c[i][24] ^ c[i][26] ^ c[i][27] ^ c[i][28] ^ c[i][30]: 'd0;
    assign newcrc[i][5]  = i_en ? d[i][7] ^ d[i][6] ^ d[i][5] ^ d[i][4] ^ d[i][3] ^ d[i][1] ^ d[i][0] ^ c[i][24] ^ c[i][25] ^ c[i][27] ^ c[i][28] ^ c[i][29] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][6]  = i_en ? d[i][7] ^ d[i][6] ^ d[i][5] ^ d[i][4] ^ d[i][2] ^ d[i][1] ^ c[i][25] ^ c[i][26] ^ c[i][28] ^ c[i][29] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][7]  = i_en ? d[i][7] ^ d[i][5] ^ d[i][3] ^ d[i][2] ^ d[i][0] ^ c[i][24] ^ c[i][26] ^ c[i][27] ^ c[i][29] ^ c[i][31]: 'd0;
    assign newcrc[i][8]  = i_en ? d[i][4] ^ d[i][3] ^ d[i][1] ^ d[i][0] ^ c[i][0] ^ c[i][24] ^ c[i][25] ^ c[i][27] ^ c[i][28]: 'd0;
    assign newcrc[i][9]  = i_en ? d[i][5] ^ d[i][4] ^ d[i][2] ^ d[i][1] ^ c[i][1] ^ c[i][25] ^ c[i][26] ^ c[i][28] ^ c[i][29]: 'd0;
    assign newcrc[i][10] = i_en ? d[i][5] ^ d[i][3] ^ d[i][2] ^ d[i][0] ^ c[i][2] ^ c[i][24] ^ c[i][26] ^ c[i][27] ^ c[i][29]: 'd0;
    assign newcrc[i][11] = i_en ? d[i][4] ^ d[i][3] ^ d[i][1] ^ d[i][0] ^ c[i][3] ^ c[i][24] ^ c[i][25] ^ c[i][27] ^ c[i][28]: 'd0;
    assign newcrc[i][12] = i_en ? d[i][6] ^ d[i][5] ^ d[i][4] ^ d[i][2] ^ d[i][1] ^ d[i][0] ^ c[i][4] ^ c[i][24] ^ c[i][25] ^ c[i][26] ^ c[i][28] ^ c[i][29] ^ c[i][30]: 'd0;
    assign newcrc[i][13] = i_en ? d[i][7] ^ d[i][6] ^ d[i][5] ^ d[i][3] ^ d[i][2] ^ d[i][1] ^ c[i][5] ^ c[i][25] ^ c[i][26] ^ c[i][27] ^ c[i][29] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][14] = i_en ? d[i][7] ^ d[i][6] ^ d[i][4] ^ d[i][3] ^ d[i][2] ^ c[i][6] ^ c[i][26] ^ c[i][27] ^ c[i][28] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][15] = i_en ? d[i][7] ^ d[i][5] ^ d[i][4] ^ d[i][3] ^ c[i][7] ^ c[i][27] ^ c[i][28] ^ c[i][29] ^ c[i][31]: 'd0;
    assign newcrc[i][16] = i_en ? d[i][5] ^ d[i][4] ^ d[i][0] ^ c[i][8] ^ c[i][24] ^ c[i][28] ^ c[i][29]: 'd0;
    assign newcrc[i][17] = i_en ? d[i][6] ^ d[i][5] ^ d[i][1] ^ c[i][9] ^ c[i][25] ^ c[i][29] ^ c[i][30]: 'd0;
    assign newcrc[i][18] = i_en ? d[i][7] ^ d[i][6] ^ d[i][2] ^ c[i][10] ^ c[i][26] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][19] = i_en ? d[i][7] ^ d[i][3] ^ c[i][11] ^ c[i][27] ^ c[i][31]: 'd0;
    assign newcrc[i][20] = i_en ? d[i][4] ^ c[i][12] ^ c[i][28]: 'd0;
    assign newcrc[i][21] = i_en ? d[i][5] ^ c[i][13] ^ c[i][29]: 'd0;
    assign newcrc[i][22] = i_en ? d[i][0] ^ c[i][14] ^ c[i][24]: 'd0;
    assign newcrc[i][23] = i_en ? d[i][6] ^ d[i][1] ^ d[i][0] ^ c[i][15] ^ c[i][24] ^ c[i][25] ^ c[i][30]: 'd0;
    assign newcrc[i][24] = i_en ? d[i][7] ^ d[i][2] ^ d[i][1] ^ c[i][16] ^ c[i][25] ^ c[i][26] ^ c[i][31]: 'd0;
    assign newcrc[i][25] = i_en ? d[i][3] ^ d[i][2] ^ c[i][17] ^ c[i][26] ^ c[i][27]: 'd0;
    assign newcrc[i][26] = i_en ? d[i][6] ^ d[i][4] ^ d[i][3] ^ d[i][0] ^ c[i][18] ^ c[i][24] ^ c[i][27] ^ c[i][28] ^ c[i][30]: 'd0;
    assign newcrc[i][27] = i_en ? d[i][7] ^ d[i][5] ^ d[i][4] ^ d[i][1] ^ c[i][19] ^ c[i][25] ^ c[i][28] ^ c[i][29] ^ c[i][31]: 'd0;
    assign newcrc[i][28] = i_en ? d[i][6] ^ d[i][5] ^ d[i][2] ^ c[i][20] ^ c[i][26] ^ c[i][29] ^ c[i][30]: 'd0;
    assign newcrc[i][29] = i_en ? d[i][7] ^ d[i][6] ^ d[i][3] ^ c[i][21] ^ c[i][27] ^ c[i][30] ^ c[i][31]: 'd0;
    assign newcrc[i][30] = i_en ? d[i][7] ^ d[i][4] ^ c[i][22] ^ c[i][28] ^ c[i][31]: 'd0;
    assign newcrc[i][31] = i_en ? d[i][5] ^ c[i][23] ^ c[i][29]: 'd0;

    if(i > 0) begin
        assign c[i] = newcrc[i - 1];
    end

    
always@(posedge i_clk,posedge i_rst)
begin
  if(i_rst)
    ro_crc[i] <= 'd0;
  else 
    ro_crc[i] <= ~{
                  newcrc[i][0],newcrc[i][1],newcrc[i][2],newcrc[i][3],newcrc[i][4],newcrc[i][5],newcrc[i][6],newcrc[i][7],
                  newcrc[i][8],newcrc[i][9],newcrc[i][10],newcrc[i][11],newcrc[i][12],newcrc[i][13],newcrc[i][14],newcrc[i][15],
                  newcrc[i][16],newcrc[i][17],newcrc[i][18],newcrc[i][19],newcrc[i][20],newcrc[i][21],newcrc[i][22],newcrc[i][23],
                  newcrc[i][24],newcrc[i][25],newcrc[i][26],newcrc[i][27],newcrc[i][28],newcrc[i][29],newcrc[i][30],newcrc[i][31]
                  };
end
end
endgenerate

    


always@(posedge i_clk,posedge i_rst)
begin
  if(i_rst || !i_en)
    crc <= 32'hffffffff;
  else if(i_en)
    crc <= newcrc[7];
  else 
    crc <= crc;
end

endmodule
