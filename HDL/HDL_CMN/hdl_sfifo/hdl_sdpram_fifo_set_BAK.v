
	//	xilinx_simple_dual_port_ram based fifo
	
	//	hdl_afifo_top	//	fix	16 deep async reg	fifo
	//	hdl_sfifo_top	//	param deep sync	 reg/bram fifo
	//	
	//	hdl_eqw_sfifo	=	hdl_sfifo_top	+	logic			;	//	equal	width	sync	fifo
	//	hdl_eqw_afifo	=	hdl_eqw_sfifo	+	hdl_afifo_top	;	//	equal	width	async	fifo
	//		
	//	hdl_exw_sfifo	=	hdl_eqw_sfifo	+	logic			;	//	up/down	extended	width	sync	fifo
	//	hdl_exw_afifo	=	hdl_exw_sfifo	+	hdl_afifo_top	;	//	up/down	extended	width	async	fifo

	`define	exw_afifo
	`define	exw_sfifo
	`define	eqw_afifo
	`define	afifo_top
//	`define	SFIFO_HDL
//	`define	AFIFO_LITE

	`timescale	1ns/1ps
`ifdef	exw_afifo
	module	hdl_exw_afifo	#(	//	up/down	extended	width	async	fifo
		parameter	LOOP_NUM				= 	0			,
		parameter	RAM_STYLE				= 	"block"		,	//	"distributed"	or	"block"	;
		parameter	ALMOST_EMPTY_OFFSET		=	'h8			,
		parameter	ALMOST_FULL_OFFSET		=	'h8			,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
		parameter	AW						=	9			,	//	write	port	deep	width
		parameter	DW						=	16			,	//	write	port	data	width
		parameter	QW						=	DW				//	read	port	data	width
	)(
		input	wire						RST				,
		input	wire						WRCLK			,
		
		input	wire						WREN			,
		input	wire	[DW	-1:0]			DI				,
		output	wire						ALMOSTFULL		,
		output	wire						FULL			,

		input	wire						WREN_CLEAR		,
		input	wire						WREN_LAST		,
		output	wire	[AW		:0]			WRCOUNT			,
		output	wire						WRERR			,

		input	wire						RDEN			,
		output	wire	[QW	-1:0]			DO				,
		output	wire						ALMOSTEMPTY		,
		output	wire						EMPTY			,
		input	wire						RDEN_LAST		,
		output	wire	[AW		:0]			RDCOUNT			,
		output	wire						RDERR			,

		input	wire						RDCLK			
	);
		
		generate
		
				wire				wclk_em	;
				wire				wclk_fu	;
				wire				rclk_em	;
				wire				rclk_fu	;
		
	//			wire	wclk_rd	=	~	(	wclk_em	||	wclk_fu	)	;
    //
	//			reg		[31:0]	wcnt_reg	=	0	;
	//			always@(posedge	WRCLK)	begin
	//				if(	RST	)	wcnt_reg	<=	0	;
	//				else	if(	WREN	&&	wclk_wr	)	wcnt_reg	<=	wcnt_reg	;
	//				else	if(	WREN	)	wcnt_reg	<=	wcnt_reg	+	1	;
	//				else	if(	wclk_wr	)	wcnt_reg	<=	wcnt_reg	-	1	;
	//				else	wcnt_reg	<=	wcnt_reg	;
	//			end
	//			
	//			assign	WRCOUNT	=	wcnt_reg	;
	//	
	//			wire	rclk_wr	=	~	(	rclk_em	||	rclk_fu	)	;
	//			
	//			reg		[31:0]	rcnt_reg	=	0	;
	//			always@(posedge	RDCLK)	begin
	//				if(	RST	)	rcnt_reg	<=	0	;
	//				else	if(	RDEN	&&	rclk_wr	)	rcnt_reg	<=	rcnt_reg	;
	//				else	if(	RDEN	)	rcnt_reg	<=	rcnt_reg	+	1	;
	//				else	if(	rclk_wr	)	rcnt_reg	<=	rcnt_reg	-	1	;
	//				else	rcnt_reg	<=	rcnt_reg	;
	//			end
	//			
	//			assign	RDCOUNT	=	rcnt_reg	;
		
			if(	DW	>	QW	)	begin
			
				wire	[DW	-1:0]	wclk_do	;
				wire	[DW	-1:0]	rclk_di	;

				hdl_eqw_sfifo	#(
					.	LOOP_NUM					(	LOOP_NUM					)	,
					.	RAM_STYLE					(	RAM_STYLE					)	,
					.	ALMOST_EMPTY_OFFSET			(	'h08						)	,
					.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
					.	FIRST_WORD_FALL_THROUGH		(	"TRUE"						)	,
					.	AW							(	AW							)	,
					.	DW							(	DW							)	
				)hdl_eqw_sfifo_w(
					.	WRCOUNT				(			WRCOUNT					)	,	//	output			[AW-1:0]			
					.	WRERR				(			WRERR					)	,	//	output								
					.	WREN				(			WREN					)	,	//	input								
					.	DI					(			DI						)	,	//	input			[DW	-1:0]			
					.	ALMOSTFULL			(			ALMOSTFULL				)	,	//	output								
					.	FULL				(			FULL					)	,	//	output								
					.	RDEN				(	~	(	wclk_em	||	wclk_fu	)	)	,	//	input								
					.	DO					(			wclk_do					)	,	//	output			[QW	-1:0]			
					.	ALMOSTEMPTY			(									)	,	//	output								
					.	EMPTY				(			wclk_em					)	,	//	output								
					.	RDCOUNT				(									)	,	//	output			[AW-1:0]			
					.	RDERR				(									)	,	//	output								
					.	RST					(			RST						)	,	//	input								
					.	CLK					(			WRCLK					)		//	input								
				);
				
				hdl_afifo_top	#(
					.	FWFT	(	"TRUE"	)	,
					.	DATA_WD	(	DW		)	
				)hdl_afifo_top	(
					.	rst					(			RST						)	,	//	input	wire					
					.	wclk				(			WRCLK					)	,	//	input	wire					
					.	wen					(	~	(	wclk_em	||	wclk_fu	)	)	,	//	input	wire					
					.	wdata				(			wclk_do					)	,	//	input	wire	[DATA_WD-1:0]	
					.	full				(			wclk_fu					)	,	//	output	wire					
					.	rclk				(			RDCLK					)	,	//	input	wire					
					.	ren					(	~	(	rclk_em	||	rclk_fu	)	)	,	//	input	wire					
					.	rdata				(			rclk_di					)	,	//	output	wire	[DATA_WD-1:0]	
					.	empty				(			rclk_em					)		//	output	wire					
				);
				
				hdl_exw_sfifo	#(
					.	LOOP_NUM					(	LOOP_NUM					)	,
					.	RAM_STYLE					(	RAM_STYLE					)	,
					.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
					.	ALMOST_FULL_OFFSET			(	'h08						)	,
					.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
					.	AW							(	AW							)	,
					.	DW							(	DW							)	,
					.	QW							(	QW							)	
				)hdl_exw_sfifo(
					.	WRCOUNT				(									)	,	//	output			[AW-1:0]			
					.	WRERR				(									)	,	//	output								
					.	WREN_CLEAR			(			1'b0					)	,	//	input								
					.	WREN_LAST			(			1'b0					)	,	//	input								
					.	WREN				(	~	(	rclk_em	||	rclk_fu	)	)	,	//	input								
					.	DI					(			rclk_di					)	,	//	input			[DW	-1:0]			
					.	ALMOSTFULL			(									)	,	//	output								
					.	FULL				(			rclk_fu					)	,	//	output								
					.	RDEN				(			RDEN					)	,	//	input								
					.	DO					(			DO						)	,	//	output			[QW	-1:0]			
					.	ALMOSTEMPTY			(			ALMOSTEMPTY				)	,	//	output								
					.	EMPTY				(			EMPTY					)	,	//	output								
					.	RDEN_LAST			(			RDEN_LAST				)	,	//	input								
					.	RDCOUNT				(			RDCOUNT					)	,	//	output			[AW-1:0]			
					.	RDERR				(			RDERR					)	,	//	output								
					.	RST					(			RST						)	,	//	input								
					.	CLK					(			RDCLK					)		//	input								
				);
				
			end	else	if(	DW	<	QW	)	begin
	
				wire	[QW	-1:0]	wclk_do	;
				wire	[QW	-1:0]	rclk_di	;
				
				hdl_exw_sfifo	#(
					.	LOOP_NUM					(	LOOP_NUM					)	,
					.	RAM_STYLE					(	RAM_STYLE					)	,
					.	ALMOST_EMPTY_OFFSET			(	'h08						)	,
					.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
					.	FIRST_WORD_FALL_THROUGH		(	"TRUE"						)	,
					.	AW							(	AW							)	,
					.	DW							(	DW							)	,
					.	QW							(	QW							)	
				)hdl_exw_sfifo_w(
					.	WRCOUNT				(			WRCOUNT					)	,	//	output			[AW-1:0]			
					.	WRERR				(			WRERR					)	,	//	output								
					.	WREN_CLEAR			(			WREN_CLEAR				)	,	//	input				
					.	WREN_LAST			(			WREN_LAST				)	,	//	input				
					.	WREN				(			WREN					)	,	//	input								
					.	DI					(			DI						)	,	//	input			[DW	-1:0]			
					.	ALMOSTFULL			(			ALMOSTFULL				)	,	//	output								
					.	FULL				(			FULL					)	,	//	output								
					.	RDEN				(	~	(	wclk_em	||	wclk_fu	)	)	,	//	input								
					.	DO					(			wclk_do					)	,	//	output			[QW	-1:0]			
					.	ALMOSTEMPTY			(									)	,	//	output								
					.	EMPTY				(			wclk_em					)	,	//	output								
					.	RDEN_LAST			(			1'b0					)	,	//	input								
					.	RDCOUNT				(									)	,	//	output			[AW-1:0]			
					.	RDERR				(									)	,	//	output								
					.	RST					(			RST						)	,	//	input								
					.	CLK					(			WRCLK					)		//	input								
				);
				
				hdl_afifo_top	#(
					.	FWFT	(	"TRUE"	)	,
					.	DATA_WD	(	QW		)	
				)hdl_afifo_top	(
					.	rst					(			RST						)	,	//	input	wire					
					.	wclk				(			WRCLK					)	,	//	input	wire					
					.	wen					(	~	(	wclk_em	||	wclk_fu	)	)	,	//	input	wire					
					.	wdata				(			wclk_do					)	,	//	input	wire	[DATA_WD-1:0]	
					.	full				(			wclk_fu					)	,	//	output	wire					
					.	rclk				(			RDCLK					)	,	//	input	wire					
					.	ren					(	~	(	rclk_em	||	rclk_fu	)	)	,	//	input	wire					
					.	rdata				(			rclk_di					)	,	//	output	wire	[DATA_WD-1:0]	
					.	empty				(			rclk_em					)		//	output	wire					
				);
				
				hdl_eqw_sfifo	#(
					.	LOOP_NUM					(	LOOP_NUM					)	,
					.	RAM_STYLE					(	RAM_STYLE					)	,
					.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
					.	ALMOST_FULL_OFFSET			(	'h08						)	,
					.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
					.	AW							(	AW							)	,
					.	DW							(	QW							)	
				)hdl_eqw_sfifo_r(
					.	WRCOUNT				(									)	,	//	output			[AW-1:0]			
					.	WRERR				(									)	,	//	output								
					.	WREN				(	~	(	rclk_em	||	rclk_fu	)	)	,	//	input								
					.	DI					(			rclk_di					)	,	//	input			[DW	-1:0]			
					.	ALMOSTFULL			(									)	,	//	output								
					.	FULL				(			rclk_fu					)	,	//	output								
					.	RDEN				(			RDEN					)	,	//	input								
					.	DO					(			DO						)	,	//	output			[QW	-1:0]			
					.	ALMOSTEMPTY			(			ALMOSTEMPTY				)	,	//	output								
					.	EMPTY				(			EMPTY					)	,	//	output								
					.	RDCOUNT				(			RDCOUNT					)	,	//	output			[AW-1:0]			
					.	RDERR				(			RDERR					)	,	//	output								
					.	RST					(			RST						)	,	//	input								
					.	CLK					(			RDCLK					)		//	input								
				);
				
				
			end	else	begin	//	if(	DW	==	QW	)	

				hdl_eqw_afifo	#(
					.	LOOP_NUM					(	LOOP_NUM				)	,
					.	RAM_STYLE					(	RAM_STYLE				)	,
					.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET		)	,
					.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET		)	,
					.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH	)	,
					.	AW							(	AW						)	,
					.	DW							(	DW						)	 
				)hdl_eqw_afifo_i(
					.	RST					(			RST						)	,	//	input	wire					
					.	WRCLK				(			WRCLK					)	,	//	input	wire					
					.	WRCOUNT				(			WRCOUNT					)	,	//	output	wire	[AWID:0]		
					.	WRERR				(			WRERR					)	,	//	output	wire					
					.	WREN				(			WREN					)	,	//	input	wire					
					.	DI					(			DI						)	,	//	input	wire	[DW	-1:0]		
					.	ALMOSTFULL			(			ALMOSTFULL				)	,	//	output	wire					
					.	FULL				(			FULL					)	,	//	output	wire					
					.	RDEN				(			RDEN					)	,	//	input	wire					
					.	DO					(			DO						)	,	//	output	wire	[DW	-1:0]		
					.	ALMOSTEMPTY			(			ALMOSTEMPTY				)	,	//	output	wire					
					.	EMPTY				(			EMPTY					)	,	//	output	wire					
					.	RDCOUNT				(			RDCOUNT					)	,	//	output	wire	[AWID:0]		
					.	RDERR				(			RDERR					)	,	//	output	wire					
					.	RDCLK				(			RDCLK					)		//	input	wire					
				);

			end
		endgenerate		
	endmodule	//	hdl_exw_afifo
