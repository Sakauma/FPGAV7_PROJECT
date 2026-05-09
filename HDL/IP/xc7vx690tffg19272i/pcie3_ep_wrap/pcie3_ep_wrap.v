//-----------------------------------------------------------------------------
//
//	(c																										)	Copyright	2012-2012	Xilinx,	Inc.	All	rights	reserved.
//
//	This	file	contains	confidential	and	proprietary	information
//	of	Xilinx,	Inc.	and	is	protected	under	U.S.	and
//	international	copyright	and	other	intellectual	property
//	laws.
//
//	DISCLAIMER
//	This	disclaimer	is	not	a	license	and	does	not	grant	any
//	rights	to	the	materials	distributed	herewith.	Except	as
//	otherwise	provided	in	a	valid	license	issued	to	you	by
//	Xilinx,	and	to	the	maximum	extent	permitted	by	applicable
//	law:	(1																										)	THESE	MATERIALS	ARE	MADE	AVAILABLE	"AS	IS"	AND
//	WITH	ALL	FAULTS,	AND	XILINX	HEREBY	DISCLAIMS	ALL	WARRANTIES
//	AND	CONDITIONS,	EXPRESS,	IMPLIED,	OR	STATUTORY,	INCLUDING
//	BUT	NOT	LIMITED	TO	WARRANTIES	OF	MERCHANTABILITY,	NON-
//	INFRINGEMENT,	OR	FITNESS	FOR	ANY	PARTICULAR	PURPOSE;	and
//	(2																										)	Xilinx	shall	not	be	liable	(whether	in	contract	or	tort,
//	including	negligence,	or	under	any	other	theory	of
//	liability																										)	for	any	loss	or	damage	of	any	kind	or	nature
//	related	to,	arising	under	or	in	connection	with	these
//	materials,	including	for	any	direct,	or	any	indirect,
//	special,	incidental,	or	consequential	loss	or	damage
//	(including	loss	of	data,	profits,	goodwill,	or	any	type	of
//	loss	or	damage	suffered	as	a	result	of	any	action	brought
//	by	a	third	party																										)	even	if	such	damage	or	loss	was
//	reasonably	foreseeable	or	Xilinx	had	been	advised	of	the
//	possibility	of	the	same.
//
//	CRITICAL	APPLICATIONS
//	Xilinx	products	are	not	designed	or	intended	to	be	fail-
//	safe,	or	for	use	in	any	application	requiring	fail-safe
//	performance,	such	as	life-support	or	safety	devices	or
//	systems,	Class	III	medical	devices,	nuclear	facilities,
//	applications	related	to	the	deployment	of	airbags,	or	any
//	other	applications	that	could	lead	to	death,	personal
//	injury,	or	severe	property	or	environmental	damage
//	(individually	and	collectively,	"Critical
//	Applications"																										).	Customer	assumes	the	sole	risk	and
//	liability	of	any	use	of	Xilinx	products	in	Critical
//	Applications,	subject	only	to	applicable	laws	and
//	regulations	governing	limitations	on	product	liability.
//
//	THIS	COPYRIGHT	NOTICE	AND	DISCLAIMER	MUST	BE	RETAINED	AS
//	PART	OF	THIS	FILE	AT	ALL	TIMES.
//
//-----------------------------------------------------------------------------
//
//	Project	:	Ultrascale	FPGA	Gen3	Integrated	Block	for	PCI	Express
//	File		:	xilinx_pcie_uscale_ep.v
//	Version	:	4.4	
//-----------------------------------------------------------------------------
//--
//--	Description:	PCI	Express	Endpoint	example	FPGA	design
//--
//------------------------------------------------------------------------------

`timescale	1ps	/	1ps

	`define PCI_EXP_EP_OUI                           24'h000A35
	`define PCI_EXP_EP_DSN_1                         {{8'h1},`PCI_EXP_EP_OUI}
	`define PCI_EXP_EP_DSN_2                         32'h00000001
//	`define SIM_MODE                       									

(*	DowngradeIPIdentifiedWarnings	=	"yes"	*)
module	pcie3_ep_wrap	#	(
	parameter	C_DATA_WIDTH					=	256						,//	RX/TX	interface	data	width
	parameter	KEEP_WIDTH						=	C_DATA_WIDTH	/	32	,	
	parameter	EXT_PIPE_SIM					=	"FALSE"					,//	This	Parameter	has	effect	on	selecting	Enable	External	PIPE	Interface	in	GUI.
	parameter	PL_LINK_CAP_MAX_LINK_SPEED		=	4						,//	1-	GEN1,	2	-	GEN2,	4	-	GEN3
	parameter	PL_LINK_CAP_MAX_LINK_WIDTH		=	8						//	1-	X1,	2	-	X2,	4	-	X4,	8	-	X8
)	(
	output	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1	)	:	0]	pci_exp_txp		,
	output	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1	)	:	0]	pci_exp_txn		,
	input	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1	)	:	0]	pci_exp_rxp		,
	input	[(PL_LINK_CAP_MAX_LINK_WIDTH	-	1	)	:	0]	pci_exp_rxn		,

	input	wire									s_axis_rq_tlast			,
	input	wire		[C_DATA_WIDTH-1:0]			s_axis_rq_tdata			,
	input	wire					[59:0]			s_axis_rq_tuser			,
	input	wire		[KEEP_WIDTH-1:0]			s_axis_rq_tkeep			,
	output	wire									s_axis_rq_tready		,
	input	wire									s_axis_rq_tvalid		,
	
	output	wire		[C_DATA_WIDTH-1:0]			m_axis_rc_tdata			,
	output	wire					[74:0]			m_axis_rc_tuser			,
	output	wire									m_axis_rc_tlast			,
	output	wire		[KEEP_WIDTH-1:0]			m_axis_rc_tkeep			,
	output	wire									m_axis_rc_tvalid		,
	input	wire									m_axis_rc_tready		,
	
	output	wire		[C_DATA_WIDTH-1:0]			m_axis_cq_tdata			,
	output	wire					[84:0]			m_axis_cq_tuser			,
	output	wire									m_axis_cq_tlast			,
	output	wire		[KEEP_WIDTH-1:0]			m_axis_cq_tkeep			,
	output	wire									m_axis_cq_tvalid		,
	input	wire									m_axis_cq_tready		,
	
	input	wire		[C_DATA_WIDTH-1:0]			s_axis_cc_tdata			,
	input	wire					[32:0]			s_axis_cc_tuser			,
	input	wire									s_axis_cc_tlast			,
	input	wire		[KEEP_WIDTH-1:0]			s_axis_cc_tkeep			,
	input	wire									s_axis_cc_tvalid		,
	output	wire									s_axis_cc_tready		,

	output					[3:0]					cfg_interrupt_msi_enable	,
	output					[11:0]					cfg_interrupt_msi_mmenable	,
	input					[31:0]					cfg_interrupt_msi_int		,
	output											cfg_interrupt_msi_sent		,
	output											cfg_interrupt_msi_fail		,

	//----------------------------------------------------------------------------------------------------------------//
//	Configuration	(CFG)	Interface								//
	//----------------------------------------------------------------------------------------------------------------//

	
	output	wire					[1:0]			pcie_tfc_nph_av			,	//	initial	h3	when	user_lnk_up	
	output	wire					[1:0]			pcie_tfc_npd_av			,	//	initial	h3	when	user_lnk_up	
	output	wire					[3:0]			pcie_rq_seq_num			,	//	initial	h0	when	user_lnk_up	
	output	wire									pcie_rq_seq_num_vld		,	//	initial	h0	when	user_lnk_up	
	output	wire					[5:0]			pcie_rq_tag				,	//	initial	h0	when	user_lnk_up	
	output	wire									pcie_rq_tag_vld			,	//	initial	h0	when	user_lnk_up	
	output	wire					[1:0]			pcie_rq_tag_av			,	//	initial	h3	when	power on
	input	wire									pcie_cq_np_req			,
	output	wire					[5:0]			pcie_cq_np_req_count	,	//	initial	h20	when	user_lnk_up	

	output	wire					[2:0]			cfg_max_payload			,	//	0->0->0->0->2
	output	wire					[2:0]			cfg_max_read_req		,	//	0->2->2->2

	output	wire					[2:0]			cfg_current_speed		,	//	0->1->1->4
	output	wire					[3:0]			cfg_negotiated_width	,	//	0->8->8->8
	output	wire									cfg_phy_link_down		,	//	L->H->L->L
	output	wire					[1:0]			cfg_phy_link_status		,	//	0->1->2->3
	 
	

	output	wire									cfg_err_cor_out			,
	output	wire									cfg_err_nonfatal_out	,
	output	wire									cfg_err_fatal_out		,
	output	wire									cfg_local_error			,
	input	wire									c_os_config				,
	input	wire									c_os_big_endian			,
	output	wire									mmcm_lock				,
	output	wire									user_lnk_up				,
	output	wire									phy_rdy_out				,
	output	wire									clk_50M					,
	output	wire									user_clk				,
	output	wire									user_reset				,

	input											sys_clk_p				,
	input											sys_clk_n				,
	input											vio_rst					,
	output											sys_rst_n_c				,
	input											sys_rst_n

);

//	Local	Parameters	derived	from	user	selection
	localparam		TCQ	=	1;

	wire								[3:0]	cfg_flr_in_process;
	wire								[1:0]	cfg_flr_done;
	wire								[7:0]	cfg_vf_flr_in_process;
	wire								[5:0]	cfg_vf_flr_done;

	//----------------------------------------------------------------------------------------------------------------//
//	System(SYS)	Interface																						//
	//----------------------------------------------------------------------------------------------------------------//

	wire										sys_clk;
	wire										sys_clk_gt;
	wire										sys_rst_n_c;

	//-----------------------------------------------------------------------------------------------------------------------

/////////////////////////	pcie device reset	logic	begin	/////////////////////////////////////
//	reg									user_lnk_up_q	=	0	;
//	always@(posedge	user_clk)	user_lnk_up_q	<=	user_lnk_up		;
//	reg											user_lnk_fe		=	0	;
//	always@(posedge	user_clk)	user_lnk_fe		<=	user_lnk_up_q	&&	!user_lnk_up		;
//	
//	reg									[23:0]	pcie_link_fall_cnt	=	0	;	//	250MHz	,	â‰?	4ms
//	always@(posedge	user_clk)	pcie_link_fall_cnt	<=	user_lnk_fe	?	0	:	pcie_link_fall_cnt	+	!pcie_link_fall_cnt[23]	;
//	
//	reg											pcie_link_fall_flag	=	0	;
//	always@(posedge	user_clk)	pcie_link_fall_flag	<=	user_lnk_fe	?	1	:	pcie_link_fall_flag	;
//	
//	
//	reg									[22:0]	pcie_power_on_cnt	=	0	;	//	250MHz	,	â‰?	4ms
//	always@(posedge	user_clk)	pcie_power_on_cnt	<=	pcie_power_on_cnt	+	!pcie_power_on_cnt[22]	;
//	
//	reg	pcie_rst_cnt_rst_n_pre	=	0	;	always@(posedge	user_clk)	pcie_rst_cnt_rst_n_pre	<=	pcie_link_fall_flag	?	pcie_link_fall_cnt[23]	:	pcie_power_on_cnt[22]	;
//	reg	pcie_rst_cnt_rst_pre	=	1	;	always@(posedge	user_clk)	pcie_rst_cnt_rst_pre	<=	pcie_link_fall_flag	?	!pcie_link_fall_cnt[23]	:	!pcie_power_on_cnt[22]	;
//	
//	
//	(* max_fanout=200 *)		reg		pcie_rst_cnt_rst_n	=	0	;
//	always@(posedge	user_clk)	pcie_rst_cnt_rst_n	<=	pcie_rst_cnt_rst_n_pre	;
//	
//	(* max_fanout=200 *)		reg		pcie_rst_cnt_rst	=	1	;
//	always@(posedge	user_clk)	pcie_rst_cnt_rst	<=	pcie_rst_cnt_rst_pre	;
	
