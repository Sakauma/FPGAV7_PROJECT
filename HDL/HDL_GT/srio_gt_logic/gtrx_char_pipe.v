
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
//	Dependencies		:	
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	gtrx 信号预处理
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description							:
//	
//	Additional	Comments:	
//
//////////////////////////////////////////////////////////////////////////////////

//	`timescale	1ns/1ps

module	gtrx_char_pipe	#(
	parameter		LINK_WIDTH		=	1	,	//	SRIO GT LANE WIDTH					
	parameter		GT_BYTES		=	4					
)(
	input	wire	[	LINK_WIDTH*4*8	-1:0]	gtrx_data					,
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_charisk				,
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_chariscomma			,
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_disperr				,
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_notintable				,
	input	wire	[	LINK_WIDTH		-1:0]	gtrx_chanisaligned			,
	input	wire	[	LINK_WIDTH		-1:0]	gtrx_reset_done				,
	input	wire								gtrx_reset_req				,
	output	wire								gtrx_reset					,
	output	wire								gtrx_chanbonden				,
	
	output	wire								gtrx_align_rst				,
	
	output	reg		[	LINK_WIDTH		-1:0]	gtxchanisaligned			,
	output	reg									gtrx_error_or				,
	output	reg		[	32				-1:0]	gtrx_error_cnt			=0	,
	output	reg		[	32				-1:0]	r1r_gtrx_kpd_cnt		=0	,
	output	reg		[	32				-1:0]	gtx_gtrx_sof_cnt		=0	,
	input	wire								set_link_1x					,
	output	wire								any_gtrxaligned				,
	output	wire								all_gtrxaligned				,
	output	reg									idle2_detected			=0	,
	
	output	reg		[	LINK_WIDTH*4*8	-1:0]	r1rx_data		=	{{LINK_WIDTH*4}{8'hbc}}		,
	output	reg		[	LINK_WIDTH*4*1	-1:0]	r1rx_charisk	=	{{LINK_WIDTH*4}{1'b1}}		,
	output	reg		[	LINK_WIDTH*4*1	-1:0]	r1rx_chariscomma=	{{LINK_WIDTH*4}{1'b1}}		,
	output	reg		[	LINK_WIDTH*1*1	-1:0]	r1rx_chanisaligned			,

	input	wire								gt_pcs_rst					,
	input	wire								gt_pcs_clk					

);	
	
	localparam	LW	=	LINK_WIDTH		;
	localparam	LB	=	GT_BYTES		;
	
	localparam	RSVD	=	8'hBC		;
	
	wire	rst	;
	wire	clk	;
	
	assign	clk	=	gt_pcs_clk	;
//	assign	rst	=	gt_pcs_rst	;
	
	always@(posedge	clk)	gtxchanisaligned	<=	LINK_WIDTH==1	?	1'b1	:	gtrx_chanisaligned	;
	
	wire		gtrx_disperr_or		=	|	gtrx_disperr	;
	wire		gtrx_notintable_or	=	|	gtrx_notintable	;
	wire		gtrx_8b10b_error	=	gtrx_disperr	||	gtrx_notintable	;
	
	localparam	FREE_NUM	=	9	;
	reg	[FREE_NUM:0]	gtrx_err_free_cnt	=	0	;
	wire				gtrx_err_free_ok	=	gtrx_err_free_cnt[FREE_NUM]	;
	
	always@(posedge	clk)	begin
		if			(	gt_pcs_rst			)	gtrx_err_free_cnt	<=	0	;
		else	if	(	gtrx_8b10b_error	)	gtrx_err_free_cnt	<=	0	;
		else	if	(	gtrx_err_free_ok	)	gtrx_err_free_cnt	<=	gtrx_err_free_cnt				;
		else									gtrx_err_free_cnt	<=	gtrx_err_free_cnt	+	1'b1	;
	end
	
	///////////////	~(&gtrx_chanisaligned)	情况下的自动复位	begin	///////////////
	generate	
		if(LW==1)	begin
			assign	gtrx_align_rst	=	0		;
		end	else	begin
			reg				gtx_ali_rst				=	1'b0			;
			always@(posedge	clk)	gtx_ali_rst			<=	gtrx_err_free_cnt[FREE_NUM-1]	&&	~(&gtrx_chanisaligned)	;
						
			assign	gtrx_align_rst	=	gtx_ali_rst		;
		end
	endgenerate
	///////////////	~(&gtrx_chanisaligned)	情况下的自动复位	end	///////////////
	
	always@(posedge	gt_pcs_clk)	begin
		if			(	gt_pcs_rst	)							gtrx_error_cnt	<=	0	;
		else	if	(	|(gtrx_disperr	|	gtrx_notintable))	gtrx_error_cnt	<=	gtrx_error_cnt	+1	;
		else													gtrx_error_cnt	<=	gtrx_error_cnt		;
	end	
	
	always@(posedge	clk)	gtrx_error_or	<=	!	gtrx_err_free_ok	;
	assign	rst	=	gtrx_error_or	;
		
	reg		any_gtrx_chanisaligned	=	0	;	always@(posedge	clk)	any_gtrx_chanisaligned	<=	LINK_WIDTH==1	?	gtrx_err_free_ok	:	
																														gtrx_err_free_ok	&&	gtrx_chanisaligned[0]	;
	reg		all_gtrx_chanisaligned	=	0	;	always@(posedge	clk)	all_gtrx_chanisaligned	<=	LINK_WIDTH==1	?	gtrx_err_free_ok	:	
																														gtrx_err_free_ok	&&	(&gtrx_chanisaligned)	;
	
//	reg	all_gtrx_chanisaligned_n	=	1	;	always@(posedge	clk)	all_gtrx_chanisaligned_n	<=	~	all_gtrx_chanisaligned	;
	
	
	assign	gtrx_reset		=	1'b0	;
	reg		set_link_full	=	1'b1	;
	always@(posedge	clk)	set_link_full	<=	~	set_link_1x	;
	assign	gtrx_chanbonden	=	set_link_full	;
	
	assign	any_gtrxaligned	=	any_gtrx_chanisaligned	;
	assign	all_gtrxaligned	=	all_gtrx_chanisaligned	;

	always@(posedge	clk)	begin
		if	(	gt_pcs_rst	)	idle2_detected	<=	0	;
	//	else	if(gtrx_8b10b_error)										idle2_detected	<=	0	;
		else	if(gtrx_data[0*8+:8]	==	8'h3C	&&	gtrx_charisk[0]	)	idle2_detected	<=	1	;
		else	if(gtrx_data[1*8+:8]	==	8'h3C	&&	gtrx_charisk[1]	)	idle2_detected	<=	1	;
		else	if(gtrx_data[2*8+:8]	==	8'h3C	&&	gtrx_charisk[2]	)	idle2_detected	<=	1	;
		else	if(gtrx_data[3*8+:8]	==	8'h3C	&&	gtrx_charisk[3]	)	idle2_detected	<=	1	;
		else	idle2_detected	<=	idle2_detected	;
	end


	genvar	i,j;
	generate	
		for	(i=0;	i	<	LW;	i=i+1)	begin	
			always@(posedge	clk)	begin
				if	(	rst	)														begin
					r1rx_data			[i*4*8+:4*8]	<=	{{4}{RSVD}}						;
					r1rx_charisk		[i*4*1+:4*1]	<=	{{4}{1'b1}}						;
					r1rx_chariscomma	[i*4*1+:4*1]	<=	{{4}{1'b1}}						;
				end	else	if	(|(gtrx_disperr[i*4+:4]|gtrx_notintable[i*4+:4]))	begin
					r1rx_data			[i*4*8+:4*8]	<=	{{4}{RSVD}}						;
					r1rx_charisk		[i*4*1+:4*1]	<=	{{4}{1'b1}}						;
					r1rx_chariscomma	[i*4*1+:4*1]	<=	{{4}{1'b1}}						;
				end	else															begin
					r1rx_data			[i*4*8+:4*8]	<=	gtrx_data			[i*4*8+:4*8]	;
					r1rx_charisk		[i*4*1+:4*1]	<=	gtrx_charisk		[i*4*1+:4*1]	;
					r1rx_chariscomma	[i*4*1+:4*1]	<=	gtrx_chariscomma	[i*4*1+:4*1]	;
				end
			end
		end
	endgenerate
	always@(posedge	clk)	r1rx_chanisaligned				<=	gtrx_chanisaligned				;

///////////////	检测包定界符号	begin	///////////////
	localparam	A_CHAR		=	8'hFB		;	//	special	char	A
	localparam	K_CHAR		=	8'hBC		;	//	special	char	K
	localparam	R_CHAR		=	8'hFD		;	//	special	char	R
	localparam	M_CHAR		=	8'h3C		;	//	special	char	M
	localparam	P_CHAR		=	8'h7C		;	//	special	char	PD
	localparam	S_CHAR		=	8'h1C		;	//	special	char	SC

	wire	[	LW*LB	-1:0]	gtrx_a			;
	wire	[	LW*LB	-1:0]	gtrx_k			;
	wire	[	LW*LB	-1:0]	gtrx_r			;
	wire	[	LW*LB	-1:0]	gtrx_m			;
	wire	[	LW*LB	-1:0]	gtrx_p			;
	wire	[	LW*LB	-1:0]	gtrx_s			;

	wire	[	LW*LB	-1:0]	r1rx_a			;
	wire	[	LW*LB	-1:0]	r1rx_k			;
	wire	[	LW*LB	-1:0]	r1rx_r			;
	wire	[	LW*LB	-1:0]	r1rx_m			;
	wire	[	LW*LB	-1:0]	r1rx_p			;
	wire	[	LW*LB	-1:0]	r1rx_s			;

	integer	k;

	generate	for	(j=0;	j	<	LW*LB;	j=j+1)	begin	
		assign	gtrx_a		[j]	=	gtrx_charisk[j]	&&	gtrx_data[j*8+:8]==A_CHAR	;
		assign	gtrx_k		[j]	=	gtrx_charisk[j]	&&	gtrx_data[j*8+:8]==K_CHAR	;
		assign	gtrx_r		[j]	=	gtrx_charisk[j]	&&	gtrx_data[j*8+:8]==R_CHAR	;
		assign	gtrx_m		[j]	=	gtrx_charisk[j]	&&	gtrx_data[j*8+:8]==M_CHAR	;
		assign	gtrx_p		[j]	=	gtrx_charisk[j]	&&	gtrx_data[j*8+:8]==P_CHAR	;
		assign	gtrx_s		[j]	=	gtrx_charisk[j]	&&	gtrx_data[j*8+:8]==S_CHAR	;
		
		assign	r1rx_a		[j]	=	r1rx_charisk[j]	&&	r1rx_data[j*8+:8]==A_CHAR	;
		assign	r1rx_k		[j]	=	r1rx_charisk[j]	&&	r1rx_data[j*8+:8]==K_CHAR	;
		assign	r1rx_r		[j]	=	r1rx_charisk[j]	&&	r1rx_data[j*8+:8]==R_CHAR	;
		assign	r1rx_m		[j]	=	r1rx_charisk[j]	&&	r1rx_data[j*8+:8]==M_CHAR	;
		assign	r1rx_p		[j]	=	r1rx_charisk[j]	&&	r1rx_data[j*8+:8]==P_CHAR	;
		assign	r1rx_s		[j]	=	r1rx_charisk[j]	&&	r1rx_data[j*8+:8]==S_CHAR	;	
	end		endgenerate
		

	reg		[4:0]	w_r1rx_p_cnt	=	0	;
	reg		[4:0]	r_r1rx_p_cnt	=	0	;		
	always@(*)	begin
		w_r1rx_p_cnt		=	0	;
		for ( k=LB*LW-1; k>=0; k=k-1 ) begin
			if	(	r1rx_p	[k]	)		w_r1rx_p_cnt		=	w_r1rx_p_cnt	+	1'b1	;
		end
	end
	always@(posedge	clk)	r_r1rx_p_cnt	<=	w_r1rx_p_cnt	;
		
		
	always@(posedge	clk)	r1r_gtrx_kpd_cnt	<=gt_pcs_rst?0:r1r_gtrx_kpd_cnt+r_r1rx_p_cnt;
	///////////////	检测包定界符号	end	///////////////
	
	///////////////	检测包定开始符号	end	///////////////
	wire	[LW*LB*9-1:0]	gtrx_mid_char	;
	wire	[LW*LB*9-1:0]	gtrx_cvt_char	;
	wire	[LW*LB*8-1:0]	gtrx_cnvt_dat	;
	wire	[LW*LB*1-1:0]	gtrx_cnvt_isk	;

	generate	for ( i=0; i<LW*LB; i=i+1 ) begin
		assign	gtrx_mid_char	[(i%LB*LW+i/LB)*9+:9]		=	{	gtrx_charisk[i],gtrx_data	[i*8+:8]	}	;
		assign	gtrx_cnvt_dat		[i*8+:8]				=	gtrx_cvt_char		[i*9+0+:8]	;
		assign	gtrx_cnvt_isk		[i*1+:1]				=	gtrx_cvt_char		[i*9+8+:1]	;
	end	endgenerate
	
	generate	for ( i=0; i<LB; i=i+1 ) begin
		for ( j=0; j<LW; j=j+1 ) begin
		assign	gtrx_cvt_char	[i*LW*9+j*9+:9]		=	gtrx_mid_char	[i*LW*9+(LW-1-j)*9+:9]	;
	end	end	endgenerate
	
	localparam	WXX	=	LW==4	?	2	:	3	;
	wire	[WXX*LW*LB*8-1:0]	gtrx_cnvt_dat_xxx	;
	wire	[WXX*LW*LB*1-1:0]   gtrx_cnvt_isk_xxx	;
	
	localparam	P_P	=	LW==4	?	0*LW*LB	:	1*LW*LB	;	//	PRE	PIPE	trans
	wire	[3:0]		sop_byte		;
	reg		[3:0]		sop_byte_idle1=0;
	reg		[3:0]		sop_byte_idle2=0;
generate
	if(LW==4)	begin
		
		
		reg		[LW*LB*8-1:0]	gtrx_cnvt_dat_q	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	gtrx_cnvt_isk_q	=	{{LW*LB}{1'b1}}	;
				
		always@(posedge	clk)	begin
			gtrx_cnvt_dat_q	<=	gtrx_cnvt_dat	;
		    gtrx_cnvt_isk_q	<=	gtrx_cnvt_isk	;
		end
		
		assign	gtrx_cnvt_dat_xxx	=	{	gtrx_cnvt_dat_q	,	gtrx_cnvt_dat	}	;
		assign	gtrx_cnvt_isk_xxx	=	{	gtrx_cnvt_isk_q	,	gtrx_cnvt_isk	}	;
		
	end	else	if(LW==2)	begin
		
		reg		[LW*LB*8-1:0]	gtrx_cnvt_dat_q1	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	gtrx_cnvt_isk_q1	=	{{LW*LB}{1'b1}}	;
		reg		[LW*LB*8-1:0]	gtrx_cnvt_dat_q2	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	gtrx_cnvt_isk_q2	=	{{LW*LB}{1'b1}}	;
		
		always@(posedge	clk)	begin
			gtrx_cnvt_dat_q1	<=	gtrx_cnvt_dat		;
		    gtrx_cnvt_isk_q1	<=	gtrx_cnvt_isk		;
			gtrx_cnvt_dat_q2	<=	gtrx_cnvt_dat_q1	;
		    gtrx_cnvt_isk_q2	<=	gtrx_cnvt_isk_q1	;
		end
		
		assign	gtrx_cnvt_dat_xxx	=	{	gtrx_cnvt_dat_q2	,	gtrx_cnvt_dat_q1	,	gtrx_cnvt_dat	}	;
		assign	gtrx_cnvt_isk_xxx	=	{	gtrx_cnvt_isk_q2	,	gtrx_cnvt_isk_q1	,	gtrx_cnvt_isk	}	;

	end	else	if(LW==1)	begin
		
		reg		[LW*LB*8-1:0]	gtrx_cnvt_dat_q1	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	gtrx_cnvt_isk_q1	=	{{LW*LB}{1'b1}}	;
		reg		[LW*LB*8-1:0]	gtrx_cnvt_dat_q2	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	gtrx_cnvt_isk_q2	=	{{LW*LB}{1'b1}}	;
		
		always@(posedge	clk)	begin
			gtrx_cnvt_dat_q1	<=	gtrx_cnvt_dat		;
		    gtrx_cnvt_isk_q1	<=	gtrx_cnvt_isk		;
			gtrx_cnvt_dat_q2	<=	gtrx_cnvt_dat_q1	;
		    gtrx_cnvt_isk_q2	<=	gtrx_cnvt_isk_q1	;
		end
		
		assign	gtrx_cnvt_dat_xxx	=	{	gtrx_cnvt_dat_q2	,	gtrx_cnvt_dat_q1	,	gtrx_cnvt_dat	}	;
		assign	gtrx_cnvt_isk_xxx	=	{	gtrx_cnvt_isk_q2	,	gtrx_cnvt_isk_q1	,	gtrx_cnvt_isk	}	;

	end
endgenerate

		always@(posedge	clk)	sop_byte_idle1[3]	<=	gtrx_cnvt_isk_xxx[P_P+(1+3)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+3)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_dat_xxx[(P_P+(1+3)*LW-01)*8-16-3+:6]	==	{3'b000,3'b000}	;
		always@(posedge	clk)	sop_byte_idle1[2]	<=	gtrx_cnvt_isk_xxx[P_P+(1+2)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+2)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_dat_xxx[(P_P+(1+2)*LW-01)*8-16-3+:6]	==	{3'b000,3'b000}	;
		always@(posedge	clk)	sop_byte_idle1[1]	<=	gtrx_cnvt_isk_xxx[P_P+(1+1)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+1)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_dat_xxx[(P_P+(1+1)*LW-01)*8-16-3+:6]	==	{3'b000,3'b000}	;
		always@(posedge	clk)	sop_byte_idle1[0]	<=	gtrx_cnvt_isk_xxx[P_P+(1+0)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+0)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_dat_xxx[(P_P+(1+0)*LW-01)*8-16-3+:6]	==	{3'b000,3'b000}	;

		always@(posedge	clk)	sop_byte_idle2[3]	<=	gtrx_cnvt_isk_xxx[P_P+(1+3)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+3)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_isk_xxx[P_P+(1+3)*LW-01-07]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+3)*LW-01-07)*8+:8]	==	8'h7C;
		always@(posedge	clk)	sop_byte_idle2[2]	<=	gtrx_cnvt_isk_xxx[P_P+(1+2)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+2)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_isk_xxx[P_P+(1+2)*LW-01-07]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+2)*LW-01-07)*8+:8]	==	8'h7C;
		always@(posedge	clk)	sop_byte_idle2[1]	<=	gtrx_cnvt_isk_xxx[P_P+(1+1)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+1)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_isk_xxx[P_P+(1+1)*LW-01-07]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+1)*LW-01-07)*8+:8]	==	8'h7C;
		always@(posedge	clk)	sop_byte_idle2[0]	<=	gtrx_cnvt_isk_xxx[P_P+(1+0)*LW-01]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+0)*LW-01)*8+:8]	==	8'h7C	&&	gtrx_cnvt_isk_xxx[P_P+(1+0)*LW-01-07]	&&	gtrx_cnvt_dat_xxx[(P_P+(1+0)*LW-01-07)*8+:8]	==	8'h7C;
		
		assign	sop_byte	=	idle2_detected	?	sop_byte_idle2	:	sop_byte_idle1	;
		
		always@(posedge	clk)	gtx_gtrx_sof_cnt	<=	rst	?	0	:	gtx_gtrx_sof_cnt	+	sop_byte[0]+sop_byte[1]+sop_byte[2]+sop_byte[3];
	///////////////	检测包开始符号	end	///////////////
		

	/* synthesis translate_off */ 


	/* synthesis translate_on */ 

endmodule











