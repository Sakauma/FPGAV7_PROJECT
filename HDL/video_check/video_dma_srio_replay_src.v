`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// DMA-loaded video replay source.
// RK3588 sends one 64-byte frame header followed by raw16 payload packets. This module strips the
// header and replays each payload packet as the SRIO-shaped stream consumed by srio_data_classifier:
// one 64-bit SRIO header beat followed by raw16 payload beats.
////////////////////////////////////////////////////////////////////////////////////////////////////
module video_dma_srio_replay_src #(
	parameter		DW							= 64,
	parameter		TARGET_SRC_ID				= 16'h0000,
	parameter		FRAME_WIDTH					= 2048,
	parameter		FRAME_HEIGHT				= 2048
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
	output		[31:0]							m_axis_tuser,

	output	reg	[31:0]							frame_count,
	output	reg	[31:0]							payload_packet_count,
	output	reg	[31:0]							bad_header_count,

	input										clk,
	input										rst_n
);

	localparam		ST_WAIT_HEADER				= 3'd0;
	localparam		ST_READ_HEADER				= 3'd1;
	localparam		ST_DISCARD					= 3'd2;
	localparam		ST_PACKET_HEADER			= 3'd3;
	localparam		ST_PAYLOAD					= 3'd4;

	localparam [63:0] FRAME_MAGIC				= 64'h30474d4956475046;	// "FPGVIMG0"
	localparam [63:0] SRIO_PACKET_HEADER		= 64'h0000000000001000;
	localparam [31:0] FRAME_BYTES				= FRAME_WIDTH * FRAME_HEIGHT * 2;

	reg		[2:0]								cs;
	reg		[3:0]								header_word_count;
	reg		[31:0]								frame_byte_count;

	wire										in_trv;
	wire										out_trv;
	wire	[3:0]								keep_bytes;
	wire	[31:0]								next_frame_byte_count;

	function [3:0] f_keep_bytes;
		input [DW/8-1:0] keep;
		integer i;
		begin
			f_keep_bytes = 4'd0;
			for (i = 0; i < DW/8; i = i + 1) begin
				f_keep_bytes = f_keep_bytes + {3'd0, keep[i]};
			end
		end
	endfunction

	assign s_axis_tready = ((cs == ST_WAIT_HEADER) || (cs == ST_READ_HEADER) ||
							(cs == ST_DISCARD)) ? 1'b1 :
						   (cs == ST_PAYLOAD) ? m_axis_tready : 1'b0;

	assign m_axis_tvalid = (cs == ST_PACKET_HEADER) ? s_axis_tvalid :
						   (cs == ST_PAYLOAD) ? s_axis_tvalid : 1'b0;
	assign m_axis_tlast  = (cs == ST_PAYLOAD) ? s_axis_tlast : 1'b0;
	assign m_axis_tdata  = (cs == ST_PACKET_HEADER) ? SRIO_PACKET_HEADER : s_axis_tdata;
	assign m_axis_tkeep  = (cs == ST_PACKET_HEADER) ? {(DW/8){1'b1}} : s_axis_tkeep;
	assign m_axis_tuser  = {TARGET_SRC_ID, 16'd0};

	assign in_trv = s_axis_tvalid && s_axis_tready;
	assign out_trv = m_axis_tvalid && m_axis_tready;
	assign keep_bytes = f_keep_bytes(s_axis_tkeep);
	assign next_frame_byte_count = frame_byte_count + {28'd0, keep_bytes};

	always @(posedge clk) begin
		if (~rst_n) begin
			cs						<= ST_WAIT_HEADER;
			header_word_count		<= 4'd0;
			frame_byte_count		<= 32'd0;
			frame_count				<= 32'd0;
			payload_packet_count	<= 32'd0;
			bad_header_count		<= 32'd0;
		end else begin
			case (cs)
			ST_WAIT_HEADER: begin
				header_word_count <= 4'd0;
				if (in_trv) begin
					if (s_axis_tdata == FRAME_MAGIC) begin
						header_word_count <= 4'd1;
						if (s_axis_tlast) begin
							bad_header_count <= bad_header_count + 1'b1;
							cs <= ST_WAIT_HEADER;
						end else begin
							cs <= ST_READ_HEADER;
						end
					end else begin
						bad_header_count <= bad_header_count + 1'b1;
						cs <= s_axis_tlast ? ST_WAIT_HEADER : ST_DISCARD;
					end
				end
			end

			ST_READ_HEADER: begin
				if (in_trv) begin
					if (header_word_count == 4'd7) begin
						header_word_count <= 4'd0;
						frame_byte_count <= 32'd0;
						if (s_axis_tlast) begin
							cs <= ST_PACKET_HEADER;
						end else begin
							bad_header_count <= bad_header_count + 1'b1;
							cs <= ST_DISCARD;
						end
					end else begin
						header_word_count <= header_word_count + 1'b1;
						if (s_axis_tlast) begin
							bad_header_count <= bad_header_count + 1'b1;
							cs <= ST_WAIT_HEADER;
						end
					end
				end
			end

			ST_DISCARD: begin
				if (in_trv && s_axis_tlast) begin
					cs <= ST_WAIT_HEADER;
				end
			end

			ST_PACKET_HEADER: begin
				if (out_trv) begin
					cs <= ST_PAYLOAD;
				end
			end

			ST_PAYLOAD: begin
				if (out_trv) begin
					if (s_axis_tlast) begin
						payload_packet_count <= payload_packet_count + 1'b1;
						if (next_frame_byte_count >= FRAME_BYTES) begin
							frame_count <= frame_count + 1'b1;
							frame_byte_count <= 32'd0;
							cs <= ST_WAIT_HEADER;
						end else begin
							frame_byte_count <= next_frame_byte_count;
							cs <= ST_PACKET_HEADER;
						end
					end else begin
						frame_byte_count <= next_frame_byte_count;
					end
				end
			end

			default: begin
				cs <= ST_WAIT_HEADER;
			end
			endcase
		end
	end

endmodule
