`timescale	1ns/1ps
module	hdl_eqw_afifo	#(
	parameter	LOOP_NUM				= 	0			,
	parameter	RAM_STYLE				= 	"block"		,
	parameter	ALMOST_EMPTY_OFFSET		=	'h8			,
	parameter	ALMOST_FULL_OFFSET		=	'h8			,
	parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
	parameter	AW						=	9			,
	parameter	DW						=	16			
)(
	input	wire						RST				,
	input	wire						WRCLK			,

	output	wire	[AW-1:0]			WRCOUNT			,
	output	wire						WRERR			,
	
	input	wire						WREN			,
	input	wire	[DW	-1:0]			DI				,
	output	wire						ALMOSTFULL		,
	output	wire						FULL			,

	input	wire						RDEN			,
	output	wire	[DW	-1:0]			DO				,
	output	wire						ALMOSTEMPTY		,
	output	wire						EMPTY			,
	
	output	wire	[AW-1:0]			RDCOUNT			,
	output	wire						RDERR			,

	input	wire						RDCLK			
);
	
			wire				sync_rd	;
			wire	[DW	-1:0]	sync_do	;
			wire				sync_ae	;
			wire				sync_em	;
			
			wire				asyn_wr	;
			wire	[DW	-1:0]	asyn_di	;
			wire				asyn_fu	;
			
			reg		sync_ae_q1	=0	;	always@(posedge	RDCLK)	sync_ae_q1	<=	sync_ae		;
			reg		sync_ae_q2	=0	;	always@(posedge	RDCLK)	sync_ae_q2	<=	sync_ae_q1	;
				
			assign	ALMOSTEMPTY	=	sync_ae_q2	;
			
			assign	sync_rd	=	~sync_em	&&	~asyn_fu	;
			assign	asyn_wr	=	sync_rd	;
			assign	asyn_di	=	sync_do	;
			
			hdl_exp_sfifo	#(
				.	LOOP_NUM					(	LOOP_NUM					)	,
				.	RAM_STYLE					(	RAM_STYLE					)	,
				.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
				.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
				.	FIRST_WORD_FALL_THROUGH		(	"TRUE"						)	,
				.	AW							(	AW							)	,
				.	DW							(	DW							)	,
				.	QW							(	QW							)	
			)hdl_exp_sfifo(
				.	WRCOUNT				(	WRCOUNT				)	,	//	output			[AW-1:0]			
				.	WRERR				(	WRERR				)	,	//	output								
				.	WREN_LAST			(	1'b0				)	,	//	input								
				.	WREN				(	WREN				)	,	//	input								
				.	DI					(	DI					)	,	//	input			[DW	-1:0]			
				.	ALMOSTFULL			(	ALMOSTFULL			)	,	//	output								
				.	FULL				(	FULL				)	,	//	output								
				.	RDEN				(	sync_rd				)	,	//	input								
				.	DO					(	sync_do				)	,	//	output			[QW	-1:0]			
				.	ALMOSTEMPTY			(	sync_ae				)	,	//	output								
				.	EMPTY				(	sync_em				)	,	//	output								
				.	RDEN_LAST			(	1'b0				)	,	//	input								
				.	RDCOUNT				(	RDCOUNT				)	,	//	output			[AW-1:0]			
				.	RDERR				(	RDERR				)	,	//	output								
				.	RST					(	RST					)	,	//	input								
				.	CLK					(	WRCLK				)		//	input								
			);
			
			hdl_afifo_top	#(
				.	FWFT	(	FIRST_WORD_FALL_THROUGH	)	,
				.	DATA_WD	(	DW						)	
			)hdl_afifo_top	(
				.	rst			(	RST			)	,	//	input	wire					
				.	wclk		(	WRCLK		)	,	//	input	wire					
				.	wen			(	asyn_wr		)	,	//	input	wire					
				.	wdata		(	asyn_di		)	,	//	input	wire	[DATA_WD-1:0]	
				.	full		(	asyn_fu		)	,	//	output	wire					
				.	rclk		(	RDCLK		)	,	//	input	wire					
				.	ren			(	RDEN		)	,	//	input	wire					
				.	rdata		(	DO			)	,	//	output	wire	[DATA_WD-1:0]	
				.	empty		(	EMPTY		)		//	output	wire					
			);
			
endmodule