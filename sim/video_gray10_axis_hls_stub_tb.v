`timescale 1ns/1ps

module video_gray10_axis_hls_stub_tb;
	reg				s_axis_tvalid;
	wire			s_axis_tready;
	reg				s_axis_tlast;
	reg		[63:0]	s_axis_tdata;
	reg		[7:0]	s_axis_tkeep;
	reg		[63:0]	s_axis_tuser;
	wire			m_axis_tvalid;
	reg				m_axis_tready;
	wire			m_axis_tlast;
	wire	[63:0]	m_axis_tdata;
	wire	[7:0]	m_axis_tkeep;
	wire	[63:0]	m_axis_tuser;
	reg				clk;
	reg				rst_n;

	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	initial begin
		rst_n = 1'b1;
		s_axis_tvalid = 1'b1;
		s_axis_tlast = 1'b1;
		s_axis_tkeep = 8'hff;
		s_axis_tuser = 64'h1234;
		m_axis_tready = 1'b1;
		s_axis_tdata = {16'hffc0, 16'h8000, 16'h0040, 16'h0000};
		#1;
		if (m_axis_tdata !== {16'h03ff, 16'h0200, 16'h0001, 16'h0000}) begin
			$fatal(1, "unexpected converted data: %h", m_axis_tdata);
		end
		if (!m_axis_tvalid || !m_axis_tready || !m_axis_tlast ||
			m_axis_tkeep !== 8'hff || m_axis_tuser !== 64'h1234) begin
			$fatal(1, "sideband propagation failed");
		end
		$finish;
	end

	video_gray10_axis_hls_stub #(
		.DW(64),
		.RAW10_SHIFT(6)
	) dut (
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready),
		.s_axis_tlast(s_axis_tlast),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tkeep(s_axis_tkeep),
		.s_axis_tuser(s_axis_tuser),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(m_axis_tlast),
		.m_axis_tdata(m_axis_tdata),
		.m_axis_tkeep(m_axis_tkeep),
		.m_axis_tuser(m_axis_tuser),
		.clk(clk),
		.rst_n(rst_n)
	);
endmodule
