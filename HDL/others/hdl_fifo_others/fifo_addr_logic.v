`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  www.netbric.com
// Engineer: liaotianyu
// 
// Create Date: 2014/05/28 12:06:14
// Design Name: bfifo 
// Module Name: fifo_addr_logic
// Project Name: 
// Target Devices: 
// Tool Versions: 
//
// Description: 
//       This code implements fifo addr process
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

module fifo_addr_logic #(
	parameter AWID       = 10
) (
  input 		    clk,                          // write clock
  input 		    rst,                          // write reset
  input 		    enb,                          // nfull control
  input 		    inc,                          // Write enable
(* max_fanout=100 *)output reg  [AWID-1:0]    addr                          // fifo_addr
);

//////////////////////////////////////////////////////////////////////////////////
//      mem instance
//////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or posedge rst) begin
		if( rst==1'b1 ) begin
				addr <= 0;
		end
		else begin
				if( inc==1'b1 && enb==1'b1 )begin
						addr <= addr + 1'b1;
				end
		end
end

endmodule

