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
module	zt_axis_wrddr3_top	#(
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
	--DMA通道AXI Slave接口
	--------------------------------------------------------------------------------------*/
	//DMA Dn Signals
	input	wire	[63:0]						s_axis_tdata								,
	input			[ 3:0]						s_axis_tid									,
	output										s_axis_tready								,
	input	wire								s_axis_tvalid								,
	input			[ 7:0]						s_axis_tstrb								,
	input			[ 7:0]						s_axis_tkeep								,
	input										s_axis_tlast								,
	input			[63:0]						s_axis_tuser								,
	input			[ 3:0]						s_axis_tdest								,

	output	wire	[31:0]						packet_count								,
	input			[31:0]						reg_mem_addr_c								,
	input			[31:0]						reg_mem_size_c								,

	/*--------------------------------------------------------------------------------------
	--DDR3 AXI4写入接口
	--------------------------------------------------------------------------------------*/
	output	wire	[ 3:0]						M_AXI_AWID									,
	output	wire	[31:0]						M_AXI_AWADDR								,
	output	wire	[ 7:0]						M_AXI_AWLEN									,
	output	wire	[ 2:0]						M_AXI_AWSIZE								,
	output	wire	[ 1:0]						M_AXI_AWBURST								,
	output	wire								M_AXI_AWLOCK								,
	output	wire	[ 3:0]						M_AXI_AWCACHE								,
	output	wire	[ 2:0]						M_AXI_AWPROT								,
	output	wire	[ 3:0]						M_AXI_AWQOS									,
	output	wire								M_AXI_AWVALID								,
	input	wire								M_AXI_AWREADY								,
	output	wire	[63:0]						M_AXI_WDATA									,
	output	wire	[ 7:0]						M_AXI_WSTRB									,
	output	wire								M_AXI_WLAST									,
	output	wire								M_AXI_WVALID								,
	input	wire								M_AXI_WREADY								,
	input	wire	[ 3:0]						M_AXI_BID									,
	input	wire	[ 1:0]						M_AXI_BRESP									,
	input	wire								M_AXI_BVALID								,
	output	wire								M_AXI_BREADY								,

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
	output			[63:0]						m_axis_tuser								,
	output			[ 3:0]						m_axis_tdest								,
	/*--------------------------------------------------------------------------------------
	--DDR3 AXI4读出接口
	--------------------------------------------------------------------------------------*/
	output	wire	[ 3:0]						M_AXI_ARID									,
	output	wire	[31:0]						M_AXI_ARADDR								,
	output	wire	[ 7:0]						M_AXI_ARLEN									,
	output	wire	[ 2:0]						M_AXI_ARSIZE								,
	output	wire	[ 1:0]						M_AXI_ARBURST								,
	output	wire								M_AXI_ARLOCK								,
	output	wire	[3:0]						M_AXI_ARCACHE								,
	output	wire	[2:0]						M_AXI_ARPROT								,
	output	wire	[3:0]						M_AXI_ARQOS									,
	output	wire								M_AXI_ARVALID								,
	input	wire								M_AXI_ARREADY								,

	input	wire	[ 3:0]						M_AXI_RID									,
	input	wire	[63:0]						M_AXI_RDATA									,
	input	wire	[ 1:0]						M_AXI_RRESP									,
	input	wire								M_AXI_RLAST									,
	input	wire								M_AXI_RVALID								,
	output	wire								M_AXI_RREADY
	);
//==================================================================================================
//--信号定义
	/*--------------------------------------------------------------------------------------
	--AXIW接口模块信号
	--------------------------------------------------------------------------------------*/
	wire										m_axiw_req									;
	wire										m_axiw_gnt									;
	wire			[10:0]						m_axiw_len64								;
	wire			[31:0]						m_axiw_addr									;
	wire			[ 7:0]						m_axiw_wstrb								;

	wire			[63:0]						m_axiw_fifo_rdata							;
	wire										m_axiw_fifo_empty							;
	wire										m_axiw_fifo_rden							;

	/*--------------------------------------------------------------------------------------
	--AXI_Read_Trn接口信号定义
	--------------------------------------------------------------------------------------*/
	wire										m_axir_req									;
	wire										m_axir_gnt									;
	wire			[10:0]						m_axir_len64								;
	wire			[31:0]						m_axir_addr									;

	/*--------------------------------------------------------------------------------------
	--交互计数器
	--------------------------------------------------------------------------------------*/
	wire			[31:0]						packet_cnt									;
	wire										packet_inc									;

	assign	packet_count						= packet_cnt								;
	
	/*--------------------------------------------------------------------------------------
	--Soft_reset Sync
	--------------------------------------------------------------------------------------*/
	reg				[1:0]						soft_reset_q								;
	
	always @(posedge clk) begin
		soft_reset_q[1:0]						<= {soft_reset_q[0],soft_rst}				;
	end
	
