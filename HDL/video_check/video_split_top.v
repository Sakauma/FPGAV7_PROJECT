`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY				
// Engineer:		DuCHaoMing	        
//                                     
// Create Date:		2014/6/12 9:49:39   
// Design Name:		video_split_top              
// Module Name:		video_split_top             
// Project Name:	SRIO to Ethernet Video Transmission	                
// Target Devices:	Xilinx Virtex-7                
// Tool versions:	Vivado                
// Description:		Top module for two SRIO channels + video merge + 10G Ethernet transmission                
// 				
// Dependencies:	srio_data_classifier, sp_clloect_4k, video_send				
// 				
// Revision:		2.0 - Added SRIO data classifier on SRIO 0				
////////////////////////////////////////////////////////////////////////////////////////////////////
 module video_split_top #(
	parameter	SIM				= 1,		// 0: use real FIFO, 1: use simulation FIFO
	parameter	PR_DN_NUM		= 1,
	parameter	BUS_DW			= 64,
	parameter	DW				= 64,
	parameter	QW				= 64,
	parameter	TARGET_SRC_ID	= 16'h0000	// Target Source ID for video data on SRIO 0
)(
	//================================================================================================
	// SRIO 0 Interface
	//================================================================================================
	input					srio0_tvalid,
	output					srio0_tready,
	input					srio0_tlast,
	input	[63:0]			srio0_tdata,
	input	[7:0]			srio0_tkeep,
	input	[31:0]			srio0_tuser,

	//================================================================================================
	// SRIO 1 Interface
	//================================================================================================
	input					srio1_tvalid,
	output					srio1_tready,
	input					srio1_tlast,
	input	[63:0]			srio1_tdata,
	input	[7:0]			srio1_tkeep,
	input	[31:0]			srio1_tuser,

	//================================================================================================
	// Non-Target SRIO 0 Data Output (to other modules)
	//================================================================================================
	output					srio0_nontarget_tvalid,
	input					srio0_nontarget_tready,
	output					srio0_nontarget_tlast,
	output	[63:0]			srio0_nontarget_tdata,
	output	[7:0]			srio0_nontarget_tkeep,
	output	[31:0]			srio0_nontarget_tuser,

	//================================================================================================
	// Ethernet (UDP) AXI-Stream Output
	//================================================================================================
	output	[PR_DN_NUM*DW-1:0]		udp_axis_tdata,
	input	[PR_DN_NUM*1-1:0]			udp_axis_tready,
	output	[PR_DN_NUM*1-1:0]			udp_axis_tvalid,
	output	[PR_DN_NUM*DW/8-1:0]		udp_axis_tkeep,
	output	[PR_DN_NUM*1-1:0]			udp_axis_tlast,
	output	[PR_DN_NUM*32-1:0]			udp_axis_tuser,

	//================================================================================================
	// Common Interface
	//================================================================================================
	input					core_clk,
	input					clk,
	input					rst_n
);

	//================================================================================================
	// Internal Signals - SRIO 0 Classifier Output
	//================================================================================================
	wire				srio0_target_tvalid;
	wire				srio0_target_tready;
	wire				srio0_target_tlast;
	wire	[63:0]		srio0_target_tdata;
	wire	[7:0]		srio0_target_tkeep;
	wire	[31:0]		srio0_target_tuser;

	//================================================================================================
	// Internal Signals - Connect sp_clloect_4k_0 to video_send
	//================================================================================================
	wire				srio0_info_wr;
	wire	[63:0]		srio0_info_di;
	wire				srio0_info_af;
	wire				srio0_info_fu;
	wire				srio0_fifo_wr;
	wire	[BUS_DW-1:0]	srio0_fifo_di;
	wire				srio0_fifo_af;
	wire				srio0_fifo_fu;
	wire				srio0_fifo_wl;

	//================================================================================================
	// Internal Signals - Connect sp_clloect_4k_1 to video_send
	//================================================================================================
	wire				srio1_info_wr;
	wire	[63:0]		srio1_info_di;
	wire				srio1_info_af;
	wire				srio1_info_fu;
	wire				srio1_fifo_wr;
	wire	[BUS_DW-1:0]	srio1_fifo_di;
	wire				srio1_fifo_af;
	wire				srio1_fifo_fu;
	wire				srio1_fifo_wl;

	//================================================================================================
	// Statistics Outputs (optional, can leave unconnected)
	//================================================================================================
	wire	[31:0]		srio0_rx_pkg_cnt;
	wire	[31:0]		srio0_rx_ocm_cnt;
	wire	[31:0]		srio0_rx_4k_cnt;
	wire	[31:0]		srio0_rx_dat_cnt;
	
	wire	[31:0]		srio1_rx_pkg_cnt;
	wire	[31:0]		srio1_rx_ocm_cnt;
	wire	[31:0]		srio1_rx_4k_cnt;
	wire	[31:0]		srio1_rx_dat_cnt;

	//================================================================================================
	// Instance 0: SRIO Data Classifier for SRIO 0
	//================================================================================================
	srio_data_classifier #(
		.SIM				(SIM),
		.TARGET_SRC_ID		(TARGET_SRC_ID),
		.FIFO_DEPTH			(1024),
		.DATA_WIDTH			(64),
		.USER_WIDTH			(32),
		.KEEP_WIDTH			(8)
	) u_srio_data_classifier (
		.srio_tvalid		(srio0_tvalid),
		.srio_tready		(srio0_tready),
		.srio_tlast			(srio0_tlast),
		.srio_tdata			(srio0_tdata),
		.srio_tkeep			(srio0_tkeep),
		.srio_tuser			(srio0_tuser),

		.target_tvalid		(srio0_target_tvalid),
		.target_tready		(srio0_target_tready),
		.target_tlast		(srio0_target_tlast),
		.target_tdata		(srio0_target_tdata),
		.target_tkeep		(srio0_target_tkeep),
		.target_tuser		(srio0_target_tuser),

		.nontarget_tvalid	(srio0_nontarget_tvalid),
		.nontarget_tready	(srio0_nontarget_tready),
		.nontarget_tlast	(srio0_nontarget_tlast),
		.nontarget_tdata	(srio0_nontarget_tdata),
		.nontarget_tkeep	(srio0_nontarget_tkeep),
		.nontarget_tuser	(srio0_nontarget_tuser),

		.clk				(clk),
		.rst_n				(rst_n)
	);

	//================================================================================================
	// Instance 1: sp_clloect_4k for SRIO Channel 0 (Target ID Data)
	//================================================================================================
	sp_collect_4k #(
		.BUS_DW			(BUS_DW)
	) u_sp_collect_4k_0 (
		.sr_iorx_tvalid		(srio0_target_tvalid),
		.sr_iorx_tready		(srio0_target_tready),
		.sr_iorx_tlast		(srio0_target_tlast),
		.sr_iorx_tdata		(srio0_target_tdata),
		.sr_iorx_tkeep		(srio0_target_tkeep),
		.sr_iorx_tuser		(srio0_target_tuser),

		.rio_treq_info_wr	(srio0_info_wr),
		.rio_treq_info_di	(srio0_info_di),
		.rio_treq_info_af	(srio0_info_af),
		.rio_treq_info_fu	(srio0_info_fu),
		.rio_treq_fifo_wr	(srio0_fifo_wr),
		.rio_treq_fifo_di	(srio0_fifo_di),
		.rio_treq_fifo_af	(srio0_fifo_af),
		.rio_treq_fifo_fu	(srio0_fifo_fu),
		.rio_treq_fifo_wl	(srio0_fifo_wl),

		.srio_rx_pkg_cnt	(srio0_rx_pkg_cnt),
		.srio_rx_ocm_cnt	(srio0_rx_ocm_cnt),
		.srio_rx_4k_cnt		(srio0_rx_4k_cnt),
		.srio_rx_dat_cnt	(srio0_rx_dat_cnt),

		.clk				(clk),
		.rst_n				(rst_n)
	);

	//================================================================================================
	// Instance 2: sp_clloect_4k for SRIO Channel 1
	//================================================================================================
	sp_collect_4k #(
		.BUS_DW			(BUS_DW)
	) u_sp_clloect_4k_1 (
		.sr_iorx_tvalid		(srio1_tvalid),
		.sr_iorx_tready		(srio1_tready),
		.sr_iorx_tlast		(srio1_tlast),
		.sr_iorx_tdata		(srio1_tdata),
		.sr_iorx_tkeep		(srio1_tkeep),
		.sr_iorx_tuser		(srio1_tuser),

		.rio_treq_info_wr	(srio1_info_wr),
		.rio_treq_info_di	(srio1_info_di),
		.rio_treq_info_af	(srio1_info_af),
		.rio_treq_info_fu	(srio1_info_fu),
		.rio_treq_fifo_wr	(srio1_fifo_wr),
		.rio_treq_fifo_di	(srio1_fifo_di),
		.rio_treq_fifo_af	(srio1_fifo_af),
		.rio_treq_fifo_fu	(srio1_fifo_fu),
		.rio_treq_fifo_wl	(srio1_fifo_wl),

		.srio_rx_pkg_cnt	(srio1_rx_pkg_cnt),
		.srio_rx_ocm_cnt	(srio1_rx_ocm_cnt),
		.srio_rx_4k_cnt		(srio1_rx_4k_cnt),
		.srio_rx_dat_cnt	(srio1_rx_dat_cnt),

		.clk				(clk),
		.rst_n				(rst_n)
	);

	//================================================================================================
	// Instance 3: video_send - Video Merge and Ethernet Transmission
	//================================================================================================
	video_send #(
		.SIM				(SIM),
		.DW					(DW),
		.QW					(QW),
		.PR_DN_NUM			(PR_DN_NUM)
	) u_video_send (
		.rio0_treq_info_wr	(srio0_info_wr),
		.rio0_treq_info_di	(srio0_info_di),
		.rio0_treq_info_af	(srio0_info_af),
		.rio0_treq_info_fu	(srio0_info_fu),
		.rio0_treq_fifo_wr	(srio0_fifo_wr),
		.rio0_treq_fifo_di	(srio0_fifo_di),
		.rio0_treq_fifo_af	(srio0_fifo_af),
		.rio0_treq_fifo_fu	(srio0_fifo_fu),
		.rio0_treq_fifo_wl	(srio0_fifo_wl),

		.rio1_treq_info_wr	(srio1_info_wr),
		.rio1_treq_info_di	(srio1_info_di),
		.rio1_treq_info_af	(srio1_info_af),
		.rio1_treq_info_fu	(srio1_info_fu),
		.rio1_treq_fifo_wr	(srio1_fifo_wr),
		.rio1_treq_fifo_di	(srio1_fifo_di),
		.rio1_treq_fifo_af	(srio1_fifo_af),
		.rio1_treq_fifo_fu	(srio1_fifo_fu),
		.rio1_treq_fifo_wl	(srio1_fifo_wl),

		.udp_axis_tdata		(udp_axis_tdata),
		.udp_axis_tready	(udp_axis_tready),
		.udp_axis_tvalid	(udp_axis_tvalid),
		.udp_axis_tkeep		(udp_axis_tkeep),
		.udp_axis_tlast		(udp_axis_tlast),
		.udp_axis_tuser		(udp_axis_tuser),
		.core_clk			(core_clk	)	,
		.clk				(clk),
		.rst_n				(rst_n)
	);

endmodule
