`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZhengYunLong
//
// Create Date:		2018/6/27 19:10:38
// Design Name:		
// Module Name:		zt_axiw_burst
// Project Name:
// Target Devices:	XC7k325T
// Tool Versions: 	Vivado 2016.1
// Description:
//		模块实现基于AXI4接口的Burst写操作
// Dependencies:
//		
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module zt_axi_wburst #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	--------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"			
	)(
//==================================================================================================
//--Comman Interface
	input										clk											,
	input										rst											,
//==================================================================================================
//--Master AXI4写接口
	output	wire	[3:0]						M_AXI_AWID									,
	(*mark_debug="TRUE"*)
	output	reg		[31:0]						M_AXI_AWADDR					= 0			,
	(*mark_debug="TRUE"*)
	output	reg		[7:0]						M_AXI_AWLEN						= 0			,
	output	wire	[2:0]						M_AXI_AWSIZE								,
	output	wire	[1:0]						M_AXI_AWBURST								,
	output	wire								M_AXI_AWLOCK								,
	output	wire	[3:0]						M_AXI_AWCACHE								,
	output	wire	[2:0]						M_AXI_AWPROT								,
	output	wire	[3:0]						M_AXI_AWQOS									,
	(*mark_debug="TRUE"*)
	output	wire								M_AXI_AWVALID								,
	(*mark_debug="TRUE"*)
	input	wire								M_AXI_AWREADY								,
	output	wire	[63:0]						M_AXI_WDATA									,
	output	wire	[7:0]						M_AXI_WSTRB									,
	(*mark_debug="TRUE"*)
	output	wire								M_AXI_WLAST									,
	(*mark_debug="TRUE"*)
	output	wire								M_AXI_WVALID								,
	(*mark_debug="TRUE"*)
	input	wire								M_AXI_WREADY								,
	input	wire	[3:0]						M_AXI_BID									,
	input	wire	[1:0]						M_AXI_BRESP									,
	(*mark_debug="TRUE"*)
	input	wire								M_AXI_BVALID								,
	(*mark_debug="TRUE"*)
	output	wire								M_AXI_BREADY								,

//==================================================================================================
//--写请求接口
	input										m_axiw_req									,
	output	wire								m_axiw_gnt									,
	input			[10:0]						m_axiw_len64								,
	input			[31:0]						m_axiw_addr									,
	input			[7:0]						m_axiw_wstrb								,	//仅当最后一个64比特数据有效，用于OnlyOne模式
	
	input			[63:0]						m_axiw_fifo_rdata							,
	input										m_axiw_fifo_empty							,
	output										m_axiw_fifo_rden
	);
//==================================================================================================
//--参数定义
	localparam		[10:0]						PR_AXI_BURST				= 11'd64		;

//==================================================================================================
//--信号定义
	reg				[5:0]						S_AXI_CM									;
	reg				[5:0]						S_AXI_NM									;
	
	
	reg											axi_last					= 0 			;
	reg				[10:0]						axi_cnt						= 0				;
	reg				[10:0]						axi_len						= 0				;

	localparam									S_AXI_IDLE_M				= 6'b00_0001	;
	localparam									S_AXI_SLICE_M				= 6'b00_0010	;
	localparam									S_AXI_AW_M					= 6'b00_0100	;
	localparam									S_AXI_W_M					= 6'b00_1000	;
	localparam									S_AXI_B_M					= 6'b01_0000	;
	localparam									S_AXI_DONE_M				= 6'b10_0000	;
//==================================================================================================
//--状态机实现
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_AXI_CM							<= S_AXI_IDLE_M								;
		end else begin
			S_AXI_CM							<= S_AXI_NM									;
		end
	end
	
	always @(*) begin
		S_AXI_NM								= 'bx										;
		case(S_AXI_CM)
			S_AXI_IDLE_M						: begin
				if(m_axiw_req) begin
					S_AXI_NM					= S_AXI_SLICE_M								;
				end else begin
					S_AXI_NM					= S_AXI_IDLE_M								;
				end
			end
			S_AXI_SLICE_M						: begin
				S_AXI_NM						= S_AXI_AW_M								;
			end
			S_AXI_AW_M							: begin
				if(M_AXI_AWREADY && M_AXI_AWVALID) begin
					S_AXI_NM					= S_AXI_W_M									;
				end else begin
					S_AXI_NM					= S_AXI_AW_M								;
				end
			end
			S_AXI_W_M							: begin
				if(M_AXI_WREADY && M_AXI_WVALID && M_AXI_WLAST) begin
					S_AXI_NM					= S_AXI_B_M									;
				end else begin
					S_AXI_NM					= S_AXI_W_M									;
				end
			end
			S_AXI_B_M							: begin
				if(M_AXI_BVALID && M_AXI_BREADY) begin
					if(axi_last) begin
						S_AXI_NM				= S_AXI_DONE_M								;
					end else begin
						S_AXI_NM				= S_AXI_SLICE_M								;
					end
				end else begin
					S_AXI_NM					= S_AXI_B_M									;
				end
			end
			S_AXI_DONE_M						: begin
				S_AXI_NM						= S_AXI_IDLE_M								;
			end
			default								: begin
				S_AXI_NM						= S_AXI_IDLE_M								;
			end
		endcase
	end
	
	/*--------------------------------------------------------------------------------------
	--AXI_LEN实现
	--------------------------------------------------------------------------------------*/	
	always @(posedge clk) begin
		case(S_AXI_CM)
			S_AXI_IDLE_M						: begin
				axi_len							<= m_axiw_len64								;
				axi_last						<= 1'b0										;
			end
			S_AXI_SLICE_M						: begin
				if(axi_len>PR_AXI_BURST) begin
					axi_len						<= axi_len - PR_AXI_BURST					;
					axi_last					<= 1'b0										;
				end else begin
					axi_len						<= axi_len									;
					axi_last					<= 1'b1										;
				end
			end
			S_AXI_DONE_M						: begin
				axi_len							<= 11'b0									;
				axi_last						<= 1'b0										;
			end
			default								: begin
				axi_len							<= axi_len									;
				axi_last						<= axi_last									;
			end
		endcase
	end
	
	/*--------------------------------------------------------------------------------------
	--AXI_CNT计数器实现
	--------------------------------------------------------------------------------------*/	
	always @(posedge clk) begin
		if(S_AXI_CM==S_AXI_W_M) begin
			if(M_AXI_WVALID && M_AXI_WREADY) begin
				axi_cnt							<= axi_cnt + 1'b1							;
			end else begin
				axi_cnt							<= axi_cnt									;
			end
		end else begin
			axi_cnt								<= 11'b0									;
		end
	end
	
//==================================================================================================
//--M_AXI_*信号实现
	always @(posedge clk) begin
		case(S_AXI_CM)
			S_AXI_IDLE_M						: begin
				M_AXI_AWADDR					<= m_axiw_addr								;
			end
			S_AXI_AW_M							: begin
				if(M_AXI_AWREADY & M_AXI_AWVALID & !axi_last) begin
					M_AXI_AWADDR				<= M_AXI_AWADDR + PR_AXI_BURST*8			;
				end else begin
					M_AXI_AWADDR				<= M_AXI_AWADDR								;
				end
			end
			default								: begin
				M_AXI_AWADDR					<= M_AXI_AWADDR								;
			end
		endcase
	end
	
	always @(posedge clk) begin
		case(S_AXI_CM)
			S_AXI_IDLE_M						: begin
				M_AXI_AWLEN						<= 8'b0										;
			end
			S_AXI_SLICE_M						: begin
				if(axi_len>PR_AXI_BURST) begin
					M_AXI_AWLEN					<= PR_AXI_BURST - 1'b1						;
				end else begin
					M_AXI_AWLEN					<= axi_len - 1'b1							;
				end
			end
			default								: begin
				M_AXI_AWLEN						<= M_AXI_AWLEN								;
			end
		endcase
	end
	
	assign	M_AXI_WSTRB							= (m_axiw_len64==1'b1)?m_axiw_wstrb:8'hFF	;
	assign	M_AXI_AWVALID						= (S_AXI_CM==S_AXI_AW_M)?1'b1:1'b0			;
	
	assign	M_AXI_WVALID						= (S_AXI_CM==S_AXI_W_M)?~m_axiw_fifo_empty:1'b0;
	assign	M_AXI_WDATA							= m_axiw_fifo_rdata							;
	assign	M_AXI_WLAST							= M_AXI_WVALID && axi_cnt==M_AXI_AWLEN		;

	assign	M_AXI_AWID							= 4'b0000									;
	assign	M_AXI_AWSIZE						= 3'b011									;	//64
	assign	M_AXI_AWBURST						= 2'b01										;	//00 FIXED 01 INCR 10 WRAP
	assign	M_AXI_AWLOCK						= 1'b0										;
	assign	M_AXI_AWPROT						= 3'b000									;
	assign	M_AXI_AWQOS							= 4'b0000									;	//MIG Slave Not used
	assign	M_AXI_BREADY						= (S_AXI_CM==S_AXI_B_M)?1'b1:1'b0			;
	assign	M_AXI_AWCACHE						= 4'b0000									;	
	
	assign	m_axiw_fifo_rden					= M_AXI_WVALID && M_AXI_WREADY				;
	assign	m_axiw_gnt							= (S_AXI_CM==S_AXI_DONE_M)?1'b1:1'b0		;

endmodule