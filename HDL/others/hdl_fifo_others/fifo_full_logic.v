`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  www.netbric.com
// Engineer: liaotianyu
// 
// Create Date: 2014/05/28 12:06:14
// Design Name: bfifo 
// Module Name: fifo_full_logic
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

module fifo_full_logic #(
	parameter AWID             = 10   ,
	parameter AFULL_TH         = 4    ,
    parameter FLAG_ENABLE_STOP = 1'b1  
) (
  input 					wclk,                           // write clock
  input 					wrst,                           // write reset
  input 					wen ,                           // write enable
  input  [AWID-1:0]			waddr,                          // write addr 
  input  [AWID-1:0]			raddr,                          // read  addr
  output reg                full,                          // 
  output reg                nfull,                          // 
  output reg                afull,                         // 
  output reg                nafull,                         // 
  output reg                woverflow,                      // 
  output reg [AWID:0]       cnt_free                        // cnt of free space
);

//////////////////////////////////////////////////////////////////////////////////
//       signal define
//////////////////////////////////////////////////////////////////////////////////
reg  [AWID-1:0]			raddr_dly;                         //the last raddr
wire [AWID-1:0]         cnt_free_comb;

assign cnt_free_comb = raddr - waddr;
//////////////////////////////////////////////////////////////////////////////////
//       raddr_dly process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge wclk or posedge wrst) begin
		if( wrst==1'b1 ) begin
				raddr_dly <= 0;
		end
		else begin
				raddr_dly <= raddr;
		end
end


//////////////////////////////////////////////////////////////////////////////////
//       nfull process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge wclk or posedge wrst) begin
		if( wrst==1'b1 ) begin
				full <= 1'b0;
				nfull <= 1'b1;
		end
		else begin
				if( wen==1'b1 && cnt_free_comb==1 )begin  //the num of free space is 1 and it is used by wen
						full <= 1'b1;
						nfull <= 1'b0;
				end
				else if( raddr!=raddr_dly ) begin
						full <= 1'b0;
						nfull <= 1'b1;
				end
		end
end

//////////////////////////////////////////////////////////////////////////////////
//       nafull process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge wclk or posedge wrst) begin
		if( wrst==1'b1 ) begin
				afull <= 1'b0;
				nafull <= 1'b1;
		end
		else begin
				if( cnt_free_comb < AFULL_TH  && cnt_free_comb!=0 || nfull==1'b0 )begin  //the num of free space is less than AFULL_TH  and it is used by wen
						afull <= 1'b1;
						nafull <= 1'b0;
				end
				else if( raddr!=raddr_dly ) begin
						afull <= 1'b0;
						nafull <= 1'b1;
				end
		end
end

//////////////////////////////////////////////////////////////////////////////////
//       woverflow process
//////////////////////////////////////////////////////////////////////////////////
//wire flag_enable_stop;
//assign flag_enable_stop = 1'b1;
always@(posedge wclk or posedge wrst) begin
        if( wrst==1'b1 ) begin
                woverflow <= 1'b0;
        end
        else begin
                if( wen==1'b1 && nfull==1'b0 )begin
                        woverflow <= 1'b1;
                        /* synthesis translate_off */
                        $error("%t, %m, ERROR: woverflow happen", $time );
                        #1000;
                        if( FLAG_ENABLE_STOP==1'b1 ) begin
                                $stop;
                        end
                        /* synthesis translate_on */
                end
        end
end


//////////////////////////////////////////////////////////////////////////////////
//       cnt_used process
//////////////////////////////////////////////////////////////////////////////////
always@(posedge wclk or posedge wrst) begin
		if( wrst==1'b1 ) begin
				cnt_free <= 2**AWID;
		end
		else begin
				if( waddr==raddr && nfull==1'b1 )begin //fifo is full
						cnt_free <= 2**AWID;
				end
				else begin
						cnt_free <= cnt_free_comb;
				end
		end
end

endmodule

