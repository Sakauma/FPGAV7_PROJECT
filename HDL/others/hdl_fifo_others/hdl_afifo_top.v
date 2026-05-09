
module	hdl_afifo_top	#(
	parameter	FWFT	=	"TRUE"	,
	parameter	DATA_WD	=	8		
)(
	input	wire					rst,

	input	wire					wclk,
	input	wire					wen,
	input	wire	[DATA_WD-1:0]	wdata,
	output	wire					full,

	input	wire					rclk,
	input	wire					ren,
	output	wire	[DATA_WD-1:0]	rdata,
	output	wire					empty
);

	reg	[DATA_WD-1:0]	mem	[0:3];

	reg	[2:0]	wptr;
	reg	[2:0]	rptr;

	reg	[2:0]	rptr_in_wclk_pre;
	reg	[2:0]	rptr_in_wclk;

	reg	[2:0]	wptr_in_rclk_pre;
	reg	[2:0]	wptr_in_rclk;

	always	@	(	posedge	wclk	)	begin
	//	always	@	(	negedge	wclk	)	begin
		if	(	rst	)	begin
			wptr	<=	0;
			rptr_in_wclk_pre	<=	0;
			rptr_in_wclk		<=	0;
			mem[0]	<=	0;
			mem[1]	<=	0;
			mem[2]	<=	0;
			mem[3]	<=	0;
		end
		else	begin
			if	(	wen	)	begin
				mem[wptr[1:0]]	<=	wdata;
				wptr	<=	wptr	+	1'b1;
			end

			rptr_in_wclk_pre	<=	normal_to_green(rptr);
			rptr_in_wclk		<=	rptr_in_wclk_pre;
		end
	end

	wire	[2:0]	rptr_in_wclk_normal	=	green_to_normal(rptr_in_wclk);

	//	assign	full	=	~(	(rptr_in_wclk_normal[2]!=wptr[2])	&&	(rptr_in_wclk_normal[1:0]==wptr[1:0])	);
	assign	full	=	(rptr_in_wclk_normal[2]!=wptr[2])	&&	(rptr_in_wclk_normal[1:0]==wptr[1:0])	;

	always	@	(	posedge	rclk	)	begin//rst	)	begin
		if	(	rst	)	begin
			rptr	<=	0;
			wptr_in_rclk_pre	<=	0;
			wptr_in_rclk		<=	0;
		end
		else	begin
			if	(	ren	)	rptr	<=	rptr	+	1'b1;

			wptr_in_rclk_pre	<=	normal_to_green(wptr);
			wptr_in_rclk		<=	wptr_in_rclk_pre;
		end
	end

	generate
		if( FWFT=="TRUE" ) begin : FWFT_DOUT
			assign	rdata	=	mem[rptr[1:0]];
		end	else  begin : REG_DOUT
			reg	[DATA_WD-1:0]	rdata_r	=	0	;
			always	rdata_r	<=	ren	?	mem[rptr[1:0]]	:	rdata_r	;
			assign	rdata	=	rdata_r	;
		end
	endgenerate



	assign	empty	=	rptr	==	green_to_normal(wptr_in_rclk);


	function	[2:0]	normal_to_green;
	input	[2:0]	normal;
	begin
		case	(	normal	)
		3'b000:	normal_to_green	=	3'b000;
		3'b001:	normal_to_green	=	3'b001;
		3'b010:	normal_to_green	=	3'b011;
		3'b011:	normal_to_green	=	3'b010;
		3'b100:	normal_to_green	=	3'b110;
		3'b101:	normal_to_green	=	3'b111;
		3'b110:	normal_to_green	=	3'b101;
		3'b111:	normal_to_green	=	3'b100;
		endcase
	end
	endfunction

	function	[2:0]	green_to_normal;
	input	[2:0]	green;
	begin
		case	(	green	)
		3'b000:	green_to_normal	=	3'b000;
		3'b001:	green_to_normal	=	3'b001;
		3'b011:	green_to_normal	=	3'b010;
		3'b010:	green_to_normal	=	3'b011;
		3'b110:	green_to_normal	=	3'b100;
		3'b111:	green_to_normal	=	3'b101;
		3'b101:	green_to_normal	=	3'b110;
		3'b100:	green_to_normal	=	3'b111;
		endcase
	end
	endfunction


endmodule

