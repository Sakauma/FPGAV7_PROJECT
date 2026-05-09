 `timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			HXZY
// Engineer:		ZYL
// Create Date:		2018/5/11 19:40:24
// Design Name:		XR2000
// Module Name:		xr2000_axilite_top
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		模块用于组合AXI Lite Cross Bar&axi_lite_clock_conventor,分别输出两种时钟下的寄存器总线
//		1-->PCIe Clock模块的时钟
//		2-->Srio_log_clk模块的时钟
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module xr2000_axilite_top #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	---------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"									,
	parameter		P_AXILITE_CH_NUM_R			= 3
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--|clk-->可以连接master clk，也可以连接外部时钟，进行快速查询处理
	--|rst-->复位信号，高电平同步复位信号
	--------------------------------------------------------------------------------------*/
	input										rst											,
	input										slave_clk									,
	input			[P_AXILITE_CH_NUM_R-1:0]	master_clk									,
	
//==================================================================================================
//--master output
	/*--------------------------------------------------------------------------------------
	--Write Address Channel Signals
	--------------------------------------------------------------------------------------*/
	input			[32-1:0] 					slave_axi_awaddr							,
  	input			[3-1:0]						slave_axi_awprot							,
  	input			[1-1:0]						slave_axi_awvalid							,
  	output			[1-1:0]						slave_axi_awready							,

	/*--------------------------------------------------------------------------------------
	--Write Data Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[31:0]						slave_axi_wdata								,
  	input			[ 3:0]						slave_axi_wstrb								,
  	input										slave_axi_wvalid							,
  	output										slave_axi_wready							,

	/*--------------------------------------------------------------------------------------
	--Write Response Channel Signals
	--------------------------------------------------------------------------------------*/
  	output			[ 1:0]						slave_axi_bresp								,
  	output										slave_axi_bvalid							,
  	input										slave_axi_bready							,

	/*--------------------------------------------------------------------------------------
	--Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[31:0]						slave_axi_araddr							,
  	input			[ 2:0]						slave_axi_arprot							,
  	input										slave_axi_arvalid							,
  	output										slave_axi_arready							,

	/*--------------------------------------------------------------------------------------
	--Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	output			[31:0]						slave_axi_rdata								,
  	output			[ 1:0]						slave_axi_rresp								,
  	output										slave_axi_rvalid							,
  	input										slave_axi_rready							,

//==================================================================================================
//--Master Clock通道定义
	/*--------------------------------------------------------------------------------------
	--Write Address Channel Signals
	--------------------------------------------------------------------------------------*/
	output			[P_AXILITE_CH_NUM_R*32-1:0] master_axi_awaddr							,
  	output			[P_AXILITE_CH_NUM_R* 3-1:0]	master_axi_awprot							,
  	output			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_awvalid							,
  	input			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_awready							,

  	output			[P_AXILITE_CH_NUM_R*32-1:0]	master_axi_wdata							,
  	output			[P_AXILITE_CH_NUM_R* 4-1:0]	master_axi_wstrb							,
  	output			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_wvalid							,
  	input			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_wready							,

  	input			[P_AXILITE_CH_NUM_R* 2-1:0]	master_axi_bresp							,
  	input			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_bvalid							,
  	output			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_bready							,

  	output			[P_AXILITE_CH_NUM_R*32-1:0]	master_axi_araddr							,
  	output			[P_AXILITE_CH_NUM_R* 3-1:0]	master_axi_arprot							,
  	output			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_arvalid							,
  	input			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_arready							,

  	input			[P_AXILITE_CH_NUM_R*32-1:0]	master_axi_rdata							,
  	input			[P_AXILITE_CH_NUM_R* 2-1:0]	master_axi_rresp							,
  	input			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_rvalid							,
  	output			[P_AXILITE_CH_NUM_R* 1-1:0]	master_axi_rready
	);
//==================================================================================================
//--axi_crossbar_0的Slave信号定义
 /**************** Write Address Channel Signals ****************/
	wire			[P_AXILITE_CH_NUM_R*32-1:0] s_axi_awaddr								;
	wire			[P_AXILITE_CH_NUM_R* 3-1:0]	s_axi_awprot								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_awvalid								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_awready								;
  /**************** Write Data Channel Signals ****************/
	wire			[P_AXILITE_CH_NUM_R*32-1:0]	s_axi_wdata									;
	wire			[P_AXILITE_CH_NUM_R* 4-1:0]	s_axi_wstrb									;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_wvalid								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_wready								;
  /**************** Write Response Channel Signals ****************/
	wire			[P_AXILITE_CH_NUM_R* 2-1:0]	s_axi_bresp									;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_bvalid								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_bready								;
  /**************** Read Address Channel Signals ****************/
	wire			[P_AXILITE_CH_NUM_R*32-1:0]	s_axi_araddr								;
	wire			[P_AXILITE_CH_NUM_R* 3-1:0]	s_axi_arprot								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_arvalid								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_arready								;
  /**************** Read Data Channel Signals ****************/
	wire			[P_AXILITE_CH_NUM_R*32-1:0]	s_axi_rdata									;
	wire			[P_AXILITE_CH_NUM_R* 2-1:0]	s_axi_rresp									;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_rvalid								;
	wire			[P_AXILITE_CH_NUM_R* 1-1:0]	s_axi_rready								;
//==================================================================================================
//--PCIe Clock AXI-Lite总线实现
	/*--------------------------------------------------------------------------------------
	--Write Address Channel Signals Chanenl 0 direct output
	--------------------------------------------------------------------------------------*/
//	assign	master_axi_awaddr	[0*32 +:32]		= s_axi_awaddr			[0*32 +:32]			;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_awprot	[0* 3 +: 3]		= s_axi_awprot          [0* 3 +: 3]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_awvalid	[0* 1 +: 1]		= s_axi_awvalid         [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//	assign	s_axi_awready		[0* 1 +: 1]		= master_axi_awready    [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//																				   				//	切换到	FST_CLK	时钟域			
//	assign	master_axi_wdata	[0*32 +:32]		= s_axi_wdata           [0*32 +:32]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_wstrb	[0* 4 +: 4]		= s_axi_wstrb           [0* 4 +: 4]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_wvalid	[0* 1 +: 1]		= s_axi_wvalid          [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//	assign	s_axi_wready		[0* 1 +: 1]		= master_axi_wready     [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//							                                                                    //	切换到	FST_CLK	时钟域
//	assign	s_axi_bresp			[0* 2 +: 2]		= master_axi_bresp      [0* 2 +: 2]         ;	//	切换到	FST_CLK	时钟域						
//	assign	s_axi_bvalid		[0* 1 +: 1]		= master_axi_bvalid     [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_bready	[0* 1 +: 1]		= s_axi_bready          [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//																				   				//	切换到	FST_CLK	时钟域			
//	assign	master_axi_araddr	[0*32 +:32]		= s_axi_araddr          [0*32 +:32]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_arprot	[0* 3 +: 3]		= s_axi_arprot          [0* 3 +: 3]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_arvalid	[0* 1 +: 1]		= s_axi_arvalid         [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//	assign	s_axi_arready		[0* 1 +: 1]		= master_axi_arready    [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//																				   				//	切换到	FST_CLK	时钟域			
//	assign	s_axi_rdata			[0*32 +:32]		= master_axi_rdata	    [0*32 +:32]         ;	//	切换到	FST_CLK	时钟域						
//	assign	s_axi_rresp			[0* 2 +: 2]		= master_axi_rresp	    [0* 2 +: 2]         ;	//	切换到	FST_CLK	时钟域						
//	assign	s_axi_rvalid		[0* 1 +: 1]		= master_axi_rvalid	    [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						
//	assign	master_axi_rready	[0* 1 +: 1]		= s_axi_rready          [0* 1 +: 1]         ;	//	切换到	FST_CLK	时钟域						


//==================================================================================================
//--AXI_LITE_Cross_bar Implement
generate if(P_AXILITE_CH_NUM_R==2) begin : CROSSBAR_G
	axi_crossbar_2	i_crossbar	(
		//**********************************************
		// DUT MASTER INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.m_axi_awaddr							( s_axi_awaddr								),
		.m_axi_awprot							( s_axi_awprot								),
		.m_axi_awvalid							( s_axi_awvalid								),
		.m_axi_awready							( s_axi_awready								),
		/**************** Write Data Channel Signals ****************/
		.m_axi_wdata							( s_axi_wdata								),
		.m_axi_wstrb							( s_axi_wstrb								),
		.m_axi_wvalid							( s_axi_wvalid								),
		.m_axi_wready							( s_axi_wready								),
		/**************** Write Response Channel Signals ****************/
		.m_axi_bresp							( s_axi_bresp								),
		.m_axi_bvalid							( s_axi_bvalid								),
		.m_axi_bready							( s_axi_bready								),
		/**************** Read Address Channel Signals ****************/
		.m_axi_araddr							( s_axi_araddr								),
		.m_axi_arprot							( s_axi_arprot								),
		.m_axi_arvalid							( s_axi_arvalid								),
		.m_axi_arready							( s_axi_arready								),
		/**************** Read Data Channel Signals ****************/
		.m_axi_rdata							( s_axi_rdata								),
		.m_axi_rresp							( s_axi_rresp								),
		.m_axi_rvalid							( s_axi_rvalid								),
		.m_axi_rready							( s_axi_rready								),

		//**********************************************
		// DUT SLAVE INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.s_axi_awaddr							( slave_axi_awaddr							),
		.s_axi_awprot							( slave_axi_awprot							),
		.s_axi_awvalid							( slave_axi_awvalid							),
		.s_axi_awready							( slave_axi_awready							),
		/**************** Write Data Channel Signals ****************/
		.s_axi_wdata							( slave_axi_wdata							),
		.s_axi_wstrb							( slave_axi_wstrb							),
		.s_axi_wvalid							( slave_axi_wvalid							),
		.s_axi_wready							( slave_axi_wready							),
		/**************** Write Response Channel Signals ****************/
		.s_axi_bresp							( slave_axi_bresp							),
		.s_axi_bvalid							( slave_axi_bvalid							),
		.s_axi_bready							( slave_axi_bready							),
		/**************** Read Address Channel Signals ****************/
		.s_axi_araddr							( slave_axi_araddr							),
		.s_axi_arprot							( slave_axi_arprot							),
		.s_axi_arvalid							( slave_axi_arvalid							),
		.s_axi_arready							( slave_axi_arready							),
		/**************** Read Data Channel Signals ****************/
		.s_axi_rdata							( slave_axi_rdata							),
		.s_axi_rresp							( slave_axi_rresp							),
		.s_axi_rvalid							( slave_axi_rvalid							),
		.s_axi_rready							( slave_axi_rready							),

		/**************** System Signals ****************/
		.aclk									( slave_clk									),
		.aresetn								( ~rst										)
	);
end else if(P_AXILITE_CH_NUM_R==3) begin : CROSSBAR_G
	axi_crossbar_3	i_crossbar	(
		//**********************************************
		// DUT MASTER INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.m_axi_awaddr							( s_axi_awaddr								),
		.m_axi_awprot							( s_axi_awprot								),
		.m_axi_awvalid							( s_axi_awvalid								),
		.m_axi_awready							( s_axi_awready								),
		/**************** Write Data Channel Signals ****************/
		.m_axi_wdata							( s_axi_wdata								),
		.m_axi_wstrb							( s_axi_wstrb								),
		.m_axi_wvalid							( s_axi_wvalid								),
		.m_axi_wready							( s_axi_wready								),
		/**************** Write Response Channel Signals ****************/
		.m_axi_bresp							( s_axi_bresp								),
		.m_axi_bvalid							( s_axi_bvalid								),
		.m_axi_bready							( s_axi_bready								),
		/**************** Read Address Channel Signals ****************/
		.m_axi_araddr							( s_axi_araddr								),
		.m_axi_arprot							( s_axi_arprot								),
		.m_axi_arvalid							( s_axi_arvalid								),
		.m_axi_arready							( s_axi_arready								),
		/**************** Read Data Channel Signals ****************/
		.m_axi_rdata							( s_axi_rdata								),
		.m_axi_rresp							( s_axi_rresp								),
		.m_axi_rvalid							( s_axi_rvalid								),
		.m_axi_rready							( s_axi_rready								),

		//**********************************************
		// DUT SLAVE INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.s_axi_awaddr							( slave_axi_awaddr							),
		.s_axi_awprot							( slave_axi_awprot							),
		.s_axi_awvalid							( slave_axi_awvalid							),
		.s_axi_awready							( slave_axi_awready							),
		/**************** Write Data Channel Signals ****************/
		.s_axi_wdata							( slave_axi_wdata							),
		.s_axi_wstrb							( slave_axi_wstrb							),
		.s_axi_wvalid							( slave_axi_wvalid							),
		.s_axi_wready							( slave_axi_wready							),
		/**************** Write Response Channel Signals ****************/
		.s_axi_bresp							( slave_axi_bresp							),
		.s_axi_bvalid							( slave_axi_bvalid							),
		.s_axi_bready							( slave_axi_bready							),
		/**************** Read Address Channel Signals ****************/
		.s_axi_araddr							( slave_axi_araddr							),
		.s_axi_arprot							( slave_axi_arprot							),
		.s_axi_arvalid							( slave_axi_arvalid							),
		.s_axi_arready							( slave_axi_arready							),
		/**************** Read Data Channel Signals ****************/
		.s_axi_rdata							( slave_axi_rdata							),
		.s_axi_rresp							( slave_axi_rresp							),
		.s_axi_rvalid							( slave_axi_rvalid							),
		.s_axi_rready							( slave_axi_rready							),

		/**************** System Signals ****************/
		.aclk									( slave_clk									),
		.aresetn								( ~rst										)
	);
end else if(P_AXILITE_CH_NUM_R==4) begin : CROSSBAR_G
	axi_crossbar_4	i_crossbar	(
		//**********************************************
		// DUT MASTER INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.m_axi_awaddr							( s_axi_awaddr								),
		.m_axi_awprot							( s_axi_awprot								),
		.m_axi_awvalid							( s_axi_awvalid								),
		.m_axi_awready							( s_axi_awready								),
		/**************** Write Data Channel Signals ****************/
		.m_axi_wdata							( s_axi_wdata								),
		.m_axi_wstrb							( s_axi_wstrb								),
		.m_axi_wvalid							( s_axi_wvalid								),
		.m_axi_wready							( s_axi_wready								),
		/**************** Write Response Channel Signals ****************/
		.m_axi_bresp							( s_axi_bresp								),
		.m_axi_bvalid							( s_axi_bvalid								),
		.m_axi_bready							( s_axi_bready								),
		/**************** Read Address Channel Signals ****************/
		.m_axi_araddr							( s_axi_araddr								),
		.m_axi_arprot							( s_axi_arprot								),
		.m_axi_arvalid							( s_axi_arvalid								),
		.m_axi_arready							( s_axi_arready								),
		/**************** Read Data Channel Signals ****************/
		.m_axi_rdata							( s_axi_rdata								),
		.m_axi_rresp							( s_axi_rresp								),
		.m_axi_rvalid							( s_axi_rvalid								),
		.m_axi_rready							( s_axi_rready								),

		//**********************************************
		// DUT SLAVE INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.s_axi_awaddr							( slave_axi_awaddr							),
		.s_axi_awprot							( slave_axi_awprot							),
		.s_axi_awvalid							( slave_axi_awvalid							),
		.s_axi_awready							( slave_axi_awready							),
		/**************** Write Data Channel Signals ****************/
		.s_axi_wdata							( slave_axi_wdata							),
		.s_axi_wstrb							( slave_axi_wstrb							),
		.s_axi_wvalid							( slave_axi_wvalid							),
		.s_axi_wready							( slave_axi_wready							),
		/**************** Write Response Channel Signals ****************/
		.s_axi_bresp							( slave_axi_bresp							),
		.s_axi_bvalid							( slave_axi_bvalid							),
		.s_axi_bready							( slave_axi_bready							),
		/**************** Read Address Channel Signals ****************/
		.s_axi_araddr							( slave_axi_araddr							),
		.s_axi_arprot							( slave_axi_arprot							),
		.s_axi_arvalid							( slave_axi_arvalid							),
		.s_axi_arready							( slave_axi_arready							),
		/**************** Read Data Channel Signals ****************/
		.s_axi_rdata							( slave_axi_rdata							),
		.s_axi_rresp							( slave_axi_rresp							),
		.s_axi_rvalid							( slave_axi_rvalid							),
		.s_axi_rready							( slave_axi_rready							),

		/**************** System Signals ****************/
		.aclk									( slave_clk									),
		.aresetn								( ~rst										)
	);
end else if(P_AXILITE_CH_NUM_R==6) begin : CROSSBAR_G
	axi_crossbar_6	i_crossbar	(
		//**********************************************
		// DUT MASTER INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.m_axi_awaddr							( s_axi_awaddr								),
		.m_axi_awprot							( s_axi_awprot								),
		.m_axi_awvalid							( s_axi_awvalid								),
		.m_axi_awready							( s_axi_awready								),
		/**************** Write Data Channel Signals ****************/
		.m_axi_wdata							( s_axi_wdata								),
		.m_axi_wstrb							( s_axi_wstrb								),
		.m_axi_wvalid							( s_axi_wvalid								),
		.m_axi_wready							( s_axi_wready								),
		/**************** Write Response Channel Signals ****************/
		.m_axi_bresp							( s_axi_bresp								),
		.m_axi_bvalid							( s_axi_bvalid								),
		.m_axi_bready							( s_axi_bready								),
		/**************** Read Address Channel Signals ****************/
		.m_axi_araddr							( s_axi_araddr								),
		.m_axi_arprot							( s_axi_arprot								),
		.m_axi_arvalid							( s_axi_arvalid								),
		.m_axi_arready							( s_axi_arready								),
		/**************** Read Data Channel Signals ****************/
		.m_axi_rdata							( s_axi_rdata								),
		.m_axi_rresp							( s_axi_rresp								),
		.m_axi_rvalid							( s_axi_rvalid								),
		.m_axi_rready							( s_axi_rready								),

		//**********************************************
		// DUT SLAVE INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.s_axi_awaddr							( slave_axi_awaddr							),
		.s_axi_awprot							( slave_axi_awprot							),
		.s_axi_awvalid							( slave_axi_awvalid							),
		.s_axi_awready							( slave_axi_awready							),
		/**************** Write Data Channel Signals ****************/
		.s_axi_wdata							( slave_axi_wdata							),
		.s_axi_wstrb							( slave_axi_wstrb							),
		.s_axi_wvalid							( slave_axi_wvalid							),
		.s_axi_wready							( slave_axi_wready							),
		/**************** Write Response Channel Signals ****************/
		.s_axi_bresp							( slave_axi_bresp							),
		.s_axi_bvalid							( slave_axi_bvalid							),
		.s_axi_bready							( slave_axi_bready							),
		/**************** Read Address Channel Signals ****************/
		.s_axi_araddr							( slave_axi_araddr							),
		.s_axi_arprot							( slave_axi_arprot							),
		.s_axi_arvalid							( slave_axi_arvalid							),
		.s_axi_arready							( slave_axi_arready							),
		/**************** Read Data Channel Signals ****************/
		.s_axi_rdata							( slave_axi_rdata							),
		.s_axi_rresp							( slave_axi_rresp							),
		.s_axi_rvalid							( slave_axi_rvalid							),
		.s_axi_rready							( slave_axi_rready							),

		/**************** System Signals ****************/
		.aclk									( slave_clk									),
		.aresetn								( ~rst										)
	);
end
endgenerate


//==================================================================================================
//--
genvar i;
//	generate for (i=1;i<P_AXILITE_CH_NUM_R;i=i+1) begin: CONVERTER_G
generate for (i=0;i<P_AXILITE_CH_NUM_R;i=i+1) begin: CONVERTER_G	//	pcie时钟域与FST时钟域
	axi_clock_converter_0	i_clock_converter (
		//**********************************************
		// DUT SLAVE INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.s_axi_awaddr							( s_axi_awaddr		 	[i*32 +: 32]		),
		.s_axi_awprot							( s_axi_awprot       	[i* 3 +:  3]		),
		.s_axi_awvalid							( s_axi_awvalid      	[i* 1 +:  1]		),
		.s_axi_awready							( s_axi_awready      	[i* 1 +:  1]		),
                                                                     	
		.s_axi_wdata							( s_axi_wdata        	[i*32 +: 32]		),
		.s_axi_wstrb							( s_axi_wstrb        	[i* 4 +:  4]		),
		.s_axi_wvalid							( s_axi_wvalid       	[i* 1 +:  1]		),
		.s_axi_wready							( s_axi_wready       	[i* 1 +:  1]		),
                                                                     	
		.s_axi_bresp							( s_axi_bresp        	[i* 2 +:  2]		),
		.s_axi_bvalid							( s_axi_bvalid       	[i* 1 +:  1]		),
		.s_axi_bready							( s_axi_bready       	[i* 1 +:  1]		),
                                                                     	
		.s_axi_araddr							( s_axi_araddr       	[i*32 +: 32]		),
		.s_axi_arprot							( s_axi_arprot       	[i* 3 +:  3]		),
		.s_axi_arvalid							( s_axi_arvalid      	[i* 1 +:  1]		),
		.s_axi_arready							( s_axi_arready      	[i* 1 +:  1]		),
                                                                     	
		.s_axi_rdata							( s_axi_rdata        	[i*32 +: 32]		),
		.s_axi_rresp							( s_axi_rresp        	[i* 2 +:  2]		),
		.s_axi_rvalid							( s_axi_rvalid       	[i* 1 +:  1]		),
		.s_axi_rready							( s_axi_rready       	[i* 1 +:  1]		),
		                                                             	
		.s_axi_aclk								( slave_clk			 						),
		.s_axi_aresetn							( ~rst										),

		//**********************************************
		// DUT MASTER INTERFACE
		//**********************************************
		/**************** Write Address Channel Signals ****************/
		.m_axi_awaddr							( master_axi_awaddr		[i*32 +: 32]		),
		.m_axi_awprot							( master_axi_awprot		[i* 3 +:  3]		),
		.m_axi_awvalid							( master_axi_awvalid	[i* 1 +:  1]		),
		.m_axi_awready							( master_axi_awready	[i* 1 +:  1]		),
		            
		.m_axi_wdata							( master_axi_wdata		[i*32 +: 32]		),
		.m_axi_wstrb							( master_axi_wstrb		[i* 4 +:  4]		),
		.m_axi_wvalid							( master_axi_wvalid		[i* 1 +:  1]		),
		.m_axi_wready							( master_axi_wready		[i* 1 +:  1]		),
		
		.m_axi_bresp							( master_axi_bresp		[i* 2 +:  2]		),
		.m_axi_bvalid							( master_axi_bvalid		[i* 1 +:  1]		),
		.m_axi_bready							( master_axi_bready		[i* 1 +:  1]		),
		
		.m_axi_araddr							( master_axi_araddr		[i*32 +: 32]		),
		.m_axi_arprot							( master_axi_arprot		[i* 3 +:  3]		),
		.m_axi_arvalid							( master_axi_arvalid	[i* 1 +:  1]		),
		.m_axi_arready							( master_axi_arready	[i* 1 +:  1]		),
		
		.m_axi_rdata							( master_axi_rdata		[i*32 +: 32]		),
		.m_axi_rresp							( master_axi_rresp		[i* 2 +:  2]		),
		.m_axi_rvalid							( master_axi_rvalid		[i* 1 +:  1]		),
		.m_axi_rready							( master_axi_rready		[i* 1 +:  1]		),
		
		.m_axi_aclk								( master_clk			[i* 1 +:  1]		),
		.m_axi_aresetn							( ~rst										)
	);
end
endgenerate
endmodule