`endif



`ifdef	exw_sfifo
	module	hdl_exw_sfifo	#(
		parameter	LOOP_NUM				= 	0				,
		parameter	RAM_STYLE				= 	"block"			,	//	"distributed"	or	"block"	;
		parameter	ALMOST_EMPTY_OFFSET		=	256				,
		parameter	ALMOST_FULL_OFFSET		=	256				,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"			,
		parameter	AW						=	9				,	//	THE DEEP WIDTH	OF WRITE PORT
		parameter	DW						=	16				,
		parameter	QW						=	64				
	)(
		input								WREN			,
		input			[DW	-1:0]			DI				,
		output								ALMOSTFULL		,
		output								FULL			,
	
		input								WREN_CLEAR		,
		input								WREN_LAST		,
		output			[AW		:0]			WRCOUNT			,
		output								WRERR			,
	
		input								RDEN			,
		output			[QW	-1:0]			DO				,
		output								ALMOSTEMPTY		,
		output								EMPTY			,
		input								RDEN_LAST		,
		output			[AW		:0]			RDCOUNT			,
		output								RDERR			,
	
		input								RST				,
		input								CLK				
	);
		
		localparam	MAX_DW	=	DW>QW	?	DW	:	QW			;
		localparam	MIN_AW	=	clogb2(DW*2**AW/MAX_DW)			;
		wire	 [MIN_AW:0] cnt_used;	assign	WRCOUNT	=cnt_used	;
		wire	 [MIN_AW:0] cnt_free;	assign	RDCOUNT	=cnt_free	;
				
	// genvar i;
		generate
			if(	DW	>	QW	)	begin

				wire							buf_rd			;
				wire	[DW	-1:0]				buf_do			;
				wire							buf_af			;	//	[FIFO_NUM	-1:0]
				wire							buf_fu			;	//	[FIFO_NUM	-1:0]
				wire							buf_ae			;	//	[FIFO_NUM	-1:0]
				wire							buf_em			;	//	[FIFO_NUM	-1:0]
	
				reg	[clogb2(DW/QW)-1:0]	rd_cnt	 = 0;
				assign					ALMOSTFULL	=	buf_af					;	
				assign					FULL		=	buf_fu					;	//buf_fu[0]	;	//
				assign					ALMOSTEMPTY	=	buf_ae	&&	(rd_cnt==0)	;	
				assign					EMPTY		=	buf_em	&&	(rd_cnt==0)	;	//buf_ae[0]	&&	(rd_cnt==0)	;//
	
				wire	dr_align	;
	
				always@(posedge	CLK)	begin
					if(RST)	begin
						rd_cnt	<=	0	;
					end	else	if(RDEN_LAST&&	!EMPTY	)begin
						rd_cnt	<=	0	;
					end	else	begin
						rd_cnt	<=	RDEN	&&	!EMPTY	?	rd_cnt	+	1	:	rd_cnt	;
					end
				end
	
				reg	[DW-QW-1:0]	buf_do_reg	=	0	;
				always@(posedge	CLK)	begin
					if(RST)	buf_do_reg	<=	0	;
					else	if(buf_rd)	buf_do_reg	<=	buf_do[QW+:DW-QW]	;
				end
	
				wire	[DW-1:0]	buf_do_reg_latch	;
				assign	buf_do_reg_latch	=	{	buf_do_reg	,	buf_do[0+:QW]	};
	
				assign	dr_align	=	rd_cnt	==	0	;
	
				assign	buf_rd	=	((dr_align		&&	RDEN)	)&&	!EMPTY;	//||	RDEN_LAST	;
				assign	DO	=	buf_do_reg_latch[rd_cnt*QW+:QW]	;
	
				hdl_sfifo_top #(
					.	RAM_STYLE  	(	RAM_STYLE					)	,	//	Specify RAM style: auto/block/distributed
					.	FWFT       	(	FIRST_WORD_FALL_THROUGH		)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
					.	DWID       	(	DW							)	,
					.	AWID       	(	MIN_AW						)	, 
					.	AFULL_TH   	(	ALMOST_FULL_OFFSET					)	, 
					.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET /2**(AW-MIN_AW)	)	, 
					.	DBG_WID    	(	32							)		
				)hdl_sfifo_top(
					.	clk			(	CLK				)	,   	// input						write clock
					.	rst			(	RST				)	,   	// input						write reset
					.	wen			(	WREN			)	,   	// input						Write enable
					.	wdata		(	DI				)	,   	// input		[DWID-1:0]		RAM input data
					.	afull		(	buf_af			)	,   	// output						
					.	full		(	buf_fu			)	,   	// output						
					.	nafull		(					)	,   	// output						
					.	nfull		(					)	,   	// output						
					.	cnt_used	(	cnt_used		)	,   	// output		[AWID:0]		the counter used in fifo for write clock domain
					.	woverflow	(	WRERR			)	,   	// output						
					.	ren			(	buf_rd			)	,   	// input						Read Enable
					.	rdata		(	buf_do			)	,   	// output		[DWID-1:0]		RAM output data
					.	aempty		(	buf_ae			)	,   	// output						
					.	empty		(	buf_em			)	,   	// output						
					.	naempty		(					)	,   	// output						
					.	nempty		(					)	,   	// output						
					.	cnt_free	(	cnt_free		)	,   	// output		[AWID:0]		the counter used in fifo for read clock domain 
					.	roverflow	(	RDERR			)	,   	// output						
					.	dbg_sig		(					)			// output		[DBG_WID-1:0]	debug signal
				);
				
			end	else	if(	DW	<	QW	)	begin
			
				wire							buf_wr			;
				wire	[QW	-1:0]				buf_di			;
				wire							buf_af			;	//	[FIFO_NUM	-1:0]
				wire							buf_fu			;	//	[FIFO_NUM	-1:0]
				wire							buf_ae			;	//	[FIFO_NUM	-1:0]
				wire							buf_em			;	//	[FIFO_NUM	-1:0]
	
				// reg		[QW-1:0]		buf_di_reg	=0	;
				// reg		[QW-DW-1:0]		buf_di_l	=0	;
	
				assign					ALMOSTFULL	=	buf_af	;		//	buf_af[0]	;
				assign					FULL		=	buf_fu	;		//	buf_af[0]	;	//	buf_fu[0]	;
				assign					ALMOSTEMPTY	=	buf_ae	;		//	buf_ae[0]	;
				assign					EMPTY		=	buf_em	;		//	buf_em[0]	;
	
				wire	dw_align	;
	
				reg	[clogb2(QW/DW)-1:0]	wr_cnt=0	;
				always@(posedge	CLK)	begin
					if(RST)	begin
						wr_cnt	<=	0	;
					end	else	if(buf_wr||WREN_CLEAR)begin
						wr_cnt	<=	0	;
					end	else	begin
						wr_cnt	<=	WREN	&&	!FULL	?	wr_cnt	+	1	:	wr_cnt	;	//buf_wr	?	0:
					end
				end
	
				assign	dw_align	=	wr_cnt	==	QW/DW	-1	;
	
				assign	buf_wr	=	(dw_align	&&	WREN	)	||	WREN_LAST	;
	
				reg		[	QW	-	1	:	0	]	buf_di_reg	=	0	;	always@(posedge	CLK)	buf_di_reg	<=	buf_wr	?	0	:	buf_di	;
	
				genvar k;
				for ( k=0; k<QW/DW; k=k+1 ) begin: dw_convert
					
					assign	buf_di[	k	*	DW	+:	DW	]	=	wr_cnt	==	k	?	DI	:	buf_di_reg[	k	*	DW	+:	DW	]	;
						
				end
	
				hdl_sfifo_top #(
					.	RAM_STYLE  	(	RAM_STYLE					)	,	//	Specify RAM style: auto/block/distributed
					.	FWFT       	(	FIRST_WORD_FALL_THROUGH		)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
					.	DWID       	(	MAX_DW						)	,
					.	AWID       	(	MIN_AW						)	, 
					.	AFULL_TH   	(	ALMOST_FULL_OFFSET	/2**(AW-MIN_AW)		)	, 
					.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET 					)	, 
					.	DBG_WID    	(	32										)		
				)hdl_sfifo_top(
					.	clk			(	CLK				)	,   	// input						write clock
					.	rst			(	RST				)	,   	// input						write reset
					.	wen			(	buf_wr			)	,   	// input						Write enable
					.	wdata		(	buf_di			)	,   	// input		[DWID-1:0]		RAM input data
					.	afull		(	buf_af			)	,   	// output						
					.	full		(	buf_fu			)	,   	// output						
					.	nafull		(					)	,   	// output						
					.	nfull		(					)	,   	// output						
					.	cnt_used	(	cnt_used		)	,   	// output		[AWID:0]		the counter used in fifo for write clock domain
					.	woverflow	(	WRERR			)	,   	// output						
					.	ren			(	RDEN			)	,   	// input						Read Enable
					.	rdata		(	DO				)	,   	// output		[DWID-1:0]		RAM output data
					.	aempty		(	buf_ae			)	,   	// output						
					.	empty		(	buf_em			)	,   	// output						
					.	naempty		(					)	,   	// output						
					.	nempty		(					)	,   	// output						
					.	cnt_free	(	cnt_free		)	,   	// output		[AWID:0]		the counter used in fifo for read clock domain 
					.	roverflow	(	RDERR			)	,   	// output						
					.	dbg_sig		(					)			// output		[DBG_WID-1:0]	debug signal
				);
				
			end	else	begin	//	if(	DW	==	QW	)
				
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
			end	//	if
		endgenerate
	
		function integer clogb2;
		input integer depth;
		integer depth_reg;
			begin
				depth_reg = depth;
				for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
				depth_reg = depth_reg >> 1;
				end
				if( 2**clogb2 >= depth*2 )begin
				clogb2 = clogb2 - 1;
				end
			end 
		endfunction
	
	endmodule	//	hdl_exw_sfifo
