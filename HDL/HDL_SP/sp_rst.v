//////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY
// Engineer:		ZhengYunLong
//
// Create Date:		2018/11/5 17:36:00
// Design Name:
// Module Name:		xr2000_srio_rst.v
// Project Name:	XR2000
// Target Devices:	XC7K325TFFG676-2
// Tool versions:	Vivado 2016.4
// Description:
//	XR2000项目仿真卡的SRIO复位设计，当检测到SRIO设备的Link_initiazation时，进行复位设计，
//支持寄存器复位配置。复位信号控制时钟不能用log_clk，防止锁死
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - 2018/11/14 12:44:36 
//		Add Link Reset Signals 
// Revision 0.03 -2018/11/15 18:45:44
//		Add PowerUp Reset,hold time for 300ms
//		Add PowerUP firber reset
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////////////////////
module	sp_rst	#(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	--------------------------------------------------------------------------------------*/
	parameter		P_SIMULATION_R				= "FALSE"
	)(
//==================================================================================================
//--Port Defines
	/*--------------------------------------------------------------------------------------
	--Common Inteface
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										rst											,

	/*--------------------------------------------------------------------------------------
	--SRIO Link Status Interface
	--------------------------------------------------------------------------------------*/
	input										port_initialized							,
	input										link_initialized							,
	input										mode_1x										,


	input			[31:0]						reg_srio_reset_time_c						,
	input										reg_srio_reset_enable_c						,
	input										reg_srio_reset_trig_c						,
	input										reg_srio_1x_auto_rst_en						,
	
	/*--------------------------------------------------------------------------------------
	--SRIO Reset Output
	--------------------------------------------------------------------------------------*/
	output	reg									force_reinit			= 1'b0
	);
//==================================================================================================
//--Parameter Defines
	localparam									S_RST_IDLE_M			= 3'b001			;
	localparam									S_RST_RST_M				= 3'b010			;
	localparam									S_RST_DONE_M			= 3'b100			;

	localparam									B_RST_RST_M				= 2'b1				;
	localparam									B_RST_DONE_M			= 2'd2				;

//==================================================================================================
//--Signals Defines	
	reg				[2:0]						S_RST_CM				= 0					;
	reg				[2:0]						S_RST_NM				= 0					;
	
	reg				[2:0]						link_q					= 0					;
	wire										link_fe										;
	wire										link_re										;


	wire										reset_trig									;
	
	reg				[31:0]						rst_cnt				= 0						;


			wire								rio_1x_rst_req							;

//==================================================================================================
//--Falling edge detect
	always @(posedge clk) begin
		link_q[2:0]								<= {link_q[1:0],link_initialized}			;
	end

	assign	link_fe								= link_q[2] && ~link_q[1]					;
	assign	link_re								= ~link_q[2] && link_q[1]					;
	assign	reset_trig							= link_fe && reg_srio_reset_enable_c		;
	
	
//==================================================================================================
//--Reset Implement
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			S_RST_CM							<= S_RST_IDLE_M								;
		end else begin
			S_RST_CM							<= S_RST_NM									;
		end
	end

	always @* begin
		S_RST_NM								= S_RST_IDLE_M								;
		case(S_RST_CM)
			S_RST_IDLE_M						: begin
				if(reg_srio_reset_trig_c | reset_trig) begin
					S_RST_NM					= S_RST_RST_M								;
				end else begin
					S_RST_NM					= S_RST_IDLE_M								;
				end
			end
			S_RST_RST_M							: begin
				if(rst_cnt==reg_srio_reset_time_c) begin
					S_RST_NM					= S_RST_DONE_M								;
				end else begin
					S_RST_NM					= S_RST_RST_M								;
				end
			end
			S_RST_DONE_M						: begin
				S_RST_NM						= S_RST_IDLE_M								;
			end
			default								: begin
				S_RST_NM						= S_RST_IDLE_M								;
			end
		endcase
	end
	
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			force_reinit						<= 1'b0										;
		end else if(S_RST_NM[B_RST_RST_M]) begin
			force_reinit						<= 1'b1										;
		end else begin
		//	force_reinit						<= 1'b0										;
			force_reinit						<= rio_1x_rst_req							;
		end
	end

	always @(posedge clk) begin
		if(S_RST_NM[B_RST_RST_M]) begin
			rst_cnt								<= rst_cnt + 1'b1							;
		end else begin
			rst_cnt								<= 32'b0									;
		end
	end
	
