`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  www.netbric.com
// Engineer: liaotianyu
// 
// Create Date: 2014/05/28 12:06:14
// Design Name: bfifo 
// Module Name: fifo_empty_logic
// Project Name: 
// Target Devices: 
// Tool Versions: 
//
// Description: 
//       This code implements fifo full process
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

module fifo_empty_logic #(
	parameter AWID             = 10   ,
	parameter AEMPTY_TH        = 4    ,
    parameter FLAG_ENABLE_STOP = 1'b1
) (
  input 					rclk,                           // write clock
  input 					rrst,                           // write reset
  input 					ren ,                           // write enable
  input  [AWID-1:0]			raddr,                          // write addr 
  input  [AWID-1:0]			waddr,                          // read  addr                       // 
  output reg                nempty,                          // 
  output reg                aempty,                         // 
  output reg                naempty,                         // 
  output reg                roverflow,                      // 
  output reg [AWID:0]       cnt_used                        // cnt of used space
);

//////////////////////////////////////////////////////////////////////////////////
//       signal define
//////////////////////////////////////////////////////////////////////////////////
reg  [AWID-1:0]			waddr_dly;                         //the last raddr
wire [AWID-1:0]         cnt_used_comb;
assign cnt_used_comb = waddr - raddr;

//////////////////////////////////////////////////////////////////////////////////
//       raddr_dly process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge rclk or posedge rrst) begin
		if( rrst==1'b1 ) begin
				waddr_dly <= 0;
		end
		else begin
				waddr_dly <= waddr;
		end
end


//////////////////////////////////////////////////////////////////////////////////
//       nempty process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge rclk or posedge rrst) begin
		if( rrst==1'b1 ) begin
				nempty <= 1'b0;
		end
		else begin
				if( ren==1'b1 && cnt_used_comb==1 )begin  //the num of used space is 1 and it is used by ren
						nempty <= 1'b0;
				end
				else if( waddr!=waddr_dly ) begin
						nempty <= 1'b1;
				end
		end
end

//////////////////////////////////////////////////////////////////////////////////
//       naempty process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge rclk or posedge rrst) begin
		if( rrst==1'b1 ) begin
				aempty <= 1'b1;
				naempty <= 1'b0;
		end
		else begin
				if( cnt_used_comb < AEMPTY_TH  && cnt_used_comb!=0 || nempty==1'b0 )begin  //the num of used space is less than AFULL_TH  and it is used by ren
						aempty <= 1'b1;
						naempty <= 1'b0;
				end
				else if( waddr!=waddr_dly ) begin
						aempty <= 1'b0;
						naempty <= 1'b1;
				end
		end
end

//////////////////////////////////////////////////////////////////////////////////
//       roverflow process
//////////////////////////////////////////////////////////////////////////////////
//wire flag_enable_stop;
//assign flag_enable_stop = 1'b1;
always@(posedge rclk or posedge rrst) begin
        if( rrst==1'b1 ) begin
                roverflow <= 1'b0;
        end
        else begin
                if( ren==1'b1 && nempty==1'b0 )begin
                        roverflow <= 1'b1;
                        /* synthesis translate_off */
                        $error("%t, %m, ERROR: roverflow happen", $time );
                        #1000;
                        if( FLAG_ENABLE_STOP==1'b1 ) begin
                                $stop;
                        end
                        /* synthesis translate_on */
                end
        end
end


//////////////////////////////////////////////////////////////////////////////////
//       cnt_free process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge rclk or posedge rrst) begin
		if( rrst==1'b1 ) begin
			cnt_used <= 0;
		end
		else begin
				if( waddr==raddr && nempty==1'b1 )begin //fifo is full
						cnt_used <= 2**AWID;
				end
				else begin
						cnt_used <= cnt_used_comb;
				end
		end
end

endmodule

