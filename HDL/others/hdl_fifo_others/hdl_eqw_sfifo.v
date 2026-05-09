
module	hdl_eqw_sfifo	#(
	parameter	LOOP_NUM				= 	0			,
	parameter	RAM_STYLE				= 	"block"		,
	parameter	ALMOST_EMPTY_OFFSET		=	256			,
	parameter	ALMOST_FULL_OFFSET		=	256			,
	parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
	parameter	AW						=	9			,
	parameter	DW						=	64			
)(
	input								WREN			,
	input			[DW	-1:0]			DI				,
	output								ALMOSTFULL		,
	output								FULL			,
	output			[AW-1:0]			WRCOUNT			,
	output								WRERR			,

	input								RDEN			,
	output			[DW	-1:0]			DO				,
	output								ALMOSTEMPTY		,
	output								EMPTY			,
	output			[AW-1:0]			RDCOUNT			,
	output								RDERR			,
	
	input								RST				,
	input								CLK				
);

	wire	 [AW:0] cnt_used;	assign	WRCOUNT	=cnt_used[AW-1:0]	;
	wire	 [AW:0] cnt_free;	assign	RDCOUNT	=cnt_free[AW-1:0]	;

	hdl_sfifo_top #(
		.	RAM_STYLE  	(	RAM_STYLE					)	,	//	Specify RAM style: auto/block/distributed
		.	FWFT       	(	FIRST_WORD_FALL_THROUGH		)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
		.	DWID       	(	DW							)	,
		.	AWID       	(	AW							)	, 
		.	AFULL_TH   	(	ALMOST_FULL_OFFSET			)	, 
		.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET 		)	, 
		.	DBG_WID    	(	32							)		
	)hdl_sfifo_top(
		.	clk			(	CLK				)	,   	// input						write clock
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

endmodule	
