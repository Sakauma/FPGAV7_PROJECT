`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// SRIO-shaped video pattern source.
// It emits the same packet shape consumed by srio_data_classifier and sp_collect_4k: one header beat
// followed by 64-bit raw16 pixel payload beats.
////////////////////////////////////////////////////////////////////////////////////////////////////
module video_srio_pattern_src #(
	parameter		DW							= 64,
	parameter		TARGET_SRC_ID				= 16'h0000,
	parameter		FRAME_WIDTH					= 1920,
	parameter		FRAME_HEIGHT				= 1080,
	parameter		PACKET_BYTES				= 4096,
	parameter		RAW10_SHIFT					= 6,
	parameter		FRAME_GAP_CYCLES			= 1024
)(
	output										m_axis_tvalid,
	input										m_axis_tready,
	output										m_axis_tlast,
	output		[DW-1:0]						m_axis_tdata,
	output		[DW/8-1:0]						m_axis_tkeep,
	output		[31:0]							m_axis_tuser,

	input										clk,
	input										rst_n
);

	localparam		ST_IDLE						= 2'd0;
	localparam		ST_HEADER					= 2'd1;
	localparam		ST_DATA						= 2'd2;
	localparam		ST_GAP						= 2'd3;
	localparam		FRAME_BYTES					= FRAME_WIDTH * FRAME_HEIGHT * 2;
	localparam [15:0] PACKET_BYTES_16			= PACKET_BYTES;
	localparam [15:0] FRAME_GAP_CYCLES_16		= FRAME_GAP_CYCLES;

	reg		[1:0]								cs;
	reg		[31:0]								frame_byte_index;
	reg		[31:0]								frame_count;
	reg		[15:0]								packet_bytes;
	reg		[15:0]								packet_word_index;
	reg		[15:0]								frame_gap_count;

	wire	[31:0]								frame_remaining;
	wire	[15:0]								next_packet_bytes;
	wire	[15:0]								packet_words;
	wire	[31:0]								base_pixel_index;
	wire										trv;
	wire										data_last;
	wire	[15:0]								pix0;
	wire	[15:0]								pix1;
	wire	[15:0]								pix2;
	wire	[15:0]								pix3;

	function [15:0] f_pattern_pixel;
		input [31:0] pixel_index;
		input [31:0] frame_id;
		reg [9:0] raw10;
		reg [15:0] raw16;
		begin
			raw10 = pixel_index[9:0] + frame_id[9:0];
			raw16 = {6'd0, raw10};
			f_pattern_pixel = raw16 << RAW10_SHIFT;
		end
	endfunction

	assign frame_remaining = FRAME_BYTES - frame_byte_index;
	assign next_packet_bytes = (frame_remaining < PACKET_BYTES) ? frame_remaining[15:0] :
																 PACKET_BYTES_16;
	assign packet_words = {3'd0, packet_bytes[15:3]};
	assign base_pixel_index = (frame_byte_index >> 1) + {14'd0, packet_word_index, 2'd0};
	assign pix0 = f_pattern_pixel(base_pixel_index + 32'd0, frame_count);
	assign pix1 = f_pattern_pixel(base_pixel_index + 32'd1, frame_count);
	assign pix2 = f_pattern_pixel(base_pixel_index + 32'd2, frame_count);
	assign pix3 = f_pattern_pixel(base_pixel_index + 32'd3, frame_count);

	assign m_axis_tvalid = (cs == ST_HEADER) || (cs == ST_DATA);
	assign m_axis_tlast  = (cs == ST_DATA) && data_last;
	assign m_axis_tkeep  = {(DW/8){1'b1}};
	assign m_axis_tuser  = {TARGET_SRC_ID, 16'd0};
	assign m_axis_tdata  = (cs == ST_HEADER) ? {30'd0, 34'h0000001000} :
											   {pix3, pix2, pix1, pix0};
	assign trv = m_axis_tvalid && m_axis_tready;
	assign data_last = (packet_word_index + 1'b1) >= packet_words;

	always @(posedge clk) begin
		if (~rst_n) begin
			cs					<= ST_IDLE;
			frame_byte_index	<= 32'd0;
			frame_count			<= 32'd0;
			packet_bytes		<= 16'd0;
			packet_word_index	<= 16'd0;
			frame_gap_count		<= 16'd0;
		end else begin
			case (cs)
			ST_IDLE: begin
				packet_bytes		<= next_packet_bytes;
				packet_word_index	<= 16'd0;
				cs					<= ST_HEADER;
			end

			ST_HEADER: begin
				if (trv) begin
					packet_word_index <= 16'd0;
					cs				  <= ST_DATA;
				end
			end

			ST_DATA: begin
				if (trv) begin
					if (data_last) begin
						packet_word_index <= 16'd0;
						if ((frame_byte_index + packet_bytes) >= FRAME_BYTES) begin
							frame_byte_index <= 32'd0;
							frame_count		 <= frame_count + 1'b1;
							frame_gap_count	 <= FRAME_GAP_CYCLES_16;
							cs				 <= ST_GAP;
						end else begin
							frame_byte_index <= frame_byte_index + packet_bytes;
							cs				 <= ST_IDLE;
						end
					end else begin
						packet_word_index <= packet_word_index + 1'b1;
					end
				end
			end

			ST_GAP: begin
				if (frame_gap_count == 16'd0) begin
					cs <= ST_IDLE;
				end else begin
					frame_gap_count <= frame_gap_count - 1'b1;
				end
			end

			default: begin
				cs <= ST_IDLE;
			end
			endcase
		end
	end

endmodule
