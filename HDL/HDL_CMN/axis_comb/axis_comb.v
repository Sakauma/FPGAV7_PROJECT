// `timescale	1ns/1ps
module	axis_comb#(
	parameter	CH			=	2		,
	parameter	DW			=	64		
)(
	output	wire	[	CH*	1		-	1	:	0	]	axsr_tready				,
	input	wire	[	CH*	1		-	1	:	0	]	axsr_tvalid				,
	input	wire	[	CH*	1		-	1	:	0	]	axsr_tlast				,
	input	wire	[	CH*	DW		-	1	:	0	]	axsr_tdata				,
	input	wire	[	CH*	64		-	1	:	0	]	axsr_tuser				,
	input	wire	[	CH*	DW/8	-	1	:	0	]	axsr_tkeep				,
	input	wire	[	CH*	DW/8	-	1	:	0	]	axsr_tstrb				,
	input	wire	[	CH*	4		-	1	:	0	]	axsr_tdest				,
	input	wire	[	CH*	4		-	1	:	0	]	axsr_tid				,
	
	input	wire										axst_tready				,
	output	wire										axst_tvalid				,
	output	wire										axst_tlast				,
	output	wire	[	DW		-	1	:	0	]		axst_tdata				,
	output	wire	[	64		-	1	:	0	]		axst_tuser				,
	output	wire	[	DW/8	-	1	:	0	]		axst_tkeep				,
	output	wire	[	DW/8	-	1	:	0	]		axst_tstrb				,
	output	wire	[	4		-	1	:	0	]		axst_tdest				,
	output	wire	[	4		-	1	:	0	]		axst_tid				,
	
	input												rst						,
	input												clk						
);
(* max_fanout=10 *)
reg	[clogb2(CH)-1:0]	ch_num	=	0	;
reg	[CH-1:0]			ch_mrk	=	0	;

	wire	tvalid_ok				=	|	axsr_tvalid	;

	localparam	idle				=	2'b01	;
	localparam	proc				=	2'b10	;
	
(* max_fanout=20 *)	reg	[1:0]	cs	,ns	;
	
	wire		cs_proc	=	cs[clogb2(proc)]	;

	always@(posedge	clk)	begin
		if(rst)	cs	<=	idle;
		else	cs	<=	ns	;
	end
	
	always@(*)	begin
		if(rst)	begin
			ns	=	idle	;
		end	else	begin
			ns	=	cs		;
			case	(cs)
				idle				:	if(	tvalid_ok									)	ns	=	proc		;
				proc				:	if(	axst_tready	&&	axst_tvalid	&&	axst_tlast	)	ns	=	idle 		;
				default				:														ns	=	idle		;
			endcase
		end
	end

	integer k;
	always @ ( posedge clk ) begin
		if ( rst ) begin
			ch_num = 0;
			ch_mrk = 0;
		end	else if ( cs==	idle	&&	tvalid_ok	) begin
			for ( k=CH; k>0; k=k-1 ) begin
				ch_num	=	axsr_tvalid[k-1]	?		(k-1)	: ch_num	;
				ch_mrk	=	axsr_tvalid[k-1]	?	1<<	(k-1)	: ch_mrk	;	
			end
		end
	end
	
	assign	axst_tvalid		=	cs_proc	?	axsr_tvalid	[ch_num*	1		+:	1		]	:	0	;
	assign	axst_tlast		=	cs_proc	?	axsr_tlast	[ch_num*	1		+:	1		]	:	0	;
	assign	axst_tdata		=	cs_proc	?	axsr_tdata	[ch_num*	DW		+:	DW		]	:	0	;
	assign	axst_tuser		=	cs_proc	?	axsr_tuser	[ch_num*	64		+:	64		]	:	0	;
	assign	axst_tkeep		=	cs_proc	?	axsr_tkeep	[ch_num*	DW/8	+:	DW/8	]	:	0	;
	assign	axst_tstrb		=	cs_proc	?	axsr_tstrb	[ch_num*	DW/8	+:	DW/8	]	:	0	;
	assign	axst_tdest		=	cs_proc	?	axsr_tdest	[ch_num*	4		+:	4		]	:	0	;
	assign	axst_tid		=	cs_proc	?	axsr_tid	[ch_num*	4		+:	4		]	:	0	;

	assign	axsr_tready		=	cs_proc	?	axst_tready	<<	ch_num	:	0	;

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