`endif








`ifdef	eqw_afifo	
	module	hdl_eqw_afifo	#(	//	equal	width	async	fifo
		parameter	LOOP_NUM				= 	0			,
		parameter	RAM_STYLE				= 	"block"		,
		parameter	ALMOST_EMPTY_OFFSET		=	'h8			,
		parameter	ALMOST_FULL_OFFSET		=	'h8			,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"		,
		parameter	AW						=	9			,//	write	port	deep	width
		parameter	DW						=	16			 //	write	port	data	width
	)(
		input	wire						RST				,
		input	wire						WRCLK			,
	
		output	wire	[AW		:0]			WRCOUNT			,
		output	wire						WRERR			,
		
		input	wire						WREN			,
		input	wire	[DW	-1:0]			DI				,
		output	wire						ALMOSTFULL		,
		output	wire						FULL			,
	
		input	wire						RDEN			,
		output	wire	[DW	-1:0]			DO				,
		output	wire						ALMOSTEMPTY		,
		output	wire						EMPTY			,
		
		output	wire	[AW		:0]			RDCOUNT			,
		output	wire						RDERR			,
	
		input	wire						RDCLK			
	);
		
				wire	[DW	-1:0]	wclk_do	;
				wire				wclk_em	;
				wire				wclk_fu	;
				
	
				wire	[DW	-1:0]	rclk_di	;
				wire				rclk_em	;
				wire				rclk_fu	;

				hdl_eqw_sfifo	#(
					.	LOOP_NUM					(	LOOP_NUM					)	,
					.	RAM_STYLE					(	RAM_STYLE					)	,
					.	ALMOST_EMPTY_OFFSET			(	'h08						)	,
					.	ALMOST_FULL_OFFSET			(	ALMOST_FULL_OFFSET			)	,
					.	FIRST_WORD_FALL_THROUGH		(	"TRUE"						)	,
					.	AW							(	AW							)	,
					.	DW							(	DW							)	
				)hdl_eqw_sfifo_w(
					.	WRCOUNT				(			WRCOUNT					)	,	//	output			[AW-1:0]			
					.	WRERR				(			WRERR					)	,	//	output								
					.	WREN				(			WREN					)	,	//	input								
					.	DI					(			DI						)	,	//	input			[DW	-1:0]			
					.	ALMOSTFULL			(			ALMOSTFULL				)	,	//	output								
					.	FULL				(			FULL					)	,	//	output								
					.	RDEN				(	~	(	wclk_em	||	wclk_fu	)	)	,	//	input								
					.	DO					(			wclk_do					)	,	//	output			[QW	-1:0]			
					.	ALMOSTEMPTY			(									)	,	//	output								
					.	EMPTY				(			wclk_em					)	,	//	output								
					.	RDCOUNT				(									)	,	//	output			[AW-1:0]			
					.	RDERR				(									)	,	//	output								
					.	RST					(			RST						)	,	//	input								
					.	CLK					(			WRCLK					)		//	input								
				);
				
				hdl_afifo_top	#(
					.	FWFT	(	"TRUE"	)	,
					.	DATA_WD	(	DW		)	
				)hdl_afifo_top	(
					.	rst					(			RST						)	,	//	input	wire					
					.	wclk				(			WRCLK					)	,	//	input	wire					
					.	wen					(	~	(	wclk_em	||	wclk_fu	)	)	,	//	input	wire					
					.	wdata				(			wclk_do					)	,	//	input	wire	[DATA_WD-1:0]	
					.	full				(			wclk_fu					)	,	//	output	wire					
					.	rclk				(			RDCLK					)	,	//	input	wire					
					.	ren					(	~	(	rclk_em	||	rclk_fu	)	)	,	//	input	wire					
					.	rdata				(			rclk_di					)	,	//	output	wire	[DATA_WD-1:0]	
					.	empty				(			rclk_em					)		//	output	wire					
				);
				
				hdl_eqw_sfifo	#(
					.	LOOP_NUM					(	LOOP_NUM					)	,
					.	RAM_STYLE					(	RAM_STYLE					)	,
					.	ALMOST_EMPTY_OFFSET			(	ALMOST_EMPTY_OFFSET			)	,
					.	ALMOST_FULL_OFFSET			(	'h08						)	,
					.	FIRST_WORD_FALL_THROUGH		(	FIRST_WORD_FALL_THROUGH		)	,
					.	AW							(	AW							)	,
					.	DW							(	DW							)	
				)hdl_eqw_sfifo_r(
					.	WRCOUNT				(									)	,	//	output			[AW-1:0]			
					.	WRERR				(									)	,	//	output								
					.	WREN				(	~	(	rclk_em	||	rclk_fu	)	)	,	//	input								
					.	DI					(			rclk_di					)	,	//	input			[DW	-1:0]			
					.	ALMOSTFULL			(									)	,	//	output								
					.	FULL				(			rclk_fu					)	,	//	output								
					.	RDEN				(			RDEN					)	,	//	input								
					.	DO					(			DO						)	,	//	output			[QW	-1:0]			
					.	ALMOSTEMPTY			(			ALMOSTEMPTY				)	,	//	output								
					.	EMPTY				(			EMPTY					)	,	//	output								
					.	RDCOUNT				(			RDCOUNT					)	,	//	output			[AW-1:0]			
					.	RDERR				(			RDERR					)	,	//	output								
					.	RST					(			RST						)	,	//	input								
					.	CLK					(			RDCLK					)		//	input								
				);
	
	endmodule	//	hdl_eqw_afifo
