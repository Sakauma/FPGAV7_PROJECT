 `timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			HXZY
// Engineer:		ZYL
// Create Date:		2020/3/4 9:15:41
// Design Name:		XR2000
// Module Name:		sr_maintr----SrioRedundancy_top
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		模块用于实现维护包发送与接收操作
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - 增加Link_initialization的0x148 ACK_ID复位操作
//////////////////////////////////////////////////////////////////////////////////
//==================================================================================================
//--sr_other Instantation
module sp_maintr #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	---------------------------------------------------------------------------------------*/
	parameter									P_SIMULATION_R			= "TRUE"
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--|clk-->可以连接log_clk，也可以连接外部时钟，进行快速查询处理
	--|rst-->复位信号，高电平同步复位信号
	--------------------------------------------------------------------------------------*/
	input										rst											,
	input										log_clk										,
	/*--------------------------------------------------------------------------------------
	--维护包写接口
	--------------------------------------------------------------------------------------*/
	input			[31:0]						c_s_m_waddr									,
	input			[31:0]						c_s_m_wdata									,
	input										c_s_m_wstart								,
	output										c_s_m_wdone									,
	output	reg		[1:0]						c_s_m_wstatus_set	= 0						,
	
	input			[31:0]						c_s_m_raddr									,
	input										c_s_m_rstart								,
	output										c_s_m_rdone									,
	output	reg		[31:0]						c_s_m_rdata_set		= 0						,
	output			[1:0]						c_s_m_rstatus_set							,
	
	input										c_s_m_rst									,

	/*--------------------------------------------------------------------------------------
	--SA通道Maintr信号
	--------------------------------------------------------------------------------------*/
	output	reg									maintr_rst			= 0						,
	output             							maintr_awvalid								,
    input            							maintr_awready								,
    output			[31:0]  					maintr_awaddr								,
    output             							maintr_wvalid								,
    input            							maintr_wready								,
    output			[31:0]  					maintr_wdata								,
    input            							maintr_bvalid								,
    output             							maintr_bready								,
    input			[1:0]   					maintr_bresp								,
    output             							maintr_arvalid								,
    input            							maintr_arready								,
    output			[31:0]  					maintr_araddr								,
    input            							maintr_rvalid								,
    output             							maintr_rready								,
    input			[31:0]  					maintr_rdata								,
    input			[1:0]   					maintr_rresp
    );
//==================================================================================================
//--参数定义
	/*--------------------------------------------------------------------------------------
	--Maintr_W写状态机参数定义
	--------------------------------------------------------------------------------------*/
	localparam									S_W_IDLE_M			= 5'b0_0001				;
	localparam									S_W_AW_M			= 5'b0_0010				;
	localparam									S_W_W_M				= 5'b0_0100				;
	localparam									S_W_B_M				= 5'b0_1000				;
	localparam									S_W_DONE_M			= 5'b1_0000				;
	
	localparam									B_W_IDLE_M			= 3'd0					;
	localparam									B_W_AW_M			= 3'd1					;
	localparam									B_W_W_M				= 3'd2					;
	localparam									B_W_B_M				= 3'd3					;
	localparam									B_W_DONE_M			= 3'd4					;

	/*--------------------------------------------------------------------------------------
	--Maintr_R读状态机参数定义
	--------------------------------------------------------------------------------------*/
	localparam									S_R_IDLE_M			= 4'b0001				;
	localparam									S_R_AR_M			= 4'b0010				;
	localparam									S_R_RR_M			= 4'b0100				;
	localparam									S_R_DONE_M			= 4'b1000				;
	
	localparam									B_R_IDLE_M			= 2'd0					;
	localparam									B_R_AR_M			= 2'd1					;
	localparam									B_R_RR_M			= 2'd2					;
	localparam									B_R_DONE_M			= 2'd3					;
	

	/*--------------------------------------------------------------------------------------
	--超时计数器实现
	--------------------------------------------------------------------------------------*/
	localparam									S_WR_TIMEOUT		= 32'h00FF_FFFF			;
	

//==================================================================================================
//--信号定义
	/*--------------------------------------------------------------------------------------
	--Maintr_W状态机及相关信号定义
	--------------------------------------------------------------------------------------*/
	(*mark_debug="TRUE"*)
	reg				[4:0]						S_W_CM										;
	reg				[4:0]						S_W_NM										;
	reg				[31:0]						s_w_cnt				= 0						;	//超时计数器
	(*mark_debug="TRUE"*)
	reg											s_w_timeout			= 0						;
//	reg											s_w_sel										;	//=0,Host,=1,link_rst_req

	/*--------------------------------------------------------------------------------------
	--Maintr_W状态机及相关信号定义
	--------------------------------------------------------------------------------------*/
	(*mark_debug="TRUE"*)
	reg				[3:0]						S_R_CM										;
	(*mark_debug="TRUE"*)
	reg				[3:0]						S_R_NM										;
	(*mark_debug="TRUE"*)
	reg				[31:0]						s_r_cnt				= 0						;	//超时计数器
	reg											s_r_timeout			= 0						;

//==================================================================================================
//--reset for host trig	2020/5/18 19:24:14
	reg				[3:0]						reset_time			= 0						;
	
	always @(posedge log_clk or posedge rst) begin
		if(rst) begin
			reset_time							<= 4'hF										;
			maintr_rst							<= 1'b0										;
		end else if(c_s_m_rst) begin
			reset_time							<= 4'hF										;
			maintr_rst							<= 1'b0										;
		end else if(reset_time>0) begin
			reset_time							<= reset_time - 1'b1						;
			maintr_rst							<= 1'b1										;	//reset for 16 clocks
		end else begin
			reset_time							<= reset_time								;
			maintr_rst							<= 1'b0										;
		end
	end

//==================================================================================================
//--写状态机执行
	always @(posedge log_clk or posedge rst) begin
		if(rst) begin
			S_W_CM								<= S_W_IDLE_M								;
		end else begin
			S_W_CM								<= S_W_NM									;
		end
	end

	always @(posedge log_clk) begin
		if(S_W_CM[B_W_IDLE_M] || S_W_CM[B_W_DONE_M]) begin
			s_w_cnt								<= 32'b0									;
			s_w_timeout							<= 1'b0										;
		end else if(s_w_cnt==S_WR_TIMEOUT) begin
			s_w_cnt								<= S_WR_TIMEOUT								;
			s_w_timeout							<= 1'b1										;
		end else begin
			s_w_cnt								<= s_w_cnt + 1'b1							;
			s_w_timeout							<= s_w_timeout								;
		end
	end


	always @(*) begin
		S_W_NM									= S_W_IDLE_M								;
		case(S_W_CM)
			S_W_IDLE_M							: begin
				if(c_s_m_wstart) begin
					S_W_NM						= S_W_AW_M									;
				end else begin
					S_W_NM						= S_W_IDLE_M								;
				end
			end
			S_W_AW_M							: begin
				if(s_w_timeout) begin
					S_W_NM						= S_W_DONE_M								;
				end else if(maintr_awready && maintr_wready) begin
					S_W_NM						= S_W_B_M									;
				end else if(maintr_awready) begin
					S_W_NM						= S_W_W_M									;
				end else begin
					S_W_NM						= S_W_AW_M									;
				end
			end
			S_W_W_M								: begin
				if(s_w_timeout) begin
					S_W_NM						= S_W_DONE_M								;
				end else if(maintr_wready) begin
					S_W_NM						= S_W_B_M									;
				end else begin
					S_W_NM						= S_W_W_M									;
				end
			end
			S_W_B_M								: begin
				if(s_w_timeout) begin
					S_W_NM						= S_W_DONE_M								;
				end else if(maintr_bvalid) begin
					S_W_NM						= S_W_DONE_M								;
				end else begin
					S_W_NM						= S_W_B_M									;
				end
			end
			S_W_DONE_M							: begin
				S_W_NM							= S_W_IDLE_M								;
			end
			default								: begin
				S_W_NM							= S_W_IDLE_M								;
			end
		endcase
	end
	
	assign	maintr_awvalid						= S_W_CM[B_W_AW_M]							;
	assign	maintr_wvalid						= S_W_CM[B_W_AW_M] | S_W_CM[B_W_W_M]		;
	assign	maintr_bready						= S_W_CM[B_W_B_M]							;
	
	assign	maintr_awaddr						= c_s_m_waddr								;
	assign	maintr_wdata						= c_s_m_wdata								;
	
//	assign	maintr_awaddr					= (s_w_sel==1'b0)?c_s_m_waddr:LP_LINK_RST_WADDR	;
//	assign	maintr_wdata					= (s_w_sel==1'b0)?c_s_m_wdata:LP_LINK_RST_WDATA	;
	
	assign	c_s_m_wdone							= S_W_CM[B_W_DONE_M]?1'b1:1'b0				;
	
	always @(posedge log_clk) begin
		if(S_W_CM[B_W_IDLE_M]) begin
			c_s_m_wstatus_set					<= 2'b00									;
		end else if(maintr_bready && maintr_bvalid) begin
			c_s_m_wstatus_set					<= maintr_bresp								;
		end else if(s_w_timeout==1'b1) begin
			c_s_m_wstatus_set					<= 2'b11									;
		end else begin
			c_s_m_wstatus_set					<= c_s_m_wstatus_set						;
		end
	end
//==================================================================================================
//--读状态机执行
	always @(posedge log_clk or posedge rst) begin
		if(rst) begin
			S_R_CM								<= S_R_IDLE_M								;
		end else begin
			S_R_CM								<= S_R_NM									;
		end
	end

	always @(posedge log_clk) begin
		if(S_R_CM[B_R_IDLE_M] || S_R_CM[B_R_DONE_M]) begin
			s_r_cnt								<= 32'b0									;
			s_r_timeout							<= 1'b0										;
		end else if(s_r_cnt==S_WR_TIMEOUT) begin
			s_r_cnt								<= S_WR_TIMEOUT								;
			s_r_timeout							<= 1'b1										;
		end else begin
			s_r_cnt								<= s_r_cnt + 1'b1							;
			s_r_timeout							<= s_r_timeout								;
		end
	end

	always @(*) begin
		S_R_NM									= S_R_IDLE_M								;
		case(S_R_CM)
			S_R_IDLE_M							: begin
				if(c_s_m_rstart) begin
					S_R_NM						= S_R_AR_M									;
				end else begin
					S_R_NM						= S_R_IDLE_M								;
				end
			end
			S_R_AR_M							: begin
				if(s_r_timeout) begin
					S_R_NM						= S_R_DONE_M								;
				end else if(maintr_arready) begin
					S_R_NM						= S_R_RR_M									;
				end else begin
					S_R_NM						= S_R_AR_M									;
				end
			end
			S_R_RR_M							: begin
				if(s_r_timeout) begin
					S_R_NM						= S_R_DONE_M								;
				end else if(maintr_rvalid) begin
					S_R_NM						= S_R_DONE_M								;
				end else begin
					S_R_NM						= S_R_RR_M									;
				end
			end
			S_R_DONE_M							: begin
				S_R_NM							= S_R_IDLE_M								;
			end
			default								: begin
				S_R_NM							= S_R_IDLE_M								;
			end
		endcase
	end

	assign	maintr_arvalid						= (S_R_CM[B_R_AR_M])?1'b1:1'b0				;
	assign	maintr_rready						= 1'b1										;
	assign	maintr_araddr						= c_s_m_raddr								;
//	assign	c_s_m_rdata_set						= maintr_rdata								;
	
	always @(posedge log_clk) begin
		if(S_R_CM[B_R_IDLE_M]) begin
			c_s_m_rdata_set						<= 32'hFFFF_FFFF							;
		end else if(maintr_rvalid && maintr_rready) begin
			c_s_m_rdata_set						<= maintr_rdata								;
		end else begin
			c_s_m_rdata_set						<= maintr_rdata								;
		end
	end
	
	assign	c_s_m_rstatus_set					= (s_r_timeout==1'b1)?2'b11:maintr_rresp	;
	assign	c_s_m_rdone							= S_R_CM[B_R_DONE_M]?1'b1:1'b0				;

endmodule