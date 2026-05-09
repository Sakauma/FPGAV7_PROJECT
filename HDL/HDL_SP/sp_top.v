 `timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			HXZY
// Engineer:		ZYL
// Create Date:		2020/3/4 9:15:07
// Design Name:		XR2000
// Module Name:		spb_top-SrioPCIeBridge_TOP
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		文件将一个SRIO通道的所有事物融合在一个模块里
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sp_top #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	---------------------------------------------------------------------------------------*/
	parameter		LOOP_NUM					= 0											,
	parameter		P_SIMULATION_R				= "FALSE"									,
	parameter		P_BIG_CACHE_R				= "FALSE"
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--|clk-->可以连接log_clk，也可以连接外部时钟，进行快速查询处理
	--|rst-->复位信号，高电平同步复位信号
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										rst											,
	input										srio_rst									,

	input										log_clk										,
	/*--------------------------------------------------------------------------------------
	--link
	--------------------------------------------------------------------------------------*/
	input										link_initialized							,
	input										port_initialized							,
	input										port_error									,
	input										mode_1x										,
	output										force_reinit								,
	/*--------------------------------------------------------------------------------------
	--Write Address Channel Signals
	--------------------------------------------------------------------------------------*/
	input			[32-1:0]					sys_axi_awaddr								,
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

`ifdef	ENABLE_SIM
//==================================================================================================
//--DMA Channel Signals
	/*--------------------------------------------------------------------------------------
	--DMA Channel AXI Stream Inteface
	--------------------------------------------------------------------------------------*/
	output										dma_s_axis_aclk								,
	output			[64-1	:0]					dma_s_axis_tdata							,
	output			[4-1	:0]					dma_s_axis_tid								,
	input			[1-1	:0]					dma_s_axis_tready							,
	output			[1-1	:0]					dma_s_axis_tvalid							,
	output			[8-1	:0]					dma_s_axis_tstrb							,
	output			[8-1	:0]					dma_s_axis_tkeep							,
	output			[1-1	:0]					dma_s_axis_tlast							,
	output			[64-1	:0]					dma_s_axis_tuser							,
	output			[4-1	:0]					dma_s_axis_tdest							,

	output										dma_m_axis_aclk								,
	input			[64-1	:0]					dma_m_axis_tdata							,
	input			[4-1	:0]					dma_m_axis_tid								,
	output			[1-1	:0]					dma_m_axis_tready							,
	input			[1-1	:0]					dma_m_axis_tvalid							,
	input			[8-1	:0]					dma_m_axis_tstrb							,
	input			[8-1	:0]					dma_m_axis_tkeep							,
	input			[1-1	:0]					dma_m_axis_tlast							,
	input			[64-1	:0]					dma_m_axis_tuser							,
	input			[4-1	:0]					dma_m_axis_tdest							,
	/*--------------------------------------------------------------------------------------
	--host clock packet cnt
	--------------------------------------------------------------------------------------*/
	output	wire	[31:0]						c_sp_up_cnt									,
	output	wire	[31:0]						c_sp_dn_cnt									,

