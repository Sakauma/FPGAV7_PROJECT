`timescale 1ns / 1ps

(* FMSH_ATTR = "xadc_filter", DONT_TOUCH = "yes" *)module xadc_filter_wrapper #(
parameter INIT_40 = 16'h0000,//{11'dx,ch[4:0]}:if singal channel ,sel channel
parameter INIT_41 = 16'h2000,//{SEQ[3:0],12'hxxxx}:0011-single channel;else sequencer on
parameter INIT_48 = 16'h0000,//sequencer channel sel:temp/vccint/...
parameter INIT_49 = 16'h0000,//sequencer channel sel:vaux[n]
parameter INIT_4C = 16'h0000,//bit-11 : IS_BIPOLAR_VPVN
parameter INIT_4D = 16'h0000,//IS_BIPOLAR_VUAX[n]
parameter GLITCH_VALUE_TEMP     = 100,  //code number
parameter GLITCH_VALUE_VCCINT   = 200,  //code number
parameter GLITCH_VALUE_VCCAUX   = 200,  //code number
parameter GLITCH_VALUE_VPVN     = 400,  //code number
parameter GLITCH_VALUE_VREFP    = 200,  //code number
parameter GLITCH_VALUE_VREFN    = 200,  //code number
parameter GLITCH_VALUE_VCCBRAM  = 200,  //code number
parameter GLITCH_VALUE_VCCPINT  = 200,  //code number
parameter GLITCH_VALUE_VCCPAUX  = 200,  //code number
parameter GLITCH_VALUE_VCCODDR  = 200,  //code number
parameter GLITCH_VALUE_VAUX0    = 400,  //code number
parameter GLITCH_VALUE_VAUX1    = 400,  //code number
parameter GLITCH_VALUE_VAUX2    = 400,  //code number
parameter GLITCH_VALUE_VAUX3    = 400,  //code number
parameter GLITCH_VALUE_VAUX4    = 400,  //code number
parameter GLITCH_VALUE_VAUX5    = 400,  //code number
parameter GLITCH_VALUE_VAUX6    = 400,  //code number
parameter GLITCH_VALUE_VAUX7    = 400,  //code number
parameter GLITCH_VALUE_VAUX8    = 400,  //code number
parameter GLITCH_VALUE_VAUX9    = 400,  //code number
parameter GLITCH_VALUE_VAUX10   = 400,  //code number
parameter GLITCH_VALUE_VAUX11   = 400,  //code number
parameter GLITCH_VALUE_VAUX12   = 400,  //code number
parameter GLITCH_VALUE_VAUX13   = 400,  //code number
parameter GLITCH_VALUE_VAUX14   = 400,  //code number
parameter GLITCH_VALUE_VAUX15   = 400  //code number
)
(
input clk,reset,
input [6:0] xadc_daddr,
input xadc_den,

input din_valid,
input [11:0] din,

output reg dout_valid,
output reg [11:0] dout
);

localparam TEMP      = 7'h00;
localparam VCCINT    = 7'h01;
localparam VCCAUX    = 7'h02;
localparam VPVN      = 7'h03;
localparam VREFP     = 7'h04;
localparam VREFN     = 7'h05;
localparam VCCBRAM   = 7'h06;
localparam VCCPINT   = 7'h0D;
localparam VCCPAUX   = 7'h0E;
localparam VCCO_DDR   = 7'h0F;
localparam VAUX0     = 7'h10;
localparam VAUX1     = 7'h11;
localparam VAUX2     = 7'h12;
localparam VAUX3     = 7'h13;
localparam VAUX4     = 7'h14;
localparam VAUX5     = 7'h15;
localparam VAUX6     = 7'h16;
localparam VAUX7     = 7'h17;
localparam VAUX8     = 7'h18;
localparam VAUX9     = 7'h19;
localparam VAUX10    = 7'h1A;
localparam VAUX11    = 7'h1B;
localparam VAUX12    = 7'h1C;
localparam VAUX13    = 7'h1D;
localparam VAUX14    = 7'h1E;
localparam VAUX15    = 7'h1F;

//=============reset sync ===============
reg reset_r0,reset_r1,reset_r2;
wire reset_sync;
assign reset_sync = reset_r2;
always @ ( posedge clk or posedge reset )
begin
 if ( reset ) 
    begin
        reset_r0 <= 1'b1;
        reset_r1 <= 1'b1;
        reset_r2 <= 1'b1;
    end
 else 
    begin   
        reset_r0 <= 1'b0;
        reset_r1 <= reset_r0;
        reset_r2 <= reset_r1;
    end
end
//=============reset sync ===============

//=======xadc_daddr hold==============
// if user logic daddr only appear 1 clk,(sync with xadc_den)
reg [6:0] daddr_temp = 7'd0;
always @ ( posedge clk )
begin 
 if ( reset_sync )
    daddr_temp <= 7'd0;
 else if ( xadc_den )
    daddr_temp <= xadc_daddr;
 else daddr_temp <= daddr_temp;
end
//=======xadc_daddr hold==============

//======
reg din_valid_r0 = 1'b0;
always @ ( posedge clk )
begin 
 if ( reset_sync )
    din_valid_r0 <= 1'b0;
 else 
    din_valid_r0 <= din_valid;
end
//===================

wire dout_valid_temp,dout_valid_vccint,dout_valid_vccaux,dout_valid_vpvn;
wire dout_valid_vrefp,dout_valid_vrefn,dout_valid_vccbram;
wire dout_valid_vccpint,dout_valid_vccpaux,dout_valid_vccoddr;
wire dout_valid_vaux0,dout_valid_vaux1,dout_valid_vaux2,dout_valid_vaux3;
wire dout_valid_vaux4,dout_valid_vaux5,dout_valid_vaux6,dout_valid_vaux7;
wire dout_valid_vaux8,dout_valid_vaux9,dout_valid_vaux10,dout_valid_vaux11;
wire dout_valid_vaux12,dout_valid_vaux13,dout_valid_vaux14,dout_valid_vaux15;

wire [11:0] dout_temp,dout_vccint,dout_vccaux,dout_vpvn;
wire [11:0] dout_vrefp,dout_vrefn,dout_vccbram;
wire [11:0] dout_vccpint,dout_vccpaux,dout_vccoddr;
wire [11:0] dout_vaux0,dout_vaux1,dout_vaux2,dout_vaux3;
wire [11:0] dout_vaux4,dout_vaux5,dout_vaux6,dout_vaux7;
wire [11:0] dout_vaux8,dout_vaux9,dout_vaux10,dout_vaux11;
wire [11:0] dout_vaux12,dout_vaux13,dout_vaux14,dout_vaux15;

reg dout_valid_r = 1'b0;
reg [11:0] dout_r = 'd0;

always @ ( posedge clk )
begin 
 if ( reset_sync )
    begin   
        dout_valid   <= 1'b0;
        dout <= 'd0;
    end
 else if ( din_valid_r0 )
    begin   
        case ( daddr_temp )
            7'h00 : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h00 ) || (INIT_41[15:12] != 4'h3 && INIT_48[8])) 
                        begin dout_valid <= dout_valid_temp;      dout  <= dout_temp; end
                    else begin dout_valid <= 'd0;      dout  <= 'd0; end
                    end
            7'h01 : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h01 ) || (INIT_41[15:12] != 4'h3 && INIT_48[9]))
                        begin dout_valid <= dout_valid_vccint;    dout  <= dout_vccint; end
                    else begin dout_valid <= 'd0;       dout    <= 'd0; end
                    end
            7'h02 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h02 ) || (INIT_41[15:12] != 4'h3 && INIT_48[10])) 
                        begin dout_valid <= dout_valid_vccaux;    dout  <= dout_vccaux; end
                    else begin dout_valid   <= 'd0;     dout    <= 'd0; end
                    end
            7'h03 : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h03 ) || (INIT_41[15:12] != 4'h3 && INIT_48[11])) 
                        begin dout_valid <= dout_valid_vpvn;      dout  <= dout_vpvn; end
                    else begin dout_valid   <= 'd0;     dout    <= 'd0; end
                    end
            7'h04 : begin 
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h04 ) || (INIT_41[15:12] != 4'h3 && INIT_48[12])) 
                        begin dout_valid <= dout_valid_vrefp;     dout  <= dout_vrefp; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h05 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h05 ) || (INIT_41[15:12] != 4'h3 && INIT_48[13])) 
                        begin dout_valid <= dout_valid_vrefn;     dout  <= dout_vrefn; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h06 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h06 ) || (INIT_41[15:12] != 4'h3 && INIT_48[14])) 
                        begin dout_valid <= dout_valid_vccbram;   dout  <= dout_vccbram; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h0D : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h0D ) || (INIT_41[15:12] != 4'h3 && INIT_48[5])) 
                        begin dout_valid <= dout_valid_vccpint;   dout  <= dout_vccpint; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h0E : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h0E ) || (INIT_41[15:12] != 4'h3 && INIT_48[6])) 
                        begin dout_valid <= dout_valid_vccpaux;   dout  <= dout_vccpaux; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h0F : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h0F ) || (INIT_41[15:12] != 4'h3 && INIT_48[7])) 
                        begin dout_valid <= dout_valid_vccoddr;   dout  <= dout_vccoddr; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h10 : begin 
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h10 ) || (INIT_41[15:12] != 4'h3 && INIT_49[0])) 
                        begin dout_valid <= dout_valid_vaux0;     dout  <= dout_vaux0; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h11 : begin 
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h11 ) || (INIT_41[15:12] != 4'h3 && INIT_49[1])) 
                        begin dout_valid <= dout_valid_vaux1;     dout  <= dout_vaux1; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h12 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h12 ) || (INIT_41[15:12] != 4'h3 && INIT_49[2])) 
                        begin dout_valid <= dout_valid_vaux2;     dout  <= dout_vaux2; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h13 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h13 ) || (INIT_41[15:12] != 4'h3 && INIT_49[3])) 
                        begin dout_valid <= dout_valid_vaux3;     dout  <= dout_vaux3; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h14 : begin 
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h14 ) || (INIT_41[15:12] != 4'h3 && INIT_49[4])) 
		    	begin dout_valid <= dout_valid_vaux4;     dout  <= dout_vaux4; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h15 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h15 ) || (INIT_41[15:12] != 4'h3 && INIT_49[5])) 
                        begin dout_valid <= dout_valid_vaux5;     dout  <= dout_vaux5; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h16 : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h16 ) || (INIT_41[15:12] != 4'h3 && INIT_49[6])) 
                        begin dout_valid <= dout_valid_vaux6;     dout  <= dout_vaux6; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h17 : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h17 ) || (INIT_41[15:12] != 4'h3 && INIT_49[7])) 
                        begin dout_valid <= dout_valid_vaux7;     dout  <= dout_vaux7; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h18 : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h18 ) || (INIT_41[15:12] != 4'h3 && INIT_49[8])) 
                        begin dout_valid <= dout_valid_vaux8;     dout  <= dout_vaux8; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h19 : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h19 ) || (INIT_41[15:12] != 4'h3 && INIT_49[9])) 
                        begin dout_valid <= dout_valid_vaux9;     dout  <= dout_vaux9; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h1A : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1A ) || (INIT_41[15:12] != 4'h3 && INIT_49[10])) 
                        begin dout_valid <= dout_valid_vaux10;    dout  <= dout_vaux10; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h1B : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1B ) || (INIT_41[15:12] != 4'h3 && INIT_49[11])) 
                        begin dout_valid <= dout_valid_vaux11;    dout  <= dout_vaux11; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h1C : begin   
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1C ) || (INIT_41[15:12] != 4'h3 && INIT_49[12])) 
                        begin dout_valid <= dout_valid_vaux12;    dout  <= dout_vaux12; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h1D : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1D ) || (INIT_41[15:12] != 4'h3 && INIT_49[13])) 
                        begin dout_valid <= dout_valid_vaux13;    dout  <= dout_vaux13; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h1E : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1E ) || (INIT_41[15:12] != 4'h3 && INIT_49[14])) 
                        begin dout_valid <= dout_valid_vaux14;    dout  <= dout_vaux14; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            7'h1F : begin
                    if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1F ) || (INIT_41[15:12] != 4'h3 && INIT_49[15])) 
                        begin dout_valid <= dout_valid_vaux15;    dout  <= dout_vaux15; end
                    else begin dout_valid   <= 'd0; dout    <= 'd0; end
                    end
            default : begin dout_valid <= dout_valid;    dout  <= dout; end
        endcase
    end
 else 
    begin
        dout_valid   <= 1'b0;
        dout <= dout;
    end
end

//temp
generate if ( (INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h00 ) || (INIT_41[15:12] != 4'h3 && INIT_48[8]) )
begin : u_temp
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_TEMP)
    )
    inst_filter_temp(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == TEMP)),
     .din(din),
     .dout_valid (dout_valid_temp),
     .dout(dout_temp)
    );
end
endgenerate

//vccint
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h01 ) || (INIT_41[15:12] != 4'h3 && INIT_48[9]))
begin : u_vccint
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VCCINT)
    )
    inst_filter_vccint(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VCCINT)),
     .din(din),
     .dout_valid (dout_valid_vccint),
     .dout(dout_vccint)
    );
end
endgenerate

//vccaux
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h02 ) || (INIT_41[15:12] != 4'h3 && INIT_48[10]))
begin : u_vccaux
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VCCAUX)
    )
    inst_filter_vccaux(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VCCAUX)),
     .din(din),
     .dout_valid (dout_valid_vccaux),
     .dout(dout_vccaux)
    );
end
endgenerate

//vpvn
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h03 ) || (INIT_41[15:12] != 4'h3 && INIT_48[11]))
begin : u_vpvn
    filter #(
     //.IS_BIPOLAR(IS_BIPOLAR_VPVN),
     .IS_BIPOLAR(INIT_4C[11]),
     .GLITCH_VALUE(GLITCH_VALUE_VPVN)
    )
    inst_filter_vpvn(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VPVN)),
     .din(din),
     .dout_valid (dout_valid_vpvn),
     .dout(dout_vpvn)
    );
end
endgenerate

//vrefp
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h04 ) || (INIT_41[15:12] != 4'h3 && INIT_48[12]))
begin : u_vrefp
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VREFP)
    )
    inst_filter_vrefp(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VREFP)),
     .din(din),
     .dout_valid (dout_valid_vrefp),
     .dout(dout_vrefp)
    );
end
endgenerate 

//vrefn
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h05 ) || (INIT_41[15:12] != 4'h3 && INIT_48[13]))
begin : u_vrefn
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VREFN)
    )
    inst_filter_vrefn(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VREFN)),
     .din(din),
     .dout_valid (dout_valid_vrefn),
     .dout(dout_vrefn)
    );
end
endgenerate 

//vccbram
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h06 ) || (INIT_41[15:12] != 4'h3 && INIT_48[14]))
begin : u_vccbram
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VCCBRAM)
    )
    inst_filter_vccbram(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VCCBRAM)),
     .din(din),
     .dout_valid (dout_valid_vccbram),
     .dout(dout_vccbram)
    );
end
endgenerate 

//vccpint
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h0D ) || (INIT_41[15:12] != 4'h3 && INIT_48[5]))
begin : u_vccpint
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VCCPINT)
    )
    inst_filter_vccpint(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VCCPINT)),
     .din(din),
     .dout_valid (dout_valid_vccpint),
     .dout(dout_vccpint)
    );
end
endgenerate 

//vccpaux
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h0E ) || (INIT_41[15:12] != 4'h3 && INIT_48[6]))
begin : u_vccpaux
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VCCPAUX)
    )
    inst_filter_vccpaux(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VCCPAUX)),
     .din(din),
     .dout_valid (dout_valid_vccpaux),
     .dout(dout_vccpaux)
    );
end
endgenerate 

//vcco_ddr
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h0F ) || (INIT_41[15:12] != 4'h3 && INIT_48[7]))
begin : u_vcco_ddr
    filter #(
     .IS_BIPOLAR(0),
     .GLITCH_VALUE(GLITCH_VALUE_VCCODDR)
    )
    inst_filter_vccoddr(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VCCO_DDR)),
     .din(din),
     .dout_valid (dout_valid_vccoddr),
     .dout(dout_vccoddr)
    );
end
endgenerate 

//vaux0
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h10 ) || (INIT_41[15:12] != 4'h3 && INIT_49[0]))
begin : u_vaux0
    filter #(
     .IS_BIPOLAR(INIT_4D[0]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX0)
    )
    inst_filter_vaux0(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX0)),
     .din(din),
     .dout_valid (dout_valid_vaux0),
     .dout(dout_vaux0)
    );
end
endgenerate 

//vaux1
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h11 ) || (INIT_41[15:12] != 4'h3 && INIT_49[1]))
begin : u_vaux1
    filter #(
     .IS_BIPOLAR(INIT_4D[1]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX1)
    )
    inst_filter_vaux1(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX1)),
     .din(din),
     .dout_valid (dout_valid_vaux1),
     .dout(dout_vaux1)
    );
end
endgenerate 

//vaux2
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h12 ) || (INIT_41[15:12] != 4'h3 && INIT_49[2]))
begin : u_vaux2
    filter #(
     .IS_BIPOLAR(INIT_4D[2]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX2)
    )
    inst_filter_vaux2(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX2)),
     .din(din),
     .dout_valid (dout_valid_vaux2),
     .dout(dout_vaux2)
    );
end
endgenerate

//vaux3
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h13 ) || (INIT_41[15:12] != 4'h3 && INIT_49[3]))
begin : u_vaux3
    filter #(
     .IS_BIPOLAR(INIT_4D[3]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX3)
    )
    inst_filter_vaux3(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX3)),
     .din(din),
     .dout_valid (dout_valid_vaux3),
     .dout(dout_vaux3)
    );
end
endgenerate 

//vaux4
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h14 ) || (INIT_41[15:12] != 4'h3 && INIT_49[4]))
begin : u_vaux4
    filter #(
     .IS_BIPOLAR(INIT_4D[4]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX4)
    )
    inst_filter_vaux4(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX4)),
     .din(din),
     .dout_valid (dout_valid_vaux4),
     .dout(dout_vaux4)
    );
end
endgenerate 

//vaux5
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h15 ) || (INIT_41[15:12] != 4'h3 && INIT_49[5]))
begin : u_vaux5
    filter #(
     .IS_BIPOLAR(INIT_4D[5]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX5)
    )
    inst_filter_vaux5(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX5)),
     .din(din),
     .dout_valid (dout_valid_vaux5),
     .dout(dout_vaux5)
    );
end
endgenerate 

//vaux6
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h16 ) || (INIT_41[15:12] != 4'h3 && INIT_49[6]))
begin : u_vaux6
    filter #(
     .IS_BIPOLAR(INIT_4D[6]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX6)
    )
    inst_filter_vaux6(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX6)),
     .din(din),
     .dout_valid (dout_valid_vaux6),
     .dout(dout_vaux6)
    );
end
endgenerate 

//vaux7
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h17 ) || (INIT_41[15:12] != 4'h3 && INIT_49[7]))
begin : u_vaux7
    filter #(
     .IS_BIPOLAR(INIT_4D[7]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX7)
    )
    inst_filter_vaux7(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX7)),
     .din(din),
     .dout_valid (dout_valid_vaux7),
     .dout(dout_vaux7)
    );
end
endgenerate 

//vaux8
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h18 ) || (INIT_41[15:12] != 4'h3 && INIT_49[8]))
begin : u_vaux8
    filter #(
     .IS_BIPOLAR(INIT_4D[8]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX8)
    )
    inst_filter_vaux8(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX8)),
     .din(din),
     .dout_valid (dout_valid_vaux8),
     .dout(dout_vaux8)
    );
end
endgenerate

//vaux9
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h19 ) || (INIT_41[15:12] != 4'h3 && INIT_49[9]))
begin : u_vaux9
    filter #(
     .IS_BIPOLAR(INIT_4D[9]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX9)
    )
    inst_filter_vaux9(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX9)),
     .din(din),
     .dout_valid (dout_valid_vaux9),
     .dout(dout_vaux9)
    );
end
endgenerate 

//vaux10
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1A ) || (INIT_41[15:12] != 4'h3 && INIT_49[10]))
begin : u_vaux10
    filter #(
     .IS_BIPOLAR(INIT_4D[10]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX10)
    )
    inst_filter_vaux10(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX10)),
     .din(din),
     .dout_valid (dout_valid_vaux10),
     .dout(dout_vaux10)
    );
end
endgenerate 

//vaux11
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1B ) || (INIT_41[15:12] != 4'h3 && INIT_49[11]))
begin : u_vaux11
    filter #(
     .IS_BIPOLAR(INIT_4D[11]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX11)
    )
    inst_filter_vaux11(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX11)),
     .din(din),
     .dout_valid (dout_valid_vaux11),
     .dout(dout_vaux11)
    );
end
endgenerate 

//vaux12
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1C ) || (INIT_41[15:12] != 4'h3 && INIT_49[12]))
begin : u_vaux12
    filter #(
     .IS_BIPOLAR(INIT_4D[12]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX12)
    )
    inst_filter_vaux12(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX12)),
     .din(din),
     .dout_valid (dout_valid_vaux12),
     .dout(dout_vaux12)
    );
end
endgenerate 

//vaux13
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1D ) || (INIT_41[15:12] != 4'h3 && INIT_49[13]))
begin : u_vaux13
    filter #(
     .IS_BIPOLAR(INIT_4D[13]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX13)
    )
    inst_filter_vaux13(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX13)),
     .din(din),
     .dout_valid (dout_valid_vaux13),
     .dout(dout_vaux13)
    );
end
endgenerate 

//vaux14
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1E ) || (INIT_41[15:12] != 4'h3 && INIT_49[14]))
begin : u_vaux14
    filter #(
     .IS_BIPOLAR(INIT_4D[14]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX14)
    )
    inst_filter_vaux14(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX14)),
     .din(din),
     .dout_valid (dout_valid_vaux14),
     .dout(dout_vaux14)
    );
end
endgenerate 

//vaux15
generate if ((INIT_41[15:12] == 4'h3 && INIT_40[4:0] == 5'h1F ) || (INIT_41[15:12] != 4'h3 && INIT_49[15]))
begin : u_vaux15
    filter #(
     .IS_BIPOLAR(INIT_4D[15]),
     .GLITCH_VALUE(GLITCH_VALUE_VAUX15)
    )
    inst_filter_vaux15(
     .clk (clk),
     .reset (reset_sync),
     .din_valid (din_valid&&(daddr_temp == VAUX15)),
     .din(din),
     .dout_valid (dout_valid_vaux15),
     .dout(dout_vaux15)
    );
end
endgenerate 

endmodule
