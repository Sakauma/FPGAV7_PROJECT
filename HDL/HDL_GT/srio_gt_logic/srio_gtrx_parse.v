
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2022年2月14日18:01:30
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
//		Description		:	包解析
//
//		Revision	1.01	-	File	Modified	by	:	xxx
//		Description							:
//	
//	Additional	Comments:	IDLE2	Control Symbol
//	56+:08	7C/1C
//	53+:03	STYPE0
//	47+:06	PARAMETER0
//	41+:06	PARAMETER1
//	38+:03	STYPE1		32+06+:3
//	35+:03	CMD         32+03+:3
//	21+:14	RSVD		21+14
//	08+:13	CRC-13		08+13
//	00+:08	7C/1C		00+08

//////////////////////////////////////////////////////////////////////////////////
module	srio_gtrx_parse 	#(
	parameter		LINK_WIDTH		=	1	,	//	SRIO GT LANE WIDTH					
	parameter		FIFO_WIDTH		=	64		//	SRIO GT LANE WIDTH					
)(

		input	wire								gtrx_error_or				,
		input	wire								idle2_detected				,
		output	wire								gtrx_rdy_64					,
		input	wire								gtrx_vld_64					,
		input	wire	[	64				-1:0]	gtrx_dat_64					,
		input	wire	[	8				-1:0]	gtrx_isk_64					,
		
		output	wire								gtrx_dat_info_wr			,
		output	wire	[	12				-1:0]	gtrx_dat_info_di			,
		input	wire								gtrx_dat_info_af			,
		input	wire								gtrx_dat_info_fu			,
		output	wire								gtrx_dat_fifo_wr			,
		output	wire	[	FIFO_WIDTH		-1:0]	gtrx_dat_fifo_di			,
		input	wire								gtrx_dat_fifo_af			,
		input	wire								gtrx_dat_fifo_fu			,
		
		output	wire								gtrx_ksc_fifo_wr			,
		output	wire	[	FIFO_WIDTH		-1:0]	gtrx_ksc_fifo_di			,
		input	wire								gtrx_ksc_fifo_af			,
		input	wire								gtrx_ksc_fifo_fu			,
		
		output	reg		[	32				-1:0]	par_fifo_afu_cnt	=0		,
		output	reg		[	32				-1:0]	par_gtrx_sop_cnt	=0		,
		output	reg		[	32				-1:0]	par_byte_kpd_cnt	=0		,
		output	reg		[	32				-1:0]	sopdat_match_cnt	=0		,
		
		input	wire								itf_rst						,
		input	wire								itf_clk						
	);
	
	wire	rst	=	itf_rst	;
	wire	clk	=	itf_clk	;

	reg					gtrx_vld_q		=	0	;	always@(posedge	clk)	gtrx_vld_q		<=	gtrx_vld_64	 				;
	reg					gtrx_rv_q		=	0	;	always@(posedge	clk)	gtrx_rv_q		<=	gtrx_vld_64	&&	gtrx_rdy_64	;
	
	
	wire	[64/2-1:0]	msb_gtrx_dat_64	=	gtrx_dat_64	[1*64/2+:64/2]		;
	wire	[08/2-1:0]	msb_gtrx_isk_64	=	gtrx_isk_64	[1*08/2+:08/2]		;
	wire	[64/2-1:0]	lsb_gtrx_dat_64	=	gtrx_dat_64	[0*64/2+:64/2]		;
	wire	[08/2-1:0]	lsb_gtrx_isk_64	=	gtrx_isk_64	[0*08/2+:08/2]		;

	reg		[64/2-1:0]	gtd_h_q			=	0	;	always@(posedge	clk)	gtd_h_q			<=	msb_gtrx_dat_64	;
	reg		[08/2-1:0]	gtk_h_q			=	0	;	always@(posedge	clk)	gtk_h_q			<=	msb_gtrx_isk_64	;
	reg		[64/2-1:0]	gtd_l_q			=	0	;	always@(posedge	clk)	gtd_l_q			<=	lsb_gtrx_dat_64	;
	reg		[08/2-1:0]	gtk_l_q			=	0	;	always@(posedge	clk)	gtk_l_q			<=	lsb_gtrx_isk_64	;
	
	wire	msb_kpd_w	;	assign	msb_kpd_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	;	//	除SOP情况外表示包终止
	wire	msb_ksc_w	;	assign	msb_ksc_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h1C	;
	wire	msb_kbc_w	;	assign	msb_kbc_w	=(	msb_gtrx_isk_64[00+:01]	&&	msb_gtrx_dat_64[00*08+:08]	==	8'hBC)	
												||(	msb_gtrx_isk_64[01+:01]	&&	msb_gtrx_dat_64[01*08+:08]	==	8'hBC)	
												||(	msb_gtrx_isk_64[02+:01]	&&	msb_gtrx_dat_64[02*08+:08]	==	8'hBC)	
												||(	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'hBC)	;
	wire	msb_dat_w	;	assign	msb_dat_w	=	msb_gtrx_isk_64	==	0												;
	wire	lsb_kpd_w	;	assign	lsb_kpd_w	=	lsb_gtrx_isk_64[03+:01]	&&	lsb_gtrx_dat_64[03*08+:08]	==	8'h7C	;
	wire	lsb_ksc_w	;	assign	lsb_ksc_w	=	lsb_gtrx_isk_64[03+:01]	&&	lsb_gtrx_dat_64[03*08+:08]	==	8'h1C	;
	wire	lsb_kbc_w	;	assign	lsb_kbc_w	=(	lsb_gtrx_isk_64[00+:01]	&&	lsb_gtrx_dat_64[00*08+:08]	==	8'hBC)	
												||(	lsb_gtrx_isk_64[01+:01]	&&	lsb_gtrx_dat_64[01*08+:08]	==	8'hBC)	
												||(	lsb_gtrx_isk_64[02+:01]	&&	lsb_gtrx_dat_64[02*08+:08]	==	8'hBC)	
												||(	lsb_gtrx_isk_64[03+:01]	&&	lsb_gtrx_dat_64[03*08+:08]	==	8'hBC)	;
	wire	lsb_dat_w	;	assign	lsb_dat_w	=	lsb_gtrx_isk_64	==	0												;

////////////	just for idle2 ////////////
	wire	msb_epd_w		=	msb_gtrx_isk_64[00+:01]	&&	msb_gtrx_dat_64[00*08+:08]	==	8'h7C	&&	idle2_detected		;	//	长控制符的第2个DW
	wire	msb_esc_w		=	msb_gtrx_isk_64[00+:01]	&&	msb_gtrx_dat_64[00*08+:08]	==	8'h1C	&&	idle2_detected		;	//	长控制符的第2个DW
	wire	lsb_epd_w		=	lsb_gtrx_isk_64[00+:01]	&&	lsb_gtrx_dat_64[00*08+:08]	==	8'h7C	&&	idle2_detected		;	//	长控制符的第2个DW
	wire	lsb_esc_w		=	lsb_gtrx_isk_64[00+:01]	&&	lsb_gtrx_dat_64[00*08+:08]	==	8'h1C	&&	idle2_detected		;	//	长控制符的第2个DW

////////////	just for idle2 ////////////

	//	包终止（包结束eop、包取消cop等不上传）

	wire	[06-1:0]	idle1_msb_type1_cmd	=	msb_gtrx_dat_64[05+:06]	;	//	{type1,cmd}
	wire	[06-1:0]	idle1_lsb_type1_cmd	=	lsb_gtrx_dat_64[05+:06]	;	//	{type1,cmd}

	wire	[06-1:0]	idle2_msb_type1_cmd	=	msb_gtrx_dat_64[03+:06]	;	//	{type1,cmd}
	wire	[06-1:0]	idle2_lsb_type1_cmd	=	lsb_gtrx_dat_64[03+:06]	;	//	{type1,cmd}

	wire	[06-1:0]	msb_type1_cmd		=	idle2_detected	?	idle2_msb_type1_cmd	:	idle1_msb_type1_cmd	;
	wire	[06-1:0]	lsb_type1_cmd		=	idle2_detected	?	idle2_lsb_type1_cmd	:	idle1_lsb_type1_cmd	;
	

	wire	msb_sop_w	;	assign	msb_sop_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	msb_type1_cmd[3+:3]	==	3'b000	;	//	==	{3'b000,3'b000}	;	//	start	of	Packet					,考虑保留定义
	wire	lsb_sop_w	;	assign	lsb_sop_w	=	lsb_gtrx_isk_64[03+:01]	&&	lsb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	lsb_type1_cmd[3+:3]	==	3'b000	;	//	==	{3'b000,3'b000}	;	//	start	of	Packet					,考虑保留定义
//	wire	msb_cop_w	;	assign	msb_cop_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	msb_type1_cmd[3+:3]	==	3'b001	;	//	==	{3'b001,3'b000}	;	//	Stomp Control Symbol				,考虑保留定义
//	wire	msb_eop_w	;	assign	msb_eop_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	msb_type1_cmd[3+:3]	==	3'b010	;	//	==	{3'b010,3'b000}	;	//	End-of-Packet Control Symbol		,考虑保留定义
//	wire	msb_rfr_w	;	assign	msb_rfr_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	msb_type1_cmd[3+:3]	==	3'b011	;	//	==	{3'b011,3'b000}	;	//	Restart-From-Retry Control Symbol	,考虑保留定义
//	wire	msb_rst_w	;	assign	msb_rst_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	msb_type1_cmd[3+:3]	==	3'b100	;	//	==	{3'b100,3'b011}	;	//	Link-Request Control Symbol			,考虑保留定义
//	wire	msb_sta_w	;	assign	msb_sta_w	=	msb_gtrx_isk_64[03+:01]	&&	msb_gtrx_dat_64[03*08+:08]	==	8'h7C	&&	msb_type1_cmd[3+:3]	==	3'b100	;	//	==	{3'b100,3'b100}	;	//	Link-Request Control Symbol			,考虑保留定义

	wire	idle1_msb_dat_w	=	msb_dat_w	;
	wire	idle1_lsb_dat_w	=	lsb_dat_w	;

	wire	idle2_msb_dat_w	=	msb_dat_w	||	msb_epd_w		;	//	将PD长控制符的第2个DW视为数据
	wire	idle2_lsb_dat_w	=	lsb_dat_w	||	lsb_epd_w		;	//	将PD长控制符的第2个DW视为数据
            
	wire	idle1_msb_ksc_w	=	msb_ksc_w	;
	wire	idle1_lsb_ksc_w	=	lsb_ksc_w	;
            
	wire	idle2_msb_ksc_w	=	msb_ksc_w	||	msb_esc_w																				;
	wire	idle2_lsb_ksc_w	=	lsb_ksc_w	||	lsb_esc_w																				;

	reg		msb_kpd=0	;	always@(posedge	clk)	msb_kpd	<=	msb_kpd_w		||	msb_kbc_w											;
	reg		msb_ksc=0	;	always@(posedge	clk)	msb_ksc	<=	idle2_detected	?	idle2_msb_ksc_w	:	idle1_msb_ksc_w					;
	reg		msb_kbc=0	;	always@(posedge	clk)	msb_kbc	<=	msb_kbc_w																;
	reg		msb_dat=0	;	always@(posedge	clk)	msb_dat	<=	idle2_detected	?	idle2_msb_dat_w	:	idle1_msb_dat_w					;
	reg		lsb_kpd=0	;	always@(posedge	clk)	lsb_kpd	<=	lsb_kpd_w		||	lsb_kbc_w											;
	reg		lsb_ksc=0	;	always@(posedge	clk)	lsb_ksc	<=	idle2_detected	?	idle2_lsb_ksc_w	:	idle1_lsb_ksc_w					;
	reg		lsb_kbc=0	;	always@(posedge	clk)	lsb_kbc	<=	lsb_kbc_w																;
	reg		lsb_dat=0	;	always@(posedge	clk)	lsb_dat	<=	idle2_detected	?	idle2_lsb_dat_w	:	idle1_lsb_dat_w					;
	
	reg		msb_sop=0	;	always@(posedge	clk)	msb_sop	<=	msb_sop_w																;	
	reg		lsb_sop=0	;	always@(posedge	clk)	lsb_sop	<=	lsb_sop_w																;	


	reg		[32-1:00]	gtd_h_q_l	=	0										;
	reg		[32-1:00]	gtd_l_q_l	=	0										;
	
	always@(posedge	clk)	begin
		if			(	rst		)	par_gtrx_sop_cnt	<=	0	;
		else	if	(	msb_sop	&&	gtrx_rv_q	)	par_gtrx_sop_cnt	<=	par_gtrx_sop_cnt	+1	;
		else	if	(	lsb_sop	&&	gtrx_rv_q	)	par_gtrx_sop_cnt	<=	par_gtrx_sop_cnt	+1	;
		else	par_gtrx_sop_cnt	<=	par_gtrx_sop_cnt	;
	end

		reg		[63:0]	gtrx_dat_64_q	=0	;	always@(posedge	clk)	gtrx_dat_64_q	<=	gtrx_vld_64	&&	gtrx_rdy_64	?	gtrx_dat_64	:	gtrx_dat_64_q	;
		reg		[07:0]	gtrx_isk_64_q	=0	;	always@(posedge	clk)	gtrx_isk_64_q	<=	gtrx_vld_64	&&	gtrx_rdy_64	?	gtrx_isk_64	:	gtrx_isk_64_q	;
		
		wire	[64*2-1:0]	gtrx_dat_64_x2	=	{	gtrx_dat_64_q	,	gtrx_dat_64	}	;
		wire	[08*2-1:0]	gtrx_isk_64_x2	=	{	gtrx_isk_64_q	,	gtrx_isk_64	}	;
		reg		[7:0]	par_sop_byte	=	0	;
	//	always@(posedge	clk)	par_sop_byte[7]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+07+:01]	&&	gtrx_dat_64_x2[64+07*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+07*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+07*08+:1]	,	gtrx_dat_64_x2[32+6+8+07*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+07*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[6]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+06+:01]	&&	gtrx_dat_64_x2[64+06*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+06*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+06*08+:1]	,	gtrx_dat_64_x2[32+6+8+06*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+06*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[5]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+05+:01]	&&	gtrx_dat_64_x2[64+05*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+05*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+05*08+:1]	,	gtrx_dat_64_x2[32+6+8+05*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+05*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[4]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+04+:01]	&&	gtrx_dat_64_x2[64+04*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+04*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+04*08+:1]	,	gtrx_dat_64_x2[32+6+8+04*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+04*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[3]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+03+:01]	&&	gtrx_dat_64_x2[64+03*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+03*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+03*08+:1]	,	gtrx_dat_64_x2[32+6+8+03*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+03*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[2]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+02+:01]	&&	gtrx_dat_64_x2[64+02*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+02*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+02*08+:1]	,	gtrx_dat_64_x2[32+6+8+02*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+02*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[1]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+01+:01]	&&	gtrx_dat_64_x2[64+01*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+01*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+01*08+:1]	,	gtrx_dat_64_x2[32+6+8+01*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+01*08+:8]==8'h7C)		);	
	//	always@(posedge	clk)	par_sop_byte[0]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+00+:01]	&&	gtrx_dat_64_x2[64+00*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+00*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+00*08+:1]	,	gtrx_dat_64_x2[32+6+8+00*08+:2]	}==3'b000&&	gtrx_dat_64_x2[8+00*08+:8]==8'h7C)		);
	
		always@(posedge	clk)	par_sop_byte[7]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+07+:01]	&&	gtrx_dat_64_x2[64+07*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+07*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+07*08+:1]	,	gtrx_dat_64_x2[32+6+8+07*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[6]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+06+:01]	&&	gtrx_dat_64_x2[64+06*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+06*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+06*08+:1]	,	gtrx_dat_64_x2[32+6+8+06*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[5]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+05+:01]	&&	gtrx_dat_64_x2[64+05*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+05*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+05*08+:1]	,	gtrx_dat_64_x2[32+6+8+05*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[4]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+04+:01]	&&	gtrx_dat_64_x2[64+04*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+04*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+04*08+:1]	,	gtrx_dat_64_x2[32+6+8+04*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[3]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+03+:01]	&&	gtrx_dat_64_x2[64+03*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+03*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+03*08+:1]	,	gtrx_dat_64_x2[32+6+8+03*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[2]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+02+:01]	&&	gtrx_dat_64_x2[64+02*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+02*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+02*08+:1]	,	gtrx_dat_64_x2[32+6+8+02*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[1]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+01+:01]	&&	gtrx_dat_64_x2[64+01*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+01*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+01*08+:1]	,	gtrx_dat_64_x2[32+6+8+01*08+:2]	}==3'b000									)		);	
		always@(posedge	clk)	par_sop_byte[0]	<=	gtrx_vld_64	&&	gtrx_rdy_64	&&	gtrx_isk_64_x2[08+00+:01]	&&	gtrx_dat_64_x2[64+00*08+:08]	==	8'h7C	;	//	&&	((~idle2_detected?	gtrx_dat_64_x2[32+16+00*08+:3]==3'b000	:	{	gtrx_dat_64_x2[32+8+8+00*08+:1]	,	gtrx_dat_64_x2[32+6+8+00*08+:2]	}==3'b000									)		);
	
	always@(posedge	clk)	par_byte_kpd_cnt	<=	rst		?	0	:
													par_byte_kpd_cnt			
												+	par_sop_byte[7]				
												+	par_sop_byte[6]				
												+	par_sop_byte[5]				
												+	par_sop_byte[4]				
												+	par_sop_byte[3]				
												+	par_sop_byte[2]				
												+	par_sop_byte[1]				
												+	par_sop_byte[0]		;

	reg					dat_ing	=	0												;
	reg					dat_vld	=	0												;
	reg					dat_lst	=	0												;
	reg		[12-1:00]	dat_cnt	=	0												;
	reg		[32-1:00]	dat_msb	=	0												;
	reg		[32-1:00]	dat_lsb	=	0												;
	reg		[32-1:00]	dat_rem	=	0												;
	reg					dat_kpd	=	0												;
	reg					ksc_vld	=	0												;
	reg		[32-1:00]	ksc_msb	=	0												;
	reg		[32-1:00]	ksc_lsb	=	0												;

	reg					dat_ing_q	;	always@(posedge	clk)	dat_ing_q	<=	dat_ing	;
	reg					dat_vld_q	;	always@(posedge	clk)	dat_vld_q	<=	dat_vld	;
	wire				dat_lst_w	;	assign					dat_lst_w	=	dat_lst	;
	reg		[12-1:00]	dat_cnt_q	;	always@(posedge	clk)	dat_cnt_q	<=	dat_cnt	;
	reg		[32-1:00]	dat_msb_q	;	always@(posedge	clk)	dat_msb_q	<=	dat_msb	;
	reg		[32-1:00]	dat_lsb_q	;	always@(posedge	clk)	dat_lsb_q	<=	dat_lsb	;
	reg		[32-1:00]	dat_rem_q	;	always@(posedge	clk)	dat_rem_q	<=	dat_rem	;
	reg					dat_kpd_q	;	always@(posedge	clk)	dat_kpd_q	<=	dat_kpd	;
	reg					ksc_vld_q	;	always@(posedge	clk)	ksc_vld_q	<=	ksc_vld	;
	reg		[32-1:00]	ksc_msb_q	;	always@(posedge	clk)	ksc_msb_q	<=	ksc_msb	;
	reg		[32-1:00]	ksc_lsb_q	;	always@(posedge	clk)	ksc_lsb_q	<=	ksc_lsb	;

	reg		fifo_rdy	=	1	;
	always@(posedge	clk)	begin
		if			(	rst						)	fifo_rdy	<=	1			;
		else	if	(!	dat_ing	&&	!	dat_vld	)	fifo_rdy	<=	gtrx_dat_info_af||gtrx_dat_fifo_af||gtrx_ksc_fifo_af	?	0	:	1	;
		else										fifo_rdy	<=	fifo_rdy	;
	end
	
	//////////	debug	signal	检测FIFO是否溢出	begin	/////////////
	reg		fifo_rdy_q	=	1	;	always@(posedge	clk)	fifo_rdy_q	<=	fifo_rdy	;
	wire	fifo_rdy_f			;	assign	fifo_rdy_f	=	!fifo_rdy	&&	fifo_rdy_q	;
//	reg		[31:0]	par_fifo_afu_cnt	=	0	;
	always@(posedge	clk)	begin
		if			(	rst			)	par_fifo_afu_cnt	<=	0			;
		else	if	(	fifo_rdy_f	)	par_fifo_afu_cnt	<=	par_fifo_afu_cnt	+	1	;
		else							par_fifo_afu_cnt	<=	par_fifo_afu_cnt			;
	end
	//////////	debug	signal	检测FIFO是否溢出	end		/////////////
	
	assign	gtrx_dat_fifo_wr		=	dat_vld		&&	fifo_rdy											;
	
	assign	gtrx_dat_fifo_di[32+:32]=	dat_msb																;
													
	assign	gtrx_dat_fifo_di[00+:32]=	dat_lsb																;
	

	assign	gtrx_dat_info_wr		=	dat_lst		&&	fifo_rdy											;
	assign	gtrx_dat_info_di		=	dat_cnt_q		+	(dat_kpd	?	1'b1:1'b0)						;
	
	assign	gtrx_ksc_fifo_wr		=	ksc_vld		&&	fifo_rdy											;
	assign	gtrx_ksc_fifo_di		=	{	ksc_msb	,	ksc_lsb	}											;

	localparam	B_IDLE		=	0	;	localparam	S_IDLE		=	2**	B_IDLE			;	//	'h01	//	找到包开始sop后跳转到S_DATA
	localparam	B_DATA		=	1	;	localparam	S_DATA		=	2**	B_DATA			;	//	'h02	//
	localparam	B_SOPDAT	=	2	;	localparam	S_SOPDAT	=	2**	B_SOPDAT		;	//	'h04	//
	localparam	B_ERROR		=	3	;	localparam	S_ERROR		=	2**	B_ERROR			;	//	'h08	//

	reg			[4:0]	CS_GTRX	=	S_IDLE	;

	assign	gtrx_rdy_64		=	(CS_GTRX[B_DATA]&&gtrx_vld_q&&msb_sop&&lsb_dat)	?	1'b0	:	1'b1	;	//	在 {SOP,DAT}时等待一拍，处理情况{SOP,KSC}-{DAT,DAT}-{SOP,DAT}情况

	wire	dbg_sopdat_match	=	CS_GTRX	==	S_SOPDAT	;
	always@(posedge	clk)	sopdat_match_cnt	<=	rst	?	0:	sopdat_match_cnt+dbg_sopdat_match	;
	
	
	/////////	包解析状态机	BEGIN	///////////
	

	always@(posedge	clk)	begin
		if(rst)	begin
			CS_GTRX	<=	S_IDLE		;
		end	else					begin	//	gtrx	数据有效情况下进行解析
			case	(	CS_GTRX	)	
				S_IDLE		:	begin				// 寻找包开始sop																	
					if			(	gtrx_error_or					)	CS_GTRX	<=	S_ERROR					;                  							
					else	
					if			(	gtrx_vld_q&&msb_sop				)	CS_GTRX	<=	S_DATA					;                  							
					else	if	(	gtrx_vld_q&&lsb_sop				)	CS_GTRX	<=	S_DATA					;                  							
					else												CS_GTRX	<=	S_IDLE					;  
				end	
				S_DATA		:	begin				
					if			(	gtrx_error_or					)	CS_GTRX	<=	S_ERROR					;            							
					else	
					if			(	gtrx_vld_q&&msb_sop&&lsb_dat	)	CS_GTRX	<=	S_SOPDAT				;            							
					else	if	(	gtrx_vld_q&&msb_sop				)	CS_GTRX	<=	S_DATA					;            							
					else	if	(	gtrx_vld_q&&msb_kpd&&lsb_sop	)	CS_GTRX	<=	S_DATA					;            							
					else	if	(	gtrx_vld_q&&msb_kpd				)	CS_GTRX	<=	S_IDLE					;            							
					else	if	(	gtrx_vld_q&&lsb_sop				)	CS_GTRX	<=	S_DATA					;            							
					else	if	(	gtrx_vld_q&&lsb_kpd				)	CS_GTRX	<=	S_IDLE					;            							
					else												CS_GTRX	<=	CS_GTRX					;
				end
				S_SOPDAT		:	begin	
					CS_GTRX	<=	S_DATA					;
				end
				S_ERROR			:	begin	
					CS_GTRX	<=	S_IDLE					;
				end
				default			:	begin	
					CS_GTRX	<=	S_IDLE					;
				end
			endcase
		end
	end

	always@(posedge	clk)	begin
	//	if(CS_GTRX[B_DATA]&&msb_sop&&lsb_dat&&gtrx_rv_q)	begin
		if(gtrx_rv_q)	begin
			gtd_h_q_l	<=	gtd_h_q		;
		    gtd_l_q_l	<=	gtd_l_q		;
		end	else	begin
			gtd_h_q_l	<=	gtd_h_q_l	;
			gtd_l_q_l	<=	gtd_l_q_l	;
		end
	end

	always@(posedge	clk)	begin
		if	(	rst	)															dat_ing	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop			)	dat_ing	<=	1			;		
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&lsb_sop			)	dat_ing	<=	1			;		
		else	if	(	CS_GTRX[B_IDLE]										)	dat_ing	<=	0			;		
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_ing	<=	1			;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd&&lsb_sop	)	dat_ing	<=	1			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_ing	<=	0			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_ing	<=	1			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_ing	<=	0			;
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_ing	<=	1			;		
		else	if	(	CS_GTRX[B_ERROR]	)									dat_ing	<=	0			;		
		else																	dat_ing	<=	dat_ing		;		
	end



	always@(posedge	clk)	begin
		if	(	rst	)															dat_vld	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop&&lsb_dat	)	dat_vld	<=	1			;		
		else	if	(	CS_GTRX[B_IDLE]										)	dat_vld	<=	0			;		
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_vld	<=	dat_cnt[0]	?	1		:	0		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_dat	)	dat_vld	<=	1									;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_sop	)	dat_vld	<=	1									;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_kpd	)	dat_vld	<=	1									;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat			)	dat_vld	<=	dat_cnt[0]	?	1		:	0		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_vld	<=	dat_cnt[0]	?	1		:	0		;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_vld	<=	dat_cnt[0]	?	1		:	0		;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_dat			)	dat_vld	<=	dat_cnt[0]	?	1		:	0		;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_vld	<=	dat_cnt[0]	?	1		:	0		;
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_vld	<=	1			;		
		else																	dat_vld	<=	0			;		
	end

	always@(posedge	clk)	begin
		if	(	rst	)															dat_lst	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]										)	dat_lst	<=	0			;		
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_lst	<=	1			;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_lst	<=	1			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_lst	<=	1			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_lst	<=	1			;
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_lst	<=	0			;		
		else	if	(	CS_GTRX[B_ERROR]	)									dat_lst	<=	0			;		
		else																	dat_lst	<=	0			;		
	end
	
	always@(posedge	clk)	begin
		if	(	rst	)															dat_cnt	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop&&lsb_dat	)	dat_cnt	<=	2			;		
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop			)	dat_cnt	<=	1			;		
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&lsb_sop			)	dat_cnt	<=	1			;		
		else	if	(	CS_GTRX[B_IDLE]										)	dat_cnt	<=	0			;		
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop&&lsb_dat	)	dat_cnt	<=	2			;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_cnt	<=	1			;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_sop	)	dat_cnt	<=	1			;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_dat	)	dat_cnt	<=	dat_cnt+2	;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_kpd	)	dat_cnt	<=	0			;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat			)	dat_cnt	<=	dat_cnt+1	;				
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd&&lsb_sop	)	dat_cnt	<=	1			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_cnt	<=	0			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_cnt	<=	1			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_dat			)	dat_cnt	<=	dat_cnt+1	;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_cnt	<=	0			;
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_cnt	<=	2			;		
		else	if	(	CS_GTRX[B_ERROR]	)									dat_cnt	<=	0			;		
		else																	dat_cnt	<=	dat_cnt		;		
	end

	always@(posedge	clk)	begin
		if	(	rst	)															dat_msb	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop&&lsb_dat	)	dat_msb	<=	gtd_h_q		;
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_msb	<=	dat_cnt[0]	?	dat_rem	:	gtd_h_q	;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat			)	dat_msb	<=	dat_cnt[0]	?	dat_rem	:	gtd_h_q	;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_msb	<=	dat_rem								;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_msb	<=	dat_cnt[0]	?	dat_rem	:	gtd_h_q	;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_dat			)	dat_msb	<=	dat_cnt[0]	?	dat_rem	:	gtd_l_q	;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_msb	<=	dat_cnt[0]	?	dat_rem	:	gtd_h_q	;
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_msb	<=	gtd_h_q_l	;		
		else																	dat_msb	<=	dat_msb		;		
	end
	
	always@(posedge	clk)	begin
		if	(	rst	)															dat_lsb	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop&&lsb_dat	)	dat_lsb	<=	gtd_l_q		;		
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_lsb	<=	gtd_l_q		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat			)	dat_lsb	<=	dat_cnt[0]	?	gtd_h_q	:	gtd_l_q	;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_lsb	<=	dat_lsb		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_lsb	<=	gtd_h_q		;			
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_dat			)	dat_lsb	<=	dat_cnt[0]	?	gtd_h_q	:	gtd_l_q	;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_lsb	<=	gtd_h_q		;		
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_lsb	<=	gtd_l_q_l	;		
		else																	dat_lsb	<=	dat_lsb		;		
	end
	
	always@(posedge	clk)	begin
		if	(	rst	)															dat_rem	<=	0			;
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&msb_sop			)	dat_rem	<=	gtd_h_q		;		
		else	if	(	CS_GTRX[B_IDLE]	&&	gtrx_vld_q	&&lsb_sop			)	dat_rem	<=	gtd_l_q		;		
		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_sop			)	dat_rem	<=	gtd_h_q		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_sop	)	dat_rem	<=	gtd_l_q		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat			)	dat_rem	<=	dat_cnt[0]	?	gtd_l_q	:	gtd_h_q	;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_kpd			)	dat_rem	<=	gtd_l_q		;		
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_sop			)	dat_rem	<=	gtd_l_q		;			
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_dat			)	dat_rem	<=	gtd_l_q		;
	//	else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&lsb_kpd			)	dat_rem	<=	dat_rem		;		
		
		else	if	(	CS_GTRX[B_SOPDAT]	)									dat_rem	<=	gtd_l_q_l	;		
		else																	dat_rem	<=	dat_rem		;		
	end
			

	
	always@(posedge	clk)	begin
		if	(	rst	)															dat_kpd	<=	0			;
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_sop	)	dat_kpd	<=	1			;			
		else	if	(	CS_GTRX[B_DATA]	&&	gtrx_vld_q	&&msb_dat&&lsb_kpd	)	dat_kpd	<=	1			;			
		else																	dat_kpd	<=	0			;		
	end
	
	
	
	
	always@(posedge	clk)	begin
		if	(	rst	)		begin
			ksc_vld	<=	0			;
			ksc_msb	<=	0			;
			ksc_lsb	<=	0			;
		end	else	if	(	idle2_detected	&&	gtrx_vld_q	&&	msb_ksc	&&	lsb_ksc	)	begin		
			ksc_vld	<=	1			;
			ksc_msb	<=	gtd_h_q		;
			ksc_lsb	<=	gtd_l_q		;
		end	else	if	(	idle2_detected	&&	gtrx_vld_q	&&	msb_ksc	&&	~lsb_ksc)	begin
			ksc_vld	<=	1			;
			ksc_msb	<=	gtd_l_q_l	;
			ksc_lsb	<=	gtd_h_q		;
		end	else	if	(	!idle2_detected	&&	gtrx_vld_q	&&msb_ksc&&lsb_ksc	)	begin		
			ksc_vld	<=	1			;
			ksc_msb	<=	gtd_h_q		;
			ksc_lsb	<=	gtd_l_q		;
		end	else	if	(	!idle2_detected	&&	gtrx_vld_q	&&msb_ksc			)	begin
			ksc_vld	<=	1			;
			ksc_msb	<=	gtd_h_q		;
			ksc_lsb	<=	0			;
		end	else	if	(	!idle2_detected	&&	gtrx_vld_q	&&lsb_ksc			)	begin
			ksc_vld	<=	1			;
			ksc_msb	<=	gtd_l_q		;
			ksc_lsb	<=	0			;
		end	else												begin
			ksc_vld	<=	0			;
			ksc_msb	<=	ksc_msb		;
			ksc_lsb	<=	ksc_lsb		;
		end
	end