/////////////////////////	pcie device reset	logic	begin	/////////////////////////////////////
	reg									user_lnk_up_q	=	0	;
	always@(posedge	user_clk)	user_lnk_up_q	<=	user_lnk_up		;
	reg											user_lnk_fe		=	0	;
	always@(posedge	user_clk)	user_lnk_fe		<=	user_lnk_up_q	&&	!user_lnk_up		;
	
	reg									[22:0]	pcie_link_fall_cnt	=	0	;	//	250MHz	,	â‰?	4ms
	always@(posedge	user_clk)	pcie_link_fall_cnt	<=	user_lnk_fe	?	0	:	pcie_link_fall_cnt	+	!pcie_link_fall_cnt[22]	;
	
	reg	pcie_rst_cnt_rst_n_pre	=	0	;	always@(posedge	user_clk)	pcie_rst_cnt_rst_n_pre	<=		pcie_link_fall_cnt[22]	;
	reg	pcie_rst_cnt_rst_pre	=	1	;	always@(posedge	user_clk)	pcie_rst_cnt_rst_pre	<=	!	pcie_link_fall_cnt[22]	;
	
	(* max_fanout=200 *)		reg		pcie_rst_cnt_rst_n	=	0	;
	always@(posedge	user_clk)	pcie_rst_cnt_rst_n	<=	pcie_rst_cnt_rst_n_pre	;
	
	(* max_fanout=200 *)		reg		pcie_rst_cnt_rst	=	1	;
	always@(posedge	user_clk)	pcie_rst_cnt_rst	<=	pcie_rst_cnt_rst_pre	;
	
/////////////////////////	pcie device reset	logic	end	/////////////////////////////////////	
	
	
/////////////////////////	pcie device reset	logic	end	/////////////////////////////////////
	
//	IBUF	sys_reset_n_ibuf	(.O(sys_rst_n_c)	,	.I(sys_rst_n)	);
//	assign	sys_rst_n_c	=	sys_rst_n	;
	assign	sys_rst_n_c	=	pcie_rst_cnt_rst_n	;
	
//	IBUFDS_GTE3	#	(.REFCLK_HROW_CK_SEL(2'b00))	refclk_ibuf	(.O(sys_clk_gt)	,	.ODIV2(sys_clk)	,	.I(sys_clk_p)	,	.CEB(1'b0)	,	.IB(sys_clk_n));
	IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(clk_50M), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));


//	wire	[15:0]	cfg_vend_id			=	16'h289e;	
//	wire	[15:0]	cfg_dev_id			=	16'h7024;	
//	wire	[15:0]	cfg_subsys_id		=	16'h0007;								
//	wire	[7:0]	cfg_rev_id			=	8'h00;	
	wire	[15:0]	cfg_subsys_vend_id	=	16'h10EE;									
	assign			pcie_rq_tag_av		=	2'b11	;

	//------------------------------------------------------------------------------------------------------------------//					
	//		PIO	Example	Design	Top	Level																			//							
	//------------------------------------------------------------------------------------------------------------------//					
	pcie3_other_itf	pcie3_other_itf_i	(																									
		.	cfg_flr_in_process								(	cfg_flr_in_process		[1:0]												)	,	//	input                            [1:0] 
		.	cfg_flr_done									(	cfg_flr_done																)	,	//	output wire                      [1:0] 
		.	cfg_vf_flr_in_process							(	cfg_vf_flr_in_process	[5:0]												)	,	//	input                            [5:0] 
		.	cfg_vf_flr_done									(	cfg_vf_flr_done																)	,	//	output wire                      [5:0] 
		.	user_reset										(	user_reset																	)	,	//	
		.	user_clk										(	user_clk																	)	
	);



