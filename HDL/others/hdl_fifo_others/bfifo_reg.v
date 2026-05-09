//////////////////////////////////////////////////////////////////////////////////
// Company:  www.netbric.com
// Engineer: liaotianyu
// 
// Create Date: 2014/05/28 12:06:14
// Design Name: toe
// Module Name: async_bfifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
//
// Description: 
//       This code implements a parameterized single-clock fifo by block ram or distribute ram;
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created by 2014/05/30
// Additional Comments:
//
// Revision 0.01 - File Modifid
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module bfifo_reg #(
    	parameter RAM_STYLE  = "distributed",              // Specify RAM style: auto/block/distributed
	parameter DWID       = 18, 
	parameter AWID       = 10, 
	parameter AFULL_TH   = 4, 
	parameter AEMPTY_TH  = 4, 
	parameter DBG_WID    = 32 
) (
  input 		    clk,                           // write clock
  input 		    rst,                           // write reset
  input 		    wen,                           // Write enable
  input  [DWID-1:0]   	    wdata,                         // RAM input data
  output                    full,                         // 
  output                    nfull,                         // 
  output                    afull,                         // 
  output                    nafull,                        // 
  output                    woverflow,                     // 
  output [AWID:0]           cnt_free,                      // the counter used in fifo for read clock domain 
  input                     ren,                           // Read Enable
  output [DWID-1:0]         rdata,                         // RAM output data
  output                    nempty,                        // 
  output                    aempty,                       // 
  output                    naempty,                       // 
  output                    roverflow,                     // 
  output [AWID:0]           cnt_used ,                     // the counter used in fifo for write clock domain
  output [DBG_WID-1:0]      dbg_sig                        // debug signal
);

//////////////////////////////////////////////////////////////////////////////////
//      signal declare
//////////////////////////////////////////////////////////////////////////////////
//generate
//begin
//    if(RAM_STYLE == "distributed")
//    begin
//    end
//    else
//    begin
//        wire [AWID-1:0] waddr;
//    end
//end
//endgenerate
(*max_fanout = 100*)   wire [AWID-1:0] waddr;
wire [AWID-1:0] raddr;

//////////////////////////////////////////////////////////////////////////////////
//      mem instance
//////////////////////////////////////////////////////////////////////////////////
sdp_ram #(
	.RAM_STYLE ( RAM_STYLE ),
	.DWID      ( DWID      ), 
	.AWID      ( AWID      ), 
	.DBG_WID   ( DBG_WID   ) 
) inst_sdp_ram (
    .clk     (  clk         ),         // Write clock
    .waddr   (  waddr       ),         // Write address bus, width determined from RAM_DEPTH
    .wen     (  wen         ),         // Write enable
    .wdata   (  wdata       ),         // RAM input data
    .raddr   (  raddr       ),         // Read address bus, width determined from RAM_DEPTH
    .ren     (  ren         ),         // Read Enable, for additional power savings, disable when not in use
    .rdata   (  rdata       ),         // RAM output data
    .dbg     (              )          // debug signal
);

//////////////////////////////////////////////////////////////////////////////////
//     waddr logic instance 
//////////////////////////////////////////////////////////////////////////////////
fifo_addr_logic #(
	.AWID (AWID)
	)
inst_waddr(
	.clk         ( clk      ),
	.rst         ( rst      ),
	.enb         (nfull     ),
	.inc         (wen       ),
	.addr        (waddr     )
	);

//////////////////////////////////////////////////////////////////////////////////
//     raddr logic instance 
//////////////////////////////////////////////////////////////////////////////////
fifo_addr_logic #(
	.AWID (AWID)
	)
inst_raddr(
	.clk         ( clk      ),
	.rst         ( rst      ),
	.enb         (nempty    ),
	.inc         (ren       ),
	.addr        (raddr     )
	);

//////////////////////////////////////////////////////////////////////////////////
//     full logic instance
//////////////////////////////////////////////////////////////////////////////////
fifo_full_logic #(
	.AWID        ( AWID       ),
	.AFULL_TH    ( AFULL_TH   )
	)
inst_full_logic(
	.wclk        ( clk        ),
	.wrst        ( rst        ),
	.wen         ( wen        ),
	.waddr       ( waddr      ),
	.raddr       ( raddr      ),
	.full        ( full       ),
	.nfull       ( nfull      ),
	.afull       ( afull      ),
	.nafull      ( nafull     ),
	.woverflow   ( woverflow  ),
	.cnt_free    ( cnt_free   )
	);

//////////////////////////////////////////////////////////////////////////////////
//     empty logic instance
//////////////////////////////////////////////////////////////////////////////////
fifo_empty_logic #(
	.AWID        ( AWID       ),
	.AEMPTY_TH   ( AEMPTY_TH  )
	)
inst_empty_logic(
	.rclk       ( clk        ),
	.rrst       ( rst        ),
	.ren        ( ren        ),
	.raddr      ( raddr      ),
	.waddr      ( waddr      ),
	.nempty     ( nempty     ),
	.aempty     ( aempty     ),
	.naempty    ( naempty    ),
	.roverflow  ( roverflow  ),
	.cnt_used   ( cnt_used   )
	);

//////////////////////////////////////////////////////////////////////////////////
//  debug sig
//////////////////////////////////////////////////////////////////////////////////
assign dbg_sig = { 28'h0, woverflow, roverflow, nafull, nempty };

endmodule

