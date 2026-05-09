module FIFOE2_DUALCLOCK_MACRO (ALMOSTEMPTY, ALMOSTFULL, DO, EMPTY, FULL, RDCOUNT, RDERR, WRCOUNT, WRERR,
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


    //Parameter checks for invalid combinations
    initial begin
      if (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES")
        begin
           if (DATA_WIDTH == 0)
            begin
              $display("Attribute Syntax Error : The attribute DATA_WIDTH on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %d.  This attribute must atleast be equal to 1", DATA_WIDTH);
              #1 $finish;
            end
          else if (DATA_WIDTH > 36 && FIFO_SIZE == "18Kb")
            begin
              $display("Attribute Syntax Error : The attribute DATA_WIDTH on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %d.  For FIFO_SIZE of 18Kb, allowed values of this attribute are 1 to 36", DATA_WIDTH);
              #1 $finish;
            end
          else if (DATA_WIDTH > 72)
            begin
              $display("Attribute Syntax Error : The attribute DATA_WIDTH on FIFO_DUALCLOCK_HDL_SYN instance %m is set to %d.  Allowed values of this attribute are 1 to 36 for FIFO_SIZE of 18Kb and 1 to 72 for FIFO_SIZE of 36Kb", DATA_WIDTH);
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

    localparam DATA_P = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (DATA_WIDTH == 9) ||  (DATA_WIDTH == 17) || (DATA_WIDTH == 18) || (DATA_WIDTH == 33) || (DATA_WIDTH == 34) || (DATA_WIDTH == 35) || (DATA_WIDTH == 36) || (DATA_WIDTH == 65) || (DATA_WIDTH == 66) || (DATA_WIDTH == 67) || (DATA_WIDTH == 68) || (DATA_WIDTH == 69) || (DATA_WIDTH == 70) || (DATA_WIDTH == 71) || (DATA_WIDTH == 72) ? "TRUE" : "FALSE") : "FALSE";

    localparam d_size = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? ( (DATA_WIDTH >= 0 && DATA_WIDTH <= 4) ? 4 : (DATA_WIDTH > 4 && DATA_WIDTH <= 9) ? 9 : (DATA_WIDTH > 9 && DATA_WIDTH <= 18) ? 18 : (DATA_WIDTH > 18 && DATA_WIDTH <= 36) ? 36 : 18) : (FIFO_SIZE == "36Kb") ? ( (DATA_WIDTH >= 0 && DATA_WIDTH <= 4) ? 4 : (DATA_WIDTH > 4 && DATA_WIDTH <= 9) ? 9 : (DATA_WIDTH > 9 && DATA_WIDTH <= 18) ? 18 : (DATA_WIDTH > 18 && DATA_WIDTH <= 36) ? 36 : (DATA_WIDTH > 36 && DATA_WIDTH <= 72) ? 72 : 36) : 36) : 36;

    localparam D_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? ( ( DATA_WIDTH > 0 && DATA_WIDTH <= 4) ? 4 : (DATA_WIDTH > 4 && DATA_WIDTH <= 9) ? 8 : (DATA_WIDTH > 9 && DATA_WIDTH <= 18) ? 16 : (DATA_WIDTH > 18 && DATA_WIDTH <= 36) ? 32 : 16) : (FIFO_SIZE == "36Kb") ? ( (DATA_WIDTH > 0 && DATA_WIDTH <= 4) ? 4 : (DATA_WIDTH > 4 && DATA_WIDTH <= 9) ? 8 : (DATA_WIDTH > 9 && DATA_WIDTH <= 18) ? 16 : (DATA_WIDTH > 18 && DATA_WIDTH <= 36) ? 32 : (DATA_WIDTH > 36 && DATA_WIDTH <= 72) ? 64 : 32) : 32 ) : 32;

    localparam DIP_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (DATA_WIDTH < 9 ) ? 0 : (DATA_WIDTH == 9) ? 1 : (DATA_WIDTH == 17) ? 1 : (DATA_WIDTH == 18) ? 2 : (DATA_WIDTH == 33) ? 1 : (DATA_WIDTH == 34) ? 2 : (DATA_WIDTH == 35) ? 3 : (DATA_WIDTH == 36) ? 4 : (DATA_WIDTH == 65) ? 1 : (DATA_WIDTH == 66) ? 2 : (DATA_WIDTH == 67) ? 3 : (DATA_WIDTH == 68) ? 4 : (DATA_WIDTH == 69) ? 5 : (DATA_WIDTH == 70) ? 6 : (DATA_WIDTH == 71) ? 7 : (DATA_WIDTH == 72) ? 8 : 0 ) : 0; 
    localparam DOP_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (DATA_WIDTH < 9 ) ? 1 : (DATA_WIDTH == 9) ? 1 : (DATA_WIDTH == 17) ? 1 : (DATA_WIDTH == 18) ? 2 : (DATA_WIDTH == 33) ? 1 : (DATA_WIDTH == 34) ? 2 : (DATA_WIDTH == 35) ? 3 : (DATA_WIDTH == 36) ? 4 : (DATA_WIDTH == 65) ? 1 : (DATA_WIDTH == 66) ? 2 : (DATA_WIDTH == 67) ? 3 : (DATA_WIDTH == 68) ? 4 : (DATA_WIDTH == 69) ? 5 : (DATA_WIDTH == 70) ? 6 : (DATA_WIDTH == 71) ? 7 : (DATA_WIDTH == 72) ? 8 : 1 ) : 1; 

    localparam COUNT_WIDTH = (DEVICE == "VIRTEX5" || DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? ( (DATA_WIDTH <= 4) ? 12 : (DATA_WIDTH > 4 && DATA_WIDTH <= 9) ? 11 : (DATA_WIDTH > 9 && DATA_WIDTH <= 18) ? 10 : (DATA_WIDTH > 18 && DATA_WIDTH <= 36) ? 9 : 12 ) : (FIFO_SIZE == "36Kb") ? ( (DATA_WIDTH <= 4) ? 13 : (DATA_WIDTH > 4 && DATA_WIDTH <=9) ? 12 : (DATA_WIDTH > 9 && DATA_WIDTH <= 18) ? 11 : (DATA_WIDTH > 18 && DATA_WIDTH <= 36) ? 10 : (DATA_WIDTH > 36 && DATA_WIDTH <= 72) ? 9 : 13 ) : 13 ) : 13;

    localparam MAX_D_WIDTH = (DEVICE == "VIRTEX5") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH <= 18) ? 16 : (FIFO_SIZE == "18Kb" && DATA_WIDTH > 18 && DATA_WIDTH <= 36)  ? 32 : (FIFO_SIZE == "36Kb" && DATA_WIDTH <= 36) ? 32 : (FIFO_SIZE == "36Kb" && DATA_WIDTH > 36 && DATA_WIDTH <= 72) ? 64 : 64 ) : 
    (DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? 32 : (FIFO_SIZE == "36Kb") ? 64 : 64 ) : 
    64;

    localparam MAX_DP_WIDTH = (DEVICE == "VIRTEX5") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH <= 18) ? 2 : (FIFO_SIZE == "18Kb" && DATA_WIDTH > 18 && DATA_WIDTH <= 36)  ? 4 : (FIFO_SIZE == "36Kb" && DATA_WIDTH <= 36) ? 4 : (FIFO_SIZE == "36Kb" && DATA_WIDTH > 36 && DATA_WIDTH <= 72) ? 8 : 8 ) : 
    (DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb") ? 4 : (FIFO_SIZE == "36Kb") ? 8 : 8 ) : 
    8;

    localparam MAX_COUNT_WIDTH = (DEVICE == "VIRTEX5") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH <= 18) ? 12 : (FIFO_SIZE == "18Kb" && DATA_WIDTH > 18 && DATA_WIDTH <= 36)  ? 9 : (FIFO_SIZE == "36Kb" && DATA_WIDTH <= 36) ? 13 : (FIFO_SIZE == "36Kb" && DATA_WIDTH > 36 && DATA_WIDTH <= 72) ? 9 : 13 ) : 
    (DEVICE == "VIRTEX6" || DEVICE == "7SERIES") ? ( (FIFO_SIZE == "18Kb" && DATA_WIDTH <= 36)  ? 12 : (FIFO_SIZE == "36Kb" && DATA_WIDTH <= 72) ? 13 : 13 ) : 
    13;


    localparam FIFO_WIDTH	=	DATA_WIDTH >	36	? 72	:
								DATA_WIDTH >	18	? 36	:
								DATA_WIDTH >	9	? 18	:	4	;
	
	
	
	

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

	FIFO36E2#(		
		.	CASCADE_ORDER			(		"NONE"									)	,		//	FIRST,	LAST,	MIDDLE,	NONE,	PARALLEL
		.	CLOCK_DOMAINS			(		"INDEPENDENT"							)	,		//	COMMON,	INDEPENDENT
		.	EN_ECC_PIPE				(		"FALSE"									)	,		//	ECC	pipeline	register,	(FALSE,	TRUE)
		.	EN_ECC_READ				(		"FALSE"									)	,		//	Enable	ECC	decoder,	(FALSE,	TRUE)
		.	EN_ECC_WRITE			(		"FALSE"									)	,		//	Enable	ECC	encoder,	(FALSE,	TRUE)
		.	FIRST_WORD_FALL_THROUGH	(		FIRST_WORD_FALL_THROUGH					)	,		//	FALSE,	TRUE
		.	INIT					(		'h0										)	,		//	Initial	values	on	output	port
		.	PROG_EMPTY_THRESH		(		ALMOST_EMPTY_OFFSET						)	,		//	Programmable	Empty	Threshold
		.	PROG_FULL_THRESH		(		ALMOST_FULL_OFFSET						)	,		//	Programmable	Full	Threshold
		//	Programmable	Inversion	Attributes:	Specifies	the	use	of	the	built-in	programmable	inversion
		.	IS_RDCLK_INVERTED		(		1'b0									)	,		//	Optional	inversion	for	RDCLK
		.	IS_RDEN_INVERTED		(		1'b0									)	,		//	Optional	inversion	for	RDEN
		.	IS_RSTREG_INVERTED		(		1'b0									)	,		//	Optional	inversion	for	RSTREG
		.	IS_RST_INVERTED			(		1'b0									)	,		//	Optional	inversion	for	RST
		.	IS_WRCLK_INVERTED		(		1'b0									)	,		//	Optional	inversion	for	WRCLK
		.	IS_WREN_INVERTED		(		1'b0									)	,		//	Optional	inversion	for	WREN
		.	RDCOUNT_TYPE			(		"RAW_PNTR"								)	,		//	EXTENDED_DATACOUNT,	RAW_PNTR,	SIMPLE_DATACOUNT,	SYNC_PNTR
		.	REGISTER_MODE			(		"UNREGISTERED"							)	,		//	DO_PIPELINED,	REGISTERED,	UNREGISTERED
		.	RSTREG_PRIORITY			(		"RSTREG"								)	,		//	REGCE,	RSTREG
		.	SLEEP_ASYNC				(		"FALSE"									)	,		//	FALSE,	TRUE
		.	SRVAL					(		'h0										)	,		//	SET/reset	value	of	the	FIFO	outputs
		.	WRCOUNT_TYPE			(		"RAW_PNTR"								)	,		//	EXTENDED_DATACOUNT,	RAW_PNTR,	SIMPLE_DATACOUNT,	SYNC_PNTR
		.	READ_WIDTH				(		FIFO_WIDTH								)	,		//	18-9
		.	WRITE_WIDTH				(		FIFO_WIDTH								)			//	18-9
	)	dn_data_fifo_inst	(		
		.	CASDOUT					(												)	,		//	64-bit	output:	Data	cascade	output	bus
		.	CASDOUTP				(												)	,		//	8-bit	output:	Parity	data	cascade	output	bus
		.	CASNXTEMPTY				(												)	,		//	1-bit	output:	Cascade	next	empty
		.	CASPRVRDEN				(												)	,		//	1-bit	output:	Cascade	previous	read	enable
		.	DBITERR					(												)	,		//	1-bit	output:	Double	bit	error	status
		.	ECCPARITY				(												)	,		//	8-bit	output:	Generated	error	correction	parity
		.	SBITERR					(												)	,		//	1-bit	output:	Single	bit	error	status
		.	DOUTP					(												)	,		//	8-bit	output:	FIFO	parity	output	bus.
		.	RDCOUNT					(		RDCOUNT									)	,		//	14-bit	output:	Read	count
		.	RDERR					(		RDERR									)	,		//	1-bit	output:	Read	error
		.	RDRSTBUSY				(												)	,		//	1-bit	output:	Reset	busy	(sync	to	RDCLK)
		.	CASDIN					(		{{64}{1'b0}}							)	,		//	64-bit	input:	Data	cascade	input	bus
		.	CASDINP					(		{{08}{1'b0}}							)	,		//	8-bit	input:	Parity	data	cascade	input	bus
		.	CASDOMUX				(		{{01}{1'b0}}							)	,		//	1-bit	input:	Cascade	MUX	select	input
		.	CASDOMUXEN				(		{{01}{1'b0}}							)	,		//	1-bit	input:	Enable	for	cascade	MUX	select
		.	CASNXTRDEN				(		{{01}{1'b0}}							)	,		//	1-bit	input:	Cascade	next	read	enable
		.	CASOREGIMUX				(		{{01}{1'b0}}							)	,		//	1-bit	input:	Cascade	output	MUX	select
		.	CASOREGIMUXEN			(		{{01}{1'b0}}							)	,		//	1-bit	input:	Cascade	output	MUX	select	enable
		.	CASPRVEMPTY				(		{{01}{1'b0}}							)	,		//	1-bit	input:	Cascade	previous	empty
		.	INJECTDBITERR			(		{{01}{1'b0}}							)	,		//	1-bit	input:	Inject	a	double	bit	error
		.	INJECTSBITERR			(		{{01}{1'b0}}							)	,		//	1-bit	input:	Inject	a	single	bit	error
		.	REGCE					(		{{01}{1'b0}}							)	,		//	1-bit	input:	Output	register	clock	enable
		.	RSTREG					(		{{01}{1'b0}}							)	,		//	1-bit	input:	Output	register	reset
		.	SLEEP					(		{{01}{1'b0}}							)	,		//	1-bit	input:	Sleep	Mode
		.	WRCOUNT					(		WRCOUNT									)	,		//	14-bit	output:	Write	count
		.	WRERR					(		WRERR									)	,		//	1-bit	output:	Write	Error
		.	WRRSTBUSY				(												)	,		//	1-bit	output:	Reset	busy	(sync	to	WRCLK)
		.	RST						(		RST										)	,		//	1-bit	input:	Reset
		.	WRCLK					(		WRCLK									)	,		//	1-bit	input:	Write	clock
		.	WREN					(		WREN									)	,		//	1-bit	input:	Write	enable
		.	DIN						(		DI										)	,		//	64-bit	input:	FIFO	data	input	bus
		.	PROGFULL				(		ALMOSTFULL								)	,		//	1-bit	output:	Programmable	full
		.	FULL					(		FULL									)	,		//	1-bit	output:	Full
		.	RDEN					(		RDEN									)	,		//	1-bit	input:	Read	enable
		.	DOUT					(		DO										)	,		//	64-bit	output:	FIFO	data	output	bus
		.	PROGEMPTY				(		ALMOSTEMPTY								)	,		//	1-bit	output:	Programmable	empty
		.	EMPTY					(		EMPTY									)	,		//	1-bit	output:	Empty
		.	RDCLK					(		RDCLK									)	,		//	1-bit	input:	Read	clock
		.	DINP					(		{{08}{1'b0}}							)			//	8-bit	input:	FIFO	parity	input	bus
	)	;
endmodule