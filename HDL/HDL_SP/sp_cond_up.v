 `timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:			HXZY
// Engineer:		ZYL
// Create Date:		2018/5/11 19:52:11
// Design Name:		XR2000
// Module Name:		sp_up
// Project Name:
// Target Devices:	K7-V7
// Tool Versions: 	Vivado 2016.1 HDL-EDIT UltraEdit TAB=4 Consolas
// Description:
//		文件实现SRIO冗余IP Core接收到的数据上传
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sp_cond_up #(
	/*--------------------------------------------------------------------------------------
	--P_SIMULATION_R
	---------------------------------------------------------------------------------------*/
	parameter									LOOP_NUM				= 0					,
	parameter									P_SIMULATION_R			= "FALSE"			,
	parameter									P_BIG_CACHE_R			= "FALSE"
	)(
//==================================================================================================
//--输入输出端口定义---------------------------
	/*--------------------------------------------------------------------------------------
	--Common Interface
	--|clk-->可以连接log_clk，也可以连接外部时钟，进行快速查询处理
	--|rst-->复位信号，高电平同步复位信号
	--------------------------------------------------------------------------------------*/
	input										clk											,
	input										log_clk										,
	input										rst											,
	input										srio_rst									,
	/*--------------------------------------------------------------------------------------
	--统计寄存器
	--------------------------------------------------------------------------------------*/	
	output	reg		[31:0]						c_sp_up_cnt									,
	output	reg		[31:0]						c_sp_rx_cnt									,
	input	wire								c_sp_en										,

//==================================================================================================
//--DMA Channel Signals
	/*--------------------------------------------------------------------------------------
	--DMA Channel AXI Stream Inteface
	--------------------------------------------------------------------------------------*/
	output			[63:0]						dma_s_axis_tdata							,
	output			[ 3:0]						dma_s_axis_tid								,
	input										dma_s_axis_tready							,
	output										dma_s_axis_tvalid							,
	output			[ 7:0]						dma_s_axis_tstrb							,
	output			[ 7:0]						dma_s_axis_tkeep							,
	output										dma_s_axis_tlast							,
	output			[63:0]						dma_s_axis_tuser							,
	output			[ 3:0]						dma_s_axis_tdest							,

//==================================================================================================
//--SRIO Reduncy Signals
	/*--------------------------------------------------------------------------------------
	--USER SRIO Redundancy Interface
	--------------------------------------------------------------------------------------*/
	input										sr_iorx_tvalid								,
	output										sr_iorx_tready								,
	input										sr_iorx_tlast								,
	input			[63:0]						sr_iorx_tdata								,
	input			[ 7:0]						sr_iorx_tkeep								,
	input			[31:0]						sr_iorx_tuser
	);
//==================================================================================================
//--参数定义
	/*--------------------------------------------------------------------------------------
	--状态机参数
	--------------------------------------------------------------------------------------*/
	localparam									S_SR_IDLE_M				= 2'b01				;
	localparam									S_SR_DATA_M				= 2'b10				;
	
	/*--------------------------------------------------------------------------------------
	--DMA接口状态参数定义
	--------------------------------------------------------------------------------------*/	
	localparam									S_D_IDLE_M				= 5'b00001			;	//	0
	localparam									S_D_PRE_M				= 5'b00010			;	//	1
	localparam									S_D_DATA_M				= 5'b00100			;	//	2
	localparam									S_D_DONE_M				= 5'b01000			;	//	3
	localparam									S_D_AFRST_M				= 5'b10000			;	//	4
	
//==================================================================================================
//--信号定义
	/*--------------------------------------------------------------------------------------
	--SRIO RX接口处理
	--------------------------------------------------------------------------------------*/	
	reg				[ 1:0]						S_SR_NM										;
	reg				[ 1:0]						S_SR_CM										;
	
	reg				[31:0]						sr_iorx_id									;
	reg				[15:0]						sr_iorx_cnt									;
	wire			[15:0]						sr_iorx_cnt_pre								;
	
	/*--------------------------------------------------------------------------------------
	--DMA接口状态机信号定义
	--------------------------------------------------------------------------------------*/	
	reg				[ 4:0]						S_D_CM										;
	reg				[ 4:0]						S_D_NM										;
	
	reg				[15:0]						dma_cnt										;
	wire			[15:0]						dma_s_len									;
	
	/*--------------------------------------------------------------------------------------
	--数据及事务FIFO信号定义
	--------------------------------------------------------------------------------------*/	
	wire			[63:0]						data_fifo_din								;
	wire										data_fifo_wen								;
	wire										data_fifo_full								;
	wire										data_fifo_afull								;
	
	wire			[63:0]						data_fifo_dout								;
	wire										data_fifo_ren								;
	wire										data_fifo_empty								;
	
	reg				[63:0]						trn_fifo_din								;
	reg											trn_fifo_wen								;
	
	wire			[63:0]						trn_fifo_dout								;
	wire										trn_fifo_ren								;
	wire										trn_fifo_empty								;
	wire										trn_fifo_full								;
	wire										trn_fifo_afull								;

	wire										dma_trv										;
	assign					dma_trv	=	dma_s_axis_tvalid	&&	dma_s_axis_tready			;
	wire										fifo_empyt									;
	assign					fifo_empyt	=	trn_fifo_empty	||	data_fifo_empty				;	
	
//==================================================================================================
//--SRIO数据接收写入FIFO
	always @(posedge log_clk ) begin
		if(rst) begin
			S_SR_CM								<= S_SR_IDLE_M								;
		end else begin
			S_SR_CM								<= S_SR_NM									;
		end
	end

	always @(*) begin		
		if(rst)	begin	
			S_SR_NM									= S_SR_IDLE_M								;
		end	else	begin
			S_SR_NM									= S_SR_CM									;
			case(S_SR_CM)
				S_SR_IDLE_M							: begin
					if(sr_iorx_tvalid && sr_iorx_tready && sr_iorx_tlast) begin
						S_SR_NM						= S_SR_IDLE_M								;
					end else if(sr_iorx_tvalid && sr_iorx_tready) begin
						S_SR_NM						= S_SR_DATA_M								;
					end else begin
						S_SR_NM						= S_SR_IDLE_M								;
					end
				end
				S_SR_DATA_M							: begin
					if((sr_iorx_tvalid && sr_iorx_tready && sr_iorx_tlast)|srio_rst) begin
						S_SR_NM						= S_SR_IDLE_M								;
					end else begin
						S_SR_NM						= S_SR_DATA_M								;
					end
				end
				default								: begin
					S_SR_NM							= S_SR_IDLE_M								;
				end
			endcase
		end
	end

	always @(posedge log_clk ) begin
		if(rst) begin
			sr_iorx_id							<= 32'b0									;
		end else begin
			case(S_SR_CM)
				S_SR_IDLE_M						: begin
					sr_iorx_id					<= sr_iorx_tuser							;
				end
				S_SR_DATA_M						: begin
					sr_iorx_id					<= sr_iorx_id								;
				end
				default							: begin
					sr_iorx_id					<= sr_iorx_id								;
				end
			endcase
		end
	end
	
	always @(posedge log_clk ) begin
		if(rst) begin
			sr_iorx_cnt							<= 16'b0									;
		end else begin
			case(S_SR_CM)
				S_SR_IDLE_M						: begin
					if((sr_iorx_tvalid && sr_iorx_tready && sr_iorx_tlast) | srio_rst) begin
						sr_iorx_cnt				<= 16'b0									;
					end else	if(sr_iorx_tvalid && sr_iorx_tready) begin
						sr_iorx_cnt				<= sr_iorx_cnt + 1'b1						;
					end else begin
						sr_iorx_cnt				<= 16'b0									;
					end
				end
				S_SR_DATA_M						: begin
					if((sr_iorx_tvalid && sr_iorx_tready && sr_iorx_tlast) | srio_rst) begin
						sr_iorx_cnt				<= 16'b0									;
					end else if(sr_iorx_tvalid && sr_iorx_tready) begin
						sr_iorx_cnt				<= sr_iorx_cnt + 1'b1						;
					end else begin
						sr_iorx_cnt				<= sr_iorx_cnt								;
					end
				end
			endcase
		end
	end
	
	assign	sr_iorx_cnt_pre						= sr_iorx_cnt + 1'b1						;
	
	reg	sp_en_vld	=	0	;
	
	assign	data_fifo_wen						= sr_iorx_tvalid && sr_iorx_tready &&	sp_en_vld	;
	
//	wire			[63:0]						sr_iorx_tdata_swap							;
//	assign	sr_iorx_tdata_swap					= 	{
//														sr_iorx_tdata[7:0],
//														sr_iorx_tdata[15:8],
//														sr_iorx_tdata[23:16],
//														sr_iorx_tdata[31:24],
//														sr_iorx_tdata[39:32],
//														sr_iorx_tdata[47:40],
//														sr_iorx_tdata[55:48],
//														sr_iorx_tdata[63:56]
//													}										;

//	assign	data_fifo_din						= (sr_iorx_cnt==0)?sr_iorx_tdata:sr_iorx_tdata;
	
	reg	[2:0]	rst_log_syn	=	3'h7	;
	always@(posedge	log_clk)	rst_log_syn	<=	{	rst_log_syn[1:0],rst}	;

	assign	data_fifo_din						= sr_iorx_tdata								;
	assign	sr_iorx_tready						= (data_fifo_afull==1'b0 && trn_fifo_afull==1'b0)?1'b1:rst_log_syn[2];
	
	always @(posedge log_clk ) begin
		if(rst) begin
			trn_fifo_din						<= 64'b0									;
			trn_fifo_wen						<= 1'b0										;
		end else begin
			case(S_SR_CM)
				S_SR_IDLE_M						: begin
					if(sr_iorx_tvalid && sr_iorx_tlast && sr_iorx_tready &&	sp_en_vld) begin
						trn_fifo_din			<= {sr_iorx_tuser,16'h1234,16'd1}			;
						trn_fifo_wen			<= 1'b1										;
					end else begin
						trn_fifo_din			<= 64'hDEED_BEEF							;
						trn_fifo_wen			<= 1'b0										;
					end
				end
				S_SR_DATA_M						: begin
					if(sr_iorx_tvalid && sr_iorx_tlast && sr_iorx_tready &&	sp_en_vld) begin
						trn_fifo_din			<= {sr_iorx_id[31:0],16'h5678,sr_iorx_cnt_pre}	;
						trn_fifo_wen			<= 1'b1										;
					end else if(sr_iorx_tvalid && sr_iorx_tready &&srio_rst&&	sp_en_vld) begin
						trn_fifo_din			<= {sr_iorx_id[31:0],16'h5678,sr_iorx_cnt_pre}	;
						trn_fifo_wen			<= 1'b1										;					
					end else if(srio_rst&&	sp_en_vld) begin
						trn_fifo_din			<= {sr_iorx_id[31:0],16'h5678,sr_iorx_cnt}	;
						trn_fifo_wen			<= 1'b1										;
					end else begin
						trn_fifo_din			<= 64'hDEED_BEEF							;
						trn_fifo_wen			<= 1'b0										;
					end
				end
				default							: begin
					trn_fifo_din				<= 64'hDEED_BEEF							;
					trn_fifo_wen				<= 1'b0										;
				end
			endcase
		end
	end
	
	always @(posedge log_clk ) begin
		if(rst) begin
			c_sp_rx_cnt							<= 32'b0									;
		end else if(sr_iorx_tvalid && sr_iorx_tlast && sr_iorx_tready) begin
			c_sp_rx_cnt							<= c_sp_rx_cnt + 1'b1						;
		end else begin
			c_sp_rx_cnt							<= c_sp_rx_cnt								;
		end
	end
	
	always@(posedge	log_clk)	begin
		if(rst)	sp_en_vld	<=	0	;
		else	if(	sr_iorx_tvalid && sr_iorx_tlast && sr_iorx_tready	)	sp_en_vld	<=	c_sp_en	;
		else	if(	srio_rst											)	sp_en_vld	<=	c_sp_en	;
		else	if(	sr_iorx_cnt	==	0	&&	~	sr_iorx_tvalid			)	sp_en_vld	<=	c_sp_en	;
		else	sp_en_vld	<=	sp_en_vld	;
	end
	
	reg	[1:0]	rst_clk_syn	=	2'h3	;
	always@(posedge	clk)	rst_clk_syn	<=	{rst_clk_syn[0],rst}	;
	
	reg		rst_dly	=	1	;
	always@(posedge	clk)	rst_dly	<=	rst_clk_syn[1]	;
	
	reg		[8:0]	afrst_cnt	=	0	;
	always@(posedge	clk)	begin
		if(S_D_CM[4])	afrst_cnt	<=	(!data_fifo_empty)||(!trn_fifo_empty)||rst_dly	?	0	:	afrst_cnt	+	!afrst_cnt[8]	;
		else	afrst_cnt	<=	0	;
	end
	
//==================================================================================================
//--DMA信号实现
	always @(posedge clk ) begin
		if(rst) begin
			S_D_CM								<= S_D_IDLE_M								;
		end else begin
			S_D_CM								<= S_D_NM									;
		end
	end

	always @(*) begin
		S_D_NM								=	S_D_CM									;
		case(S_D_CM)
			S_D_IDLE_M						: begin
				if(	rst_dly	)	begin
					S_D_NM					=	S_D_AFRST_M								;
				end	else	if(!trn_fifo_empty&&!data_fifo_empty) begin
					S_D_NM					= S_D_PRE_M									;
				end else begin
					S_D_NM					= S_D_IDLE_M								;
				end
			end
			S_D_PRE_M						: begin
				if(dma_trv) begin
					S_D_NM					= S_D_DATA_M								;
				end else begin
					S_D_NM					= S_D_PRE_M									;
				end
			end
			S_D_DATA_M						: begin
//				if(dma_cnt==trn_fifo_dout[15:0] && dma_s_axis_tready) begin
				if(dma_trv&&dma_s_axis_tlast) begin
					S_D_NM					= S_D_DONE_M								;
				end else begin
					S_D_NM					= S_D_DATA_M								;
				end
			end
			S_D_DONE_M						: begin
				S_D_NM						= S_D_IDLE_M								;
			end
			S_D_AFRST_M						: begin
				if(	afrst_cnt[8]	)	begin
					S_D_NM					= S_D_IDLE_M							;
				end	else	begin
					S_D_NM					= S_D_CM								;
				end
			end				
			default							: begin
				S_D_NM						= S_D_IDLE_M								;
			end
		endcase
	end
	
	always @(posedge clk ) begin
		if(rst) begin
			dma_cnt								<= 16'b0									;
		end else if(S_D_DATA_M==S_D_CM || S_D_PRE_M==S_D_CM)  begin
			if(dma_trv) begin
				dma_cnt							<= dma_cnt + 1'b1							;
			end else begin
				dma_cnt							<= dma_cnt									;
			end
		end else begin
			dma_cnt								<= 16'b0									;
		end
	end
	
	localparam	RIO_DW	=	64	;
	wire	[RIO_DW-1:0]	dma_s_axis_tdatax	;
	genvar k;
	for ( k=0; k<RIO_DW; k=k+8 ) begin: up_byte_cvt
		assign	dma_s_axis_tdata[k+:8]	=	dma_s_axis_tdatax[RIO_DW-8-k+:8]		;
	end
	
	assign	dma_s_axis_tdatax					= (S_D_CM==S_D_PRE_M)
												? trn_fifo_dout:data_fifo_dout				;
	
	assign	dma_s_axis_tvalid					= ((S_D_DATA_M==S_D_CM && !data_fifo_empty)	||
													(S_D_PRE_M==S_D_CM && !trn_fifo_empty))
												? 1'b1:1'b0									;
	
	assign	dma_s_axis_tuser[63:0]				= {48'b0,dma_s_len[15:0]}					;

	assign	dma_s_len[15:0]						= {trn_fifo_dout[14:0],1'b0}+2'b10			;
	
	assign	dma_s_axis_tlast					= (dma_cnt>=trn_fifo_dout[15:0]&& dma_s_axis_tvalid)
												? 1'b1:1'b0									;
	
	assign	data_fifo_ren						= (S_D_DATA_M==S_D_CM && dma_trv)
											//	? 1'b1:1'b0									;
												? 1'b1:(S_D_CM[4]&&	!data_fifo_empty)		;
	
	assign	trn_fifo_ren						= (S_D_CM==S_D_DONE_M	&& !trn_fifo_empty)
												?	1'b1:(S_D_CM[4]&&	!trn_fifo_empty)	;
	
	assign	dma_s_axis_tid						= 0											;
	assign	dma_s_axis_tdest					= 0											;
	assign	dma_s_axis_tkeep					= 0											;
	assign	dma_s_axis_tstrb					= 0											;
	
	always @(posedge clk ) begin
		if(rst) begin
			c_sp_up_cnt							<= 32'b0									;
		end else if(trn_fifo_ren) begin
			c_sp_up_cnt							<= c_sp_up_cnt + 1'b1						;
		end else begin
			c_sp_up_cnt							<= c_sp_up_cnt								;
		end
	end
	
//==================================================================================================
//--FIFO例化
generate if(P_BIG_CACHE_R=="TRUE") begin: CACHE_G
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
	)
	i0_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( trn_fifo_afull							),	// 1-bit output almost full
		.DO										( data_fifo_dout[7:0]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( data_fifo_empty							),	// 1-bit output empty
		.FULL									( data_fifo_full 							),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[7:0]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i1_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[15:8]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[15:8]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i2_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[23:16]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[23:16]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i3_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[31:24]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[31:24]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i4_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[39:32]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[39:32]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i5_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[47:40]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[47:40]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i6_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[55:48]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[55:48]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
	
	FIFOE2_DUALCLOCK_MACRO #(
		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
		.DATA_WIDTH								( 8											),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
		)
	i7_data_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( 											),	// 1-bit output almost full
		.DO										( data_fifo_dout[63:56]						),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( 											),	// 1-bit output empty
		.FULL									( 											),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( data_fifo_din[63:56]						),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( data_fifo_wen								)	// 1-bit input write enable
	);
		
end else begin	
//	FIFOE2_DUALCLOCK_MACRO #(
//		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
//		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
//		.DATA_WIDTH								( 64										),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
//		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
//		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
//		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
//		)
//	i_data_fifo (
//		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
//		.ALMOSTFULL								( 											),	// 1-bit output almost full
//		.DO										( data_fifo_dout							),	// Output data, width defined by DATA_WIDTH parameter
//		.EMPTY									( data_fifo_empty							),	// 1-bit output empty
//		.FULL									( data_fifo_full 							),	// 1-bit output full
//		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
//		.RDERR									( 											),	// 1-bit output read error
//		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
//		.WRERR									( 											),	// 1-bit output write error
//		.DI										( data_fifo_din								),	// Input data, width defined by DATA_WIDTH parameter
//		.RDCLK									( clk										),	// 1-bit input read clock
//		.RDEN									( data_fifo_ren								),	// 1-bit input read enable
//		.RST									( rst										),	// 1-bit input reset
//		.WRCLK									( log_clk									),	// 1-bit input write clock
//		.WREN									( data_fifo_wen								)	// 1-bit input write enable
//	);
	
	hdl_eqw_afifo	#(	//	equal	width	async fifo
		.	LOOP_NUM				(	0				)	,
		.	RAM_STYLE				(	"block"			)	,	//	Specify RAM style: auto/block/distributed
		.	ALMOST_EMPTY_OFFSET		(	'h80			)	,
		.	ALMOST_FULL_OFFSET		(	'h41			)	,
		.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
		.	AW						(	09				)	,
		.	DW						(	64				)	
	)i_data_fifo(
		.	RST					(	rst					)	,	//	input	wire					
		.	WRCLK				(	log_clk				)	,	//	input	wire					
		.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
		.	WRERR				(						)	,	//	output	wire					
		.	WREN				(	data_fifo_wen		)	,	//	input	wire					
		.	DI					(	data_fifo_din		)	,	//	input	wire	[DW	-1:0]		
		.	ALMOSTFULL			(	data_fifo_afull		)	,	//	output	wire					
		.	FULL				(	data_fifo_full		)	,	//	output	wire					
		.	RDEN				(	data_fifo_ren		)	,	//	input	wire					
		.	DO					(	data_fifo_dout		)	,	//	output	wire	[QW	-1:0]		
		.	ALMOSTEMPTY			(						)	,	//	output	wire					
		.	EMPTY				(	data_fifo_empty		)	,	//	output	wire					
		.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
		.	RDERR				(						)	,	//	output	wire					
		.	RDCLK				(	clk					)		//	input	wire					
	);
	
end
endgenerate 
	
//	FIFOE2_DUALCLOCK_MACRO #(
//		.ALMOST_EMPTY_OFFSET					( 9'h080									),	// Sets the almost empty threshold
//		.ALMOST_FULL_OFFSET						( 9'h004									),	// Sets almost full threshold
//		.DATA_WIDTH								( 64										),	// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
//		.DEVICE									( "7SERIES"									),	// Target device: "VIRTEX5", "VIRTEX6", "7SERIES"
//		.FIFO_SIZE								( "36Kb"									),	// Target BRAM: "18Kb" or "36Kb"
//		.FIRST_WORD_FALL_THROUGH 				( "TRUE"									)	// Sets the FIfor FWFT to "TRUE" or "FALSE"
//		)
	hdl_eqw_afifo	#(	//	equal	width	async fifo
		.	LOOP_NUM				(	0				)	,
		.	RAM_STYLE				(	"distributed"	)	,	//	Specify RAM style: auto/block/distributed
		.	ALMOST_EMPTY_OFFSET		(	'h10			)	,
		.	ALMOST_FULL_OFFSET		(	'h10			)	,
		.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,	//	Sets the FIfor FWFT to "TRUE" or "FALSE"
		.	AW						(	5				)	,
		.	DW						(	64				)	
	)
	i_trn_fifo (
		.ALMOSTEMPTY							( 											),	// 1-bit output almost empty
		.ALMOSTFULL								( trn_fifo_afull							),	// 1-bit output almost full
		.DO										( trn_fifo_dout								),	// Output data, width defined by DATA_WIDTH parameter
		.EMPTY									( trn_fifo_empty							),	// 1-bit output empty
		.FULL									( trn_fifo_full								),	// 1-bit output full
		.RDCOUNT								( 											),	// Output read count, width determined by FIfor depth
		.RDERR									( 											),	// 1-bit output read error
		.WRCOUNT								( 											),	// Output write count, width determined by FIfor depth
		.WRERR									( 											),	// 1-bit output write error
		.DI										( trn_fifo_din								),	// Input data, width defined by DATA_WIDTH parameter
		.RDCLK									( clk										),	// 1-bit input read clock
		.RDEN									( trn_fifo_ren								),	// 1-bit input read enable
		.RST									( rst										),	// 1-bit input reset
		.WRCLK									( log_clk									),	// 1-bit input write clock
		.WREN									( trn_fifo_wen								)	// 1-bit input write enable
	);
	
//	generate if(LOOP_NUM==0)	begin
//		ila_w32_d1024 sp_cond_up_i (
//			.	clk		(	log_clk	)	,	// input wire clk
//			.	probe0	(	{
//			
//								trn_fifo_full				,
//								trn_fifo_wen				,
//								trn_fifo_din	[31:0]		,						
//								data_fifo_full				,
//								data_fifo_wen				,
//								data_fifo_din	[31:0]		,
//								S_SR_CM						,
//								rst							,
//								srio_rst					
//							}	
//			)		// input wire [31:0] probe0
//		);
//		
//  		ila_576X1024 sp_cond_up_i (
//  			.	clk		(	clk	)	,	// input wire clk
//  			.	probe0	(	{
//  			
//  								trn_fifo_wen				,
//  								trn_fifo_full				,
//  								data_fifo_wen				,
//  								data_fifo_full				,
//  								sr_iorx_tvalid 				,
//  								sr_iorx_tready				,
//  								sr_iorx_tlast				,
//  								
//  								dma_cnt	[08:0]				,
//  								trn_fifo_empty				,
//  								trn_fifo_ren				,
//  								trn_fifo_dout	[08:0]		,						
//  								data_fifo_empty				,						
//  								data_fifo_ren				,						
//  								data_fifo_dout	[31:0]		,						
//  								dma_s_axis_tready			,
//  								dma_s_axis_tvalid			,
//  								dma_s_axis_tlast			,
//  								S_D_CM						,
//  								rst_dly					,
//  								rst					
//  			
//  							}	
//  			)		// input wire [31:0] probe0
//  		);
 // 	end	endgenerate

endmodule