//==================================================================================================
//--zt_axis_wrddr3_wr Instantation
	zt_axis_wrddr3_wr	#(
		.P_SIMULATION_R							( P_SIMULATION_R							),
		.P_Ddr3_Start_Addr_R					( P_Ddr3_Start_Addr_R						),
		.P_ddr3_Mem_Size_R						( P_ddr3_Mem_Size_R							),
		.P_Ddr3_Block_size_R					( P_Ddr3_Block_size_R						),
		.P_Packet_Unit_B_R						( P_Packet_Unit_B_R							),
		.P_Packet_Head_Len_R					( P_Packet_Head_Len_R						),
		.P_Packet_Len_LSB_R						( P_Packet_Len_LSB_R						)
	)
	i_zt_axis_wrddr3_wr (
		.clk									( clk										),
		.rst									( rst										),
		.soft_rst								( soft_reset_q[1]							),
		
		.reg_mem_addr_c							( reg_mem_addr_c							),
		.reg_mem_size_c							( reg_mem_size_c							),
		
		.s_axis_tdata							( s_axis_tdata								),
		.s_axis_tid								( s_axis_tid								),
		.s_axis_tready							( s_axis_tready								),
		.s_axis_tvalid							( s_axis_tvalid								),
		.s_axis_tstrb							( s_axis_tstrb								),
		.s_axis_tkeep							( s_axis_tkeep								),
		.s_axis_tlast							( s_axis_tlast								),
		.s_axis_tuser							( s_axis_tuser								),
		.s_axis_tdest							( s_axis_tdest								),
		.m_axiw_req								( m_axiw_req								),
		.m_axiw_gnt								( m_axiw_gnt								),
		.m_axiw_len64							( m_axiw_len64								),
		.m_axiw_addr							( m_axiw_addr								),
		.m_axiw_wstrb							( m_axiw_wstrb								),

		.m_axiw_fifo_rdata						( m_axiw_fifo_rdata							),
		.m_axiw_fifo_empty						( m_axiw_fifo_empty							),
		.m_axiw_fifo_rden						( m_axiw_fifo_rden							),

		.packet_cnt								( packet_cnt								),
		.packet_inc								( packet_inc								)
	);

//==================================================================================================
//--zt_axi_wburst Instantation
	zt_axi_wburst	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_zt_axi_wburst (
		.clk									( clk										),
		.rst									( rst										),

		.M_AXI_AWID								( M_AXI_AWID								),
		.M_AXI_AWADDR							( M_AXI_AWADDR								),
		.M_AXI_AWLEN							( M_AXI_AWLEN								),
		.M_AXI_AWSIZE							( M_AXI_AWSIZE								),
		.M_AXI_AWBURST							( M_AXI_AWBURST								),
		.M_AXI_AWLOCK							( M_AXI_AWLOCK								),
		.M_AXI_AWCACHE							( M_AXI_AWCACHE								),
		.M_AXI_AWPROT							( M_AXI_AWPROT								),
		.M_AXI_AWQOS							( M_AXI_AWQOS								),
		.M_AXI_AWVALID							( M_AXI_AWVALID								),
		.M_AXI_AWREADY							( M_AXI_AWREADY								),
		.M_AXI_WDATA							( M_AXI_WDATA								),
		.M_AXI_WSTRB							( M_AXI_WSTRB								),
		.M_AXI_WLAST							( M_AXI_WLAST								),
		.M_AXI_WVALID							( M_AXI_WVALID								),
		.M_AXI_WREADY							( M_AXI_WREADY								),
		.M_AXI_BID								( M_AXI_BID									),
		.M_AXI_BRESP							( M_AXI_BRESP								),
		.M_AXI_BVALID							( M_AXI_BVALID								),
		.M_AXI_BREADY							( M_AXI_BREADY								),

		.m_axiw_req								( m_axiw_req								),
		.m_axiw_gnt								( m_axiw_gnt								),
		.m_axiw_len64							( m_axiw_len64								),
		.m_axiw_addr							( m_axiw_addr								),
		.m_axiw_wstrb							( m_axiw_wstrb								),
		.m_axiw_fifo_rdata						( m_axiw_fifo_rdata							),
		.m_axiw_fifo_empty						( m_axiw_fifo_empty							),
		.m_axiw_fifo_rden						( m_axiw_fifo_rden							)
	);

