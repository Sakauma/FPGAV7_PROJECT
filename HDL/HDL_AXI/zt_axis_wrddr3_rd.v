`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZhengYunLong
//
// Create Date:		2018/9/7 14:15:13
// Design Name:
// Module Name:		zt_axis_wrddr3_rd
// Project Name:	XP2000
// Target Devices:	XC7K325TFFG676-2
// Tool versions:	Vivado 2016.4
// Description:
//	该模块为XP2000最大集合的顶层模块
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////////////////////
module	zt_axis_wrddr3_rd	#(
	parameter		P_SIMULATION_R				= "TRUE"									,
	parameter		P_Ddr3_Start_Addr_R	 		= 32'h0000_0000								,	//起始地址为0
	parameter		P_ddr3_Mem_Size_R			= 32'h1000_0000								,	//256MB
	parameter		P_Ddr3_Block_size_R			= 32'h0000_0100								,	//512字节
	parameter		P_Packet_Unit_B_R			= 8											,	//长度单位为8字节、4字节等
	parameter		P_Packet_Head_Len_R			= 1											,	//广义包头长度8字节为单位
	parameter		P_Packet_DATA_Plen_R		= 1											,	//随广义包头预取得长度，8字节为单位
	parameter		P_Packet_Len_LSB_R			= 0												//广义包头中Len素在QWROD的LSB位置
	)(
	/*--------------------------------------------------------------------------------------
	--Common Inteface
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										rst											,
	input										soft_rst									,
	
	/*--------------------------------------------------------------------------------------
	--DMA通道AXI Master接口
	--------------------------------------------------------------------------------------*/
	output			[63:0]						m_axis_tdata								,
	output			[ 3:0]						m_axis_tid									,
	input										m_axis_tready								,
	output										m_axis_tvalid								,
	output			[ 7:0]						m_axis_tstrb								,
	output			[ 7:0]						m_axis_tkeep								,
	output										m_axis_tlast								,
	output	reg		[63:0]						m_axis_tuser								,
	output			[ 3:0]						m_axis_tdest								,
	/*--------------------------------------------------------------------------------------
	--DDR3 AXI4读出接口
	--------------------------------------------------------------------------------------*/
	input	wire	[ 3:0]						M_AXI_RID									,
	(*mark_debug="TRUE"*)
	input	wire	[63:0]						M_AXI_RDATA									,
	input	wire	[ 1:0]						M_AXI_RRESP									,
	(*mark_debug="TRUE"*)
	input	wire								M_AXI_RLAST									,
	(*mark_debug="TRUE"*)
	input	wire								M_AXI_RVALID								,
	(*mark_debug="TRUE"*)
	output	wire								M_AXI_RREADY								,
	
	/*--------------------------------------------------------------------------------------
	--AXI_Read_Trn接口信号定义
	--------------------------------------------------------------------------------------*/
	(*mark_debug="TRUE"*)
	output										m_axir_req									,
	(*mark_debug="TRUE"*)
	input										m_axir_gnt									,
	(*mark_debug="TRUE"*)
	output	reg		[10:0]						m_axir_len64			= 0					,
	output	reg		[31:0]						m_axir_addr				= P_Ddr3_Start_Addr_R,
	
	/*--------------------------------------------------------------------------------------
	--Packet管理
	--------------------------------------------------------------------------------------*/	
	input										packet_inc									,
	output	reg		[31:0]						packet_cnt				= 0					
	);	
//==================================================================================================
//--参数定义
	/*--------------------------------------------------------------------------------------
	--状态机参数
	--------------------------------------------------------------------------------------*/		
	localparam		S_R_IDLE_M					= 7'b000_0001								;
	localparam		S_R_HREQ_M					= 7'b000_0010								;
	localparam		S_R_HDATA_M					= 7'b000_0100								;
	localparam		S_R_LOAD_M					= 7'b000_1000								;
	localparam		S_R_DREQ_M					= 7'b001_0000								;
	localparam		S_R_DDATA_M					= 7'b010_0000								;
	localparam		S_R_DONE_M					= 7'b100_0000								;
	                                        	                    						
	                                        	                    						
//	localparam		B_R_IDLE_M					= 0											;
	localparam		B_R_HREQ_M					= 1											;
	localparam		B_R_HDATA_M					= 2											;
	localparam		B_R_LOAD_M					= 3											;
	localparam		B_R_DREQ_M					= 4											;
	localparam		B_R_DDATA_M					= 5											;
	localparam		B_R_DONE_M					= 6											;
	
	/*--------------------------------------------------------------------------------------
	--S_NM Master AXI-Stream
	--------------------------------------------------------------------------------------*/	
	localparam		S_IDLE_M					= 4'b0001									;
	localparam		S_HEAD_M					= 4'b0010									;
	localparam		S_DATA_M					= 4'b0100									;
	localparam		S_DONE_M					= 4'b1000									;
	                                        	                    						
	localparam		B_IDLE_M					= 0											;
	localparam		B_HEAD_M					= 1											;
	localparam		B_DATA_M					= 2											;
	localparam		B_DONE_M					= 3											;
	
	/*--------------------------------------------------------------------------------------
	--最多包数目计算
	--------------------------------------------------------------------------------------*/
	localparam		L_DDR3_END_ADDR_P			= P_ddr3_Mem_Size_R+P_Ddr3_Start_Addr_R 		;	//缓冲区结束定制
	localparam		L_HEAD_LEN64_P				= P_Packet_Head_Len_R + P_Packet_DATA_Plen_R	;	//包头的长度+预取数据长度(64bit单位)
	localparam		L_HEAD_ADDR_OFFSET_P		= L_HEAD_LEN64_P*8							;	//跳过包头的数据偏移量
//==================================================================================================
//--信号定义
	/*--------------------------------------------------------------------------------------
	--存储器读访问接口控制信号
	--------------------------------------------------------------------------------------*/	 
	 reg			[ 6:0]						S_R_CM										;
	 reg			[ 6:0]						S_R_NM										;
	 
	 reg			[ 2:0]						head_cnt									;
	 wire			[10:0]						packet_len64								;
	 wire										packet_dec									;
	/*--------------------------------------------------------------------------------------
	--存储器地址管理信号
	--------------------------------------------------------------------------------------*/	 
	 reg			[31:0]						axir_addr				= P_Ddr3_Start_Addr_R;
	 
	/*--------------------------------------------------------------------------------------
	--Data FIFO信号
	--------------------------------------------------------------------------------------*/	 	
	wire			[63:0]						data_fifo_din								;
	wire										data_fifo_wen								;
	wire										data_fifo_afull								;

	wire			[63:0]						data_fifo_dout								;
	wire										data_fifo_empty								;
	wire										data_fifo_ren								;
	
	/*--------------------------------------------------------------------------------------
	--AXIS-Stream Master相关信号
	--------------------------------------------------------------------------------------*/
	reg				[ 3:0]						S_NM										;
	reg				[ 3:0]						S_CM										;

	wire			[15:0]						data_len_x									;
	wire			[10:0]						data_len64									;
	reg				[10:0]						data_cnt									;

//==================================================================================================
//--状态机实现
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_R_CM								<= S_R_IDLE_M								;
		end else begin
			S_R_CM								<= S_R_NM									;
		end
	end
	
	always @(*) begin				
		S_R_NM									= 'bx										;
		case(S_R_CM)
			S_R_IDLE_M							: begin
				if(packet_cnt>0 && (!data_fifo_afull | soft_rst)) begin
					S_R_NM						= S_R_HREQ_M								;
				end else begin
					S_R_NM						= S_R_IDLE_M								;
				end
			end
			S_R_HREQ_M							: begin
				if(m_axir_gnt && m_axir_req) begin
					S_R_NM						= S_R_HDATA_M								;
				end else begin
					S_R_NM						= S_R_HREQ_M								;
				end
			end
			S_R_HDATA_M							: begin
				if(M_AXI_RLAST && M_AXI_RVALID && M_AXI_RREADY) begin
					S_R_NM						= S_R_LOAD_M								;
				end else begin
					S_R_NM						= S_R_HDATA_M								;
				end
			end
			S_R_LOAD_M							: begin
				if(packet_len64==0 || packet_len64==P_Packet_DATA_Plen_R) begin
					S_R_NM						= S_R_DONE_M								;
				end else begin
					S_R_NM						= S_R_DREQ_M								;
				end
			end
			S_R_DREQ_M							: begin
				if(m_axir_gnt && m_axir_req) begin
					S_R_NM						= S_R_DDATA_M								;
				end else begin
					S_R_NM						= S_R_DREQ_M								;
				end
			end
			S_R_DDATA_M							: begin
				if(M_AXI_RLAST && M_AXI_RVALID && M_AXI_RREADY) begin
					S_R_NM						= S_R_DONE_M								;
				end else begin
					S_R_NM						= S_R_DDATA_M								;
				end
			end
			S_R_DONE_M							: begin
				S_R_NM							= S_R_IDLE_M								;
			end
		endcase
	end
	
	assign	packet_dec							= S_R_CM[B_R_DONE_M]						;
	
//-------------------------------------------------------------------------------------------
//--获取数据段的长度，考虑到不同的应用，HEAD的读取长度可以考虑增加一定的数据量
//--例如在SRIO下发的历程中，HEAD_LEN64=1,DATA_LEN也经常为1，因此增加一定的长度判断	
	always @(posedge clk) begin
		if(S_R_NM[S_R_IDLE_M]) begin
			head_cnt							<= 0										;
		end else 
		if(S_R_NM[S_R_HREQ_M] || S_R_NM[S_R_HDATA_M]) begin
			if(M_AXI_RREADY && M_AXI_RVALID) begin
				head_cnt						<= head_cnt + 1'b1							;
			end else begin
				head_cnt						<= head_cnt									;
			end
		end
	end
	
	reg				[15:0]						packet_len_x			= 0					;	//广义包头中的长度
	always @(posedge clk) begin
		if(M_AXI_RREADY && M_AXI_RVALID && head_cnt==-0) begin
			packet_len_x						<= M_AXI_RDATA[P_Packet_Len_LSB_R+:16]		;
		end else begin
			packet_len_x						<= packet_len_x								;
		end
	end
	
generate if(P_Packet_Unit_B_R==8) begin
	assign	packet_len64						= packet_len_x[10:0]						;
end else if(P_Packet_Unit_B_R==4) begin
	assign	packet_len64						= (packet_len_x[0]==1'b0)
												? packet_len_x[11:1]
												: packet_len_x[11:1]+1'b1					;
end else begin	//其它情况按单字节处理
	assign	packet_len64						= (packet_len_x[2:0]==3'b0)
												? packet_len_x[13:3]
												: packet_len_x[13:3]+1'b1					;
end
endgenerate


//--M_AXIR信号实现--------------------------------------------------------------------------
	/*--------------------------------------------------------------------------------------
	--64bit单位长度实现
	--注意:如果HDATA长度必须减去PLEN
	--------------------------------------------------------------------------------------*/	
	always @(posedge clk) begin
		if(S_R_NM[B_R_HREQ_M]) begin
			m_axir_len64						<= L_HEAD_LEN64_P							;
		end else if(S_R_NM[B_R_LOAD_M]) begin
			m_axir_len64						<= packet_len64 - P_Packet_DATA_Plen_R		;
		end else begin
			m_axir_len64						<= m_axir_len64								;
		end
	end
	
	always @(posedge clk) begin
		if(S_R_NM[B_R_HREQ_M]) begin
			m_axir_addr							<= axir_addr								;
		end else if(S_R_NM[B_R_HDATA_M]) begin
			m_axir_addr							<= axir_addr + L_HEAD_ADDR_OFFSET_P			;
		end
	end
	
	assign	m_axir_req							= S_R_CM[B_R_HREQ_M] | S_R_CM[B_R_DREQ_M]	;
	

//--存储器地址管理--------------------------------------------------------------------------
	/*--------------------------------------------------------------------------------------
	--地址管理
	--------------------------------------------------------------------------------------*/	
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			axir_addr							<= P_Ddr3_Start_Addr_R						;
		end else if(soft_rst) begin
			axir_addr							<= P_Ddr3_Start_Addr_R						;
		end else if(packet_dec && axir_addr==L_DDR3_END_ADDR_P-P_Ddr3_Block_size_R) begin
			axir_addr							<= P_Ddr3_Start_Addr_R						;
		end else if(packet_dec) begin
			axir_addr							<= axir_addr + P_Ddr3_Block_size_R			;
		end else begin
			axir_addr							<= axir_addr								;
		end
	end
	
	/*--------------------------------------------------------------------------------------
	--packet计数器管理
	--------------------------------------------------------------------------------------*/
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			packet_cnt							<= 32'b0									;
		end else if(soft_rst) begin
			packet_cnt							<= 32'b0									;
		end else if(packet_dec && packet_inc) begin
			packet_cnt							<= packet_cnt								;
		end else if(packet_inc) begin
			packet_cnt							<= packet_cnt + 1'b1						;
		end else if(packet_dec && packet_cnt!=0) begin
			packet_cnt							<= packet_cnt - 1'b1						;
		end else begin
			packet_cnt							<= packet_cnt								;
		end
	end

//==================================================================================================
//--数据写入
	assign	data_fifo_din						= M_AXI_RDATA								;
	assign	data_fifo_wen						= M_AXI_RVALID && M_AXI_RREADY && ~soft_rst	;
	
	assign	M_AXI_RREADY						= 1'b1										;
	assign	data_fifo_ren						= m_axis_tvalid && m_axis_tready && ~soft_rst;
	
	/*--------------------------------------------------------------------------------------
	--解决FIFO的不同步问题，用计数器实现数据使能
	--------------------------------------------------------------------------------------*/
	reg				[7:0]						dn_cnt										;
	wire										dn_cnt_dec									;
	assign	dn_cnt_dec							= S_CM[B_DONE_M] &&	~soft_rst				;
	
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			dn_cnt								<= 8'b0										;
		end else if(soft_rst) begin
			dn_cnt								<= 8'b0										;
		end else if(packet_dec && dn_cnt_dec) begin
			dn_cnt								<= dn_cnt									;
		end else if(packet_dec) begin
			dn_cnt								<= dn_cnt + 1'b1							;
		end else if(dn_cnt_dec && dn_cnt!=0) begin
			dn_cnt								<= dn_cnt - 1'b1							;
		end else begin
			dn_cnt								<= dn_cnt									;
		end
	end
	
//--DATA FIFO例化
	FIFO_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h040									),	// Sets almost full threshold
		.DATA_WIDTH								( 64										),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( data_fifo_afull							),	// 1-bit output almost full
		.DO										( data_fifo_dout							),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( data_fifo_empty							),	// 1-bit output empty
		.FULL									(  											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din								),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst | soft_rst							),	// 1-bit input reset
		.WRCLK									( clk										),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	
//==================================================================================================
//--AXI Stream Master输出
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_CM								<= S_IDLE_M									;
		end else if(soft_rst) begin
			S_CM								<= S_IDLE_M									;
		end else begin
			S_CM								<= S_NM										;
		end
	end
	
	always @(*) begin
		S_NM									= 'bx										;
		case(S_CM)
			S_IDLE_M							: begin
				if(dn_cnt>0) begin
					S_NM						= S_HEAD_M									;
				end else begin
					S_NM						= S_IDLE_M									;
				end
			end
			S_HEAD_M							: begin
				S_NM							= S_DATA_M									;
			end
			S_DATA_M							: begin
				if(m_axis_tready && m_axis_tvalid && m_axis_tlast) begin
					S_NM						= S_DONE_M									;
				end else begin
					S_NM						= S_DATA_M									;
				end
			end
			S_DONE_M							: begin
				S_NM							= S_IDLE_M									;
			end
		endcase
	end

//---------------------------------------------------------------------------------------------
//--包长获取
	assign	data_len_x							= data_fifo_dout[P_Packet_Len_LSB_R+:16]		;

generate if(P_Packet_Unit_B_R==8) begin
	assign	data_len64							= data_len_x[10:0] + P_Packet_Head_Len_R		;
end else if(P_Packet_Unit_B_R==4) begin
	assign	data_len64							= (data_len_x[0]==1'b0)
												? (data_len_x[11:1]+P_Packet_Head_Len_R)
												: (data_len_x[11:1]+1'b1+P_Packet_Head_Len_R);
end else begin	//其它情况按单字节处理
	assign	data_len64							= (data_len_x[2:0]==3'b0)
												? (data_len_x[13:3]+P_Packet_Head_Len_R)
												: (data_len_x[13:3]+1'b1+P_Packet_Head_Len_R);
end
endgenerate

//--------------------------------------------------------------------------------------------
//--计数器实现
	always @(posedge clk) begin
		if(S_NM[B_IDLE_M]) begin
			data_cnt							<= 0										;
			m_axis_tuser[63:0]					<= 0										;
		end else if(S_NM[B_HEAD_M]) begin
			data_cnt							<= data_len64 - 1'b1						;
			m_axis_tuser						<= {52'b0,data_len64[10:0],1'b0}			;
		end else if(S_CM[B_DATA_M]) begin
			if(m_axis_tready & m_axis_tvalid) begin
				data_cnt						<= data_cnt - 1'b1							;
			end else begin
				data_cnt						<= data_cnt									;
			end
		end else begin
			data_cnt							<= data_cnt									;
			m_axis_tuser[63:0]					<= m_axis_tuser[63:0]						;
		end
	end
//---------------------------------------------------------------------------------------------
//--m_axis_信号实现
	assign	m_axis_tdata						= data_fifo_dout							;
	
	assign	m_axis_tvalid						= S_CM[B_DATA_M]							;
	
	assign	m_axis_tlast						= data_cnt==0 && m_axis_tready 
												&& m_axis_tvalid							;
	
	assign	m_axis_tdest						= 0											;
	assign	m_axis_tid							= 0											;
	assign	m_axis_tkeep						= 0											;
	assign	m_axis_tstrb						= 0											;

endmodule