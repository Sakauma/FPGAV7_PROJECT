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
// Inst File�???							
// 										
// Revision:							
// 										
////////////////////////////////////////////////////////////////////////////////////////////////////
module sp_collect_4k	#(					
	parameter		BUS_DW						= 64										,
	parameter		PARA2						= 32										
	)(
		
//---selfdefine Interface-----------------------
										
	                                                                                           
	input										sr_iorx_tvalid								,  
	output										sr_iorx_tready								,  
	input										sr_iorx_tlast								,  
	input			[63:0]						sr_iorx_tdata								,  
	input			[7:0]						sr_iorx_tkeep								,  
	input			[31:0]						sr_iorx_tuser								,  
	
	output										rio_treq_info_wr							,//info信息描述图像范围，以及图像序�???
	output			[64-1:0]					rio_treq_info_di							,
	input										rio_treq_info_af							,
	input										rio_treq_info_fu							,
	output										rio_treq_fifo_wr							,
	output			[BUS_DW-1:0]				rio_treq_fifo_di							,
	input										rio_treq_fifo_af							,
	input										rio_treq_fifo_fu							,
	output										rio_treq_fifo_wl							,
	
	
	output	reg		[31:0]						srio_rx_pkg_cnt								,
	output	reg		[31:0]						srio_rx_ocm_cnt								,
	output	reg		[31:0]						srio_rx_4k_cnt								,
	output	reg		[31:0]						srio_rx_dat_cnt								,
	
	
	
												 
//---Common Interface---------------------------
	input										clk											,
	input										rst_n										 
	);
//==================================================================================================
//--Signals Define------------------------------


	reg		[4:0]								cs,ns										;
	
	/*--------------------------------------------------------------------------------------
	--READY 信号在空闲状态下为低 ，等待数据进入后接受包信息，
	 根据地址判断判断包类型�??
	 如果地址范围�??? 0x0-4096 为ocm包丢�???
	其他为数据包
	--------------------------------------------------------------------------------------*/	
	localparam									IDLE	  = 5'b00001						;
	localparam									ADR_CHECK = 5'b00010						;
	localparam									DAT_WRITE = 5'b00100						;
	localparam									OCM_DISCA = 5'b01000						;
	localparam									PKG_FINSH = 5'b10000						;
	
	//srio 包地�???映射规则可能不是字节
	localparam									RIO_OCM_ADDR= 33'h1000						;
	//拼包单元是多�??? 以太�???8k  �???�???4k
	localparam									RIO_SYN_ADDR= 33'h1000	-1					;  
	//操作的srio包大小单�???
	localparam									SR_PKG_BNUM= 32'h200						;
	
//==================================================================================================
//--axi stream info
	//用来捕获srio头信息标�???
	reg											axs_sop										;
	wire	[63:0]	tdata						=sr_iorx_tdata								;
	wire			tready						;assign	sr_iorx_tready  =	tready        	;
	wire			trv		                    = sr_iorx_tready&sr_iorx_tvalid				;
    wire			trvl	                    = sr_iorx_tready&sr_iorx_tvalid&sr_iorx_tlast;
    reg  			trvl_q	                   ;always @(posedge clk ) trvl_q 		<= trvl ;	//ram 操作根据trv用时序控制，存在滞后一拍 ，状态机结束用trvlq控制	
	 
    wire			trv_head				  	=		axs_sop	&&	trv						;
    wire			trv_data					=	~	axs_sop	&&	trv						;
  																 		
  	
  	
//==================================================================================================
//--  	srio msg	
		reg		[63:0]	rio_head	    ;
  		wire	[63:56]	req_srcTID		;   
  		wire	[63:60]	req_msglen_1	;
		wire	[59:56]	req_msgseg_1	;	                                    
  		wire	[55:52]	req_FTYPE       ;     		                                 
  		wire	[51:48]	req_TTYPE	    ;     		                                    
  		wire	[46:45]	req_prio	    ;     		                                    
  		wire	[44:44]	req_CRF	    	;     		                                    
  		wire	[43:36]	req_size_1    	;     		                                    
  		wire	[33:0]	req_addr		;     		                                    
  		wire	[31:16]	req_info		;     		                                    
  		wire	[9:4]	req_mailbox     ;     		                                    			 																																																																										
    	wire	[1:0]	req_letter    	;   
    	
    	reg		[15:0]	video_cnt		;
    	reg		[31:0]	video_row_loc	;//记录图像其实地址内容
    	
