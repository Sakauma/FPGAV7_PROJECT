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
	parameter		SOURCE_MODE					= (TEST_PATTERN_ENABLE ? 1 : 0),
	parameter		TEST_PACKET_BYTES			= 4096
)(
	input										srio0_tvalid,
	output										srio0_tready,
	input										srio0_tlast,
	input		[63:0]							srio0_tdata,
	input		[7:0]							srio0_tkeep,
	input		[31:0]							srio0_tuser,

	input										replay_tvalid,
	output										replay_tready,
	input										replay_tlast,
	input		[63:0]							replay_tdata,
	input		[7:0]							replay_tkeep,
	input		[31:0]							replay_tuser,

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
	wire										use_srio0_source;
	wire										use_pattern_source;
	wire										use_replay_source;

	assign use_srio0_source   = (SOURCE_MODE == 0);
	assign use_pattern_source = (SOURCE_MODE == 1);
	assign use_replay_source  = (SOURCE_MODE == 2);

	assign classifier_srio_tvalid = use_replay_source ? replay_tvalid :
									use_pattern_source ? pattern_tvalid : srio0_tvalid;
	assign classifier_srio_tlast  = use_replay_source ? replay_tlast :
									use_pattern_source ? pattern_tlast  : srio0_tlast;
	assign classifier_srio_tdata  = use_replay_source ? replay_tdata :
									use_pattern_source ? pattern_tdata  : srio0_tdata;
	assign classifier_srio_tkeep  = use_replay_source ? replay_tkeep :
									use_pattern_source ? pattern_tkeep  : srio0_tkeep;
	assign classifier_srio_tuser  = use_replay_source ? replay_tuser :
									use_pattern_source ? pattern_tuser  : srio0_tuser;
	assign pattern_tready         = use_pattern_source ? classifier_srio_tready : 1'b0;
	assign replay_tready          = use_replay_source ? classifier_srio_tready : 1'b0;
	assign srio0_tready           = use_srio0_source ? classifier_srio_tready : 1'b1;

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

////////////////////////////////////////////////////////////////////////////////////////////////////
// Original-protocol bring-up path.
// Input packets keep the legacy SRIO-like 4KB payload shape; only the payload pixels pass through
// the replaceable algorithm stage before being returned to sp_cond_up through sp_rx.
////////////////////////////////////////////////////////////////////////////////////////////////////
module video_original_hls_pcie_top #(
	parameter		SIM							= 0,
	parameter		BUS_DW						= 64,
	parameter		DW							= 64,
	parameter		TARGET_SRC_ID				= 16'h0000,
	parameter		FRAME_WIDTH					= 2048,
	parameter		FRAME_HEIGHT				= 2048,
	parameter		RAW10_SHIFT					= 6,
	parameter		TEST_PACKET_BYTES			= 4096,
	parameter		SOURCE_MODE					= 1
)(
	input										srio0_tvalid,
	output										srio0_tready,
	input										srio0_tlast,
	input		[DW-1:0]						srio0_tdata,
	input		[DW/8-1:0]						srio0_tkeep,
	input		[31:0]							srio0_tuser,

	output										srio0_nontarget_tvalid,
	input										srio0_nontarget_tready,
	output										srio0_nontarget_tlast,
	output		[DW-1:0]						srio0_nontarget_tdata,
	output		[DW/8-1:0]						srio0_nontarget_tkeep,
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

	wire										use_srio0_source;
	wire										pattern_tvalid;
	wire										pattern_tready;
	wire										pattern_tlast;
	wire	[DW-1:0]							pattern_tdata;
	wire	[DW/8-1:0]							pattern_tkeep;
	wire	[31:0]								pattern_tuser;

	wire										source_tvalid;
	wire										source_tready;
	wire										source_tlast;
	wire	[DW-1:0]							source_tdata;
	wire	[DW/8-1:0]							source_tkeep;
	wire	[31:0]								source_tuser;

	wire										target_tvalid;
	wire										target_tready;
	wire										target_tlast;
	wire	[DW-1:0]							target_tdata;
	wire	[DW/8-1:0]							target_tkeep;
	wire	[31:0]								target_tuser;

	wire										info_wr;
	wire	[63:0]								info_di;
	wire										info_af;
	wire										info_fu;
	wire										fifo_wr;
	wire	[DW-1:0]							fifo_di;
	wire										fifo_af;
	wire										fifo_fu;
	wire										fifo_wl;

	wire										raw_axis_tvalid;
	wire										raw_axis_tready;
	wire										raw_axis_tlast;
	wire	[DW-1:0]							raw_axis_tdata;
	wire	[DW/8-1:0]							raw_axis_tkeep;
	wire	[63:0]								raw_axis_tuser;
	wire	[31:0]								collect_drop_count;

	assign use_srio0_source = (SOURCE_MODE == 0);

	assign source_tvalid = use_srio0_source ? srio0_tvalid : pattern_tvalid;
	assign source_tlast  = use_srio0_source ? srio0_tlast  : pattern_tlast;
	assign source_tdata  = use_srio0_source ? srio0_tdata  : pattern_tdata;
	assign source_tkeep  = use_srio0_source ? srio0_tkeep  : pattern_tkeep;
	assign source_tuser  = use_srio0_source ? srio0_tuser  : pattern_tuser;
	assign srio0_tready  = use_srio0_source ? source_tready : 1'b1;
	assign pattern_tready = use_srio0_source ? 1'b0 : source_tready;

	assign feature_match_count = 32'd0;
	assign stitch_dx = 16'sd0;
	assign stitch_dy = 16'sd0;
	assign stitch_confidence = 16'd0;
	assign drop_count = collect_drop_count;

	video_srio_pattern_src #(
		.DW									(DW),
		.TARGET_SRC_ID						(TARGET_SRC_ID),
		.FRAME_WIDTH						(FRAME_WIDTH),
		.FRAME_HEIGHT						(FRAME_HEIGHT),
		.PACKET_BYTES						(TEST_PACKET_BYTES),
		.RAW10_SHIFT						(RAW10_SHIFT)
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
		.DATA_WIDTH							(DW),
		.USER_WIDTH							(32),
		.KEEP_WIDTH							(DW/8)
	) u_srio_data_classifier (
		.srio_tvalid						(source_tvalid),
		.srio_tready						(source_tready),
		.srio_tlast							(source_tlast),
		.srio_tdata							(source_tdata),
		.srio_tkeep							(source_tkeep),
		.srio_tuser							(source_tuser),
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
	) u_sp_collect_4k (
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
		.srio_rx_pkg_cnt					(),
		.srio_rx_ocm_cnt					(),
		.srio_rx_4k_cnt						(),
		.srio_rx_dat_cnt					(),
		.clk								(clk),
		.rst_n								(rst_n)
	);

	video_collect_axis_source #(
		.DW									(DW)
	) u_video_collect_axis_source (
		.rio_treq_info_wr					(info_wr),
		.rio_treq_info_di					(info_di),
		.rio_treq_info_af					(info_af),
		.rio_treq_info_fu					(info_fu),
		.rio_treq_fifo_wr					(fifo_wr),
		.rio_treq_fifo_di					(fifo_di),
		.rio_treq_fifo_af					(fifo_af),
		.rio_treq_fifo_fu					(fifo_fu),
		.rio_treq_fifo_wl					(fifo_wl),
		.m_axis_tdata						(raw_axis_tdata),
		.m_axis_tready						(raw_axis_tready),
		.m_axis_tvalid						(raw_axis_tvalid),
		.m_axis_tkeep						(raw_axis_tkeep),
		.m_axis_tlast						(raw_axis_tlast),
		.m_axis_tuser						(raw_axis_tuser),
		.packet_count						(),
		.drop_count							(collect_drop_count),
		.clk								(clk),
		.rst_n								(rst_n)
	);

	video_gray10_axis_hls_stub #(
		.DW									(DW),
		.RAW10_SHIFT						(RAW10_SHIFT)
	) u_video_gray10_axis_hls_stub (
		.s_axis_tvalid						(raw_axis_tvalid),
		.s_axis_tready						(raw_axis_tready),
		.s_axis_tlast						(raw_axis_tlast),
		.s_axis_tdata						(raw_axis_tdata),
		.s_axis_tkeep						(raw_axis_tkeep),
		.s_axis_tuser						(raw_axis_tuser),
		.m_axis_tvalid						(m_axis_tvalid),
		.m_axis_tready						(m_axis_tready),
		.m_axis_tlast						(m_axis_tlast),
		.m_axis_tdata						(m_axis_tdata),
		.m_axis_tkeep						(m_axis_tkeep),
		.m_axis_tuser						(m_axis_tuser),
		.clk								(clk),
		.rst_n								(rst_n)
	);