`endif
















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
	output			[AW		:0]			WRCOUNT			,
	output								WRERR			,

	input								RDEN			,
	output			[DW	-1:0]			DO				,
	output								ALMOSTEMPTY		,
	output								EMPTY			,
	output			[AW		:0]			RDCOUNT			,
	output								RDERR			,
	
	input								RST				,
	input								CLK				
);

	wire	 [AW:0] cnt_used;	assign	WRCOUNT	=	cnt_used	;
	wire	 [AW:0] cnt_free;	assign	RDCOUNT	=	cnt_free	;

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

endmodule	//	hdl_eqw_sfifo












`ifdef SFIFO_HDL

module	FIFO_SYNCCLOCK_HDL	#(
	parameter	LOOP_NUM				= 	0				,
	parameter	DEVICE					= 	"7SERIES"		,
	parameter	RAM_STYLE				= 	"distributed"	,
	parameter	ALMOST_EMPTY_OFFSET		=	256				,
	parameter	ALMOST_FULL_OFFSET		=	256				,
	parameter	FIFO_SIZE				=	"18Kb"			,
	parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"			,
	parameter	AW						=	5				,
	parameter	DATA_WIDTH				=	32				
)(
	input								WREN			,
	input			[DATA_WIDTH	-1:0]	DI				,
	output								ALMOSTFULL		,
	output								FULL			,
	output			[AW		:0]			WRCOUNT			,
	output								WRERR			,

	input								RDEN			,
	output			[DATA_WIDTH	-1:0]	DO				,
	output								ALMOSTEMPTY		,
	output								EMPTY			,
	output			[AW		:0]			RDCOUNT			,
	output								RDERR			,
	
	input								RST				,
	input								WRCLK			,
	input								RDCLK				
);

	localparam  DW	= DATA_WIDTH	;

	wire	CLK	=	WRCLK	;

	wire	 [31:0] cnt_used;	assign	WRCOUNT	=	cnt_used	;
	wire	 [31:0] cnt_free;	assign	RDCOUNT	=	cnt_free	;

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

endmodule	//	hdl_eqw_sfifo

