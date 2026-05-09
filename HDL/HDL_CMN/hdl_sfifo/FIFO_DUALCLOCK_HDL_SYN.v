module FIFO_DUALCLOCK_HDL_SYN (ALMOSTEMPTY, ALMOSTFULL, DO, EMPTY, FULL, RDCOUNT, RDERR, WRCOUNT, WRERR,
	       DI, RDCLK, RDEN, RST, WRCLK, WREN);

    parameter ALMOST_EMPTY_OFFSET = 9'h080;
    parameter ALMOST_FULL_OFFSET = 9'h080;
    parameter integer DATA_WIDTH = 22; 
    parameter DEVICE = "VIRTEX5";
    parameter FIFO_SIZE = "36Kb"; 
    parameter FIRST_WORD_FALL_THROUGH = "FALSE";
    parameter INIT = 72'h0; // This parameter is valid only for Virtex6
    parameter SRVAL = 72'b0; // This parameter is valid only for Virtex6
    parameter SIM_MODE = "SAFE"; // This parameter is valid only for Virtex5

	localparam	 DATA_WIDTH_DN	=	DATA_WIDTH	>	72	?	72	:	DATA_WIDTH	;

    //Parameter checks for invalid combinations
    initial begin
      if (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES")
        begin
           if (DATA_WIDTH_DN == 0)
            begin
              $display("Attribute Syntax Error : The attribute DATA_WIDTH_DN on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %d.  This attribute must atleast be equal to 1", DATA_WIDTH_DN);
              #1 $finish;
            end
          else if (DATA_WIDTH_DN > 36 && FIFO_SIZE == "18Kb")
            begin
              $display("Attribute Syntax Error : The attribute DATA_WIDTH_DN on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %d.  For FIFO_SIZE of 18Kb, allowed values of this attribute are 1 to 36", DATA_WIDTH_DN);
              #1 $finish;
            end
          else if (DATA_WIDTH_DN > 72)
            begin
              $display("Attribute Syntax Error : The attribute DATA_WIDTH_DN on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %d.  Allowed values of this attribute are 1 to 36 for FIFO_SIZE of 18Kb and 1 to 72 for FIFO_SIZE of 36Kb", DATA_WIDTH_DN);
              #1 $finish;
            end
          if(FIFO_SIZE == "18Kb" || FIFO_SIZE == "36Kb") ;
          else
             begin
               $display("Attribute Syntax Error : The attribute FIFO_SIZE on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %s.  Legal values for this attribute are 18Kb or 36Kb", FIFO_SIZE);
               #1 $finish;
             end
        end
      else 
        begin
          $display("Attribute Syntax Error : The attribute DEVICE on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %s.  Legal values of this attribute are VIRTEX5, VIRTEX6, 7SERIES", DEVICE);
          #1 $finish;
        end
    end // initial begin

    localparam DATA_P = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (DATA_WIDTH_DN == 9) ||  (DATA_WIDTH_DN == 17) || (DATA_WIDTH_DN == 18) || (DATA_WIDTH_DN == 33) || (DATA_WIDTH_DN == 34) || (DATA_WIDTH_DN == 35) || (DATA_WIDTH_DN == 36) || (DATA_WIDTH_DN == 65) || (DATA_WIDTH_DN == 66) || (DATA_WIDTH_DN == 67) || (DATA_WIDTH_DN == 68) || (DATA_WIDTH_DN == 69) || (DATA_WIDTH_DN == 70) || (DATA_WIDTH_DN == 71) || (DATA_WIDTH_DN == 72) ? "TRUE" : "FALSE") : "FALSE";

    localparam d_size = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? ( (DATA_WIDTH_DN >= 0 && DATA_WIDTH_DN <= 4) ? 4 : (DATA_WIDTH_DN > 4 && DATA_WIDTH_DN <= 9) ? 9 : (DATA_WIDTH_DN > 9 && DATA_WIDTH_DN <= 18) ? 18 : (DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36) ? 36 : 18) : (FIFO_SIZE == "36Kb") ? ( (DATA_WIDTH_DN >= 0 && DATA_WIDTH_DN <= 4) ? 4 : (DATA_WIDTH_DN > 4 && DATA_WIDTH_DN <= 9) ? 9 : (DATA_WIDTH_DN > 9 && DATA_WIDTH_DN <= 18) ? 18 : (DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36) ? 36 : (DATA_WIDTH_DN > 36 && DATA_WIDTH_DN <= 72) ? 72 : 36) : 36) : 36;

    localparam D_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? ( ( DATA_WIDTH_DN > 0 && DATA_WIDTH_DN <= 4) ? 4 : (DATA_WIDTH_DN > 4 && DATA_WIDTH_DN <= 9) ? 8 : (DATA_WIDTH_DN > 9 && DATA_WIDTH_DN <= 18) ? 16 : (DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36) ? 32 : 16) : (FIFO_SIZE == "36Kb") ? ( (DATA_WIDTH_DN > 0 && DATA_WIDTH_DN <= 4) ? 4 : (DATA_WIDTH_DN > 4 && DATA_WIDTH_DN <= 9) ? 8 : (DATA_WIDTH_DN > 9 && DATA_WIDTH_DN <= 18) ? 16 : (DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36) ? 32 : (DATA_WIDTH_DN > 36 && DATA_WIDTH_DN <= 72) ? 64 : 32) : 32 ) : 32;

    localparam DIP_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (DATA_WIDTH_DN < 9 ) ? 0 : (DATA_WIDTH_DN == 9) ? 1 : (DATA_WIDTH_DN == 17) ? 1 : (DATA_WIDTH_DN == 18) ? 2 : (DATA_WIDTH_DN == 33) ? 1 : (DATA_WIDTH_DN == 34) ? 2 : (DATA_WIDTH_DN == 35) ? 3 : (DATA_WIDTH_DN == 36) ? 4 : (DATA_WIDTH_DN == 65) ? 1 : (DATA_WIDTH_DN == 66) ? 2 : (DATA_WIDTH_DN == 67) ? 3 : (DATA_WIDTH_DN == 68) ? 4 : (DATA_WIDTH_DN == 69) ? 5 : (DATA_WIDTH_DN == 70) ? 6 : (DATA_WIDTH_DN == 71) ? 7 : (DATA_WIDTH_DN == 72) ? 8 : 0 ) : 0; 
    localparam DOP_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (DATA_WIDTH_DN < 9 ) ? 1 : (DATA_WIDTH_DN == 9) ? 1 : (DATA_WIDTH_DN == 17) ? 1 : (DATA_WIDTH_DN == 18) ? 2 : (DATA_WIDTH_DN == 33) ? 1 : (DATA_WIDTH_DN == 34) ? 2 : (DATA_WIDTH_DN == 35) ? 3 : (DATA_WIDTH_DN == 36) ? 4 : (DATA_WIDTH_DN == 65) ? 1 : (DATA_WIDTH_DN == 66) ? 2 : (DATA_WIDTH_DN == 67) ? 3 : (DATA_WIDTH_DN == 68) ? 4 : (DATA_WIDTH_DN == 69) ? 5 : (DATA_WIDTH_DN == 70) ? 6 : (DATA_WIDTH_DN == 71) ? 7 : (DATA_WIDTH_DN == 72) ? 8 : 1 ) : 1; 

    localparam COUNT_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? ( (DATA_WIDTH_DN <= 4) ? 12 : (DATA_WIDTH_DN > 4 && DATA_WIDTH_DN <= 9) ? 11 : (DATA_WIDTH_DN > 9 && DATA_WIDTH_DN <= 18) ? 10 : (DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36) ? 9 : 12 ) : (FIFO_SIZE == "36Kb") ? ( (DATA_WIDTH_DN <= 4) ? 13 : (DATA_WIDTH_DN > 4 && DATA_WIDTH_DN <=9) ? 12 : (DATA_WIDTH_DN > 9 && DATA_WIDTH_DN <= 18) ? 11 : (DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36) ? 10 : (DATA_WIDTH_DN > 36 && DATA_WIDTH_DN <= 72) ? 9 : 13 ) : 13 ) : 13;

    localparam MAX_D_WIDTH = (DEVICE == "VIRTEX5") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN <= 18) ? 16 : (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36)  ? 32 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN <= 36) ? 32 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN > 36 && DATA_WIDTH_DN <= 72) ? 64 : 64 ) : 
    (DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? 32 : (FIFO_SIZE == "36Kb") ? 64 : 64 ) : 
    64;

    localparam MAX_DP_WIDTH = (DEVICE == "VIRTEX5") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN <= 18) ? 2 : (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36)  ? 4 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN <= 36) ? 4 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN > 36 && DATA_WIDTH_DN <= 72) ? 8 : 8 ) : 
    (DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? 4 : (FIFO_SIZE == "36Kb") ? 8 : 8 ) : 
    8;

    localparam MAX_COUNT_WIDTH = (DEVICE == "VIRTEX5") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN <= 18) ? 12 : (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN > 18 && DATA_WIDTH_DN <= 36)  ? 9 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN <= 36) ? 13 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN > 36 && DATA_WIDTH_DN <= 72) ? 9 : 13 ) : 
    (DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH_DN <= 36)  ? 12 : (FIFO_SIZE == "36Kb" && DATA_WIDTH_DN <= 72) ? 13 : 13 ) : 
    13;



    output ALMOSTEMPTY;
    output ALMOSTFULL;
    output [DATA_WIDTH-1:0] DO;
    output EMPTY;
    output FULL;
    output [COUNT_WIDTH-1:0] RDCOUNT;
    output RDERR;
    output [COUNT_WIDTH-1:0] WRCOUNT;
    output WRERR;

    input [DATA_WIDTH-1:0] DI;
    input RDCLK;
    input RDEN;
    input RST;
    input WRCLK;
    input WREN;

	localparam	RAM_STYLE	=	DEVICE == "DRAM"	?	"distributed"	:	"block"	;

	wire	 [COUNT_WIDTH:0] cnt_used;	assign	WRCOUNT	=cnt_used[COUNT_WIDTH-1:0]	;
	wire	 [COUNT_WIDTH:0] cnt_free;	assign	RDCOUNT	=cnt_free[COUNT_WIDTH-1:0]	;

	hdl_sfifo_top #(
		.	RAM_STYLE  	(	RAM_STYLE					)	,	//	Specify RAM style: auto/block/distributed
		.	FWFT       	(	FIRST_WORD_FALL_THROUGH		)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
		.	DWID       	(	DATA_WIDTH					)	,
		.	AWID       	(	COUNT_WIDTH					)	, 
		.	AFULL_TH   	(	ALMOST_FULL_OFFSET			)	, 
		.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET 		)	, 
		.	DBG_WID    	(	32							)		
	)hdl_sfifo_top(
		.	clk			(	WRCLK			)	,   	// input						write clock
		.	rst			(	RST				)	,   	// input						write reset
		.	wen			(	WREN			)	,   	// input						Write enable
		.	wdata		(	DI				)	,   	// input		[DWID-1:0]		RAM input data
		.	afull		(	ALMOSTFULL		)	,   	// output						
		.	full		(	FULL			)	,   	// output						
		.	nafull		(					)	,   	// output						
		.	nfull		(					)	,   	// output						
		.	cnt_used	(	cnt_used		)	,   	// output		[AWID:0]		the counter used in fifo for write clock domain
		.	woverflow	(	WRERR			)	,   	// output						
		.	ren			(	RDEN			)	,   	// input						Read Enable
		.	rdata		(	DO				)	,   	// output		[DWID-1:0]		RAM output data
		.	aempty		(	ALMOSTEMPTY		)	,   	// output						
		.	empty		(	EMPTY			)	,   	// output						
		.	naempty		(					)	,   	// output						
		.	nempty		(					)	,   	// output						
		.	cnt_free	(	cnt_free		)	,   	// output		[AWID:0]		the counter used in fifo for read clock domain 
		.	roverflow	(	RDERR			)	,   	// output						
		.	dbg_sig		(					)			// output		[DBG_WID-1:0]	debug signal
	);

//	function integer clogb2;
//	input integer depth;
//	integer depth_reg;
//		begin
//			depth_reg = depth;
//			for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
//			depth_reg = depth_reg >> 1;
//			end
//			if( 2**clogb2 >= depth*2 )begin
//			clogb2 = clogb2 - 1;
//			end
//		end 
//	endfunction

endmodule