`ifdef SIM_MODE
	
	localparam	LINK_WIDTH	=	"x8"	;

	assign	pci_exp_txn	=	pci_exp_rxn	;
	assign	pci_exp_txp	=	pci_exp_rxp	;

	reg	[5-1:0]	gen_ip_clk_cnt	=	0	;
	reg	ipc_clk_reg	=	0	;	

	generate	if(	LINK_WIDTH	==	"x1"	)	begin
					always@(posedge	sys_clk_p)	gen_ip_clk_cnt	<=	gen_ip_clk_cnt==4/2-1	?	0	:	gen_ip_clk_cnt	+	1	;
					always@(posedge	sys_clk_p)	ipc_clk_reg		<=	gen_ip_clk_cnt==4/2-1	?	~	ipc_clk_reg	:	ipc_clk_reg	;
					assign	user_clk	=	ipc_clk_reg	;
				end	else	if(	LINK_WIDTH	==	"x2"	)	begin
					always@(posedge	sys_clk_p)	gen_ip_clk_cnt	<=	gen_ip_clk_cnt==4/4-1	?	0	:	gen_ip_clk_cnt	+	1	;
					always@(posedge	sys_clk_p)	ipc_clk_reg		<=	gen_ip_clk_cnt==4/4-1	?	~	ipc_clk_reg	:	ipc_clk_reg	;
					assign	user_clk	=	ipc_clk_reg	;
				end	else	if(	LINK_WIDTH	==	"x4"	)	begin
					assign	user_clk	=	sys_clk_p		;
				end	else	if(	LINK_WIDTH	==	"x8"	)	begin
					assign	user_clk	=	sys_clk_p		;
				end				
	endgenerate

	(* max_fanout=50 *)	reg	[3:0]	user_reset_reg	=	4'hf	;	always@(posedge	user_clk	)	user_reset_reg	<=	{	user_reset_reg[2:0]	,	~	sys_rst_n_c	}	;
	assign	user_reset	=	user_reset_reg[3]	;

	reg	[7:0]	user_reset_dly	=	8'hff	;
	always@(posedge	user_clk)	user_reset_dly	<=	{	user_reset_dly[6:0]	,	user_reset	}	;

	assign	user_lnk_up		=	~	user_reset_dly[7]	;
	assign	phy_rdy_out		=	~	user_reset_dly[3]	;

	assign	pcie_cq_np_req_count		=	user_lnk_up	?	32	:	0	;
	assign	cfg_max_payload				=	0							;	//	user_lnk_up	?	2	:	0	;
	assign	cfg_max_read_req			=	2							;	//	user_lnk_up	?	2	:	0	;
	assign	cfg_current_speed			=	user_lnk_up	?	4	:	0	;
	assign	cfg_negotiated_width		=	user_lnk_up	?	8	:	0	;
	assign	cfg_phy_link_down			=	user_lnk_up	?	0	:	0	;
	assign	cfg_phy_link_status			=	user_lnk_up	?	3	:	0	;
	
	assign	cfg_err_cor_out				=	0		;
	assign	cfg_err_nonfatal_out		=	0		;
	assign	cfg_err_fatal_out			=	0		;
	assign	cfg_local_error				=	0		;
	

	wire		[	04	-1:0]						iprq_first_be				;
	wire		[	04	-1:0]						iprq_last_be				;
	wire		[	03	-1:0]						iprq_addr_off				;
	wire		[	01	-1:0]						iprq_discontinue			;
	wire		[	01	-1:0]						iprq_tph_present			;
	wire		[	02	-1:0]						iprq_tph_type				;
	wire		[	01	-1:0]						iprq_tph_indirect_tag_en	;
	wire		[	08	-1:0]						iprq_tph_st_tag				;
	wire		[	04	-1:0]						iprq_seq_num				;
	wire		[	32	-1:0]						iprq_parity					;
	wire		[	01	-1:0]						iprq_Force_ECRC				;
	wire		[	03	-1:0]						iprq_attr		    		;
	wire		[	03	-1:0]						iprq_TC		  				;
	wire		[	01	-1:0]						iprq_reqid_en	    		;
	wire		[	16	-1:0]						iprq_Cmper_id	    		;
	wire		[	08	-1:0]						iprq_Tag		    		;
	wire		[	08	-1:0]						iprq_BUS_num	    		;
	wire		[	08	-1:0]						iprq_FD_num	   				;
	wire		[	01	-1:0]						iprq_EP		   				;
	wire		[	04	-1:0]						iprq_req_type	    		;
	wire		[	11	-1:0]						iprq_dw_cnt	    			;
	wire		[	62	-1:0]						iprq_addr		    		;
	wire		[	02	-1:0]						iprq_AT		    			;

	wire											iprq_data_vld				;
	wire											iprq_data_end				;
	wire											iprq_head_vld				;
	wire		[C_DATA_WIDTH-1:0]					iprq_data_out				;

	pcie_ipcq_simulator	#(
		.	CQH_DW		(	4*32			)	,
		.	DW			(	C_DATA_WIDTH	)	
	)pcie_ipcq_simulator(
		.	user_lnk_up				(	user_lnk_up				)	,	//	input												
		.	phy_rdy_out				(	phy_rdy_out				)	,	//	input												
		.	c_os_config				(	c_os_config				)	,	//	input												
		.	c_os_big_endian			(	c_os_big_endian			)	,	//	input												
		.	m_axis_cq_tvalid		(	m_axis_cq_tvalid		)	,	//	output	wire										
		.	m_axis_cq_tready		(	m_axis_cq_tready		)	,	//	input	wire										
		.	m_axis_cq_tlast			(	m_axis_cq_tlast			)	,	//	output	wire										
		.	m_axis_cq_tdata			(	m_axis_cq_tdata			)	,	//	output	wire	[	DW			-	1	:	0	]	
		.	m_axis_cq_tkeep			(	m_axis_cq_tkeep			)	,	//	output	wire	[	DW	/	32	-	1	:	0	]	
		.	m_axis_cq_tuser			(	m_axis_cq_tuser			)	,	//	output	wire	[	85			-	1	:	0	]	
		.	pcie_cq_np_req_count	(	pcie_cq_np_req_count	)	,	//	input	wire	[	6			-	1	:	0	]	
		.	pcie_cq_np_req			(	pcie_cq_np_req			)	,	//	input	wire										
		.	rst						(	user_reset				)	,	//	input												
		.	clk						(	user_clk				)		//	input												

	);

	pcie_ipcc_simulator	#(		
		.	CCH_DW		(	3*32			)	,
		.	DW			(	C_DATA_WIDTH	)	
	)pcie_ipcc_simulator(
		.	user_lnk_up				(	user_lnk_up				)	,	//	input	wire										
		.	phy_rdy_out				(	phy_rdy_out				)	,	//	input	wire										
		.	s_axis_cc_tvalid		(	s_axis_cc_tvalid		)	,	//	input	wire										
		.	s_axis_cc_tready		(	s_axis_cc_tready		)	,	//	output	wire										
		.	s_axis_cc_tdata			(	s_axis_cc_tdata			)	,	//	input	wire	[	DW			-	1	:	0	]	
		.	s_axis_cc_tkeep			(	s_axis_cc_tkeep			)	,	//	input	wire	[	DW	/	32	-	1	:	0	]	
		.	s_axis_cc_tlast			(	s_axis_cc_tlast			)	,	//	input	wire										
		.	s_axis_cc_tuser			(	s_axis_cc_tuser			)	,	//	input	wire	[	33			-	1	:	0	]	
		.	rst						(	user_reset				)	,	//	input												
		.	clk						(	user_clk				)		//	input												
	);

	pcie_iprq_simulator	#(
		.	RQH_DW		(	4*32			)	,
		.	DW			(	C_DATA_WIDTH	)	
	)pcie_iprq_simulator(
		.	user_lnk_up					(	user_lnk_up					)	,	//	input	wire										
		.	phy_rdy_out					(	phy_rdy_out					)	,	//	input	wire										
		.	s_axis_rq_tvalid			(	s_axis_rq_tvalid			)	,	//	input	wire										
		.	s_axis_rq_tready			(	s_axis_rq_tready			)	,	//	output	wire										
		.	s_axis_rq_tdata				(	s_axis_rq_tdata				)	,	//	input	wire	[	DW			-	1	:	0	]	
		.	s_axis_rq_tkeep				(	s_axis_rq_tkeep				)	,	//	input	wire	[	DW	/	32	-	1	:	0	]	
		.	s_axis_rq_tlast				(	s_axis_rq_tlast				)	,	//	input	wire										
		.	s_axis_rq_tuser				(	s_axis_rq_tuser				)	,	//	input	wire	[	60			-	1	:	0	]	
		.	pcie_rq_tag					(	pcie_rq_tag					)	,	//	output	wire	[	6			-	1	:	0	]  	
		.	pcie_rq_tag_vld				(	pcie_rq_tag_vld				)	,	//	output	wire										
		.	pcie_rq_tag_av				(	pcie_rq_tag_av				)	,	//	output	wire	[	2			-	1	:	0	]  	
		.	pcie_tfc_nph_av				(	pcie_tfc_nph_av				)	,	//	output	wire	[	2			-	1	:	0	]  	
		.	pcie_tfc_npd_av				(	pcie_tfc_npd_av				)	,	//	output	wire	[	2			-	1	:	0	]  	
		.	pcie_rq_seq_num				(	pcie_rq_seq_num				)	,	//	output	wire	[	4			-	1	:	0	]  	
		.	pcie_rq_seq_num_vld			(	pcie_rq_seq_num_vld			)	,	//	output												
		.	iprq_first_be				(	iprq_first_be				)	,	//	output	reg		[	04	-1:0]				
		.	iprq_last_be				(	iprq_last_be				)	,	//	output	reg		[	04	-1:0]				
		.	iprq_addr_off				(	iprq_addr_off				)	,	//	output	reg		[	03	-1:0]				
		.	iprq_discontinue			(	iprq_discontinue			)	,	//	output	reg		[	01	-1:0]				
		.	iprq_tph_present			(	iprq_tph_present			)	,	//	output	reg		[	01	-1:0]				
		.	iprq_tph_type				(	iprq_tph_type				)	,	//	output	reg		[	02	-1:0]				
		.	iprq_tph_indirect_tag_en	(	iprq_tph_indirect_tag_en	)	,	//	output	reg		[	01	-1:0]				
		.	iprq_tph_st_tag				(	iprq_tph_st_tag				)	,	//	output	reg		[	08	-1:0]				
		.	iprq_seq_num				(	iprq_seq_num				)	,	//	output	reg		[	04	-1:0]				
		.	iprq_parity					(	iprq_parity					)	,	//	output	reg		[	32	-1:0]				
		.	iprq_Force_ECRC				(	iprq_Force_ECRC				)	,	//	output	reg		[	01	-1:0]			
		.	iprq_attr		    		(	iprq_attr		    		)	,	//	output	reg		[	03	-1:0]			
		.	iprq_TC		  				(	iprq_TC		  				)	,	//	output	reg		[	03	-1:0]			
		.	iprq_reqid_en	    		(	iprq_reqid_en	    		)	,	//	output	reg		[	01	-1:0]			
		.	iprq_Cmper_id	    		(	iprq_Cmper_id	    		)	,	//	output	reg		[	16	-1:0]			
		.	iprq_Tag		    		(	iprq_Tag		    		)	,	//	output	reg		[	08	-1:0]			
		.	iprq_BUS_num	    		(	iprq_BUS_num	    		)	,	//	output	reg		[	08	-1:0]			
		.	iprq_FD_num	   				(	iprq_FD_num	   				)	,	//	output	reg		[	08	-1:0]			
		.	iprq_EP		   				(	iprq_EP		   				)	,	//	output	reg		[	01	-1:0]			
		.	iprq_req_type	    		(	iprq_req_type	    		)	,	//	output	reg		[	04	-1:0]			
		.	iprq_dw_cnt	    			(	iprq_dw_cnt	    			)	,	//	output	reg		[	11	-1:0]			
		.	iprq_addr		    		(	iprq_addr		    		)	,	//	output	reg		[	62	-1:0]			
		.	iprq_AT		    			(	iprq_AT		    			)	,	//	output	reg		[	02	-1:0]			
		.	iprq_data_vld				(	iprq_data_vld				)	,	//	output	reg											
		.	iprq_data_end				(	iprq_data_end				)	,	//	output	reg											
		.	iprq_head_vld				(	iprq_head_vld				)	,	//	output	reg											
		.	iprq_data_out				(	iprq_data_out				)	,	//	output	reg		[DW-1:0]							
		.	rst							(	user_reset					)	,	//	output												
		.	clk							(	user_clk					)		//	output												
	);
	
	pcie_iprc_simulator	#(
		.	RCH_DW	(	3*32	)	,
		.	DW		(	256		)	
	)pcie_iprc_simulator(																						
		.	user_lnk_up				(	user_lnk_up				)	,	//	input	wire										
		.	phy_rdy_out				(	phy_rdy_out				)	,	//	input	wire										
		.	m_axis_rc_tready		(	m_axis_rc_tready		)	,	//	input	wire										
		.	m_axis_rc_tvalid		(	m_axis_rc_tvalid		)	,	//	output	wire										
		.	m_axis_rc_tlast			(	m_axis_rc_tlast			)	,	//	output	wire										
		.	m_axis_rc_tdata			(	m_axis_rc_tdata			)	,	//	output	wire	[	DW			-	1	:	0	]	
		.	m_axis_rc_tkeep			(	m_axis_rc_tkeep			)	,	//	output	wire	[	DW	/	32	-	1	:	0	]	
		.	m_axis_rc_tuser			(	m_axis_rc_tuser			)	,	//	output	wire	[	75			-	1	:	0	]	
		
		.	cfg_max_payload			(	cfg_max_payload			)	,	//	input	wire	[	03	-1:0]					
		.	cfg_max_read_req		(	cfg_max_read_req		)	,	//	input	wire	[	03	-1:0]					
		
		.	iprq_first_be			(	iprq_first_be			)	,	//	input	wire	[	04	-1:0]		
		.	iprq_last_be			(	iprq_last_be			)	,	//	input	wire	[	04	-1:0]		
		.	iprq_addr_off			(	iprq_addr_off			)	,	//	input	wire	[	03	-1:0]		
		.	iprq_discontinue		(	iprq_discontinue		)	,	//	input	wire	[	01	-1:0]		
		.	iprq_tph_present		(	iprq_tph_present		)	,	//	input	wire	[	01	-1:0]		
		.	iprq_tph_type			(	iprq_tph_type			)	,	//	input	wire	[	02	-1:0]		
		.	iprq_tph_indirect_tag_en(	iprq_tph_indirect_tag_en)	,	//	input	wire	[	01	-1:0]		
		.	iprq_tph_st_tag			(	iprq_tph_st_tag			)	,	//	input	wire	[	08	-1:0]		
		.	iprq_seq_num			(	iprq_seq_num			)	,	//	input	wire	[	04	-1:0]		
		.	iprq_parity				(	iprq_parity				)	,	//	input	wire	[	32	-1:0]		
		.	iprq_Force_ECRC			(	iprq_Force_ECRC			)	,	//	input	wire	[	01	-1:0]		
		.	iprq_attr		    	(	iprq_attr		    	)	,	//	input	wire	[	03	-1:0]		
		.	iprq_TC		  			(	iprq_TC		  			)	,	//	input	wire	[	03	-1:0]		
		.	iprq_reqid_en	    	(	iprq_reqid_en	    	)	,	//	input	wire	[	01	-1:0]		
		.	iprq_Cmper_id	    	(	iprq_Cmper_id	    	)	,	//	input	wire	[	16	-1:0]		
		.	iprq_Tag		    	(	iprq_Tag		    	)	,	//	input	wire	[	08	-1:0]		
		.	iprq_BUS_num	    	(	iprq_BUS_num	    	)	,	//	input	wire	[	08	-1:0]		
		.	iprq_FD_num	   			(	iprq_FD_num	   			)	,	//	input	wire	[	08	-1:0]		
		.	iprq_EP		   			(	iprq_EP		   			)	,	//	input	wire	[	01	-1:0]		
		.	iprq_req_type	    	(	iprq_req_type	    	)	,	//	input	wire	[	04	-1:0]		
		.	iprq_dw_cnt	    		(	iprq_dw_cnt	    		)	,	//	input	wire	[	11	-1:0]		
		.	iprq_addr		    	(	iprq_addr		    	)	,	//	input	wire	[	62	-1:0]		
		.	iprq_AT		    		(	iprq_AT		    		)	,	//	input	wire	[	02	-1:0]		
		.	iprq_data_vld			(	iprq_data_vld			)	,	//	input	wire							
		.	iprq_data_end			(	iprq_data_end			)	,	//	input	wire							
		.	iprq_head_vld			(	iprq_head_vld			)	,	//	input	wire							
		.	iprq_data_out			(	iprq_data_out			)	,	//	input	wire							
		.	rst						(	user_reset				)	,	//	input												
		.	clk						(	user_clk				)		//	input												
	);
	
	cfg_interrupt_simulator	cfg_interrupt_simulator(
		.	cfg_interrupt_msi_enable	(	cfg_interrupt_msi_enable	)	,	//	output					[3:0]		
		.	cfg_interrupt_msi_mmenable	(	cfg_interrupt_msi_mmenable	)	,	//	output					[11:0]		
		.	cfg_interrupt_msi_int		(	cfg_interrupt_msi_int		)	,	//	input					[31:0]		
		.	cfg_interrupt_msi_sent		(	cfg_interrupt_msi_sent		)	,	//	output								
		.	cfg_interrupt_msi_fail		(	cfg_interrupt_msi_fail		)	,	//	output								
		.	user_reset					(	user_reset					)	,	//	input                       		
		.	user_clk					(	user_clk					)		//	input                       		
	);
	
`else	
	
	wire								[3:0]	s_axis_rq_tready_4b	;	assign	s_axis_rq_tready	=	s_axis_rq_tready_4b[0]	;
	wire								[3:0]	s_axis_cc_tready_4b	;	assign	s_axis_cc_tready	=	s_axis_cc_tready_4b[0]	;

	wire	user_reset_ip	;	
	(* max_fanout=100 *)	reg		[3:0]	user_reset_dup	=	4'hf	;
	always@(posedge	user_clk)	user_reset_dup	<=	{	user_reset_dup[2:0]	,	user_reset_ip	}	;
	assign	user_reset	=	user_reset_dup[3]	;
