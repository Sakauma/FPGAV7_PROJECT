
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2021年11月30日20:25:08
//	Design	Name		:	
//	Module	Name		:	
//	Project	Name		:	
//	Target	Devices		:	all	Xilinx device
//	Tool	versions	:	all
//	Description		:	
//	Editor			:	Npp,	tab	size	(4)
//	Dependencies		:	no
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	multi-lane data	align
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description							:
//	
//	Additional	Comments:	
//
//////////////////////////////////////////////////////////////////////////////////

//	`timescale	1ns/1ps


module	gtrx_chanalign_shift	#(
	parameter		LINK_WIDTH		=	1				,
	parameter		GT_BYTES		=	4				
)(
	input	wire	[	LINK_WIDTH*32	-1:0]	gtrx_data					,	
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_charisk				,
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_chariscomma			,
	input	wire	[	LINK_WIDTH		-1:0]	gtrx_chanisaligned			,
	
	output	wire	[	LINK_WIDTH*32	-1:0]	shft_data					,
	output	wire	[	LINK_WIDTH*4	-1:0]	shft_charisk				,
	output	wire	[	LINK_WIDTH*4	-1:0]	shft_chariscomma			,
	output	wire	[	LINK_WIDTH		-1:0]	shft_chanisaligned			,
	
	input	wire								gtrx_error_or				,
	input	wire								force_reinit				,
	
	input	wire								gt_pcs_rst					,
	input	wire								gt_pcs_clk					
	
);	

	localparam	LW	=	LINK_WIDTH		;
	localparam	LB	=	GT_BYTES		;
	
	localparam	RSVD	=	8'hBC	;

	wire	rst	;
	wire	clk	;
	
	assign	clk	=	gt_pcs_clk	;
	assign	rst	=	gt_pcs_rst	;

	reg		[	LINK_WIDTH*4*8	-1:0]	rg0_gtrx_data			=	{{LINK_WIDTH}{{4{RSVD}}}}				;
	reg		[	LINK_WIDTH*4	-1:0]	rg0_gtrx_charisk		=	{{LINK_WIDTH}{{4{1'b1}}}}				;
	reg		[	LINK_WIDTH*4	-1:0]	rg0_gtrx_chariscomma	=	{{LINK_WIDTH}{{4{1'b1}}}}				;

	reg		[	LINK_WIDTH*4*8	-1:0]	rg1_gtrx_data			=	{{LINK_WIDTH}{{4{RSVD}}}}				;
	reg		[	LINK_WIDTH*4	-1:0]	rg1_gtrx_charisk		=	{{LINK_WIDTH}{{4{1'b1}}}}				;
	reg		[	LINK_WIDTH*4	-1:0]	rg1_gtrx_chariscomma	=	{{LINK_WIDTH}{{4{1'b1}}}}				;

//		gtrx_data0		gtrx_data1		gtrx_data2
//						rg0_gtrx_data0	rg0_gtrx_data1	
//										rg1_gtrx_data0
	always@(posedge	clk)	rg0_gtrx_data			<=	gtrx_data					;
	always@(posedge	clk)	rg0_gtrx_charisk		<=	gtrx_charisk				;
	always@(posedge	clk)	rg0_gtrx_chariscomma	<=	gtrx_chariscomma			;

	always@(posedge	clk)	rg1_gtrx_data			<=	rg0_gtrx_data				;
	always@(posedge	clk)	rg1_gtrx_charisk		<=	rg0_gtrx_charisk			;
	always@(posedge	clk)	rg1_gtrx_chariscomma	<=	rg0_gtrx_chariscomma		;

	wire	ln0_b3iska	=	rg0_gtrx_charisk[3]	&&	rg0_gtrx_data[3*8+:8]	==	8'hFB	;	

	reg		[	LINK_WIDTH*4*8	-1:0]	lnx_gtrx_dat	=	{{LINK_WIDTH}{{4{RSVD}}}}	;
	reg		[	LINK_WIDTH*4	-1:0]	lnx_gtrx_isk	=	{{LINK_WIDTH}{{4{1'b1}}}}	;
	reg		[	LINK_WIDTH*4	-1:0]	lnx_gtrx_cmm	=	{{LINK_WIDTH}{{4{1'b1}}}}	;
	reg		[	LINK_WIDTH*1	-1:0]	lnx_gtrx_ali	=	{{LINK_WIDTH}{{4{1'b0}}}}	;
	reg		[	LINK_WIDTH*4	-1:0]	lnx_gtrx_sft	=	0	;

	always@(posedge	clk)	lnx_gtrx_dat[0*32+:32]	<=	rg0_gtrx_data			[0*32+:32]					;
	always@(posedge	clk)	lnx_gtrx_isk[0*04+:04]	<=	rg0_gtrx_charisk		[0*04+:04]					;
	always@(posedge	clk)	lnx_gtrx_cmm[0*04+:04]	<=	rg0_gtrx_chariscomma	[0*04+:04]					;
	always@(posedge	clk)	lnx_gtrx_ali[0*01+:01]	<=	gtrx_chanisaligned		[0*01+:01]					;
	always@(posedge	clk)	lnx_gtrx_sft[0*04+:04]	<=	4'h0												;


	wire	[LINK_WIDTH-1:0]	lnx_b3_ls1_k_a	;	assign	lnx_b3_ls1_k_a[0]	=	1'b1	;	//	左移1字符
	wire	[LINK_WIDTH-1:0]	lnx_b3_ls2_k_a	;	assign	lnx_b3_ls2_k_a[0]	=	1'b1	;	//	左移2字符
	wire	[LINK_WIDTH-1:0]	lnx_b3_rs1_k_a	;	assign	lnx_b3_rs1_k_a[0]	=	1'b1	;	//	右移1字符
	wire	[LINK_WIDTH-1:0]	lnx_b3_rs2_k_a	;	assign	lnx_b3_rs2_k_a[0]	=	1'b1	;	//	右移2字符

	wire	[LINK_WIDTH*32-1:32]	lnx_b3_ls1_dat	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_ls1_isk	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_ls1_cmm	;
		
	wire	[LINK_WIDTH*32-1:32]	lnx_b3_ls2_dat	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_ls2_isk	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_ls2_cmm	;
    	
	wire	[LINK_WIDTH*32-1:32]	lnx_b3_rs1_dat	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_rs1_isk	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_rs1_cmm	;
		
	wire	[LINK_WIDTH*32-1:32]	lnx_b3_rs2_dat	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_rs2_isk	;
	wire	[LINK_WIDTH*04-1:04]	lnx_b3_rs2_cmm	;	
	
genvar	i,j	;
generate for(i=1;i<LINK_WIDTH;i=i+1)begin
//////////////////////	{rg1_gtrx_charisk,rg0_gtrx_charisk,gtrx_charisk}
	assign	lnx_b3_ls1_k_a[i*01+:01]	=	rg1_gtrx_charisk[i*4+0]	&&	rg1_gtrx_data[i*32+0*08+:08]	==	8'hFB	;
	assign	lnx_b3_ls2_k_a[i*01+:01]	=	rg1_gtrx_charisk[i*4+1]	&&	rg1_gtrx_data[i*32+1*08+:08]	==	8'hFB	;
	assign	lnx_b3_rs1_k_a[i*01+:01]	=	rg0_gtrx_charisk[i*4+2]	&&	rg0_gtrx_data[i*32+2*08+:08]	==	8'hFB	;
	assign	lnx_b3_rs2_k_a[i*01+:01]	=	rg0_gtrx_charisk[i*4+1]	&&	rg0_gtrx_data[i*32+1*08+:08]	==	8'hFB	;

	assign	lnx_b3_ls1_dat[i*32+:32]	=	{	rg1_gtrx_data		[i*32+0+:1*8]		,	rg0_gtrx_data			[i*32+4*8-1-:(4-1)*8]	}	;
	assign	lnx_b3_ls1_isk[i*04+:04]	=	{	rg1_gtrx_charisk	[i*04+0+:1*1]		,	rg0_gtrx_charisk		[i*04+4*1-1-:(4-1)*1]	}	;
	assign	lnx_b3_ls1_cmm[i*04+:04]	=	{	rg1_gtrx_chariscomma[i*04+0+:1*1]		,	rg0_gtrx_chariscomma	[i*04+4*1-1-:(4-1)*1]	}	;
	
	
	assign	lnx_b3_ls2_dat[i*32+:32]	=	{	rg1_gtrx_data		[i*32+0+:2*8]		,	rg0_gtrx_data			[i*32+4*8-1-:(4-2)*8]	}	;
	assign	lnx_b3_ls2_isk[i*04+:04]	=	{	rg1_gtrx_charisk	[i*04+0+:2*1]		,	rg0_gtrx_charisk		[i*04+4*1-1-:(4-2)*1]	}	;
	assign	lnx_b3_ls2_cmm[i*04+:04]	=	{	rg1_gtrx_chariscomma[i*04+0+:2*1]		,	rg0_gtrx_chariscomma	[i*04+4*1-1-:(4-2)*1]	}	;

	assign	lnx_b3_rs1_dat[i*32+:32]	=	{	rg0_gtrx_data		[i*32+0+:(4-1)*8]	,		gtrx_data			[i*32+4*8-1-:1*8]		}	;
	assign	lnx_b3_rs1_isk[i*04+:04]	=	{	rg0_gtrx_charisk	[i*04+0+:(4-1)*1]	,		gtrx_charisk		[i*04+4*1-1-:1*1]		}	;
	assign	lnx_b3_rs1_cmm[i*04+:04]	=	{	rg0_gtrx_chariscomma[i*04+0+:(4-1)*1]	,		gtrx_chariscomma	[i*04+4*1-1-:1*1]		}	;

	assign	lnx_b3_rs2_dat[i*32+:32]	=	{	rg0_gtrx_data		[i*32+0+:(4-2)*8]	,		gtrx_data			[i*32+4*8-1-:2*8]		}	;
	assign	lnx_b3_rs2_isk[i*04+:04]	=	{	rg0_gtrx_charisk	[i*04+0+:(4-2)*1]	,		gtrx_charisk		[i*04+4*1-1-:2*1]		}	;
	assign	lnx_b3_rs2_cmm[i*04+:04]	=	{	rg0_gtrx_chariscomma[i*04+0+:(4-2)*1]	,		gtrx_chariscomma	[i*04+4*1-1-:2*1]		}	;

	always@(posedge	clk)	begin
		if			(	rst		)	begin
			lnx_gtrx_dat[i*32+:32]	<=	{4{RSVD}}	;
			lnx_gtrx_isk[i*04+:04]	<=	{4{1'b1}}	;
			lnx_gtrx_cmm[i*04+:04]	<=	{4{1'b1}}	;
			lnx_gtrx_ali[i*01+:01]	<=	1'b0		;
			lnx_gtrx_sft[i*04+:04]	<=	4'h0		;
		end	else	if	(	gtrx_error_or	||		force_reinit	)	begin
			lnx_gtrx_dat[i*32+:32]	<=	{4{RSVD}}	;
			lnx_gtrx_isk[i*04+:04]	<=	{4{1'b1}}	;
			lnx_gtrx_cmm[i*04+:04]	<=	{4{1'b1}}	;
			lnx_gtrx_ali[i*01+:01]	<=	1'b0		;
			lnx_gtrx_sft[i*04+:04]	<=	4'h0		;
			
		end	else	if	(	gtrx_chanisaligned[i]	==	1'b1		)	begin
			lnx_gtrx_dat[i*32+:32]	<=	rg0_gtrx_data		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	rg0_gtrx_charisk	[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	rg0_gtrx_chariscomma[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	4'h0											;
		end	else	if	(	lnx_gtrx_sft[i*04+0+:1]	==	1'b1		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	ln0_b3iska	!=	lnx_b3_rs2_k_a	[i]	?	{4{RSVD}}:	lnx_b3_rs2_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_rs2_k_a	[i]	?	{4{1'b1}}:	lnx_b3_rs2_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_rs2_k_a	[i]	?	{4{1'b1}}:	lnx_b3_rs2_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	ln0_b3iska	!=	lnx_b3_rs2_k_a	[i]	?	1'b0	:	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_rs2_k_a	[i]	?	4'h0	:	lnx_gtrx_sft		[i*04+:04]					;
		end	else	if	(	lnx_gtrx_sft[i*04+1+:1]	==	1'b1		)	begin
			lnx_gtrx_dat[i*32+:32]	<=	ln0_b3iska	!=	lnx_b3_rs1_k_a	[i]	?	{4{RSVD}}:	lnx_b3_rs1_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_rs1_k_a	[i]	?	{4{1'b1}}:	lnx_b3_rs1_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_rs1_k_a	[i]	?	{4{1'b1}}:	lnx_b3_rs1_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	ln0_b3iska	!=	lnx_b3_rs1_k_a	[i]	?	1'b0	:	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_rs1_k_a	[i]	?	4'h0	:	lnx_gtrx_sft		[i*04+:04]					;
		end	else	if	(	lnx_gtrx_sft[i*04+2+:1]	==	1'b1		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	ln0_b3iska	!=	lnx_b3_ls1_k_a	[i]	?	{4{RSVD}}:	lnx_b3_ls1_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_ls1_k_a	[i]	?	{4{1'b1}}:	lnx_b3_ls1_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_ls1_k_a	[i]	?	{4{1'b1}}:	lnx_b3_ls1_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	ln0_b3iska	!=	lnx_b3_ls1_k_a	[i]	?	1'b0	:	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_ls1_k_a	[i]	?	4'h0	:	lnx_gtrx_sft		[i*04+:04]					;
		end	else	if	(	lnx_gtrx_sft[i*04+3+:1]	==	1'b1		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	ln0_b3iska	!=	lnx_b3_ls2_k_a	[i]	?	{4{RSVD}}:	lnx_b3_ls2_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_ls2_k_a	[i]	?	{4{1'b1}}:	lnx_b3_ls2_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_ls2_k_a	[i]	?	{4{1'b1}}:	lnx_b3_ls2_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	ln0_b3iska	!=	lnx_b3_ls2_k_a	[i]	?	1'b0	:	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	ln0_b3iska	!=	lnx_b3_ls2_k_a	[i]	?	4'h0	:	lnx_gtrx_sft		[i*04+:04]					;
		end	else	if	(	ln0_b3iska	&&	lnx_b3_ls1_k_a	[i]		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	lnx_b3_ls1_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	lnx_b3_ls1_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	lnx_b3_ls1_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	4'b0100											;
		end	else	if	(	ln0_b3iska	&&	lnx_b3_ls2_k_a	[i]		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	lnx_b3_ls2_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	lnx_b3_ls2_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	lnx_b3_ls2_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	4'b1000											;
		end	else	if	(	ln0_b3iska	&&	lnx_b3_rs1_k_a	[i]		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	lnx_b3_rs1_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	lnx_b3_rs1_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	lnx_b3_rs1_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	4'b0010											;
		end	else	if	(	ln0_b3iska	&&	lnx_b3_rs2_k_a	[i]		)	begin	
			lnx_gtrx_dat[i*32+:32]	<=	lnx_b3_rs2_dat		[i*32+:32]					;
			lnx_gtrx_isk[i*04+:04]	<=	lnx_b3_rs2_isk		[i*04+:04]					;
			lnx_gtrx_cmm[i*04+:04]	<=	lnx_b3_rs2_cmm		[i*04+:04]					;
			lnx_gtrx_ali[i*01+:01]	<=	1'b1											;
			lnx_gtrx_sft[i*04+:04]	<=	4'b0001											;
		end	else														begin
			lnx_gtrx_dat[i*32+:32]	<=	32'hBCBCBCBC									;
			lnx_gtrx_isk[i*04+:04]	<=	4'b1111											;
			lnx_gtrx_cmm[i*04+:04]	<=	4'b1111											;
			lnx_gtrx_ali[i*01+:01]	<=	4'b0000											;
			lnx_gtrx_sft[i*04+:04]	<=	4'b0000											;
		end
	end
end	endgenerate			
	
////////////	处理	&chanisaligned！=1	情况下的特殊符号不对齐情况	begin	////////////
	localparam	A_CHAR		=	8'hFB		;	//	special	char	A
	localparam	K_CHAR		=	8'hBC		;	//	special	char	K
	localparam	R_CHAR		=	8'hFD		;	//	special	char	R
	localparam	M_CHAR		=	8'h3C		;	//	special	char	M
	localparam	P_CHAR		=	8'h7C		;	//	special	char	PD
	localparam	S_CHAR		=	8'h1C		;	//	special	char	SC
			
	reg		[	LINK_WIDTH*4*8	-1:0]	oreg_data			=	{{LINK_WIDTH}{{4{RSVD}}}}				;
	reg		[	LINK_WIDTH*4	-1:0]	oreg_charisk		=	{{LINK_WIDTH}{{4{1'b1}}}}				;
	reg		[	LINK_WIDTH*4	-1:0]	oreg_chariscomma	=	{{LINK_WIDTH}{{4{1'b1}}}}				;		
	reg		[	LINK_WIDTH*4	-1:0]	oreg_chanisaligned	=	{{LINK_WIDTH}{{4{1'b0}}}}				;		
	
	generate
		for(i=0;i<LB;i=i+1)begin	
			for(j=1;j<LW;j=j+1)begin	
				always@(posedge	clk)	begin
					if	(	(	lnx_gtrx_isk[i]	&&	lnx_gtrx_dat[i*8+:8]	==	R_CHAR	)			
						||	(	lnx_gtrx_isk[i]	&&	lnx_gtrx_dat[i*8+:8]	==	M_CHAR	))	begin
						oreg_data		[j*32+i*8+:8]	<=	gtrx_chanisaligned[j]?	lnx_gtrx_dat[j*32+i*8+:8]	:	lnx_gtrx_dat[i*8+:8]	;
						oreg_charisk	[j*04+i*1+:1]	<=  gtrx_chanisaligned[j]?	lnx_gtrx_isk[j*04+i*1+:1]	:	lnx_gtrx_isk[i*1+:1]	;
						oreg_chariscomma[j*04+i*1+:1]	<=	gtrx_chanisaligned[j]?	lnx_gtrx_cmm[j*04+i*1+:1]	:	lnx_gtrx_cmm[i*1+:1]	;
					end	else																begin
						oreg_data		[j*32+i*8+:8]	<=	lnx_gtrx_dat[j*32+i*8+:8]	;
						oreg_charisk	[j*04+i*1+:1]	<=  lnx_gtrx_isk[j*04+i*1+:1]	;
						oreg_chariscomma[j*04+i*1+:1]	<=	lnx_gtrx_cmm[j*04+i*1+:1]	;
					end
				end
			end
		end
	endgenerate
	
	always@(posedge	clk)	begin
		oreg_data			[0*32+:32]	<=	lnx_gtrx_dat	[0*32+:32]	;
	    oreg_charisk		[0*04+:04]	<=	lnx_gtrx_isk    [0*04+:04]	;
	    oreg_chariscomma	[0*04+:04]	<=	lnx_gtrx_cmm    [0*04+:04]	;
		oreg_chanisaligned				<=	lnx_gtrx_ali				;
	end
	
	assign	shft_data				=		oreg_data			;
	assign	shft_charisk			=	    oreg_charisk		;
	assign	shft_chariscomma		=		oreg_chariscomma	;
	assign	shft_chanisaligned		=		oreg_chanisaligned	;

////////////	处理	&chanisaligned！=1	情况下的特殊符号不对齐情况	end	////////////

//	`ifdef	DBG_ILA		
//
//	wire	[31:0]	ln3_gtrx_data			=	gtrx_data		[3*32+:32]	;
//	wire	[31:0]	ln2_gtrx_data			=	gtrx_data		[2*32+:32]	;
//	wire	[31:0]	ln1_gtrx_data			=	gtrx_data		[1*32+:32]	;
//	wire	[31:0]	ln0_gtrx_data			=	gtrx_data		[0*32+:32]	;
//	wire	[3:0]	ln3_gtrx_charisk		=	gtrx_charisk	[3*04+:04]	;
//	wire	[3:0]	ln2_gtrx_charisk		=	gtrx_charisk	[2*04+:04]	;
//	wire	[3:0]	ln1_gtrx_charisk		=	gtrx_charisk	[1*04+:04]	;
//	wire	[3:0]	ln0_gtrx_charisk		=	gtrx_charisk	[0*04+:04]	;
//
//	wire	[31:0]	lnx_bt3_shft_data			=	{	shft_data	[3*32+3*8+:8],	shft_data	[2*32+3*8+:8]	,	shft_data	[1*32+3*8+:8],	shft_data	[0*32+3*8+:8]	}	;
//	wire	[3:0]	lnx_bt3_shft_charisk		=	{	shft_charisk[3*04+3*1+:1],	shft_charisk[2*04+3*1+:1]	,	shft_charisk[1*04+3*1+:1],	shft_charisk[0*04+3*1+:1]	}	;
//
//
//
//
//			ila_288X1024 ila_576X1024_parse (
//				.	clk		(	clk	)	,	// input wire clk
//				.	probe0	(	
//								{
//	
//									lnx_b3_ls1_k_a			,
//									lnx_b3_ls2_k_a			,
//									lnx_b3_rs1_k_a			,
//									lnx_b3_rs2_k_a			,
//									ln0_b3iska				,
//									
//									ln3_gtrx_data			,
//									ln2_gtrx_data			,
//									ln1_gtrx_data			,
//									ln0_gtrx_data			,
//									ln3_gtrx_charisk		,
//									ln2_gtrx_charisk		,
//									ln1_gtrx_charisk		,
//									ln0_gtrx_charisk		,
//									gtrx_chanisaligned		,
//									
//									lnx_bt3_shft_data	,	
//									lnx_bt3_shft_charisk,
//									shft_chanisaligned	,
//									
//									lnx_gtrx_ali			,
//									lnx_gtrx_sft			,
//									force_reinit			,
//									gtrx_error_or
//									
//									
//									
//								}	
//							)		// input wire [31:0] probe0
//			);
//	`endif

endmodule
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			