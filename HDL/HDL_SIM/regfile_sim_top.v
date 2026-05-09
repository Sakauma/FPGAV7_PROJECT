 `timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			HXZY
// Engineer:		ZYL
// Create Date:		2018/5/11 19:40:24
// Design Name:		XR2000
// Module Name:		xr2000_regfile_pcie
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		PCIe时钟下的寄存器读写模块
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module regfile_sim_top #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	---------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"									,

	parameter		P_Srio_CH_NUM_R				= 32'h0000_0002								,
	parameter		P_Srio_CAP_R				= 32'h0000_0001								,
	parameter		P_Srio_ID_WTH_R				= 32'h0000_0008								,
	parameter		P_Srio_SPEED_R				= 32'h0000_0001								,
	parameter		P_Srio_BANK_R				= 32'h0000_0000								,
	parameter		P_Board_MEM_SIZE_R			= 32'hFFFF_FFFF								,

	parameter		P_Srio_CH0_R				= 32'h0100_0001								,
	parameter		P_Srio_CH1_R				= 32'hFFFF_FFFF								,
	parameter		P_Srio_CH2_R				= 32'hFFFF_FFFF								,
	parameter		P_Srio_CH3_R				= 32'hFFFF_FFFF								,
	parameter		P_Srio_CH4_R				= 32'hFFFF_FFFF								,
	parameter		P_Srio_CH5_R				= 32'hFFFF_FFFF								,
	parameter		P_Srio_CH6_R				= 32'hFFFF_FFFF								,
	parameter		P_Srio_CH7_R				= 32'hFFFF_FFFF
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--|clk-->可以连接log_clk，也可以连接外部时钟，进行快速查询处理
	--|rst-->复位信号，高电平同步复位信号
	--------------------------------------------------------------------------------------*/
	input										rst											,
	input										clk											,

	/*--------------------------------------------------------------------------------------
	--Write Address Channel Signals
	--------------------------------------------------------------------------------------*/
	input			[32-1:0] 					sys_axi_awaddr								,
  	input			[3-1:0]						sys_axi_awprot								,
  	input			[1-1:0]						sys_axi_awvalid								,
  	output			[1-1:0]						sys_axi_awready								,

	/*--------------------------------------------------------------------------------------
	--Write Data Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[31:0]						sys_axi_wdata								,
  	input			[ 3:0]						sys_axi_wstrb								,
  	input										sys_axi_wvalid								,
  	output										sys_axi_wready								,

	/*--------------------------------------------------------------------------------------
	--Write Response Channel Signals
	--------------------------------------------------------------------------------------*/
  	output			[ 1:0]						sys_axi_bresp								,
  	output										sys_axi_bvalid								,
  	input										sys_axi_bready								,

	/*--------------------------------------------------------------------------------------
	--Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[31:0]						sys_axi_araddr								,
  	input			[ 2:0]						sys_axi_arprot								,
  	input										sys_axi_arvalid								,
  	output	wire								sys_axi_arready								,

	/*--------------------------------------------------------------------------------------
	--Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	output			[31:0]						sys_axi_rdata								,
  	output			[ 1:0]						sys_axi_rresp								,
  	output										sys_axi_rvalid								,
  	input										sys_axi_rready								,
  	
  	/*--------------------------------------------------------------------------------------
	--Timestamp out
	--------------------------------------------------------------------------------------*/	
	output	wire	[63:0]						c_bm_timestamp								,
	output	wire								c_bm_timestamp_rf							,
	
	/*--------------------------------------------------------------------------------------
	--BM Count in
	--------------------------------------------------------------------------------------*/	
	input			[31:0]						c_bm_up_cnt									,
	output			[31:0]						dma_size_set								,
	output			[31:0]						dma_wait_set								,
  	
  	/*--------------------------------------------------------------------------------------
	--DDR3 user for DN
	--------------------------------------------------------------------------------------*/	
	output			[31:0]						reg_ch0_mem_addr_c							,
	output			[31:0]						reg_ch0_mem_size_c							,
	output			[31:0]						reg_ch1_mem_addr_c							,
	output			[31:0]						reg_ch1_mem_size_c							,
	output			[31:0]						reg_ch2_mem_addr_c							,
	output			[31:0]						reg_ch2_mem_size_c							,
	output			[31:0]						reg_ch3_mem_addr_c							,
	output			[31:0]						reg_ch3_mem_size_c							,
	output			[31:0]						reg_ch4_mem_addr_c							,
	output			[31:0]						reg_ch4_mem_size_c							,
	output			[31:0]						reg_ch5_mem_addr_c							,
	output			[31:0]						reg_ch5_mem_size_c							,
	output			[31:0]						reg_ch6_mem_addr_c							,
	output			[31:0]						reg_ch6_mem_size_c							,
	output			[31:0]						reg_ch7_mem_addr_c							,
	output			[31:0]						reg_ch7_mem_size_c							,
  	
  	/*--------------------------------------------------------------------------------------
	--DMA Channel Cache Packet Count
	--------------------------------------------------------------------------------------*/	
	input			[8*32-1:0]					c_sp_up_cnt									,
	input			[8*32-1:0]					c_sp_dn_cnt						
	);
	
//==================================================================================================
//--zt_axi2reg Instantation
	wire										reg_wvalid									;
	wire			[31:0]						reg_waddr									;
	wire			[31:0]						reg_wdata									;
	
	wire			[31:0]						reg_raddr									;
	wire			[31:0]						reg_rdata									;

	sp_axi2reg	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_pcie_axi2reg (
		.clk									( clk										),
		.rst									( rst										),
		
		.sys_axi_awaddr							( sys_axi_awaddr							),
		.sys_axi_awprot							( sys_axi_awprot							),
		.sys_axi_awvalid						( sys_axi_awvalid							),
		.sys_axi_awready						( sys_axi_awready							),
		.sys_axi_wdata							( sys_axi_wdata								),
		.sys_axi_wstrb							( sys_axi_wstrb								),
		.sys_axi_wvalid							( sys_axi_wvalid							),
		.sys_axi_wready							( sys_axi_wready							),
		.sys_axi_bresp							( sys_axi_bresp								),
		.sys_axi_bvalid							( sys_axi_bvalid							),
		.sys_axi_bready							( sys_axi_bready							),
		.sys_axi_araddr							( sys_axi_araddr							),
		.sys_axi_arprot							( sys_axi_arprot							),
		.sys_axi_arvalid						( sys_axi_arvalid							),
		.sys_axi_arready						( sys_axi_arready							),
		.sys_axi_rdata							( sys_axi_rdata								),
		.sys_axi_rresp							( sys_axi_rresp								),
		.sys_axi_rvalid							( sys_axi_rvalid							),
		.sys_axi_rready							( sys_axi_rready							),
		
		.reg_waddr								( reg_waddr									),
		.reg_wvalid								( reg_wvalid								),
		.reg_wdata								( reg_wdata									),
		.reg_raddr								( reg_raddr									),
		.reg_rdata								( reg_rdata									)
	);	
	
//==================================================================================================
//--xr2000_regfile_pcie Instantation
	regfile_sim_reg	#(
		.P_SIMULATION_R				            ( P_SIMULATION_R							),
		.P_Srio_CH_NUM_R			            ( P_Srio_CH_NUM_R			    			),
		.P_Srio_CAP_R				            ( P_Srio_CAP_R				    			),
		.P_Srio_ID_WTH_R			            ( P_Srio_ID_WTH_R			    			),
		.P_Srio_SPEED_R				            ( P_Srio_SPEED_R							),
		.P_Srio_BANK_R							( P_Srio_BANK_R								),
		.P_Board_MEM_SIZE_R						( P_Board_MEM_SIZE_R						),

		.P_Srio_CH0_R				            ( P_Srio_CH0_R				    			),
		.P_Srio_CH1_R				            ( P_Srio_CH1_R				    			),
		.P_Srio_CH2_R				            ( P_Srio_CH2_R				    			),
		.P_Srio_CH3_R				            ( P_Srio_CH3_R				    			),
		.P_Srio_CH4_R				            ( P_Srio_CH4_R				    			),
		.P_Srio_CH5_R				            ( P_Srio_CH5_R				    			),
		.P_Srio_CH6_R				            ( P_Srio_CH6_R				    			),
		.P_Srio_CH7_R							( P_Srio_CH7_R				    			)
	)
	i_regfile_pcie (
		.rst									( rst										),
		.clk									( clk										),
		
		.reg_waddr								( reg_waddr									),
		.reg_wvalid								( reg_wvalid								),
		.reg_wdata								( reg_wdata									),
		.reg_raddr								( reg_raddr									),
		.reg_rdata								( reg_rdata									),  
		
		.c_bm_timestamp							( c_bm_timestamp							),
		.c_bm_timestamp_rf						( c_bm_timestamp_rf							),
		.c_bm_up_cnt							( c_bm_up_cnt								),
		.dma_size_set							( dma_size_set								),
		.dma_wait_set							( dma_wait_set								),
		
		.reg_ch0_mem_addr_c						( reg_ch0_mem_addr_c						),
		.reg_ch0_mem_size_c						( reg_ch0_mem_size_c						),
		.reg_ch1_mem_addr_c						( reg_ch1_mem_addr_c						),
		.reg_ch1_mem_size_c						( reg_ch1_mem_size_c						),
		.reg_ch2_mem_addr_c						( reg_ch2_mem_addr_c						),
		.reg_ch2_mem_size_c						( reg_ch2_mem_size_c						),
		.reg_ch3_mem_addr_c						( reg_ch3_mem_addr_c						),
		.reg_ch3_mem_size_c						( reg_ch3_mem_size_c						),
		.reg_ch4_mem_addr_c						( reg_ch4_mem_addr_c						),
		.reg_ch4_mem_size_c						( reg_ch4_mem_size_c						),
		.reg_ch5_mem_addr_c						( reg_ch5_mem_addr_c						),
		.reg_ch5_mem_size_c						( reg_ch5_mem_size_c						),
		.reg_ch6_mem_addr_c						( reg_ch6_mem_addr_c						),
		.reg_ch6_mem_size_c						( reg_ch6_mem_size_c						),
		.reg_ch7_mem_addr_c						( reg_ch7_mem_addr_c						),
		.reg_ch7_mem_size_c						( reg_ch7_mem_size_c						),
		
		.c_sp_up_cnt							( c_sp_up_cnt								),
		.c_sp_dn_cnt							( c_sp_dn_cnt								)	
	);

endmodule