//==================================================================================================
//--zt_axis_wrddr3_rd Instantation
	zt_axis_wrddr3_rd	#(
		.P_SIMULATION_R							( P_SIMULATION_R							),
		.P_Ddr3_Start_Addr_R					( P_Ddr3_Start_Addr_R						),
		.P_ddr3_Mem_Size_R						( P_ddr3_Mem_Size_R							),
		.P_Ddr3_Block_size_R					( P_Ddr3_Block_size_R						),
		.P_Packet_Unit_B_R						( P_Packet_Unit_B_R							),
		.P_Packet_Head_Len_R					( P_Packet_Head_Len_R						),
		.P_Packet_DATA_Plen_R					( P_Packet_DATA_Plen_R						),
		.P_Packet_Len_LSB_R						( P_Packet_Len_LSB_R						)
	)
	i_zt_axis_wrddr3_rd (
		.clk									( clk										),
		.rst									( rst										),
		.soft_rst								( soft_reset_q[1]							),
		
		.reg_mem_addr_c							( reg_mem_addr_c							),
		.reg_mem_size_c							( reg_mem_size_c							),

		.m_axis_tdata							( m_axis_tdata								),
		.m_axis_tid								( m_axis_tid								),
		.m_axis_tready							( m_axis_tready								),
		.m_axis_tvalid							( m_axis_tvalid								),
		.m_axis_tstrb							( m_axis_tstrb								),
		.m_axis_tkeep							( m_axis_tkeep								),
		.m_axis_tlast							( m_axis_tlast								),
		.m_axis_tuser							( m_axis_tuser								),
		.m_axis_tdest							( m_axis_tdest								),

		.M_AXI_RID								( M_AXI_RID									),
		.M_AXI_RDATA							( M_AXI_RDATA								),
		.M_AXI_RRESP							( M_AXI_RRESP								),
		.M_AXI_RLAST							( M_AXI_RLAST								),
		.M_AXI_RVALID							( M_AXI_RVALID								),
		.M_AXI_RREADY							( M_AXI_RREADY								),
		.m_axir_req								( m_axir_req								),
		.m_axir_gnt								( m_axir_gnt								),
		.m_axir_len64							( m_axir_len64								),
		.m_axir_addr							( m_axir_addr								),

		.packet_inc								( packet_inc								),
		.packet_cnt								( packet_cnt								)
	);

//==================================================================================================
//--zt_axi_rburst Instantation
	zt_axi_rburst	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_zt_axi_rburst (
		.clk									( clk										),
		.rst									( rst										),

		.M_AXI_ARID								( M_AXI_ARID								),
		.M_AXI_ARADDR							( M_AXI_ARADDR								),
		.M_AXI_ARLEN							( M_AXI_ARLEN								),
		.M_AXI_ARSIZE							( M_AXI_ARSIZE								),
		.M_AXI_ARBURST							( M_AXI_ARBURST								),
		.M_AXI_ARLOCK							( M_AXI_ARLOCK								),
		.M_AXI_ARCACHE							( M_AXI_ARCACHE								),
		.M_AXI_ARPROT							( M_AXI_ARPROT								),
		.M_AXI_ARQOS							( M_AXI_ARQOS								),
		.M_AXI_ARVALID							( M_AXI_ARVALID								),
		.M_AXI_ARREADY							( M_AXI_ARREADY								),

		.m_axir_req								( m_axir_req								),
		.m_axir_gnt								( m_axir_gnt								),
		.m_axir_len64							( m_axir_len64								),
		.m_axir_addr							( m_axir_addr								)
	);

endmodule