
`timescale 1ns / 1ps
module hdl_sfifo_top #(
	parameter RAM_STYLE  = "block"	,	//	Specify RAM style: auto/block/distributed
	parameter FWFT       = "TRUE"	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
	parameter DWID       = 18		,
	parameter AWID       = 6		, 
	parameter AFULL_TH   = 4		, 
	parameter AEMPTY_TH  = 4		, 
	parameter DBG_WID    = 32 		
) (
  //write clock domain
  input  		    clk,                          // write clock
  input 		    rst,                          // write reset
  input 		    wen,                           // Write enable
  input  [DWID-1:0]   	    wdata,                         // RAM input data
  output                    full,                         // 
  output                    nfull,                         // 
  output                    afull,                        // 
  output                    nafull,                        // 
  output                    woverflow,                     // 
  output [AWID:0]           cnt_free,                      // the counter used in fifo for read clock domain 
  input                     ren,                           // Read Enable
  output wire [DWID-1:0]         rdata,                         // RAM output data
  output                    empty,                        // 
  output                    nempty,                        // 
  output                    aempty,                       // 
  output                    naempty,                       // 
  output                    roverflow,                     // 
  output [AWID:0]           cnt_used ,                     // the counter used in fifo for write clock domain
  output [DBG_WID-1:0]      dbg_sig                        // debug signal
);
	wire [DWID-1:0]         rdata_t;

	reg [DWID-1:0]         rdata_r;

	generate
		if( FWFT=="TRUE" ) begin : FWFT_DOUT
			assign	rdata	=	rdata_t	;
		end	else  begin : REG_DOUT
			assign	rdata	=	rdata_r	;
			always	@(posedge clk or posedge rst)begin
				if(rst)
					rdata_r <= 0;
				else
					rdata_r <= 	ren ? rdata_t : rdata_r;
			end
		end
	endgenerate

	//////////////////////////////////////////////////////////////////////////////////
	//  signal declare
	//////////////////////////////////////////////////////////////////////////////////
	wire                     old_ren        ;                     // Read Enable
	wire  [DWID-1:0]         old_rdata      ;                     // RAM output data
	wire                     old_nempty     ;                     // 
	wire                     old_naempty    ;                     // 
	wire                     old_roverflow  ;                     // 
	 
	//////////////////////////////////////////////////////////////////////////////////
	//  old fifo
	//////////////////////////////////////////////////////////////////////////////////
	bfifo_reg #(
	  .RAM_STYLE   ( RAM_STYLE   ),
	  .DWID        ( DWID        ),
	  .AWID        ( AWID        ),
	  .AFULL_TH    ( AFULL_TH    ),
	  .AEMPTY_TH   ( AEMPTY_TH   ),
	  .DBG_WID     ( DBG_WID     )
	) inst_fifo (
		.clk          ( clk          ),                 // write clock
		.rst          ( rst          ),                 // write reset
		.wen          ( wen           ),                 // Write enable
		.wdata        ( wdata         ),                 // RAM input data
		.full         ( full          ),                 // 
		.nfull        ( nfull         ),                 // 
		.afull        ( afull         ),                 // 
		.nafull       ( nafull        ),                 // 
		.woverflow    ( woverflow     ),                 // 
		.cnt_used     ( cnt_used      ),                 // the counter used in fifo for write clock domain
		.ren          ( old_ren       ),                 // Read Enable
		.rdata        ( old_rdata     ),                 // RAM output data
		.nempty       ( old_nempty    ),                 // 
		.aempty       ( aempty        ),                 // 
		.naempty      ( naempty       ),                 // 
		.roverflow    ( old_roverflow ),                 // 
		.cnt_free     ( cnt_free      ),                 // the counter used in fifo for read clock domain 
		.dbg_sig      (               )                  // debug signal
	);

	//////////////////////////////////////////////////////////////////////////////////
	//  new fifo read interface
	//////////////////////////////////////////////////////////////////////////////////
	fifo_rdif_tf #(
	  .DWID        ( DWID ),
	  .AWID        ( AWID )
	) inst_fifo_rdif_tf (
	  .clk               ( clk            ),                // Read clock
	  .rst               ( rst            ),                // Read reset 
	  .old_ren           ( old_ren        ),                // Read Enable
	  .old_rdata         ( old_rdata      ),                // RAM output data
	  .old_nempty        ( old_nempty     ),                // 
	  .new_ren           ( ren            ),                // Read Enable
	  .new_rdata         ( rdata_t        ),                // RAM output data
	  .new_empty         ( empty         ),                // 
	  .new_nempty        ( nempty         ),                // 
	  .new_roverflow     ( roverflow      )                 // 
	);

	//////////////////////////////////////////////////////////////////////////////////
	//  debug sig
	//////////////////////////////////////////////////////////////////////////////////
	assign dbg_sig = { 28'h0, woverflow, roverflow, nafull, nempty };

endmodule
 
