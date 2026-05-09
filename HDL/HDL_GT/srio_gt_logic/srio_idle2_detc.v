
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2022年2月18日10:37:48
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
//		Description		:	IDLE2空闲序列标记为BC特殊字符
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description							:
//	
//	Additional	Comments:	
//
//////////////////////////////////////////////////////////////////////////////////

//	`timescale	1ns/1ps

module	srio_idle2_detc	#(
	parameter		LINK_WIDTH		=	1	,	//	SRIO GT LANE WIDTH					
	parameter		GT_BYTES		=	4		//	SRIO GT BYTE NUMBER					
)(
	input	wire	[	LINK_WIDTH*4*8	-1:0]	desc_data					,	
	input	wire	[	LINK_WIDTH*4	-1:0]	desc_charisk				,
	input	wire	[	LINK_WIDTH*4	-1:0]	desc_chariscomma			,

	output	reg		[	LINK_WIDTH*4*8	-1:0]	flag_data					,
	output	reg		[	LINK_WIDTH*4	-1:0]	flag_charisk				,
	output	reg		[	LINK_WIDTH*4	-1:0]	flag_chariscomma			,
	
	input	wire								gt_pcs_rst					,
	input	wire								gt_pcs_clk					
);	

	localparam	RSVD	=	8'hBC	;	//	将K28.5视为无效字符

	localparam	LW	=	LINK_WIDTH	;
	localparam	LB	=	GT_BYTES	;
	
	wire	rst	;
	wire	clk	;
	
	assign	clk	=	gt_pcs_clk	;
	assign	rst	=	gt_pcs_rst	;

	localparam	A_CHAR		=	8'hFB		;	//	special	char	A
	localparam	K_CHAR		=	8'hBC		;	//	special	char	K
	localparam	R_CHAR		=	8'hFD		;	//	special	char	R
	localparam	M_CHAR		=	8'h3C		;	//	special	char	M
	localparam	P_CHAR		=	8'h7C		;	//	special	char	PD
	localparam	S_CHAR		=	8'h1C		;	//	special	char	SC

	wire	[LB-1:0]	ln0_desc_is_a	;
	wire	[LB-1:0]	ln0_desc_is_k	;
	wire	[LB-1:0]	ln0_desc_is_r	;
	wire	[LB-1:0]	ln0_desc_is_m	;
	wire	[LB-1:0]	ln0_desc_is_p	;
	wire	[LB-1:0]	ln0_desc_is_s	;
	
	wire	[3:0]		sop_byte		;
	wire	[3:0]		eop_byte		;
	wire	[3:0]		slc_byte		;
	wire	[3:0]		elc_byte		;
	
	
	reg		[	LB+1	-1:0]	wir_pkt_frame_flag				;
	reg		[	LB		-1:0]	reg_pkt_frame_flag				;
	reg		[	LB+1	-1:0]	wir_lsc_frame_flag				;
	reg		[	LB		-1:0]	reg_lsc_frame_flag				;

	wire	[	LB		-1:0]	wir_idle2_frame_flag			;
	reg		[	LB		-1:0]	reg_idle2_frame_flag			;
	
	wire	[		LB	-1:0]	wir_idle2_frame_rise			;
	
	wire	[		LB	-1:0]	exp_idle2_frame_flag			;
	assign	exp_idle2_frame_flag	=	{	reg_idle2_frame_flag[0]	,	wir_idle2_frame_flag[LB-1:1]		}	;
		
		
	genvar i,j;

	integer	k;
	
	generate	for ( i=0; i<LB; i=i+1 ) begin
		assign	ln0_desc_is_a	[i]		=	desc_charisk[i]	&&	desc_data[i*8+:8]==A_CHAR	;
		assign	ln0_desc_is_k	[i]		=	desc_charisk[i]	&&	desc_data[i*8+:8]==K_CHAR	;
		assign	ln0_desc_is_r	[i]		=	desc_charisk[i]	&&	desc_data[i*8+:8]==R_CHAR	;
		assign	ln0_desc_is_m	[i]		=	desc_charisk[i]	&&	desc_data[i*8+:8]==M_CHAR	;
		assign	ln0_desc_is_p	[i]		=	desc_charisk[i]	&&	desc_data[i*8+:8]==P_CHAR	;
		assign	ln0_desc_is_s	[i]		=	desc_charisk[i]	&&	desc_data[i*8+:8]==S_CHAR	;
	end	endgenerate
	
	generate	for ( i=0; i<LB; i=i+1 ) begin
		assign	wir_idle2_frame_rise	[i]	=	wir_idle2_frame_flag	[i]	&&	~	exp_idle2_frame_flag[i]		;
	end	endgenerate
	
	always@(*)	begin
		wir_pkt_frame_flag		=	{{LB+1}{reg_pkt_frame_flag[0]}}		;
		for ( k=LB-1; k>=0; k=k-1 ) begin
			wir_pkt_frame_flag[k]	=	wir_pkt_frame_flag[k+1]			;
			if			(	sop_byte		[k]	)		wir_pkt_frame_flag[k]	=	1'b1										;
			else	if	(	eop_byte		[k]	)		wir_pkt_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_a	[k]	)		wir_pkt_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_k	[k]	)		wir_pkt_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_r	[k]	)		wir_pkt_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_m	[k]	)		wir_pkt_frame_flag[k]	=	1'b0										;
		end
	end
	always@(posedge	clk)	reg_pkt_frame_flag	<=	rst	?	0	:	wir_pkt_frame_flag[0+:LB]	;
	
	
	always@(*)	begin
		wir_lsc_frame_flag		=	{{LB+1}{reg_lsc_frame_flag[0]}}		;
		for ( k=LB-1; k>=0; k=k-1 ) begin
			wir_lsc_frame_flag[k]	=	wir_lsc_frame_flag[k+1]			;
			if			(	slc_byte		[k]	)		wir_lsc_frame_flag[k]	=	1'b1										;
			else	if	(	elc_byte		[k]	)		wir_lsc_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_a	[k]	)		wir_lsc_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_k	[k]	)		wir_lsc_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_r	[k]	)		wir_lsc_frame_flag[k]	=	1'b0										;
			else	if	(	ln0_desc_is_m	[k]	)		wir_lsc_frame_flag[k]	=	1'b0										;
		end
	end
	always@(posedge	clk)	reg_lsc_frame_flag	<=	rst	?	0	:	wir_lsc_frame_flag[0+:LB]	;
	
