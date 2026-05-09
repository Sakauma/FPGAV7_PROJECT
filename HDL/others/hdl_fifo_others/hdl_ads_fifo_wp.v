`timescale	1ns/1ps
	module	hdl_ads_fifo_wp	#(
		parameter	LOOP_NUM				= 	0			,
		parameter	DEVICE					= 	"7SERIES"	,
		parameter	ALMOST_EMPTY_OFFSET		=	256			,
		parameter	ALMOST_FULL_OFFSET		=	256			,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
		parameter	CLOCK_MODE				=	"SYNC"		,	//	"READ_BLOCK"	,	"WRITE_BLOCK"	or	"SYNC"
		parameter	AW						=	9			,
		parameter	DW						=	16			,
		parameter	QW						=	DW			
	)(
		input	wire						RST				,
		input	wire						WRCLK			,
		
		input	wire						WREN			,
		input	wire	[DW	-1:0]			DI				,
		output	wire						ALMOSTFULL		,
		output	wire						FULL			,

		input	wire						WREN_LAST		,
		output	wire	[AW-1:0]			WRCOUNT			,
		output	wire						WRERR			,

		input	wire						RDEN			,
		output	wire	[QW	-1:0]			DO				,
		output	wire						ALMOSTEMPTY		,
		output	wire						EMPTY			,
		input	wire						RDEN_LAST		,
		output	wire	[AW-1:0]			RDCOUNT			,
		output	wire						RDERR			,

		input	wire						RDCLK			
	);
	
	generate
		if(	CLOCK_MODE	==	"SYNC"	)	begin
			hdl_exp_fifo_wp	#(
				.	LOOP_NUM					(	LOOP_NUM					)	,
				.	DEVICE						(	DEVICE						)	,
				.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
				.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
				.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
				.	AW							(	AW							)	,
				.	DW							(	DW							)	,
				.	QW							(	QW							)	
			)hdl_exp_fifo_wp(
				.	WREN				(	WREN				)	,	//	input								
				.	DI					(	DI					)	,	//	input			[DW	-1:0]			
				.	ALMOSTFULL			(	ALMOSTFULL			)	,	//	output								
				.	FULL				(	FULL				)	,	//	output								
				.	WREN_LAST			(	WREN_LAST			)	,	//	input								
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
				.	CLK					(	WRCLK				)		//	input								
			);
		else	if(	CLOCK_MODE	==	"WRITE_BLOCK"	)	begin
		
			wire				asyn_rd	;
			wire	[DW	-1:0]	asyn_do	;
			wire				asyn_ne	;
			
			wire				sync_wr	;
			wire	[DW	-1:0]	sync_di	;
			wire				sync_af	;
			wire				sync_fu	;
			
			reg		sync_af_q1	=0	;	always@(posedge	WRCLK)	sync_af_q1	<=	sync_af		;
			reg		sync_af_q2	=0	;	always@(posedge	WRCLK)	sync_af_q2	<=	sync_af_q1	;
				
			assign	ALMOSTFULL	=	sync_af_q2	;	//	in write_block mode ALMOSTFULL	is	not sensitive
			
			assign	asyn_rd	=	~asyn_em	&&	~	sync_fu	;
			assign	sync_wr	=	asyn_rd	;
			assign	sync_di	=	asyn_do	;
			
			hdl_afifo_top	#(
				.	FWFT	(	"TRUE"	)	,
				.	DATA_WD	(	DW		)	
			)hdl_afifo_top	(
				.	rst			(	RST			)	,	//	input	wire					
				.	wclk		(	WRCLK		)	,	//	input	wire					
				.	wen			(	WREN		)	,	//	input	wire					
				.	wdata		(	DI			)	,	//	input	wire	[DATA_WD-1:0]	
				.	full		(	FULL		)	,	//	output	wire					
				.	rclk		(	RDCLK		)	,	//	input	wire					
				.	ren			(	asyn_rd		)	,	//	input	wire					
				.	rdata		(	asyn_do		)	,	//	output	wire	[DATA_WD-1:0]	
				.	empty		(	asyn_em		)		//	output	wire					
			);
			
			hdl_exp_fifo_wp	#(
				.	LOOP_NUM					(	LOOP_NUM					)	,
				.	DEVICE						(	DEVICE						)	,
				.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
				.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
				.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
				.	AW							(	AW							)	,
				.	DW							(	DW							)	,
				.	QW							(	QW							)	
			)hdl_exp_fifo_wp(
				.	WREN				(	sync_rd				)	,	//	input								
				.	DI					(	sync_di				)	,	//	input			[DW	-1:0]			
				.	ALMOSTFULL			(	sync_af				)	,	//	output								
				.	FULL				(	sync_fu				)	,	//	output								
				.	WREN_LAST			(	WREN_LAST			)	,	//	input								
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
				.	CLK					(	RDCLK				)		//	input								
			);
		else	begin
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
			
			assign	sync_rd	=	~sync_em	&&	~	asyn_fu	;
			assign	asyn_wr	=	sync_rd	;
			assign	asyn_di	=	sync_do	;
			
			hdl_exp_fifo_wp	#(
				.	LOOP_NUM					(	LOOP_NUM					)	,
				.	DEVICE						(	DEVICE						)	,
				.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
				.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
				.	FIRST_WORD_FALL_THROUGH		(	"TRUE"						)	,
				.	AW							(	AW							)	,
				.	DW							(	DW							)	,
				.	QW							(	QW							)	
			)hdl_exp_fifo_wp(
				.	WREN				(	WREN				)	,	//	input								
				.	DI					(	DI					)	,	//	input			[DW	-1:0]			
				.	ALMOSTFULL			(	ALMOSTFULL			)	,	//	output								
				.	FULL				(	FULL				)	,	//	output								
				.	WREN_LAST			(	WREN_LAST			)	,	//	input								
				.	WRCOUNT				(	WRCOUNT				)	,	//	output			[AW-1:0]			
				.	WRERR				(	WRERR				)	,	//	output								
				.	RDEN				(	sync_rd				)	,	//	input								
				.	DO					(	sync_do				)	,	//	output			[QW	-1:0]			
				.	ALMOSTEMPTY			(	sync_ae				)	,	//	output								
				.	EMPTY				(	sync_em				)	,	//	output								
				.	RDEN_LAST			(	RDEN_LAST			)	,	//	input								
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
		end	if
			
endmodule