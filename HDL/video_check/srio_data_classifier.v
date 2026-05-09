`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY				
// Engineer:		DuCHaoMing	        
//                                     
// Create Date:		2026/04/27          
// Design Name:		srio_data_classifier              
// Module Name:		srio_data_classifier             
// Project Name:	SRIO to Ethernet Video Transmission	                
// Target Devices:	Xilinx Virtex-7                
// Tool versions:	Vivado                
// Description:		SRIO data classifier - classify data based on source ID to different outputs              
// 				
// Dependencies:	None                
// 				
// Revision:		1.0				
////////////////////////////////////////////////////////////////////////////////////////////////////
module srio_data_classifier #(
	parameter	SIM				= 0,		// 0: use real FIFO, 1: use simulation FIFO
	parameter	TARGET_SRC_ID	= 16'h0000,	// Target Source ID for video data
	parameter	FIFO_DEPTH		= 1024,		// FIFO depth for non-target data
	parameter	DATA_WIDTH		= 64,		// Data width
	parameter	USER_WIDTH		= 32,		// User width
	parameter	KEEP_WIDTH		= 8			// Keep width
)(
	//================================================================================================
	// Input SRIO AXI-Stream Interface
	//================================================================================================
	input					srio_tvalid,
	output					srio_tready,
	input					srio_tlast,
	input	[DATA_WIDTH-1:0]	srio_tdata,
	input	[KEEP_WIDTH-1:0]	srio_tkeep,
	input	[USER_WIDTH-1:0]	srio_tuser,

	//================================================================================================
	// Output 1: Target ID Data (to video collect module)
	//================================================================================================
	output					target_tvalid,
	input					target_tready,
	output					target_tlast,
	output	[DATA_WIDTH-1:0]	target_tdata,
	output	[KEEP_WIDTH-1:0]	target_tkeep,
	output	[USER_WIDTH-1:0]	target_tuser,

	//================================================================================================
	// Output 2: Non-Target ID Data (to other modules)
	//================================================================================================
	output					nontarget_tvalid,
	input					nontarget_tready,
	output					nontarget_tlast,
	output	[DATA_WIDTH-1:0]	nontarget_tdata,
	output	[KEEP_WIDTH-1:0]	nontarget_tkeep,
	output	[USER_WIDTH-1:0]	nontarget_tuser,

	//================================================================================================
	// Common Interface
	//================================================================================================
	input					clk,
	input					rst_n
);

	//================================================================================================
	// Internal Signals
	//================================================================================================
	wire 					trv 	= srio_tvalid && srio_tready ;
	wire 					trvl 	= trv && srio_tlast ;
	wire					pkt_is_target;			// Current packet is target
	//reg						pkt_is_target_d1;		// Delayed for pipeline
	reg		[15:0]			pkt_src_id;				// Current packet source ID (from header)
	reg						prev_tlast;				// Previous tlast for edge detection

	//================================================================================================
	// FIFO Signals for Non-Target Data
	//================================================================================================
	wire					fifo_wr_en;
	wire					fifo_rd_en;
	wire	[DATA_WIDTH+KEEP_WIDTH+USER_WIDTH+1-1:0]	fifo_wr_data;	// {tlast, tuser, tkeep, tdata}
	wire	[DATA_WIDTH+KEEP_WIDTH+USER_WIDTH+1-1:0]	fifo_rd_data;
	wire					fifo_full;
	wire					fifo_empty;
	wire					fifo_almost_full;
	wire					fifo_almost_empty;

	//================================================================================================
	// Output Stage Signals
	//================================================================================================
	reg						target_tvalid_reg;
	reg						target_tlast_reg;
	reg		[DATA_WIDTH-1:0]	target_tdata_reg;
	reg		[KEEP_WIDTH-1:0]	target_tkeep_reg;
	reg		[USER_WIDTH-1:0]	target_tuser_reg;
	
	reg 						aixs_head;
	reg  						sop ;	

	//================================================================================================
	// Source ID Extraction and Classification (Combined)
	//================================================================================================
	//================================================================================================
	// IMPORTANT: Source ID sampled ONLY at HEADER BEAT (Start of Packet)!
	// According to sp_clloect_4k.v line 102: req_srcTID is from tdata[63:56] at SOP
	//================================================================================================

	// Detect SOP (Start of Packet): prev_tlast && srio_tvalid) indicates new packet header
	always @(posedge clk ) begin
		if ( ~rst_n ) begin
			sop			<= 1'b1 ;
		end else  if ( trvl )begin 
			sop 		<= 1'b1 ;
		end else if ( trv ) begin
			sop			<= 1'b0	;
		end
	end
	always @(posedge clk ) begin
		if ( ~rst_n ) begin
			aixs_head			<= 1'b1 ;
		end else  if ( trvl )begin 
			aixs_head 			<= 1'b1 ;
		end else if ( srio_tvalid ) begin
			aixs_head			<= 1'b0	;
		end
	end
	always @(posedge clk ) begin
		if(~rst_n)begin
		  	pkt_src_id	<= 16'h0000 ;
		end else if (sop) begin 
			pkt_src_id	<= srio_tuser [31:16] ;
		end else begin 
			pkt_src_id	<= pkt_src_id	;
		end
	end
	assign	pkt_is_target	= pkt_src_id == TARGET_SRC_ID ? 1'b1: 1'b0 ;
	//================================================================================================
	// Packet Classification Logic (Sample + Classify in one step)
	//================================================================================================
	/*always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			pkt_is_target		<= 1'b0;
			pkt_is_target_d1	<= 1'b0;
			pkt_src_id			<= 16'h0000;
		//	prev_tlast			<= 1'b1;
		end else if (sop) begin
				pkt_src_id <= srio_tuser[31:16];  // EXACTLY matches sp_clloect_4k.v line 102: req_srcTID is tdata[63:56]
				pkt_is_target <= (srio_tuser[31:16] == TARGET_SRC_ID);
			end
			
			// End of packet: reset classification
			if (srio_tvalid & srio_tready & srio_tlast) begin
				pkt_is_target <= 1'b0;
			end
			
			pkt_is_target_d1 <= pkt_is_target;
		end
	end*/

	//================================================================================================
	// Input TREADY Generation
	//================================================================================================
	assign srio_tready = aixs_head ?	1'b0       :
				    pkt_is_target  ? target_tready : 
									 ~fifo_almost_full ;	// For non-target, stop when FIFO almost full

	//================================================================================================
	// Target Path (Direct Combinatorial Connection)
	//================================================================================================
	always @(*) begin
		target_tvalid_reg = 1'h0;
		target_tlast_reg = 1'h0;
		target_tdata_reg = {DATA_WIDTH{1'h0}};
		target_tkeep_reg = {KEEP_WIDTH{1'h0}};
		target_tuser_reg = {USER_WIDTH{1'h0}};
		
		if (pkt_is_target && srio_tvalid) begin
			target_tvalid_reg = 1'h1;
			target_tlast_reg = srio_tlast;
			target_tdata_reg = srio_tdata;
			target_tkeep_reg = srio_tkeep;
			target_tuser_reg = srio_tuser;
		end
	end

	assign target_tvalid	= target_tvalid_reg;
	assign target_tlast		= target_tlast_reg;
	assign target_tdata		= target_tdata_reg;
	assign target_tkeep		= target_tkeep_reg;
	assign target_tuser		= target_tuser_reg;

	//================================================================================================
	// Non-Target Path (Through FIFO)
	//================================================================================================
	assign fifo_wr_en = (~pkt_is_target) && srio_tvalid && srio_tready;
	assign fifo_wr_data = {srio_tlast, srio_tuser, srio_tkeep, srio_tdata};
	
	assign fifo_rd_en = (~fifo_empty) && nontarget_tready;
	
	// Unpack FIFO output
	assign nontarget_tvalid	= ~fifo_empty;
	assign nontarget_tlast	= fifo_rd_data[DATA_WIDTH+KEEP_WIDTH+USER_WIDTH+1-1];
	assign nontarget_tuser	= fifo_rd_data[DATA_WIDTH+KEEP_WIDTH+USER_WIDTH-1 : DATA_WIDTH+KEEP_WIDTH];
	assign nontarget_tkeep	= fifo_rd_data[DATA_WIDTH+KEEP_WIDTH-1 : DATA_WIDTH];
	assign nontarget_tdata	= fifo_rd_data[DATA_WIDTH-1 : 0];

	//================================================================================================
	// FIFO Instantiation
	//================================================================================================
	generate
		if (SIM == 1) begin
			// Use simulation FIFO
			sim_classifier_fifo #(
				.WIDTH		(DATA_WIDTH + KEEP_WIDTH + USER_WIDTH + 1),	// tlast + tuser + tkeep + tdata
				.DEPTH		(FIFO_DEPTH)
			) u_srio_classifier_fifo (
				.wr_clk		(clk),
				.wr_rst_n	(rst_n),
				.wr_en		(fifo_wr_en),
				.wr_data	(fifo_wr_data),
				.full		(fifo_full),
				.almost_full(fifo_almost_full),
				
				.rd_clk		(clk),
				.rd_rst_n	(rst_n),
				.rd_en		(fifo_rd_en),
				.rd_data	(fifo_rd_data),
				.empty		(fifo_empty),
				.almost_empty(fifo_almost_empty)
			);
		end else begin
			// Use real FIFO - replace with your actual FIFO module here
	
	                                                                                
				hdl_exw_afifo	#(                                                  
					.	LOOP_NUM				(	0				),              
					.	RAM_STYLE				(	"block"			),              
					.	ALMOST_EMPTY_OFFSET		(	'h10			),              
					.	ALMOST_FULL_OFFSET		(	'h10			),              
					.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),              
					.	AW						( 	10				),              
					.	DW						(	DATA_WIDTH + KEEP_WIDTH + USER_WIDTH + 1				),              
					.	QW						(	DATA_WIDTH + KEEP_WIDTH + USER_WIDTH + 1				)               
				)u_srio_classifier_fifo(                                                        
					.	RST					(	~rst_n				),          
					.	WRCLK				(	clk					),                  
					.	WRCOUNT				(						),              
					.	WRERR				(						),              
					.	WREN_CLEAR			(	1'b0				),              
					.	WREN_LAST			(	1'b0				),              
					.	WREN				(	fifo_wr_en			),          
					.	DI					(	fifo_wr_data		),          
					.	ALMOSTFULL			(	fifo_almost_full	),          
					.	FULL				(	fifo_full			),          
					.	RDEN_LAST			(	1'b0				),              
					.	RDEN				(	fifo_rd_en			),          
					.	DO					(	fifo_rd_data		),              
					.	ALMOSTEMPTY			(	fifo_almost_empty	),              
					.	EMPTY				(	fifo_empty			),              
					.	RDCOUNT				(						),              
					.	RDERR				(						),              
					.	RDCLK				(	clk				)                   
				);                                                                  		 
	
	
		
		end
	endgenerate

endmodule
