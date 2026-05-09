`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY				
// Engineer:		DuCHaoMing	        
//                                     
// Create Date:		2026/04/27          
// Design Name:		sim_fifo              
// Module Name:		sim_fifo & sim_exw_fifo             
// Project Name:	SRIO to Ethernet Video Transmission	                
// Description:		Simulation FIFO modules - compatible with hdl_eqw_afifo and hdl_exw_afifo interface              
// 				
////////////////////////////////////////////////////////////////////////////////////////////////////

//================================================================================================
// Equal Width FIFO (compatible with hdl_eqw_afifo)
//================================================================================================
module sim_eqw_afifo #(
	parameter	LOOP_NUM				= 0,
	parameter	RAM_STYLE				= "distributed",
	parameter	ALMOST_EMPTY_OFFSET		= 'h8,
	parameter	ALMOST_FULL_OFFSET		= 'h8,
	parameter	FIRST_WORD_FALL_THROUGH	= "TRUE",
	parameter	AW						= 5,
	parameter	DW						= 64
)(
	input					RST,
	input					WRCLK,
	output	[AW-1:0]		WRCOUNT,
	output					WRERR,
	input					WREN,
	input	[DW-1:0]		DI,
	output					ALMOSTFULL,
	output					FULL,
	input					RDEN,
	output	[DW-1:0]		DO,
	output					ALMOSTEMPTY,
	output					EMPTY,
	output	[AW-1:0]		RDCOUNT,
	output					RDERR,
	input					RDCLK
);

	localparam	DEPTH	= 1 << AW;
	reg [DW-1:0]		mem[0:DEPTH-1];
	reg [AW:0]			wr_ptr;
	reg [AW:0]			rd_ptr;
	
	assign FULL = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);
	assign EMPTY = (wr_ptr == rd_ptr);
	assign ALMOSTFULL = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0] - ALMOST_FULL_OFFSET[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);
	assign ALMOSTEMPTY = (wr_ptr == rd_ptr + ALMOST_EMPTY_OFFSET[AW-1:0]) || (wr_ptr == rd_ptr + 1);
	
	assign WRCOUNT = wr_ptr[AW-1:0];
	assign RDCOUNT = rd_ptr[AW-1:0];
	assign WRERR = 1'b0;
	assign RDERR = 1'b0;
	
	generate
		if (FIRST_WORD_FALL_THROUGH == "TRUE") begin
			reg [DW-1:0] do_reg;
			always @(*) begin
				if (EMPTY) begin
					do_reg = {DW{1'b0}};
				end else begin
					do_reg = mem[rd_ptr[AW-1:0]];
				end
			end
			assign DO = do_reg;
		end else begin
			assign DO = mem[rd_ptr[AW-1:0]];
		end
	endgenerate
	
	always @(posedge WRCLK or posedge RST) begin
		if (RST) begin
			wr_ptr <=1'b0;
		end else if (WREN & ~FULL) begin
			mem[wr_ptr[AW-1:0]] <= DI;
			wr_ptr <= wr_ptr + 1'b1;
		end
	end
	
	always @(posedge RDCLK or posedge RST) begin
		if (RST) begin
			rd_ptr <=1'b0;
		end else if (RDEN & ~EMPTY) begin
			rd_ptr <= rd_ptr + 1'b1;
		end
	end

endmodule


//================================================================================================
// Extended Width FIFO (compatible with hdl_exw_afifo)
//================================================================================================
module sim_exw_afifo #(
	parameter	LOOP_NUM				= 0,
	parameter	RAM_STYLE				= "block",
	parameter	ALMOST_EMPTY_OFFSET		= 'h10,
	parameter	ALMOST_FULL_OFFSET		= 'h10,
	parameter	FIRST_WORD_FALL_THROUGH	= "TRUE",
	parameter	AW						= 10,
	parameter	DW						= 64,
	parameter	QW						= 64
)(
	input					RST,
	input					WRCLK,
	output	[AW-1:0]		WRCOUNT,
	output					WRERR,
	input					WREN_CLEAR,
	input					WREN_LAST,
	input					WREN,
	input	[DW-1:0]		DI,
	output					ALMOSTFULL,
	output					FULL,
	input					RDEN_LAST,
	input					RDEN,
	output	[QW-1:0]		DO,
	output					ALMOSTEMPTY,
	output					EMPTY,
	output	[AW-1:0]		RDCOUNT,
	output					RDERR,
	input					RDCLK
);

	localparam	DEPTH	= 1 << AW;
	reg [DW-1:0]		mem[0:DEPTH-1];
	reg [AW:0]			wr_ptr;
	reg [AW:0]			rd_ptr;
	
	assign FULL = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);
	assign EMPTY = (wr_ptr == rd_ptr);
	assign ALMOSTFULL = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0] - ALMOST_FULL_OFFSET[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);
	assign ALMOSTEMPTY = (wr_ptr == rd_ptr + ALMOST_EMPTY_OFFSET[AW-1:0]) || (wr_ptr == rd_ptr + 1);
	
	assign WRCOUNT = wr_ptr[AW-1:0];
	assign RDCOUNT = rd_ptr[AW-1:0];
	assign WRERR = 1'b0;
	assign RDERR = 1'b0;
	
	generate
		if (FIRST_WORD_FALL_THROUGH == "TRUE") begin
			reg [QW-1:0] do_reg;
			always @(*) begin
				if (EMPTY) begin
					do_reg = {QW{1'b0}};
				end else begin
					do_reg = mem[rd_ptr[AW-1:0]];
				end
			end
			assign DO = do_reg;
		end else begin
			assign DO = mem[rd_ptr[AW-1:0]];
		end
	endgenerate
	
	always @(posedge WRCLK or posedge RST) begin
		if (RST) begin
			wr_ptr <=1'b0;
		end else if (WREN & ~FULL) begin
			mem[wr_ptr[AW-1:0]] <= DI;
			wr_ptr <= wr_ptr + 1'b1;
		end
	end
	
	always @(posedge RDCLK or posedge RST) begin
		if (RST) begin
			rd_ptr <=1'b0;
		end else if (RDEN & ~EMPTY) begin
			rd_ptr <= rd_ptr + 1'b1;
		end
	end

endmodule


//================================================================================================
// Simple FIFO for srio_data_classifier
//================================================================================================
module sim_classifier_fifo #(
	parameter	WIDTH	= 64,
	parameter	DEPTH	= 1024,
	parameter	AW		= $clog2(DEPTH)
)(
	input					wr_clk,
	input					wr_rst_n,
	input					wr_en,
	input	[WIDTH-1:0]		wr_data,
	output					full,
	output					almost_full,
	
	input					rd_clk,
	input					rd_rst_n,
	input					rd_en,
	output	[WIDTH-1:0]		rd_data,
	output					empty,
	output					almost_empty
);

	reg [WIDTH-1:0]	mem[0:DEPTH-1];
	reg [AW:0]		wr_ptr;
	reg [AW:0]		rd_ptr;
	
	assign full = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);
	assign empty = (wr_ptr == rd_ptr);
	assign almost_full = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0] - 2) && (wr_ptr[AW] != rd_ptr[AW]);
	assign almost_empty = (wr_ptr == rd_ptr + 1) || (wr_ptr == rd_ptr);
	
	assign rd_data = mem[rd_ptr[AW-1:0]];
	
	always @(posedge wr_clk or negedge wr_rst_n) begin
		if (~wr_rst_n) begin
			wr_ptr <=1'b0;
		end else if (wr_en & ~full) begin
			mem[wr_ptr[AW-1:0]] <= wr_data;
			wr_ptr <= wr_ptr + 1'b1;
		end
	end
	
	always @(posedge rd_clk or negedge rd_rst_n) begin
		if (~rd_rst_n) begin
			rd_ptr <=1'b0;
		end else if (rd_en & ~empty) begin
			rd_ptr <= rd_ptr + 1'b1;
		end
	end

endmodule