//==================================================================================================
//--	ram signal     	
    	reg						ram_wena;
    	reg		[ 9:0]			ram_addra;	
    	reg     [63:0]			ram_wdata;
    	reg		[ 9:0]			ram_addrb;
    	wire	[63:0]			ram_rdata;
    	
    	reg						pkg_reading;
		reg						pkg_reading_q0;
		reg						pkg_reading_q1;
		reg						pkg_reading_last_q0;
		reg						pkg_reading_last_q1;
		reg		[15:0]			write_word_count;
		reg		[15:0]			read_word_count;
		wire	[15:0]			write_word_count_next;
		wire					packet_done;
		wire					read_issue_last;
		
    	
//==================================================================================================
//--Parameter Define----------------------------



 

    always@(posedge	clk)	begin
		if(~rst_n)begin
			cs	<=	IDLE	;
		end else begin
			cs	<=	ns	;
		end
	end
	always@(*)	begin
		ns										=	cs										;
		case( cs)
		IDLE	:	begin
			if( sr_iorx_tvalid )begin 
				ns								= ADR_CHECK									;
			end else begin 
				ns								= IDLE										;
			end		
		end
		ADR_CHECK	:	begin
			if(req_addr >=RIO_OCM_ADDR )	begin 
				ns								=	DAT_WRITE								;
			end else begin 
				ns								=	OCM_DISCA								;
			end	
		end
		DAT_WRITE	:	begin
			if( trvl_q )	begin
				ns								=	PKG_FINSH								;
			end else begin
				ns								=	DAT_WRITE								;
			end
		end
		OCM_DISCA	:	begin
			if (trvl ) begin
				ns								= IDLE										;
			end else begin 
				ns								= OCM_DISCA									;
			end
		end
		PKG_FINSH	:	begin
			 if((~pkg_reading) && (~pkg_reading_q0) && (~pkg_reading_q1) )begin
			 	ns								= IDLE										;
			 end else begin 
			 	ns								= PKG_FINSH									;
			 end
		end	 		
		default	:	ns	= IDLE	;
		endcase
	end          
      
      
    assign	 tready						= rst_n ==0 								? 1'b0 :
										// cs==IDLE &&sr_iorx_tvalid					? 1'b1 :
										  cs==IDLE|| cs == PKG_FINSH   				? 1'b0 :
										 pkg_reading == 1'b1 &  ram_addra >=ram_addrb?1'b0 :
										 											  1'b1 ;
    	//[15:0]	video_cnt												  		
      //reg  [31:0]	video_row_loc															;
      always @ ( posedge clk ) begin 
      	if (~rst_n) begin
      		video_cnt							<= 0 										;
      	end else if ( video_row_loc == 32'd2048) begin //这里计数单位后续�???核对
      		video_cnt 							<= video_cnt +1'b1							;
      	end
      end
      
      always @( posedge clk ) begin 
      	if (~rst_n )begin 
      		video_row_loc						<= 32'd0									;
      	end else if ( ram_addra == 0 && cs==ADR_CHECK ) begin
      		video_row_loc						<= req_addr									;
      	end 
      end
      always @(posedge clk ) begin
		if (~rst_n ) begin 
			axs_sop								<= 1'b1										;
		end else if ( trvl  ) begin 
			axs_sop								<= 1'b1										;
		end else if ( trv ) begin 
			axs_sop								<= 1'b0										;
		end else begin 
			axs_sop								<= axs_sop									;
		end
	  end
              
      always @ (posedge clk ) begin 
      	if (~rst_n	) begin 
      		rio_head        					<= 0										;
      	end else if ( trv_head ) begin 
      		rio_head							<=  tdata									;
      	end else begin 
      		rio_head							<= rio_head									;
      	end
      end
   
   assign		req_srcTID			=	axs_sop			?	tdata[63:56]	:	rio_head[63:56]		;   
   assign		req_msglen_1		=	axs_sop			?	tdata[63:60]	:	rio_head[63:60]		;   
   assign		req_msgseg_1    	=	axs_sop			?	tdata[59:56]	:	rio_head[59:56]		;   
   assign		req_FTYPE       	=	axs_sop			?	tdata[55:52]	:	rio_head[55:52]		;   
   assign		req_TTYPE	    	=	axs_sop			?	tdata[51:48]	:	rio_head[51:48]		;   
   assign		req_prio	    	=	axs_sop			?	tdata[46:45]	:	rio_head[46:45]		;   
   assign		req_CRF	    		=	axs_sop			?	tdata[44:44]	:	rio_head[44:44]		;   
   assign		req_size_1    		=	axs_sop			?	tdata[43:36]	:	rio_head[43:36]		;   
   assign		req_addr			=	axs_sop			?	tdata[33:0]		:	rio_head[33:0]		;   
   assign		req_info			=	axs_sop			?	tdata[31:16]	:	rio_head[31:16]		;   
   assign		req_mailbox     	=	axs_sop			?	tdata[9:4]		:	rio_head[9:4]		;   
   assign		req_letter    		=	axs_sop			?	tdata[1:0]		:	rio_head[1:0]		;   
   
   
   
    always @ ( posedge clk ) begin 
  	 if( ~ rst_n) begin
  	 	ram_wena				<= 1'b0		;
  	 end else if (cs == DAT_WRITE&& trv	 ) begin 
  	 	ram_wena            	<= 1'b1		;
	 end else begin
	   ram_wena				    <= 1'b0		;
	 end
   end           
	always @ ( posedge clk ) begin 
  	 if( ~ rst_n) begin
  	 	ram_wdata				<= 32'd0		;//12bit shi 4k 的达成为
  	 end else  begin
  	 	ram_wdata				<= sr_iorx_tdata 		;
  	 end
   end            
   //assign ram_wdata    = sr_iorx_tdata ;
  always @ ( posedge clk ) begin 
  	 if( ~ rst_n) begin
  	 	ram_addra				<= 32'd0		;
  	 end else if (ns ==  ADR_CHECK ) begin 
  	 	ram_addra           	<= req_addr[11:3]		;//12bit shi 4k 的达成为
  	 end else if (ram_wena )begin
  	 	ram_addra				<= ram_addra+1'b1 				;
  	 end
   end           

   assign write_word_count_next = write_word_count + {15'd0, ram_wena};
   assign packet_done = trvl_q && (write_word_count_next != 16'd0);
   assign read_issue_last = pkg_reading && ((ram_addrb + 1'b1) >= read_word_count);

   always @( posedge clk ) begin 
   		if (~ rst_n )begin 
   			pkg_reading           <= 1'b0			;
		end else if ( packet_done ) begin
   			pkg_reading			  <= 1'b1			;
		end else if ( read_issue_last || rio_treq_fifo_af)begin
    	    pkg_reading     	  <= 1'b0			;
    	end else begin 
    		pkg_reading			  <= pkg_reading	;
		end
   end
   always @(posedge clk ) begin
		if (~rst_n) begin
			pkg_reading_q0		  <= 1'b0;
			pkg_reading_last_q0	  <= 1'b0;
		end else begin
			pkg_reading_q0		  <= pkg_reading	;
			pkg_reading_last_q0	  <= read_issue_last;
		end
   end
   //RAM data have  2 clock delay
   always @(posedge clk ) begin
		if (~rst_n) begin
			pkg_reading_q1		  <= 1'b0;
			pkg_reading_last_q1	  <= 1'b0;
		end else begin
			pkg_reading_q1		  <= pkg_reading_q0	;
			pkg_reading_last_q1	  <= pkg_reading_last_q0;
		end
   end

   always@ (posedge clk ) begin 
   		if (~ rst_n) begin 
   			ram_addrb								<= 0 										;
   		end else if ( pkg_reading ) begin 
   			ram_addrb								<= ram_addrb +1'b1							;
   		end else begin
			ram_addrb								<= 0 										;
		end
	end
	assign	rio_treq_fifo_wr         =pkg_reading_q1;//RAM data have  2 clock delay
	assign	rio_treq_fifo_di		 =ram_rdata	;
	
	assign	rio_treq_info_wr 		=	packet_done;
	assign	rio_treq_info_di		= 	{video_cnt,video_row_loc,{write_word_count_next[12:0],3'b000}} ;
    assign	rio_treq_fifo_wl        =	pkg_reading_last_q1;

	always @(posedge clk) begin
		if (~rst_n) begin
			write_word_count		<= 16'd0;
		end else if (ns == ADR_CHECK) begin
			write_word_count		<= 16'd0;
		end else if (ram_wena) begin
			write_word_count		<= write_word_count + 1'b1;
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			read_word_count			<= 16'd0;
		end else if (packet_done) begin
			read_word_count			<= write_word_count_next;
		end
	end

sr_dat_ram dat_4k (
  .clka	(			clk				),    // input wire clka
  .ena	(			1'b1			),      // input wire ena
  .wea	(			ram_wena		),      // input wire [0 : 0] wea
  .addra(			ram_addra		),  // input wire [3 : 0] addra
  .dina	(			ram_wdata		),    // input wire [63 : 0] dina
  .douta(			 				),  // output wire [63 : 0] douta
  .clkb	(			clk				),    // input wire clkb
  .enb	(			1'b1			),      // input wire enb
  .web	(			1'b0			),      // input wire [0 : 0] web
  .addrb(			ram_addrb		),  // input wire [3 : 0] addrb
  .dinb	(			32'h0 			),    // input wire [63 : 0] dinb
  .doutb(			ram_rdata		)  // output wire [63 : 0] doutb
);



endmodule