//	always@(*)	begin
//		wir_idle2_frame_flag		=	{{LB+1}{reg_idle2_frame_flag[0]}}		;
//		for ( k=LB-1; k>=0; k=k-1 ) begin
//			wir_idle2_frame_flag[k]	=	wir_idle2_frame_flag[k+1]			;
//			if			(	sop_byte		[k]	)		wir_idle2_frame_flag[k]	=	1'b0										;
//			else	if	(	eop_byte		[k]	)		wir_idle2_frame_flag[k]	=	1'b1										;
//			else	if	(	slc_byte		[k]	)		wir_idle2_frame_flag[k]	=	1'b0										;
//			else	if	(	elc_byte		[k]	)		wir_idle2_frame_flag[k]	=	~reg_idle2_frame_flag[k]	?	1'b0	:1'b1	;		
//		end
//	end

	assign	wir_idle2_frame_flag	=	~(wir_pkt_frame_flag	|	wir_lsc_frame_flag)	;


	always@(posedge	clk)	reg_idle2_frame_flag	<=	rst	?	{{LB}{1'b1}}	:	wir_idle2_frame_flag[0+:LB]	;

	wire	[LW*LB*9-1:0]	desc_mid_char	;
	wire	[LW*LB*9-1:0]	desc_cvt_char	;
	wire	[LW*LB*8-1:0]	desc_cnvt_dat	;
	wire	[LW*LB*1-1:0]	desc_cnvt_isk	;

	generate	for ( i=0; i<LW*LB; i=i+1 ) begin
		assign	desc_mid_char	[(i%LB*LW+i/LB)*9+:9]		=	{	desc_charisk[i],desc_data	[i*8+:8]	}	;
		assign	desc_cnvt_dat		[i*8+:8]				=	desc_cvt_char		[i*9+0+:8]	;
		assign	desc_cnvt_isk		[i*1+:1]				=	desc_cvt_char		[i*9+8+:1]	;
	end	endgenerate
	
	generate	for ( i=0; i<LB; i=i+1 ) begin
		for ( j=0; j<LW; j=j+1 ) begin
		assign	desc_cvt_char	[i*LW*9+j*9+:9]		=	desc_mid_char	[i*LW*9+(LW-1-j)*9+:9]	;
	end	end	endgenerate
	
	localparam	WXX	=	LW==4	?	2	:	3	;
	wire	[WXX*LW*LB*8-1:0]	desc_cnvt_dat_xxx	;
	wire	[WXX*LW*LB*1-1:0]   desc_cnvt_isk_xxx	;
	
	localparam	P_P	=	LW==4	?	0*LW*LB	:	1*LW*LB	;	//	PRE	PIPE	trans
	
generate
	if(LW==4)	begin
		
		
		reg		[LW*LB*8-1:0]	desc_cnvt_dat_q	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	desc_cnvt_isk_q	=	{{LW*LB}{1'b1}}	;
				
		always@(posedge	clk)	begin
			desc_cnvt_dat_q	<=	desc_cnvt_dat	;
		    desc_cnvt_isk_q	<=	desc_cnvt_isk	;
		end
		
		assign	desc_cnvt_dat_xxx	=	{	desc_cnvt_dat_q	,	desc_cnvt_dat	}	;
		assign	desc_cnvt_isk_xxx	=	{	desc_cnvt_isk_q	,	desc_cnvt_isk	}	;
		
		//	[05+:06]	--	idle1
		//	[03+:06]	--	idle2

		for ( j=0; j<LW; j=j+1 ) begin
			for ( i=0; i<LB; i=i+1 ) begin
				always@(posedge	clk)	begin
					if			(	rst	)						begin
						flag_data			[j*LB*8+i*8+:8]	<=	RSVD	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	1'b1	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	1'b1	;
					end	else	if	(	~	wir_idle2_frame_flag[i]		)	begin
						flag_data			[j*LB*8+i*8+:8]	<=	desc_data			[j*LB*8+i*8+:8]	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	desc_charisk		[j*LB*1+i*1+:1]	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	desc_chariscomma	[j*LB*1+i*1+:1]	;
					end	else	if	(	wir_idle2_frame_rise	[i]		)	begin
						flag_data			[j*LB*8+i*8+:8]	<=	desc_data			[j*LB*8+i*8+:8]	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	desc_charisk		[j*LB*1+i*1+:1]	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	desc_chariscomma	[j*LB*1+i*1+:1]	;
					end	else												begin
						flag_data			[j*LB*8+i*8+:8]	<=	RSVD								;
						flag_charisk		[j*LB*1+i*1+:1]	<=	1'b1								;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	1'b1								;
					end
				end
			end
		end
		
	end	else	if(LW==2)	begin
		
		reg		[LW*LB*8-1:0]	desc_cnvt_dat_q1	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	desc_cnvt_isk_q1	=	{{LW*LB}{1'b1}}	;
		reg		[LW*LB*8-1:0]	desc_cnvt_dat_q2	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	desc_cnvt_isk_q2	=	{{LW*LB}{1'b1}}	;
		
		always@(posedge	clk)	begin
			desc_cnvt_dat_q1	<=	desc_cnvt_dat		;
		    desc_cnvt_isk_q1	<=	desc_cnvt_isk		;
			desc_cnvt_dat_q2	<=	desc_cnvt_dat_q1	;
		    desc_cnvt_isk_q2	<=	desc_cnvt_isk_q1	;
		end
		
		assign	desc_cnvt_dat_xxx	=	{	desc_cnvt_dat_q2	,	desc_cnvt_dat_q1	,	desc_cnvt_dat	}	;
		assign	desc_cnvt_isk_xxx	=	{	desc_cnvt_isk_q2	,	desc_cnvt_isk_q1	,	desc_cnvt_isk	}	;

		reg		[	LW*LB*8	-1:0]	reg_desc_data			=	{{LW*LB}{RSVD}}	;	always@(posedge	clk)	reg_desc_data		<=	desc_data		;			
		reg		[	LW*LB*1	-1:0]	reg_desc_charisk		=	{{LW*LB}{1'b1}}	;	always@(posedge	clk)	reg_desc_charisk	<=	desc_charisk	;		
		reg		[	LW*LB*1	-1:0]	reg_desc_chariscomma	=	{{LW*LB}{1'b1}}	;	always@(posedge	clk)	reg_desc_chariscomma<=	desc_chariscomma;		

		for ( j=0; j<LW; j=j+1 ) begin
			for ( i=0; i<LB; i=i+1 ) begin
				always@(posedge	clk)	begin
					if			(	rst	)						begin
						flag_data			[j*LB*8+i*8+:8]	<=	RSVD	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	1'b1	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	1'b1	;
					end	else	if	(	~	wir_idle2_frame_flag[i]		)	begin
						flag_data			[j*LB*8+i*8+:8]	<=	reg_desc_data			[j*LB*8+i*8+:8]	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	reg_desc_charisk		[j*LB*1+i*1+:1]	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	reg_desc_chariscomma	[j*LB*1+i*1+:1]	;
					end	else	if	(	wir_idle2_frame_rise	[i]		)	begin
						flag_data			[j*LB*8+i*8+:8]	<=	reg_desc_data			[j*LB*8+i*8+:8]	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	reg_desc_charisk		[j*LB*1+i*1+:1]	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	reg_desc_chariscomma	[j*LB*1+i*1+:1]	;
					end	else												begin
						flag_data			[j*LB*8+i*8+:8]	<=	RSVD								;
						flag_charisk		[j*LB*1+i*1+:1]	<=	1'b1								;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	1'b1								;
					end
				end
			end
		end

	end	else	if(LW==1)	begin
		
		reg		[LW*LB*8-1:0]	desc_cnvt_dat_q1	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	desc_cnvt_isk_q1	=	{{LW*LB}{1'b1}}	;
		reg		[LW*LB*8-1:0]	desc_cnvt_dat_q2	=	{{LW*LB}{RSVD}}	;
		reg		[LW*LB*1-1:0]	desc_cnvt_isk_q2	=	{{LW*LB}{1'b1}}	;
		
		always@(posedge	clk)	begin
			desc_cnvt_dat_q1	<=	desc_cnvt_dat		;
		    desc_cnvt_isk_q1	<=	desc_cnvt_isk		;
			desc_cnvt_dat_q2	<=	desc_cnvt_dat_q1	;
		    desc_cnvt_isk_q2	<=	desc_cnvt_isk_q1	;
		end
		
		assign	desc_cnvt_dat_xxx	=	{	desc_cnvt_dat_q2	,	desc_cnvt_dat_q1	,	desc_cnvt_dat	}	;
		assign	desc_cnvt_isk_xxx	=	{	desc_cnvt_isk_q2	,	desc_cnvt_isk_q1	,	desc_cnvt_isk	}	;

		reg		[	LW*LB*8	-1:0]	reg_desc_data			=	{{LW*LB}{RSVD}}	;	always@(posedge	clk)	reg_desc_data		<=	desc_data		;			
		reg		[	LW*LB*1	-1:0]	reg_desc_charisk		=	{{LW*LB}{1'b1}}	;	always@(posedge	clk)	reg_desc_charisk	<=	desc_charisk	;		
		reg		[	LW*LB*1	-1:0]	reg_desc_chariscomma	=	{{LW*LB}{1'b1}}	;	always@(posedge	clk)	reg_desc_chariscomma<=	desc_chariscomma;		

		for ( j=0; j<LW; j=j+1 ) begin
			for ( i=0; i<LB; i=i+1 ) begin
				always@(posedge	clk)	begin
					if			(	rst	)						begin
						flag_data			[j*LB*8+i*8+:8]	<=	RSVD	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	1'b1	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	1'b1	;
					end	else	if	(	~	wir_idle2_frame_flag[i]		)	begin
						flag_data			[j*LB*8+i*8+:8]	<=	reg_desc_data			[j*LB*8+i*8+:8]	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	reg_desc_charisk		[j*LB*1+i*1+:1]	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	reg_desc_chariscomma	[j*LB*1+i*1+:1]	;
					end	else	if	(	wir_idle2_frame_rise	[i]		)	begin
						flag_data			[j*LB*8+i*8+:8]	<=	reg_desc_data			[j*LB*8+i*8+:8]	;
						flag_charisk		[j*LB*1+i*1+:1]	<=	reg_desc_charisk		[j*LB*1+i*1+:1]	;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	reg_desc_chariscomma	[j*LB*1+i*1+:1]	;
					end	else												begin
						flag_data			[j*LB*8+i*8+:8]	<=	RSVD								;
						flag_charisk		[j*LB*1+i*1+:1]	<=	1'b1								;
						flag_chariscomma	[j*LB*1+i*1+:1]	<=	1'b1								;
					end
				end
			end
		end

	end
endgenerate

		assign	sop_byte[3]	=	desc_cnvt_isk_xxx[P_P+(1+3)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+3)*LW-01)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+(1+3)*LW-01)*8-24+3+:6]	==	{3'b000,3'b000}	;
		assign	sop_byte[2]	=	desc_cnvt_isk_xxx[P_P+(1+2)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+2)*LW-01)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+(1+2)*LW-01)*8-24+3+:6]	==	{3'b000,3'b000}	;
		assign	sop_byte[1]	=	desc_cnvt_isk_xxx[P_P+(1+1)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+1)*LW-01)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+(1+1)*LW-01)*8-24+3+:6]	==	{3'b000,3'b000}	;
		assign	sop_byte[0]	=	desc_cnvt_isk_xxx[P_P+(1+0)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+0)*LW-01)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+(1+0)*LW-01)*8-24+3+:6]	==	{3'b000,3'b000}	;
	
		assign	eop_byte[3]	=	desc_cnvt_isk_xxx[P_P+(1+3)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+3)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_isk_xxx[P_P+7+(1+3)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+7+(1+3)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+7+(1+3)*LW-LW)*8-24+3+:6]	!=	{3'b000,3'b000}	;
		assign	eop_byte[2]	=	desc_cnvt_isk_xxx[P_P+(1+2)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+2)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_isk_xxx[P_P+7+(1+2)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+7+(1+2)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+7+(1+2)*LW-LW)*8-24+3+:6]	!=	{3'b000,3'b000}	;
		assign	eop_byte[1]	=	desc_cnvt_isk_xxx[P_P+(1+1)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+1)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_isk_xxx[P_P+7+(1+1)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+7+(1+1)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+7+(1+1)*LW-LW)*8-24+3+:6]	!=	{3'b000,3'b000}	;
		assign	eop_byte[0]	=	desc_cnvt_isk_xxx[P_P+(1+0)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+0)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_isk_xxx[P_P+7+(1+0)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+7+(1+0)*LW-LW)*8+:8]	==	8'h7C	&&	desc_cnvt_dat_xxx[(P_P+7+(1+0)*LW-LW)*8-24+3+:6]	!=	{3'b000,3'b000}	;

		assign	slc_byte[3]	=	desc_cnvt_isk_xxx[P_P+(1+3)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+3)*LW-01)*8+:8]	==	8'h1C	;
		assign	slc_byte[2]	=	desc_cnvt_isk_xxx[P_P+(1+2)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+2)*LW-01)*8+:8]	==	8'h1C	;
		assign	slc_byte[1]	=	desc_cnvt_isk_xxx[P_P+(1+1)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+1)*LW-01)*8+:8]	==	8'h1C	;
		assign	slc_byte[0]	=	desc_cnvt_isk_xxx[P_P+(1+0)*LW-01]	&&	desc_cnvt_dat_xxx[(P_P+(1+0)*LW-01)*8+:8]	==	8'h1C	;

		assign	elc_byte[3]	=	desc_cnvt_isk_xxx[P_P+(1+3)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+3)*LW-LW)*8+:8]	==	8'h1C	;
		assign	elc_byte[2]	=	desc_cnvt_isk_xxx[P_P+(1+2)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+2)*LW-LW)*8+:8]	==	8'h1C	;
		assign	elc_byte[1]	=	desc_cnvt_isk_xxx[P_P+(1+1)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+1)*LW-LW)*8+:8]	==	8'h1C	;
		assign	elc_byte[0]	=	desc_cnvt_isk_xxx[P_P+(1+0)*LW-LW]	&&	desc_cnvt_dat_xxx[(P_P+(1+0)*LW-LW)*8+:8]	==	8'h1C	;


	//	/* synthesis translate_off */ 
		
	//	/* synthesis translate_on */ 

endmodule