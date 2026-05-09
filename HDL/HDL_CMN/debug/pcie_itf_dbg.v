`timescale	1ps/1ps
module	pcie_itf_dbg		#(
	parameter			DW								=	256
)(

		input										m_axis_rc_tready							,
		input										m_axis_rc_tvalid							,
		input										m_axis_rc_tlast								,
		input	[	DW			-	1	:	0	]	m_axis_rc_tdata								,
		input	[	DW	/	32	-	1	:	0	]	m_axis_rc_tkeep								,
		input	[	75			-	1	:	0	]	m_axis_rc_tuser								,

		input										s_axis_cc_tvalid							,
		input										s_axis_cc_tready							,
		input	[	DW			-	1	:	0	]	s_axis_cc_tdata								,
		input	[	DW	/	32	-	1	:	0	]	s_axis_cc_tkeep								,
		input										s_axis_cc_tlast								,
		input	[	33			-	1	:	0	]	s_axis_cc_tuser								,

		input										s_axis_rq_tvalid							,
		input										s_axis_rq_tready							,
		input	[	DW			-	1	:	0	]	s_axis_rq_tdata								,
		input	[	DW	/	32	-	1	:	0	]	s_axis_rq_tkeep								,
		input										s_axis_rq_tlast								,
		input	[	60			-	1	:	0	]	s_axis_rq_tuser								,

		input	[	6			-	1	:	0	]  	pcie_rq_tag									,
		input										pcie_rq_tag_vld								,
		input	[	2			-	1	:	0	]  	pcie_rq_tag_av								,
		input	[	2			-	1	:	0	]  	pcie_tfc_nph_av								,
		input	[	2			-	1	:	0	]  	pcie_tfc_npd_av								,
		input	[	4			-	1	:	0	]  	pcie_rq_seq_num								,
		input										pcie_rq_seq_num_vld							,

		input										m_axis_cq_tready							,
		input										m_axis_cq_tvalid							,
		input										m_axis_cq_tlast								,
		input	[	DW			-	1	:	0	]	m_axis_cq_tdata								,
		input	[	DW	/	32	-	1	:	0	]	m_axis_cq_tkeep								,
		input	[	85			-	1	:	0	]	m_axis_cq_tuser								,
		input	[	6			-	1	:	0	]	pcie_cq_np_req_count						,
		input										pcie_cq_np_req								,

		input	[3:0]								cfg_interrupt_msi_enable					,
		input	[11:0]								cfg_interrupt_msi_mmenable					,
		input	[31:0]								cfg_interrupt_msi_int						,
		input										cfg_interrupt_msi_sent						,
		input										cfg_interrupt_msi_fail						,
		input	[01:0]								inter_req_cnt								,
		input	[01:0]								inter_send_cnt								,
		input	[01:0]								inter_fail_cnt								,
		input	[31:0]								inter_int_latch								,

		input			[2:0]						cfg_current_speed							,
		input			[3:0]						cfg_negotiated_width						,
		input										cfg_phy_link_down							,
		input			[1:0]						cfg_phy_link_status							,

		input										cfg_err_cor_out								,
		input										cfg_err_nonfatal_out						,
		input										cfg_err_fatal_out							,
		input										cfg_local_error								,
		input										user_lnk_up									,
		input										phy_rdy_out									,

		input			[2:0]						cfg_max_payload								,	//	no used in pcie gen3
		input			[2:0]						cfg_max_read_req							,	//	no used in pcie gen3


		input										c_os_config									,
		input										c_os_big_endian								,

		input			[	16	-	1	:	0]		pcie_far_id									,
		input			[	16	-	1	:	0]		pcie_dev_id									,
		output			[	3	-	1	:	0]		led											,

		input			[	4	-	1	:	0]		srio_clk_cnt								,
		input			[	12	-	1	:	0]		srio_iotx_trvl_cnt							,
		input			[	12	-	1	:	0]		srio_iorx_trvl_cnt							,
		input			[	2	-	1	:	0]		srio_port_error								,
		input			[	2	-	1	:	0]		srio_port_initialized						,
		input			[	2	-	1	:	0]		srio_link_initialized						,
		input			[	2	-	1	:	0]		srio_mode_1x								,
		input			[	2	-	1	:	0]		srio_force_reinit							,
		input										mmcm_lock									,
		input										sys_rst										,
		input										sys_rst_n_in_c								,
		input										sys_rst_n_c									,
		output	wire								soft_rst									,
		
		input										pcie_clk									,
		input										pcie_rst

);


	wire	clk	=	pcie_clk	;
	wire	rst	=	pcie_rst	;

	localparam	PCIE_DW	=	DW	;

	reg		[	32	-	1	:	0	]	pcie_clk_cnt	=	0	;
	always@(posedge	pcie_clk)	pcie_clk_cnt	<=	pcie_clk_cnt	+	1	;

	assign	led[2]	=	user_lnk_up			;
	assign	led[1]	=	pcie_rst			;
	assign	led[0]	=	pcie_clk_cnt[31]	;

//	//////////////	pcie vio and ila debug signal	////////////////

	wire											rq_tvalid		=	s_axis_rq_tvalid		;
	wire											rq_tready		=	s_axis_rq_tready		;
	wire											rq_tlast		=	s_axis_rq_tlast			;
	wire					[PCIE_DW	-1:0]		rq_tdata		=	s_axis_rq_tdata			;
	wire								[59:0]		rq_tuser		=	s_axis_rq_tuser			;
	wire					[PCIE_DW	/4-1:0]		rq_tkeep		=	s_axis_rq_tkeep			;

	wire											rc_tvalid		=	m_axis_rc_tvalid		;
	wire											rc_tready		=	m_axis_rc_tready		;
	wire											rc_tlast		=	m_axis_rc_tlast			;
	wire					[PCIE_DW	-1:0]		rc_tdata		=	m_axis_rc_tdata			;
	wire								[74:0]		rc_tuser		=	m_axis_rc_tuser			;
	wire					[PCIE_DW	/4-1:0]		rc_tkeep		=	m_axis_rc_tkeep			;

	wire											cq_tvalid		=	m_axis_cq_tvalid		;
	wire											cq_tready		=	m_axis_cq_tready		;
	wire											cq_tlast		=	m_axis_cq_tlast			;
	wire					[PCIE_DW	-1:0]		cq_tdata		=	m_axis_cq_tdata			;
	wire								[84:0]		cq_tuser		=	m_axis_cq_tuser			;
	wire					[PCIE_DW	/4-1:0]		cq_tkeep		=	m_axis_cq_tkeep			;

	wire											cc_tvalid		=	s_axis_cc_tvalid		;
	wire											cc_tready		=	s_axis_cc_tready		;
	wire											cc_tlast		=	s_axis_cc_tlast			;
	wire					[PCIE_DW	-1:0]		cc_tdata		=	s_axis_cc_tdata			;
	wire								[32:0]		cc_tuser		=	s_axis_cc_tuser			;
	wire					[PCIE_DW	/4-1:0]		cc_tkeep		=	s_axis_cc_tkeep			;

	reg	[	7	:	0	]	pcie_rq_tag_cnt	=	0	;
	always@(posedge	clk)	pcie_rq_tag_cnt	<=	rst	?	0	:	pcie_rq_tag_vld	?	pcie_rq_tag_cnt	+	1	:	pcie_rq_tag_cnt	;

	reg		cq_sof_idle	=	0	;
	always@(posedge	clk)	cq_sof_idle	<=	rst	||	(	cq_tready	&&	cq_tvalid	&&	cq_tlast	)	?	1'b1	:	cq_tready	&&	cq_tvalid	?	0	:	cq_sof_idle	;
	wire	cq_sof	=	cq_sof_idle	&&	cq_tvalid	;

	reg		[PCIE_DW		-1:0]		cq_thead_256	=	0	;	always@(posedge	clk)	cq_thead_256	<=	rst	?	0	:	cq_sof	?	cq_tdata	:	cq_thead_256	;
	reg		[PCIE_DW	/4	-1:0]		cq_thead_64		=	0	;
	reg		[	2			-1:0]		cq_hd_cnt		=	0	;
	reg		[	8			-1:0]		cq_trvl_cnt		=	0	;	always@(posedge	clk)	cq_trvl_cnt	<=	rst	?	0	:	cq_tready&&cq_tvalid&&cq_tlast	?	cq_trvl_cnt	+1	:	cq_trvl_cnt	;

	reg	[	32	-1:0]	cq_thead_dw0	=	0	;	always@(posedge	clk)	cq_thead_dw0	<=	rst	?	0	:	cq_sof	?	cq_tdata[0*32+:32]	:	cq_thead_dw0	;
	reg	[	32	-1:0]	cq_thead_dw1	=	0	;	always@(posedge	clk)	cq_thead_dw1	<=	rst	?	0	:	cq_sof	?	cq_tdata[1*32+:32]	:	cq_thead_dw1	;
	reg	[	32	-1:0]	cq_thead_dw2	=	0	;	always@(posedge	clk)	cq_thead_dw2	<=	rst	?	0	:	cq_sof	?	cq_tdata[2*32+:32]	:	cq_thead_dw2	;
	reg	[	32	-1:0]	cq_thead_dw3	=	0	;	always@(posedge	clk)	cq_thead_dw3	<=	rst	?	0	:	cq_sof	?	cq_tdata[3*32+:32]	:	cq_thead_dw3	;
	reg	[	32	-1:0]	cq_tdata_dw3	=	0	;	always@(posedge	clk)	cq_tdata_dw3	<=	rst	?	0	:	cq_sof	?	cq_tdata[7*32+:32]	:	cq_tdata_dw3	;
	reg	[	32	-1:0]	cq_tdata_dw2	=	0	;	always@(posedge	clk)	cq_tdata_dw2	<=	rst	?	0	:	cq_sof	?	cq_tdata[6*32+:32]	:	cq_tdata_dw2	;
	reg	[	32	-1:0]	cq_tdata_dw1	=	0	;	always@(posedge	clk)	cq_tdata_dw1	<=	rst	?	0	:	cq_sof	?	cq_tdata[5*32+:32]	:	cq_tdata_dw1	;
	reg	[	32	-1:0]	cq_tdata_dw0	=	0	;	always@(posedge	clk)	cq_tdata_dw0	<=	rst	?	0	:	cq_sof	?	cq_tdata[4*32+:32]	:	cq_tdata_dw0	;

	reg	cq_sof_dly	=	0	;
	always@(posedge	clk)	cq_sof_dly	<=	cq_sof	;

	always@(posedge	clk)	begin
		if(	cq_sof_dly	)	begin
			$display("%0t	:recv a pcie TLP : cq_thead_dw0 is	%h	cq_thead_dw1	is	%h	cq_thead_dw2	is	%h	cq_thead_dw3	is	%h",	$realtime,	cq_thead_dw0,cq_thead_dw1,cq_thead_dw2,cq_thead_dw3);
			$display("%0t	:recv a pcie TLP : cq_tdata_dw0 is	%h	cq_tdata_dw1	is	%h	cq_tdata_dw2	is	%h	cq_tdata_dw3	is	%h",	$realtime,	cq_tdata_dw0,cq_tdata_dw1,cq_tdata_dw2,cq_tdata_dw3);
		end
	end

	always@(posedge	clk)	begin
		if(	rst	)	begin
			cq_hd_cnt	<=	0	;
			cq_thead_64	<=	64'h1234567887654321	;
		end	else	if(	cq_sof	)	begin
			cq_hd_cnt	<=	1	;
			cq_thead_64	<=	cq_tdata[0*64	+:	64]	;
		end	else	if(	cq_hd_cnt	==	1	)	begin
			cq_hd_cnt	<=	2	;
			cq_thead_64	<=	cq_thead_256[1*64	+:	64]	;
		end	else	if(	cq_hd_cnt	==	2	)	begin
			cq_hd_cnt	<=	3	;
			cq_thead_64	<=	cq_thead_256[2*64	+:	64]	;
		end	else	if(	cq_hd_cnt	==	3	)	begin
			cq_hd_cnt	<=	0	;
			cq_thead_64	<=	cq_thead_256[3*64	+:	64]	;
		end	else	begin
			cq_hd_cnt	<=	0	;
			cq_thead_64	<=	cq_thead_64				;
		end
	end

	reg		cc_sof_idle	=	0	;
	always@(posedge	clk)	cc_sof_idle	<=	rst	||	(	cc_tready	&&	cc_tvalid	&&	cc_tlast	)	?	1'b1	:	cc_tready	&&	cc_tvalid	?	0	:	cc_sof_idle	;
	wire	cc_sof	=	cc_sof_idle	&&	cc_tvalid	;

	reg		[PCIE_DW		-1:0]		cc_thead_256	=	0	;	always@(posedge	clk)	cc_thead_256	<=	rst	?	0	:	cc_sof	?	cc_tdata	:	cc_thead_256	;
	reg		[PCIE_DW	/4	-1:0]		cc_thead_64		=	0	;
	reg		[	2			-1:0]		cc_hd_cnt		=	0	;
	reg		[	8			-1:0]		cc_trvl_cnt		=	0	;	always@(posedge	clk)	cc_trvl_cnt	<=	rst	?	0	:	cc_tready&&cc_tvalid&&cc_tlast	?	cc_trvl_cnt	+1	:	cc_trvl_cnt	;

	reg	[	32	-1:0]	cc_thead_dw0	=	0	;	always@(posedge	clk)	cc_thead_dw0	<=	rst	?	0	:	cc_sof	?	cc_tdata[0*32+:32]	:	cc_thead_dw0	;
	reg	[	32	-1:0]	cc_thead_dw1	=	0	;	always@(posedge	clk)	cc_thead_dw1	<=	rst	?	0	:	cc_sof	?	cc_tdata[1*32+:32]	:	cc_thead_dw1	;
	reg	[	32	-1:0]	cc_thead_dw2	=	0	;	always@(posedge	clk)	cc_thead_dw2	<=	rst	?	0	:	cc_sof	?	cc_tdata[2*32+:32]	:	cc_thead_dw2	;
	reg	[	32	-1:0]	cc_thead_dw3	=	0	;	always@(posedge	clk)	cc_thead_dw3	<=	rst	?	0	:	cc_sof	?	cc_tdata[3*32+:32]	:	cc_thead_dw3	;
	reg	[	32	-1:0]	cc_tdata_dw3	=	0	;	always@(posedge	clk)	cc_tdata_dw3	<=	rst	?	0	:	cc_sof	?	cc_tdata[7*32+:32]	:	cc_tdata_dw3	;
	reg	[	32	-1:0]	cc_tdata_dw2	=	0	;	always@(posedge	clk)	cc_tdata_dw2	<=	rst	?	0	:	cc_sof	?	cc_tdata[6*32+:32]	:	cc_tdata_dw2	;
	reg	[	32	-1:0]	cc_tdata_dw1	=	0	;	always@(posedge	clk)	cc_tdata_dw1	<=	rst	?	0	:	cc_sof	?	cc_tdata[5*32+:32]	:	cc_tdata_dw1	;
	reg	[	32	-1:0]	cc_tdata_dw0	=	0	;	always@(posedge	clk)	cc_tdata_dw0	<=	rst	?	0	:	cc_sof	?	cc_tdata[4*32+:32]	:	cc_tdata_dw0	;

	reg	cc_sof_dly	=	0	;
	always@(posedge	clk)	cc_sof_dly	<=	cc_sof	;

	always@(posedge	clk)	begin
		if(	cc_sof_dly	)	begin
			$display("%0t	:recv a pcie TLP : cc_thead_dw0 is	%h	cc_thead_dw1	is	%h	cc_thead_dw2	is	%h	cc_thead_dw3	is	%h",	$realtime,	cc_thead_dw0,cc_thead_dw1,cc_thead_dw2,cc_thead_dw3);
			$display("%0t	:recv a pcie TLP : cc_tdata_dw0 is	%h	cc_tdata_dw1	is	%h	cc_tdata_dw2	is	%h	cc_tdata_dw3	is	%h",	$realtime,	cc_tdata_dw0,cc_tdata_dw1,cc_tdata_dw2,cc_tdata_dw3);
		end
	end

	always@(posedge	clk)	begin
		if(	rst	)	begin
			cc_hd_cnt	<=	0	;
			cc_thead_64	<=	64'h1234567887654321	;
		end	else	if(	cc_sof	)	begin
			cc_hd_cnt	<=	1	;
			cc_thead_64	<=	cc_tdata[0*64	+:	64]	;
		end	else	if(	cc_hd_cnt	==	1	)	begin
			cc_hd_cnt	<=	2	;
			cc_thead_64	<=	cc_thead_256[1*64	+:	64]	;
		end	else	if(	cc_hd_cnt	==	2	)	begin
			cc_hd_cnt	<=	3	;
			cc_thead_64	<=	cc_thead_256[2*64	+:	64]	;
		end	else	if(	cc_hd_cnt	==	3	)	begin
			cc_hd_cnt	<=	0	;
			cc_thead_64	<=	cc_thead_256[3*64	+:	64]	;
		end	else	begin
			cc_hd_cnt	<=	0	;
			cc_thead_64	<=	cc_thead_64				;
		end
	end

	reg		rq_sof_idle	=	0	;
	always@(posedge	clk)	rq_sof_idle	<=	rst	||	(	rq_tready	&&	rq_tvalid	&&	rq_tlast	)	?	1'b1	:	rq_tready	&&	rq_tvalid	?	0	:	rq_sof_idle	;
	wire	rq_sof	=	rq_sof_idle	&&	rq_tvalid	;

	reg		[PCIE_DW		-1:0]		rq_thead_256	=	0	;	always@(posedge	clk)	rq_thead_256	<=	rst	?	0	:	rq_sof	?	rq_tdata	:	rq_thead_256	;
	reg		[PCIE_DW	/4	-1:0]		rq_thead_64		=	0	;
	reg		[	2			-1:0]		rq_hd_cnt		=	0	;
	reg		[	8			-1:0]		rq_trvl_cnt		=	0	;	always@(posedge	clk)	rq_trvl_cnt	<=	rst	?	0	:	rq_tready&&rq_tvalid&&rq_tlast	?	rq_trvl_cnt	+1	:	rq_trvl_cnt	;

	reg	[	32	-1:0]	rq_thead_dw0	=	0	;	always@(posedge	clk)	rq_thead_dw0	<=	rst	?	0	:	rq_sof	?	rq_tdata[0*32+:32]	:	rq_thead_dw0	;
	reg	[	32	-1:0]	rq_thead_dw1	=	0	;	always@(posedge	clk)	rq_thead_dw1	<=	rst	?	0	:	rq_sof	?	rq_tdata[1*32+:32]	:	rq_thead_dw1	;
	reg	[	32	-1:0]	rq_thead_dw2	=	0	;	always@(posedge	clk)	rq_thead_dw2	<=	rst	?	0	:	rq_sof	?	rq_tdata[2*32+:32]	:	rq_thead_dw2	;
	reg	[	32	-1:0]	rq_thead_dw3	=	0	;	always@(posedge	clk)	rq_thead_dw3	<=	rst	?	0	:	rq_sof	?	rq_tdata[3*32+:32]	:	rq_thead_dw3	;
	reg	[	32	-1:0]	rq_tdata_dw3	=	0	;	always@(posedge	clk)	rq_tdata_dw3	<=	rst	?	0	:	rq_sof	?	rq_tdata[7*32+:32]	:	rq_tdata_dw3	;
	reg	[	32	-1:0]	rq_tdata_dw2	=	0	;	always@(posedge	clk)	rq_tdata_dw2	<=	rst	?	0	:	rq_sof	?	rq_tdata[6*32+:32]	:	rq_tdata_dw2	;
	reg	[	32	-1:0]	rq_tdata_dw1	=	0	;	always@(posedge	clk)	rq_tdata_dw1	<=	rst	?	0	:	rq_sof	?	rq_tdata[5*32+:32]	:	rq_tdata_dw1	;
	reg	[	32	-1:0]	rq_tdata_dw0	=	0	;	always@(posedge	clk)	rq_tdata_dw0	<=	rst	?	0	:	rq_sof	?	rq_tdata[4*32+:32]	:	rq_tdata_dw0	;

	always@(posedge	clk)	begin
		if(	rst	)	begin
			rq_hd_cnt	<=	0	;
			rq_thead_64	<=	64'h1234567887654321	;
		end	else	if(	rq_sof	)	begin
			rq_hd_cnt	<=	1	;
			rq_thead_64	<=	rq_tdata[0*64	+:	64]	;
		end	else	if(	rq_hd_cnt	==	1	)	begin
			rq_hd_cnt	<=	2	;
			rq_thead_64	<=	rq_thead_256[1*64	+:	64]	;
		end	else	if(	rq_hd_cnt	==	2	)	begin
			rq_hd_cnt	<=	3	;
			rq_thead_64	<=	rq_thead_256[2*64	+:	64]	;
		end	else	if(	rq_hd_cnt	==	3	)	begin
			rq_hd_cnt	<=	0	;
			rq_thead_64	<=	rq_thead_256[3*64	+:	64]	;
		end	else	begin
			rq_hd_cnt	<=	0	;
			rq_thead_64	<=	rq_thead_64				;
		end
	end


	reg		rc_sof_idle	=	0	;
	always@(posedge	clk)	rc_sof_idle	<=	rst	||	(	rc_tready	&&	rc_tvalid	&&	rc_tlast	)	?	1'b1	:	rc_tready	&&	rc_tvalid	?	0	:	rc_sof_idle	;
	wire	rc_sof	=	rc_sof_idle	&&	rc_tvalid	;

	reg		[PCIE_DW		-1:0]		rc_thead_256	=	0	;	always@(posedge	clk)	rc_thead_256	<=	rst	?	0	:	rc_sof	?	rc_tdata	:	rc_thead_256	;
	reg		[PCIE_DW	/4	-1:0]		rc_thead_64		=	0	;
	reg		[	2			-1:0]		rc_hd_cnt		=	0	;
	reg		[	8			-1:0]		rc_trvl_cnt		=	0	;	always@(posedge	clk)	rc_trvl_cnt	<=	rst	?	0	:	rc_tready&&rc_tvalid&&rc_tlast	?	rc_trvl_cnt	+1	:	rc_trvl_cnt	;

	reg	[	32	-1:0]	rc_thead_dw0	=	0	;	always@(posedge	clk)	rc_thead_dw0	<=	rst	?	0	:	rc_sof	?	rc_tdata[0*32+:32]	:	rc_thead_dw0	;
	reg	[	32	-1:0]	rc_thead_dw1	=	0	;	always@(posedge	clk)	rc_thead_dw1	<=	rst	?	0	:	rc_sof	?	rc_tdata[1*32+:32]	:	rc_thead_dw1	;
	reg	[	32	-1:0]	rc_thead_dw2	=	0	;	always@(posedge	clk)	rc_thead_dw2	<=	rst	?	0	:	rc_sof	?	rc_tdata[2*32+:32]	:	rc_thead_dw2	;
	reg	[	32	-1:0]	rc_thead_dw3	=	0	;	always@(posedge	clk)	rc_thead_dw3	<=	rst	?	0	:	rc_sof	?	rc_tdata[3*32+:32]	:	rc_thead_dw3	;
	reg	[	32	-1:0]	rc_tdata_dw3	=	0	;	always@(posedge	clk)	rc_tdata_dw3	<=	rst	?	0	:	rc_sof	?	rc_tdata[7*32+:32]	:	rc_tdata_dw3	;
	reg	[	32	-1:0]	rc_tdata_dw2	=	0	;	always@(posedge	clk)	rc_tdata_dw2	<=	rst	?	0	:	rc_sof	?	rc_tdata[6*32+:32]	:	rc_tdata_dw2	;
	reg	[	32	-1:0]	rc_tdata_dw1	=	0	;	always@(posedge	clk)	rc_tdata_dw1	<=	rst	?	0	:	rc_sof	?	rc_tdata[5*32+:32]	:	rc_tdata_dw1	;
	reg	[	32	-1:0]	rc_tdata_dw0	=	0	;	always@(posedge	clk)	rc_tdata_dw0	<=	rst	?	0	:	rc_sof	?	rc_tdata[4*32+:32]	:	rc_tdata_dw0	;

/*	synthesis	translate_off	*/

	reg	rc_sof_dly	=	0	;
	always@(posedge	clk)	rc_sof_dly	<=	rc_sof	;

	always@(posedge	clk)	begin
		if(	rc_sof_dly	)	begin
			$display("%0t	:recv a pcie TLP : rc_thead_dw0 is	%h	rc_thead_dw1	is	%h	rc_thead_dw2	is	%h	rc_thead_dw3	is	%h",	$realtime,	rc_thead_dw0,rc_thead_dw1,rc_thead_dw2,rc_thead_dw3);
			$display("%0t	:recv a pcie TLP : rc_tdata_dw0 is	%h	rc_tdata_dw1	is	%h	rc_tdata_dw2	is	%h	rc_tdata_dw3	is	%h",	$realtime,	rc_tdata_dw0,rc_tdata_dw1,rc_tdata_dw2,rc_tdata_dw3);
		end
	end

/*	synthesis	translate_on	*/

	always@(posedge	clk)	begin
		if(	rst	)	begin
			rc_hd_cnt	<=	0	;
			rc_thead_64	<=	64'h1234567887654321	;
		end	else	if(	rc_sof	)	begin
			rc_hd_cnt	<=	1	;
			rc_thead_64	<=	rc_tdata[0*64	+:	64]	;
		end	else	if(	rc_hd_cnt	==	1	)	begin
			rc_hd_cnt	<=	2	;
			rc_thead_64	<=	rc_thead_256[1*64	+:	64]	;
		end	else	if(	rc_hd_cnt	==	2	)	begin
			rc_hd_cnt	<=	3	;
			rc_thead_64	<=	rc_thead_256[2*64	+:	64]	;
		end	else	if(	rc_hd_cnt	==	3	)	begin
			rc_hd_cnt	<=	0	;
			rc_thead_64	<=	rc_thead_256[3*64	+:	64]	;
		end	else	begin
			rc_hd_cnt	<=	0	;
			rc_thead_64	<=	rc_thead_64				;
		end
	end

	reg			[	4	-	1	:	0]		sy0_srio_clk_cnt				,	sy1_srio_clk_cnt			,	sy2_srio_clk_cnt				;
	reg			[	12	-	1	:	0]		sy0_srio_iotx_trvl_cnt			,	sy1_srio_iotx_trvl_cnt		,	sy2_srio_iotx_trvl_cnt			;
	reg			[	12	-	1	:	0]		sy0_srio_iorx_trvl_cnt			,	sy1_srio_iorx_trvl_cnt		,	sy2_srio_iorx_trvl_cnt			;
	reg			[	2	-	1	:	0]		sy0_srio_port_error				,	sy1_srio_port_error			,	sy2_srio_port_error				;
	reg			[	2	-	1	:	0]		sy0_srio_port_initialized		,	sy1_srio_port_initialized	,	sy2_srio_port_initialized		;
	reg			[	2	-	1	:	0]		sy0_srio_link_initialized		,	sy1_srio_link_initialized	,	sy2_srio_link_initialized		;
	reg			[	2	-	1	:	0]		sy0_srio_mode_1x				,	sy1_srio_mode_1x			,	sy2_srio_mode_1x				;
	reg			[	2	-	1	:	0]		sy0_srio_force_reinit			,	sy1_srio_force_reinit		,	sy2_srio_force_reinit			;
	reg										sy0_sys_rst						,	sy1_sys_rst					,	sy2_sys_rst						;
	reg										sy0_sys_rst_n_in_c				,	sy1_sys_rst_n_in_c			,	sy2_sys_rst_n_in_c				;

	always@(posedge	clk)	sy0_srio_clk_cnt				<=	srio_clk_cnt				;
	always@(posedge	clk)	sy0_srio_iotx_trvl_cnt			<=	srio_iotx_trvl_cnt			;
	always@(posedge	clk)	sy0_srio_iorx_trvl_cnt			<=	srio_iorx_trvl_cnt			;
	always@(posedge	clk)	sy0_srio_port_error				<=	srio_port_error				;
	always@(posedge	clk)	sy0_srio_port_initialized		<=	srio_port_initialized		;
	always@(posedge	clk)	sy0_srio_link_initialized		<=	srio_link_initialized		;
	always@(posedge	clk)	sy0_srio_mode_1x				<=	srio_mode_1x				;
	always@(posedge	clk)	sy0_srio_force_reinit			<=	srio_force_reinit			;
	always@(posedge	clk)	sy0_sys_rst						<=	sys_rst						;
	always@(posedge	clk)	sy0_sys_rst_n_in_c				<=	sys_rst_n_in_c				;

	always@(posedge	clk)	sy1_srio_clk_cnt				<=	sy0_srio_clk_cnt				;
	always@(posedge	clk)	sy1_srio_iotx_trvl_cnt			<=	sy0_srio_iotx_trvl_cnt			;
	always@(posedge	clk)	sy1_srio_iorx_trvl_cnt			<=	sy0_srio_iorx_trvl_cnt			;
	always@(posedge	clk)	sy1_srio_port_error				<=	sy0_srio_port_error				;
	always@(posedge	clk)	sy1_srio_port_initialized		<=	sy0_srio_port_initialized		;
	always@(posedge	clk)	sy1_srio_link_initialized		<=	sy0_srio_link_initialized		;
	always@(posedge	clk)	sy1_srio_mode_1x				<=	sy0_srio_mode_1x				;
	always@(posedge	clk)	sy1_srio_force_reinit			<=	sy0_srio_force_reinit			;
	always@(posedge	clk)	sy1_sys_rst						<=	sy0_sys_rst						;
	always@(posedge	clk)	sy1_sys_rst_n_in_c				<=	sy0_sys_rst_n_in_c				;

	always@(posedge	clk)	sy2_srio_clk_cnt				<=	sy1_srio_clk_cnt				;
	always@(posedge	clk)	sy2_srio_iotx_trvl_cnt			<=	sy1_srio_iotx_trvl_cnt			;
	always@(posedge	clk)	sy2_srio_iorx_trvl_cnt			<=	sy1_srio_iorx_trvl_cnt			;
	always@(posedge	clk)	sy2_srio_port_error				<=	sy1_srio_port_error				;
	always@(posedge	clk)	sy2_srio_port_initialized		<=	sy1_srio_port_initialized		;
	always@(posedge	clk)	sy2_srio_link_initialized		<=	sy1_srio_link_initialized		;
	always@(posedge	clk)	sy2_srio_mode_1x				<=	sy1_srio_mode_1x				;
	always@(posedge	clk)	sy2_srio_force_reinit			<=	sy1_srio_force_reinit			;
	always@(posedge	clk)	sy2_sys_rst						<=	sy1_sys_rst						;
	always@(posedge	clk)	sy2_sys_rst_n_in_c				<=	sy1_sys_rst_n_in_c				;

/*
	vio_0 vio_0_5x128 (
	  .clk			(	clk		)	,	// input wire clk
	  .probe_in0	(
						{

							sy2_srio_port_error								,
							sy2_srio_port_initialized						,
							sy2_srio_link_initialized						,
							sy2_srio_mode_1x								,
							sy2_srio_force_reinit							,
							sy2_sys_rst										,
							sy2_sys_rst_n_in_c								,

							sy2_srio_clk_cnt								,
							sy2_srio_iotx_trvl_cnt[0+:12]					,
							sy2_srio_iorx_trvl_cnt[0+:12]					,
							sys_rst_n_c										,
							pcie_rst										,
							c_os_config										,
							c_os_big_endian									,
							pcie_far_id										,
							pcie_dev_id										,
							mmcm_lock                                        ,
							cfg_interrupt_msi_enable						,
							cfg_interrupt_msi_mmenable						,
							cfg_interrupt_msi_int							,
							cfg_max_payload									,
							cfg_max_read_req								,
							cfg_current_speed								,
							cfg_negotiated_width							,
							cfg_phy_link_down								,
							cfg_phy_link_status								,
							cfg_err_cor_out									,
							cfg_err_nonfatal_out							,
							cfg_err_fatal_out								,
							cfg_local_error									,
							user_lnk_up										,
							phy_rdy_out										,

							pcie_rq_tag					[	0	+:	6	]  	,
							pcie_rq_tag_vld									,
							pcie_rq_tag_av				[	0	+:	2	]  	,
							pcie_tfc_nph_av				[	0	+:	2	]  	,
							pcie_tfc_npd_av				[	0	+:	2	]  	,
							pcie_rq_seq_num				[	0	+:	4	]  	,
							pcie_rq_seq_num_vld								,
							pcie_cq_np_req_count		[	0	+:	6	]	,
							pcie_cq_np_req									,

							cq_trvl_cnt										,
							cc_trvl_cnt										,
							rq_trvl_cnt										,
							rc_trvl_cnt										,

							inter_req_cnt									,
							inter_send_cnt									,
							inter_fail_cnt									,
							inter_int_latch									,

							pcie_rq_tag_cnt									,

							pcie_clk_cnt[31:28]								}	) 	,
		.probe_in1	(
						{
							cq_thead_dw0	,
		                    cq_thead_dw1	,
		                    cq_thead_dw2	,
		                    cq_thead_dw3	,
		                    cq_tdata_dw3	,
		                    cq_tdata_dw2	,
		                    cq_tdata_dw1	,
		                    cq_tdata_dw0		}	) 	,
		.probe_in2	(
						{
							cc_thead_dw0	,
		                    cc_thead_dw1	,
		                    cc_thead_dw2	,
		                    cc_thead_dw3	,
		                    cc_tdata_dw3	,
		                    cc_tdata_dw2	,
		                    cc_tdata_dw1	,
		                    cc_tdata_dw0		}	) 	,

		.probe_in3	(
						{
							rq_thead_dw0	,
		                    rq_thead_dw1	,
		                    rq_thead_dw2	,
		                    rq_thead_dw3	,
		                    rq_tdata_dw3	,
		                    rq_tdata_dw2	,
		                    rq_tdata_dw1	,
		                    rq_tdata_dw0		}	) 	,
		.probe_in4	(
						{
							rc_thead_dw0	,
		                    rc_thead_dw1	,
		                    rc_thead_dw2	,
		                    rc_thead_dw3	,
		                    rc_tdata_dw3	,
		                    rc_tdata_dw2	,
		                    rc_tdata_dw1	,
		                    rc_tdata_dw0		}	),
		                    
		.probe_out0( 		soft_rst	)                    
		                    
		                    
		                    

	);      
	



  	ila_576X1024 ila_axis (
  		.clk		(	clk		)	, // input wire clk
  		.probe0		(
  						{
  
  
  
  
  							pcie_rq_tag									,
  							pcie_rq_tag_vld								,
  							pcie_rq_tag_av								,
  							pcie_tfc_nph_av								,
  							pcie_tfc_npd_av								,
  							pcie_rq_seq_num								,
  							pcie_rq_seq_num_vld							,
  
  							pcie_cq_np_req_count						,
  							pcie_cq_np_req								,
  
  							s_axis_cc_tuser								,
  
                              rq_trvl_cnt									,
                              rc_trvl_cnt									,
                              cc_trvl_cnt									,
  							cq_trvl_cnt									,
  
  							m_axis_rc_tkeep								,
  							m_axis_rc_tuser								,
  
  							s_axis_cc_tkeep								,
  
  							s_axis_rq_tkeep								,
  							s_axis_rq_tuser								,
  
  							m_axis_cq_tkeep								,
  							m_axis_cq_tuser								,
  
  							m_axis_rc_tready							,
  							m_axis_rc_tvalid							,
  							m_axis_rc_tlast								,
  					//		m_axis_rc_tdata								,
  
  							s_axis_cc_tvalid							,
  							s_axis_cc_tready							,
  					//		s_axis_cc_tdata								,
  							s_axis_cc_tlast								,
  
  
  							s_axis_rq_tvalid							,
  							s_axis_rq_tready							,
  					//		s_axis_rq_tdata								,
  							s_axis_rq_tlast								,
  
  					//		m_axis_cq_tdata								,
  							m_axis_cq_tready							,
  							m_axis_cq_tvalid							,
  							m_axis_cq_tlast								,
  
  							rq_sof										,
  					//		rq_thead_256								,
  							rq_thead_64									,
  							rq_hd_cnt									,
  
  							rc_sof										,
  					//		rc_thead_256								,
  							rc_thead_64									,
  							rc_hd_cnt									,
  
  							cq_sof										,
  					//		cq_thead_256								,
  							cq_thead_64									,
  							cq_hd_cnt									,
  
  							cc_sof										,
  					//		cc_thead_256								,
  							cc_thead_64									,
  							cc_hd_cnt
  
  						}
  					) 	// input wire [1051:0] probe0
  	);        	    
              */	

endmodule