//	//	msb_sop	&&	lsb_sop		//	Illegal	
//		msb_sop	&&	lsb_epd		
//	//	msb_sop	&&	lsb_ksc		//	Illegal	
//	//	msb_sop	&&	lsb_dat		//	Illegal	
//	//	msb_sop	&&	lsb_kpd		//	Illegal	
//	//	msb_sop	&&	lsb_esc		//	Illegal	
//	//	msb_sop	&&	lsb_rsv		//	Illegal	
//
//	//	msb_esp	&&	lsb_sop		
//	//	msb_esp	&&	lsb_epd		//	Illegal	
//		msb_esp	&&	lsb_ksc		
//		msb_esp	&&	lsb_dat		
//	//	msb_esp	&&	lsb_kpd		//	Illegal	
//	//	msb_esp	&&	lsb_esc		//	Illegal	
//	//	msb_esp	&&	lsb_rsv		//	Illegal	
//
//	//	msb_ksc	&&	lsb_sop		//	Illegal	
//	//	msb_ksc	&&	lsb_epd		//	Illegal	
//	//	msb_ksc	&&	lsb_ksc		//	Illegal	
//	//	msb_ksc	&&	lsb_dat		//	Illegal	
//	//	msb_ksc	&&	lsb_kpd		//	Illegal			
//		msb_ksc	&&	lsb_esc		
//	//	msb_ksc	&&	lsb_rsv		//	Illegal		
//
//		msb_dat	&&	lsb_sop			
//	//	msb_dat	&&	lsb_epd		//	Illegal		
//		msb_dat	&&	lsb_ksc			
//		msb_dat	&&	lsb_dat			
//		msb_dat	&&	lsb_kpd					
//	//	msb_dat	&&	lsb_esc		//	Illegal		
//	//	msb_dat	&&	lsb_rsv		//	Illegal		
//
//	//	msb_kpd	&&	lsb_sop		//	Illegal		
//		msb_kpd	&&	lsb_epd		
//	//	msb_kpd	&&	lsb_ksc		//	Illegal		
//	//	msb_kpd	&&	lsb_dat		//	Illegal		
//	//	msb_kpd	&&	lsb_kpd		//	Illegal				
//	//	msb_kpd	&&	lsb_esc		//	Illegal		
//	//	msb_kpd	&&	lsb_rsv		//	Illegal		
//
//		msb_epd	&&	lsb_sop		
//	//	msb_epd	&&	lsb_epd		//	Illegal	
//		msb_epd	&&	lsb_ksc		
//		msb_epd	&&	lsb_dat		
//	//	msb_epd	&&	lsb_kpd		//	Illegal	
//	//	msb_epd	&&	lsb_esc		//	Illegal	
//		msb_epd	&&	lsb_rsv		
//
//		msb_esc	&&	lsb_sop		
//	//	msb_esc	&&	lsb_epd		//	Illegal		
//		msb_esc	&&	lsb_ksc		
//		msb_esc	&&	lsb_dat		
//		msb_esc	&&	lsb_kpd		
//	//	msb_esc	&&	lsb_esc		//	Illegal		
//		msb_esc	&&	lsb_rsv		









	
	/////////	包解析状态机	END	///////////
//	`ifdef	DBG_ILA		
//			ila_288X1024 ila_288X1024_parse (
//				.	clk		(	clk	)	,	// input wire clk
//				.	probe0	(	
//								{
//	
//									gtrx_dat_info_wr			,
//									gtrx_dat_info_di			,
//									gtrx_dat_fifo_wr			,
//									gtrx_dat_fifo_di			,
//	
//									gtrx_rdy_64		,
//									gtrx_vld_64		,
//									gtrx_rv_q		,
//									gtd_h_q		 	,
//									gtk_h_q		 	,
//									gtd_l_q		 	,
//									gtk_l_q		 	,
//	
//									CS_GTRX			,
//									msb_sop			,	
//									msb_kpd			,	
//									msb_ksc			,
//									msb_kbc			,
//									msb_dat			,
//									lsb_sop			,
//									lsb_kpd			,
//									lsb_ksc			,
//									lsb_kbc			,
//									lsb_dat			,
//									
//									dat_ing			,
//									dat_vld			,
//									dat_lst			,
//									dat_cnt			,
//									dat_msb			,
//									dat_lsb			,
//									dat_rem			,
//									dat_kpd			
//									
//								}	
//							)		// input wire [31:0] probe0
//			);
//	`endif
endmodule