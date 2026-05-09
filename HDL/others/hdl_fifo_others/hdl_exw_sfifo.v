
`timescale	1ns/1ps
	module	hdl_exw_sfifo	#(
		parameter	LOOP_NUM				= 	0				,
		parameter	RAM_STYLE				= 	"block"	,	//	"distributed"	or	"block"	;
		parameter	ALMOST_EMPTY_OFFSET		=	256				,
		parameter	ALMOST_FULL_OFFSET		=	256				,
		parameter	FIRST_WORD_FALL_THROUGH	=	"TRUE"			,
		parameter	AW						=	9				,	//	THE DEEP WIDTH	OF WRITE PORT
		parameter	DW						=	16				,
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
	
	localparam	COUNT_WIDTH	=	DW>QW	?	clogb2(AW)	:	clogb2(QW/DW*AW)	;
	wire	 [COUNT_WIDTH:0] cnt_used;	assign	WRCOUNT	=cnt_used[COUNT_WIDTH-1:0]	;
	wire	 [COUNT_WIDTH:0] cnt_free;	assign	RDCOUNT	=cnt_free[COUNT_WIDTH-1:0]	;
	
// genvar i;
	generate
		if(	DW	==	QW	)	begin
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

			reg	[clogb2(QW/DW)-1:0]	wr_cnt	;
			always@(posedge	CLK)	begin
				if(RST)	begin
					wr_cnt	<=	0	;
				end	else	if(buf_wr)begin
					wr_cnt	<=	0	;
				end	else	begin
					wr_cnt	<=	WREN	&&	!FULL	?	wr_cnt	+	1	:	wr_cnt	;	//buf_wr	?	0:
				end
			end

			assign	dw_align	=	wr_cnt	==	QW/DW	-1	;

			assign	buf_wr	=	(dw_align	||	WREN_LAST	)	&&	WREN	&&	!FULL;

			reg		[	QW	-	1	:	0	]	buf_di_reg	=	0	;	always@(posedge	CLK)	buf_di_reg	<=	buf_wr	?	0	:	buf_di	;

			genvar k;
			generate	for ( k=0; k<QW/DW; k=k+1 ) begin: dw_convert
				
				assign	buf_di[	k	*	DW	+:	DW	]	=	wr_cnt	==	k	?	DI	:	buf_di_reg[	k	*	DW	+:	DW	]	;
					
			end	endgenerate

			hdl_sfifo_top #(
				.	RAM_STYLE  	(	RAM_STYLE					)	,	//	Specify RAM style: auto/block/distributed
				.	FWFT       	(	FIRST_WORD_FALL_THROUGH		)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
				.	DWID       	(	QW							)	,
				.	AWID       	(	AW							)	, 
				.	AFULL_TH   	(	ALMOST_FULL_OFFSET			)	, 
				.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET 		)	, 
				.	DBG_WID    	(	32							)		
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
			
		end	else	begin
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
				.	AWID       	(	AW							)	, 
				.	AFULL_TH   	(	ALMOST_FULL_OFFSET			)	, 
				.	AEMPTY_TH  	(	ALMOST_EMPTY_OFFSET 		)	, 
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

endmodule