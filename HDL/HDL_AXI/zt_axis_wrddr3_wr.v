`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZhengYunLong
//
// Create Date:		2018/9/7 11:41:09
// Design Name:
// Module Name:		zt_axis_wrddr3_top
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
module	zt_axis_wrddr3_wr	#(
	parameter		P_SIMULATION_R				= "TRUE"									,
	parameter		P_Ddr3_Start_Addr_R	 		= 32'h0000_0000								,	//起始地址为0
	parameter		P_ddr3_Mem_Size_R			= 32'h1000_0000								,	//256MB
	parameter		P_Ddr3_Block_size_R			= 32'h0000_0100								,	//512字节
	parameter		P_Packet_Unit_B_R			= 8											,	//长度单位为8字节、4字节等
	parameter		P_Packet_Head_Len_R			= 1											,	//广义包头长度8字节为单位
	parameter		P_Packet_Len_LSB_R			= 0												//广义包头中Len素在QWROD的LSB位置
	)(
	/*--------------------------------------------------------------------------------------
	--Common Inteface
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										rst											,
	input										soft_rst									,

	input			[31:0]						reg_mem_addr_c								,
	input			[31:0]						reg_mem_size_c								,
	
	/*--------------------------------------------------------------------------------------
	--DMA通道AXI Slave接口
	--------------------------------------------------------------------------------------*/
	//DMA Dn Signals
	(*mark_debug="TRUE"*)
	input	wire	[63:0]						s_axis_tdata								,
	input			[3:0]						s_axis_tid									,
	(*mark_debug="TRUE"*)
	output										s_axis_tready								,
	(*mark_debug="TRUE"*)
	input	wire								s_axis_tvalid								,
	input			[7:0]						s_axis_tstrb								,
	input			[7:0]						s_axis_tkeep								,
	(*mark_debug="TRUE"*)
	input										s_axis_tlast								,
	input			[63:0]						s_axis_tuser								,
	input			[3:0]						s_axis_tdest								,

	/*--------------------------------------------------------------------------------------
	--AXIW接口模块信号
	--------------------------------------------------------------------------------------*/
	(*mark_debug="TRUE"*)
	output										m_axiw_req									,
	(*mark_debug="TRUE"*)
	input										m_axiw_gnt									,
	(*mark_debug="TRUE"*)
	output	reg		[10:0]						m_axiw_len64			= 0					,
	(*mark_debug="TRUE"*)
	output	reg		[31:0]						m_axiw_addr				= P_Ddr3_Start_Addr_R,
	output			[7:0]						m_axiw_wstrb								,	//仅当最后一个64比特数据有效，用于OnlyOne模式

	output			[63:0]						m_axiw_fifo_rdata							,
	output										m_axiw_fifo_empty							,
	input										m_axiw_fifo_rden							,

	/*--------------------------------------------------------------------------------------
	--packet Inc输出
	--------------------------------------------------------------------------------------*/
	input			[31:0]						packet_cnt									,
	output										packet_inc
	);
//==================================================================================================
//--参数定义
	/*--------------------------------------------------------------------------------------
	--状态机参数
	--------------------------------------------------------------------------------------*/
	localparam									S_W_IDLE_M				= 4'b0001			;
	localparam									S_W_LOAD_M				= 4'b0010			;
	localparam									S_W_REQ_M				= 4'b0100			;
	localparam									S_W_DONE_M				= 4'b1000			;

//	localparam									B_W_IDLE_M				= 0					;
	localparam									B_W_LOAD_M				= 1					;
	localparam									B_W_REQ_M				= 2					;
	localparam									B_W_DONE_M				= 3					;

	/*--------------------------------------------------------------------------------------
	--最多包数目计算
	--------------------------------------------------------------------------------------*/
	localparam		LP_DDR3_END_ADDR			= P_ddr3_Mem_Size_R+P_Ddr3_Start_Addr_R 	;
	localparam		LP_PACKET_MAX_NUM			= P_ddr3_Mem_Size_R/P_Ddr3_Block_size_R		;

//==================================================================================================
//--信号定义
	/*--------------------------------------------------------------------------------------
	--状态机信号定义
	--------------------------------------------------------------------------------------*/
	reg				[3:0]						S_W_CM										;
	reg				[3:0]						S_W_NM										;

	wire										mem_vld										;

	/*--------------------------------------------------------------------------------------
	--数据FIFO信号定义
	--------------------------------------------------------------------------------------*/
	wire			[63:0]						data_fifo_din								;
	wire										data_fifo_wen								;
	wire										data_fifo_full								;

	wire			[63:0]						data_fifo_dout								;
	wire										data_fifo_empty								;
	wire										data_fifo_ren								;
//==================================================================================================
//--DMA数据写入FIFO
	assign	s_axis_tready						= ~data_fifo_full							;
	assign	data_fifo_wen						= s_axis_tvalid && s_axis_tready			;
	assign	data_fifo_din[63:0]					= s_axis_tdata								;

//==================================================================================================
//--存储器存储报文个数,当前报文个数小于总数，则可以进行数据存储
	assign	mem_vld								= packet_cnt<LP_PACKET_MAX_NUM-1			;

//==================================================================================================
//--DDR3写入操作
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_W_CM								<= S_W_IDLE_M								;
		end else begin
			S_W_CM								<= S_W_NM									;
		end
	end

	always @(*) begin
		S_W_NM									= 'bx										;
		case(S_W_CM)
			S_W_IDLE_M							: begin
				if(!data_fifo_empty && mem_vld) begin
					S_W_NM						= S_W_LOAD_M								;
				end else begin
					S_W_NM						= S_W_IDLE_M								;
				end
			end
			S_W_LOAD_M							: begin
				S_W_NM							= S_W_REQ_M									;
			end
			S_W_REQ_M							: begin
				if(m_axiw_gnt && m_axiw_req) begin
					S_W_NM						= S_W_DONE_M								;
				end else begin
					S_W_NM						= S_W_REQ_M									;
				end
			end
			S_W_DONE_M							: begin
				S_W_NM							= S_W_IDLE_M								;
			end
		endcase
	end
//==================================================================================================
//--M_AXIW相关信号输出
	/*--------------------------------------------------------------------------------------
	--m_axiw_len64
	--------------------------------------------------------------------------------------*/
	wire			[10:0]						len64										;
	wire			[15:0]						len_x										;

	assign	len_x								= data_fifo_dout[P_Packet_Len_LSB_R+:16]	;

generate if(P_Packet_Unit_B_R==8) begin
	assign	len64								= len_x										;
end else if(P_Packet_Unit_B_R==4) begin
	assign	len64								= (len_x[0]==1'b0)
												? len_x[11:1]
												: len_x[11:1]+1'b1							;
end else begin	//其它情况按单字节处理
	assign	len64								= (len_x[2:0]==3'b0)
												? len_x[13:3]
												: len_x[13:3]+1'b1							;
end
endgenerate

	always @(posedge clk) begin
		if(S_W_NM[B_W_LOAD_M]) begin
			m_axiw_len64						<= len64 + P_Packet_Head_Len_R				;
		end else begin
			m_axiw_len64						<= m_axiw_len64								;
		end
	end
	/*--------------------------------------------------------------------------------------
	--m_axiw_req
	--------------------------------------------------------------------------------------*/
	assign	m_axiw_req							= S_W_CM[B_W_REQ_M]							;
	assign	m_axiw_wstrb						= 8'hFF										;

	assign	m_axiw_fifo_empty					= data_fifo_empty							;
	assign	m_axiw_fifo_rdata					= data_fifo_dout							;
	assign	data_fifo_ren						= m_axiw_fifo_rden							;
//==================================================================================================
//--存储器地址管理
	assign	packet_inc							= S_W_CM[B_W_DONE_M] && ~soft_rst			;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			m_axiw_addr							<= P_Ddr3_Start_Addr_R						;
		end else if(soft_rst) begin
			m_axiw_addr							<= P_Ddr3_Start_Addr_R						;
		end else if(packet_inc && (m_axiw_addr+P_Ddr3_Block_size_R==LP_DDR3_END_ADDR)) begin
			m_axiw_addr							<= P_Ddr3_Start_Addr_R						;
		end else if(packet_inc) begin
			m_axiw_addr							<= m_axiw_addr + P_Ddr3_Block_size_R		;
		end else begin
			m_axiw_addr							<= m_axiw_addr								;
		end
	end

//==================================================================================================
//--DATA FIFO例化
	FIFO_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 64										),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout							),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( data_fifo_empty							),	// 1-bit output empty
		.FULL									( data_fifo_full 							),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din								),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( clk										),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
endmodule