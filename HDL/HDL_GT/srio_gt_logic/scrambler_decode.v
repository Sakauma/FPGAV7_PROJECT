//	Main	Function	:
//	1.	产生M序列并解扰，方程式P(X)可配。
//	2.	种子值可配。
//---------------------------------------------------------------------

`timescale	1ns	/	1ps
module	scrambler_decode	#
(
	parameter	D_WIDTH	=	8			,	//数据位宽
	parameter	P_WIDTH	=	17			,	//方程式位宽
	parameter	SEED	=	17'h1FFFF	,	//解扰种子
	parameter	POLY	=	32'h10081		//方程式：P(X)	=	1	+	X^8	+	X^17
)
(
	input					I_rst	,	//	
	input					I_clk	,	//	
	input					I_load	,	//	解扰序列加载
	input	[P_WIDTH-1:0]	I_seed	,	//	解扰序列加载值
	input	[D_WIDTH-1:0]	I_sync	,	//	解扰序列同步输入-按bit
	input	[D_WIDTH-1:0]	I_valid	,	//	解扰数据同步输入-按bit
	input	[D_WIDTH-1:0]	I_data	,	//	原始数据输入
	output	[D_WIDTH-1:0]	O_sync	,	//	解扰序列同步输出
	output	[D_WIDTH-1:0]	O_seed	,	//	解扰数据同步输出
	output	[D_WIDTH-1:0]	O_valid	,	//	解扰数据同步输出
	output	[D_WIDTH-1:0]	O_data		//	解扰数据输出
);
	
	integer	i;
	reg	[P_WIDTH-1:0]	m_now	;
	reg	[P_WIDTH-1:0]	m_next	;
	reg	[D_WIDTH-1:0]	d_now	;
	reg	[D_WIDTH-1:0]	d_next	;
	
	always	@	(m_now,I_data)
	begin
		m_next	=	m_now	;
		for(i=0;i<D_WIDTH;i=i+1)
		begin
		//	d_next[i]	=	^(POLY[P_WIDTH-1:1]&m_next[P_WIDTH-1:1])^I_data[i];
			d_next[D_WIDTH-1-i]	=	(I_valid[D_WIDTH-1-i]?m_next[P_WIDTH-1]:1'b0)^I_data[D_WIDTH-1-i];
		//	m_next		=	{m_next[P_WIDTH-2:0],I_data[i]};
			if(I_sync[D_WIDTH-1-i])	m_next	=	{m_next[P_WIDTH-2:0],^(POLY[P_WIDTH-1:1]&m_next[P_WIDTH-1:1])};
		end
	end
	
	always	@	(posedge	I_clk)
	begin
		if(I_rst)
			d_now	<=	0;
	//	else	if(I_valid)
	//		d_now	<=	d_next;
		else	
			d_now	<=	d_next;
	end

	reg	[D_WIDTH-1:0]		I_sync_q	=	0	;
	always@(posedge	I_clk)	I_sync_q	<=	I_sync		;
	assign	O_sync	=	I_sync_q	;
	
	always	@	(posedge	I_clk)
	begin
		if(I_rst)
			m_now	<=	SEED;
		else	if(I_load)
			m_now	<=	I_seed;
	//	else	if(I_sync)
	//		m_now	<=	m_next;
		else	
			m_now	<=	m_next;
	end
	
	assign	O_data	=	d_now;
	
	reg	[D_WIDTH-1:0]		I_valid_q	=	0	;
	always@(posedge	I_clk)	I_valid_q	<=	I_valid		;
	
	reg	[15:0]	vaild_cnt	=	0	;
	always@(posedge	I_clk)	begin
		if			(	I_rst	)	vaild_cnt	<=	0					;
		else	if	(	I_valid_q)	vaild_cnt	<=	vaild_cnt	+	1	;
		else						vaild_cnt	<=	vaild_cnt			;
	end
	
	assign	O_valid	=	I_valid_q	;
	
	assign	O_seed	=	m_now	;	
	
endmodule	