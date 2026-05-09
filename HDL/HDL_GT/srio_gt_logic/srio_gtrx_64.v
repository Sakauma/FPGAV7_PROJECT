
//	Company				:	Cavige
//	Engineer			:	LJP
//	Create	Date		:	2021�?11�?02�?20:25:08
//	Design	Name		:	
//	Module	Name		:	
//	Project	Name		:	
//	Target	Devices		:	all	Xilinx device
//	Tool	versions	:	all
//	Description			:	
//	Editor				:	Npp,	tab	size	(4)
//	Dependencies		:	
//	Revision			:	1.00
//		Revision	1.00	-	File	Created	by		:	LJP
//		Description		:	32bit PHY �?64bit数据位宽转换
//
//		Revision	1.01	-	File	Modified	by	:	
//		Description		:	
//	
//	Additional	Comments:	
//

module	srio_gtrx_64	#(
	parameter		LINK_WIDTH		=	1		//	SRIO GT LANE WIDTH			
)(
		input	wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_cvt_spd_vlu			,	
		input	wire								gtrx_cvt_spd_vld			,
		output	wire								gtrx_cvt_buf_naf			,

		input	wire								gt_pcs_rst					,
		input	wire								gt_pcs_clk					,
		
		input	wire								gtrx_rdy_64					,
		output	wire								gtrx_vld_64					,
		output	wire	[	64				-1:0]	gtrx_dat_64					,
		output	wire	[	8				-1:0]	gtrx_isk_64					,
		input	wire								itf_rst						,
		input	wire								itf_clk						
	);	
	
		wire						rst			=	itf_rst				;
		wire						clk			=	itf_clk				;
	
		wire								gtrx_fifo_wr				;
		wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_fifo_di				;
		wire								gtrx_fifo_af				;
		wire								gtrx_fifo_fu				;	

		wire								gtrx_fifo_rd				;
		wire	[	72				-1:0]	gtrx_fifo_do				;
		wire								gtrx_fifo_ae				;
		wire								gtrx_fifo_em				;
		
		wire	[	LINK_WIDTH*4*9	-1:0]	gtrx_fifo_dix				;
		wire	[	72				-1:0]	gtrx_fifo_dox				;
		
		assign	gtrx_fifo_dix		=	gtrx_cvt_spd_vlu				;

		assign	gtrx_fifo_wr	=	gtrx_cvt_spd_vld	;
		assign	gtrx_fifo_di	=	LINK_WIDTH	!=	4	?	gtrx_fifo_dix	//	字节序变�?
														:	{	gtrx_fifo_dix[00+:72]	,	gtrx_fifo_dix[72+:72]	}	;

		assign	gtrx_cvt_buf_naf=	~	gtrx_fifo_af	;

		assign	gtrx_vld_64		=	~	gtrx_fifo_em	;

		assign	gtrx_fifo_rd	=	gtrx_vld_64	&&	gtrx_rdy_64	;
	
		assign	gtrx_fifo_dox	=	LINK_WIDTH	!=	1	?	gtrx_fifo_do	//	字节序变�?
														:	{	gtrx_fifo_do[00+:36]	,	gtrx_fifo_do[36+:36]	}	;	
	
genvar	i	;
generate for(i=0;i<8;i=i+1)begin 
	assign	gtrx_isk_64[i*1+:1]	=	gtrx_fifo_dox[i*9+8+:1]		;	//	分离特殊字符和数据字�?
	assign	gtrx_dat_64[i*8+:8]	=	gtrx_fifo_dox[i*9+0+:8]		;	//	分离特殊字符和数据字�?
end
endgenerate

	localparam	FIFO_AW	=	LINK_WIDTH	==	4	?	5	:
							LINK_WIDTH	==	2	?	6	:	7	;

		hdl_exw_afifo	#(	//	extended	width	async fifo
			.	LOOP_NUM				(	0				)	,
			.	RAM_STYLE				(	"distributed"	)	,
			//.	RD_RAM_STYLE			(	"distributed"	)	,
			//.	SYNCHRONIZATION			(	"no"			)	,
			.	ALMOST_EMPTY_OFFSET		(	'h08			)	,
			.	ALMOST_FULL_OFFSET		(	80/LINK_WIDTH	)	,
			.	FIRST_WORD_FALL_THROUGH	(	"TRUE"			)	,
			.	AW						(	FIFO_AW			)	,
		//	.	RD_AW					(	FIFO_AW			)	,
			.	DW						(	LINK_WIDTH*4*9	)	,
			.	QW						(	72				)	
		)axsr_fifo(
			.	RST					(	gt_pcs_rst			)	,	//	input	wire					
			.	WRCLK				(	gt_pcs_clk			)	,	//	input	wire					
			.	WRCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	WRERR				(						)	,	//	output	wire					
			.	WREN_CLEAR			(	1'b0				)	,	//	input	wire					
			.	WREN_LAST			(	1'b0				)	,	//	input	wire					
			.	WREN				(	gtrx_fifo_wr		)	,	//	input	wire					
			.	DI					(	gtrx_fifo_di		)	,	//	input	wire	[DW	-1:0]		
			.	ALMOSTFULL			(	gtrx_fifo_af		)	,	//	output	wire					
			.	FULL				(	gtrx_fifo_fu		)	,	//	output	wire					
			.	RDEN				(	gtrx_fifo_rd		)	,	//	input	wire					
			.	DO					(	gtrx_fifo_do		)	,	//	output	wire	[QW	-1:0]		
			.	ALMOSTEMPTY			(	gtrx_fifo_ae		)	,	//	output	wire					
			.	EMPTY				(	gtrx_fifo_em		)	,	//	output	wire					
			.	RDEN_LAST			(	1'b0				)	,	//	input	wire					
			.	RDCOUNT				(						)	,	//	output	wire	[AW-1:0]		
			.	RDERR				(						)	,	//	output	wire					
			.	RDCLK				(	itf_clk				)		//	input	wire					
		);
	
	
endmodule