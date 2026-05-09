
//	Company			:	Cavige
//	Engineer		:	LJP
//	Create	Date	:	2022年2月22日18:01:30
//	Design	Name	:	
//	Module	Name	:	
//	Project	Name	:	
//	Target	Devices	:	all	Xilinx device
//	Tool	versions:	all
//	Description		:	
//	Editor			:	Npp,	tab	size	(4)
//	Dependencies	:	srio phy specification
//	Revision		:	1.00
//	Revision	1.00	-	File	Created	by		:	LJP
//	Description		:	srio idle2 seq descram
//
//	Revision	1.01	-	File	Modified	by	:	
//	Description							:
//	
//	Additional	Comments:	
//
//////////////////////////////////////////////////////////////////////////////////

//	`timescale	1ns/1ps

module	srio_descram_top	#(
	parameter	LOOP_NUM							=	0						,	//	数据位宽	
	parameter	D_WIDTH								=	32						,	//	数据位宽	
	parameter	P_WIDTH								=	17						,	//	方程式位宽	
	parameter	SEED								=	17'h1FFFF				,	//	初始化种子	
	parameter	POLY								=	17'h10081				,	//	方程式掩码	
	parameter	LINK_WIDTH							=	4						,	//	Number	of	GT	lanes	{1,	2,	4}
	parameter	GT_BYTES							=	4							//	Bytes	on	the	GT	Interface
)(

	//Serdes	inputs
		input	wire	[			GT_BYTES*8	-1:0]		ensc_data				,	//	加绕数据输入
		input	wire	[			GT_BYTES	-1:0]		ensc_charisk			,	//	加绕数据输入
		input	wire	[			GT_BYTES	-1:0]		ensc_chariscomma		,	//	加绕数据输入

		output	reg		[			GT_BYTES*8	-1:0]		desc_data		=	{4{8'hbc}}	,	//	解扰数据输出
		output	reg		[			GT_BYTES	-1:0]		desc_charisk	=	{4{1'b1}}	,	//	解扰数据输出
		output	reg		[			GT_BYTES	-1:0]		desc_chariscomma=	{4{1'b1}}	,	//	解扰数据输出

		output	reg											desc_verify_ok		=0			,	//	解扰验证通过
		output	reg		[			04			-1:0]		desc_verify_err_cnt	=0			,	//	解扰错误次数
		input	wire	[			GT_BYTES	-1:0]		idle2_cs_break_i				,	//	空闲序列终止输入，LANE_ID!=0适用
		output	wire	[			GT_BYTES	-1:0]		idle2_cs_break_o				,	//	空闲序列终止输出，LANE_ID==0适用
			
		input	wire										gt_pcs_rst						,
		input	wire										gt_pcs_clk						
	);	

	localparam	LW	=	LINK_WIDTH		;
	localparam	LB	=	GT_BYTES		;
	
	localparam	RSVD	=	8'hBC		;

	wire	rst	;
	wire	clk	;
	
	assign	rst	=	gt_pcs_rst	;
	assign	clk	=	gt_pcs_clk	;


	wire	[	LB*8	-1:0]		r1rx_data				;	assign	r1rx_data			=	ensc_data			;		
	wire	[	LB*1	-1:0]		r1rx_charisk			;	assign	r1rx_charisk		=	ensc_charisk		;		
	wire	[	LB*1	-1:0]		r1rx_chariscomma		;	assign	r1rx_chariscomma	=	ensc_chariscomma	;		

	reg		[	LB*8	-1:0]		r2rx_data			=	{4{8'hbc}}	;
	reg		[	LB*1	-1:0]		r2rx_charisk		=	{4{1'b1}}	;
	reg		[	LB*1	-1:0]		r2rx_chariscomma	=	{4{1'b1}}	;

	reg		[	LB*8	-1:0]		r3rx_data			=	{4{8'hbc}}	;
	reg		[	LB*1	-1:0]		r3rx_charisk		=	{4{1'b1}}	;
	reg		[	LB*1	-1:0]		r3rx_chariscomma	=	{4{1'b1}}	;

	reg		[	LB*8	-1:0]		r4rx_data			=	{4{8'hbc}}	;
	reg		[	LB*1	-1:0]		r4rx_charisk		=	{4{1'b1}}	;
	reg		[	LB*1	-1:0]		r4rx_chariscomma	=	{4{1'b1}}	;
	
	reg		[	LB*8	-1:0]		r5rx_data			=	{4{8'hbc}}	;
	reg		[	LB*1	-1:0]		r5rx_charisk		=	{4{1'b1}}	;
	reg		[	LB*1	-1:0]		r5rx_chariscomma	=	{4{1'b1}}	;

	wire	[	LB*8	-1:0]		descram_o_sync			;
	wire	[	LB*8	-1:0]		descram_o_valid			;
	wire	[	LB*8	-1:0]		enscram_o_valid			;

	reg		[	LB*1	-1:0]		cs_field_mark		=0	;
	wire	[	LB*8	-1:0]		descram_i_sync			;
	wire	[	LB*8	-1:0]		descram_i_valid			;
	wire	[	LB*8	-1:0]		descram_i_data			;	assign	descram_i_data	=	r4rx_data	;
	reg								desc_sync_check		=0	;
//	reg								desc_sync_load		=0	;
	reg		[	17		-1:0]		desc_sync_seed		=0	;
	wire	[	LB*8	-1:0]		descram_o_data			;

	always@(posedge	clk)	begin
		r2rx_data				<=	r1rx_data				;
		r2rx_charisk			<=	r1rx_charisk			;
        r2rx_chariscomma		<=	r1rx_chariscomma		;
		r3rx_data				<=	r2rx_data				;
		r3rx_charisk			<=	r2rx_charisk			;
        r3rx_chariscomma		<=	r2rx_chariscomma		;
		r4rx_data				<=	r3rx_data				;
		r4rx_charisk			<=	r3rx_charisk			;
        r4rx_chariscomma		<=	r3rx_chariscomma		;
		r5rx_data				<=	r4rx_data				;
		r5rx_charisk			<=	r4rx_charisk			;
        r5rx_chariscomma		<=	r4rx_chariscomma		;
	end

	localparam	A_CHAR		=	8'hFB		;	//	special	char	A
	localparam	K_CHAR		=	8'hBC		;	//	special	char	K
	localparam	R_CHAR		=	8'hFD		;	//	special	char	R
	localparam	M_CHAR		=	8'h3C		;	//	special	char	M
	localparam	P_CHAR		=	8'h7C		;	//	special	char	PD
	localparam	S_CHAR		=	8'h1C		;	//	special	char	SC

	wire	[	4	-1:0]	r1rx_is_a			;
	wire	[	4	-1:0]	r1rx_is_k			;
	wire	[	4	-1:0]	r1rx_is_r			;
	wire	[	4	-1:0]	r1rx_is_m			;
	wire	[	4	-1:0]	r1rx_is_p			;
	wire	[	4	-1:0]	r1rx_is_s			;

	reg		[	4	-1:0]	r2rx_is_a	=0		;	always@(posedge	clk)	r2rx_is_a	<=	r1rx_is_a	;
	reg		[	4	-1:0]	r2rx_is_k	=0		;	always@(posedge	clk)	r2rx_is_k	<=	r1rx_is_k	;
	reg		[	4	-1:0]	r2rx_is_r	=0		;	always@(posedge	clk)	r2rx_is_r	<=	r1rx_is_r	;
	reg		[	4	-1:0]	r2rx_is_m	=0		;	always@(posedge	clk)	r2rx_is_m	<=	r1rx_is_m	;
	reg		[	4	-1:0]	r2rx_is_p	=0		;	always@(posedge	clk)	r2rx_is_p	<=	r1rx_is_p	;
	reg		[	4	-1:0]	r2rx_is_s	=0		;	always@(posedge	clk)	r2rx_is_s	<=	r1rx_is_s	;

	reg		[	4	-1:0]	r3rx_is_a	=0		;	always@(posedge	clk)	r3rx_is_a	<=	r2rx_is_a	;
	reg		[	4	-1:0]	r3rx_is_k	=0		;	always@(posedge	clk)	r3rx_is_k	<=	r2rx_is_k	;
	reg		[	4	-1:0]	r3rx_is_r	=0		;	always@(posedge	clk)	r3rx_is_r	<=	r2rx_is_r	;
	reg		[	4	-1:0]	r3rx_is_m	=0		;	always@(posedge	clk)	r3rx_is_m	<=	r2rx_is_m	;
	reg		[	4	-1:0]	r3rx_is_p	=0		;	always@(posedge	clk)	r3rx_is_p	<=	r2rx_is_p	;
	reg		[	4	-1:0]	r3rx_is_s	=0		;	always@(posedge	clk)	r3rx_is_s	<=	r2rx_is_s	;


	genvar	i,j;
	generate	for	(i=0;	i	<	LB;	i=i+1)	begin	
		assign	r1rx_is_a		[i]	=	r1rx_charisk[i]	&&	r1rx_data[i*8+:8]==A_CHAR	;
		assign	r1rx_is_k		[i]	=	r1rx_charisk[i]	&&	r1rx_data[i*8+:8]==K_CHAR	;
		assign	r1rx_is_r		[i]	=	r1rx_charisk[i]	&&	r1rx_data[i*8+:8]==R_CHAR	;
		assign	r1rx_is_m		[i]	=	r1rx_charisk[i]	&&	r1rx_data[i*8+:8]==M_CHAR	;
		assign	r1rx_is_p		[i]	=	r1rx_charisk[i]	&&	r1rx_data[i*8+:8]==P_CHAR	;
		assign	r1rx_is_s		[i]	=	r1rx_charisk[i]	&&	r1rx_data[i*8+:8]==S_CHAR	;
	end		endgenerate


////////////	CS 字段检测	begin	////////////
	wire	w_mmmm_match				;	//	CS字段以	M,M,M,M 开始
	assign	w_mmmm_match=	r1rx_is_m[3]&&r1rx_is_m[2]&&r1rx_is_m[1]&&r1rx_is_m[0]	||
							r2rx_is_m[0]&&r1rx_is_m[3]&&r1rx_is_m[2]&&r1rx_is_m[1]	||
							r2rx_is_m[1]&&r2rx_is_m[0]&&r1rx_is_m[3]&&r1rx_is_m[2]	||
							r2rx_is_m[2]&&r2rx_is_m[1]&&r2rx_is_m[0]&&r1rx_is_m[3]	;
	
	
	assign				idle2_cs_break_o	=	LOOP_NUM==0	?	r1rx_charisk&(~r1rx_is_m)	:	0				;
	wire	[LB-1:0]	idle2_cs_break		=	LOOP_NUM==0	?	idle2_cs_break_o			:	idle2_cs_break_i;
	reg	[8:0]	r_mmmm_match	=	0;	//(8-4+32)	chars	after	mmmm Sequence
	always@(posedge	clk)	r_mmmm_match	<=	|idle2_cs_break	?	0	:	{	r_mmmm_match[7:0],w_mmmm_match	}	;
	
	reg	[4-1:0]	mmmm_mark	=	0;
	always@(posedge	clk)	begin
		if			(	r1rx_is_m[3]&&r1rx_is_m[2]&&r1rx_is_m[1]&&r1rx_is_m[0]	)	begin
			mmmm_mark	<=	4'b1111									;	
		end	else	if(	r2rx_is_m[0]&&r1rx_is_m[3]&&r1rx_is_m[2]&&r1rx_is_m[1]	)	begin
			mmmm_mark	<=	4'b1110									;	
		end	else	if(	r2rx_is_m[1]&&r2rx_is_m[0]&&r1rx_is_m[3]&&r1rx_is_m[2]	)	begin
			mmmm_mark	<=	4'b1100									;	
		end	else	if(	r2rx_is_m[2]&&r2rx_is_m[1]&&r2rx_is_m[0]&&r1rx_is_m[3]	)	begin
			mmmm_mark	<=	4'b1000									;	
		end	else											begin
			mmmm_mark	<=	mmmm_mark								;	
		end
	end
	
	always@(posedge	clk)	begin	
		if			(|	r_mmmm_match[7:0]					)	begin
		
			if			(	idle2_cs_break[3]		)	begin
				cs_field_mark[0+:4]	<=	0								;
			end	else	if	(	idle2_cs_break[2]	)	begin
				cs_field_mark[3+:1]	<=	{1{1'b1}}						;
				cs_field_mark[0+:3]	<=	0								;
			end	else	if	(	idle2_cs_break[1]	)	begin
				cs_field_mark[2+:2]	<=	{2{1'b1}}						;
				cs_field_mark[0+:2]	<=	0								;
			end	else	if	(	idle2_cs_break[0]	)	begin
				cs_field_mark[1+:3]	<=	{3{1'b1}}						;
				cs_field_mark[0+:1]	<=	0								;
			end	else												begin
			
				cs_field_mark	<=	4'b1111								;	
			end
		end	else	if(r_mmmm_match[8]								)	begin
		
			if			(	idle2_cs_break[3]			)	begin
				cs_field_mark[0+:4]	<=	0									;
			end	else	if	(	r1rx_charisk[2]&&~r1rx_is_m[2]		)	begin
					cs_field_mark[3+:1]	<=	mmmm_mark[3+:1]					;
					cs_field_mark[0+:3]	<=	0								;
			end	else	if	(	idle2_cs_break[1]		)	begin
					cs_field_mark[2+:2]	<=	mmmm_mark[2+:2]					;
					cs_field_mark[0+:2]	<=	0								;
			end	else	if	(	idle2_cs_break[0]		)	begin
					cs_field_mark[1+:3]	<=	mmmm_mark[1+:3]					;
					cs_field_mark[0+:1]	<=	0								;
			end	else	                                                begin
				                                                        
			cs_field_mark	<=	mmmm_mark								;
			end	
		end	else	if(	r2rx_is_m[0]&&r1rx_is_m[3]&&r1rx_is_m[2]&&r1rx_is_m[1]	)	begin
		
			if	(	idle2_cs_break[0]	)	
				cs_field_mark		<=	0								;
			else
		
			cs_field_mark	<=	4'b0001									;
		end	else	if(	r2rx_is_m[1]&&r2rx_is_m[0]&&r1rx_is_m[3]&&r1rx_is_m[2]	)	begin
		
			if			(	idle2_cs_break[1]	)	
				cs_field_mark	<=	4'b0000									;
			else	if	(	idle2_cs_break[0]	)	
				cs_field_mark	<=	4'b0010									;
			else	
			
			
			cs_field_mark	<=	4'b0011									;
		end	else	if(	r2rx_is_m[2]&&r2rx_is_m[1]&&r2rx_is_m[0]&&r1rx_is_m[3]	)	begin
			
			if			(	idle2_cs_break[2]	)	
				cs_field_mark	<=	4'b0000									;
			else	if	(	idle2_cs_break[1]	)	
				cs_field_mark	<=	4'b0100									;
			else	if	(	idle2_cs_break[0]	)	
				cs_field_mark	<=	4'b0110									;
			else	
			
			cs_field_mark	<=	4'b0111									;
		end	else											begin
			cs_field_mark	<=	4'b0000									;
		end
	end
////////////	CS 字段检测	end	////////////
	
////////////	解扰同步	begin	////////////
	wire	[32*3-1:0]	r3r2r1rx_data		=	{	r3rx_data,r2rx_data,r1rx_data	}	;
	wire	[04*3-1:0]	r3r2r1rx_is_m		=	{	r3rx_is_m,r2rx_is_m,r1rx_is_m	}	;
	wire	[04*3-1:0]	r3r2r1rx_charisk	=	{	r3rx_charisk,r2rx_charisk,r1rx_charisk	}	;
	
	reg		[3:0]	desc_sync_mark	=	0	;	//	解扰同步时刻的数据字符掩码
	
//	wire	r3r2r1rx_is_m6	=	r3r2r1rx_is_m[6+:3]	==	3'b010	&&	r3r2r1rx_charisk[6+:3]==	3'b010	;
//	wire	r3r2r1rx_is_m5	=	r3r2r1rx_is_m[5+:3]	==	3'b010	&&	r3r2r1rx_charisk[5+:3]==	3'b010	;
//	wire	r3r2r1rx_is_m4	=	r3r2r1rx_is_m[4+:3]	==	3'b010	&&	r3r2r1rx_charisk[4+:3]==	3'b010	;
//	wire	r3r2r1rx_is_m3	=	r3r2r1rx_is_m[3+:3]	==	3'b010	&&	r3r2r1rx_charisk[3+:3]==	3'b010	;

	wire	r3r2r1rx_is_m6	=	{r3r2r1rx_charisk[6+2],r3r2r1rx_is_m[6+1],r3r2r1rx_charisk[6+0]}==	3'b010	;	//	M字符的位置
	wire	r3r2r1rx_is_m5	=	{r3r2r1rx_charisk[5+2],r3r2r1rx_is_m[5+1],r3r2r1rx_charisk[5+0]}==	3'b010	;	//	M字符的位置
	wire	r3r2r1rx_is_m4	=	{r3r2r1rx_charisk[4+2],r3r2r1rx_is_m[4+1],r3r2r1rx_charisk[4+0]}==	3'b010	;	//	M字符的位置
	wire	r3r2r1rx_is_m3	=	{r3r2r1rx_charisk[3+2],r3r2r1rx_is_m[3+1],r3r2r1rx_charisk[3+0]}==	3'b010	;	//	M字符的位置

	always@(posedge	clk)	desc_sync_check	<=	(	r3r2r1rx_is_m6	||						//	0_1000_0xxx	
													r3r2r1rx_is_m5	||						//	x_0100_00xx	  
													r3r2r1rx_is_m4	||						//	x_x010_000x	  
													r3r2r1rx_is_m3							//	x_xx01_0000	  
												)		;         
	
	assign		desc_sync_load	=	desc_sync_check	&&	~	desc_verify_ok	;                   
												
													
												
												
	always@(posedge	clk)	desc_sync_mark	<=	r3r2r1rx_is_m6	?		4'b0111							:
												r3r2r1rx_is_m5	?		4'b0011							:
												r3r2r1rx_is_m4	?		4'b0001							:
											/*	r3r2r1rx_is_m3	?	*/	4'b0000							;

	always@(posedge	clk)	desc_sync_seed	<=	r3r2r1rx_is_m6	?		r3r2r1rx_data[(6+1)*8-1-:17]		:
												r3r2r1rx_is_m5	?		r3r2r1rx_data[(5+1)*8-1-:17]		:
												r3r2r1rx_is_m4	?		r3r2r1rx_data[(4+1)*8-1-:17]		:
											/*	r3r2r1rx_is_m3	?	*/	r3r2r1rx_data[(3+1)*8-1-:17]		;




////////////	解扰同步	end	////////////
	
////////////	CS 字段检测	begin	////////////

	reg	[3:0]	seed_valid_1b	=	0	;	always@(posedge	clk)	seed_valid_1b	<=	~		r2rx_is_r								;
	reg	[3:0]	data_valid_1b	=	0	;	always@(posedge	clk)	data_valid_1b	<=	~	(	r2rx_charisk	|	cs_field_mark	)	;

	localparam	CP	=	1	;

	reg	[LB*CP-1:0]	one_descram_i_sync	=	0	;
	reg	[LB*CP-1:0]	one_descram_i_valid	=	0	;
	
	generate	for	(i=0;	i	<	LB;	i=i+1)	begin	//	将1字节扩展为8bit
		always@(posedge	clk)	one_descram_i_sync	[i*CP+:CP]	<=	desc_sync_load	?	{(CP){desc_sync_mark[i]}}	:	{(CP){seed_valid_1b[i]}}	;
		always@(posedge	clk)	one_descram_i_valid	[i*CP+:CP]	<=	desc_sync_load	?	{(CP){desc_sync_mark[i]}}	:	{(CP){data_valid_1b[i]}}	;
		assign	descram_i_sync	[i*8+:8]	=	{(8/CP){one_descram_i_sync	[i*CP+:CP]	}}	;
		assign	descram_i_valid	[i*8+:8]	=	{(8/CP){one_descram_i_valid	[i*CP+:CP]	}}	;
	end		endgenerate
		
		
////////////	CS 字段检测	end////////////	

////////////	数据解扰	begin	////////////
			scrambler_decode #		(
				.	D_WIDTH	(	D_WIDTH		)	,	//	数据位宽	
				.	P_WIDTH	(	P_WIDTH		)	,	//	方程式位宽	
				.	SEED	(	SEED		)	,	//	初始化种子	
				.	POLY	(	POLY		)	 	//	方程式掩码	
			)i_scrambler_decode(
				.	I_rst  		(	gt_pcs_rst			)	,	//	input					
				.	I_clk  		(	gt_pcs_clk			)	,	//	input					
				.	I_load 		(	desc_sync_load		)	,	//	input					
				.	I_seed 		(	desc_sync_seed		)	,	//	input	[P_WIDTH-1:0]	
				.	I_sync 		(	descram_i_sync		)	,	//	input	[D_WIDTH-1:0]	
				.	I_valid		(	descram_i_valid		)	,	//	input	[D_WIDTH-1:0]	
				.	I_data 		(	descram_i_data		)	,	//	input	[D_WIDTH-1:0]	
				.	O_sync		(	descram_o_sync		)	,	//	output	[D_WIDTH-1:0]	
				.	O_valid		(	descram_o_valid		)	,	//	output	[D_WIDTH-1:0]	
				.	O_data		(	descram_o_data		)		//	output	[D_WIDTH-1:0]	
			);
////////////	数据解扰	end	////////////


////////////	解扰同步验证	begin	////////////
	
	reg	[31:0]	r1_descram_o_data	;
	always@(posedge	clk)	r1_descram_o_data	<=	descram_o_data	;

	wire	[63:0]	descram_o_data_64	=	{	r1_descram_o_data	,	descram_o_data	}	;
	wire			desc_sync_mark_m6	=	desc_sync_check	&&	desc_sync_mark	==	4'b0111		;
	wire			desc_sync_mark_m5	=	desc_sync_check	&&	desc_sync_mark	==	4'b0011		;
	wire			desc_sync_mark_m4	=	desc_sync_check	&&	desc_sync_mark	==	4'b0001		;
	wire			desc_sync_mark_m3	=	desc_sync_check	&&	desc_sync_mark	==	4'b0000		;

	reg		[2:0]	rn_desc_sync_mark_m6	=	0	;	
	reg		[2:0]	rn_desc_sync_mark_m5	=	0	;	
	reg		[2:0]	rn_desc_sync_mark_m4	=	0	;	
	reg		[2:0]	rn_desc_sync_mark_m3	=	0	;	
	always@(posedge	clk)	begin
		rn_desc_sync_mark_m6	<=	{rn_desc_sync_mark_m6[1:0]	,	desc_sync_mark_m6	}	;	
		rn_desc_sync_mark_m5	<=	{rn_desc_sync_mark_m5[1:0]	,	desc_sync_mark_m5	}	;	
		rn_desc_sync_mark_m4	<=	{rn_desc_sync_mark_m4[1:0]	,	desc_sync_mark_m4	}	;	
		rn_desc_sync_mark_m3	<=	{rn_desc_sync_mark_m3[1:0]	,	desc_sync_mark_m3	}	;	
	end
	
	always@(posedge	clk)	begin
		if	(	rst	)	desc_verify_ok	<=	0	;
		else	if(	rn_desc_sync_mark_m6[2]	)	desc_verify_ok		<=	(descram_o_data_64[(6+1)*8-1-:32]	==	0)?1:!desc_verify_err_cnt[0];	//	忽略单次验证不通过的情况
		else	if(	rn_desc_sync_mark_m5[2]	)	desc_verify_ok		<=	(descram_o_data_64[(5+1)*8-1-:32]	==	0)?1:!desc_verify_err_cnt[0];	//	忽略单次验证不通过的情况
		else	if(	rn_desc_sync_mark_m4[2]	)	desc_verify_ok		<=	(descram_o_data_64[(4+1)*8-1-:32]	==	0)?1:!desc_verify_err_cnt[0];	//	忽略单次验证不通过的情况
		else	if(	rn_desc_sync_mark_m3[2]	)	desc_verify_ok		<=	(descram_o_data_64[(3+1)*8-1-:32]	==	0)?1:!desc_verify_err_cnt[0];	//	忽略单次验证不通过的情况
		else									desc_verify_ok		<=	desc_verify_ok														;	//	忽略单次验证不通过的情况
	end
	
	always@(posedge	clk)	begin
		if	(	rst	)	desc_verify_err_cnt	<=	0	;
		else	if(	rn_desc_sync_mark_m6[2]	)	desc_verify_err_cnt	<=	(descram_o_data_64[(6+1)*8-1-:32]	==	0)?0:desc_verify_err_cnt+1	;
		else	if(	rn_desc_sync_mark_m5[2]	)	desc_verify_err_cnt	<=	(descram_o_data_64[(5+1)*8-1-:32]	==	0)?0:desc_verify_err_cnt+1	;
		else	if(	rn_desc_sync_mark_m4[2]	)	desc_verify_err_cnt	<=	(descram_o_data_64[(4+1)*8-1-:32]	==	0)?0:desc_verify_err_cnt+1	;
		else	if(	rn_desc_sync_mark_m3[2]	)	desc_verify_err_cnt	<=	(descram_o_data_64[(3+1)*8-1-:32]	==	0)?0:desc_verify_err_cnt+1	;
		else									desc_verify_err_cnt	<=	desc_verify_err_cnt													;
	end
	
	always@(posedge	clk)	begin
		if	(	desc_verify_ok	)	begin
			desc_data			=	descram_o_data	;
			desc_charisk		=	r5rx_charisk	;
			desc_chariscomma	=	r5rx_chariscomma;
		end	else	begin
			desc_data			=	{{4}{RSVD}}	;
			desc_charisk		=	{{4}{1'b1}}	;
			desc_chariscomma	=	{{4}{1'b1}}	;
		end
	end
////////////	解扰同步验证	end	////////////

//	`ifdef	DBG_ILA
//	reg		desc_verify_error	=0	;	//	0-OK,1-ERR
//	
//	always@(posedge	clk)	desc_verify_error	<=	(	rn_desc_sync_mark_m6[2]	&&	descram_o_data_64[(6+1)*8-1-:32]	!=	0	)	||
//													(	rn_desc_sync_mark_m5[2]	&&	descram_o_data_64[(5+1)*8-1-:32]	!=	0	)	||
//													(	rn_desc_sync_mark_m4[2]	&&	descram_o_data_64[(4+1)*8-1-:32]	!=	0	)	||
//													(	rn_desc_sync_mark_m3[2]	&&	descram_o_data_64[(3+1)*8-1-:32]	!=	0	)	;
//
//	generate	if(LOOP_NUM==1)	begin
//		ila_288X1024 ila_288X1024_dec (
//			.	clk		(	gt_pcs_clk	)	,	// input wire clk
//			.	probe0	(	
//							{
//	
//									rn_desc_sync_mark_m6,
//									rn_desc_sync_mark_m5,
//									rn_desc_sync_mark_m4,
//									rn_desc_sync_mark_m3,	
//									
//									ensc_data			,
//									ensc_charisk		,
//									desc_data			,
//									desc_charisk		,
//									
//							//		descram_o_valid		,
//									desc_sync_mark		,
//									desc_sync_check		,
//
//							//		descram_i_sync		,
//							//		descram_i_valid		,
//							//		descram_i_data		,
//									r1_descram_o_data	,
//							//			descram_o_data	,
//
//									desc_verify_error	,
//									desc_verify_err_cnt	,
//									desc_verify_ok			
//
//								
//							}	
//						)		// input wire [31:0] probe0
//		);
//	end	endgenerate
//	`endif
		

endmodule


