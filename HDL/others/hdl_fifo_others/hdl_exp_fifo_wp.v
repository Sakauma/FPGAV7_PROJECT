
`timescale	1ns/1ps
	module	hdl_exp_fifo_wp	#(
		parameter	LOOP_NUM				= 	0			,
		parameter	DEVICE					= 	"7SERIES"	,
		parameter	ALMOST_EMPTY_OFFSET		=	256			,
		parameter	ALMOST_FULL_OFFSET		=	256			,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
		parameter	AW						=	9			,
		parameter	DW						=	16			,
		parameter	QW						=	DW			
	)(
		input								WREN			,
		input			[DW	-1:0]			DI				,
		output								ALMOSTFULL		,
		output								FULL			,

		input								WREN_LAST		,
		output			[AW-1:0]			WRCOUNT			,
		output								WRERR			,

		input								RDEN			,
		output			[QW	-1:0]			DO				,
		output								ALMOSTEMPTY		,
		output								EMPTY			,
		input								RDEN_LAST		,
		output			[AW-1:0]			RDCOUNT			,
		output								RDERR			,

		input								RST				,
		input								CLK				
	);
// genvar i;
	generate
		if(	DW	==	QW	)	begin
			hdl_eqs_fifo	#(
				.	LOOP_NUM					(	LOOP_NUM					)	,
				.	DEVICE						(	DEVICE						)	,
				.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
				.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
				.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
				.	AW							(	AW							)	,
				.	DW							(	DW							)	
			)hdl_eqs_fifo(
				.	WREN				(	WREN				)	,//	input								
				.	DI					(	DI					)	,//	input			[DW	-1:0]			
				.	ALMOSTFULL			(	ALMOSTFULL			)	,//	output								
				.	FULL				(	FULL				)	,//	output								
				.	WRCOUNT				(	WRCOUNT				)	,//	output			[AW-1:0]			
				.	WRERR				(	WRERR				)	,//	output								
				.	RDEN				(	RDEN				)	,//	input								
				.	DO					(	DO					)	,//	output			[DW	-1:0]			
				.	ALMOSTEMPTY			(	ALMOSTEMPTY			)	,//	output								
				.	EMPTY				(	EMPTY				)	,//	output								
				.	RDCOUNT				(	RDCOUNT				)	,//	output			[AW-1:0]			
				.	RDERR				(	RDERR				)	,//	output								
				.	RST					(	RST					)	,//	input								
				.	CLK					(	CLK					)	 //	input								
			);
			
		end	else	if(	DW	<	QW	)	begin
			
			hdl_ups_fifo	#(
			.	LOOP_NUM					(	LOOP_NUM					)	,
			.	DEVICE						(	DEVICE						)	,
			.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
			.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
			.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
			.	AW							(	AW							)	,
			.	DW							(	DW							)	,
			.	QW							(	QW							)	
			)hdl_ups_fifo(
				.	WREN			(		WREN			)	,	//	input						
				.	DI				(		DI				)	,	//	input			[DW	-1:0]	
				.	ALMOSTFULL		(		ALMOSTFULL		)	,	//	output						
				.	FULL			(		FULL			)	,	//	output						
				.	WREN_LAST		(		WREN_LAST		)	,	//	input						
				.	WRCOUNT			(		WRCOUNT			)	,	//	output			[AW-1:0]	
				.	WRERR			(		WRERR			)	,	//	output						
				.	RDEN			(		RDEN			)	,	//	input						
				.	DO				(		DO				)	,	//	output			[QW	-1:0]	
				.	ALMOSTEMPTY		(		ALMOSTEMPTY		)	,	//	output						
				.	EMPTY			(		EMPTY			)	,	//	output						
				.	RDCOUNT			(		RDCOUNT			)	,	//	output			[AW-1:0]	
				.	RDERR			(		RDERR			)	,	//	output						
				.	RST				(		RST				)	,	//	input						
				.	CLK				(		CLK				)	 	//	input						
			);
			
		end	else	begin
			hdl_dns_fifo	#(
				.	LOOP_NUM					(	LOOP_NUM					)	,
				.	DEVICE						(	DEVICE						)	,
				.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
				.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
				.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
				.	AW							(	AW							)	,
				.	DW							(	DW							)	,
				.	QW							(	QW							)	
			)hdl_dns_fifo(
				.	WREN				(	WREN				)	,	//	input						
				.	DI					(	DI					)	,	//	input			[DW	-1:0]	
				.	ALMOSTFULL			(	ALMOSTFULL			)	,	//	output						
				.	FULL				(	FULL				)	,	//	output						
				.	WRCOUNT				(	WRCOUNT				)	,	//	output			[AW-1:0]	
				.	WRERR				(	WRERR				)	,	//	output						
				.	RDEN				(	RDEN				)	,	//	input						
				.	DO					(	DO					)	,	//	output			[QW	-1:0]	
				.	ALMOSTEMPTY			(	ALMOSTEMPTY			)	,	//	output						
				.	EMPTY				(	EMPTY				)	,	//	output						
				.	RDEN_LAST			(	RDEN_LAST			)	,	//	input						
				.	RDCOUNT				(	RDCOUNT				)	,	//	output			[AW-1:0]	
				.	RDERR				(	RDERR				)	,	//	output						
				.	RST					(	RST					)	,	//	input						
				.	CLK					(	CLK					)		//	input						
			);
			
		end	//	if
	endgenerate

endmodule