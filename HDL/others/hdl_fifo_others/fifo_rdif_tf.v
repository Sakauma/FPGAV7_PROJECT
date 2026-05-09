//////////////////////////////////////////////////////////////////////////////////
// Company:  www.netbric.com
// Engineer: liaotianyu
// 
// Create Date: 2014/05/28 12:06:14
// Design Name: toe
// Module Name: fifo_rdif_tf.v
// Project Name: 
// Target Devices: 
// Tool Versions: 
//
// Description: 
//       This code implement transform from fifo reg interface to fifo non-reg interface;
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
// Revision 0.01 - File Modifid
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module fifo_rdif_tf #(
        parameter DWID       = 18, 
        parameter AWID       = 10
) (
  //old
        input                     clk,                          // Read clock
        input                     rst,                          // Read reset 
  //old read interface
        output reg                old_ren,                           // Read Enable
        input  [DWID-1:0]         old_rdata,                         // RAM output data
        input                     old_nempty,                        // 

  //new read interface
        input                     new_ren,                           // Read Enable
        output     [DWID-1:0]     new_rdata,                         // RAM output data
        output reg                new_empty,                        // 
        output reg                new_nempty,                        // 
        output reg                new_roverflow                      // 
);

//////////////////////////////////////////////////////////////////////////////////
//      
//////////////////////////////////////////////////////////////////////////////////
always@( * )begin
        if ( old_nempty==1'b1 && new_nempty==1'b0 ) begin
                old_ren = 1'b1;
        end
        else if( old_nempty==1'b1 && new_ren==1'b1 ) begin
                old_ren = 1'b1;
        end
        else begin
                old_ren = 1'b0;
        end
end

always@( posedge clk or posedge rst )begin
        if( rst==1'b1 ) begin
                new_empty <= 1'b1;
                new_nempty <= 1'b0;
        end
        else begin
                if( old_ren==1'b1 ) begin // old fifo is read
                        new_empty <= 1'b0;
                        new_nempty <= 1'b1;
                end
                else if( new_ren==1'b1 )begin //new fifo is read and old fifo is empty
                        new_empty <= 1'b1;
                        new_nempty <= 1'b0;
                end
        end
end

(* max_fanout=100 *)reg                old_ren_dly;
reg [DWID-1:0]     old_rdata_latch	=	0	;           // RAM output latch

///////////for timing opt,the old_rdata_latch's rst is removed
always@( posedge clk or posedge rst )begin
        if( rst==1'b1 ) begin
                old_ren_dly <= 1'b0;
                //old_rdata_latch <= 0;
        end
        else begin
                old_ren_dly <= old_ren;
                //if( old_ren_dly==1'b1 ) begin
                //        old_rdata_latch <= old_rdata;
                //end
        end
end

always@( posedge clk  )begin

    if( old_ren_dly==1'b1 ) begin
            old_rdata_latch <= old_rdata;
    end

end
//////////

assign new_rdata = (old_ren_dly==1'b1) ? old_rdata : old_rdata_latch;


always@( posedge clk or posedge rst )begin
        if( rst==1'b1 ) begin
                new_roverflow <= 1'b0;
        end
        else begin
                if( new_ren==1'b1 && new_nempty==1'b0 ) begin // fifo is empty and read
                        new_roverflow <= 1'b1;
                        /* synthesis translate_off */
                        $display("%t, %m, ERROR: roverflow happen", $time );
                        #100;
                        $stop;
                        /* synthesis translate_on */
                end
        end
end

endmodule

