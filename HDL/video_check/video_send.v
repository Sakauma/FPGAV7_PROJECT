`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		DuCHaoMing
//
// Create Date:		2014/6/12 9:49:39
// Design Name:
// Module Name:		module_name.v
// Project Name:
// Target Devices:	XC7Z045FFG600-2L
// Tool versions:	ISE 14.6 or Vivado
// Description:
//
// Dependencies:
//
// Top File:
//
// Inst File�?
//
// Revision:
//
////////////////////////////////////////////////////////////////////////////////////////////////////
module video_send	#(
	parameter		SIM							= 1											,
	parameter		DW							= 64										,
	parameter		QW							= 64										,
	parameter		PR_DN_NUM					= 1											  
	)(
//---selfdefine Interface-----------------------

	input									rio0_treq_info_wr							,
	input		[64-1:0]					rio0_treq_info_di							,
	output									rio0_treq_info_af							,
	output									rio0_treq_info_fu							,
	input									rio0_treq_fifo_wr							,
	input		[DW-1:0]					rio0_treq_fifo_di							,
	output									rio0_treq_fifo_af							,
	output									rio0_treq_fifo_fu							,
	input									rio0_treq_fifo_wl							,


	input									rio1_treq_info_wr							,
	input		[64-1:0]					rio1_treq_info_di							,
	output									rio1_treq_info_af							,
	output									rio1_treq_info_fu							,
	input									rio1_treq_fifo_wr							,
	input		[DW-1:0]					rio1_treq_fifo_di							,
	output									rio1_treq_fifo_af							,
	output									rio1_treq_fifo_fu							,
	input									rio1_treq_fifo_wl							,
//---selfdefine Interface-----------------------
	output		[PR_DN_NUM*DW-1	: 0]		udp_axis_tdata							,	 
	input		[PR_DN_NUM*1-1	: 0]		udp_axis_tready							,
	output		[PR_DN_NUM*1-1	: 0]		udp_axis_tvalid							,
	output		[PR_DN_NUM*DW/8-1	: 0]	udp_axis_tkeep							,
	output		[PR_DN_NUM*1-1	: 0]		udp_axis_tlast							,
	output		[PR_DN_NUM*32-1	: 0]		udp_axis_tuser							,
 
 

//---Common Interface---------------------------
	input										core_clk								,
	input										clk										,
	input										rst_n
	);
//==================================================================================================
//--Signals Define------------------------------

		wire						tv 			;
		wire						tr			=	udp_axis_tready					;
		wire						tl			;
		wire		[DW-1:0 ]		tdata		;
		wire		[32-1:0	]		tuser		;
		wire						trv			=	tv & tr							;	
		wire						trvl		=	trv  & tl						; 		



		wire											rio0_treq_info_rd			;
		wire		[	64		-	1	:	0	]		rio0_treq_info_do			;
		wire											rio0_treq_info_ae			;
		wire											rio0_treq_info_em			;
		wire											rio0_treq_fifo_rd			;
		wire		[	QW		-	1	:	0	]		rio0_treq_fifo_do			;
		wire											rio0_treq_fifo_ae			;
		wire											rio0_treq_fifo_em			;


		wire											rio1_treq_info_rd			;
		wire		[	64		-	1	:	0	]		rio1_treq_info_do			;
		wire											rio1_treq_info_ae			;
		wire											rio1_treq_info_em			;
		wire											rio1_treq_fifo_rd			;
		wire		[	QW		-	1	:	0	]		rio1_treq_fifo_do			;
		wire											rio1_treq_fifo_ae			;
		wire											rio1_treq_fifo_em			;

		wire											all_info_ready				;
       	reg			[	32		-	1	:	0	]		dat_cnt0					;
       	reg			[	32		-	1	:	0	]		dat_cnt1 					;
       	

//==================================================================================================
//--Parameter Define----------------------------
		reg 		[3:0]						cs,ns								;
		localparam		IDLE					= 4'b0001							;
		localparam		ADD_ICD					= 4'b0010							;
		localparam		SEND_DAT0				= 4'b0100							;
		localparam		SEND_DAT1				= 4'b1000							;





//==================================================================================================
//--

	   always@(posedge	core_clk)	begin
        	if(~rst_n)begin
        		cs	<=	IDLE	;
	    	end else begin
        		cs	<=	ns	;
        	end
        end
        always@(*)	begin
        	ns									=	cs										;
        	case( cs )
        		IDLE : begin
        			if( all_info_ready )  begin
        				ns						=	ADD_ICD								;
        			end else begin 
        				ns						=	IDLE									;
					end
        		end
        		ADD_ICD  	:  begin
        			if( trv	) begin
        				ns						= 	SEND_DAT0								;
					end else begin 
						ns						=   ADD_ICD									;
					end	
        		end
        		SEND_DAT0	:  begin
        			if(trv && dat_cnt0 == rio0_treq_info_do[15:1] - 8 )begin 
        				ns						=	SEND_DAT1								;
        			end else begin 
        				ns						= 	SEND_DAT0								;
        			end
        		end
        		SEND_DAT1	:  begin
					if(trv && dat_cnt1  == rio0_treq_info_do[15:1] - 8 )begin 
        				ns						=	IDLE									;
        			end else begin 
        				ns						=	SEND_DAT1								;
        			end
        		end
        		default :  ns 						= IDLE										;
        	endcase
       	end

	assign		all_info_ready					= 	~ rio0_treq_info_em & ~rio1_treq_info_em ;
	assign		rio0_treq_info_rd				=	all_info_ready 		& cs == ADD_ICD				;
	assign		rio1_treq_info_rd				=	all_info_ready 		& cs == ADD_ICD				;
	assign		rio0_treq_fifo_rd				=	~rio0_treq_fifo_em  & cs == SEND_DAT0 & tr  	;
	assign		rio1_treq_fifo_rd				=	~rio1_treq_fifo_em  & cs == SEND_DAT1 & tr  	;



	assign		tv								=	cs == IDLE		?	0					:
													cs == ADD_ICD	?	1'b1				:
													cs == SEND_DAT0 ?	rio0_treq_fifo_rd	:
													cs == SEND_DAT1 ?   rio1_treq_fifo_rd   : 
																		1'b0				;
	assign		tl								=	cs == SEND_DAT1 &	dat_cnt1  == rio0_treq_info_do[15:1]-8 ? 1'b1 : 1'b0 ;


	assign		tdata							= 	cs == IDLE 		?	0					:
													cs == ADD_ICD	?	rio0_treq_info_do	:
								rio0_treq_fifo_rd &	cs == SEND_DAT0 ? 	rio0_treq_fifo_do	:
								rio1_treq_fifo_rd & cs == SEND_DAT1 ?   rio1_treq_fifo_do	:
																		0					;	
	assign		tuser							=	cs == IDLE		?	0					:
													{rio0_treq_info_do[15:0]+16'd8 , {3'd0,rio0_treq_info_do[15:3]}+1'b1 };

	always @ (posedge core_clk ) begin 
      	if (~rst_n	) begin 
      		dat_cnt0        					<= 0										;
      	end else if ( cs == SEND_DAT0 & trv  ) begin 
      		dat_cnt0							<=  dat_cnt0	+ 16'd8						;
      	end else if ( cs == IDLE ) begin 
      		dat_cnt0							<= 0										;
		end else begin 
			dat_cnt0							<= dat_cnt0									;
		end
    end
	always @ (posedge core_clk ) begin 
      	if (~rst_n	) begin 
      		dat_cnt1        					<= 0										;
      	end else if ( cs == SEND_DAT1 & trv  ) begin 
      		dat_cnt1							<=  dat_cnt1	+ 16'd8						;
      	end else if ( cs == IDLE ) begin 
      		dat_cnt1							<= 0										;
		end else begin 
			dat_cnt1							<= dat_cnt1									;
		end
    end
/*

	assign 	udp_axis_tdata						= ns ==ADD_ICD ? rio0_treq_info_do :
												  ns ==SEND_DAT0 ? rio0_treq_fifo_do:
												  ns ==SEND_DAT1 ? rio1_treq_fifo_do:
												  									0;
	assign 	udp_axis_tvalid 					= ns != IDLE 	 ? 1'b1             :			
												  ns ==SEND_DAT0 ? rio0_treq_fifo_rd:
												  ns ==SEND_DAT1 ? rio1_treq_fifo_rd:
																	1'b0			;

	assign 	udp_axis_tkeep						= {{PR_DN_NUM*DW/8}{1'b1}}			;
	assign 	udp_axis_tlast						= 	dat_cnt0 >=rio0_treq_info_do[15:1] - 8 &&
													dat_cnt1 >=rio1_treq_info_do[15:1] - 8? 1'b1:1'b0; 	
	assign 	udp_axis_tuser  					=	{rio0_treq_info_do[15:0]+8,3'b0,rio0_treq_info_do[15:3]+1};
*/
assign 	udp_axis_tdata						=	tdata								;															
assign 	udp_axis_tvalid 					=   tv 									;														
assign 	udp_axis_tkeep						=	{{PR_DN_NUM*DW/8}{1'b1}}			;		
assign 	udp_axis_tlast						=	tl											;							
assign 	udp_axis_tuser  					=	{rio0_treq_info_do[15:0]+8,3'b0,rio0_treq_info_do[15:3]+1};			
//==================================================================================================
//--SRIO 0 输出缓存

	generate
		if (0) begin
			// Use simulation FIFO
			sim_eqw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"distributed"	),
				.	ALMOST_EMPTY_OFFSET		(	'h8				),
				.	ALMOST_FULL_OFFSET		(	'h8				),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						(	5				),
				.	DW						(	64				)
			)axsr0_info(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk						),
				.	WRCOUNT				(							),
				.	WRERR				(							),
				.	WREN				(	rio0_treq_info_wr		),
				.	DI					(	rio0_treq_info_di		),
				.	ALMOSTFULL			(	rio0_treq_info_af		),
				.	FULL				(	rio0_treq_info_fu		),
				.	RDEN				(	rio0_treq_info_rd		),
				.	DO					(	rio0_treq_info_do		),
				.	ALMOSTEMPTY			(	rio0_treq_info_ae		),
				.	EMPTY				(	rio0_treq_info_em		),
				.	RDCOUNT				(							),
				.	RDERR				(							),
				.	RDCLK				(	core_clk						)
			);

			sim_exw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"block"			),
				.	ALMOST_EMPTY_OFFSET		(	'h10			),
				.	ALMOST_FULL_OFFSET		(	'h10			),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						( 	10				),
				.	DW						(	DW				),
				.	QW						(	DW				)
			)axsr0_fifo(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk						),
				.	WRCOUNT				(							),
				.	WRERR				(							),
				.	WREN_CLEAR			(	1'b0					),
				.	WREN_LAST			(	1'b0					),
				.	WREN				(	rio0_treq_fifo_wr		),
				.	DI					(	rio0_treq_fifo_di		),
				.	ALMOSTFULL			(	rio0_treq_fifo_af		),
				.	FULL				(	rio0_treq_fifo_fu		),
				.	RDEN_LAST			(	1'b0					),
				.	RDEN				(	rio0_treq_fifo_rd		),
				.	DO					(	rio0_treq_fifo_do		),
				.	ALMOSTEMPTY			(	rio0_treq_fifo_ae		),
				.	EMPTY				(	rio0_treq_fifo_em		),
				.	RDCOUNT				(							),
				.	RDERR				(							),
				.	RDCLK				(	core_clk						)
			);
		end else begin
			// Use real FIFO
			hdl_eqw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"distributed"	),
				.	ALMOST_EMPTY_OFFSET		(	'h8				),
				.	ALMOST_FULL_OFFSET		(	'h8				),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						(	5				),
				.	DW						(	64				)
			)axsr0_info(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk				),
				.	WRCOUNT				(						),
				.	WRERR				(						),
				.	WREN				(	rio0_treq_info_wr	),
				.	DI					(	rio0_treq_info_di	),
				.	ALMOSTFULL			(	rio0_treq_info_af	),
				.	FULL				(	rio0_treq_info_fu	),
				.	RDEN				(	rio0_treq_info_rd	),
				.	DO					(	rio0_treq_info_do	),
				.	ALMOSTEMPTY			(	rio0_treq_info_ae	),
				.	EMPTY				(	rio0_treq_info_em	),
				.	RDCOUNT				(						),
				.	RDERR				(						),
				.	RDCLK				(	core_clk				)
			);

			hdl_exw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"block"			),
				.	ALMOST_EMPTY_OFFSET		(	'h10			),
				.	ALMOST_FULL_OFFSET		(	'h10			),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						( 	10				),
				.	DW						(	DW				),
				.	QW						(	DW				)
			)axsr0_fifo(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk				),
				.	WRCOUNT				(						),
				.	WRERR				(						),
				.	WREN_CLEAR			(	1'b0				),
				.	WREN_LAST			(	1'b0				),
				.	WREN				(	rio0_treq_fifo_wr		),
				.	DI					(	rio0_treq_fifo_di		),
				.	ALMOSTFULL			(	rio0_treq_fifo_af		),
				.	FULL				(	rio0_treq_fifo_fu		),
				.	RDEN_LAST			(	1'b0				),
				.	RDEN				(	rio0_treq_fifo_rd		),
				.	DO					(rio0_treq_fifo_do		),
				.	ALMOSTEMPTY			(rio0_treq_fifo_ae		),
				.	EMPTY				(rio0_treq_fifo_em		),
				.	RDCOUNT				(						),
				.	RDERR				(						),
				.	RDCLK				(	core_clk				)
			);
		end
	endgenerate


//==================================================================================================
//--SRIO 1 输出缓存

	generate
		if (0) begin
			// Use simulation FIFO
			sim_eqw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"distributed"	),
				.	ALMOST_EMPTY_OFFSET		(	'h8				),
				.	ALMOST_FULL_OFFSET		(	'h8				),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						(	5				),
				.	DW						(	64				)
			)axsr1_info(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk						),
				.	WRCOUNT				(							),
				.	WRERR				(							),
				.	WREN				(	rio1_treq_info_wr		),
				.	DI					(	rio1_treq_info_di		),
				.	ALMOSTFULL			(	rio1_treq_info_af		),
				.	FULL				(rio1_treq_info_fu		),
				.	RDEN				(rio1_treq_info_rd		),
				.	DO					(rio1_treq_info_do		),
				.	ALMOSTEMPTY			(rio1_treq_info_ae		),
				.	EMPTY				(rio1_treq_info_em		),
				.	RDCOUNT				(							),
				.	RDERR				(							),
				.	RDCLK				(core_clk						)
			);

			sim_exw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"block"			),
				.	ALMOST_EMPTY_OFFSET		(	'h10			),
				.	ALMOST_FULL_OFFSET		(	'h10			),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						(   10			),
				.	DW						(	DW				),
				.	QW						(	DW				)
			)axsr1_fifo(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk						),
				.	WRCOUNT				(							),
				.	WRERR				(							),
				.	WREN_CLEAR			(	1'b0					),
				.	WREN_LAST			(	1'b0					),
				.	WREN				(rio1_treq_fifo_wr		),
				.	DI					(rio1_treq_fifo_di		),
				.	ALMOSTFULL			(rio1_treq_fifo_af		),
				.	FULL				(rio1_treq_fifo_fu		),
				.	RDEN_LAST			(	1'b0					),
				.	RDEN				(rio1_treq_fifo_rd		),
				.	DO					(rio1_treq_fifo_do		),
				.	ALMOSTEMPTY			(rio1_treq_fifo_ae		),
				.	EMPTY				(rio1_treq_fifo_em		),
				.	RDCOUNT				(							),
				.	RDERR				(							),
				.	RDCLK				(core_clk						)
			);
		end else begin
			// Use real FIFO
			hdl_eqw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"distributed"	),
				.	ALMOST_EMPTY_OFFSET		(	'h8				),
				.	ALMOST_FULL_OFFSET		(	'h8				),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						(	5				),
				.	DW						(	64				)
			)axsr1_info(
				.	RST					(	~rst_n					),
				.	WRCLK				(	clk				),
				.	WRCOUNT				(						),
				.	WRERR				(						),
				.	WREN				(	rio1_treq_info_wr	),
				.	DI					(	rio1_treq_info_di	),
				.	ALMOSTFULL			(	rio1_treq_info_af	),
				.	FULL				(rio1_treq_info_fu	),
				.	RDEN				(rio1_treq_info_rd	),
				.	DO					(rio1_treq_info_do	),
				.	ALMOSTEMPTY			(rio1_treq_info_ae	),
				.	EMPTY				(rio1_treq_info_em	),
				.	RDCOUNT				(						),
				.	RDERR				(						),
				.	RDCLK				(	core_clk				)
			);

			hdl_exw_afifo	#(
				.	LOOP_NUM				(	0				),
				.	RAM_STYLE				(	"block"			),
				.	ALMOST_EMPTY_OFFSET		(	'h10			),
				.	ALMOST_FULL_OFFSET		(	'h10			),
				.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			),
				.	AW						(   10	),
				.	DW						(	DW				),
				.	QW						(	DW				)
			)axsr1_fifo(
				.	RST					(	~rst_n				),
				.	WRCLK				(	clk					),
				.	WRCOUNT				(						),
				.	WRERR				(						),
				.	WREN_CLEAR			(	1'b0				),
				.	WREN_LAST			(	1'b0				),
				.	WREN				(rio1_treq_fifo_wr		),
				.	DI					(rio1_treq_fifo_di		),
				.	ALMOSTFULL			(rio1_treq_fifo_af		),
				.	FULL				(rio1_treq_fifo_fu		),
				.	RDEN_LAST			(	1'b0				),
				.	RDEN				(rio1_treq_fifo_rd		),
				.	DO					(rio1_treq_fifo_do		),
				.	ALMOSTEMPTY			(rio1_treq_fifo_ae		),
				.	EMPTY				(rio1_treq_fifo_em		),
				.	RDCOUNT				(						),
				.	RDERR				(						),
				.	RDCLK				(core_clk				)
			);
		end
	endgenerate

endmodule