`endif	
	/*--------------------------------------------------------------------------------------
	--BM Count
	--------------------------------------------------------------------------------------*/
	input			[31:0]						c_bm_recv_cnt								,
	input			[31:0]						c_bm_up_cnt									,
	input			[31:0]						c_bm_lost_cnt								,
	input			[31:0]						c_bm_terr_cnt								,
	input			[31:0]						c_bm_derr_cnt								,
	output										c_bm_en										,	
	output										c_bm_rtready_en								,	
	output										c_gt_ksc_enab								,	
	output										c_gt_dat_byps								,	
	
	/*--------------------------------------------------------------------------------------
	--GT Count
	--------------------------------------------------------------------------------------*/
	input			[31:0]						srgt_data_tcnt								,
	input			[31:0]						srgt_k_sc_tcnt								,
	input			[31:0]						sft_gtrx_sop_cnt							,
	input			[31:0]						rmv_gtrx_sop_cnt							,
	input			[31:0]						par_gtrx_sop_cnt							,	
	input			[31:0]						sopdat_match_cnt							,
	input			[31:0]						rmv_fifo_afu_cnt							,
	input			[31:0]						par_fifo_afu_cnt							,
	input			[31:0]						gtx_debug_signal							,	
	
//==================================================================================================
//--SRIO Reduncy Signals
	/*--------------------------------------------------------------------------------------
	--USER SRIO Redundancy Interface
	--------------------------------------------------------------------------------------*/
	output										sr_iotx_tvalid								,
	input										sr_iotx_tready								,
	output										sr_iotx_tlast								,
	output			[63:0]						sr_iotx_tdata								,
	output			[ 7:0]						sr_iotx_tkeep								,
	output			[31:0]						sr_iotx_tuser								,

	input										sr_iorx_tvalid								,
	output										sr_iorx_tready								,
	input										sr_iorx_tlast								,
	input			[63:0]						sr_iorx_tdata								,
	input			[7:0]						sr_iorx_tkeep								,
	input			[31:0]						sr_iorx_tuser								,


	/*--------------------------------------------------------------------------------------
	--SA通道Maintr信号
	--------------------------------------------------------------------------------------*/
	output										maintr_rst									,
	output             							maintr_awvalid								,
    input            							maintr_awready								,
    output			[31:0]  					maintr_awaddr								,
    output             							maintr_wvalid								,
    input            							maintr_wready								,
    output			[31:0]  					maintr_wdata								,
    input            							maintr_bvalid								,
    output             							maintr_bready								,
    input			[ 1:0]   					maintr_bresp								,

    output             							maintr_arvalid								,
    input            							maintr_arready								,
    output			[31:0]  					maintr_araddr								,
    input            							maintr_rvalid								,
    output             							maintr_rready								,
    input			[31:0]  					maintr_rdata								,
    input			[ 1:0]   					maintr_rresp
	);
//==================================================================================================
//--signals defines
	/*--------------------------------------------------------------------------------------
	--regfile signals output
	--------------------------------------------------------------------------------------*/	  	
	wire			[31:0]						reg_waddr									;
	wire										reg_wvalid									;
	wire			[31:0]						reg_wdata									;
	
	wire			[31:0]						reg_raddr									;
	wire			[31:0]						reg_rdata                                   ;

	wire			[31:0]						reg_srio_reset_time_c						;
	wire										reg_srio_reset_enable_c						;
	wire										reg_srio_reset_trig_c						;
	wire										reg_srio_1x_auto_rst_en						;
	
	wire			[31:0]						c_sp_rx_cnt									;
	wire			[31:0]						c_sp_tx_cnt									;
	
	/*--------------------------------------------------------------------------------------
	--维护包写接口
	--------------------------------------------------------------------------------------*/
	wire										c_s_m_rst									;
	wire			[31:0]						c_s_m_waddr									;
	wire			[31:0]						c_s_m_wdata									;
	wire										c_s_m_wstart								;
	wire										c_s_m_wdone									;
	wire			[1:0]						c_s_m_wstatus_set							;
                                                                                        	
	wire			[31:0]						c_s_m_raddr									;
	wire										c_s_m_rstart								;
	wire										c_s_m_rdone									;
	wire			[31:0]						c_s_m_rdata_set								;
	wire			[1:0]						c_s_m_rstatus_set							;
	
	assign	dma_s_axis_aclk						= clk									;
	assign	dma_m_axis_aclk						= clk										;

	wire										c_sp_en										;
											
										   
										
										
											
											
									   
											
											
											  
`ifdef	ENABLE_SIM
//==================================================================================================
//--sp_up Instantation
	sp_cond_up	#(
		.LOOP_NUM								( LOOP_NUM									),
		.P_SIMULATION_R							( P_SIMULATION_R							),
		.P_BIG_CACHE_R							( P_BIG_CACHE_R								)
	)
	i_sp_cond_up (
		.clk									( clk										),
		.log_clk								( log_clk									),
		.rst									( rst										),
		.c_sp_up_cnt							( c_sp_up_cnt								),
		.c_sp_rx_cnt							( c_sp_rx_cnt								),
		
		.srio_rst								( srio_rst									),
		.c_sp_en								( c_sp_en									),

		.dma_s_axis_tdata						( dma_s_axis_tdata							),
		.dma_s_axis_tid							( dma_s_axis_tid							),
		.dma_s_axis_tready						( dma_s_axis_tready							),
		.dma_s_axis_tvalid						( dma_s_axis_tvalid							),
		.dma_s_axis_tstrb						( dma_s_axis_tstrb							),
		.dma_s_axis_tkeep						( dma_s_axis_tkeep							),
		.dma_s_axis_tlast						( dma_s_axis_tlast							),
		.dma_s_axis_tuser						( dma_s_axis_tuser							),
		.dma_s_axis_tdest						( dma_s_axis_tdest							),

		.sr_iorx_tvalid							( sr_iorx_tvalid							),
		.sr_iorx_tready							( sr_iorx_tready							),
		.sr_iorx_tlast							( sr_iorx_tlast								),
		.sr_iorx_tdata							( sr_iorx_tdata								),
		.sr_iorx_tkeep							( sr_iorx_tkeep								),
		.sr_iorx_tuser							( sr_iorx_tuser								)
	);


