
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2021年11月30日20:25:08
//	Design	Name		:	
//	Module	Name		:	
//	Project	Name		:	
//	Target	Devices		:	all	Xilinx device
//	Tool	versions	:	all
//	Description			:	
//	Editor				:	Npp,	tab	size	(4)
//	Dependencies		:	
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	移除非控制包和数据包的字符
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description							:
//	
//	Additional	Comments:	
//
//////////////////////////////////////////////////////////////////////////////////

//	`timescale	1ns/1ps

module	gtrx_rm_idle	#(
	parameter		LINK_WIDTH		=	1		//	SRIO GT LANE WIDTH					
)(
	input	wire								gt_pcs_rst					,
	input	wire								gt_pcs_clk					,
	
	input	wire								idle2_detected				,	
	
	input	wire	[	LINK_WIDTH*4*8	-1:0]	gtrx_data					,	
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_charisk				,
	input	wire	[	LINK_WIDTH*4	-1:0]	gtrx_chariscomma			,
	
	output	reg		[	32				-1:0]	gtx_gtrx_sop_cnt			,
	output	reg		[	32				-1:0]	rmv_gtrx_sop_cnt			,
	output	reg		[	32				-1:0]	rmv_byte_sop_cnt			,
	output	reg		[	32				-1:0]	rmv_fifo_afu_cnt			,
	input	wire								gtrx_cvt_buf_naf			,
	output	wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_cvt_spd_vlu			,	
	output	wire								gtrx_cvt_spd_vld				
);	
	
	localparam	LW	=	LINK_WIDTH	;
	localparam	LB	=	4			;
	
	wire	rst	;
	wire	clk	;
	
	assign	clk	=	gt_pcs_clk	;
	assign	rst	=	gt_pcs_rst	;
	
	reg		[3:0]						gtrx_vld_msk	=	0		;	//	当前收到有效的字符掩码
	reg									r_gtrx_spd_vld	=	0		;
	reg		[	2				-1:0]	r_gtrx_spd_num	=	0		;	//	已经收到有效的字符计数
	reg		[	LINK_WIDTH*36	-1:0]	r_gtrx_spd_vlu	=	{{LINK_WIDTH*4}{9'h1BC}}		;
	reg		[	LINK_WIDTH*36	-1:0]	r_gtrx_spd_rem	=	{{LINK_WIDTH*4}{9'h1BC}}		;

	reg		gtrx_cvt_buf_rdy	=	1	;
	always@(posedge	clk)	begin
		if			(	rst					)	gtrx_cvt_buf_rdy	<=	1					;
		else	if	(	~	r_gtrx_spd_vld	)	gtrx_cvt_buf_rdy	<=	gtrx_cvt_buf_naf	;
		else									gtrx_cvt_buf_rdy	<=	gtrx_cvt_buf_rdy	;
	end
	
	reg		gtrx_cvt_buf_rdy_q	=	1	;	always@(posedge	clk)	gtrx_cvt_buf_rdy_q	<=	gtrx_cvt_buf_rdy	;
	always@(posedge	clk)	begin
		if				(	rst	)	begin
			rmv_fifo_afu_cnt	<=	0	;
		end	else	if	(	gtrx_cvt_buf_rdy	==	0	&&
							gtrx_cvt_buf_rdy_q	==	1		)begin
			rmv_fifo_afu_cnt	<=	rmv_fifo_afu_cnt+1	;
		end	else	begin
			rmv_fifo_afu_cnt	<=	rmv_fifo_afu_cnt	;
		end
	end
	
	assign	gtrx_cvt_spd_vld		=	r_gtrx_spd_vld		&&	gtrx_cvt_buf_rdy		;
	
	wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_mid_spd_vlu			;

genvar i,j;

//	字节序转换
//	data_4lane=	{	data_lane3[31:0],data_lane2[31:0],data_lane1[31:0],data_lane0[31:0]			}
//	转换为		{
//					data_lane0[3*8+:8],data_lane1[3*8+:8],data_lane2[3*8+:8],data_lane3[3*8+:8]	,
//					data_lane0[2*8+:8],data_lane1[2*8+:8],data_lane2[2*8+:8],data_lane3[2*8+:8]	,
//					data_lane0[1*8+:8],data_lane1[1*8+:8],data_lane2[1*8+:8],data_lane3[1*8+:8]	,
//					data_lane0[0*8+:8],data_lane1[0*8+:8],data_lane2[0*8+:8],data_lane3[0*8+:8]	
//				}

	generate	for ( i=0; i<LINK_WIDTH*4; i=i+1 ) begin
		assign	gtrx_mid_spd_vlu	[(i%LB*LW+i/LB)*9+:9]		=	r_gtrx_spd_vlu	[i*9+:9]	;
	end	endgenerate
	
	generate	for ( i=0; i<LB; i=i+1 ) begin
		for ( j=0; j<LW; j=j+1 ) begin
		assign	gtrx_cvt_spd_vlu	[i*LW*9+j*9+:9]		=	gtrx_mid_spd_vlu	[i*LW*9+(LW-1-j)*9+:9]	;
	end	end	endgenerate	


	wire	[	LINK_WIDTH*4*8	-1:0]	gtrx_cnvt_dat	;
	wire	[	LINK_WIDTH*4*1	-1:0]	gtrx_cnvt_isk	;
	
	generate	for ( i=0; i<LINK_WIDTH*4; i=i+1 ) begin
		assign	gtrx_cnvt_dat	[i*8+:8]	=	gtrx_cvt_spd_vlu		[i*9+0+:8]	;
		assign	gtrx_cnvt_isk	[i*1+:1]	=	gtrx_cvt_spd_vlu		[i*9+8+:1]	;
	end	endgenerate

	////////////	去掉空闲字符开始	////////
	
	reg		[	LINK_WIDTH*4*9	-1:0]	gtrx_char_q	=0	;
	
generate for(i=0;i<LINK_WIDTH*4;i=i+1)begin 
	always@(posedge	clk)	gtrx_char_q[i*9+:9]	<=	{	gtrx_charisk[i]	,	gtrx_data[i*8+:8]	}	;
end
endgenerate

//	仅需要判断	LANE0 的控制符
generate for(i=0;i<4;i=i+1)begin 	
		
	always@(posedge	clk)	begin
		if(rst)	gtrx_vld_msk[i]	<=	0	;
		else	if	(	gtrx_charisk[i]==1	&&	gtrx_data[i*8+:8]	==8'h1C		)	gtrx_vld_msk[i]	<=	1	;
		else	if	(	gtrx_charisk[i]==1	&&	gtrx_data[i*8+:8]	==8'h7C		)	gtrx_vld_msk[i]	<=	1	;
		else	if	(	gtrx_charisk[i]==0										)	gtrx_vld_msk[i]	<=	1	;
		else																		gtrx_vld_msk[i]	<=	0	;
	end
end
endgenerate
	
//	always@(*)	begin
	always@(posedge	clk)	begin
		if(	rst)	r_gtrx_spd_num	<=	0	;
//		else	if	(	~	all_gtrx_chanisaligned	)	r_gtrx_spd_num	<=	0	;
		else
			case	(gtrx_vld_msk)	
				4'b0000	:	r_gtrx_spd_num	<=	0	;	
				
				4'b0001	,
				4'b0010	,
				4'b0100	,
				4'b1000	:	r_gtrx_spd_num	<=	r_gtrx_spd_num	+	1	;	
				4'b0011	,
				4'b0101	,
				4'b0110	,
				4'b1001	,
				4'b1010	,
				4'b1100	:	r_gtrx_spd_num	<=	r_gtrx_spd_num	+	2	;	
				
				4'b0111	,
				4'b1011	,
				4'b1101	,
				4'b1110	:	r_gtrx_spd_num	<=	r_gtrx_spd_num	+	3	;
				
				4'b1111	:	r_gtrx_spd_num	<=	r_gtrx_spd_num	+	4	;
			endcase
	end

	always@(posedge	clk)	begin
		if(	rst)	r_gtrx_spd_vld	<=	0	;
		else	
			case	(gtrx_vld_msk)	
				4'b0000	:	r_gtrx_spd_vld	<=	r_gtrx_spd_num!=0	;	
				4'b0001	,
				4'b0010	,
				4'b0100	,
				4'b1000	:	r_gtrx_spd_vld	<=	r_gtrx_spd_num>2	;	
				
				4'b0011	,
				4'b0101	,
				4'b0110	,
				4'b1001	,
				4'b1010	,
				4'b1100	:	r_gtrx_spd_vld	<=	r_gtrx_spd_num>1	;	
				
				4'b0111	,
				4'b1011	,
				4'b1101	,
				4'b1110	:	r_gtrx_spd_vld	<=	r_gtrx_spd_num>0	;
				
				4'b1111	:	r_gtrx_spd_vld	<=	1					;
			endcase
	end


generate for(i=0;i<LINK_WIDTH;i=i+1)begin 
//	always@(posedge	clk)	begin
//		if(	rst)	begin
//			r_gtrx_spd_vlu	[i*36+:4*9]	<=	{{4}{9'h1BC}}		;
//			r_gtrx_spd_rem	[i*36+:4*9]	<=	{{4}{9'h1BC}}		;
//		end	else	begin
//			r_gtrx_spd_vlu	[i*36+:4*9]	<=	w_gtrx_spd_vlu[i*36+:4*9]		;
//			r_gtrx_spd_rem	[i*36+:4*9]	<=	w_gtrx_spd_rem[i*36+:4*9]		;
//		end	
//	end

	always@(posedge	clk)	begin
		if(rst)	begin
			r_gtrx_spd_vlu		[i*36+:36]	<=	{{4}{9'h1BC}}		;
			r_gtrx_spd_rem		[i*36+:36]	<=	{{4}{9'h1BC}}		;
		end	else	begin
			case	(gtrx_vld_msk[3:0])	
				4'b0000	:	begin	
					if				(r_gtrx_spd_num==0)	begin
						r_gtrx_spd_vlu	[i*36+:36]		<=	{{4}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+:36]		<=	{{4}{9'h1BC}}					;
					end	else	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	{{1}{9'h1BC}}					;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end	
				4'b0001	:	begin	
					if				(r_gtrx_spd_num==0)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
					
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
					
				end
				4'b0010	:	begin	
					if				(r_gtrx_spd_num==0)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b0100	:	begin	
					if				(r_gtrx_spd_num==0)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1000	:	begin	
					if				(r_gtrx_spd_num==0)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b0011	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b0101	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b0110	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1001	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1010	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1100	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b0111	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1011	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1101	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
				4'b1110	:	begin	
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_vlu	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_vlu	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_vlu	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	r_gtrx_spd_vlu	[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end
				end
	
				4'b1111	:	begin
					if				(r_gtrx_spd_num==0)	begin								//	0
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==1)	begin								//	1
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	{{1}{9'h1BC}}					;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else	if	(r_gtrx_spd_num==2)	begin								//	2
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;	
						
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	{{1}{9'h1BC}}					;
					end	else							begin	//	if	(r_gtrx_spd_num==3)	//	3
						r_gtrx_spd_vlu	[i*36+3*9+:9]	<=	r_gtrx_spd_rem	[i*36+3*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+2*9+:9]	<=	r_gtrx_spd_rem	[i*36+2*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+1*9+:9]	<=	r_gtrx_spd_rem	[i*36+1*9+:9]	;	
						r_gtrx_spd_vlu	[i*36+0*9+:9]	<=	gtrx_char_q		[i*36+3*9+:9]	;	
	
						r_gtrx_spd_rem	[i*36+3*9+:9]	<=	gtrx_char_q		[i*36+2*9+:9]	;
						r_gtrx_spd_rem	[i*36+2*9+:9]	<=	gtrx_char_q		[i*36+1*9+:9]	;
						r_gtrx_spd_rem	[i*36+1*9+:9]	<=	gtrx_char_q		[i*36+0*9+:9]	;
					end
				end
		//	no	default	,all case	been mapped
			endcase
		end
	end
end
endgenerate
	////////////	去掉空闲字符	结束	////////
		
		wire	[	LINK_WIDTH*4*8	-1:0]	rmv_gtrx_dat_vlu	;	//	,	ln1_gtrx_dat_vlu	,	ln2_gtrx_dat_vlu	,	ln3_gtrx_dat_vlu	;
		wire	[	LINK_WIDTH*4*1	-1:0]	rmv_gtrx_isk_vlu	;	//	,	ln1_gtrx_isk_vlu	,	ln2_gtrx_isk_vlu	,	ln3_gtrx_isk_vlu	;
		wire	[	LINK_WIDTH*4*8	-1:0]	rmv_gtrx_dat_rem	;	//	,	ln1_gtrx_dat_rem	,	ln2_gtrx_dat_rem	,	ln3_gtrx_dat_rem	;
		wire	[	LINK_WIDTH*4*1	-1:0]	rmv_gtrx_isk_rem	;	//	,	ln1_gtrx_isk_rem	,	ln2_gtrx_isk_rem	,	ln3_gtrx_isk_rem	;
		
		generate	for ( i=0; i<LINK_WIDTH*4; i=i+1 ) begin
			assign	rmv_gtrx_dat_vlu	[i*8+:8]	=	r_gtrx_spd_vlu		[i*9+0+:8]	;
			assign	rmv_gtrx_isk_vlu	[i*1+:1]	=	r_gtrx_spd_vlu		[i*9+8+:1]	;
			assign	rmv_gtrx_dat_rem	[i*8+:8]	=	r_gtrx_spd_rem		[i*9+0+:8]	;
			assign	rmv_gtrx_isk_rem	[i*1+:1]	=	r_gtrx_spd_rem		[i*9+8+:1]	;
		end	endgenerate
		
		reg		[3:0]	gtx_sop_byte	=	0	;	
		reg		[3:0]	rmv_sop_byte	=	0	;	
		
		always@(posedge	clk)	gtx_gtrx_sop_cnt	<=	rst	?	0	:	gtx_gtrx_sop_cnt	+	gtx_sop_byte[0]+gtx_sop_byte[1]+gtx_sop_byte[2]+gtx_sop_byte[3];
		
		
generate	if(LINK_WIDTH==4)	begin
		wire	[	4*8	-1:0]	ln0_gtrx_data			,	ln1_gtrx_data			,	ln2_gtrx_data			,	ln3_gtrx_data					;	
		wire	[	4	-1:0]	ln0_gtrx_charisk		,	ln1_gtrx_charisk		,	ln2_gtrx_charisk		,	ln3_gtrx_charisk				;
		wire	[	4	-1:0]	ln0_gtrx_chariscomma	,	ln1_gtrx_chariscomma	,	ln2_gtrx_chariscomma	,	ln3_gtrx_chariscomma			;

		assign	ln0_gtrx_data			=	gtrx_data			[0*32+:32]	;	
		assign	ln0_gtrx_charisk		=	gtrx_charisk		[0*04+:04]	;	
		assign	ln0_gtrx_chariscomma	=	gtrx_chariscomma	[0*04+:04]	;	

		assign	ln1_gtrx_data			=	gtrx_data			[1*32+:32]	;
		assign	ln1_gtrx_charisk		=	gtrx_charisk		[1*04+:04]	;
		assign	ln1_gtrx_chariscomma	=	gtrx_chariscomma	[1*04+:04]	;
                                                                            
		assign	ln2_gtrx_data			=	gtrx_data			[2*32+:32]	;
		assign	ln2_gtrx_charisk		=	gtrx_charisk		[2*04+:04]	;
		assign	ln2_gtrx_chariscomma	=	gtrx_chariscomma	[2*04+:04]	;
		                                                                    
		assign	ln3_gtrx_data			=	gtrx_data			[3*32+:32]	;
		assign	ln3_gtrx_charisk		=	gtrx_charisk		[3*04+:04]	;
		assign	ln3_gtrx_chariscomma	=	gtrx_chariscomma	[3*04+:04]	;
		
		//	[05+:06]	--	idle1
		//	[03+:06]	--	idle2

		always@(posedge	clk)	gtx_sop_byte[3]	<=	ln0_gtrx_charisk[3]	&&	ln0_gtrx_data[3*08+:08]	==	8'h7C	&&	((~idle2_detected?{ln2_gtrx_data[3*8+0+:3],ln3_gtrx_data[3*8+5+:3]}:{ln2_gtrx_data[3*8+0+:1],ln3_gtrx_data[3*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	gtx_sop_byte[2]	<=	ln0_gtrx_charisk[2]	&&	ln0_gtrx_data[2*08+:08]	==	8'h7C	&&	((~idle2_detected?{ln2_gtrx_data[2*8+0+:3],ln3_gtrx_data[2*8+5+:3]}:{ln2_gtrx_data[2*8+0+:1],ln3_gtrx_data[2*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	gtx_sop_byte[1]	<=	ln0_gtrx_charisk[1]	&&	ln0_gtrx_data[1*08+:08]	==	8'h7C	&&	((~idle2_detected?{ln2_gtrx_data[1*8+0+:3],ln3_gtrx_data[1*8+5+:3]}:{ln2_gtrx_data[1*8+0+:1],ln3_gtrx_data[1*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	gtx_sop_byte[0]	<=	ln0_gtrx_charisk[0]	&&	ln0_gtrx_data[0*08+:08]	==	8'h7C	&&	((~idle2_detected?{ln2_gtrx_data[0*8+0+:3],ln3_gtrx_data[0*8+5+:3]}:{ln2_gtrx_data[0*8+0+:1],ln3_gtrx_data[0*8+3+:5]})	==	{3'b000,3'b000})	;
	

		wire	[	4*8	-1:0]	ln0_gtrx_dat_rem		,	ln1_gtrx_dat_rem		,	ln2_gtrx_dat_rem		,	ln3_gtrx_dat_rem		;	
		wire	[	4	-1:0]	ln0_gtrx_isk_rem		,	ln1_gtrx_isk_rem		,	ln2_gtrx_isk_rem		,	ln3_gtrx_isk_rem		;

		wire	[	4*8	-1:0]	ln0_gtrx_dat_vlu		,	ln1_gtrx_dat_vlu		,	ln2_gtrx_dat_vlu		,	ln3_gtrx_dat_vlu		;	
		wire	[	4	-1:0]	ln0_gtrx_isk_vlu		,	ln1_gtrx_isk_vlu		,	ln2_gtrx_isk_vlu		,	ln3_gtrx_isk_vlu		;

		assign	ln0_gtrx_dat_vlu	=	rmv_gtrx_dat_vlu	[0*32+:32]	;	
		assign	ln0_gtrx_isk_vlu	=	rmv_gtrx_isk_vlu	[0*04+:04]	;   	

		assign	ln1_gtrx_dat_vlu	=	rmv_gtrx_dat_vlu	[1*32+:32]	;	
		assign	ln1_gtrx_isk_vlu	=	rmv_gtrx_isk_vlu	[1*04+:04]	;   

		assign	ln2_gtrx_dat_vlu	=	rmv_gtrx_dat_vlu	[2*32+:32]	;
		assign	ln2_gtrx_isk_vlu	=	rmv_gtrx_isk_vlu	[2*04+:04]	;

		assign	ln3_gtrx_dat_vlu	=	rmv_gtrx_dat_vlu	[3*32+:32]	;
		assign	ln3_gtrx_isk_vlu	=	rmv_gtrx_isk_vlu	[3*04+:04]	;

		assign	ln0_gtrx_dat_rem	=	rmv_gtrx_dat_rem	[0*32+:32]	;	
		assign	ln0_gtrx_isk_rem	=	rmv_gtrx_isk_rem	[0*04+:04]	;   	

		assign	ln1_gtrx_dat_rem	=	rmv_gtrx_dat_rem	[1*32+:32]	;	
		assign	ln1_gtrx_isk_rem	=	rmv_gtrx_isk_rem	[1*04+:04]	;   

		assign	ln2_gtrx_dat_rem	=	rmv_gtrx_dat_rem	[2*32+:32]	;
		assign	ln2_gtrx_isk_rem	=	rmv_gtrx_isk_rem	[2*04+:04]	;

		assign	ln3_gtrx_dat_rem	=	rmv_gtrx_dat_rem	[3*32+:32]	;
		assign	ln3_gtrx_isk_rem	=	rmv_gtrx_isk_rem	[3*04+:04]	;

		always@(posedge	clk)	rmv_sop_byte[3]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu[3]	&&	rmv_gtrx_dat_vlu[3*08+:08]	==	8'h7C	&&	((~idle2_detected?{rmv_gtrx_dat_vlu[(LW-2)*32+3*8+0+:3],rmv_gtrx_dat_vlu[(LW-1)*32+3*8+5+:3]}:{rmv_gtrx_dat_vlu[(LW-2)*32+3*8+0+:1],rmv_gtrx_dat_vlu[(LW-1)*32+3*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	rmv_sop_byte[2]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu[2]	&&	rmv_gtrx_dat_vlu[2*08+:08]	==	8'h7C	&&	((~idle2_detected?{rmv_gtrx_dat_vlu[(LW-2)*32+2*8+0+:3],rmv_gtrx_dat_vlu[(LW-1)*32+2*8+5+:3]}:{rmv_gtrx_dat_vlu[(LW-2)*32+2*8+0+:1],rmv_gtrx_dat_vlu[(LW-1)*32+2*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	rmv_sop_byte[1]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu[1]	&&	rmv_gtrx_dat_vlu[1*08+:08]	==	8'h7C	&&	((~idle2_detected?{rmv_gtrx_dat_vlu[(LW-2)*32+1*8+0+:3],rmv_gtrx_dat_vlu[(LW-1)*32+1*8+5+:3]}:{rmv_gtrx_dat_vlu[(LW-2)*32+1*8+0+:1],rmv_gtrx_dat_vlu[(LW-1)*32+1*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	rmv_sop_byte[0]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu[0]	&&	rmv_gtrx_dat_vlu[0*08+:08]	==	8'h7C	&&	((~idle2_detected?{rmv_gtrx_dat_vlu[(LW-2)*32+0*8+0+:3],rmv_gtrx_dat_vlu[(LW-1)*32+0*8+5+:3]}:{rmv_gtrx_dat_vlu[(LW-2)*32+0*8+0+:1],rmv_gtrx_dat_vlu[(LW-1)*32+0*8+3+:5]})	==	{3'b000,3'b000})	;
	
		always@(posedge	clk)	rmv_gtrx_sop_cnt	<=	rst	?	0	:	rmv_gtrx_sop_cnt	+	rmv_sop_byte[0]+rmv_sop_byte[1]+rmv_sop_byte[2]+rmv_sop_byte[3];
		always@(posedge	clk)	rmv_byte_sop_cnt	<=	rst	?	0	:	rmv_byte_sop_cnt	+	rmv_sop_byte[0]+rmv_sop_byte[1]+rmv_sop_byte[2]+rmv_sop_byte[3];
	
	end	else	if(LINK_WIDTH==2)	begin

		wire	[	4*8	-1:0]	ln0_gtrx_data			,	ln1_gtrx_data				;	
		wire	[	4	-1:0]	ln0_gtrx_charisk		,	ln1_gtrx_charisk			;
		
		reg		[	4*8	-1:0]	rg0_gtrx_data			,	rg1_gtrx_data				;
		reg		[	4	-1:0]	rg0_gtrx_charisk		,	rg1_gtrx_charisk			;
		

		assign	ln0_gtrx_data			=	gtrx_data			[0*32+:32]	;	
		assign	ln0_gtrx_charisk		=	gtrx_charisk		[0*04+:04]	;	

		assign	ln1_gtrx_data			=	gtrx_data			[1*32+:32]	;
		assign	ln1_gtrx_charisk		=	gtrx_charisk		[1*04+:04]	;
                                                                            
		always@(posedge	clk)	rg0_gtrx_data			<=	gtrx_data			[0*32+:32]	;
		always@(posedge	clk)	rg0_gtrx_charisk		<=	gtrx_charisk		[0*04+:04]	;
		                                                                    
		always@(posedge	clk)	rg1_gtrx_data			<=	gtrx_data			[1*32+:32]	;
		always@(posedge	clk)	rg1_gtrx_charisk		<=	gtrx_charisk		[1*04+:04]	;
		

		always@(posedge	clk)	gtx_sop_byte[3]	<=	rg0_gtrx_charisk[3]	&&	rg0_gtrx_data[3*08+:08]	==	8'h7C	&&	((~idle2_detected?{rg0_gtrx_data[2*8+0+:3],rg1_gtrx_data[2*8+5+:3]}	:{rg0_gtrx_data[2*8+0+:1],rg1_gtrx_data[2*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	gtx_sop_byte[2]	<=	rg0_gtrx_charisk[2]	&&	rg0_gtrx_data[2*08+:08]	==	8'h7C	&&	((~idle2_detected?{rg0_gtrx_data[1*8+0+:3],rg1_gtrx_data[1*8+5+:3]}	:{rg0_gtrx_data[1*8+0+:1],rg1_gtrx_data[1*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	gtx_sop_byte[1]	<=	rg0_gtrx_charisk[1]	&&	rg0_gtrx_data[1*08+:08]	==	8'h7C	&&	((~idle2_detected?{rg0_gtrx_data[0*8+0+:3],rg1_gtrx_data[0*8+5+:3]}	:{rg0_gtrx_data[0*8+0+:1],rg1_gtrx_data[0*8+3+:5]})	==	{3'b000,3'b000})	;
		always@(posedge	clk)	gtx_sop_byte[0]	<=	rg0_gtrx_charisk[0]	&&	rg0_gtrx_data[0*08+:08]	==	8'h7C	&&	((~idle2_detected?{ln0_gtrx_data[3*8+0+:3],ln1_gtrx_data[3*8+5+:3]}	:{ln0_gtrx_data[3*8+0+:1],ln1_gtrx_data[3*8+3+:5]})	==	{3'b000,3'b000})	;
		
		
		wire	[	4*8	-1:0]	ln0_gtrx_dat_vlu		,	ln1_gtrx_dat_vlu		;		
		wire	[	4	-1:0]	ln0_gtrx_isk_vlu		,	ln1_gtrx_isk_vlu		;	

		wire	[	4*8	-1:0]	ln0_gtrx_dat_rem		,	ln1_gtrx_dat_rem		;		
		wire	[	4	-1:0]	ln0_gtrx_isk_rem		,	ln1_gtrx_isk_rem		;	

		reg		[	4*8	-1:0]	rg0_gtrx_dat_vlu		,	rg1_gtrx_dat_vlu	=	{4{8'hBC}}	;
		reg		[	4	-1:0]	rg0_gtrx_isk_vlu		,	rg1_gtrx_isk_vlu	=	{4{1'h01}}	;

		assign	ln0_gtrx_dat_vlu		=	rmv_gtrx_dat_vlu		[0*32+:32]	;	
		assign	ln0_gtrx_isk_vlu		=	rmv_gtrx_isk_vlu		[0*04+:04]	;	

		assign	ln1_gtrx_dat_vlu		=	rmv_gtrx_dat_vlu		[1*32+:32]	;
		assign	ln1_gtrx_isk_vlu		=	rmv_gtrx_isk_vlu		[1*04+:04]	;

		assign	ln0_gtrx_dat_rem	=	rmv_gtrx_dat_rem	[0*32+:32]	;	
		assign	ln0_gtrx_isk_rem	=	rmv_gtrx_isk_rem	[0*04+:04]	;   	

		assign	ln1_gtrx_dat_rem	=	rmv_gtrx_dat_rem	[1*32+:32]	;	
		assign	ln1_gtrx_isk_rem	=	rmv_gtrx_isk_rem	[1*04+:04]	;   

		always@(posedge	clk)	rg0_gtrx_dat_vlu		<=	r_gtrx_spd_vld	?	rmv_gtrx_dat_vlu		[0*32+:32]	:	rg0_gtrx_dat_vlu	;
		always@(posedge	clk)	rg0_gtrx_isk_vlu		<=	r_gtrx_spd_vld	?	rmv_gtrx_isk_vlu		[0*04+:04]	:	rg0_gtrx_isk_vlu	;
		                                                                    
		always@(posedge	clk)	rg1_gtrx_dat_vlu		<=	r_gtrx_spd_vld	?	rmv_gtrx_dat_vlu		[1*32+:32]	:	rg1_gtrx_dat_vlu	;
		always@(posedge	clk)	rg1_gtrx_isk_vlu		<=	r_gtrx_spd_vld	?	rmv_gtrx_isk_vlu		[1*04+:04]	:	rg1_gtrx_isk_vlu	;
		
		always@(posedge	clk)	rmv_sop_byte[3]	<=	r_gtrx_spd_vld	&&	rg0_gtrx_isk_vlu[3]	&&	rg0_gtrx_dat_vlu[3*08+:08]	==	8'h7C	&&	((~idle2_detected?{rg0_gtrx_dat_vlu[2*8+0+:3],rg1_gtrx_dat_vlu[2*8+5+:3]}	:{rg0_gtrx_dat_vlu[2*8+0+:1],rg1_gtrx_dat_vlu[2*8+3+:5]}	)==	{3'b000,3'b000}	);		
		always@(posedge	clk)	rmv_sop_byte[2]	<=	r_gtrx_spd_vld	&&	rg0_gtrx_isk_vlu[2]	&&	rg0_gtrx_dat_vlu[2*08+:08]	==	8'h7C	&&	((~idle2_detected?{rg0_gtrx_dat_vlu[1*8+0+:3],rg1_gtrx_dat_vlu[1*8+5+:3]}	:{rg0_gtrx_dat_vlu[1*8+0+:1],rg1_gtrx_dat_vlu[1*8+3+:5]}	)==	{3'b000,3'b000}	);		
		always@(posedge	clk)	rmv_sop_byte[1]	<=	r_gtrx_spd_vld	&&	rg0_gtrx_isk_vlu[1]	&&	rg0_gtrx_dat_vlu[1*08+:08]	==	8'h7C	&&	((~idle2_detected?{rg0_gtrx_dat_vlu[0*8+0+:3],rg1_gtrx_dat_vlu[0*8+5+:3]}	:{rg0_gtrx_dat_vlu[0*8+0+:1],rg1_gtrx_dat_vlu[0*8+3+:5]}	)==	{3'b000,3'b000}	);		
		always@(posedge	clk)	rmv_sop_byte[0]	<=	r_gtrx_spd_vld	&&	rg0_gtrx_isk_vlu[0]	&&	rg0_gtrx_dat_vlu[0*08+:08]	==	8'h7C	&&	((~idle2_detected?{ln0_gtrx_dat_vlu[3*8+0+:3],ln1_gtrx_dat_vlu[3*8+5+:3]}	:{ln0_gtrx_dat_vlu[3*8+0+:1],ln1_gtrx_dat_vlu[3*8+3+:5]}	)==	{3'b000,3'b000}	);		

		always@(posedge	clk)	rmv_gtrx_sop_cnt	<=	rst	?	0	:	rmv_gtrx_sop_cnt	+	rmv_sop_byte[1]+rmv_sop_byte[3];
		always@(posedge	clk)	rmv_byte_sop_cnt	<=	rst	?	0	:	rmv_byte_sop_cnt	+	rmv_sop_byte[0]+rmv_sop_byte[1]+rmv_sop_byte[2]+rmv_sop_byte[3];	
		
end	else	if(LINK_WIDTH==1)	begin
		reg		[3:0]	gtx_sop_byte_q	=0	;	always@(posedge	clk)	gtx_sop_byte_q	<=	gtx_sop_byte	;
		
		reg		[31:0]	gtrx_data_q		=0	;	always@(posedge	clk)	gtrx_data_q		<=	gtrx_data		;
		reg		[31:0]	gtrx_data_2		=0	;	always@(posedge	clk)	gtrx_data_2		<=	gtrx_data_q		;
		reg		[03:0]	gtrx_charisk_q	=0	;	always@(posedge	clk)	gtrx_charisk_q	<=	gtrx_charisk	;
		reg		[03:0]	gtrx_charisk_2	=0	;	always@(posedge	clk)	gtrx_charisk_2	<=	gtrx_charisk_q	;
		
		wire	[95:0]	gtrx_data_96	=	{	gtrx_data_2		,	gtrx_data_q		,	gtrx_data		}	;
		wire	[11:0]	gtrx_charisk_96	=	{	gtrx_charisk_2	,	gtrx_charisk_q	,	gtrx_charisk	}	;
		
		always@(posedge	clk)	gtx_sop_byte[3]	<=	gtrx_charisk_96[08+03+:01]	&&	gtrx_data_96[64+03*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_data_96[32+16+03*08+:3]==3'b000	:	{	gtrx_data_96[32+8+8+03*08+:1]	,	gtrx_data_96[32+6+8+03*08+:2]	}==3'b000&&	gtrx_data_96[8+03*08+:8]==8'h7C)		);	//		
		always@(posedge	clk)	gtx_sop_byte[2]	<=	gtrx_charisk_96[08+02+:01]	&&	gtrx_data_96[64+02*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_data_96[32+16+02*08+:3]==3'b000	:	{	gtrx_data_96[32+8+8+02*08+:1]	,	gtrx_data_96[32+6+8+02*08+:2]	}==3'b000&&	gtrx_data_96[8+02*08+:8]==8'h7C)		);	//		
		always@(posedge	clk)	gtx_sop_byte[1]	<=	gtrx_charisk_96[08+01+:01]	&&	gtrx_data_96[64+01*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_data_96[32+16+01*08+:3]==3'b000	:	{	gtrx_data_96[32+8+8+01*08+:1]	,	gtrx_data_96[32+6+8+01*08+:2]	}==3'b000&&	gtrx_data_96[8+01*08+:8]==8'h7C)		);	//		
		always@(posedge	clk)	gtx_sop_byte[0]	<=	gtrx_charisk_96[08+00+:01]	&&	gtrx_data_96[64+00*08+:08]	==	8'h7C	&&	((~idle2_detected?	gtrx_data_96[32+16+00*08+:3]==3'b000	:	{	gtrx_data_96[32+8+8+00*08+:1]	,	gtrx_data_96[32+6+8+00*08+:2]	}==3'b000&&	gtrx_data_96[8+00*08+:8]==8'h7C)		);	//		


		reg	[31:0]	rmv_gtrx_dat_vlu_l	=	{4{8'hBC}}	;	always@(posedge	clk)	rmv_gtrx_dat_vlu_l	<=	r_gtrx_spd_vld	?	rmv_gtrx_dat_vlu	:	rmv_gtrx_dat_vlu_l	;
		reg	[04:0]	rmv_gtrx_isk_vlu_l	=	{4{1'h01}}	;	always@(posedge	clk)	rmv_gtrx_isk_vlu_l	<=	r_gtrx_spd_vld	?	rmv_gtrx_isk_vlu	:	rmv_gtrx_isk_vlu_l	;
		
		wire	[63:0]	rmv_gtrx_dat_vlu_64	=	{	rmv_gtrx_dat_vlu_l		,	rmv_gtrx_dat_vlu	}	;
		wire	[07:0]	rmv_gtrx_isk_vlu_64	=	{	rmv_gtrx_isk_vlu_l		,	rmv_gtrx_isk_vlu	}	;
		
		always@(posedge	clk)	rmv_sop_byte[3]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu_l[3]	&&	rmv_gtrx_dat_vlu_64[32+03*08+:08]	==	8'h7C	&&	((~idle2_detected?	rmv_gtrx_dat_vlu_64[16+03*08+:3]	:	{	rmv_gtrx_dat_vlu_64[8+8+03*08+:1]	,	rmv_gtrx_dat_vlu_64[6+8+03*08+:2]	}	)==	3'b000);
		always@(posedge	clk)	rmv_sop_byte[2]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu_l[2]	&&	rmv_gtrx_dat_vlu_64[32+02*08+:08]	==	8'h7C	&&	((~idle2_detected?	rmv_gtrx_dat_vlu_64[16+02*08+:3]	:	{	rmv_gtrx_dat_vlu_64[8+8+02*08+:1]	,	rmv_gtrx_dat_vlu_64[6+8+02*08+:2]	}	)==	3'b000);
		always@(posedge	clk)	rmv_sop_byte[1]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu_l[1]	&&	rmv_gtrx_dat_vlu_64[32+01*08+:08]	==	8'h7C	&&	((~idle2_detected?	rmv_gtrx_dat_vlu_64[16+01*08+:3]	:	{	rmv_gtrx_dat_vlu_64[8+8+01*08+:1]	,	rmv_gtrx_dat_vlu_64[6+8+01*08+:2]	}	)==	3'b000);
		always@(posedge	clk)	rmv_sop_byte[0]	<=	r_gtrx_spd_vld	&&	rmv_gtrx_isk_vlu_l[0]	&&	rmv_gtrx_dat_vlu_64[32+00*08+:08]	==	8'h7C	&&	((~idle2_detected?	rmv_gtrx_dat_vlu_64[16+00*08+:3]	:	{	rmv_gtrx_dat_vlu_64[8+8+00*08+:1]	,	rmv_gtrx_dat_vlu_64[6+8+00*08+:2]	}	)==	3'b000);
		
		always@(posedge	clk)	rmv_gtrx_sop_cnt	<=	rst	?	0	:	rmv_gtrx_sop_cnt	+	rmv_sop_byte[3];
		always@(posedge	clk)	rmv_byte_sop_cnt	<=	rst	?	0	:	rmv_byte_sop_cnt	+	rmv_sop_byte[0]+rmv_sop_byte[1]+rmv_sop_byte[2]+rmv_sop_byte[3];
		
end	endgenerate

	//	/* synthesis translate_off */ 
		
	//	/* synthesis translate_on */ 




	//////////////////////	
	
//	reg		[31:0]	gtrx_sop_cnt	=	0	;
//	
//	wire	ln0_sop	=	(	gtrx_charisk[0*4+3]	&&	gtrx_data[0*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	wire	ln1_sop	=	(	gtrx_charisk[1*4+3]	&&	gtrx_data[1*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	wire	ln2_sop	=	(	gtrx_charisk[2*4+3]	&&	gtrx_data[2*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	wire	ln3_sop	=	(	gtrx_charisk[3*4+3]	&&	gtrx_data[3*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	
//	always@(posedge	clk)	gtrx_sop_cnt	<=	gtrx_sop_cnt	+	ln0_sop	+	ln1_sop	+	ln2_sop	+	ln3_sop	;
//	
//	wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_cvt_spd_vlu			;	
//	wire								gtrx_cvt_spd_vld			;
//	
//	
//	wire	ln0_sop	=	(	gtrx_charisk[0*4+3]	&&	gtrx_data[0*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	wire	ln1_sop	=	(	gtrx_charisk[1*4+3]	&&	gtrx_data[1*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	wire	ln2_sop	=	(	gtrx_charisk[2*4+3]	&&	gtrx_data[2*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	wire	ln3_sop	=	(	gtrx_charisk[3*4+3]	&&	gtrx_data[3*32+24+:8]	==	8'h7C	)	?	1'b1	:	1'b0	;
//	
//	always@(posedge	clk)	gtrx_sop_cnt	<=	gtrx_sop_cnt	+	ln0_sop	+	ln1_sop	+	ln2_sop	+	ln3_sop	;	


//	`ifdef	DBG_ILA	
//	
//		reg		[7:0]	calc_lnx_vlu		=	0	;	always@(posedge	clk)	calc_lnx_vlu		<=	rst	?	0	:	gtx_gtrx_sop_cnt	-	rmv_gtrx_sop_cnt	;
//		reg				calc_lnx_vlu_err	=	0	;	always@(posedge	clk)	calc_lnx_vlu_err	<=	rst	?	0	:	calc_lnx_vlu		>	1					;
//			ila_288X1024 ila_288X1024_rmv (
//				.	clk		(	gt_pcs_clk	)	,	// input wire clk
//				.	probe0	(	
//								{
//		
//									rmv_sop_byte			,
//									
//									gtrx_data				,
//									gtrx_charisk			,
//									gtrx_vld_msk			,
//									r_gtrx_spd_num			,
//	
//									r_gtrx_spd_vld			,
//									gtrx_cvt_buf_rdy		,
//									
//									rmv_gtrx_dat_vlu		,
//									rmv_gtrx_isk_vlu		,
//									
//									calc_lnx_vlu			,
//									calc_lnx_vlu_err		,
//									idle2_detected			,
//									
//									rmv_byte_sop_cnt		,
//									rmv_gtrx_sop_cnt		,
//									gtx_gtrx_sop_cnt		,						
//									gt_pcs_rst				
//								}	
//							)		// input wire [31:0] probe0
//			);
//	`endif	

endmodule