//	BUFG	user_reset_bufg_inst	(	.O(user_reset),	.I(user_reset_ip)	);

//	Core	Top	Level	Wrapper
	pcie3_8x8g_0	pcie3_8x8g_0_i	(

	//---------------------------------------------------------------------------------------//
//	PCI	Express	(pci_exp)	Interface														//
	//---------------------------------------------------------------------------------------//

//	Tx
	.pci_exp_txn									(	pci_exp_txn																	)	,	
	.pci_exp_txp									(	pci_exp_txp																	)	,	
																																			
//	Rx																																		
	.pci_exp_rxn									(	pci_exp_rxn																	)	,	
	.pci_exp_rxp									(	pci_exp_rxp																	)	,	
																																			
																																			
																																			
																																			
	//----------	Shared	Logic	Internal	-------------------------																	
//	.int_qpll1lock_out								(																				)	,	//	output	wire	[	1	:0]	int_qpll1lock_out				
//	.int_qpll1outrefclk_out							(																				)	,	//	output	wire	[	1	:0]	int_qpll1outrefclk_out			
//	.int_qpll1outclk_out							(																				)	,	//	output	wire	[	1	:0]	int_qpll1outclk_out				
																																			
																																			
	//---------------------------------------------------------------------------------------//												
//	AXI	Interface																	//														
	//---------------------------------------------------------------------------------------//												
																																			
	.user_clk										(	user_clk																	)	,	
	.user_reset										(	user_reset_ip																)	,	
//	.user_reset										(	user_reset																	)	,	
	.user_lnk_up									(	user_lnk_up																	)	,	

//	.phy_rdy_out									(	phy_rdy_out																	)	,	
		
	.user_app_rdy									(	phy_rdy_out																	)	,	
																																			
	.s_axis_rq_tlast								(	s_axis_rq_tlast																)	,	
	.s_axis_rq_tdata								(	s_axis_rq_tdata																)	,	
	.s_axis_rq_tuser								(	s_axis_rq_tuser																)	,	
	.s_axis_rq_tkeep								(	s_axis_rq_tkeep																)	,	
	.s_axis_rq_tready								(	s_axis_rq_tready_4b															)	,	
	.s_axis_rq_tvalid								(	s_axis_rq_tvalid															)	,	
																																			
	.m_axis_rc_tdata								(	m_axis_rc_tdata																)	,	
	.m_axis_rc_tuser								(	m_axis_rc_tuser																)	,	
	.m_axis_rc_tlast								(	m_axis_rc_tlast																)	,	
	.m_axis_rc_tkeep								(	m_axis_rc_tkeep																)	,	
	.m_axis_rc_tvalid								(	m_axis_rc_tvalid															)	,	
	.m_axis_rc_tready								(	m_axis_rc_tready															)	,	
																																			
	.m_axis_cq_tdata								(	m_axis_cq_tdata																)	,	
	.m_axis_cq_tuser								(	m_axis_cq_tuser																)	,	
	.m_axis_cq_tlast								(	m_axis_cq_tlast																)	,	
	.m_axis_cq_tkeep								(	m_axis_cq_tkeep																)	,	
	.m_axis_cq_tvalid								(	m_axis_cq_tvalid															)	,	
	.m_axis_cq_tready								(	m_axis_cq_tready															)	,	
																																			
	.s_axis_cc_tdata								(	s_axis_cc_tdata																)	,	
	.s_axis_cc_tuser								(	s_axis_cc_tuser																)	,	
	.s_axis_cc_tlast								(	s_axis_cc_tlast																)	,	
	.s_axis_cc_tkeep								(	s_axis_cc_tkeep																)	,	
	.s_axis_cc_tvalid								(	s_axis_cc_tvalid															)	,	
	.s_axis_cc_tready								(	s_axis_cc_tready_4b															)	,	
																																			
	//---------------------------------------------------------------------------------------//												
//	Configuration	(CFG)	Interface													//													
	//---------------------------------------------------------------------------------------//												
																																			
	.pcie_rq_seq_num								(	pcie_rq_seq_num																)	,	
	.pcie_rq_seq_num_vld							(	pcie_rq_seq_num_vld															)	,	
	.pcie_rq_tag									(	pcie_rq_tag																	)	,	
//	.pcie_rq_tag_av									(	pcie_rq_tag_av																)	,	
	.pcie_rq_tag_vld								(	pcie_rq_tag_vld																)	,	
	.pcie_cq_np_req									(	pcie_cq_np_req																)	,	
	.pcie_cq_np_req_count							(	pcie_cq_np_req_count														)	,	
	.cfg_phy_link_down								(	cfg_phy_link_down															)	,	
	.cfg_phy_link_status							(	cfg_phy_link_status															)	,	
	.cfg_negotiated_width							(	cfg_negotiated_width														)	,	
	.cfg_current_speed								(	cfg_current_speed															)	,	
	.cfg_max_payload								(	cfg_max_payload																)	,	
	.cfg_max_read_req								(	cfg_max_read_req															)	,	
	.cfg_function_status							(																				)	,	//	output	wire	[	15	:0]	cfg_function_status					
	.cfg_function_power_state						(																				)	,	//	output	wire	[	11	:0]	cfg_function_power_state			
	.cfg_vf_status									(																				)	,	//	output	wire	[	15	:0]	cfg_vf_status						
	.cfg_vf_power_state								(																				)	,	//	output	wire	[	23	:0]	cfg_vf_power_state					
	.cfg_link_power_state							(																				)	,	//	output	wire	[	1	:0]	cfg_link_power_state				
//	Error	Reporting	Interface																											
	.cfg_err_cor_out								(	cfg_err_cor_out																)	,	//	output	wire				cfg_err_cor_out						
	.cfg_err_nonfatal_out							(	cfg_err_nonfatal_out														)	,	//	output	wire				cfg_err_nonfatal_out																					
	.cfg_err_fatal_out								(	cfg_err_fatal_out															)	,	//	output	wire				cfg_err_fatal_out																						
	.cfg_ltr_enable									(																				)	,	//	output	wire				cfg_ltr_enable																							
	.cfg_ltssm_state								(																				)	,	//	output	wire				cfg_ltssm_state																							
	.cfg_rcb_status									(																				)	,	//	output	wire	[	5	:0]	cfg_rcb_status																							
	.cfg_dpa_substate_change						(																				)	,	//	output	wire	[	3	:0]	cfg_dpa_substate_change																							
//	.cfg_obff_enable								(																				)	,	//	output	wire	[	1	:0]	cfg_obff_enable									
//	.cfg_pl_status_change							(																				)	,	//	output	wire	[	3	:0]	cfg_pl_status_change																						
																																																				
	.cfg_tph_requester_enable						(																				)	,	//	output	wire	[	3	:0]	cfg_tph_requester_enable																					
	.cfg_tph_st_mode								(																				)	,	//	output	wire	[	11	:0]	cfg_tph_st_mode																								
	.cfg_vf_tph_requester_enable					(																				)	,	//	output	wire	[	7	:0]	cfg_vf_tph_requester_enable																					
	.cfg_vf_tph_st_mode								(																				)	,	//	output	wire	[	23	:0]	cfg_vf_tph_st_mode																							
//	Management	Interface																																														
	.cfg_mgmt_addr									(	19'h0																		)	,	//	input	wire	[	18	:0]	cfg_mgmt_addr																							
	.cfg_mgmt_write									(	1'b0																		)	,	//	input	wire				cfg_mgmt_write																							
	.cfg_mgmt_write_data							(	32'h0																		)	,	//	input	wire	[	31	:0]	cfg_mgmt_write_data																						
	.cfg_mgmt_byte_enable							(	4'h0																		)	,	//	input	wire	[	3	:0]	cfg_mgmt_byte_enable																					
	.cfg_mgmt_read									(	1'b0																		)	,	//	input	wire				cfg_mgmt_read																							
	.cfg_mgmt_read_data								(																				)	,	//	output	wire	[	31	:0]	cfg_mgmt_read_data																						
	.cfg_mgmt_read_write_done						(																				)	,	//	output	wire				cfg_mgmt_read_write_done																				
	.cfg_mgmt_type1_cfg_reg_access					(	1'b0																		)	,	//	input	wire				cfg_mgmt_type1_cfg_reg_access																			
	.pcie_tfc_nph_av								(	pcie_tfc_nph_av																)	,	//	output	wire	[	1	:0]	pcie_tfc_nph_av																			
	.pcie_tfc_npd_av								(	pcie_tfc_npd_av																)	,	//	output	wire	[	1	:0]	pcie_tfc_npd_av																			
	.cfg_msg_received								(																				)	,	//	output	wire				cfg_msg_received																								
	.cfg_msg_received_data							(																				)	,	//	output	wire	[	7	:0]	cfg_msg_received_data																							
	.cfg_msg_received_type							(																				)	,	//	output	wire	[	4	:0]	cfg_msg_received_type																							
																																																				
	.cfg_msg_transmit								(	1'b0																		)	,	//	input	wire				cfg_msg_transmit					
	.cfg_msg_transmit_type							(	3'b0																		)	,	//	input	wire	[	2	:0]	cfg_msg_transmit_type				
	.cfg_msg_transmit_data							(	32'b0																		)	,	//	input	wire	[	31	:0]	cfg_msg_transmit_data				
	.cfg_msg_transmit_done							(																				)	,	//	output	wire				cfg_msg_transmit_done				
																																																				
	.cfg_fc_ph										(																				)	,	//	output	wire	[	7	:0]	cfg_fc_ph							
	.cfg_fc_pd										(																				)	,	//	output	wire	[	11	:0]	cfg_fc_pd							
	.cfg_fc_nph										(																				)	,	//	output	wire	[	7	:0]	cfg_fc_nph							
	.cfg_fc_npd										(																				)	,	//	output	wire	[	11	:0]	cfg_fc_npd							
	.cfg_fc_cplh									(																				)	,	//	output	wire	[	7	:0]	cfg_fc_cplh							
	.cfg_fc_cpld									(																				)	,	//	output	wire	[	11	:0]	cfg_fc_cpld							
	.cfg_fc_sel										(	3'b100																		)	,	//	input	wire	[	2	:0]	cfg_fc_sel							
																																																				
	.cfg_per_func_status_control					(	3'h0																		)	,	//	input	wire	[	2	:0]	cfg_per_func_status_control			
	.cfg_per_func_status_data						(																				)	,	//	output	wire	[	15	:0]	cfg_per_func_status_data			
	//-------------------------------------------------------------------------------//																															
//	EP	and	RP																	//																																
	//-------------------------------------------------------------------------------//																															
//	.cfg_vend_id									(	cfg_vend_id																	)	,																		
//	.cfg_dev_id										(	cfg_dev_id																	)	,																		
//	.cfg_rev_id										(	cfg_rev_id																	)	,																		
//	.cfg_subsys_id									(	cfg_subsys_id																)	,																		
	.cfg_subsys_vend_id								(	cfg_subsys_vend_id															)	,	//	input	wire	[	15	:0]	cfg_subsys_vend_id																									
																																																				
	.cfg_per_function_number						(	4'h0																		)	,	//	input	wire	[	3	:0]	cfg_per_function_number				
	.cfg_per_function_output_request				(	1'b0																		)	,	//	input	wire				cfg_per_function_output_request		
	.cfg_per_function_update_done					(																				)	,	//	output	wire				cfg_per_function_update_done		
																																																				
	.cfg_dsn										(	{`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1}										)	,	//	input	wire	[	63	:0]	cfg_dsn								
	.cfg_power_state_change_ack						(	1'b0																		)	,	//	input	wire				cfg_power_state_change_ack			
	.cfg_power_state_change_interrupt				(																				)	,	//	output	wire				cfg_power_state_change_interrupt	
	.cfg_err_cor_in									(	1'b0																		)	,	//	input	wire				cfg_err_cor_in						
	.cfg_err_uncor_in								(	1'b0																		)	,	//	input	wire				cfg_err_uncor_in					
	.cfg_flr_in_process								(	cfg_flr_in_process															)	,	//	output	wire	[	3	:0]	cfg_flr_in_process					
	.cfg_flr_done									(	{2'b0,cfg_flr_done}															)	,	//	input	wire	[	3	:0]	cfg_flr_done						
	.cfg_vf_flr_in_process							(	cfg_vf_flr_in_process														)	,	//	output	wire	[	7	:0]	cfg_vf_flr_in_process				
	.cfg_vf_flr_done								(	{2'b0,cfg_vf_flr_done}														)	,	//	input	wire	[	7	:0]	cfg_vf_flr_done						
//	.cfg_local_error								(	cfg_local_error																)	,	//	output	wire				cfg_local_error						
	.cfg_link_training_enable						(	1'b1																		)	,	//	input	wire				cfg_link_training_enable			
//	EP	only																																																	
	.cfg_hot_reset_out								(																				)	,	//	output	wire				cfg_hot_reset_out					
	.cfg_config_space_enable						(	1'b1																		)	,	//	input	wire				cfg_config_space_enable				
	.cfg_req_pm_transition_l23_ready				(	1'b0																		)	,	//	input	wire				cfg_req_pm_transition_l23_ready		
	.mmcm_lock										(	mmcm_lock																	)	,																								
//	RP	only																																
	.cfg_hot_reset_in								(	1'b0																		)	,	//	input	wire				cfg_hot_reset_in								
	.cfg_ds_bus_number								(	8'h0																		)	,	//	input	wire	[	7	:0]	cfg_ds_bus_number							
	.cfg_ds_device_number							(	5'h0																		)	,	//	input	wire	[	4	:0]	cfg_ds_device_number						
	.cfg_ds_function_number							(	3'h0																		)	,	//	input	wire	[	2	:0]	cfg_ds_function_number						
	.cfg_ds_port_number								(	8'h0																		)	,	//	input	wire	[	7	:0]	cfg_ds_port_number								
																																			
	//-------------------------------------------------------------------------------//														
//	EP	Only																	//															
	//-------------------------------------------------------------------------------//														
																																			
//	Interrupt	Interface	Signals																											
	.cfg_interrupt_int								(	0																			)	,	//	input	wire	[	3	:0]	cfg_interrupt_int				
	.cfg_interrupt_pending							(	0																			)	,	//	input	wire	[	3	:0]	cfg_interrupt_pending			
	.cfg_interrupt_sent								(																				)	,	//	output	wire				cfg_interrupt_sent				
																																			
	.cfg_interrupt_msi_enable						(	cfg_interrupt_msi_enable													)	,	//	output	wire	[	3	:0]	cfg_interrupt_msi_enable						
	.cfg_interrupt_msi_vf_enable					(																				)	,	//	output	wire	[	7	:0]	cfg_interrupt_msi_vf_enable						
	.cfg_interrupt_msi_mmenable						(	cfg_interrupt_msi_mmenable													)	,	
	.cfg_interrupt_msi_mask_update					(																				)	,	//	output	wire				cfg_interrupt_msi_mask_update					
	.cfg_interrupt_msi_data							(																				)	,	//	output	wire	[	31	:0]	cfg_interrupt_msi_data							
	.cfg_interrupt_msi_select						(	4'h0																		)	,	//	input	wire	[	3	:0]	cfg_interrupt_msi_select		
	.cfg_interrupt_msi_int							(	cfg_interrupt_msi_int														)	,	//	input	wire	[	31	:0]	cfg_interrupt_msi_int			
	.cfg_interrupt_msi_pending_status				(	31'h0																		)	,	//	input	wire	[	31	:0]	cfg_interrupt_msi_pending_status				
	.cfg_interrupt_msi_sent							(	cfg_interrupt_msi_sent														)	,	//	output	wire				cfg_interrupt_msi_sent							
	.cfg_interrupt_msi_fail							(	cfg_interrupt_msi_fail														)	,	//	output	wire				cfg_interrupt_msi_fail							
	.cfg_interrupt_msi_attr							(	3'h0																		)	,	//	input	wire	[	2	:0]	cfg_interrupt_msi_attr							
	.cfg_interrupt_msi_tph_present					(	1'b0																		)	,	//	input	wire				cfg_interrupt_msi_tph_present				
	.cfg_interrupt_msi_tph_type						(	2'h0																		)	,	//	input	wire	[	1	:0]	cfg_interrupt_msi_tph_type					
	.cfg_interrupt_msi_tph_st_tag					(	9'h0																		)	,	//	input	wire	[	8	:0]	cfg_interrupt_msi_tph_st_tag				
//	.cfg_interrupt_msi_pending_status_function_num	(	4'b0																		)	,	//	input	wire	[	3	:0]	cfg_interrupt_msi_pending_status_function_num	
//	.cfg_interrupt_msi_pending_status_data_enable	(	1'b0																		)	,	//	input	wire				cfg_interrupt_msi_pending_status_data_enable
	.cfg_interrupt_msi_function_number				(	3'h0																		)	,	//	input	wire	[	3	:0]	cfg_interrupt_msi_function_number				
																																			
// 	.drp_clk										(	user_clk																	)	,	//	input	wire				drp_clk								
//    .pcie_drp_rdy									(																				)	,	//	output	wire				drp_rdy								
//    .pcie_drp_do									(																				)	,	//	output	wire	[	15	:0]	drp_do								
//    .pcie_drp_en									(	1'b0																		)	,	//	input	wire				drp_en								
//    .pcie_drp_we									(	1'b0																		)	,	//	input	wire				drp_we								
//    .pcie_drp_addr									(	11'h0																		)	,	//	input	wire	[	9	:0]	drp_addr							
//    .pcie_drp_di									(	16'h0																		)	,	//	input	wire	[	15	:0]	drp_di								
//	.pl_gen2_upstream_prefer_deemph					(	1'b0																		)	,	//	input	wire				pl_gen2_upstream_prefer_deemph					
//	.pl_eq_reset_eieos_count						(	1'b0																		)	,	//	input	wire				pl_eq_reset_eieos_count							
//	.pl_eq_in_progress								(																				)	,	//	output	wire				pl_eq_in_progress								
//	.pl_eq_phase									(																				)	,	//	output	wire	[	1	:0]	pl_eq_phase										

/*	only	in Ultra7 FPGA
	.conf_req_data									(	32'h0																		)	,	//	input	wire	[	31	:0]	conf_req_data									
	.conf_req_reg_num								(	4'h0																		)	,	//	input	wire	[	3	:0]	conf_req_reg_num								
	.conf_req_type									(	2'h0																		)	,	//	input	wire	[	1	:0]	conf_req_type									
	.conf_req_valid									(	1'b0																		)	,	//	input	wire				conf_req_valid									
	.conf_req_ready									(																				)	,	//	output	wire				conf_req_ready									
	.conf_resp_rdata								(																				)	,	//	output	wire	[	31	:0]	conf_resp_rdata									
	.conf_resp_valid								(																				)	,	//	output	wire				conf_resp_valid									
*/
																																			
	//--------------------------------------------------------------------------------------//												
//	System(SYS)	Interface															//														
	//--------------------------------------------------------------------------------------//												
																																			
	.sys_clk										(	sys_clk																		)	,	//	input	wire				sys_clk											
//	.sys_clk_gt										(	sys_clk_gt																	)	,	//	input	wire				sys_clk_gt						
	.sys_reset										(~	sys_rst_n_c																	)		//	input	wire				sys_reset|| vio_rst						sys_rst_n_c	
	);					
	/*
//	reg		[	8	-1:0]	reg_pci_exp_txn											;	always@(posedge	user_clk)	reg_pci_exp_txn											<=	pci_exp_txn											;
//	reg		[	8   -1:0]	reg_pci_exp_txp										    ;	always@(posedge	user_clk)	reg_pci_exp_txp										    <=	pci_exp_txp										    ;
//	reg		[	8   -1:0]	reg_pci_exp_rxn										    ;	always@(posedge	user_clk)	reg_pci_exp_rxn										    <=	pci_exp_rxn										    ;
//	reg		[	8   -1:0]	reg_pci_exp_rxp										    ;	always@(posedge	user_clk)	reg_pci_exp_rxp										    <=	pci_exp_rxp										    ;
//	reg		[	1   -1:0]	reg_user_clk										    ;	always@(posedge	user_clk)	reg_user_clk										    <=	user_clk										    ;
	reg		[	1   -1:0]	reg_user_reset										    ;	always@(posedge	user_clk)	reg_user_reset										    <=	user_reset										    ;
	reg		[	1   -1:0]	reg_user_lnk_up										    ;	always@(posedge	user_clk)	reg_user_lnk_up										    <=	user_lnk_up										    ;
	reg		[	256 -1:0]	reg_s_axis_rq_tdata									    ;	always@(posedge	user_clk)	reg_s_axis_rq_tdata									    <=	s_axis_rq_tdata									    ;
	reg		[	8   -1:0]	reg_s_axis_rq_tkeep									    ;	always@(posedge	user_clk)	reg_s_axis_rq_tkeep									    <=	s_axis_rq_tkeep									    ;
	reg		[	1   -1:0]	reg_s_axis_rq_tlast									    ;	always@(posedge	user_clk)	reg_s_axis_rq_tlast									    <=	s_axis_rq_tlast									    ;
	reg		[	4   -1:0]	reg_s_axis_rq_tready								    ;	always@(posedge	user_clk)	reg_s_axis_rq_tready								    <=	s_axis_rq_tready								    ;
	reg		[	60  -1:0]	reg_s_axis_rq_tuser									    ;	always@(posedge	user_clk)	reg_s_axis_rq_tuser									    <=	s_axis_rq_tuser									    ;
	reg		[	1   -1:0]	reg_s_axis_rq_tvalid								    ;	always@(posedge	user_clk)	reg_s_axis_rq_tvalid								    <=	s_axis_rq_tvalid								    ;
	reg		[	256 -1:0]	reg_m_axis_rc_tdata									    ;	always@(posedge	user_clk)	reg_m_axis_rc_tdata									    <=	m_axis_rc_tdata									    ;
	reg		[	8   -1:0]	reg_m_axis_rc_tkeep									    ;	always@(posedge	user_clk)	reg_m_axis_rc_tkeep									    <=	m_axis_rc_tkeep									    ;
	reg		[	1   -1:0]	reg_m_axis_rc_tlast									    ;	always@(posedge	user_clk)	reg_m_axis_rc_tlast									    <=	m_axis_rc_tlast									    ;
	reg		[	1   -1:0]	reg_m_axis_rc_tready								    ;	always@(posedge	user_clk)	reg_m_axis_rc_tready								    <=	m_axis_rc_tready								    ;
	reg		[	75  -1:0]	reg_m_axis_rc_tuser									    ;	always@(posedge	user_clk)	reg_m_axis_rc_tuser									    <=	m_axis_rc_tuser									    ;
	reg		[	1   -1:0]	reg_m_axis_rc_tvalid								    ;	always@(posedge	user_clk)	reg_m_axis_rc_tvalid								    <=	m_axis_rc_tvalid								    ;
	reg		[	256 -1:0]	reg_m_axis_cq_tdata									    ;	always@(posedge	user_clk)	reg_m_axis_cq_tdata									    <=	m_axis_cq_tdata									    ;
	reg		[	8   -1:0]	reg_m_axis_cq_tkeep									    ;	always@(posedge	user_clk)	reg_m_axis_cq_tkeep									    <=	m_axis_cq_tkeep									    ;
	reg		[	1   -1:0]	reg_m_axis_cq_tlast									    ;	always@(posedge	user_clk)	reg_m_axis_cq_tlast									    <=	m_axis_cq_tlast									    ;
	reg		[	1   -1:0]	reg_m_axis_cq_tready								    ;	always@(posedge	user_clk)	reg_m_axis_cq_tready								    <=	m_axis_cq_tready								    ;
	reg		[	85  -1:0]	reg_m_axis_cq_tuser									    ;	always@(posedge	user_clk)	reg_m_axis_cq_tuser									    <=	m_axis_cq_tuser									    ;
	reg		[	1   -1:0]	reg_m_axis_cq_tvalid								    ;	always@(posedge	user_clk)	reg_m_axis_cq_tvalid								    <=	m_axis_cq_tvalid								    ;
	reg		[	256 -1:0]	reg_s_axis_cc_tdata									    ;	always@(posedge	user_clk)	reg_s_axis_cc_tdata									    <=	s_axis_cc_tdata									    ;
	reg		[	8   -1:0]	reg_s_axis_cc_tkeep									    ;	always@(posedge	user_clk)	reg_s_axis_cc_tkeep									    <=	s_axis_cc_tkeep									    ;
	reg		[	1   -1:0]	reg_s_axis_cc_tlast									    ;	always@(posedge	user_clk)	reg_s_axis_cc_tlast									    <=	s_axis_cc_tlast									    ;
	reg		[	4   -1:0]	reg_s_axis_cc_tready								    ;	always@(posedge	user_clk)	reg_s_axis_cc_tready								    <=	s_axis_cc_tready								    ;
	reg		[	33  -1:0]	reg_s_axis_cc_tuser									    ;	always@(posedge	user_clk)	reg_s_axis_cc_tuser									    <=	s_axis_cc_tuser									    ;
	reg		[	1   -1:0]	reg_s_axis_cc_tvalid								    ;	always@(posedge	user_clk)	reg_s_axis_cc_tvalid								    <=	s_axis_cc_tvalid								    ;
	reg		[	4   -1:0]	reg_pcie_rq_seq_num									    ;	always@(posedge	user_clk)	reg_pcie_rq_seq_num									    <=	pcie_rq_seq_num									    ;
	reg		[	1   -1:0]	reg_pcie_rq_seq_num_vld								    ;	always@(posedge	user_clk)	reg_pcie_rq_seq_num_vld								    <=	pcie_rq_seq_num_vld								    ;
	reg		[	6   -1:0]	reg_pcie_rq_tag										    ;	always@(posedge	user_clk)	reg_pcie_rq_tag										    <=	pcie_rq_tag										    ;
	reg		[	2   -1:0]	reg_pcie_rq_tag_av									    ;	always@(posedge	user_clk)	reg_pcie_rq_tag_av									    <=	pcie_rq_tag_av									    ;
	reg		[	1   -1:0]	reg_pcie_rq_tag_vld									    ;	always@(posedge	user_clk)	reg_pcie_rq_tag_vld									    <=	pcie_rq_tag_vld									    ;
	reg		[	2   -1:0]	reg_pcie_tfc_nph_av									    ;	always@(posedge	user_clk)	reg_pcie_tfc_nph_av									    <=	pcie_tfc_nph_av									    ;
	reg		[	2   -1:0]	reg_pcie_tfc_npd_av									    ;	always@(posedge	user_clk)	reg_pcie_tfc_npd_av									    <=	pcie_tfc_npd_av									    ;
	reg		[	1   -1:0]	reg_pcie_cq_np_req									    ;	always@(posedge	user_clk)	reg_pcie_cq_np_req									    <=	pcie_cq_np_req									    ;
	reg		[	6   -1:0]	reg_pcie_cq_np_req_count							    ;	always@(posedge	user_clk)	reg_pcie_cq_np_req_count							    <=	pcie_cq_np_req_count							    ;
	reg		[	1   -1:0]	reg_cfg_phy_link_down								    ;	always@(posedge	user_clk)	reg_cfg_phy_link_down								    <=	cfg_phy_link_down								    ;
	reg		[	2   -1:0]	reg_cfg_phy_link_status								    ;	always@(posedge	user_clk)	reg_cfg_phy_link_status								    <=	cfg_phy_link_status								    ;
	reg		[	4   -1:0]	reg_cfg_negotiated_width							    ;	always@(posedge	user_clk)	reg_cfg_negotiated_width							    <=	cfg_negotiated_width							    ;
	reg		[	3   -1:0]	reg_cfg_current_speed								    ;	always@(posedge	user_clk)	reg_cfg_current_speed								    <=	cfg_current_speed								    ;
	reg		[	3   -1:0]	reg_cfg_max_payload									    ;	always@(posedge	user_clk)	reg_cfg_max_payload									    <=	cfg_max_payload									    ;
	reg		[	3   -1:0]	reg_cfg_max_read_req								    ;	always@(posedge	user_clk)	reg_cfg_max_read_req								    <=	cfg_max_read_req								    ;
//	reg		[	16  -1:0]	reg_cfg_function_status								    ;	always@(posedge	user_clk)	reg_cfg_function_status								    <=	cfg_function_status								    ;
//	reg		[	12  -1:0]	reg_cfg_function_power_state						    ;	always@(posedge	user_clk)	reg_cfg_function_power_state						    <=	cfg_function_power_state						    ;
//	reg		[	16  -1:0]	reg_cfg_vf_status									    ;	always@(posedge	user_clk)	reg_cfg_vf_status									    <=	cfg_vf_status									    ;
//	reg		[	24  -1:0]	reg_cfg_vf_power_state								    ;	always@(posedge	user_clk)	reg_cfg_vf_power_state								    <=	cfg_vf_power_state								    ;
//	reg		[	2   -1:0]	reg_cfg_link_power_state							    ;	always@(posedge	user_clk)	reg_cfg_link_power_state							    <=	cfg_link_power_state							    ;
//	reg		[	19  -1:0]	reg_cfg_mgmt_addr									    ;	always@(posedge	user_clk)	reg_cfg_mgmt_addr									    <=	cfg_mgmt_addr									    ;
//	reg		[	1   -1:0]	reg_cfg_mgmt_write									    ;	always@(posedge	user_clk)	reg_cfg_mgmt_write									    <=	cfg_mgmt_write									    ;
//	reg		[	32  -1:0]	reg_cfg_mgmt_write_data								    ;	always@(posedge	user_clk)	reg_cfg_mgmt_write_data								    <=	cfg_mgmt_write_data								    ;
//	reg		[	4   -1:0]	reg_cfg_mgmt_byte_enable							    ;	always@(posedge	user_clk)	reg_cfg_mgmt_byte_enable							    <=	cfg_mgmt_byte_enable							    ;
//	reg		[	1   -1:0]	reg_cfg_mgmt_read									    ;	always@(posedge	user_clk)	reg_cfg_mgmt_read									    <=	cfg_mgmt_read									    ;
//	reg		[	32  -1:0]	reg_cfg_mgmt_read_data								    ;	always@(posedge	user_clk)	reg_cfg_mgmt_read_data								    <=	cfg_mgmt_read_data								    ;
//	reg		[	1   -1:0]	reg_cfg_mgmt_read_write_done						    ;	always@(posedge	user_clk)	reg_cfg_mgmt_read_write_done						    <=	cfg_mgmt_read_write_done						    ;
//	reg		[	1   -1:0]	reg_cfg_mgmt_type1_cfg_reg_access					    ;	always@(posedge	user_clk)	reg_cfg_mgmt_type1_cfg_reg_access					    <=	cfg_mgmt_type1_cfg_reg_access					    ;
//	reg		[	1   -1:0]	reg_cfg_err_cor_out									    ;	always@(posedge	user_clk)	reg_cfg_err_cor_out									    <=	cfg_err_cor_out									    ;
//	reg		[	1   -1:0]	reg_cfg_err_nonfatal_out							    ;	always@(posedge	user_clk)	reg_cfg_err_nonfatal_out							    <=	cfg_err_nonfatal_out							    ;
//	reg		[	1   -1:0]	reg_cfg_err_fatal_out								    ;	always@(posedge	user_clk)	reg_cfg_err_fatal_out								    <=	cfg_err_fatal_out								    ;
//	reg		[	1   -1:0]	reg_cfg_local_error									    ;	always@(posedge	user_clk)	reg_cfg_local_error									    <=	cfg_local_error									    ;
//	reg		[	1   -1:0]	reg_cfg_ltr_enable									    ;	always@(posedge	user_clk)	reg_cfg_ltr_enable									    <=	cfg_ltr_enable									    ;
//	reg		[	6   -1:0]	reg_cfg_ltssm_state									    ;	always@(posedge	user_clk)	reg_cfg_ltssm_state									    <=	cfg_ltssm_state									    ;
//	reg		[	4   -1:0]	reg_cfg_rcb_status									    ;	always@(posedge	user_clk)	reg_cfg_rcb_status									    <=	cfg_rcb_status									    ;
//	reg		[	4   -1:0]	reg_cfg_dpa_substate_change							    ;	always@(posedge	user_clk)	reg_cfg_dpa_substate_change							    <=	cfg_dpa_substate_change							    ;
//	reg		[	2   -1:0]	reg_cfg_obff_enable									    ;	always@(posedge	user_clk)	reg_cfg_obff_enable									    <=	cfg_obff_enable									    ;
//	reg		[	1   -1:0]	reg_cfg_pl_status_change							    ;	always@(posedge	user_clk)	reg_cfg_pl_status_change							    <=	cfg_pl_status_change							    ;
	reg		[	4   -1:0]	reg_cfg_tph_requester_enable						    ;	always@(posedge	user_clk)	reg_cfg_tph_requester_enable						    <=	cfg_tph_requester_enable						    ;
//	reg		[	12  -1:0]	reg_cfg_tph_st_mode									    ;	always@(posedge	user_clk)	reg_cfg_tph_st_mode									    <=	cfg_tph_st_mode									    ;
//	reg		[	8   -1:0]	reg_cfg_vf_tph_requester_enable						    ;	always@(posedge	user_clk)	reg_cfg_vf_tph_requester_enable						    <=	cfg_vf_tph_requester_enable						    ;
//	reg		[	24  -1:0]	reg_cfg_vf_tph_st_mode								    ;	always@(posedge	user_clk)	reg_cfg_vf_tph_st_mode								    <=	cfg_vf_tph_st_mode								    ;
//	reg		[	1   -1:0]	reg_cfg_msg_received								    ;	always@(posedge	user_clk)	reg_cfg_msg_received								    <=	cfg_msg_received								    ;
//	reg		[	8   -1:0]	reg_cfg_msg_received_data							    ;	always@(posedge	user_clk)	reg_cfg_msg_received_data							    <=	cfg_msg_received_data							    ;
//	reg		[	5   -1:0]	reg_cfg_msg_received_type							    ;	always@(posedge	user_clk)	reg_cfg_msg_received_type							    <=	cfg_msg_received_type							    ;
//	reg		[	1   -1:0]	reg_cfg_msg_transmit								    ;	always@(posedge	user_clk)	reg_cfg_msg_transmit								    <=	cfg_msg_transmit								    ;
//	reg		[	3   -1:0]	reg_cfg_msg_transmit_type							    ;	always@(posedge	user_clk)	reg_cfg_msg_transmit_type							    <=	cfg_msg_transmit_type							    ;
//	reg		[	32  -1:0]	reg_cfg_msg_transmit_data							    ;	always@(posedge	user_clk)	reg_cfg_msg_transmit_data							    <=	cfg_msg_transmit_data							    ;
//	reg		[	1   -1:0]	reg_cfg_msg_transmit_done							    ;	always@(posedge	user_clk)	reg_cfg_msg_transmit_done							    <=	cfg_msg_transmit_done							    ;
//	reg		[	8   -1:0]	reg_cfg_fc_ph										    ;	always@(posedge	user_clk)	reg_cfg_fc_ph										    <=	cfg_fc_ph										    ;
//	reg		[	12  -1:0]	reg_cfg_fc_pd										    ;	always@(posedge	user_clk)	reg_cfg_fc_pd										    <=	cfg_fc_pd										    ;
//	reg		[	8   -1:0]	reg_cfg_fc_nph										    ;	always@(posedge	user_clk)	reg_cfg_fc_nph										    <=	cfg_fc_nph										    ;
//	reg		[	12  -1:0]	reg_cfg_fc_npd										    ;	always@(posedge	user_clk)	reg_cfg_fc_npd										    <=	cfg_fc_npd										    ;
//	reg		[	8   -1:0]	reg_cfg_fc_cplh										    ;	always@(posedge	user_clk)	reg_cfg_fc_cplh										    <=	cfg_fc_cplh										    ;
//	reg		[	12  -1:0]	reg_cfg_fc_cpld										    ;	always@(posedge	user_clk)	reg_cfg_fc_cpld										    <=	cfg_fc_cpld										    ;
//	reg		[	3   -1:0]	reg_cfg_fc_sel										    ;	always@(posedge	user_clk)	reg_cfg_fc_sel										    <=	cfg_fc_sel										    ;
//	reg		[	3   -1:0]	reg_cfg_per_func_status_control						    ;	always@(posedge	user_clk)	reg_cfg_per_func_status_control						    <=	cfg_per_func_status_control						    ;
//	reg		[	16  -1:0]	reg_cfg_per_func_status_data						    ;	always@(posedge	user_clk)	reg_cfg_per_func_status_data						    <=	cfg_per_func_status_data						    ;
//	reg		[	4   -1:0]	reg_cfg_per_function_number							    ;	always@(posedge	user_clk)	reg_cfg_per_function_number							    <=	cfg_per_function_number							    ;
//	reg		[	1   -1:0]	reg_cfg_per_function_output_request					    ;	always@(posedge	user_clk)	reg_cfg_per_function_output_request					    <=	cfg_per_function_output_request					    ;
//	reg		[	1   -1:0]	reg_cfg_per_function_update_done					    ;	always@(posedge	user_clk)	reg_cfg_per_function_update_done					    <=	cfg_per_function_update_done					    ;
	reg		[	64  -1:0]	reg_cfg_dsn											    ;	always@(posedge	user_clk)	reg_cfg_dsn											    <=	cfg_dsn											    ;
	reg		[	1   -1:0]	reg_cfg_power_state_change_ack						    ;	always@(posedge	user_clk)	reg_cfg_power_state_change_ack						    <=	cfg_power_state_change_ack						    ;
	reg		[	1   -1:0]	reg_cfg_power_state_change_interrupt				    ;	always@(posedge	user_clk)	reg_cfg_power_state_change_interrupt				    <=	cfg_power_state_change_interrupt				    ;
	reg		[	1   -1:0]	reg_cfg_err_cor_in									    ;	always@(posedge	user_clk)	reg_cfg_err_cor_in									    <=	cfg_err_cor_in									    ;
	reg		[	1   -1:0]	reg_cfg_err_uncor_in								    ;	always@(posedge	user_clk)	reg_cfg_err_uncor_in								    <=	cfg_err_uncor_in								    ;
	reg		[	4   -1:0]	reg_cfg_flr_in_process								    ;	always@(posedge	user_clk)	reg_cfg_flr_in_process								    <=	cfg_flr_in_process								    ;
	reg		[	4   -1:0]	reg_cfg_flr_done									    ;	always@(posedge	user_clk)	reg_cfg_flr_done									    <=	cfg_flr_done									    ;
	reg		[	8   -1:0]	reg_cfg_vf_flr_in_process							    ;	always@(posedge	user_clk)	reg_cfg_vf_flr_in_process							    <=	cfg_vf_flr_in_process							    ;
	reg		[	8   -1:0]	reg_cfg_vf_flr_done									    ;	always@(posedge	user_clk)	reg_cfg_vf_flr_done									    <=	cfg_vf_flr_done									    ;
//	reg		[	1   -1:0]	reg_cfg_link_training_enable						    ;	always@(posedge	user_clk)	reg_cfg_link_training_enable						    <=	cfg_link_training_enable						    ;
//	reg		[	4   -1:0]	reg_cfg_interrupt_int								    ;	always@(posedge	user_clk)	reg_cfg_interrupt_int								    <=	cfg_interrupt_int								    ;
//	reg		[	4   -1:0]	reg_cfg_interrupt_pending							    ;	always@(posedge	user_clk)	reg_cfg_interrupt_pending							    <=	cfg_interrupt_pending							    ;
//	reg		[	1   -1:0]	reg_cfg_interrupt_sent								    ;	always@(posedge	user_clk)	reg_cfg_interrupt_sent								    <=	cfg_interrupt_sent								    ;
	reg		[	4   -1:0]	reg_cfg_interrupt_msi_enable						    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_enable						    <=	cfg_interrupt_msi_enable						    ;
	reg		[	8   -1:0]	reg_cfg_interrupt_msi_vf_enable						    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_vf_enable						    <=	cfg_interrupt_msi_vf_enable						    ;
	reg		[	12  -1:0]	reg_cfg_interrupt_msi_mmenable						    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_mmenable						    <=	cfg_interrupt_msi_mmenable						    ;
	reg		[	1   -1:0]	reg_cfg_interrupt_msi_mask_update					    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_mask_update					    <=	cfg_interrupt_msi_mask_update					    ;
	reg		[	32  -1:0]	reg_cfg_interrupt_msi_data							    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_data							    <=	cfg_interrupt_msi_data							    ;
	reg		[	4   -1:0]	reg_cfg_interrupt_msi_select						    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_select						    <=	cfg_interrupt_msi_select						    ;
	reg		[	32  -1:0]	reg_cfg_interrupt_msi_int							    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_int							    <=	cfg_interrupt_msi_int							    ;
//	reg		[	32  -1:0]	reg_cfg_interrupt_msi_pending_status				    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_pending_status				    <=	cfg_interrupt_msi_pending_status				    ;
//	reg		[	1   -1:0]	reg_cfg_interrupt_msi_pending_status_data_enable        ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_pending_status_data_enable        <=	cfg_interrupt_msi_pending_status_data_enable        ;
//	reg		[	4   -1:0]	reg_cfg_interrupt_msi_pending_status_function_num	    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_pending_status_function_num	    <=	cfg_interrupt_msi_pending_status_function_num	    ;
	reg		[	1   -1:0]	reg_cfg_interrupt_msi_sent							    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_sent							    <=	cfg_interrupt_msi_sent							    ;
	reg		[	1   -1:0]	reg_cfg_interrupt_msi_fail							    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_fail							    <=	cfg_interrupt_msi_fail							    ;
	reg		[	3   -1:0]	reg_cfg_interrupt_msi_attr							    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_attr							    <=	cfg_interrupt_msi_attr							    ;
//	reg		[	1   -1:0]	reg_cfg_interrupt_msi_tph_present					    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_tph_present					    <=	cfg_interrupt_msi_tph_present					    ;
//	reg		[	2   -1:0]	reg_cfg_interrupt_msi_tph_type						    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_tph_type						    <=	cfg_interrupt_msi_tph_type						    ;
//	reg		[	9   -1:0]	reg_cfg_interrupt_msi_tph_st_tag					    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_tph_st_tag					    <=	cfg_interrupt_msi_tph_st_tag					    ;
//	reg		[	4   -1:0]	reg_cfg_interrupt_msi_function_number				    ;	always@(posedge	user_clk)	reg_cfg_interrupt_msi_function_number				    <=	cfg_interrupt_msi_function_number				    ;
//	reg		[	1   -1:0]	reg_cfg_hot_reset_out								    ;	always@(posedge	user_clk)	reg_cfg_hot_reset_out								    <=	cfg_hot_reset_out								    ;
//	reg		[	1   -1:0]	reg_cfg_config_space_enable							    ;	always@(posedge	user_clk)	reg_cfg_config_space_enable							    <=	cfg_config_space_enable							    ;
//	reg		[	1   -1:0]	reg_cfg_req_pm_transition_l23_ready					    ;	always@(posedge	user_clk)	reg_cfg_req_pm_transition_l23_ready					    <=	cfg_req_pm_transition_l23_ready					    ;
	reg		[	1   -1:0]	reg_cfg_hot_reset_in								    ;	always@(posedge	user_clk)	reg_cfg_hot_reset_in								    <=	cfg_hot_reset_in								    ;
	reg		[	8   -1:0]	reg_cfg_ds_port_number								    ;	always@(posedge	user_clk)	reg_cfg_ds_port_number								    <=	cfg_ds_port_number								    ;
	reg		[	8   -1:0]	reg_cfg_ds_bus_number								    ;	always@(posedge	user_clk)	reg_cfg_ds_bus_number								    <=	cfg_ds_bus_number								    ;
	reg		[	5   -1:0]	reg_cfg_ds_device_number							    ;	always@(posedge	user_clk)	reg_cfg_ds_device_number							    <=	cfg_ds_device_number							    ;
	reg		[	3   -1:0]	reg_cfg_ds_function_number							    ;	always@(posedge	user_clk)	reg_cfg_ds_function_number							    <=	cfg_ds_function_number							    ;
	reg		[	16  -1:0]	reg_cfg_subsys_vend_id								    ;	always@(posedge	user_clk)	reg_cfg_subsys_vend_id								    <=	cfg_subsys_vend_id								    ;
	reg		[	1   -1:0]	reg_drp_rdy											    ;	always@(posedge	user_clk)	reg_drp_rdy											    <=	drp_rdy											    ;
	reg		[	16  -1:0]	reg_drp_do											    ;	always@(posedge	user_clk)	reg_drp_do											    <=	drp_do											    ;
//	reg		[	1   -1:0]	reg_drp_clk											    ;	always@(posedge	user_clk)	reg_drp_clk											    <=	drp_clk											    ;
	reg		[	1   -1:0]	reg_drp_en											    ;	always@(posedge	user_clk)	reg_drp_en											    <=	drp_en											    ;
	reg		[	1   -1:0]	reg_drp_we											    ;	always@(posedge	user_clk)	reg_drp_we											    <=	drp_we											    ;
	reg		[	10  -1:0]	reg_drp_addr										    ;	always@(posedge	user_clk)	reg_drp_addr										    <=	drp_addr										    ;
	reg		[	16  -1:0]	reg_drp_di											    ;	always@(posedge	user_clk)	reg_drp_di											    <=	drp_di											    ;
//	reg		[	1   -1:0]	reg_sys_clk											    ;	always@(posedge	user_clk)	reg_sys_clk											    <=	sys_clk											    ;
//	reg		[	1   -1:0]	reg_sys_clk_gt										    ;	always@(posedge	user_clk)	reg_sys_clk_gt										    <=	sys_clk_gt										    ;
	reg		[	1   -1:0]	reg_sys_rst_n_c										    ;	always@(posedge	user_clk)	reg_sys_rst_n_c										    <=	sys_rst_n_c										    ;
//	reg		[	2   -1:0]	reg_conf_req_type									    ;	always@(posedge	user_clk)	reg_conf_req_type									    <=	conf_req_type									    ;
//	reg		[	4   -1:0]	reg_conf_req_reg_num								    ;	always@(posedge	user_clk)	reg_conf_req_reg_num								    <=	conf_req_reg_num								    ;
//	reg		[	32  -1:0]	reg_conf_req_data									    ;	always@(posedge	user_clk)	reg_conf_req_data									    <=	conf_req_data									    ;
//	reg		[	1   -1:0]	reg_conf_req_valid									    ;	always@(posedge	user_clk)	reg_conf_req_valid									    <=	conf_req_valid									    ;
//	reg		[	1   -1:0]	reg_conf_req_ready									    ;	always@(posedge	user_clk)	reg_conf_req_ready									    <=	conf_req_ready									    ;
//	reg		[	32  -1:0]	reg_conf_resp_rdata									    ;	always@(posedge	user_clk)	reg_conf_resp_rdata									    <=	conf_resp_rdata									    ;
//	reg		[	1   -1:0]	reg_conf_resp_valid									    ;	always@(posedge	user_clk)	reg_conf_resp_valid									    <=	conf_resp_valid									    ;
//	reg		[	1   -1:0]	reg_pl_eq_reset_eieos_count							    ;	always@(posedge	user_clk)	reg_pl_eq_reset_eieos_count							    <=	pl_eq_reset_eieos_count							    ;
//	reg		[	1   -1:0]	reg_pl_gen2_upstream_prefer_deemph					    ;	always@(posedge	user_clk)	reg_pl_gen2_upstream_prefer_deemph					    <=	pl_gen2_upstream_prefer_deemph					    ;
//	reg		[	1   -1:0]	reg_pl_eq_in_progress								    ;	always@(posedge	user_clk)	reg_pl_eq_in_progress								    <=	pl_eq_in_progress								    ;
//	reg		[	2   -1:0]	reg_pl_eq_phase										    ;	always@(posedge	user_clk)	reg_pl_eq_phase										    <=	pl_eq_phase										    ;
//	reg		[	2   -1:0]	reg_int_qpll1lock_out								    ;	always@(posedge	user_clk)	reg_int_qpll1lock_out								    <=	int_qpll1lock_out								    ;
//	reg		[	2   -1:0]	reg_int_qpll1outrefclk_out							    ;	always@(posedge	user_clk)	reg_int_qpll1outrefclk_out							    <=	int_qpll1outrefclk_out							    ;
//	reg		[	2   -1:0]	reg_int_qpll1outclk_out								    ;	always@(posedge	user_clk)	reg_int_qpll1outclk_out								    <=	int_qpll1outclk_out								    ;
	reg		[	1   -1:0]	reg_phy_rdy_out										    ;	always@(posedge	user_clk)	reg_phy_rdy_out										    <=	phy_rdy_out										    ;

	vio_0 vio_0_5x128 (
	  .clk			(	user_clk		)	,//	input wire clk
	  .probe_in0	(	
						{	reg_user_reset										  ,  
							reg_user_lnk_up										  ,  
							reg_pcie_rq_seq_num									  ,  
							reg_pcie_rq_seq_num_vld								  ,  
							reg_pcie_rq_tag										  ,  
							reg_pcie_rq_tag_av									  ,  
							reg_pcie_rq_tag_vld									  ,  
							reg_pcie_tfc_nph_av									  ,  
							reg_pcie_tfc_npd_av									  ,  
							reg_pcie_cq_np_req									  ,  
							reg_pcie_cq_np_req_count							  ,  
							reg_cfg_phy_link_down								  ,  
							reg_cfg_phy_link_status								  ,  
							reg_cfg_negotiated_width							  ,  
							reg_cfg_current_speed								  ,  
							reg_cfg_max_payload									  ,  
							reg_cfg_max_read_req								  ,  
							reg_cfg_function_status								  ,  
							reg_cfg_function_power_state						  ,  
							reg_cfg_vf_status									  ,  
							reg_cfg_vf_power_state								  ,  
							reg_cfg_link_power_state							  ,  
							reg_cfg_mgmt_addr									  ,  
							reg_cfg_mgmt_write									  ,  
							reg_cfg_mgmt_write_data								  ,  
							reg_cfg_mgmt_byte_enable							  ,  
							reg_cfg_mgmt_read									  ,  
							reg_cfg_mgmt_read_data								  ,  
							reg_cfg_mgmt_read_write_done						  ,  
							reg_cfg_mgmt_type1_cfg_reg_access					  ,  
							reg_cfg_err_cor_out									  ,  
							reg_cfg_err_nonfatal_out							  ,  
							reg_cfg_err_fatal_out								  ,  
							reg_cfg_local_error									  ,  
							reg_cfg_ltr_enable									  ,  
							reg_cfg_ltssm_state									  ,  
							reg_cfg_rcb_status									  ,  
							reg_cfg_dpa_substate_change							  ,  
							reg_cfg_obff_enable									  ,  
							reg_cfg_pl_status_change							  ,  
							reg_cfg_tph_requester_enable						  ,  
							reg_cfg_tph_st_mode									  ,  
							reg_cfg_vf_tph_requester_enable						    
						}	
					),
	  .probe_in1	(	
						{	reg_cfg_vf_tph_st_mode								  ,  
							reg_cfg_msg_received								  ,  
							reg_cfg_msg_received_data							  ,  
							reg_cfg_msg_received_type							  ,  
							reg_cfg_msg_transmit								  ,  
							reg_cfg_msg_transmit_type							  ,  
							reg_cfg_msg_transmit_data							  ,  
							reg_cfg_msg_transmit_done							  ,  
							reg_cfg_fc_ph										  ,  
							reg_cfg_fc_pd										  ,  
							reg_cfg_fc_nph										  ,  
							reg_cfg_fc_npd										  ,  
							reg_cfg_fc_cplh										  ,  
							reg_cfg_fc_cpld										  ,  
							reg_cfg_fc_sel										  ,  
							reg_cfg_per_func_status_control						  ,  
							reg_cfg_per_func_status_data						  ,  
							reg_cfg_per_function_number							  ,  
							reg_cfg_per_function_output_request					  ,  
							reg_cfg_per_function_update_done					  ,  
							reg_cfg_dsn											  ,  
							reg_cfg_power_state_change_ack						  ,  
							reg_cfg_power_state_change_interrupt				  ,  
							reg_cfg_err_cor_in									  ,  
							reg_cfg_err_uncor_in								  ,  
							reg_cfg_flr_in_process								  ,  
							reg_cfg_flr_done									  ,  
							reg_cfg_vf_flr_in_process							  ,  
							reg_cfg_vf_flr_done									  ,  
							reg_cfg_link_training_enable						  	}
					),
	  .probe_in2	(	
						{	reg_cfg_interrupt_int								  ,  
							reg_cfg_interrupt_pending							  ,  
							reg_cfg_interrupt_sent								  ,  
							reg_cfg_interrupt_msi_enable						  ,  
							reg_cfg_interrupt_msi_vf_enable						  ,  
							reg_cfg_interrupt_msi_mmenable						  ,  
							reg_cfg_interrupt_msi_mask_update					  ,  
							reg_cfg_interrupt_msi_data							  ,  
							reg_cfg_interrupt_msi_select						  ,  
							reg_cfg_interrupt_msi_int							  ,  
							reg_cfg_interrupt_msi_pending_status				  ,  
					//		reg_cfg_interrupt_msi_pending_status_data_enable      ,  
					//		reg_cfg_interrupt_msi_pending_status_function_num	  ,  
							reg_cfg_interrupt_msi_sent							  ,  
							reg_cfg_interrupt_msi_fail							  ,  
							reg_cfg_interrupt_msi_attr							  ,  
							reg_cfg_interrupt_msi_tph_present					  ,  
							reg_cfg_interrupt_msi_tph_type						  ,  
							reg_cfg_interrupt_msi_tph_st_tag					  ,  
							reg_cfg_interrupt_msi_function_number				  ,  
							reg_cfg_hot_reset_out								  ,  
							reg_cfg_config_space_enable							  ,  
							reg_cfg_req_pm_transition_l23_ready					  ,  
							reg_cfg_hot_reset_in								  ,  
							reg_cfg_ds_port_number								  ,  
							reg_cfg_ds_bus_number								  ,  
							reg_cfg_ds_device_number							  ,  
							reg_cfg_ds_function_number							  ,  
							reg_cfg_subsys_vend_id								  ,  
							reg_drp_rdy											  ,  
							reg_drp_do											  ,  	
							reg_drp_en											  ,  
							reg_drp_we											  ,  
							reg_drp_addr										  ,  
							reg_drp_di											  ,  	
							reg_sys_rst_n_c										    
//							reg_conf_req_type									  ,  
//							reg_conf_req_reg_num								    
							}
					),
	  .probe_in3	(	
						{	
//							reg_conf_req_data									 ,   
//							reg_conf_req_valid									 ,   
//							reg_conf_req_ready									 ,   
//							reg_conf_resp_rdata									 ,   
//							reg_conf_resp_valid									 ,   
//							reg_pl_eq_reset_eieos_count							 ,   
//							reg_pl_gen2_upstream_prefer_deemph					 ,   
//							reg_pl_eq_in_progress								 ,   
//							reg_pl_eq_phase										 ,   
//							reg_int_qpll1lock_out								 ,   
							reg_phy_rdy_out										 ,   
							reg_s_axis_rq_tkeep									 ,   
							reg_s_axis_rq_tlast									 ,   
							reg_s_axis_rq_tready								 ,   
							reg_s_axis_rq_tuser									 ,   
							reg_s_axis_rq_tvalid								 ,   	
							reg_m_axis_rc_tkeep									 ,   
							reg_m_axis_rc_tlast									 ,   
							reg_m_axis_rc_tready								 ,   
							reg_m_axis_rc_tuser									 ,   
							reg_m_axis_rc_tvalid								    }	
					),
	  .probe_in4	(	
						{	reg_m_axis_cq_tkeep									 ,  
							reg_m_axis_cq_tlast									 ,  
							reg_m_axis_cq_tready								 ,  
							reg_m_axis_cq_tuser									 ,  
							reg_m_axis_cq_tvalid								 ,  	
							reg_s_axis_cc_tkeep									 ,  
							reg_s_axis_cc_tlast									 ,  
							reg_s_axis_cc_tready								 ,  
							reg_s_axis_cc_tuser									 ,  
							reg_s_axis_cc_tvalid									}
					)
	);
	*/
	
`endif

endmodule
