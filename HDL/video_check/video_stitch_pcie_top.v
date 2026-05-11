`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// SRIO0 video stitch path to PCIe.
// Current bring-up uses one SRIO0 video source and duplicates it logically. The stitch estimator
// therefore reports zero offset while the data path emits 10-bit pixels in 16-bit containers.
////////////////////////////////////////////////////////////////////////////////////////////////////
module video_stitch_pcie_top #(
	parameter		SIM							= 0,
	parameter		BUS_DW						= 64,
	parameter		DW							= 64,
	parameter		TARGET_SRC_ID				= 16'h0000,
	parameter		FRAME_WIDTH					= 1920,
	parameter		FRAME_HEIGHT				= 1080,
	parameter		OVERLAP_WIDTH				= 1920,
	parameter		RAW10_SHIFT					= 6,
	parameter		DUP_SRIO0_ENABLE			= 1,
	parameter		TEST_PATTERN_ENABLE			= 1,
	parameter		TEST_PACKET_BYTES			= 4096
)(
	input										srio0_tvalid,
	output										srio0_tready,
	input										srio0_tlast,
	input		[63:0]							srio0_tdata,
	input		[7:0]							srio0_tkeep,
	input		[31:0]							srio0_tuser,

	output										srio0_nontarget_tvalid,
	input										srio0_nontarget_tready,
	output										srio0_nontarget_tlast,
	output		[63:0]							srio0_nontarget_tdata,
	output		[7:0]							srio0_nontarget_tkeep,
	output		[31:0]							srio0_nontarget_tuser,

	output		[DW-1:0]						m_axis_tdata,
	input										m_axis_tready,
	output										m_axis_tvalid,
	output		[DW/8-1:0]						m_axis_tkeep,
	output										m_axis_tlast,
	output		[63:0]							m_axis_tuser,

	output		[31:0]							feature_match_count,
	output signed [15:0]						stitch_dx,
	output signed [15:0]						stitch_dy,
	output		[15:0]							stitch_confidence,
	output		[31:0]							drop_count,

	input										clk,
	input										rst_n
);

	wire										target_tvalid;
	wire										target_tready;
	wire										target_tlast;
	wire	[63:0]								target_tdata;
	wire	[7:0]								target_tkeep;
	wire	[31:0]								target_tuser;

	wire										info_wr;
	wire	[63:0]								info_di;
	wire										info_af;
	wire										info_fu;
	wire										fifo_wr;
	wire	[BUS_DW-1:0]						fifo_di;
	wire										fifo_af;
	wire										fifo_fu;
	wire										fifo_wl;

	wire	[31:0]								rx_pkg_cnt;
	wire	[31:0]								rx_ocm_cnt;
	wire	[31:0]								rx_4k_cnt;
	wire	[31:0]								rx_dat_cnt;
	wire										classifier_srio_tvalid;
	wire										classifier_srio_tready;
	wire										classifier_srio_tlast;
	wire	[63:0]								classifier_srio_tdata;
	wire	[7:0]								classifier_srio_tkeep;
	wire	[31:0]								classifier_srio_tuser;
	wire										pattern_tvalid;
	wire										pattern_tready;
	wire										pattern_tlast;
	wire	[63:0]								pattern_tdata;
	wire	[7:0]								pattern_tkeep;
	wire	[31:0]								pattern_tuser;

	assign classifier_srio_tvalid = TEST_PATTERN_ENABLE ? pattern_tvalid : srio0_tvalid;
	assign classifier_srio_tlast  = TEST_PATTERN_ENABLE ? pattern_tlast  : srio0_tlast;
	assign classifier_srio_tdata  = TEST_PATTERN_ENABLE ? pattern_tdata  : srio0_tdata;
	assign classifier_srio_tkeep  = TEST_PATTERN_ENABLE ? pattern_tkeep  : srio0_tkeep;
	assign classifier_srio_tuser  = TEST_PATTERN_ENABLE ? pattern_tuser  : srio0_tuser;
	assign pattern_tready         = TEST_PATTERN_ENABLE ? classifier_srio_tready : 1'b0;
	assign srio0_tready           = TEST_PATTERN_ENABLE ? 1'b1 : classifier_srio_tready;

	video_srio_pattern_src #(
		.DW									(64),
		.TARGET_SRC_ID						(TARGET_SRC_ID),
		.FRAME_WIDTH						(FRAME_WIDTH),
		.FRAME_HEIGHT						(FRAME_HEIGHT),
		.PACKET_BYTES						(TEST_PACKET_BYTES),
		.RAW10_SHIFT						(RAW10_SHIFT),
		.FRAME_GAP_CYCLES					(1024)
	) u_video_srio_pattern_src (
		.m_axis_tvalid						(pattern_tvalid),
		.m_axis_tready						(pattern_tready),
		.m_axis_tlast						(pattern_tlast),
		.m_axis_tdata						(pattern_tdata),
		.m_axis_tkeep						(pattern_tkeep),
		.m_axis_tuser						(pattern_tuser),
		.clk								(clk),
		.rst_n								(rst_n)
	);

	srio_data_classifier #(
		.SIM								(SIM),
		.TARGET_SRC_ID						(TARGET_SRC_ID),
		.FIFO_DEPTH							(1024),
		.DATA_WIDTH							(64),
		.USER_WIDTH							(32),
		.KEEP_WIDTH							(8)
	) u_srio_data_classifier (
		.srio_tvalid						(classifier_srio_tvalid),
		.srio_tready						(classifier_srio_tready),
		.srio_tlast							(classifier_srio_tlast),
		.srio_tdata							(classifier_srio_tdata),
		.srio_tkeep							(classifier_srio_tkeep),
		.srio_tuser							(classifier_srio_tuser),

		.target_tvalid						(target_tvalid),
		.target_tready						(target_tready),
		.target_tlast						(target_tlast),
		.target_tdata						(target_tdata),
		.target_tkeep						(target_tkeep),
		.target_tuser						(target_tuser),

		.nontarget_tvalid					(srio0_nontarget_tvalid),
		.nontarget_tready					(srio0_nontarget_tready),
		.nontarget_tlast					(srio0_nontarget_tlast),
		.nontarget_tdata					(srio0_nontarget_tdata),
		.nontarget_tkeep					(srio0_nontarget_tkeep),
		.nontarget_tuser					(srio0_nontarget_tuser),

		.clk								(clk),
		.rst_n								(rst_n)
	);

	sp_collect_4k #(
		.BUS_DW								(BUS_DW)
	) u_sp_collect_4k_video (
		.sr_iorx_tvalid						(target_tvalid),
		.sr_iorx_tready						(target_tready),
		.sr_iorx_tlast						(target_tlast),
		.sr_iorx_tdata						(target_tdata),
		.sr_iorx_tkeep						(target_tkeep),
		.sr_iorx_tuser						(target_tuser),

		.rio_treq_info_wr					(info_wr),
		.rio_treq_info_di					(info_di),
		.rio_treq_info_af					(info_af),
		.rio_treq_info_fu					(info_fu),
		.rio_treq_fifo_wr					(fifo_wr),
		.rio_treq_fifo_di					(fifo_di),
		.rio_treq_fifo_af					(fifo_af),
		.rio_treq_fifo_fu					(fifo_fu),
		.rio_treq_fifo_wl					(fifo_wl),

		.srio_rx_pkg_cnt					(rx_pkg_cnt),
		.srio_rx_ocm_cnt					(rx_ocm_cnt),
		.srio_rx_4k_cnt						(rx_4k_cnt),
		.srio_rx_dat_cnt					(rx_dat_cnt),

		.clk								(clk),
		.rst_n								(rst_n)
	);

	video_stitch_stream #(
		.DW									(DW),
		.RAW10_SHIFT						(RAW10_SHIFT)
	) u_video_stitch_stream (
		.rio_treq_info_wr					(info_wr),
		.rio_treq_info_di					(info_di),
		.rio_treq_info_af					(info_af),
		.rio_treq_info_fu					(info_fu),
		.rio_treq_fifo_wr					(fifo_wr),
		.rio_treq_fifo_di					(fifo_di),
		.rio_treq_fifo_af					(fifo_af),
		.rio_treq_fifo_fu					(fifo_fu),
		.rio_treq_fifo_wl					(fifo_wl),

		.m_axis_tdata						(m_axis_tdata),
		.m_axis_tready						(m_axis_tready),
		.m_axis_tvalid						(m_axis_tvalid),
		.m_axis_tkeep						(m_axis_tkeep),
		.m_axis_tlast						(m_axis_tlast),
		.m_axis_tuser						(m_axis_tuser),

		.feature_match_count				(feature_match_count),
		.stitch_dx							(stitch_dx),
		.stitch_dy							(stitch_dy),
		.stitch_confidence					(stitch_confidence),
		.drop_count							(drop_count),

		.clk								(clk),
		.rst_n								(rst_n)
	);

endmodule
