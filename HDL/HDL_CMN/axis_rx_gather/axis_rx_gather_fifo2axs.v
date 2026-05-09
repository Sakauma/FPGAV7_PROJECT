	// `timescale	1ns/1ps
	module	axis_rx_gather_fifo2axs#(
		parameter	DW		=	64		,
		parameter	QW		=	64		
	)(

		input											axsr_info_wr					,
		input		[	64		-	1	:	0	]		axsr_info_di					,
		output											axsr_info_af					,
		output											axsr_info_fu					,
							
		input											axsr_fifo_wr					,
		input		[	DW		-	1	:	0	]		axsr_fifo_di					,
		output											axsr_fifo_af					,
		output											axsr_fifo_fu					,

		input											i_rst							,
		input											i_clk							,
			
		output											axst_tvalid						,
		input											axst_tready						,
		output											axst_tlast						,
		output		[	QW		-	1	:	0	]		axst_tdata						,
		output		[	64		-	1	:	0	]		axst_tuser						,
		output		[	QW/8	-	1	:	0	]		axst_tstrb						,
		output		[	QW/8	-	1	:	0	]		axst_tkeep						,
		output		[	4		-	1	:	0	]		axst_tdest						,
		output		[	4		-	1	:	0	]		axst_tid						,
		output		[	32		-	1	:	0	]		axst_count						,
						
		input											o_rst							,				
		input											o_clk							
	);
		
		localparam	BC	=	QW/32	;	//	double	word count	in bus
		
		wire	clk		=	o_clk	;
		wire	rst		=	i_rst	;
		
		wire											axsr_info_rd			;
		wire		[	64		-	1	:	0	]		axsr_info_do			;
		wire											axsr_info_ae			;
		wire											axsr_info_em			;
		wire											axsr_fifo_rd			;
		wire		[	QW		-	1	:	0	]		axsr_fifo_do			;
		wire											axsr_fifo_ae			;
		wire											axsr_fifo_em			;
		
		wire	[	16	-	1	:	0	]	cur_pkg_size		=		axsr_info_do[15:0]					;
		wire								cur_pkg_done					;
		reg									cur_pkg_will_done	=	0		;
		reg		[	16	-	1	:	0	]	cur_pkg_dwct		=	0		;

		assign	axst_tid					= 0									;
		assign	axst_tdest					= 0									;
		assign	axst_tkeep					= {{QW/8}{1'b1}}					;
		assign	axst_tstrb					= {{QW/8}{1'b1}}					;
		
		assign	axst_tvalid			=	~	axsr_fifo_em			&&	~	axsr_info_em	;
		assign	axst_tlast			=		cur_pkg_done									;
		assign	axst_tdata			=		axsr_fifo_do									;
		assign	axst_tuser			=		axsr_info_do									;

		assign	axsr_info_rd				=		axst_tready		&&	axst_tvalid		&&	axst_tlast	;
		assign	axsr_fifo_rd				=		axst_tready		&&	axst_tvalid			;

		always@(posedge	clk)	begin
			if(rst)	cur_pkg_dwct	<=	0	;
			else	if(	cur_pkg_done	)	cur_pkg_dwct	<=	0							;
			else	if(	axsr_fifo_rd	)	cur_pkg_dwct	<=	cur_pkg_dwct	+	BC	;
		end
		
//		使用will_done信号的前提是包长度大�?1个节�?
		always@(posedge	clk)	begin
			if(rst)	cur_pkg_will_done	<=	0	;
			else	if(	cur_pkg_done	)	cur_pkg_will_done	<=	0							;
			else	if(	cur_pkg_dwct	+	2*BC	>=	cur_pkg_size	&&	axsr_fifo_rd	)	cur_pkg_will_done	<=	1	;
			else	cur_pkg_will_done	<=	cur_pkg_will_done	;
		end
    
		assign	cur_pkg_done	=	axsr_fifo_rd	&&	cur_pkg_will_done	;
		
	//	assign	cur_pkg_done	=	cur_pkg_dwct	+	BC	>=	cur_pkg_size	&&	axsr_fifo_rd		;
	//	
	//	reg		[	31	:	0]	axst_count_l	;	always@(posedge	clk)	axst_count_l	<=	rst	?	0	:	cur_pkg_done	?	axst_count_l	+	1	:	axst_count_l	;
	//	assign	axst_count	=	axst_count_l	;
		
		hdl_eqw_afifo	#(	//	equal	width	async fifo
			.	LOOP_NUM				(	0				)	,
			.	RAM_STYLE				(	"distributed"	)	,
//			.	SYNCHRONIZATION			(	"yes"			)	,
			.	ALMOST_EMPTY_OFFSET		(	'h8				)	,
			.	ALMOST_FULL_OFFSET		(	'h8				)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	5				)	,
			.	DW						(	64				)	
		)axsr_info(
			.	RST					(	rst					)	,	//	input	wire					
			.	WRCLK				(	i_clk				)	,	//	input	wire					
			.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(						)	,	//	output	wire					
			.	WREN				(	axsr_info_wr		)	,	//	input	wire					
			.	DI					(	axsr_info_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	axsr_info_af		)	,	//	output	wire					
			.	FULL				(	axsr_info_fu		)	,	//	output	wire					
			.	RDEN				(	axsr_info_rd		)	,	//	input	wire					
			.	DO					(	axsr_info_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	axsr_info_ae		)	,	//	output	wire					
			.	EMPTY				(	axsr_info_em		)	,	//	output	wire					
			.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(						)	,	//	output	wire					
			.	RDCLK				(	o_clk				)		//	input	wire					
		);
		
	//	hdl_eqw_afifo	#(	//	equal	width	async fifo
	//		.	LOOP_NUM				(	0				)	,
	//		.	RAM_STYLE				(	"block"			)	,
	//		.	ALMOST_EMPTY_OFFSET		(	'h8				)	,
	//		.	ALMOST_FULL_OFFSET		(	'h8				)	,
	//		.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
	//		.	AW						(	9				)	,
	//		.	DW						(	64				)	
	//	)axsr_fifo(
	//		.	RST					(	rst					)	,	//	input	wire					
	//		.	WRCLK				(	i_clk				)	,	//	input	wire					
	//		.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
	//		.	WRERR				(						)	,	//	output	wire					
	//		.	WREN				(	axsr_fifo_wr		)	,	//	input	wire					
	//		.	DI					(	axsr_fifo_di		)	,	//	input	wire	[DW	-1:0]		
	//		.	ALMOSTFULL			(	axsr_fifo_af		)	,	//	output	wire					
	//		.	FULL				(	axsr_fifo_fu		)	,	//	output	wire					
	//		.	RDEN				(	axsr_fifo_rd		)	,	//	input	wire					
	//		.	DO					(	axsr_fifo_do		)	,	//	output	wire	[QW	-1:0]		
	//		.	ALMOSTEMPTY			(	axsr_fifo_ae		)	,	//	output	wire					
	//		.	EMPTY				(	axsr_fifo_em		)	,	//	output	wire					
	//		.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
	//		.	RDERR				(						)	,	//	output	wire					
	//		.	RDCLK				(	o_clk				)		//	input	wire					
	//	);			

	//	localparam	P_WRAM_STYLE	=	DW	>	72	?	"distributed"	:	"block"	;

		hdl_exw_afifo	#(	//	extended	width	async fifo
			.	LOOP_NUM				(	0				)	,
		//	.	RAM_STYLE				(	P_WRAM_STYLE	)	,
		//	.	RD_RAM_STYLE			(	P_RRAM_STYLE	)	,
			.	RAM_STYLE				(	"block"			)	,
//			.	SYNCHRONIZATION			(	"yes"			)	,
//			.	RD_RAM_STYLE			(	"distributed"	)	,
			.	ALMOST_EMPTY_OFFSET		(	'h10			)	,
			.	ALMOST_FULL_OFFSET		(	'h10			)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(clogb2(4096*8/DW)	)	,
//			.	RD_AW					(	5				)	,
			.	DW						(	DW				)	,
			.	QW						(	DW				)	
		)axsr_fifo(
			.	RST					(	rst					)	,	//	input	wire					
			.	WRCLK				(	i_clk				)	,	//	input	wire					
			.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(						)	,	//	output	wire					
			.	WREN_CLEAR			(	1'b0				)	,	//	input	wire					
			.	WREN_LAST			(	1'b0				)	,	//	input	wire					
			.	WREN				(	axsr_fifo_wr		)	,	//	input	wire					
			.	DI					(	axsr_fifo_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	axsr_fifo_af		)	,	//	output	wire					
			.	FULL				(	axsr_fifo_fu		)	,	//	output	wire					
			.	RDEN				(	axsr_fifo_rd		)	,	//	input	wire					
			.	DO					(	axsr_fifo_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	axsr_fifo_ae		)	,	//	output	wire					
			.	EMPTY				(	axsr_fifo_em		)	,	//	output	wire					
			.	RDEN_LAST			(	1'b0				)	,	//	input	wire					
			.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(						)	,	//	output	wire					
			.	RDCLK				(	o_clk				)		//	input	wire					
		);
		/*
		ila_576X1024  gather_ila (
   		.	clk		(	o_clk	)	,	// input wire clk
   		.	probe0	(	   				
   						{
   						
   						axst_tvalid		,
						axst_tready		,
						axst_tlast		,
						axst_tdata		,
						axst_tuser		,
						 cur_pkg_dwct   ,              
						cur_pkg_done    ,              
						cur_pkg_will_done ,                 
						                  
						axst_count		 
                                                                      
   				                                             				
   					
   						}	
   		)		// input wire [31:0] probe0
   	); */
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		/* synthesis translate_on */ 
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