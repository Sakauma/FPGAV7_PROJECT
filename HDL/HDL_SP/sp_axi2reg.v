`timescale 1ns/1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZYL
// Create Date:		2020/2/19 10:17:21
// Design Name:		IR2300
// Module Name:		mbus_master_host
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		This file implement mbus master state
// Dependencies:

// Revision:
// Revision 0.01 - File Created
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module sp_axi2reg #(
	/*--------------------------------------------------------------------------------------
	--SIMULATION
	---------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"
	)(
//==================================================================================================
//--input & output port declarations
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										rst											,
//==================================================================================================
//--AXI Lite¼Ä´æÆ÷·½Ïò
	/*--------------------------------------------------------------------------------------
	--Write Data Command Signals
	--------------------------------------------------------------------------------------*/
	input			[31:0]						sys_axi_awaddr								,
  	input			[ 2:0]						sys_axi_awprot								,
  	input										sys_axi_awvalid								,
  	output										sys_axi_awready								,

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
  	output	reg									sys_axi_bvalid				= 0				,
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
  	output	wire	[31:0]						sys_axi_rdata								,
  	output			[ 1:0]						sys_axi_rresp								,
  	output	reg									sys_axi_rvalid				= 0				,
  	input										sys_axi_rready								,
	
	/*--------------------------------------------------------------------------------------
	--regfile signals output
	--------------------------------------------------------------------------------------*/	  	
	output	reg		[31:0]						reg_waddr					= 0				,
	output	reg									reg_wvalid					= 0				,
	output	reg		[31:0]						reg_wdata					= 0				,
	
	output	reg		[31:0]						reg_raddr					= 0				,
	input			[31:0]						reg_rdata

	);
//==================================================================================================
//--Signals decalarations
	reg											aw_valid					= 0				;
  
//==================================================================================================
//--axi_lite to regfile write
	always @(posedge clk) begin
		if(reg_wvalid==1'b1) begin
			aw_valid							<= 1'b0										;
		end else if(sys_axi_awvalid && sys_axi_awready) begin
			aw_valid							<= 1'b1										;
		end else begin
			aw_valid							<= aw_valid									;
		end
	end
	
	always @(posedge clk) begin
		if(reg_wvalid==1'b1) begin
			reg_wvalid							<= 1'b0										;
		end else if(sys_axi_wvalid && sys_axi_wready && (aw_valid||(sys_axi_awvalid && sys_axi_awready))) begin
			reg_wvalid							<= 1'b1										;
		end else begin
			reg_wvalid							<= reg_wvalid								;
		end
	end
	
	always @(posedge clk) begin
		if(sys_axi_awvalid && sys_axi_awready) begin
			reg_waddr							<= sys_axi_awaddr[15:0]						;
		end else begin
			reg_waddr							<= reg_waddr								;
		end
	end
	
	always @(posedge clk) begin
		if(sys_axi_wvalid && sys_axi_wready) begin
			reg_wdata							<= sys_axi_wdata							;
		end else begin
			reg_wdata							<= reg_wdata								;
		end
	end
	
	always @(posedge clk) begin
		if(sys_axi_bvalid && sys_axi_bready) begin
			sys_axi_bvalid						<= 1'b0										;
		end else if(sys_axi_wvalid && sys_axi_wready) begin
			sys_axi_bvalid						<= 1'b1										;
		end else begin
			sys_axi_bvalid						<= sys_axi_bvalid							;
		end
	end
	
	assign	sys_axi_awready						= 1'b1										;
	assign	sys_axi_wready						= 1'b1										;
	assign	sys_axi_bresp						= 2'b00										;
	
//==================================================================================================
//--axi_lite to regfile read
	reg											reg_rvalid					= 0				;
	
	always @(posedge clk) begin
		reg_rvalid								<= sys_axi_arvalid && sys_axi_arready		;
	end

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			sys_axi_rvalid						<= 1'b0										;
		end else if(sys_axi_rvalid && sys_axi_rready) begin
			sys_axi_rvalid						<= 1'b0										;
		end else if(reg_rvalid) begin
			sys_axi_rvalid						<= 1'b1										;
		end else begin
			sys_axi_rvalid						<= sys_axi_rvalid							;
		end
	end
	
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			reg_raddr							<= 12'b0									;
		end else if(sys_axi_arvalid && sys_axi_arready) begin
			reg_raddr							<= sys_axi_araddr							;
		end else begin
			reg_raddr							<= reg_raddr								;
		end
	end 
	
	assign	sys_axi_rdata						= reg_rdata									;

	assign	sys_axi_rresp						= 2'b00										; 
	assign	sys_axi_arready						= 1'b1										;
	assign	sys_axi_rresp						= 2'b00										;

endmodule