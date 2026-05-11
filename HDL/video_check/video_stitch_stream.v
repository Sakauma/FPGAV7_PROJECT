`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Stream formatter for the SRIO video stitch path.
// The first hardware bring-up mode duplicates SRIO0 logically, uses zero offset, and emits
// 10-bit pixels in 16-bit little-endian containers for PCIe/RK3588.
////////////////////////////////////////////////////////////////////////////////////////////////////
module video_stitch_stream #(
	parameter		DW							= 64,
	parameter		RAW10_SHIFT					= 6,
	parameter		FEATURE_THRESHOLD			= 16'd24
)(
	input										rio_treq_info_wr,
	input		[64-1:0]						rio_treq_info_di,
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
	output		[64-1:0]						m_axis_tuser,

	output	reg	[31:0]							feature_match_count,
	output	reg	signed [15:0]					stitch_dx,
	output	reg	signed [15:0]					stitch_dy,
	output	reg	[15:0]							stitch_confidence,
	output	reg	[31:0]							drop_count,

	input										clk,
	input										rst_n
);

	function [15:0] f_raw10;
		input [15:0] pix16;
		reg [15:0] shifted;
		begin
			shifted = pix16 >> RAW10_SHIFT;
			f_raw10 = {6'b0, shifted[9:0]};
		end
	endfunction

	function [15:0] f_abs_diff;
		input [15:0] a;
		input [15:0] b;
		begin
			f_abs_diff = (a >= b) ? (a - b) : (b - a);
		end
	endfunction

	function [15:0] f_ceil_div32;
		input [15:0] byte_count;
		begin
			f_ceil_div32 = {5'b0, byte_count[15:5]} + (|byte_count[4:0]);
		end
	endfunction

	localparam		ST_IDLE						= 2'b01;
	localparam		ST_SEND						= 2'b10;

	reg		[1:0]								cs;
	reg		[15:0]								active_bytes;
	reg		[15:0]								active_pcie_words;
	reg		[15:0]								bytes_left;

	wire										info_rd;
	wire	[63:0]								info_do;
	wire										info_ae;
	wire										info_em;

	wire										fifo_rd;
	wire	[DW-1:0]							fifo_do;
	wire										fifo_ae;
	wire										fifo_em;

	wire	[15:0]								pix0_raw10;
	wire	[15:0]								pix1_raw10;
	wire	[15:0]								pix2_raw10;
	wire	[15:0]								pix3_raw10;
	wire	[15:0]								diff01;
	wire	[15:0]								diff12;
	wire	[15:0]								diff23;
	wire	[2:0]								feature_inc;
	wire										trv;
	wire										packet_last;

	assign pix0_raw10 = f_raw10(fifo_do[15:0]);
	assign pix1_raw10 = f_raw10(fifo_do[31:16]);
	assign pix2_raw10 = f_raw10(fifo_do[47:32]);
	assign pix3_raw10 = f_raw10(fifo_do[63:48]);

	assign diff01 = f_abs_diff(pix0_raw10, pix1_raw10);
	assign diff12 = f_abs_diff(pix1_raw10, pix2_raw10);
	assign diff23 = f_abs_diff(pix2_raw10, pix3_raw10);
	assign feature_inc = {2'd0, (diff01 > FEATURE_THRESHOLD)} +
						 {2'd0, (diff12 > FEATURE_THRESHOLD)} +
						 {2'd0, (diff23 > FEATURE_THRESHOLD)};

	assign m_axis_tdata  = {pix3_raw10, pix2_raw10, pix1_raw10, pix0_raw10};
	assign m_axis_tkeep  = {(DW/8){1'b1}};
	assign m_axis_tvalid = (cs == ST_SEND) && (~fifo_em);
	assign packet_last   = (bytes_left <= 16'd8);
	assign m_axis_tlast  = (cs == ST_SEND) && packet_last;
	assign m_axis_tuser  = {32'd0, active_bytes, active_pcie_words};
	assign trv           = m_axis_tvalid && m_axis_tready;
	assign fifo_rd       = trv;
	assign info_rd       = (cs == ST_IDLE) && (~info_em);

	always @(posedge clk) begin
		if (~rst_n) begin
			cs						<= ST_IDLE;
			active_bytes			<= 16'd0;
			active_pcie_words		<= 16'd0;
			bytes_left				<= 16'd0;
			feature_match_count		<= 32'd0;
			stitch_dx				<= 16'sd0;
			stitch_dy				<= 16'sd0;
			stitch_confidence		<= 16'd0;
			drop_count				<= 32'd0;
		end else begin
			if ((rio_treq_info_wr && rio_treq_info_fu) ||
				(rio_treq_fifo_wr && rio_treq_fifo_fu)) begin
				drop_count			<= drop_count + 1'b1;
			end

			case (cs)
			ST_IDLE: begin
				stitch_dx			<= 16'sd0;
				stitch_dy			<= 16'sd0;
				stitch_confidence	<= 16'd0;
				if (info_rd) begin
					cs				<= ST_SEND;
					active_bytes	<= info_do[15:0];
					active_pcie_words <= f_ceil_div32(info_do[15:0]);
					bytes_left		<= info_do[15:0];
					feature_match_count <= 32'd0;
				end
			end

			ST_SEND: begin
				if (trv) begin
					feature_match_count <= feature_match_count + feature_inc;
					stitch_confidence <= feature_match_count[15:0] + {13'd0, feature_inc};
					if (packet_last) begin
						cs			<= ST_IDLE;
						bytes_left	<= 16'd0;
					end else begin
						bytes_left	<= bytes_left - 16'd8;
					end
				end
			end

			default: begin
				cs					<= ST_IDLE;
			end
			endcase
		end
	end

	hdl_eqw_afifo #(
		.LOOP_NUM					(0),
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
		.LOOP_NUM					(0),
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