//==================================================================================================
//--spb_top Instantation
	sp_cond_dn	#(
		.LOOP_NUM								( LOOP_NUM									),
		.P_SIMULATION_R							( P_SIMULATION_R							),
		.P_BIG_CACHE_R							( P_BIG_CACHE_R								)
	)
	i_sp_cond_dn (
		.clk									( clk										),
		.log_clk								( log_clk									),
		.rst									( rst										),
		.srio_rst								( srio_rst									),

		.c_sp_dn_cnt							( c_sp_dn_cnt								),
		.c_sp_tx_cnt							( c_sp_tx_cnt								),

		.dma_m_axis_tdata						( dma_m_axis_tdata							),
		.dma_m_axis_tid							( dma_m_axis_tid							),
		.dma_m_axis_tready						( dma_m_axis_tready							),
		.dma_m_axis_tvalid						( dma_m_axis_tvalid							),
		.dma_m_axis_tstrb						( dma_m_axis_tstrb							),
		.dma_m_axis_tkeep						( dma_m_axis_tkeep							),
		.dma_m_axis_tlast						( dma_m_axis_tlast							),
		.dma_m_axis_tuser						( dma_m_axis_tuser							),
		.dma_m_axis_tdest						( dma_m_axis_tdest							),

		.sr_iotx_tvalid							( sr_iotx_tvalid							),
		.sr_iotx_tready							( sr_iotx_tready							),
		.sr_iotx_tlast							( sr_iotx_tlast								),
		.sr_iotx_tdata							( sr_iotx_tdata								),
		.sr_iotx_tkeep							( sr_iotx_tkeep								),
		.sr_iotx_tuser							( sr_iotx_tuser								)
	);
`else
		
		assign	sr_iorx_tready		=	1'b1	;
		
		assign	sr_iotx_tvalid		=	1'b0	;
	//	assign	sr_iotx_tready		=	1'b0	;
		assign	sr_iotx_tlast		=	1'b0	;	
		assign	sr_iotx_tdata		=	64'b0	;	
		assign	sr_iotx_tkeep		=	8'b0	;	
        assign	sr_iotx_tuser		=	32'b0	;	

`endif

	sp_maintr	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_sp_maintr(
		.rst									( rst										),
		.log_clk								( log_clk									),

		.c_s_m_waddr							( c_s_m_waddr		    					),
		.c_s_m_wdata							( c_s_m_wdata		    					),
		.c_s_m_wstart							( c_s_m_wstart		    					),
		.c_s_m_wdone							( c_s_m_wdone		    					),
		.c_s_m_wstatus_set						( c_s_m_wstatus_set							),
		.c_s_m_raddr							( c_s_m_raddr		    					),
		.c_s_m_rstart							( c_s_m_rstart		    					),
		.c_s_m_rdone							( c_s_m_rdone		    					),
		.c_s_m_rdata_set						( c_s_m_rdata_set	    					),
		.c_s_m_rstatus_set						( c_s_m_rstatus_set							),
		
		.c_s_m_rst								( c_s_m_rst									),
		
		.maintr_rst								( maintr_rst								),
		.maintr_awvalid							( maintr_awvalid	    					),
		.maintr_awready  						( maintr_awready	    					),
		.maintr_awaddr   						( maintr_awaddr	    						),
		.maintr_wvalid   						( maintr_wvalid	    						),
		.maintr_wready   						( maintr_wready	    						),
		.maintr_wdata    						( maintr_wdata								),
		.maintr_bvalid   						( maintr_bvalid	    						),
		.maintr_bready   						( maintr_bready	    						),
		.maintr_bresp    						( maintr_bresp								),
		.maintr_arvalid  						( maintr_arvalid	    					),
		.maintr_arready  						( maintr_arready	    					),
		.maintr_araddr   						( maintr_araddr	    						),
		.maintr_rvalid   						( maintr_rvalid	    						),
		.maintr_rready   						( maintr_rready	    						),
		.maintr_rdata    						( maintr_rdata								),
		.maintr_rresp    						( maintr_rresp								)
	);

	sp_rst	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_sp_rst (
		.clk									( log_clk									),
		.rst									( rst										),

		.port_initialized						( port_initialized							),
		.link_initialized						( link_initialized							),

		.reg_srio_reset_time_c					( reg_srio_reset_time_c						),
		.reg_srio_reset_enable_c				( reg_srio_reset_enable_c					),
		.reg_srio_reset_trig_c					( reg_srio_reset_trig_c						),
		.reg_srio_1x_auto_rst_en				( reg_srio_1x_auto_rst_en					),
		.mode_1x								( mode_1x									),

		.force_reinit							( force_reinit								)
	);