`endif








	module	hdl_sfifo_top	#(
		parameter	RAM_STYLE	=	"block"					,	//	Specify	RAM	style:	auto/block/distributed
		parameter	FWFT		=	"TRUE"					,	//	Sets	the	FIfor	FWFT	to	"TRUE"	or	"FALSE"
		parameter	DWID		=	18						,
		parameter	AWID		=	6						,	
		parameter	AFULL_TH	=	4						,	
		parameter	AEMPTY_TH	=	4						,	
		parameter	DBG_WID		=	32			
	)	(
		input	wire					clk					,	//	write	clock
		input	wire					rst					,	//	write	reset
		input	wire					wen					,	//	Write	enable
		input	wire	[DWID-1:0]		wdata				,	//	RAM	input	data
		output	wire					full				,	//	
		output	wire					nfull				,	//	
		output	wire					afull				,	//	
		output	wire					nafull				,	//	
		output	wire					woverflow			,	//	
		output	wire	[AWID:0]		cnt_free			,	//	the	counter	used	in	fifo	for	read	clock	domain	
		input	wire					ren					,	//	Read	Enable
		output	wire	[DWID-1:0]		rdata				,	//	RAM	output	data
		output	wire					empty				,	//	
		output	wire					nempty				,	//	
		output	wire					aempty				,	//	
		output	wire					naempty				,	//	
		output	wire					roverflow			,	//	
		output	wire	[AWID:0]		cnt_used			,	//	the	counter	used	in	fifo	for	write	clock	domain
		output	wire	[DBG_WID-1:0]	dbg_sig					//	debug	signal
	);

				wire	[DWID	-1:0]	r_fifo_do			;	//	
				wire					r_fifo_em			;	//	
				wire					r_fifo_rd			;	//		
					
				wire					r_fifo_nem			;	//		
				wire					r_fifo_ae			;	//		
				wire					r_fifo_nae			;	//		
				wire					r_roverflow			;	//		
				wire	[AWID:0]		r_cnt_used			;	//		
				wire	[AWID:0]		r_cnt_free			;	//		

		generate
			 if( FWFT=="TRUE" ) begin : FWFT_DOUT1
				
				reg						t_fifo_em		=1	;
				reg		[DWID	-1:0]	t_fifo_do		=0	;
				wire					t_fifo_rd			;
			
				reg						t_fifo_nem		=	0	;	//		
				reg						t_fifo_ae		=	1	;	//		
				reg						t_fifo_nae		=	0	;	//		
				reg						t_roverflow		=	0	;	//		
				reg		[AWID	:0]		t_cnt_used		=	0	;	//		
				reg		[AWID	:0]		t_cnt_free		=	2**AWID	;	//		
				
				always@(posedge	clk)	t_fifo_em	<=	rst	?	1	:	r_fifo_rd	?	1'b0		:	t_fifo_rd	?	1'b1	:	t_fifo_em	;
				always@(posedge	clk)	t_fifo_do	<=	rst	?	0	:	r_fifo_rd	?	r_fifo_do	:	t_fifo_do	;
			
				assign	r_fifo_rd	=	~	r_fifo_em	&&	(	t_fifo_rd	||	t_fifo_em	)	;	
				
				always@(posedge	clk)	t_fifo_nem	<=	rst	?	0	:	r_fifo_rd	?	1'b1		:	t_fifo_rd	?	1'b0	:	t_fifo_nem	;
							
				always@(posedge	clk)	t_fifo_ae	<=	rst	?	1	:	r_fifo_ae		;
				always@(posedge	clk)	t_fifo_nae	<=	rst	?	0	:	r_fifo_nae		;

				always@(posedge	clk	)	t_cnt_used		<=	rst	?	0			:	t_cnt_used	+	(	wen	&&	nfull	)	-	(	ren	&&	nempty	)	;
				always@(posedge	clk	)	t_cnt_free		<=	rst	?	2**AWID		:	t_cnt_free	-	(	wen	&&	nfull	)	+	(	ren	&&	nempty	)	;

				always@(posedge	clk)	t_roverflow	<=	rst	?	0	:	t_fifo_em	&&	t_fifo_rd	;
				
			
				assign	rdata		=	t_fifo_do	;
				assign	empty		=	t_fifo_em	;
				assign	t_fifo_rd	=	ren			;
				assign	nempty		=	t_fifo_nem	;
				assign	aempty		=	t_fifo_ae	;
				assign	naempty		=	t_fifo_nae	;
				assign	roverflow	=	t_roverflow	;
				assign	cnt_used	=	t_cnt_used	;
				assign	cnt_free	=	t_cnt_free	;
				
				wire	rd_err	=	t_fifo_em	&&	t_fifo_rd	;
				
	
				
				always@( posedge clk )begin
					if( rd_err ) begin // fifo is empty and read
							/* synthesis translate_off */
							$display("%t, %m, ERROR: roverflow happen_xxxxx_", $time );
							#100;
							$stop;
							/* synthesis translate_on */
					end
				end
				
				// assign	rdata		=	r_fifo_do	;
				// assign	empty		=	r_fifo_em	;
				// assign	r_fifo_rd	=	ren		;
				// assign	nempty		=	r_fifo_nem			;
				// assign	aempty		=	r_fifo_ae			;
				// assign	naempty		=	r_fifo_nae			;
				// assign	roverflow	=	r_roverflow			;
				// assign	cnt_used	=	r_cnt_used			;
				// assign	cnt_free	=	r_cnt_free			;
				
			end	else  begin : REG_DOUT1

				assign	rdata		=	r_fifo_do	;
				assign	empty		=	r_fifo_em	;
				assign	r_fifo_rd	=	ren		;
				
				assign	nempty		=	r_fifo_nem			;
				assign	aempty		=	r_fifo_ae			;
				assign	naempty		=	r_fifo_nae			;
				assign	roverflow	=	r_roverflow			;
				assign	cnt_used	=	r_cnt_used			;
				assign	cnt_free	=	r_cnt_free			;
		
			end
		endgenerate

	hdl_sfifo_top_normal	#(
		.	RAM_STYLE			(		RAM_STYLE			)	,	//	Specify	RAM	style:	auto/block/distributed
		.	FWFT				(		FWFT				)	,	//	Sets	the	FIfor	FWFT	to	"TRUE"	or	"FALSE"
		.	DWID				(		DWID				)	,
		.	AWID				(		AWID				)	,	
		.	AFULL_TH			(		AFULL_TH			)	,	
		.	AEMPTY_TH			(		AEMPTY_TH			)	,	
		.	DBG_WID				(		DBG_WID				)
	)hdl_sfifo_top_normal_i(
		.	clk					(		clk					)		,	//	input	wire					write	clock
		.	rst					(		rst					)		,	//	input	wire					write	reset
		.	wen					(		wen					)		,	//	input	wire					Write	enable
		.	wdata				(		wdata				)		,	//	input	wire	[DWID-1:0]		RAM	input	data
		.	full				(		full				)		,	//	output	wire					
		.	nfull				(		nfull				)		,	//	output	wire					
		.	afull				(		afull				)		,	//	output	wire					
		.	nafull				(		nafull				)		,	//	output	wire					
		.	woverflow			(		woverflow			)		,	//	output	wire					
		.	cnt_free			(		r_cnt_free			)		,	//	output	wire	[AWID:0]		the	counter	used	in	fifo	for	read	clock	domain	
		.	ren					(		r_fifo_rd			)		,	//	input	wire					Read	Enable
		.	rdata				(		r_fifo_do			)		,	//	output	wire	[DWID-1:0]		RAM	output	data
		.	empty				(		r_fifo_em			)		,	//	output	wire					
		.	nempty				(		r_fifo_nem			)		,	//	output	wire					
		.	aempty				(		r_fifo_ae			)		,	//	output	wire					
		.	naempty				(		r_fifo_nae			)		,	//	output	wire					
		.	roverflow			(		r_roverflow			)		,	//	output	wire					
		.	cnt_used			(		r_cnt_used			)		,	//	output	wire	[AWID:0]		the	counter	used	in	fifo	for	write	clock	domain
		.	dbg_sig				(		dbg_sig				)			//	output	wire	[DBG_WID-1:0]	debug	signal
	);

endmodule




	module hdl_sfifo_top_normal #(
		parameter	RAM_STYLE	=	"block"					,	//	Specify	RAM	style:	auto/block/distributed
		parameter	FWFT		=	"TRUE"					,	//	Sets	the	FIfor	FWFT	to	"TRUE"	or	"FALSE"
		parameter	DWID		=	18						,
		parameter	AWID		=	6						,	
		parameter	AFULL_TH	=	4						,	
		parameter	AEMPTY_TH	=	4						,	
		parameter	DBG_WID		=	32			
	)	(
		input	wire					clk					,	//	write	clock
		input	wire					rst					,	//	write	reset
		input	wire					wen					,	//	Write	enable
		input	wire	[DWID-1:0]		wdata				,	//	RAM	input	data
		output	wire					full				,	//	
		output	wire					nfull				,	//	
		output	wire					afull				,	//	
		output	wire					nafull				,	//	
		output	wire					woverflow			,	//	
		output	wire	[AWID:0]		cnt_free			,	//	the	counter	used	in	fifo	for	read	clock	domain	
		input	wire					ren					,	//	Read	Enable
		output	wire	[DWID-1:0]		rdata				,	//	RAM	output	data
		output	wire					empty				,	//	
		output	wire					nempty				,	//	
		output	wire					aempty				,	//	
		output	wire					naempty				,	//	
		output	wire					roverflow			,	//	
		output	wire	[AWID:0]		cnt_used			,	//	the	counter	used	in	fifo	for	write	clock	domain
		output	wire	[DBG_WID-1:0]	dbg_sig					//	debug	signal
	);
	wire [DWID-1:0]         rdata_t;

	reg [DWID-1:0]         rdata_r	=	0;

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

endmodule	//	hdl_sfifo_top











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









	module fifo_addr_logic #(
		parameter AWID       = 10
	) (
	  input 		    clk,                          // write clock
	  input 		    rst,                          // write reset
	  input 		    enb,                          // nfull control
	  input 		    inc,                          // Write enable
	(* max_fanout=50 *)output reg  [AWID-1:0]    addr                          // fifo_addr
	);

	//////////////////////////////////////////////////////////////////////////////////
	//      mem instance
	//////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk or posedge rst) begin
			if( rst==1'b1 ) begin
					addr <= 0;
			end
			else begin
					if( inc==1'b1 && enb==1'b1 )begin
							addr <= addr + 1'b1;
					end
			end
	end

	endmodule











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











	module fifo_rdif_tf #(
			parameter DWID       = 18, 
			parameter AWID       = 10
	) (
	  //old
			input                     clk,                          // Read clock
			input                     rst,                          // Read reset 
	  //old read interface
			output reg                old_ren,                           // Read Enable
			input  [DWID-1:0]         old_rdata,                         // RAM output data
			input                     old_nempty,                        // 

	  //new read interface
			input                     new_ren,                           // Read Enable
			output     [DWID-1:0]     new_rdata,                         // RAM output data
			output reg                new_empty,                        // 
			output reg                new_nempty,                        // 
			output reg                new_roverflow                      // 
	);

	//////////////////////////////////////////////////////////////////////////////////
	//      
	//////////////////////////////////////////////////////////////////////////////////
	always@( * )begin
			if ( old_nempty==1'b1 && new_nempty==1'b0 ) begin
					old_ren = 1'b1;
			end
			else if( old_nempty==1'b1 && new_ren==1'b1 ) begin
					old_ren = 1'b1;
			end
			else begin
					old_ren = 1'b0;
			end
	end

	always@( posedge clk or posedge rst )begin
			if( rst==1'b1 ) begin
					new_empty <= 1'b1;
					new_nempty <= 1'b0;
			end
			else begin
					if( old_ren==1'b1 ) begin // old fifo is read
							new_empty <= 1'b0;
							new_nempty <= 1'b1;
					end
					else if( new_ren==1'b1 )begin //new fifo is read and old fifo is empty
							new_empty <= 1'b1;
							new_nempty <= 1'b0;
					end
			end
	end

	(* max_fanout=50 *)reg                old_ren_dly;
	reg [DWID-1:0]     old_rdata_latch	=	0	;           // RAM output latch

	///////////for timing opt,the old_rdata_latch's rst is removed
	always@( posedge clk or posedge rst )begin
			if( rst==1'b1 ) begin
					old_ren_dly <= 1'b0;
					//old_rdata_latch <= 0;
			end
			else begin
					old_ren_dly <= old_ren;
					//if( old_ren_dly==1'b1 ) begin
					//        old_rdata_latch <= old_rdata;
					//end
			end
	end

	always@( posedge clk  )begin

		if( old_ren_dly==1'b1 ) begin
				old_rdata_latch <= old_rdata;
		end

	end
	//////////

	assign new_rdata = (old_ren_dly==1'b1) ? old_rdata : old_rdata_latch;


	always@( posedge clk or posedge rst )begin
			if( rst==1'b1 ) begin
					new_roverflow <= 1'b0;
			end
			else begin
					if( new_ren==1'b1 && new_nempty==1'b0 ) begin // fifo is empty and read
							new_roverflow <= 1'b1;
							/* synthesis translate_off */
							$display("%t, %m, ERROR: roverflow happen", $time );
							#100;
							$stop;
							/* synthesis translate_on */
					end
			end
	end

	endmodule




















	module fifo_empty_logic #(
		parameter AWID             = 10   ,
		parameter AEMPTY_TH        = 4    ,
		parameter FLAG_ENABLE_STOP = 1'b1
	) (
	  input 					rclk,                           // write clock
	  input 					rrst,                           // write reset
	  input 					ren ,                           // write enable
	  input  [AWID-1:0]			raddr,                          // write addr 
	  input  [AWID-1:0]			waddr,                          // read  addr                       // 
	  output reg                nempty,                          // 
	  output reg                aempty,                         // 
	  output reg                naempty,                         // 
	  output reg                roverflow,                      // 
	  output reg [AWID:0]       cnt_used                        // cnt of used space
	);

	//////////////////////////////////////////////////////////////////////////////////
	//       signal define
	//////////////////////////////////////////////////////////////////////////////////
	reg  [AWID-1:0]			waddr_dly;                         //the last raddr
	wire [AWID-1:0]         cnt_used_comb;
	assign cnt_used_comb = waddr - raddr;

	//////////////////////////////////////////////////////////////////////////////////
	//       raddr_dly process
	//////////////////////////////////////////////////////////////////////////////////
	always@(posedge rclk or posedge rrst) begin
			if( rrst==1'b1 ) begin
					waddr_dly <= 0;
			end
			else begin
					waddr_dly <= waddr;
			end
	end


	//////////////////////////////////////////////////////////////////////////////////
	//       nempty process
	//////////////////////////////////////////////////////////////////////////////////
	always@(posedge rclk or posedge rrst) begin
			if( rrst==1'b1 ) begin
					nempty <= 1'b0;
			end
			else begin
					if( ren==1'b1 && cnt_used_comb==1 )begin  //the num of used space is 1 and it is used by ren
							nempty <= 1'b0;
					end
					else if( waddr!=waddr_dly ) begin
							nempty <= 1'b1;
					end
			end
	end

	//////////////////////////////////////////////////////////////////////////////////
	//       naempty process
	//////////////////////////////////////////////////////////////////////////////////
	always@(posedge rclk or posedge rrst) begin
			if( rrst==1'b1 ) begin
					aempty <= 1'b1;
					naempty <= 1'b0;
			end
			else begin
					if( cnt_used_comb < AEMPTY_TH  && cnt_used_comb!=0 || nempty==1'b0 )begin  //the num of used space is less than AFULL_TH  and it is used by ren
							aempty <= 1'b1;
							naempty <= 1'b0;
					end
					else if( waddr!=waddr_dly ) begin
							aempty <= 1'b0;
							naempty <= 1'b1;
					end
			end
	end

	//////////////////////////////////////////////////////////////////////////////////
	//       roverflow process
	//////////////////////////////////////////////////////////////////////////////////
	//wire flag_enable_stop;
	//assign flag_enable_stop = 1'b1;
	always@(posedge rclk or posedge rrst) begin
			if( rrst==1'b1 ) begin
					roverflow <= 1'b0;
			end
			else begin
					if( ren==1'b1 && nempty==1'b0 )begin
							roverflow <= 1'b1;
							/* synthesis translate_off */
							$error("%t, %m, ERROR: roverflow happen", $time );
							#1000;
							if( FLAG_ENABLE_STOP==1'b1 ) begin
									$stop;
							end
							/* synthesis translate_on */
					end
			end
	end


	//////////////////////////////////////////////////////////////////////////////////
	//       cnt_free process
	//////////////////////////////////////////////////////////////////////////////////
	always@(posedge rclk or posedge rrst) begin
			if( rrst==1'b1 ) begin
				cnt_used <= 0;
			end
			else begin
					if( waddr==raddr && nempty==1'b1 )begin //fifo is full
							cnt_used <= 2**AWID;
					end
					else begin
							cnt_used <= cnt_used_comb;
					end
			end
	end

	endmodule



















	module xilinx_simple_dual_port_1_clock_bram #(
	  parameter RAM_WIDTH = 18,                       // Specify RAM data width
	  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entires)
	  //parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	) (
	  input [clogb2(RAM_DEPTH)-1:0] addra, // Write address bus, width determined from RAM_DEPTH
	  input [clogb2(RAM_DEPTH)-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
	  input [RAM_WIDTH-1:0] dina,          // RAM input data
	  input clka,                          // Clock
	  input wea,                           // Write enable
	  input enb,                           // Read Enable, for additional power savings, disable when not in use
	  input rstb,                          // Output reset (does not affect memory contents)
	  input regceb,                        // Output register enable
	  output [RAM_WIDTH-1:0] doutb         // RAM output data
	);

	  (* ram_extract="yes", ram_style="block" *) reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
	  reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

	  // The folowing code either initializes the memory values to a specified file or to all zeros to match hardware
	  generate
		if (INIT_FILE != "") begin: use_init_file
		  initial begin
			$readmemh(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
		  end
		/* synthesis translate_off */ 
		  initial begin
		$display("INIT_FILE=%s", INIT_FILE);
		  end
		/* synthesis translate_on */ 
		end else begin: init_bram_to_zero
		  integer ram_index;
		  initial
			for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
			  BRAM[ram_index] = {RAM_WIDTH{1'b0}};
		end
	  endgenerate

	  always @(posedge clka) begin
		if (wea)
		  BRAM[addra] <= dina; 
		if (enb)
		  ram_data <= BRAM[addrb];
	  end        

	  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
	  generate
		if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

		  // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
		   assign doutb = ram_data;

		end else begin: output_register

		  // The following is a 2 clock cycle read latency with improve clock-to-out timing

		  reg [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

		  always @(posedge clka)
			if (rstb)
			  doutb_reg <= {RAM_WIDTH{1'b0}};
			else if (regceb)
			  doutb_reg <= ram_data;

		  assign doutb = doutb_reg;

		end
	  endgenerate

	//  The following function calculates the address width based on specified RAM depth
	function integer clogb2;
	  input integer depth;
	  integer depth_reg;
		begin
			depth_reg = depth;
			for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
			  depth_reg = depth_reg >> 1;
			end
			if( 2**clogb2 >= depth*2 )begin
			  clogb2 = clogb2 - 1;
			end
		end 
	endfunction

	endmodule

	// The following is an instantiation template for xilinx_simple_dual_port_1_clock_ram
	/*
	//  Xilinx Simple Dual Port Single Clock RAM
	  xilinx_simple_dual_port_1_clock_ram #(
		.RAM_WIDTH(18),                       // Specify RAM data width
		.RAM_DEPTH(1024),                     // Specify RAM depth (number of entires)
		.RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
		.INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	  ) your_instance_name (
		.addra(addra),   // Write address bus, width determined from RAM_DEPTH
		.addrb(addrb),   // Read address bus, width determined from RAM_DEPTH
		.dina(dina),     // RAM input data, width determined from RAM_WIDTH
		.clka(clka),     // Clock
		.wea(wea),       // Write enable
		.enb(enb),	     // Read Enable, for additional power savings, disable when not in use
		.rstb(rstb),     // Output reset (does not affect memory contents)
		.regceb(regceb), // Output register enable
		.doutb(doutb)    // RAM output data, width determined from RAM_WIDTH
	  );
	*/








	module xilinx_simple_dual_port_1_clock_dram #(
	  parameter RAM_WIDTH = 18,                       // Specify RAM data width
	  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entires)
	  //parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	) (
	  input [clogb2(RAM_DEPTH)-1:0] addra, // Write address bus, width determined from RAM_DEPTH
	  input [clogb2(RAM_DEPTH)-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
	  input [RAM_WIDTH-1:0] dina,          // RAM input data
	  input clka,                          // Clock
	  input wea,                           // Write enable
	  input enb,                           // Read Enable, for additional power savings, disable when not in use
	  input rstb,                          // Output reset (does not affect memory contents)
	  input regceb,                        // Output register enable
	  output [RAM_WIDTH-1:0] doutb         // RAM output data
	);

	  (* ram_extract="yes", ram_style="distributed" *) reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
	  reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

	  // The folowing code either initializes the memory values to a specified file or to all zeros to match hardware
	  generate
		if (INIT_FILE != "") begin: use_init_file
		  initial
			$readmemh(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
		end else begin: init_bram_to_zero
		  integer ram_index;
		  initial
			for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
			  BRAM[ram_index] = {RAM_WIDTH{1'b0}};
		end
	  endgenerate

	  always @(posedge clka) begin
		if (wea)
		  BRAM[addra] <= dina; 
		if (enb)
		  ram_data <= BRAM[addrb];
	  end        

	  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
	  generate
		if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

		  // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
		   assign doutb = ram_data;

		end else begin: output_register

		  // The following is a 2 clock cycle read latency with improve clock-to-out timing

		  reg [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

		  always @(posedge clka)
			if (rstb)
			  doutb_reg <= {RAM_WIDTH{1'b0}};
			else if (regceb)
			  doutb_reg <= ram_data;

		  assign doutb = doutb_reg;

		end
	  endgenerate

	//  The following function calculates the address width based on specified RAM depth
	function integer clogb2;
	  input integer depth;
	  integer depth_reg;
		begin
			depth_reg = depth;
			for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
			  depth_reg = depth_reg >> 1;
			end
			if( 2**clogb2 >= depth*2 )begin
			  clogb2 = clogb2 - 1;
			end
		end 
	endfunction

	endmodule

	// The following is an instantiation template for xilinx_simple_dual_port_1_clock_ram
	/*
	//  Xilinx Simple Dual Port Single Clock RAM
	  xilinx_simple_dual_port_1_clock_ram #(
		.RAM_WIDTH(18),                       // Specify RAM data width
		.RAM_DEPTH(1024),                     // Specify RAM depth (number of entires)
		.RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
		.INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	  ) your_instance_name (
		.addra(addra),   // Write address bus, width determined from RAM_DEPTH
		.addrb(addrb),   // Read address bus, width determined from RAM_DEPTH
		.dina(dina),     // RAM input data, width determined from RAM_WIDTH
		.clka(clka),     // Clock
		.wea(wea),       // Write enable
		.enb(enb),	     // Read Enable, for additional power savings, disable when not in use
		.rstb(rstb),     // Output reset (does not affect memory contents)
		.regceb(regceb), // Output register enable
		.doutb(doutb)    // RAM output data, width determined from RAM_WIDTH
	  );
	*/













	module xilinx_simple_dual_port_1_clock_ram #(
	  parameter RAM_WIDTH = 18,                       // Specify RAM data width
	  parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entires)
	  //parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	) (
	  input [clogb2(RAM_DEPTH)-1:0] addra, // Write address bus, width determined from RAM_DEPTH
	  input [clogb2(RAM_DEPTH)-1:0] addrb, // Read address bus, width determined from RAM_DEPTH
	  input [RAM_WIDTH-1:0] dina,          // RAM input data
	  input clka,                          // Clock
	  input wea,                           // Write enable
	  input enb,                           // Read Enable, for additional power savings, disable when not in use
	  input rstb,                          // Output reset (does not affect memory contents)
	  input regceb,                        // Output register enable
	  output [RAM_WIDTH-1:0] doutb         // RAM output data
	);

	  reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
	  reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

	  // The folowing code either initializes the memory values to a specified file or to all zeros to match hardware
	  generate
		if (INIT_FILE != "") begin: use_init_file
		  initial
			$readmemh(INIT_FILE, BRAM, 0, RAM_DEPTH-1);
		end else begin: init_bram_to_zero
		  integer ram_index;
		  initial
			for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
			  BRAM[ram_index] = {RAM_WIDTH{1'b0}};
		end
	  endgenerate

	  always @(posedge clka) begin
		if (wea)
		  BRAM[addra] <= dina; 
		if (enb)
		  ram_data <= BRAM[addrb];
	  end        

	  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
	  generate
		if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

		  // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
		   assign doutb = ram_data;

		end else begin: output_register

		  // The following is a 2 clock cycle read latency with improve clock-to-out timing

		  reg [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

		  always @(posedge clka)
			if (rstb)
			  doutb_reg <= {RAM_WIDTH{1'b0}};
			else if (regceb)
			  doutb_reg <= ram_data;

		  assign doutb = doutb_reg;

		end
	  endgenerate

	//  The following function calculates the address width based on specified RAM depth
	function integer clogb2;
	  input integer depth;
	  integer depth_reg;
		begin
			depth_reg = depth;
			for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
			  depth_reg = depth_reg >> 1;
			end
			if( 2**clogb2 >= depth*2 )begin
			  clogb2 = clogb2 - 1;
			end
		end 
	endfunction

	endmodule

	// The following is an instantiation template for xilinx_simple_dual_port_1_clock_ram
	/*
	//  Xilinx Simple Dual Port Single Clock RAM
	  xilinx_simple_dual_port_1_clock_ram #(
		.RAM_WIDTH(18),                       // Specify RAM data width
		.RAM_DEPTH(1024),                     // Specify RAM depth (number of entires)
		.RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
		.INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	  ) your_instance_name (
		.addra(addra),   // Write address bus, width determined from RAM_DEPTH
		.addrb(addrb),   // Read address bus, width determined from RAM_DEPTH
		.dina(dina),     // RAM input data, width determined from RAM_WIDTH
		.clka(clka),     // Clock
		.wea(wea),       // Write enable
		.enb(enb),	     // Read Enable, for additional power savings, disable when not in use
		.rstb(rstb),     // Output reset (does not affect memory contents)
		.regceb(regceb), // Output register enable
		.doutb(doutb)    // RAM output data, width determined from RAM_WIDTH
	  );
	*/















`ifdef AFIFO_LITE

	module	FIFO_DUALCLOCK_LITE	#(
		parameter	DEVICE					=	"7SERIES"	,		//	Target	Device:	"7SERIES"	
		parameter	ALMOST_EMPTY_OFFSET		=	9'h100		,		//	Sets	the	almost	empty	threshold
		parameter	ALMOST_FULL_OFFSET		=	9'h100		,		//	Sets	almost	full	threshold
		parameter	DATA_WIDTH				=	32			,		//	Valid	values	are	1-72	(37-72	only	valid	when	FIFO_SIZE="36Kb")
		parameter	FIFO_SIZE				=	"18Kb"		,		//	Target	BRAM:	"18Kb"	or	"36Kb"	
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"				// Sets the FIfor FWFT to "TRUE" or "FALSE"
	)(
			input	wire						RST				,
			input	wire						WRCLK			,
			
			input	wire						WREN			,
			input	wire	[DATA_WIDTH	-1:0]	DI				,
			output	wire						ALMOSTFULL		,
			output	wire						FULL			,

			output	wire	[AWID:0]			WRCOUNT			,
			output	wire						WRERR			,

			input	wire						RDEN			,
			output	wire	[DATA_WIDTH	-1:0]	DO				,
			output	wire						ALMOSTEMPTY		,
			output	wire						EMPTY			,
			output	wire	[AWID:0]			RDCOUNT			,
			output	wire						RDERR			,

			input	wire						RDCLK			
		);

			assign	ALMOSTFULL	=	0	;
			assign	WRCOUNT		=	0	;
			assign	WRERR		=	0	;
			assign	ALMOSTEMPTY	=	0	;
			assign	RDCOUNT		=	0	;
			assign	RDERR		=	0	;

			hdl_afifo_top	#(
				.	FWFT	(	FIRST_WORD_FALL_THROUGH	)	,
				.	DATA_WD	(	DATA_WIDTH				)	
			)hdl_afifo_top	(
				.	rst					(			RST						)	,	//	input	wire					
				.	wclk				(			WRCLK					)	,	//	input	wire					
				.	wen					(			WREN					)	,	//	input	wire					
				.	wdata				(			DI						)	,	//	input	wire	[DATA_WD-1:0]	
				.	full				(			FULL					)	,	//	output	wire					
				.	rclk				(			RDCLK					)	,	//	input	wire					
				.	ren					(			RDEN					)	,	//	input	wire					
				.	rdata				(			DO						)	,	//	output	wire	[DATA_WD-1:0]	
				.	empty				(			EMPTY					)		//	output	wire					
			);
			
	endmodule