`ifndef	SRIO_1_LANE
			
			reg		[	1		*	5	-1:0]	cs_1x_rst			=	0				;
			localparam	idle			=	5'h1	;	wire	cs_idle				=	cs_1x_rst[clogb2(	idle			)]	;
			localparam	rst_counter		=	5'h2	;	wire	cs_rst_counter		=	cs_1x_rst[clogb2(	rst_counter		)]	;
			localparam	rst_once_done	=	5'h4	;	wire	cs_rst_once_done	=	cs_1x_rst[clogb2(	rst_once_done	)]	;
			localparam	wait_port_init	=	5'h8	;	wire	cs_wait_port_init	=	cs_1x_rst[clogb2(	wait_port_init	)]	;
			localparam	wait_link_init	=	5'h10	;	wire	cs_wait_link_init	=	cs_1x_rst[clogb2(	wait_link_init	)]	;
			reg									rio_1x_rst_reg		=	0				;
			reg		[	1		*	24	-1:0]	rio_1x_rst_count	=	0				;	//	每次复位时间
			reg		[	1		*	4	-1:0]	rio_1x_rst_cycle	=	0				;	//	复位尝试次数
			wire								mode_1x_ture		=	port_initialized	&&	mode_1x	;
			
			always@(posedge	clk)	begin
				if(	rst	)	cs_1x_rst	<=	0	;
				else	case	(cs_1x_rst)	
					idle	:	begin
						if			(	~	reg_srio_1x_auto_rst_en		)	cs_1x_rst	<=	idle		;
						else	if	(		link_initialized			)	cs_1x_rst	<=	idle		;
						else	if	(		mode_1x_ture				)	cs_1x_rst	<=	rst_counter	;
						else	cs_1x_rst	<=	cs_1x_rst	;
					end
					rst_counter	:	begin
						if(		rio_1x_rst_count[9]	)	cs_1x_rst	<=	rst_once_done	;
						else	cs_1x_rst	<=	cs_1x_rst	;
					end
					rst_once_done	:	begin
						cs_1x_rst	<=	rio_1x_rst_cycle[3]	?	wait_link_init	:	wait_port_init	;
					end
					wait_port_init	:	begin
						if(	mode_1x_ture	)	cs_1x_rst	<=	rst_counter	;
						else	if(	link_initialized			)	cs_1x_rst	<=	idle	;
						else	if(	rio_1x_rst_count[23]		)	cs_1x_rst	<=	idle	;
						else	cs_1x_rst	<=	cs_1x_rst	;
					end
					wait_link_init	:	begin
						if(			link_initialized			)	cs_1x_rst	<=	idle	;
						else	if(	rio_1x_rst_count[23]		)	cs_1x_rst	<=	idle	;
						else	cs_1x_rst	<=	cs_1x_rst	;
					end
					default	:	cs_1x_rst	<=	idle	;
				endcase
			end
			
			always@(posedge	clk)	begin
				if(	cs_rst_counter				)	rio_1x_rst_count	<=	rio_1x_rst_count	+	!port_initialized	;
				else	if(	cs_wait_port_init	)	rio_1x_rst_count	<=	mode_1x_ture	?	0	:	rio_1x_rst_count	+	1	;
				else	if(	cs_wait_link_init	)	rio_1x_rst_count	<=	rio_1x_rst_count	+	1	;
				else	rio_1x_rst_count	<=	0	;
			end
			
			always@(posedge	clk)	begin
				if(	rst	)	rio_1x_rst_cycle	<=	0	;
				else	if(	cs_idle					)	rio_1x_rst_cycle	<=	0						;
				else	if(	cs_rst_once_done		)	rio_1x_rst_cycle	<=	rio_1x_rst_cycle	+1	;
				else									rio_1x_rst_cycle	<=	rio_1x_rst_cycle		;
			end

			always@(posedge	clk)	rio_1x_rst_reg		<=	cs_rst_counter	;
			assign	rio_1x_rst_req			=	rio_1x_rst_reg	;

`else	
			assign	rio_1x_rst_req			=	0	;
`endif
		
		function integer clogb2;
		  input integer depth;
		  integer depth_reg;
			begin
				depth_reg = depth;
				for (clogb2=0; depth_reg>0; clogb2=clogb2+1)begin
				  depth_reg = depth_reg >> 1;
				end
				if( 2**clogb2 >= depth*2 )begin
				  clogb2 = clogb2 - 1;
				end
			end 
		endfunction
endmodule