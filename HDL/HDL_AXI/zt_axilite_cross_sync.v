`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZYL
// Create Date:		2019/12/10 14:18:46
// Design Name:		JC638C
// Module Name:		zt_axilite_cross
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		This implement sync axilite cross function.max channel is 16
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module zt_axilite_cross #(
	/*--------------------------------------------------------------------------------------
	--SIMULATION
	---------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"									,
	parameter		P_AXI_CHANNEL_R				= 12										,
	parameter		P_CH_LOW_BIT_R				= 12										,
	/*--------------------------------------------------------------------------------------
	--相对于low_bit的值，例如low_bit=12,则addr[15:12]为地址空间切换，如果addr>0，那么channel0
	--应为1，P-CH_Start_Addr_R就是用来匹配addr初始值（最小值）与通道sel(从0开始）不匹配的修正
	--------------------------------------------------------------------------------------*/	
	parameter		P_CH_Start_Addr_R			= 0										
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--clk & rst
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										rst											,
	/*--------------------------------------------------------------------------------------
	--Master Write Data Command Signals
	--------------------------------------------------------------------------------------*/
	input			[31:0]						sys_axi_awaddr								,
  	input			[ 2:0]						sys_axi_awprot								,
  	input										sys_axi_awvalid								,
  	output	reg									sys_axi_awready					= 0			,

	/*--------------------------------------------------------------------------------------
	--Master Write Data Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[31:0]						sys_axi_wdata								,
  	input			[ 3:0]						sys_axi_wstrb								,
  	input										sys_axi_wvalid								,
  	output	reg									sys_axi_wready					= 0			,

	/*--------------------------------------------------------------------------------------
	--Master Write Response Channel Signals
	--------------------------------------------------------------------------------------*/
  	output	reg		[ 1:0]						sys_axi_bresp					= 0			,
  	output	reg									sys_axi_bvalid					= 0			,
  	input										sys_axi_bready								,

	/*--------------------------------------------------------------------------------------
	--Master Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[31:0]						sys_axi_araddr								,
  	input			[ 2:0]						sys_axi_arprot								,
  	input										sys_axi_arvalid								,
  	output	reg									sys_axi_arready					= 0			,

	/*--------------------------------------------------------------------------------------
	--Master Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	output	reg		[31:0]						sys_axi_rdata					= 0			,
  	output	reg		[ 1:0]						sys_axi_rresp					= 0			,
  	output	reg									sys_axi_rvalid					= 0			,
  	input										sys_axi_rready								,

  	/*--------------------------------------------------------------------------------------
	--Slave Write Data Command Signals
	--------------------------------------------------------------------------------------*/
	output	reg		[P_AXI_CHANNEL_R*32-1:0]	s_axi_awaddr					= 0			,
  	output	reg		[P_AXI_CHANNEL_R*3-1 :0]	s_axi_awprot					= 0			,
  	output	reg		[P_AXI_CHANNEL_R*1-1 :0]	s_axi_awvalid					= 0			,
  	input			[P_AXI_CHANNEL_R*1-1 :0]	s_axi_awready								,

	/*--------------------------------------------------------------------------------------
	--Slave Write Data Channel Signals
	--------------------------------------------------------------------------------------*/
  	output	reg		[P_AXI_CHANNEL_R*32-1:0]	s_axi_wdata						= 0			,
  	output	reg		[P_AXI_CHANNEL_R*4-1 :0]	s_axi_wstrb						= 0			,
  	output	reg		[P_AXI_CHANNEL_R*1-1 :0]	s_axi_wvalid					= 0			,
  	input			[P_AXI_CHANNEL_R*1-1 :0]	s_axi_wready								,

	/*--------------------------------------------------------------------------------------
	--Slave Write Response Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[P_AXI_CHANNEL_R*2-1 :0]	s_axi_bresp									,
  	input			[P_AXI_CHANNEL_R*1-1 :0]	s_axi_bvalid								,
  	output	wire	[P_AXI_CHANNEL_R*1-1 :0]	s_axi_bready								,

	/*--------------------------------------------------------------------------------------
	--Slave Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	output	reg		[P_AXI_CHANNEL_R*32-1:0]	s_axi_araddr					= 0			,
  	output	reg		[P_AXI_CHANNEL_R*3-1 :0]	s_axi_arprot								,
  	output	reg		[P_AXI_CHANNEL_R*1-1 :0]	s_axi_arvalid					= 0			,
  	input	wire	[P_AXI_CHANNEL_R*1-1 :0]	s_axi_arready								,

	/*--------------------------------------------------------------------------------------
	--Slave Read Address Channel Signals
	--------------------------------------------------------------------------------------*/
  	input			[P_AXI_CHANNEL_R*32-1:0]	s_axi_rdata									,
  	input			[P_AXI_CHANNEL_R*2-1 :0]	s_axi_rresp									,
  	input			[P_AXI_CHANNEL_R*1-1 :0]	s_axi_rvalid								,
  	output			[P_AXI_CHANNEL_R*1-1 :0]	s_axi_rready					
	);
//==================================================================================================
//--Parameter Define
	/*--------------------------------------------------------------------------------------
	--AXI Lite Write State Parameter
	--------------------------------------------------------------------------------------*/
	localparam		S_W_IDLE_M					= 3'b001									;
	localparam		S_W_B_M						= 3'b010									;
	localparam		S_W_E_M						= 3'b100									;
	
	localparam		B_W_IDLE_M					= 2'd0										;
	localparam		B_W_B_M						= 2'd1										;
	localparam		B_W_E_M						= 2'd2										;

	/*--------------------------------------------------------------------------------------
	--AXI Lite read State parameter
	--------------------------------------------------------------------------------------*/
	localparam		S_R_IDLE_M					= 3'b001									;
	localparam		S_R_B_M						= 3'b010									;
	localparam		S_R_E_M						= 3'b100									;
	
	localparam		B_R_IDLE_M					= 2'd0										;
	localparam		B_R_B_M						= 2'd1										;
	localparam		B_R_E_M						= 2'd2										;

//==================================================================================================
//--Signals Define
	/*--------------------------------------------------------------------------------------
	--AXI Lite Write State
	--------------------------------------------------------------------------------------*/
	reg				[ 2:0]						S_W_CM										;
	reg				[ 3:0]						S_W_NM										;
	reg				[ 3:0]						s_w_sel							= 0			;
	
	reg											aw_pass							= 0			;
	reg											w_pass							= 0			;
	reg											b_pass							= 0			;

	reg											wvalid_lock						= 0			;

	/*--------------------------------------------------------------------------------------
	--AXI Lite Read State
	--------------------------------------------------------------------------------------*/
	reg				[ 3:0]						S_R_CM										;
	reg				[ 3:0]						S_R_NM										;
	reg				[ 3:0]						s_r_sel							= 0			;
	
	reg											ar_pass							= 0			;
	reg											r_pass							= 0			;

	reg											arvalid_lock					= 0			;

//==================================================================================================
//--Write Channel Arb
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_W_CM								<= S_W_IDLE_M								;
		end else begin
			S_W_CM								<= S_W_NM									;
		end
	end

	always @(*) begin
		S_W_NM									= S_W_IDLE_M								;
		case(S_W_CM)
			S_W_IDLE_M							: begin
				if(sys_axi_awvalid) begin
					if((sys_axi_awaddr[P_CH_LOW_BIT_R +: 4]-P_CH_Start_Addr_R) >= P_AXI_CHANNEL_R) begin
						S_W_NM					= S_W_E_M									;
					end else begin
						S_W_NM					= S_W_B_M									;
					end
				end else begin
					S_W_NM						= S_W_IDLE_M								;
				end
			end
			S_W_B_M								: begin
				if(sys_axi_bready && sys_axi_bvalid) begin
					S_W_NM						= S_W_IDLE_M								;
				end else begin
					S_W_NM						= S_W_B_M									;
				end
			end
			S_W_E_M								: begin
				if(sys_axi_bready && sys_axi_bvalid) begin
					S_W_NM						= S_W_IDLE_M								;
				end else begin
					S_W_NM						= S_W_E_M									;
				end
			end
			default								: begin
				S_W_NM							= S_W_IDLE_M								;
			end
		endcase
	end
//==================================================================================================
//--signals implement
	/*--------------------------------------------------------------------------------------
	--sel signals
	--------------------------------------------------------------------------------------*/		
	always @(posedge clk) begin
		if(S_W_CM[B_W_IDLE_M]) begin
			s_w_sel								<= sys_axi_awaddr[P_CH_LOW_BIT_R +: 4]	
												- P_CH_Start_Addr_R							;
		end else begin
			s_w_sel								<= s_w_sel									;
		end
	end
	/*--------------------------------------------------------------------------------------
	--S_W_B_M中的aw_pass/w_lock，表示已经给出过s_axi_awvalid/s_axi_wvalid
	--------------------------------------------------------------------------------------*/	
	always @(posedge clk) begin
		if(S_W_CM[B_W_B_M]) begin
			if(sys_axi_awvalid && sys_axi_awready) begin
				aw_pass							<= 1'b1										;
			end else begin
				aw_pass							<= aw_pass									;
			end
			
			if(sys_axi_wvalid && sys_axi_wready) begin
				w_pass							<= 1'b1										;
			end else begin
				w_pass							<= w_pass									;
			end
			
			if(sys_axi_bvalid && sys_axi_bready) begin
				b_pass							<= 1'b1										;
			end else begin
				b_pass							<= b_pass									;
			end
		end else begin
			aw_pass								<= 1'b0										;
			w_pass								<= 1'b0										;
			b_pass								<= 1'b0										;
		end
	end
	
	/*--------------------------------------------------------------------------------------
	--s_axi_awvalid implement
	--------------------------------------------------------------------------------------*/
	
	always @(posedge clk) begin
		if(S_W_CM[B_W_B_M]) begin
			if(aw_pass) begin
				s_axi_awvalid[s_w_sel]			<= 0										;
			end else begin
				s_axi_awvalid[s_w_sel]			<= sys_axi_awvalid 							;
			end
		end else begin
			s_axi_awvalid[s_w_sel]				<= 0										;
		end
	end

	always @(posedge clk) begin
		if(S_W_CM[B_W_B_M]) begin
			if(w_pass) begin
				s_axi_wvalid[s_w_sel]			<= 0										;
			end else begin
				s_axi_wvalid[s_w_sel]			<= sys_axi_wvalid							;
			end
		end else begin
			s_axi_wvalid[s_w_sel]				<= 0										;
		end
	end

	always @(*) begin
		if(S_W_CM[B_W_B_M]) begin
			sys_axi_awready						= s_axi_awready[s_w_sel]					;
		end else
		if(S_W_CM[B_W_E_M]) begin
			sys_axi_awready						= 1'b1										;
		end else begin
			sys_axi_awready						= 1'b0										;
		end
	end

	always @(*) begin
		if(S_W_CM[B_W_B_M]) begin
			sys_axi_wready						= s_axi_wready[s_w_sel]						;
		end else
		if(S_W_CM[B_W_E_M]) begin
			sys_axi_wready						= 1'b1										;
		end else begin
			sys_axi_wready						= 1'b0										;
		end
	end
	
	always @(posedge clk) begin
		if(S_W_CM[B_W_B_M]) begin
			sys_axi_bresp						<= s_axi_bresp[s_w_sel*2 +:2]				;
		end else begin
			sys_axi_bresp						<= 2'b00									;
		end
	end

	always @(posedge clk) begin
		if(S_W_CM[B_W_B_M]) begin
			if((sys_axi_bvalid && sys_axi_bready) || b_pass) begin
				sys_axi_bvalid					<= 1'b0										;
			end else begin
				sys_axi_bvalid					<= s_axi_bvalid[s_w_sel]					;
			end
		end else if(S_W_CM[B_W_E_M]) begin
			sys_axi_bvalid						<= wvalid_lock								;
		end else begin
			sys_axi_bvalid						<= 1'b0										;
		end
	end

	always  @(posedge clk) begin
		if(sys_axi_bvalid && sys_axi_bready) begin
			wvalid_lock							<= 1'b0										;
		end else if(sys_axi_wvalid && sys_axi_wready)  begin
			wvalid_lock							<= 1'b1										;
		end else begin
			wvalid_lock							<= wvalid_lock								;
		end
	end


//==================================================================================================
//--Read Channel Arb
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_R_CM								<= S_R_IDLE_M								;
		end else begin
			S_R_CM								<= S_R_NM									;
		end
	end

	always @(*) begin
		S_R_NM									= S_R_IDLE_M								;
		case(S_R_CM)
			S_R_IDLE_M							: begin
				if(sys_axi_arvalid) begin
					if((sys_axi_araddr[P_CH_LOW_BIT_R +: 4]-P_CH_Start_Addr_R) >= P_AXI_CHANNEL_R) begin
						S_R_NM					= S_R_E_M									;
					end else begin
						S_R_NM					= S_R_B_M									;
					end
				end else begin
					S_R_NM						= S_R_IDLE_M								;
				end
			end
			S_R_B_M								: begin
				if(sys_axi_rvalid && sys_axi_rready) begin
					S_R_NM						= S_R_IDLE_M								;
				end else begin
					S_R_NM						= S_R_B_M									;
				end
			end
			S_R_E_M								: begin
				if(sys_axi_rvalid && sys_axi_rready) begin
					S_R_NM						= S_R_IDLE_M								;
				end else begin
					S_R_NM						= S_R_E_M									;
				end
			end
			default								: begin
				S_R_NM							= S_R_IDLE_M								;
			end
		endcase
	end
	/*--------------------------------------------------------------------------------------
	--r_sel signals
	--------------------------------------------------------------------------------------*/
	always @(posedge clk) begin
		if(S_R_CM[B_R_IDLE_M]) begin
			s_r_sel								<= sys_axi_araddr[P_CH_LOW_BIT_R +: 4]		
												- P_CH_Start_Addr_R							;
		end else begin
			s_r_sel								<= s_r_sel									;
		end
	end
	
	/*--------------------------------------------------------------------------------------
	--S_R_B_M中的ar_pass/r_lock
	--------------------------------------------------------------------------------------*/	
	always @(posedge clk) begin
		if(S_W_CM[B_W_B_M]) begin
			if(sys_axi_arvalid && sys_axi_arready) begin
				ar_pass							<= 1'b1										;
			end else begin
				ar_pass							<= ar_pass									;
			end
		end else begin
			ar_pass								<= 1'b0										;
		end
	end

	always @(posedge clk) begin
		if(S_R_CM[B_R_B_M]) begin
			if(ar_pass) begin
				s_axi_arvalid[s_r_sel]			<= 1'b0										;
			end else begin			
				s_axi_arvalid[s_r_sel]			<= sys_axi_arvalid							;
			end
		end else begin
			s_axi_arvalid[s_r_sel]				<= 0										;
		end
	end

	always @(*) begin
		if(S_R_CM[B_R_B_M]) begin
			sys_axi_arready						= s_axi_arready[s_r_sel]					;
		end else 
		if(S_R_CM[B_R_E_M]) begin
			sys_axi_arready						= 1											;
		end else begin
			sys_axi_arready						= 0											;
		end
	end

	always @(posedge clk) begin
		if(sys_axi_rvalid && sys_axi_rready) begin
			arvalid_lock						<= 1'b0										;
		end else
		if(sys_axi_arready && sys_axi_arvalid) begin
			arvalid_lock						<= 1'b1										;
		end else begin
			arvalid_lock						<= arvalid_lock								;
		end
	end


	always @(posedge clk) begin
		if(S_R_CM[B_R_B_M]) begin
			if((sys_axi_rvalid && sys_axi_rready) || r_pass) begin
				sys_axi_rvalid					<= 1'b0										;
			end else begin
				sys_axi_rvalid					<= s_axi_rvalid[s_r_sel]					;
			end
		end else
		if(S_R_CM[B_R_E_M]) begin
			sys_axi_rvalid						<= arvalid_lock								;
		end else begin
			sys_axi_rvalid						<= 1'b0										;
		end
	end

	always @(posedge clk) begin
		if(S_R_CM[B_R_B_M]) begin
			sys_axi_rresp						<= s_axi_rresp[s_r_sel*2 +: 2]				;
		end else begin
			sys_axi_rresp						<= 2'b00									;
		end
	end

	always @(posedge clk) begin
		if(S_R_CM[B_R_B_M]) begin
			sys_axi_rdata						<= s_axi_rdata[s_r_sel*32 +: 32]			;
		end else begin
			sys_axi_rdata						<= sys_axi_araddr							;
		end
	end

//==================================================================================================
//--Brodacast Master output Signlas for commmon signals
genvar ii;
generate for(ii=0;ii<P_AXI_CHANNEL_R;ii=ii+1) begin: AXI_G
	always @(posedge clk) begin
		s_axi_awaddr	[ii*32 +:32]			<= sys_axi_awaddr							;
		s_axi_awprot	[ii* 3 +: 3]			<= sys_axi_awprot							;
		s_axi_wdata		[ii*32 +:32]			<= sys_axi_wdata							;
		s_axi_wstrb		[ii*4  +: 4]			<= sys_axi_wstrb							;
		s_axi_araddr	[ii*32 +:32]			<= sys_axi_araddr							;
		s_axi_arprot	[ii*3  +: 3]			<= sys_axi_arprot							;
	end
	
	assign	s_axi_bready	[ii*1  +: 1]		= sys_axi_bready							;
	assign	s_axi_rready	[ii*1  +: 1]		= sys_axi_rready							;
end
endgenerate

endmodule