
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2021�?11�?02�?20:25:08
//	Design	Name		:	
//	Module	Name		:	
//	Project	Name		:	
//	Target	Devices		:	all	Xilinx device
//	Tool	versions	:	all
//	Description		:	
//	Editor			:	Npp,	tab	size	(4)
//	Dependencies		:	
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	TOP file for srio gt monitor
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description		:	FIFO2AXIS 时序转换					:
//	
//	Additional	Comments:	
//

`timescale 1ns/1ns

module	srio_gtrx_axis	#(
	parameter		LINK_WIDTH		=	1				,	//	SRIO GT LANE WIDTH					
	parameter		GT_BYTES		=	4				,	//	SRIO GT DATA WIDTH	PER	LANE				
	parameter		DW				=	64					//		
)(

		input	wire										gtrx_dat_info_wr			,
		input	wire	[	1	*	12		-1:0]			gtrx_dat_info_di			,
		output	wire										gtrx_dat_info_af			,
		output	wire										gtrx_dat_info_fu			,
		input	wire										gtrx_dat_fifo_wr			,
		input	wire	[	1	*	DW		-1:0]			gtrx_dat_fifo_di			,
		output	wire										gtrx_dat_fifo_af			,
		output	wire										gtrx_dat_fifo_fu			,
		
		input	wire										gtrx_ksc_fifo_wr			,
		input	wire	[	1	*	DW		-1:0]			gtrx_ksc_fifo_di			,
		output	wire										gtrx_ksc_fifo_af			,
		output	wire										gtrx_ksc_fifo_fu			,

		input	wire										srgt_iorx_tready			,
		output	wire										srgt_iorx_tvalid			,
		output	wire	[	1	*	DW		-1:0]			srgt_iorx_tdata				,
		output	wire	[	1	*	DW/8	-1:0]			srgt_iorx_tkeep				,
		output	wire										srgt_iorx_tlast				,
		output	wire	[	1	*	64		-1:0]			srgt_iorx_tuser				,
		
		output	reg		[	1	*	32		-1:0]			srgt_data_tcnt		=0		,
		output	reg		[	1	*	32		-1:0]			srgt_k_sc_tcnt		=0		,

		input	wire										gtrx_error_or				,
		input	wire										c_gt_ksc_enab				,
		input	wire										c_gt_dat_byps				,
		input	wire										itf_rst						,
		input	wire										itf_clk									
	);	

	localparam	LW	=	LINK_WIDTH	;
	localparam	LB	=	GT_BYTES*8	;

	wire	rst	=	itf_rst			;
	wire	clk	=	itf_clk			;

		wire										gtrx_phy_tready				;	assign	gtrx_phy_tready	=	srgt_iorx_tready	;
		wire										gtrx_phy_tvalid				;
		wire	[	1	*	DW		-1:0]			gtrx_phy_tdata				;
		wire	[	1	*	DW/8	-1:0]			gtrx_phy_tkeep				;
		wire										gtrx_phy_tlast				;
		wire	[	1	*	64		-1:0]			gtrx_phy_tuser				;
		                                                                        
		wire										gtrx_ksc_tready				;	assign	gtrx_ksc_tready	=	srgt_iorx_tready	;
		wire										gtrx_ksc_tvalid				;
		wire	[	1	*	DW		-1:0]			gtrx_ksc_tdata				;
		wire	[	1	*	DW/8	-1:0]			gtrx_ksc_tkeep				;
		wire										gtrx_ksc_tlast				;
		wire	[	1	*	64		-1:0]			gtrx_ksc_tuser				;

		wire					tready			;	assign	tready	=	gtrx_phy_tready	;
		wire					tvalid			;	assign	gtrx_phy_tvalid	=	tvalid	;
		wire					tlast			;	assign	gtrx_phy_tlast	=	tlast	;
		wire	[DW		-1:0]	tdata			;	assign	gtrx_phy_tdata	=	tdata	;
		wire	[64		-1:0]	tuser			;	assign	gtrx_phy_tuser	=	tuser	;
		wire	[DW/8	-1:0]	tkeep			;	assign	gtrx_phy_tkeep	=	tkeep	;

		assign	trv		=	tvalid	&&	tready				;
		assign	trvl	=	tvalid	&&	tready	&&	tlast	;
		

	wire										gtrx_dat_info_rd			;
	wire	[	1	*	12		-1:0]			gtrx_dat_info_do			;
	wire										gtrx_dat_info_ae			;
	wire										gtrx_dat_info_em			;
	wire										gtrx_dat_fifo_rd			;
	wire	[	DW				-1:0]			gtrx_dat_fifo_do			;
	wire										gtrx_dat_fifo_ae			;
	wire										gtrx_dat_fifo_em			;

	wire										gtrx_ksc_fifo_rd			;
	wire	[	DW				-1:0]			gtrx_ksc_fifo_do			;
	wire										gtrx_ksc_fifo_ae			;
	wire										gtrx_ksc_fifo_em			;
	
	wire	dat_fifo_em	=	gtrx_dat_fifo_em	&&	gtrx_dat_info_em	;

	reg	[1:0]	rst_clk_syn	=	2'h3	;
	always@(posedge	clk)	rst_clk_syn	<=	{rst_clk_syn[0],rst}	;
	
	reg		rst_dly	=	1	;
	always@(posedge	clk)	rst_dly	<=	rst_clk_syn[1]	;
	
	reg		[5:0]	afrst_cnt	=	0	;
	wire	afrst_done	=	afrst_cnt[5]	;
	
	reg		[5:0]	clear_cnt	=	0	;
	wire	clear_done	=	clear_cnt[5]	;

	reg		c_gt_ksc_enab_q	=	0	;	always@(posedge	clk)	c_gt_ksc_enab_q	<=	c_gt_ksc_enab		;
	reg		c_gt_ksc_enab_s	=	0	;	always@(posedge	clk)	c_gt_ksc_enab_s	<=	c_gt_ksc_enab_q     ;
	reg		c_gt_dat_byps_q	=	0	;	always@(posedge	clk)	c_gt_dat_byps_q	<=	c_gt_dat_byps       ;
	reg		c_gt_dat_byps_s	=	0	;	always@(posedge	clk)	c_gt_dat_byps_s	<=	c_gt_dat_byps_q     ;

	localparam	B_IDLE		=	0	;	localparam	S_IDLE		=	2**B_IDLE			;	//	
	localparam	B_DATA		=	1	;	localparam	S_DATA		=	2**B_DATA			;	//	数据�?
	localparam	B_CLEAR		=	2	;	localparam	S_CLEAR		=	2**B_CLEAR			;	//	清除FIFO残留

	reg			[2:0]	CS_DATA	=	S_IDLE	;
	
	always@(posedge	clk)	begin
		if(rst)	begin
			CS_DATA	<=	S_IDLE		;
		end	else	begin
			case	(	CS_DATA	)	
			S_IDLE		:	begin
				if				(	rst_dly	||gtrx_error_or||c_gt_dat_byps_s	)	begin
					CS_DATA	<=	S_CLEAR	;
				end	else	if	(	!srgt_iorx_tready&&srgt_iorx_tvalid			)	begin
					CS_DATA	<=	S_IDLE	;		
				end	else	if	(	!	gtrx_dat_info_em						)	begin	//	SC 包仅在IDLE状态下传输即可
					CS_DATA	<=	S_DATA	;
				end	else							begin
					CS_DATA	<=	S_IDLE	;
				end
			end
			S_DATA		:	begin
				if				(	trvl			)		begin
					CS_DATA	<=	S_IDLE	;	
				end	else									begin
					CS_DATA	<=	S_DATA	;	
				end	
			end
			S_CLEAR						: begin
				if(	clear_done	)	begin
					CS_DATA						= S_IDLE							;
				end	else	begin
					CS_DATA						= S_CLEAR							;
				end
			end	
			default		:	begin
				CS_DATA	<=	S_IDLE	;
			end
			endcase
		end
	end

	always@(posedge	clk)	begin
		if(CS_DATA[B_CLEAR])	clear_cnt	<=	!dat_fifo_em	?	0	:	clear_cnt	+	!clear_done	;
		else	clear_cnt	<=	0	;
	end	
	
	assign	gtrx_dat_info_rd	=	(CS_DATA[B_IDLE]	||	CS_DATA[B_CLEAR]	)&&	!gtrx_dat_info_em	;
	
	reg		[12-1:0]	gtrx_dat_info_do_l	=	0	;
	always@(posedge	clk)	begin
		if			(	rst				)	gtrx_dat_info_do_l	<=		0				;
		else	if	(	CS_DATA[B_IDLE]	)	gtrx_dat_info_do_l	<=	gtrx_dat_info_do	;
		else								gtrx_dat_info_do_l	<=	gtrx_dat_info_do_l	;
	end
	
	assign	tkeep	=	{{DW/8	}{1'b1}}					;	
	
	assign	tuser	=	{52'h0,gtrx_dat_info_do_l[00+:12]}	;
	
	reg		[12-1:0]	axis_cnt	=	'h10	;
	always@(posedge	clk)	begin
		if		(	rst	)	axis_cnt	<=	'h10	;
		else	if(	CS_DATA[B_IDLE]	)	axis_cnt	<=	gtrx_dat_info_do	;
		else	if(	CS_DATA[B_DATA]	)	axis_cnt	<=	axis_cnt	-	(gtrx_dat_fifo_rd?DW/LB:0)		;
		else							axis_cnt	<=	axis_cnt	;
	end
	
	assign	tvalid	=	CS_DATA[B_DATA]	&&	!gtrx_dat_fifo_em		;
	assign	tlast	=	DW/LB	>=	axis_cnt	&&	gtrx_dat_fifo_rd	;
//	assign	tdata	=	{gtrx_dat_fifo_do[0*8+:8],gtrx_dat_fifo_do[1*8+:8],gtrx_dat_fifo_do[2*8+:8],gtrx_dat_fifo_do[3*8+:8]}	;
	assign	tdata	=	gtrx_dat_fifo_do		;

	assign	gtrx_dat_fifo_rd	=	trv	||	(CS_DATA[B_CLEAR]	&&!gtrx_dat_fifo_em)	;	//	!gtrx_dat_fifo_em条件非必�?

	wire	[7:0]	INFO_WRCOUNT	;
	wire	[7:0]	INFO_RDCOUNT	;

	wire	[10:0]	FIFO_WRCOUNT	;
	wire	[10:0]	FIFO_RDCOUNT	;

		hdl_exw_afifo	#(	//	extended	width	async fifo
			.	LOOP_NUM				(	0				)	,
//			.	SYNCHRONIZATION			(	"yes"			)	,
			.	RAM_STYLE				(	"distributed"	)	,
//			.	RD_RAM_STYLE			(	"distributed"	)	,
			.	ALMOST_EMPTY_OFFSET		(	'h08			)	,
			.	ALMOST_FULL_OFFSET		(	'h08			)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	7				)	,
//			.	RD_AW					(	7				)	,
			.	DW						(	12				)	,
			.	QW						(	12				)	
		)gtrx_dat_info_i(
			.	RST					(		rst					)	,	//	input	wire					
			.	WRCLK				(		clk					)	,	//	input	wire					
			.	WRCOUNT				(	INFO_WRCOUNT			)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(							)	,	//	output	wire					
			.	WREN_CLEAR			(		1'b0				)	,	//	input	wire					
			.	WREN_LAST			(		1'b0				)	,	//	input	wire					
			.	WREN				(	gtrx_dat_info_wr		)	,	//	input	wire					
			.	DI					(	gtrx_dat_info_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	gtrx_dat_info_af		)	,	//	output	wire					
			.	FULL				(	gtrx_dat_info_fu		)	,	//	output	wire					
			.	RDEN				(	gtrx_dat_info_rd		)	,	//	input	wire					
			.	DO					(	gtrx_dat_info_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	gtrx_dat_info_ae		)	,	//	output	wire					
			.	EMPTY				(	gtrx_dat_info_em		)	,	//	output	wire					
			.	RDEN_LAST			(		1'b0				)	,	//	input	wire					
			.	RDCOUNT				(	INFO_RDCOUNT			)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(							)	,	//	output	wire					
			.	RDCLK				(		clk					)		//	input	wire					
		);

		hdl_exw_afifo	#(	//	extended	width	async fifo
			.	LOOP_NUM				(	0				)	,
//			.	SYNCHRONIZATION			(	"yes"			)	,
			.	RAM_STYLE				(	"block"			)	,
//			.	RD_RAM_STYLE			(	"block"			)	,
			.	ALMOST_EMPTY_OFFSET		(	'h100			)	,
			.	ALMOST_FULL_OFFSET		(	'h100			)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	10				)	,
//			.	RD_AW					(	10				)	,
			.	DW						(	DW				)	,
			.	QW						(	DW				)	
		)gtrx_dat_fifo_i(
			.	RST					(		rst					)	,	//	input	wire					
			.	WRCLK				(		clk					)	,	//	input	wire					
			.	WRCOUNT				(	FIFO_WRCOUNT			)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(							)	,	//	output	wire					
			.	WREN_CLEAR			(		1'b0				)	,	//	input	wire					
			.	WREN_LAST			(		1'b0				)	,	//	input	wire					
			.	WREN				(	gtrx_dat_fifo_wr		)	,	//	input	wire					
			.	DI					(	gtrx_dat_fifo_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	gtrx_dat_fifo_af		)	,	//	output	wire					
			.	FULL				(	gtrx_dat_fifo_fu		)	,	//	output	wire					
			.	RDEN				(	gtrx_dat_fifo_rd		)	,	//	input	wire					
			.	DO					(	gtrx_dat_fifo_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	gtrx_dat_fifo_ae		)	,	//	output	wire					
			.	EMPTY				(	gtrx_dat_fifo_em		)	,	//	output	wire					
			.	RDEN_LAST			(		1'b0				)	,	//	input	wire					
			.	RDCOUNT				(	FIFO_RDCOUNT			)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(							)	,	//	output	wire					
			.	RDCLK				(		clk					)		//	input	wire					
		);

		hdl_exw_afifo	#(	//	extended	width	async fifo
			.	LOOP_NUM				(	0				)	,
//			.	SYNCHRONIZATION			(	"yes"			)	,
			.	RAM_STYLE				(	"block"			)	,
//			.	RD_RAM_STYLE			(	"block"			)	,
			.	ALMOST_EMPTY_OFFSET		(	'h100			)	,
			.	ALMOST_FULL_OFFSET		(	'h100			)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	9				)	,
//			.	RD_AW					(	9				)	,
			.	DW						(	DW				)	,
			.	QW						(	DW				)	
		)gtrx_ksc_fifo_i(
			.	RST					(		rst					)	,	//	input	wire					
			.	WRCLK				(		clk					)	,	//	input	wire					
			.	WRCOUNT				(							)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(							)	,	//	output	wire					
			.	WREN_CLEAR			(		1'b0				)	,	//	input	wire					
			.	WREN_LAST			(		1'b0				)	,	//	input	wire					
			.	WREN				(	gtrx_ksc_fifo_wr	&&	c_gt_ksc_enab_s	)	,	//	input	wire					
			.	DI					(	gtrx_ksc_fifo_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	gtrx_ksc_fifo_af		)	,	//	output	wire					
			.	FULL				(	gtrx_ksc_fifo_fu		)	,	//	output	wire					
			.	RDEN				(	gtrx_ksc_fifo_rd		)	,	//	input	wire					
			.	DO					(	gtrx_ksc_fifo_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	gtrx_ksc_fifo_ae		)	,	//	output	wire					
			.	EMPTY				(	gtrx_ksc_fifo_em		)	,	//	output	wire					
			.	RDEN_LAST			(		1'b0				)	,	//	input	wire					
			.	RDCOUNT				(							)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(							)	,	//	output	wire					
			.	RDCLK				(		clk					)		//	input	wire					
		);

		assign	gtrx_ksc_fifo_rd	=		gtrx_ksc_tready	&&	gtrx_ksc_tvalid	;
		assign	gtrx_ksc_tvalid		=	!	gtrx_ksc_fifo_em&&	CS_DATA[B_IDLE]	;
		assign	gtrx_ksc_tlast		=		gtrx_ksc_fifo_rd					;
		assign	gtrx_ksc_tdata		=		gtrx_ksc_fifo_do					;
		assign	gtrx_ksc_tuser		=		2									;	//	固定长度
		assign	gtrx_ksc_tkeep		=		{{DW/8	}{1'b1}}					;


		assign		srgt_iorx_tvalid		=	CS_DATA[B_IDLE]	?	gtrx_ksc_tvalid	:	gtrx_phy_tvalid	;
		assign		srgt_iorx_tdata			=	CS_DATA[B_IDLE]	?	gtrx_ksc_tdata	:	gtrx_phy_tdata	;
		assign		srgt_iorx_tkeep			=	CS_DATA[B_IDLE]	?	gtrx_ksc_tkeep	:	gtrx_phy_tkeep	;
		assign		srgt_iorx_tlast			=	CS_DATA[B_IDLE]	?	gtrx_ksc_tlast	:	gtrx_phy_tlast	;
		assign		srgt_iorx_tuser			=	CS_DATA[B_IDLE]	?	gtrx_ksc_tuser	:	gtrx_phy_tuser	;

		always@(posedge	itf_clk)	srgt_data_tcnt	<=	srgt_data_tcnt	+	(gtrx_phy_tready	&&	gtrx_phy_tvalid	&&	gtrx_phy_tlast	?	1'b1	:	1'b0)	;
		always@(posedge	itf_clk)	srgt_k_sc_tcnt	<=	srgt_k_sc_tcnt	+	(gtrx_ksc_tready	&&	gtrx_ksc_tvalid	&&	gtrx_ksc_tlast	?	1'b1	:	1'b0)	;

//	`ifdef	DBG_ILA
//		ila_576X1024 ila_144X1024_pcs (
//			.	clk		(	gt_pcs_clk	)	,	// input wire clk
//			.	probe0	(	
//							{
//	
//								INFO_WRCOUNT			,
//								INFO_RDCOUNT			,
//														
//								FIFO_WRCOUNT			,
//								FIFO_RDCOUNT			,
//								
//								gtrx_dat_info_rd			,
//								gtrx_dat_info_do			,
//								gtrx_dat_info_ae			,
//								gtrx_dat_info_em			,
//								gtrx_dat_fifo_rd			,
//							//	gtrx_dat_fifo_do			,
//								gtrx_dat_fifo_ae			,
//								gtrx_dat_fifo_em			,
//								
//								CS_DATA						,
//								
//								gtrx_phy_tready				,
//								gtrx_phy_tvalid				,
//								gtrx_phy_tdata				,
//								gtrx_phy_tkeep				,
//								gtrx_phy_tlast				,
//								gtrx_phy_tuser	[0+:16]		,
//								
//								rst						
//							}	
//						)		// input wire [31:0] probe0
//		);
//	`endif
		

endmodule