`timescale 1ns/1ns

module video_stitch_link_tb;

	localparam		FRAME_WIDTH					= 16;
	localparam		FRAME_HEIGHT				= 4;
	localparam		FRAME_BYTES					= FRAME_WIDTH * FRAME_HEIGHT * 2;
	localparam		EXPECT_WORDS				= FRAME_BYTES / 8;
	localparam		EXPECT_DWORDS				= FRAME_BYTES / 4;
	localparam [15:0] EXPECT_DWORDS16			= FRAME_BYTES / 4;

	reg											clk;
	reg											rst_n;
	wire										srio0_tready;
	wire										nontarget_tvalid;
	wire										nontarget_tlast;
	wire	[63:0]								nontarget_tdata;
	wire	[7:0]								nontarget_tkeep;
	wire	[31:0]								nontarget_tuser;
	wire	[63:0]								m_axis_tdata;
	wire										m_axis_tvalid;
	wire	[7:0]								m_axis_tkeep;
	wire										m_axis_tlast;
	wire	[63:0]								m_axis_tuser;
	wire	[31:0]								feature_match_count;
	wire signed [15:0]							stitch_dx;
	wire signed [15:0]							stitch_dy;
	wire	[15:0]								stitch_confidence;
	wire	[31:0]								drop_count;

	integer										timeout_count;
	integer										rx_words;

	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	initial begin
		rst_n = 1'b0;
		timeout_count = 0;
		rx_words = 0;
		#200;
		rst_n = 1'b1;
	end

	always @(posedge clk) begin
		if (rst_n) begin
			timeout_count <= timeout_count + 1;
			if (timeout_count > 200000) begin
				$display("FAIL: video stitch link timeout");
				$finish;
			end
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			rx_words <= 0;
		end else if (m_axis_tvalid) begin
			if (rx_words == 0 && m_axis_tdata[63:0] !== 64'h0003_0002_0001_0000) begin
				$display("FAIL: first gray10 word mismatch: %h", m_axis_tdata);
				$finish;
			end
			if (m_axis_tlast) begin
				if ((rx_words + 1) != EXPECT_WORDS) begin
					$display("FAIL: packet word count %0d expected %0d", rx_words + 1, EXPECT_WORDS);
					$finish;
				end
				if (m_axis_tuser[15:0] != EXPECT_DWORDS16) begin
					$display("FAIL: tuser dword count %0d expected %0d", m_axis_tuser[15:0], EXPECT_DWORDS);
					$finish;
				end
				if (m_axis_tkeep != 8'hff) begin
					$display("FAIL: tkeep mismatch %h", m_axis_tkeep);
					$finish;
				end
				$display("PASS: video stitch link emitted %0d bytes, tuser dwords=%0d",
						 FRAME_BYTES, m_axis_tuser[15:0]);
				$finish;
			end
			rx_words <= rx_words + 1;
		end
	end

	video_stitch_pcie_top #(
		.SIM								(1),
		.BUS_DW								(64),
		.DW									(64),
		.TARGET_SRC_ID						(16'h0000),
		.FRAME_WIDTH						(FRAME_WIDTH),
		.FRAME_HEIGHT						(FRAME_HEIGHT),
		.OVERLAP_WIDTH						(FRAME_WIDTH),
		.RAW10_SHIFT						(6),
		.DUP_SRIO0_ENABLE					(1),
		.TEST_PATTERN_ENABLE				(1),
		.TEST_PACKET_BYTES					(FRAME_BYTES)
	) dut (
		.srio0_tvalid						(1'b0),
		.srio0_tready						(srio0_tready),
		.srio0_tlast						(1'b0),
		.srio0_tdata						(64'd0),
		.srio0_tkeep						(8'd0),
		.srio0_tuser						(32'd0),
		.srio0_nontarget_tvalid			(nontarget_tvalid),
		.srio0_nontarget_tready			(1'b1),
		.srio0_nontarget_tlast				(nontarget_tlast),
		.srio0_nontarget_tdata				(nontarget_tdata),
		.srio0_nontarget_tkeep				(nontarget_tkeep),
		.srio0_nontarget_tuser				(nontarget_tuser),
		.m_axis_tdata						(m_axis_tdata),
		.m_axis_tready						(1'b1),
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
