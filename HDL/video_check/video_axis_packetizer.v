`timescale 1ns/1ns

module video_axis_packetizer #(
	parameter	DW				= 64,
	parameter	FRAME_BYTES		= 2048*2048*2,
	parameter	PACKET_BYTES	= 4096
)(
	input							s_axis_tvalid,
	output							s_axis_tready,
	input							s_axis_tlast,
	input		[DW-1:0]			s_axis_tdata,
	input		[DW/8-1:0]			s_axis_tkeep,
	input		[63:0]				s_axis_tuser,

	output							m_axis_tvalid,
	input							m_axis_tready,
	output							m_axis_tlast,
	output		[DW-1:0]			m_axis_tdata,
	output		[DW/8-1:0]			m_axis_tkeep,
	output		[63:0]				m_axis_tuser,

	input							clk,
	input							rst_n
);

	localparam	BEAT_BYTES = DW / 8;

	reg		[31:0]	frame_bytes_left = FRAME_BYTES;
	reg		[31:0]	packet_bytes_sent = 0;
	reg		[31:0]	packet_bytes_cur = (FRAME_BYTES > PACKET_BYTES) ? PACKET_BYTES : FRAME_BYTES;

	wire			axis_fire = s_axis_tvalid && s_axis_tready;
	wire	[31:0]	next_packet_sent = packet_bytes_sent + BEAT_BYTES;
	wire			packet_done = (next_packet_sent >= packet_bytes_cur) || s_axis_tlast;
	wire	[31:0]	frame_bytes_after =
						(s_axis_tlast || frame_bytes_left <= BEAT_BYTES) ?
						FRAME_BYTES :
						(frame_bytes_left - BEAT_BYTES);
	wire	[31:0]	packet_bytes_next =
						(frame_bytes_after > PACKET_BYTES) ?
						PACKET_BYTES :
						frame_bytes_after;
	wire	[15:0]	packet_dwords = packet_bytes_cur[17:2];

	assign s_axis_tready = m_axis_tready;

	assign m_axis_tvalid = s_axis_tvalid;
	assign m_axis_tdata = s_axis_tdata;
	assign m_axis_tkeep = s_axis_tkeep;
	assign m_axis_tlast = packet_done;
	assign m_axis_tuser = {s_axis_tuser[63:16], packet_dwords};

	always @(posedge clk) begin
		if (!rst_n) begin
			frame_bytes_left <= FRAME_BYTES;
			packet_bytes_sent <= 32'd0;
			packet_bytes_cur <= (FRAME_BYTES > PACKET_BYTES) ? PACKET_BYTES : FRAME_BYTES;
		end else if (axis_fire) begin
			frame_bytes_left <= frame_bytes_after;
			if (packet_done) begin
				packet_bytes_sent <= 32'd0;
				packet_bytes_cur <= packet_bytes_next;
			end else begin
				packet_bytes_sent <= next_packet_sent;
				packet_bytes_cur <= packet_bytes_cur;
			end
		end
	end

endmodule