`endif




















	//	module	hdl_afifo_top	#(
	//		parameter	FWFT	=	"TRUE"	,
	//		parameter	DATA_WD	=	8		
	//	)(
	//		input	wire					rst,
	//	
	//		input	wire					wclk,
	//		input	wire					wen,
	//		input	wire	[DATA_WD-1:0]	wdata,
	//		output	wire					full,
	//	
	//		input	wire					rclk,
	//		input	wire					ren,
	//		output	wire	[DATA_WD-1:0]	rdata,
	//		output	wire					empty
	//	);
	//	
	//		reg	[DATA_WD-1:0]	mem	[0:3];
	//	
	//		reg	[2:0]	wptr;
	//		reg	[2:0]	rptr;
	//	
	//		reg	[2:0]	rptr_in_wclk_pre;
	//		reg	[2:0]	rptr_in_wclk;
	//	
	//		reg	[2:0]	wptr_in_rclk_pre;
	//		reg	[2:0]	wptr_in_rclk;
	//	
	//		always	@	(	posedge	wclk	)	begin
	//		//	always	@	(	negedge	wclk	)	begin
	//			if	(	rst	)	begin
	//				wptr	<=	0;
	//				rptr_in_wclk_pre	<=	0;
	//				rptr_in_wclk		<=	0;
	//				mem[0]	<=	0;
	//				mem[1]	<=	0;
	//				mem[2]	<=	0;
	//				mem[3]	<=	0;
	//			end
	//			else	begin
	//				if	(	wen	)	begin
	//					mem[wptr[1:0]]	<=	wdata;
	//					wptr	<=	wptr	+	1'b1;
	//				end
	//	
	//				rptr_in_wclk_pre	<=	normal_to_green(rptr);
	//				rptr_in_wclk		<=	rptr_in_wclk_pre;
	//			end
	//		end
	//	
	//		wire	[2:0]	rptr_in_wclk_normal	=	green_to_normal(rptr_in_wclk);
	//	
	//		//	assign	full	=	~(	(rptr_in_wclk_normal[2]!=wptr[2])	&&	(rptr_in_wclk_normal[1:0]==wptr[1:0])	);
	//		assign	full	=	(rptr_in_wclk_normal[2]!=wptr[2])	&&	(rptr_in_wclk_normal[1:0]==wptr[1:0])	;
	//	
	//		always	@	(	posedge	rclk	)	begin//rst	)	begin
	//			if	(	rst	)	begin
	//				rptr	<=	0;
	//				wptr_in_rclk_pre	<=	0;
	//				wptr_in_rclk		<=	0;
	//			end
	//			else	begin
	//				if	(	ren	)	rptr	<=	rptr	+	1'b1;
	//	
	//				wptr_in_rclk_pre	<=	normal_to_green(wptr);
	//				wptr_in_rclk		<=	wptr_in_rclk_pre;
	//			end
	//		end
	//	
	//		generate
	//			if( FWFT=="TRUE" ) begin : FWFT_DOUT
	//				assign	rdata	=	mem[rptr[1:0]];
	//			end	else  begin : REG_DOUT
	//				reg	[DATA_WD-1:0]	rdata_r	=	0	;
	//				always	rdata_r	<=	ren	?	mem[rptr[1:0]]	:	rdata_r	;
	//				assign	rdata	=	rdata_r	;
	//			end
	//		endgenerate
	//	
	//	
	//	
	//		assign	empty	=	rptr	==	green_to_normal(wptr_in_rclk);
	//	
	//	
	//		function	[2:0]	normal_to_green;
	//		input	[2:0]	normal;
	//		begin
	//			case	(	normal	)
	//			3'b000:	normal_to_green	=	3'b000;
	//			3'b001:	normal_to_green	=	3'b001;
	//			3'b010:	normal_to_green	=	3'b011;
	//			3'b011:	normal_to_green	=	3'b010;
	//			3'b100:	normal_to_green	=	3'b110;
	//			3'b101:	normal_to_green	=	3'b111;
	//			3'b110:	normal_to_green	=	3'b101;
	//			3'b111:	normal_to_green	=	3'b100;
	//			endcase
	//		end
	//		endfunction
	//	
	//		function	[2:0]	green_to_normal;
	//		input	[2:0]	green;
	//		begin
	//			case	(	green	)
	//			3'b000:	green_to_normal	=	3'b000;
	//			3'b001:	green_to_normal	=	3'b001;
	//			3'b011:	green_to_normal	=	3'b010;
	//			3'b010:	green_to_normal	=	3'b011;
	//			3'b110:	green_to_normal	=	3'b100;
	//			3'b111:	green_to_normal	=	3'b101;
	//			3'b101:	green_to_normal	=	3'b110;
	//			3'b100:	green_to_normal	=	3'b111;
	//			endcase
	//		end
	//		endfunction
	//	
	//	
	//	endmodule	//	hdl_afifo_top












`ifdef	afifo_top

		module	hdl_afifo_top	#(
			parameter	FWFT	=	"TRUE"	,
			parameter	DATA_WD	=	8		
		)(
			input	wire					rst,
		
			input	wire					wclk,
			input	wire					wen,
			input	wire	[DATA_WD-1:0]	wdata,
			output	wire					full,
		
			input	wire					rclk,
			input	wire					ren,
			output	wire	[DATA_WD-1:0]	rdata,
			output	wire					empty
		);

				
					wire	[DATA_WD-1:0]	r_fifo_do			;	//	
					wire					r_fifo_em			;	//	
					wire					r_fifo_rd			;	//	axsr_ready

			generate
				if( FWFT=="TRUE" ) begin : FWFT_DOUT
					
					reg						t_fifo_em		=1	;
					reg		[DATA_WD-1:0]	t_fifo_do		=0	;
					wire					t_fifo_rd			;
					
					always@(posedge	rclk)	t_fifo_em	<=	rst	?	1	:	r_fifo_rd	?	1'b0		:	t_fifo_rd	?	1'b1	:	t_fifo_em	;
					always@(posedge	rclk)	t_fifo_do	<=	rst	?	0	:	r_fifo_rd	?	r_fifo_do	:	t_fifo_do	;

					assign	r_fifo_rd	=	~	r_fifo_em	&&	(	t_fifo_rd	||	t_fifo_em	)	;
				
					assign	rdata	=	t_fifo_do	;
					assign	empty	=	t_fifo_em	;
					assign	t_fifo_rd	=	ren		;
					
					wire	rd_err	=	t_fifo_em	&&	t_fifo_rd	;
					
					always@( posedge rclk )begin
						if( rd_err ) begin // fifo is empty and read
								/* synthesis translate_off */
								$display("%t, %m, ERROR: roverflow happen_xxxxx_", $time );
								#100;
								$stop;
								/* synthesis translate_on */
						end
					end
					
				//	assign	rdata	=	r_fifo_do	;
				//	assign	empty	=	r_fifo_em	;
				//	assign	r_fifo_rd	=	ren		;
					
					
				end	else  begin : REG_DOUT
	
					assign	rdata	=	r_fifo_do	;
					assign	empty	=	r_fifo_em	;
					assign	r_fifo_rd	=	ren		;
			
				end
			endgenerate

		hdl_afifo_top_normal	#(
			.	FWFT	(	FWFT		)	,
			.	DATA_WD	(	DATA_WD		)	
		)hdl_afifo_top_normal_i(
			.	rst		(	rst			)	,	//	input	wire					
			.	wclk	(	wclk		)	,	//	input	wire					
			.	wen		(	wen			)	,	//	input	wire					
			.	wdata	(	wdata		)	,	//	input	wire	[DATA_WD-1:0]	
			.	full	(	full		)	,	//	output	wire					
			.	ren		(	r_fifo_rd	)	,	//	input	wire					
			.	rdata	(	r_fifo_do	)	,	//	output	wire	[DATA_WD-1:0]	
			.	empty	(	r_fifo_em	)	,	//	output	wire					
			.	rclk	(	rclk		)		//	input	wire					
		);
		endmodule

		module	hdl_afifo_top_normal	#(
			parameter	FWFT	=	"TRUE"	,
			parameter	DATA_WD	=	8		
		)(
			input	wire					rst,
		
			input	wire					wclk,
			input	wire					wen,
			input	wire	[DATA_WD-1:0]	wdata,
			output	wire					full,
		
			input	wire					rclk,
			input	wire					ren,
			output	wire	[DATA_WD-1:0]	rdata,
			output	wire					empty
		);
		
			reg	[DATA_WD-1:0]	mem	[0:7];
		
			reg	[3:0]	wptr;
			reg	[3:0]	rptr;
		
			reg	[3:0]	rptr_in_wclk_pre;
	(* max_fanout=10 *)	reg	[3:0]	rptr_in_wclk;
		
			reg	[3:0]	wptr_in_rclk_pre;
	(* max_fanout=10 *)	reg	[3:0]	wptr_in_rclk;
		
			always	@	(	posedge	wclk	)	begin
			//	always	@	(	negedge	wclk	)	begin
				if	(	rst	)	begin
					wptr	<=	0;
					rptr_in_wclk_pre	<=	0;
					rptr_in_wclk		<=	0;
					mem[0]	<=	0;
					mem[1]	<=	0;
					mem[2]	<=	0;
					mem[3]	<=	0;
					mem[4]	<=	0;
					mem[5]	<=	0;
					mem[6]	<=	0;
					mem[7]	<=	0;
				end
				else	begin
					if	(	wen	)	begin
						mem[wptr[2:0]]	<=	wdata;
						wptr	<=	wptr	+	1'b1;
					end
		
					rptr_in_wclk_pre	<=	normal_to_green(rptr);
					rptr_in_wclk		<=	rptr_in_wclk_pre;
				end
			end
		
			wire	[3:0]	rptr_in_wclk_normal	=	green_to_normal(rptr_in_wclk);
		
			//	assign	full	=	~(	(rptr_in_wclk_normal[3]!=wptr[3])	&&	(rptr_in_wclk_normal[2:0]==wptr[2:0])	);
			assign	full	=	(rptr_in_wclk_normal[3]!=wptr[3])	&&	(rptr_in_wclk_normal[2:0]==wptr[2:0])	;
		
			always	@	(	posedge	rclk	)	begin//rst	)	begin
				if	(	rst	)	begin
					rptr	<=	0;
					wptr_in_rclk_pre	<=	0;
					wptr_in_rclk		<=	0;
				end
				else	begin
					if	(	ren	)	rptr	<=	rptr	+	1'b1;
		
					wptr_in_rclk_pre	<=	normal_to_green(wptr);
					wptr_in_rclk		<=	wptr_in_rclk_pre;
				end
			end
		
			generate
				if( FWFT=="TRUE" ) begin : FWFT_DOUT
					assign	rdata	=	mem[rptr[2:0]];
				end	else  begin : REG_DOUT
					reg	[DATA_WD-1:0]	rdata_r	=	0	;
					always	rdata_r	<=	ren	?	mem[rptr[2:0]]	:	rdata_r	;
					assign	rdata	=	rdata_r	;
				end
			endgenerate
		
		
		
			assign	empty	=	rptr	==	green_to_normal(wptr_in_rclk);
		
		
			function	[3:0]	normal_to_green;
			input	[3:0]	normal;
			begin
				case	(	normal	)
				4'b0000: normal_to_green = 4'b0000;
				4'b0001: normal_to_green = 4'b0001;
				4'b0010: normal_to_green = 4'b0011;
				4'b0011: normal_to_green = 4'b0010;
				4'b0100: normal_to_green = 4'b0110;
				4'b0101: normal_to_green = 4'b0111;
				4'b0110: normal_to_green = 4'b0101;
				4'b0111: normal_to_green = 4'b0100;
				4'b1000: normal_to_green = 4'b1100;
				4'b1001: normal_to_green = 4'b1101;
				4'b1010: normal_to_green = 4'b1111;
				4'b1011: normal_to_green = 4'b1110;
				4'b1100: normal_to_green = 4'b1010;
				4'b1101: normal_to_green = 4'b1011;
				4'b1110: normal_to_green = 4'b1001;
				4'b1111: normal_to_green = 4'b1000;
				endcase
			end
			endfunction
		
			function	[3:0]	green_to_normal;
			input	[3:0]	green;
			begin
				case	(	green	)
				4'b0000: green_to_normal = 4'b0000;
				4'b0001: green_to_normal = 4'b0001;
				4'b0011: green_to_normal = 4'b0010;
				4'b0010: green_to_normal = 4'b0011;
				4'b0110: green_to_normal = 4'b0100;
				4'b0111: green_to_normal = 4'b0101;
				4'b0101: green_to_normal = 4'b0110;
				4'b0100: green_to_normal = 4'b0111;
				4'b1100: green_to_normal = 4'b1000;
				4'b1101: green_to_normal = 4'b1001;
				4'b1111: green_to_normal = 4'b1010;
				4'b1110: green_to_normal = 4'b1011;
				4'b1010: green_to_normal = 4'b1100;
				4'b1011: green_to_normal = 4'b1101;
				4'b1001: green_to_normal = 4'b1110;
				4'b1000: green_to_normal = 4'b1111;
				endcase
			end
			endfunction
		
		
		endmodule	//	hdl_afifo_top
`endif



























