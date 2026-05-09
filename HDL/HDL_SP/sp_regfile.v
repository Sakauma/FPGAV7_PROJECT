 `timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			HXZY
// Engineer:		ZYL
// Create Date:		2018/5/11 19:40:24
// Design Name:		XR2000
// Module Name:		xr2000_regfile_log
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		文件实现clk下的寄存器读写操作
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sp_regfile #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	---------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--|clk-->可以连接clk，也可以连接外部时钟，进行快速查询处理
	--|rst-->复位信号，高电平同步复位信号
	--------------------------------------------------------------------------------------*/
	input										rst											,
	input										clk											,
                                                                                       	
	/*--------------------------------------------------------------------------------------
	--regfile signals output
	--------------------------------------------------------------------------------------*/
	input			[31:0]						reg_waddr									,
	input										reg_wvalid									,
	input			[31:0]						reg_wdata									,

	input			[31:0]						reg_raddr									,
	output	reg		[31:0]						reg_rdata					= 0				,

	/*--------------------------------------------------------------------------------------
	--reg out
	--------------------------------------------------------------------------------------*/
	output	reg		[31:0]						reg_srio_reset_time_c		= 'hFF			,
	output	reg									reg_srio_reset_enable_c		= 0				,
	output	reg									reg_srio_reset_trig_c		= 0				,
	output	reg									reg_srio_1x_auto_rst_en		= 1				,
	
	/*--------------------------------------------------------------------------------------
	--Link Status
	--------------------------------------------------------------------------------------*/
	input										port_error									,
	input										port_initialized							,
	input										link_initialized							,
	input										mode_1x										,
	/*--------------------------------------------------------------------------------------
	--SP CNT
	--------------------------------------------------------------------------------------*/
	input			[31:0]						c_sp_tx_cnt									,
	input			[31:0]						c_sp_rx_cnt									,
	output	reg									c_sp_en						= 1				,
	
	/*--------------------------------------------------------------------------------------
	--BM Count
	--------------------------------------------------------------------------------------*/

	input			[31:0]						c_bm_recv_cnt								,
	input			[31:0]						c_bm_up_cnt									,
	input			[31:0]						c_bm_lost_cnt								,
	input			[31:0]						c_bm_terr_cnt								,
	input			[31:0]						c_bm_derr_cnt								,
	output	reg									c_bm_en						= 0				,	
	output	reg									c_bm_rtready_en								,	
	output	reg									c_gt_dat_byps				=0				,	
	output	reg									c_gt_ksc_enab				=0				,	
	/*--------------------------------------------------------------------------------------
	--GT Count
	--------------------------------------------------------------------------------------*/	
	input			[31:0]						srgt_data_tcnt								,
	input			[31:0]						srgt_k_sc_tcnt								,
	input			[31:0]						rmv_fifo_afu_cnt							,
	input			[31:0]						par_fifo_afu_cnt							,
	input			[31:0]						sopdat_match_cnt							,
	input			[31:0]						sft_gtrx_sop_cnt							,
	input			[31:0]						rmv_gtrx_sop_cnt							,
	input			[31:0]						par_gtrx_sop_cnt							,
	input			[31:0]						gtx_debug_signal							,

	/*--------------------------------------------------------------------------------------
	--维护包写接口
	--------------------------------------------------------------------------------------*/
	(*mark_debug="TRUE"*)
	output	reg									c_s_m_rst					= 0				,
	
	(*mark_debug="TRUE"*)
	output	reg		[31:0]						c_s_m_waddr					= 0				,
	(*mark_debug="TRUE"*)
	output	reg		[31:0]						c_s_m_wdata					= 0				,
	(*mark_debug="TRUE"*)
	output	reg									c_s_m_wstart				= 0				,
	(*mark_debug="TRUE"*)
	input										c_s_m_wdone									,
	(*mark_debug="TRUE"*)
	input			[1:0]						c_s_m_wstatus_set							,
	
	(*mark_debug="TRUE"*)
	output	reg		[31:0]						c_s_m_raddr					= 0				,
	(*mark_debug="TRUE"*)
	output	reg									c_s_m_rstart				= 0				,
	(*mark_debug="TRUE"*)
	input										c_s_m_rdone									,
	(*mark_debug="TRUE"*)
	input			[31:0]						c_s_m_rdata_set								,
	(*mark_debug="TRUE"*)
	input			[1:0]						c_s_m_rstatus_set
	);
//==================================================================================================
//--参数定义
	/*--------------------------------------------------------------------------------------
	--芯片LINK状态、版本信息等
	--------------------------------------------------------------------------------------*/
	localparam		OFF_SRIO_REV				= 12'h000									;
	localparam		OFF_SRIO_RST_TIME			= 12'h010									;
	localparam		OFF_SRIO_RST_DISABLE		= 12'h014									;
	localparam		OFF_SRIO_RST_TRIG			= 12'h018									;
	localparam		OFF_MODE_1X_RST_EN			= 12'h020									;

	localparam		OFF_SP_PORT_INI				= 12'h100									;
	localparam		OFF_SP_PORT_ERR				= 12'h104									;
	localparam		OFF_SP_LINK_INI				= 12'h108									;
	localparam		OFF_SP_MODE_1X				= 12'h10C									;

	/*--------------------------------------------------------------------------------------
	--SP TX/RX Count
	--------------------------------------------------------------------------------------*/
	localparam		OFF_SP_TX_CNT				= 12'h200									;
	localparam		OFF_SP_RX_CNT				= 12'h210									;
	localparam		OFF_DMA_SIZE_SET			= 12'h214									;
	localparam		OFF_DMA_WAIT_SET			= 12'h218									;
	localparam		OFF_SP_EN					= 12'h260									;

	/*--------------------------------------------------------------------------------------
	--维护包模块配置寄存器
	--------------------------------------------------------------------------------------*/
	localparam		OFF_S_M_WADDR				= 12'h300									;	//RW-->写维护包的偏移量地址
	localparam		OFF_S_M_WDATA				= 12'h304									;	//RW-->写维护包的数据
	localparam		OFF_S_M_WSTATUS				= 12'h308									;	//RW-->写维护包的状态获取[31]==WDONE，[1:0]=WSTATUS 00 OKAY 01 EXOKAY 10 SLVERR 11 DECERR

	localparam		OFF_S_M_RADDR				= 12'h310									;	//RW-->读维护包的偏移量地址
	localparam		OFF_S_M_RDATA				= 12'h314									;	//RW-->读维护包返回的数据
	localparam		OFF_S_M_RSTATUS				= 12'h318									;	//RW-->读维护包的状态获取[31]==RDONE，[1:0]]=WSTATUS 00 OKAY 01 EXOKAY 10 SLVERR==RSTATUS
	
	localparam		OFF_S_RST					= 12'h320									;	//trig maintr reset
	/*--------------------------------------------------------------------------------------
	--BM相关
	--------------------------------------------------------------------------------------*/	
	localparam		OFF_BM_EN					= 12'h400									;
	localparam		OFF_BM_RECV_CNT				= 12'h410									;
	localparam		OFF_BM_UP_CNT				= 12'h414									;
	localparam		OFF_BM_LOST_CNT				= 12'h418									;
	localparam		OFF_BM_TERR_CNT				= 12'h420									;
	localparam		OFF_BM_DERR_CNT				= 12'h424									;
//==================================================================================================

	/*--------------------------------------------------------------------------------------
	--GT相关
	--------------------------------------------------------------------------------------*/	
	localparam		OFF_GTX_DEBUG_SIGNAL		= 12'h504									;
	localparam		OFF_SRGT_DATA_TCNT			= 12'h508									;
	localparam		OFF_SRGT_K_SC_TCNT			= 12'h50C									;
	localparam		OFF_RMV_FIFO_AFU_CNT		= 12'h510									;
	localparam		OFF_PAR_FIFO_AFU_CNT		= 12'h514									;
	localparam		OFF_SOPDAT_MATCH_CNT		= 12'h518									;
	localparam		OFF_GTX_GTRX_SOP_CNT		= 12'h51C									;
	localparam		OFF_RMV_GTRX_SOP_CNT		= 12'h520									;
	localparam		OFF_PAR_GTRX_SOP_CNT		= 12'h524									;
//==================================================================================================

//--SRIO Reset relax
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			reg_srio_reset_time_c				<= 32'd512									;
		end else if(reg_wvalid && reg_waddr[11:0]==OFF_SRIO_RST_TIME) begin
			reg_srio_reset_time_c				<= reg_wdata[31:0]							;
		end else begin
			reg_srio_reset_time_c				<= reg_srio_reset_time_c					;
		end
	end

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			reg_srio_reset_enable_c				<= 1'b0										;
		end else if(reg_wvalid && reg_waddr[11:0]==OFF_SRIO_RST_DISABLE) begin
			reg_srio_reset_enable_c				<= reg_wdata[0]								;
		end else begin
			reg_srio_reset_enable_c				<= reg_srio_reset_enable_c					;
		end
	end

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			reg_srio_reset_trig_c				<= 1'b0										;
		end else if(reg_wvalid && reg_waddr[11:0]==OFF_SRIO_RST_TRIG) begin
			reg_srio_reset_trig_c				<= 1'b1										;
		end else begin
			reg_srio_reset_trig_c				<= 1'b0										;
		end
	end

//==================================================================================================
//--维护包控制访问写入
	/*--------------------------------------------------------------------------------------
	--A通道
	--------------------------------------------------------------------------------------*/
	reg				[31:0]						c_s_m_wstatus								;

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_M_WADDR) begin
			c_s_m_waddr							<= reg_wdata[31:0]							;
		end else begin
			c_s_m_waddr							<= c_s_m_waddr								;
		end
	end

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_M_WDATA) begin
			c_s_m_wdata							<= reg_wdata[31:0]							;
			c_s_m_wstart						<= 1'b1										;
		end else begin
			c_s_m_wdata							<= c_s_m_wdata								;
			c_s_m_wstart						<= 1'b0										;
		end
	end

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_M_WSTATUS) begin
			c_s_m_wstatus						<= 32'b0									;
		end else if(c_s_m_wdone) begin
			c_s_m_wstatus						<= {1'b1,29'b0,c_s_m_wstatus_set[1:0]}		;
		end else begin
			c_s_m_wstatus						<= c_s_m_wstatus							;
		end
	end
	
	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_RST) begin
			c_s_m_rst							<= 1'b1										;
		end else begin
			c_s_m_rst							<= 1'b0										;
		end
	end

//==================================================================================================
//--维护读控制访问寄存器
	/*--------------------------------------------------------------------------------------
	--A通道
	--------------------------------------------------------------------------------------*/

	reg				[31:0]						c_s_m_rstatus								;
	reg				[31:0]						c_s_m_rdata									;

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_M_RADDR) begin
			c_s_m_raddr							<= reg_wdata[31:0]							;
			c_s_m_rstart						<= 1'b1										;
		end else begin
			c_s_m_raddr							<= c_s_m_raddr								;
			c_s_m_rstart						<= 1'b0										;
		end
	end

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_M_RSTATUS) begin
			c_s_m_rdata							<= 32'b0									;
		end else if(c_s_m_rdone) begin
			c_s_m_rdata							<= c_s_m_rdata_set							;
		end else begin
			c_s_m_rdata							<= c_s_m_rdata								;
		end
	end

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_S_M_RSTATUS) begin
			c_s_m_rstatus						<= 32'b0									;
		end else if(c_s_m_rdone) begin
			c_s_m_rstatus						<= {1'b1,29'b0,c_s_m_rstatus_set[1:0]}		;
		end else begin
			c_s_m_rstatus						<= c_s_m_rstatus							;
		end
	end
//==================================================================================================
//--BM enable
	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_BM_EN) begin
			c_bm_en								<= reg_wdata[0]								;
			c_bm_rtready_en						<= reg_wdata[1]								;
			c_gt_dat_byps						<= reg_wdata[2]								;
			c_gt_ksc_enab						<= reg_wdata[3]								;
		end else begin
			c_bm_en								<= c_bm_en									;
			c_bm_rtready_en						<= c_bm_rtready_en							;
			c_gt_dat_byps						<= c_gt_dat_byps							;
			c_gt_ksc_enab						<= c_gt_ksc_enab							;
		end
	end
	
	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_SP_EN) begin
			c_sp_en								<= reg_wdata[0]								;
		end else begin
			c_sp_en								<= c_sp_en									;
		end
	end	

	always @(posedge clk) begin
		if(reg_wvalid && reg_waddr[11:0]==OFF_MODE_1X_RST_EN) begin
			reg_srio_1x_auto_rst_en						<= reg_wdata[0]								;
		end else begin
			reg_srio_1x_auto_rst_en						<= reg_srio_1x_auto_rst_en					;
		end
	end	

//==================================================================================================
//--寄存器读实现
	always @(posedge clk) begin
		case(reg_raddr[11:0])
			OFF_SRIO_REV						: begin
				reg_rdata						<= 32'h0000_0001							;
			end
			OFF_SP_PORT_INI						: begin
				reg_rdata						<=	{
														28'b0								,
														mode_1x								,
														link_initialized					,
														port_error							,
														port_initialized					
													}										;				
			end
			OFF_SP_PORT_ERR						: begin
				reg_rdata						<= {31'b0,port_error}						;
			end
			OFF_SP_LINK_INI						: begin
				reg_rdata						<= {31'b0,link_initialized}					;
			end
			OFF_SP_MODE_1X						: begin
				reg_rdata						<= {31'b0,mode_1x}							;
			end
			OFF_SP_TX_CNT						: begin
				reg_rdata						<= c_sp_tx_cnt								;
			end
			OFF_SP_RX_CNT						: begin
				reg_rdata						<= c_sp_rx_cnt								;
			end	
			
			OFF_S_M_WADDR						: begin
				reg_rdata						<= c_s_m_waddr								;
			end
			OFF_S_M_WDATA						: begin
				reg_rdata						<= c_s_m_wdata								;
			end
			OFF_S_M_WSTATUS						: begin
				reg_rdata						<= c_s_m_wstatus							;
			end
			OFF_S_M_RADDR						: begin
				reg_rdata						<= c_s_m_raddr								;
			end
			OFF_S_M_RDATA						: begin
				reg_rdata						<= c_s_m_rdata								;
			end
			OFF_S_M_RSTATUS						: begin
				reg_rdata						<= c_s_m_rstatus							;
			end
			
			OFF_BM_LOST_CNT						: begin
				reg_rdata						<= c_bm_lost_cnt							;
			end		
			OFF_BM_TERR_CNT						: begin
				reg_rdata						<= c_bm_terr_cnt							;
			end		                               	
			OFF_BM_DERR_CNT						: begin
				reg_rdata						<= c_bm_derr_cnt							;
			end		
			OFF_BM_RECV_CNT						: begin
				reg_rdata						<= c_bm_recv_cnt							;
			end
			OFF_BM_UP_CNT						: begin
				reg_rdata						<= c_bm_up_cnt								;
			end
			
			OFF_BM_EN							: begin
				reg_rdata						<= {28'b0,
													c_gt_ksc_enab	,
													c_gt_dat_byps	,
													c_bm_rtready_en	,
													c_bm_en						}			;
			end
			
			OFF_SP_EN							: begin
				reg_rdata						<= {31'b0,c_sp_en}							;
			end		

			OFF_MODE_1X_RST_EN					: begin
				reg_rdata						<= {31'b0,reg_srio_1x_auto_rst_en}			;
			end	
			
			OFF_SRGT_DATA_TCNT					: begin
				reg_rdata						<= srgt_data_tcnt							;
			end				
			
			OFF_SRGT_K_SC_TCNT					: begin
				reg_rdata						<= srgt_k_sc_tcnt							;
			end				                       

			OFF_GTX_DEBUG_SIGNAL				: begin
				reg_rdata						<= gtx_debug_signal							;
			end		
			
			OFF_RMV_FIFO_AFU_CNT					: begin											
				reg_rdata						<= rmv_fifo_afu_cnt							;   	
			end					                                                                	
			                                                                                    	
			OFF_PAR_FIFO_AFU_CNT					: begin                                     	
				reg_rdata						<= par_fifo_afu_cnt							;   	
			end				
			
			OFF_SOPDAT_MATCH_CNT				: begin
				reg_rdata						<= sopdat_match_cnt							;
			end		

			OFF_GTX_GTRX_SOP_CNT					: begin
				reg_rdata						<= sft_gtrx_sop_cnt							;
			end				
			
			OFF_RMV_GTRX_SOP_CNT				: begin
				reg_rdata						<= rmv_gtrx_sop_cnt							;
			end	

			OFF_PAR_GTRX_SOP_CNT				: begin
				reg_rdata						<= par_gtrx_sop_cnt							;
			end				
			
			default								: begin
				reg_rdata						<= reg_raddr								;
			end
		endcase
	end

endmodule