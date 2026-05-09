`timescale 1ns / 1ps
(* FMSH_ATTR = "xadc_filter", DONT_TOUCH = "yes" *)module filter #(
parameter IS_BIPOLAR = 0,
parameter GLITCH_VALUE = 100  //code number
)
(
input clk,reset,
input din_valid,
input [11:0] din,
//output reg [11:0] data_r0,data_r1,data_r2,
output reg dout_valid,
output reg [11:0] dout
);

//localparam TEMP      = 7'h00;
//localparam VCCINT    = 7'h01;
//localparam VCCAUX    = 7'h02;
//localparam VPVN      = 7'h03;
//localparam VREFP     = 7'h04;
//localparam VREFN     = 7'h05;
//localparam VCCBRAM   = 7'h06;
//localparam VAUX0     = 7'h10;
//localparam VAUX1     = 7'h11;
//localparam VAUX2     = 7'h12;
//localparam VAUX3     = 7'h13;
//localparam VAUX4     = 7'h14;
//localparam VAUX5     = 7'h15;
//localparam VAUX6     = 7'h16;
//localparam VAUX7     = 7'h17;
//localparam VAUX8     = 7'h18;
//localparam VAUX9     = 7'h19;
//localparam VAUX10    = 7'h1A;
//localparam VAUX11    = 7'h1B;
//localparam VAUX12    = 7'h1C;
//localparam VAUX13    = 7'h1D;
//localparam VAUX14    = 7'h1E;
//localparam VAUX15    = 7'h1F;

reg [11:0] data_r0,data_r1,data_r2;

//reg reset_r;
wire reset_sync;
assign reset_sync = reset;
//assign reset_sync = reset_r;
//always @ ( posedge clk or posedge reset )
//begin 
// if ( reset ) reset_r <= 1'b1;
// else reset_r <= 1'b0;
//end

always @ ( posedge clk )
begin 
 if ( reset_sync )
   dout_valid   <= 1'b0;
 else dout_valid <= din_valid;
end

reg first_data_flag = 1'b1;
always @ ( posedge clk )
begin
 if ( reset_sync )
  first_data_flag <= 1'b1;
 else if ( din_valid )
  first_data_flag <= 1'b0;
 else first_data_flag <= first_data_flag;
end

always @ ( posedge clk )
begin 
 if ( reset_sync )
  begin 
   data_r0 <= 12'd0;
   data_r1 <= 12'd0;
   data_r2 <= 12'd0;
  end
 else if ( din_valid )
  begin
   if ( first_data_flag )
    begin 
     data_r0 <= din;
     data_r1 <= din;
     data_r2 <= din;
    end
   else 
    begin 
     data_r0 <= din;
     data_r1 <= data_r0;
     data_r2 <= data_r1;
    end
  end
 else 
  begin
   data_r0 <= data_r0;
   data_r1 <= data_r1;
   data_r2 <= data_r2;
  end
end

always @ ( posedge clk )
begin 
 if (reset_sync)  
  begin 
   dout <= 12'd0;
  end
 else if ( din_valid ) 
  begin 
   if ( first_data_flag ) 
    dout <= din;
   else 
    begin 
     if ( IS_BIPOLAR == 1'b0 )
      begin 
       if ((data_r2>=data_r1)&&((data_r2-data_r1)>=GLITCH_VALUE))
        dout <= data_r0;
       else if ((data_r1>=data_r2)&&((data_r1-data_r2)>=GLITCH_VALUE))
        dout <= data_r0;
       else dout <= data_r2;
      end
     else
      begin 
       case ({data_r0[11],data_r1[11],data_r2[11]})
        3'b000,3'b111 : begin 
         if (((data_r2>=data_r1)&&((data_r2-data_r1)>=GLITCH_VALUE)) || ((data_r1>=data_r2)&&((data_r1-data_r2)>=GLITCH_VALUE)))
          dout <= data_r0;
         else dout <= data_r2;
         end
        3'b001 : begin 
         if ((data_r1+(~data_r2)+1)>=GLITCH_VALUE) 
          dout <= data_r0;
         else dout <= data_r2;
         end
        3'b010 : begin 
         if ((data_r2+(~data_r1)+1)>=GLITCH_VALUE)
          dout <= data_r0;
         else dout <= data_r2;
         end
        3'b011 : begin 
         if (((data_r2>=data_r1)&&((data_r2-data_r1)>=GLITCH_VALUE)) || ((data_r1>=data_r2)&&((data_r1-data_r2)>=GLITCH_VALUE)))
          dout <= data_r0;
         else dout <= data_r2;
         end
        3'b100 : begin 
         if (((data_r2>=data_r1)&&((data_r2-data_r1)>=GLITCH_VALUE)) || ((data_r1>=data_r2)&&((data_r1-data_r2)>=GLITCH_VALUE)))
          dout <= data_r0;
         else dout <= data_r2;
         end
        3'b101 : begin
         if ((data_r1+(~data_r2)+1)>=GLITCH_VALUE) 
          dout <= data_r0;
         else dout <= data_r2;
         end
        3'b110 : begin
         if ((data_r2+(~data_r1)+1)>=GLITCH_VALUE)
          dout <= data_r0;
         else dout <= data_r2;
         end
        default : dout <= data_r2;
       endcase
      end
    end
  end
 else dout <= dout;
end

endmodule