//==================================================================================================
//--zt_axi2reg Instantation
	sp_axi2reg	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_sp_axi2reg (
		.clk									( log_clk									),
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
//--sp_regfile Instantation
	sp_regfile	#(
		.P_SIMULATION_R							( P_SIMULATION_R							)
	)
	i_sp_regfile (
		.rst									( rst										),
		.clk									( log_clk									),
		
		.reg_waddr								( reg_waddr									),
		.reg_wvalid								( reg_wvalid								),
		.reg_wdata								( reg_wdata									),
		.reg_raddr								( reg_raddr									),
		.reg_rdata								( reg_rdata									),
		
		.reg_srio_reset_time_c		            ( reg_srio_reset_time_c						),
		.reg_srio_reset_enable_c	            ( reg_srio_reset_enable_c					),    
		.reg_srio_reset_trig_c					( reg_srio_reset_trig_c						),
		.reg_srio_1x_auto_rst_en				( reg_srio_1x_auto_rst_en					),

		
		.port_error								( port_error								),
		.port_initialized						( port_initialized							),
		.link_initialized						( link_initialized							),
		.mode_1x								( mode_1x									),
		
		.c_sp_tx_cnt							( c_sp_tx_cnt								),
		.c_sp_rx_cnt							( c_sp_rx_cnt								),
		.c_sp_en								( c_sp_en									),
		
		.c_bm_recv_cnt							( c_bm_recv_cnt								),
		.c_bm_up_cnt							( c_bm_up_cnt								),
		.c_bm_lost_cnt							( c_bm_lost_cnt								),
		.c_bm_terr_cnt							( c_bm_terr_cnt								),
		.c_bm_derr_cnt							( c_bm_derr_cnt								),
		.c_bm_en								( c_bm_en									),
		.c_bm_rtready_en						( c_bm_rtready_en							),
		.c_gt_ksc_enab							( c_gt_ksc_enab							),
		.c_gt_dat_byps							( c_gt_dat_byps							),
		
		.	srgt_data_tcnt						(	srgt_data_tcnt							),
		.	srgt_k_sc_tcnt						(	srgt_k_sc_tcnt							),
		.	rmv_fifo_afu_cnt					(	rmv_fifo_afu_cnt						),
		.	par_fifo_afu_cnt					(	par_fifo_afu_cnt						),
		.	sopdat_match_cnt					(	sopdat_match_cnt						),
		.	sft_gtrx_sop_cnt					(	sft_gtrx_sop_cnt						),
		.	rmv_gtrx_sop_cnt					(	rmv_gtrx_sop_cnt						),
		.	par_gtrx_sop_cnt					(	par_gtrx_sop_cnt						),
		.	gtx_debug_signal					(	gtx_debug_signal						),
		
		.c_s_m_rst								( c_s_m_rst									),
		.c_s_m_waddr							( c_s_m_waddr								),
		.c_s_m_wdata							( c_s_m_wdata								),
		.c_s_m_wstart							( c_s_m_wstart								),
		.c_s_m_wdone							( c_s_m_wdone								),
		.c_s_m_wstatus_set						( c_s_m_wstatus_set							),
		.c_s_m_raddr							( c_s_m_raddr								),
		.c_s_m_rstart							( c_s_m_rstart								),
		.c_s_m_rdone							( c_s_m_rdone								),
		.c_s_m_rdata_set						( c_s_m_rdata_set							),
		.c_s_m_rstatus_set						( c_s_m_rstatus_set							)
	);
	
endmodule
