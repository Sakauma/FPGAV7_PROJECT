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
	reg											replay_tvalid;
	wire										replay_tready;
	reg											replay_tlast;
	reg		[63:0]								replay_tdata;
	reg		[7:0]								replay_tkeep;
	reg		[31:0]								replay_tuser;
	wire										srio_replay_tvalid;
	wire										srio_replay_tready;
	wire										srio_replay_tlast;
	wire	[63:0]								srio_replay_tdata;
	wire	[7:0]								srio_replay_tkeep;
	wire	[31:0]								srio_replay_tuser;
	wire	[31:0]								replay_frame_count;
	wire	[31:0]								replay_payload_packet_count;
	wire	[31:0]								replay_bad_header_count;

	integer										timeout_count;
	integer										rx_words;
	integer										tx_words;

	function [15:0] f_test_pix16;
		input integer pixel_index;
		begin
			f_test_pix16 = pixel_index[15:0] << 6;
		end
	endfunction

	task send_replay_word;
		input [63:0] data;
		input last;
		begin
			@(negedge clk);
			replay_tdata = data;
			replay_tkeep = 8'hff;
			replay_tlast = last;
			replay_tvalid = 1'b1;
			while (~replay_tready) begin
				@(negedge clk);
			end
			@(posedge clk);
			@(negedge clk);
			replay_tvalid = 1'b0;
			replay_tlast = 1'b0;
			replay_tdata = 64'd0;
		end
	endtask

	task send_frame_header;
		begin
			send_replay_word(64'h30474d4956475046, 1'b0);	// "FPGVIMG0"
			send_replay_word(64'h00000001_00000040, 1'b0);
			send_replay_word({32'd4, 32'd16}, 1'b0);
			send_replay_word({32'd0, FRAME_BYTES}, 1'b0);
			send_replay_word({32'd0, 32'd4096}, 1'b0);
			send_replay_word(64'd0, 1'b0);
			send_replay_word(64'd0, 1'b0);
			send_replay_word(64'd0, 1'b1);
		end
	endtask

	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	initial begin
		rst_n = 1'b0;
		timeout_count = 0;
		rx_words = 0;
		tx_words = 0;
		replay_tvalid = 1'b0;
		replay_tlast = 1'b0;
		replay_tdata = 64'd0;
		replay_tkeep = 8'hff;
		replay_tuser = 32'd0;
		#200;
		rst_n = 1'b1;
	end

	initial begin
		wait(rst_n == 1'b1);
		repeat (20) @(posedge clk);
		send_frame_header();
		for (tx_words = 0; tx_words < EXPECT_WORDS; tx_words = tx_words + 1) begin
			send_replay_word({f_test_pix16(tx_words * 4 + 3),
							  f_test_pix16(tx_words * 4 + 2),
							  f_test_pix16(tx_words * 4 + 1),
							  f_test_pix16(tx_words * 4 + 0)},
							 (tx_words == EXPECT_WORDS - 1));
		end
	end

	always @(posedge clk) begin
		if (rst_n) begin
			timeout_count <= timeout_count + 1;
			if (timeout_count > 200000) begin
				$display("FAIL: video stitch link timeout frame=%0d packets=%0d bad=%0d replay_valid=%0d replay_ready=%0d",
						 replay_frame_count, replay_payload_packet_count, replay_bad_header_count,
						 srio_replay_tvalid, srio_replay_tready);
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

	video_dma_srio_replay_src #(
		.DW									(64),
		.TARGET_SRC_ID						(16'h0000),
		.FRAME_WIDTH						(FRAME_WIDTH),
		.FRAME_HEIGHT						(FRAME_HEIGHT)
	) replay_src (
		.s_axis_tvalid						(replay_tvalid),
		.s_axis_tready						(replay_tready),
		.s_axis_tlast						(replay_tlast),
		.s_axis_tdata						(replay_tdata),
		.s_axis_tkeep						(replay_tkeep),
		.s_axis_tuser						({32'd0, replay_tuser}),
		.m_axis_tvalid						(srio_replay_tvalid),
		.m_axis_tready						(srio_replay_tready),
		.m_axis_tlast						(srio_replay_tlast),
		.m_axis_tdata						(srio_replay_tdata),
		.m_axis_tkeep						(srio_replay_tkeep),
		.m_axis_tuser						(srio_replay_tuser),
		.frame_count						(replay_frame_count),
		.payload_packet_count				(replay_payload_packet_count),
		.bad_header_count					(replay_bad_header_count),
		.clk								(clk),
		.rst_n								(rst_n)
	);

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
		.TEST_PATTERN_ENABLE				(0),
		.SOURCE_MODE						(2),
		.TEST_PACKET_BYTES					(FRAME_BYTES)
	) dut (
		.srio0_tvalid						(1'b0),
		.srio0_tready						(srio0_tready),
		.srio0_tlast						(1'b0),
		.srio0_tdata						(64'd0),
		.srio0_tkeep						(8'd0),
		.srio0_tuser						(32'd0),
		.replay_tvalid						(srio_replay_tvalid),
		.replay_tready						(srio_replay_tready),
		.replay_tlast						(srio_replay_tlast),
		.replay_tdata						(srio_replay_tdata),
		.replay_tkeep						(srio_replay_tkeep),
		.replay_tuser						(srio_replay_tuser),
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
