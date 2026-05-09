//////////////////////////////////////////////////////////////////////////////////
// Company:  www.netbric.com
// Engineer: liaotianyu
// 
// Create Date: 2014/05/28 12:06:14
// Design Name: toe
// Module Name: sdp_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
//
// Description: 
//       This code implements a paramtizable SDP dual clock memory by block ram or distribute ram;
//       Xilinx Simple Dual Port 2 Clock RAM
//       This code implements a paramtizable SDP dual clock memory.
//       If a reset or enable is not necessary, it may be tied off or removed from the code.
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

module sdp_ram #(
    parameter RAM_STYLE  = "distributed",                  // Specify RAM style: auto/block/distributed
	parameter DWID       = 18, 
	parameter AWID       = 10, 
        parameter INIT_FILE  = "",                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	parameter DBG_WID    = 32 
) (
  input 					clk,                           // clock
  input  [AWID-1:0]	        waddr,                         // Write address bus, width determined from RAM_DEPTH
  input 					wen,                           // Write enable
  input  [DWID-1:0]   	    wdata,                         // RAM input data
  input  [AWID-1:0]         raddr,                         // Read address bus, width determined from RAM_DEPTH
  input                     ren,                           // Read Enable, for additional power savings, disable when not in use
  output [DWID-1:0]         rdata,                         // RAM output data
  output [DBG_WID-1:0]      dbg                            // debug signal
);

//////////////////////////////////////////////////////////////////////////////////
//      mem instance
//////////////////////////////////////////////////////////////////////////////////
generate
if( RAM_STYLE=="block" ) begin : bram
  xilinx_simple_dual_port_1_clock_bram #(
    .RAM_WIDTH(DWID),                  // Specify RAM data width
    .RAM_DEPTH(2**AWID),            // Specify RAM depth (number of entires)
    .RAM_PERFORMANCE("LOW_LATENCY"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(INIT_FILE)                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_sync_sdp_ram (
    .addra(waddr),    // Write address bus, width determined from RAM_DEPTH
    .addrb(raddr),    // Read address bus, width determined from RAM_DEPTH
    .dina(wdata),     // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Write clock
    .wea(wen),        // Write enable
    .enb(ren),        // Read Enable, for additional power savings, disable when not in use
    .rstb(1'b0),         // Output reset (does not affect memory contents)
    .regceb(1'b0),       // Output register enable
    .doutb(rdata)     // RAM output data, width determined from RAM_WIDTH
  );
end
else if( RAM_STYLE=="distributed" ) begin : dram
  xilinx_simple_dual_port_1_clock_dram #(
    .RAM_WIDTH(DWID),                  // Specify RAM data width
    .RAM_DEPTH(2**AWID),            // Specify RAM depth (number of entires)
    .RAM_PERFORMANCE("LOW_LATENCY"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(INIT_FILE)                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_sync_sdp_ram (
    .addra(waddr),    // Write address bus, width determined from RAM_DEPTH
    .addrb(raddr),    // Read address bus, width determined from RAM_DEPTH
    .dina(wdata),     // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Write clock
    .wea(wen),        // Write enable
    .enb(ren),        // Read Enable, for additional power savings, disable when not in use
    .rstb(1'b0),         // Output reset (does not affect memory contents)
    .regceb(1'b0),       // Output register enable
    .doutb(rdata)     // RAM output data, width determined from RAM_WIDTH
  );
end
else begin : auto
  xilinx_simple_dual_port_1_clock_ram #(
    .RAM_WIDTH(DWID),                  // Specify RAM data width
    .RAM_DEPTH(2**AWID),            // Specify RAM depth (number of entires)
    .RAM_PERFORMANCE("LOW_LATENCY"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(INIT_FILE)                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_sync_sdp_ram (
    .addra(waddr),    // Write address bus, width determined from RAM_DEPTH
    .addrb(raddr),    // Read address bus, width determined from RAM_DEPTH
    .dina(wdata),     // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Write clock
    .wea(wen),        // Write enable
    .enb(ren),        // Read Enable, for additional power savings, disable when not in use
    .rstb(1'b0),         // Output reset (does not affect memory contents)
    .regceb(1'b0),       // Output register enable
    .doutb(rdata)     // RAM output data, width determined from RAM_WIDTH
  );
end

endgenerate

//////////////////////////////////////////////////////////////////////////////////
//     debug process 
//////////////////////////////////////////////////////////////////////////////////
assign dbg = {DBG_WID{1'h0}};

endmodule