endmodule

module video_gray10_axis_hls_stub #(
	parameter		DW							= 64,
	parameter		RAW10_SHIFT					= 6
)(
	input										s_axis_tvalid,
	output										s_axis_tready,
	input										s_axis_tlast,
	input		[DW-1:0]						s_axis_tdata,
	input		[DW/8-1:0]						s_axis_tkeep,
	input		[63:0]							s_axis_tuser,

	output										m_axis_tvalid,
	input										m_axis_tready,
	output										m_axis_tlast,
	output		[DW-1:0]						m_axis_tdata,
	output		[DW/8-1:0]						m_axis_tkeep,
	output		[63:0]							m_axis_tuser,

	input										clk,
	input										rst_n
);

	function [15:0] f_raw10;
		input [15:0] pix16;
		reg [15:0] shifted;
		begin
			shifted = pix16 >> RAW10_SHIFT;
			f_raw10 = {6'd0, shifted[9:0]};
		end
	endfunction

	assign s_axis_tready = m_axis_tready;
	assign m_axis_tvalid = s_axis_tvalid;
	assign m_axis_tlast  = s_axis_tlast;
	assign m_axis_tkeep  = s_axis_tkeep;
	assign m_axis_tuser  = s_axis_tuser;
	assign m_axis_tdata  = {f_raw10(s_axis_tdata[63:48]),
							f_raw10(s_axis_tdata[47:32]),
							f_raw10(s_axis_tdata[31:16]),
							f_raw10(s_axis_tdata[15:0])};

endmodule

module video_collect_axis_source #(
	parameter		DW							= 64
)(
	input										rio_treq_info_wr,
	input		[63:0]							rio_treq_info_di,
	output										rio_treq_info_af,
	output										rio_treq_info_fu,
	input										rio_treq_fifo_wr,
	input		[DW-1:0]						rio_treq_fifo_di,
	output										rio_treq_fifo_af,
	output										rio_treq_fifo_fu,
	input										rio_treq_fifo_wl,

	output		[DW-1:0]						m_axis_tdata,
	input										m_axis_tready,
	output										m_axis_tvalid,
	output		[DW/8-1:0]						m_axis_tkeep,
	output										m_axis_tlast,
	output		[63:0]							m_axis_tuser,

	output	reg	[31:0]							packet_count,
	output	reg	[31:0]							drop_count,

	input										clk,
	input										rst_n
);

	function [15:0] f_ceil_div8;
		input [15:0] byte_count;
		begin
			f_ceil_div8 = {3'd0, byte_count[15:3]} + (|byte_count[2:0]);
		end
	endfunction

	localparam		ST_IDLE						= 2'b01;
	localparam		ST_SEND						= 2'b10;

	reg		[1:0]								cs;
	reg		[15:0]								active_bytes;
	reg		[15:0]								active_qwords;
	reg		[15:0]								bytes_left;

	wire										info_rd;
	wire	[63:0]								info_do;
	wire										info_ae;
	wire										info_em;
	wire										fifo_rd;
	wire	[DW-1:0]							fifo_do;
	wire										fifo_ae;
	wire										fifo_em;
	wire										trv;
	wire										packet_last;

	assign m_axis_tdata  = fifo_do;
	assign m_axis_tkeep  = {(DW/8){1'b1}};
	assign m_axis_tvalid = (cs == ST_SEND) && (~fifo_em);
	assign packet_last   = (bytes_left <= 16'd8);
	assign m_axis_tlast  = m_axis_tvalid && packet_last;
	assign m_axis_tuser  = {48'd0, active_qwords};
	assign trv           = m_axis_tvalid && m_axis_tready;
	assign fifo_rd       = trv;
	assign info_rd       = (cs == ST_IDLE) && (~info_em);

	always @(posedge clk) begin
		if (~rst_n) begin
			cs				<= ST_IDLE;
			active_bytes	<= 16'd0;
			active_qwords	<= 16'd0;
			bytes_left		<= 16'd0;
			packet_count	<= 32'd0;
			drop_count		<= 32'd0;
		end else begin
			if ((rio_treq_info_wr && rio_treq_info_fu) ||
				(rio_treq_fifo_wr && rio_treq_fifo_fu)) begin
				drop_count <= drop_count + 1'b1;
			end

			case (cs)
			ST_IDLE: begin
				if (info_rd) begin
					cs				<= ST_SEND;
					active_bytes	<= info_do[15:0];
					active_qwords	<= f_ceil_div8(info_do[15:0]);
					bytes_left		<= info_do[15:0];
				end
			end

			ST_SEND: begin
				if (trv) begin
					if (packet_last) begin
						cs			<= ST_IDLE;
						bytes_left	<= 16'd0;
						packet_count <= packet_count + 1'b1;
					end else begin
						bytes_left	<= bytes_left - 16'd8;
					end
				end
			end

			default: begin
				cs <= ST_IDLE;
			end
			endcase
		end
	end

	hdl_eqw_afifo #(
		.LOOP_NUM					(1),
		.RAM_STYLE					("distributed"),
		.ALMOST_EMPTY_OFFSET		('h8),
		.ALMOST_FULL_OFFSET			('h8),
		.FIRST_WORD_FALL_THROUGH	("TRUE"),
		.AW							(5),
		.DW							(64)
	) u_info_fifo (
		.RST						(~rst_n),
		.WRCLK						(clk),
		.WRCOUNT					(),
		.WRERR						(),
		.WREN						(rio_treq_info_wr),
		.DI							(rio_treq_info_di),
		.ALMOSTFULL					(rio_treq_info_af),
		.FULL						(rio_treq_info_fu),
		.RDEN						(info_rd),
		.DO							(info_do),
		.ALMOSTEMPTY				(info_ae),
		.EMPTY						(info_em),
		.RDCOUNT					(),
		.RDERR						(),
		.RDCLK						(clk)
	);

	hdl_exw_afifo #(
		.LOOP_NUM					(1),
		.RAM_STYLE					("block"),
		.ALMOST_EMPTY_OFFSET		('h10),
		.ALMOST_FULL_OFFSET			('h10),
		.FIRST_WORD_FALL_THROUGH	("TRUE"),
		.AW							(10),
		.DW							(DW),
		.QW							(DW)
	) u_data_fifo (
		.RST						(~rst_n),
		.WRCLK						(clk),
		.WRCOUNT					(),
		.WRERR						(),
		.WREN_CLEAR					(1'b0),
		.WREN_LAST					(rio_treq_fifo_wl),
		.WREN						(rio_treq_fifo_wr),
		.DI							(rio_treq_fifo_di),
		.ALMOSTFULL					(rio_treq_fifo_af),
		.FULL						(rio_treq_fifo_fu),
		.RDEN_LAST					(m_axis_tlast && trv),
		.RDEN						(fifo_rd),
		.DO							(fifo_do),
		.ALMOSTEMPTY				(fifo_ae),
		.EMPTY						(fifo_em),
		.RDCOUNT					(),
		.RDERR						(),
		.RDCLK						(clk)
	);

endmodule
