
module	srio_gt_support
	#(
		parameter	P_DEVICE_TYPE_R			=	"XLNX_KU"	,
		parameter	TCQ						=	100			,	//	in	pS
		parameter	LINK_WIDTH				=	4			,
		parameter	IPCORE_NUM				=	1			
	)
	(
	//	port	declarations	----------------
	//	Clocks	and	Resets
		input	wire												sys_clkp					,	
		input	wire												sys_clkn					,	
		input	wire												sys_rst						,	
																						
	//	high-speed	IO																		
		input	wire	[IPCORE_NUM	*	LINK_WIDTH		-1:0]		srio_rxn					,	
		input	wire	[IPCORE_NUM	*	LINK_WIDTH		-1:0]		srio_rxp					,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH		-1:0]		srio_txn					,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH		-1:0]		srio_txp					,	
																			
		input	wire	[IPCORE_NUM	*	01				-1:0]		any_gtrxaligned				,	
		input	wire	[IPCORE_NUM	*	01				-1:0]		force_reinit				,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		controlled_force_reinit		,	
								
		output	wire	[IPCORE_NUM	*	01				-1:0]		gt_rst						,	
		output	wire												gt_clk						,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		log_rst						,	
		output	wire												log_clk						,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		phy_rst						,	
		output	wire												phy_clk						,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		gt_pcs_rst					,	
		output	wire												gt_pcs_clk					,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH*4*8	-1:0]		gtrx_data					,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_charisk				,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_chariscomma			,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_disperr				,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH*4	-1:0]		gtrx_notintable				,	
																				
		output	wire	[IPCORE_NUM	*	LINK_WIDTH		-1:0]		gtrx_chanisaligned			,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		gtrx_reset_req				,	
		output	wire	[IPCORE_NUM	*	LINK_WIDTH		-1:0]		gtrx_reset_done				,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		gtrx_reset					,	
		output	wire	[IPCORE_NUM	*	01				-1:0]		gtrx_chanbonden				

	);

	//------------------------Parameter----------------------

	//------------------------Local	signal-------------------

		wire								gt0_qpll_clk				;
		wire								gt0_qpll_out_refclk			;
		wire								gt0_qpll_lock				;

		wire								mode_1x						;

//		wire								log_clk						;
//		wire								phy_clk						;
//		wire								gt_clk						;
		wire								refclk						;
		wire								drpclk						;
		wire								clk_lock					;

		wire	[IPCORE_NUM	*	1				-	1:0]		cfg_rst						;
//		wire	[IPCORE_NUM	*	1				-	1:0]		log_rst							;
		wire	[IPCORE_NUM	*	1				-	1:0]		buf_rst						;
//		wire	[IPCORE_NUM	*	1				-	1:0]		phy_rst						;

		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_txpmareset_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxpmareset_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_txpcsreset_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxpcsreset_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_eyescanreset_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_eyescantrigger_in		;
																						
		wire	[IPCORE_NUM	*	LINK_WIDTH	*03	-	1:0]		gt_loopback_in				;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxpolarity_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_txpolarity_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxlpmen_in				;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*05	-	1:0]		gt_txprecursor_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*05	-	1:0]		gt_txpostcursor_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*04	-	1:0]		gt_txdiffctrl_in			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_txprbsforceerr_in		;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*03	-	1:0]		gt_txprbssel_in				;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*03	-	1:0]		gt_rxprbssel_in				;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxprbscntreset_in		;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxcdrhold_in				;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxdfelpmreset_in			;
																						
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_eyescandataerror_out		;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxprbserr_out			;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*08	-	1:0]		gt_dmonitorout_out			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxcommadet_out			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_rxresetdone_out			;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_txresetdone_out			;
																						
		wire	[IPCORE_NUM	*	LINK_WIDTH	*02	-	1:0]		gt_txbufstatus_out			;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*03	-	1:0]		gt_rxbufstatus_out			;
																						
		wire	[IPCORE_NUM	*	LINK_WIDTH	*16	-	1:0]		gt_drpdo_out				;
		wire	[IPCORE_NUM	*	LINK_WIDTH		-	1:0]		gt_drprdy_out				;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*09	-	1:0]		gt_drpaddr_in				;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*16	-	1:0]		gt_drpdi_in					;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*01	-	1:0]		gt_drpen_in					;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*01	-	1:0]		gt_drpwe_in					;
																							
		wire	[IPCORE_NUM	*	LINK_WIDTH	*4*8	-1:0]		gttx_data					;
		wire	[IPCORE_NUM	*	LINK_WIDTH	*4		-1:0]		gttx_charisk				;
		wire	[IPCORE_NUM	*	LINK_WIDTH			-1:0]		gttx_inhibit				;

	//------------------------Body---------------------------

		wire	[IPCORE_NUM	*	1			-1:0]		txoutclk		;		
	//	wire	[IPCORE_NUM	*	1			-1:0]		gt_rst			;		
		wire											freerun_clk		;	// GT free run clock
		wire	[IPCORE_NUM	*	LINK_WIDTH	-1:0]		gtpowergood_out	;	// GT POWER GOOD


//	assign	mode_1x	=
//	`ifdef	LINK2	
//					1'b0	;
//	`else
//					1'b1	;
//	`endif
	assign	mode_1x	=	LINK_WIDTH	==	1	?	1'b1	:	1'b0		;
	//------------------------Instantiation------------------

genvar	ii;
generate	if(P_DEVICE_TYPE_R	==	"XLNX_V7")	begin
//	clock	share	in	neighbouring	bank
	`ifdef	SRIO_TYPE_1G1X8B	srio_gen2_1g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_gen2_1g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_gen2_1g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_gen2_2g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_gen2_2g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_gen2_2g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_gen2_3g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_gen2_3g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_gen2_3g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_gen2_5g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_gen2_5g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_gen2_5g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_gen2_6g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_gen2_6g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_gen2_6g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_gen2_1g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_gen2_1g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_gen2_1g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_gen2_2g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_gen2_2g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_gen2_2g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_gen2_3g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_gen2_3g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_gen2_3g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_gen2_5g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_gen2_5g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_gen2_5g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_gen2_6g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_gen2_6g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_gen2_6g_4x_gt_srio_clk		`endif	
	i_srio_gen2_0_srio_clk
	(
		.sys_clkp					(	sys_clkp				),
		.sys_clkn					(	sys_clkn				),
		.sys_rst					(	sys_rst					),

		.mode_1x					(	mode_1x					),

		.log_clk					(	log_clk					),
		.phy_clk					(	phy_clk					),

		.gt_clk						(	gt_clk					),
		.gt_pcs_clk					(	gt_pcs_clk				),
		.refclk						(	refclk					),
		.drpclk						(	drpclk					),

		.clk_lock					(	clk_lock				)
	);

//	gt***_common	share	in	bank
	`ifdef	SRIO_TYPE_1G1X8B	srio_gen2_1g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_gen2_1g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_gen2_1g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_gen2_2g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_gen2_2g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_gen2_2g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_gen2_3g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_gen2_3g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_gen2_3g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_gen2_5g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_gen2_5g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_gen2_5g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_gen2_6g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_gen2_6g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_gen2_6g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_gen2_1g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_gen2_1g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_gen2_1g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_gen2_2g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_gen2_2g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_gen2_2g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_gen2_3g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_gen2_3g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_gen2_3g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_gen2_5g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_gen2_5g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_gen2_5g_4x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_gen2_6g_1x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_gen2_6g_2x_gt_v7_gthe2_common		`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_gen2_6g_4x_gt_v7_gthe2_common		`endif
	i_srio_gen2_gthe2_common(
	//	.gt0_gtrefclk0_common_in	(	refclk					),
	//	.gt0_qplllockdetclk_in		(	drpclk					),
	//	.gt0_qpllreset_in			(	gt_pcs_rst				),
	//	.qpll_clk_out				(	gt0_qpll_clk				),
	//	.qpll_out_refclk_out		(	gt0_qpll_out_refclk		),
	//	.gt0_qpll_lock_out			(	gt0_qpll_lock				)	
		
			.GTREFCLK0_IN		(refclk),			//	input		GTREFCLK0_IN
			.QPLLLOCKDETCLK_IN	(drpclk),			//	input		QPLLLOCKDETCLK_IN
			.QPLLRESET_IN		(gt_pcs_rst),		//	input		QPLLRESET_IN
			.QPLLLOCK_OUT		(gt0_qpll_lock),	//	output		QPLLLOCK_OUT
			.QPLLOUTCLK_OUT		(gt0_qpll_clk),		//	output		QPLLOUTCLK_OUT
			.QPLLOUTREFCLK_OUT	(gt0_qpll_out_refclk),	//	output		QPLLOUTREFCLK_OUT
			.QPLLREFCLKLOST_OUT	()						//	output		QPLLREFCLKLOST_OUT
		
	);
	
	for(ii=0;ii<IPCORE_NUM;ii=ii+1)	begin	:	i_srgt
	`ifdef	SRIO_TYPE_1G1X8B	srio_gt_wrapper_srio_gen2_1g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_gt_wrapper_srio_gen2_1g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_gt_wrapper_srio_gen2_1g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_gt_wrapper_srio_gen2_2g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_gt_wrapper_srio_gen2_2g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_gt_wrapper_srio_gen2_2g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_gt_wrapper_srio_gen2_3g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_gt_wrapper_srio_gen2_3g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_gt_wrapper_srio_gen2_3g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_gt_wrapper_srio_gen2_5g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_gt_wrapper_srio_gen2_5g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_gt_wrapper_srio_gen2_5g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_gt_wrapper_srio_gen2_6g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_gt_wrapper_srio_gen2_6g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_gt_wrapper_srio_gen2_6g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_gt_wrapper_srio_gen2_1g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_gt_wrapper_srio_gen2_1g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_gt_wrapper_srio_gen2_1g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_gt_wrapper_srio_gen2_2g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_gt_wrapper_srio_gen2_2g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_gt_wrapper_srio_gen2_2g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_gt_wrapper_srio_gen2_3g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_gt_wrapper_srio_gen2_3g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_gt_wrapper_srio_gen2_3g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_gt_wrapper_srio_gen2_5g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_gt_wrapper_srio_gen2_5g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_gt_wrapper_srio_gen2_5g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_gt_wrapper_srio_gen2_6g_1x_gt_v7_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_gt_wrapper_srio_gen2_6g_2x_gt_v7_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_gt_wrapper_srio_gen2_6g_4x_gt_v7_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
//	#(
//		.TCQ						(	100						),
//		.LINK_WIDTH					(	LINK_WIDTH				)
//	)
	i_srio_gt_wrapper_srio_gen2_7
	(
		.gt_qplloutclk_in			(	gt0_qpll_clk								),
		.gt_qplloutrefclk_in		(	gt0_qpll_out_refclk						),
				
		.refclk						(	refclk									),
		.drpclk						(	drpclk									),
		.gt_pcs_rst					(	gt_pcs_rst								),
		.gt_pcs_clk					(	gt_pcs_clk								),
				
		.gt_txpmareset_in			(	gt_txpmareset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxpmareset_in			(	gt_rxpmareset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txpcsreset_in			(	gt_txpcsreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxpcsreset_in			(	gt_rxpcsreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_eyescanreset_in			(	gt_eyescanreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_eyescantrigger_in		(	gt_eyescantrigger_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_eyescandataerror_out	(	gt_eyescandataerror_out		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_loopback_in				(	gt_loopback_in				[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
		.gt_rxpolarity_in			(	gt_rxpolarity_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txpolarity_in			(	gt_txpolarity_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxlpmen_in				(	gt_rxlpmen_in				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txprecursor_in			(	gt_txprecursor_in			[	ii*	LINK_WIDTH	*05	+:	LINK_WIDTH	*05]			),
		.gt_txpostcursor_in			(	gt_txpostcursor_in			[	ii*	LINK_WIDTH	*05	+:	LINK_WIDTH	*05]			),
		
		.gt0_txdiffctrl_in			(	gt_txdiffctrl_in			[00+ii*	LINK_WIDTH	*04	+:04]			),
	`ifdef	SRIO_2_LANE												
		.gt1_txdiffctrl_in			(	gt_txdiffctrl_in			[04+ii*	LINK_WIDTH	*04	+:04]			),
	`elsif	SRIO_4_LANE														
		.gt1_txdiffctrl_in			(	gt_txdiffctrl_in			[04+ii*	LINK_WIDTH	*04	+:04]			),
		.gt2_txdiffctrl_in			(	gt_txdiffctrl_in			[08+ii*	LINK_WIDTH	*04	+:04]			),
		.gt3_txdiffctrl_in			(	gt_txdiffctrl_in			[12+ii*	LINK_WIDTH	*04	+:04]			),
	`endif		
		.gt_txprbsforceerr_in		(	gt_txprbsforceerr_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txprbssel_in			(	gt_txprbssel_in				[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
		.gt_rxprbssel_in			(	gt_rxprbssel_in				[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
		.gt_rxprbserr_out			(	gt_rxprbserr_out			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxprbscntreset_in		(	gt_rxprbscntreset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxcdrhold_in			(	gt_rxcdrhold_in				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_dmonitorout_out			(	gt_dmonitorout_out			[	ii*	LINK_WIDTH	*08	+:	LINK_WIDTH	*08]			),
		.gt_rxdfelpmreset_in		(	gt_rxdfelpmreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxcommadet_out			(	gt_rxcommadet_out			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxresetdone_out			(	gt_rxresetdone_out			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txresetdone_out			(	gt_txresetdone_out			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
				
		.gt_txbufstatus_out			(	gt_txbufstatus_out			[	ii*	LINK_WIDTH	*02	+:	LINK_WIDTH	*02]			),
		.gt_rxbufstatus_out			(	gt_rxbufstatus_out			[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
				
		.gt_drpdo_out				(	gt_drpdo_out				[	ii*	LINK_WIDTH	*16	+:	LINK_WIDTH	*16]			),
		.gt_drprdy_out				(	gt_drprdy_out				[	ii*	01			*01	+:	01			*01]			),
		.gt_drpaddr_in				(	gt_drpaddr_in				[	ii*	LINK_WIDTH	*09	+:	LINK_WIDTH	*09]			),
		.gt_drpdi_in				(	gt_drpdi_in					[	ii*	LINK_WIDTH	*16	+:	LINK_WIDTH	*16]			),
		.gt_drpen_in				(	gt_drpen_in					[	ii*	01			*01	+:	01			*01]			),
		.gt_drpwe_in				(	gt_drpwe_in					[	ii*	01			*01	+:	01			*01]			),
				
		.gt_clk						(	gt_clk																),
		.clk_lock					(	clk_lock															),

		.srio_rxn0					(	srio_rxn					[	ii*	LINK_WIDTH	+0	+:	1]			),
		.srio_rxp0					(	srio_rxp					[	ii*	LINK_WIDTH	+0	+:	1]			),
		.srio_txn0					(	srio_txn					[	ii*	LINK_WIDTH	+0	+:	1]			),
		.srio_txp0					(	srio_txp					[	ii*	LINK_WIDTH	+0	+:	1]			),
	`ifdef	SRIO_2_LANE																						
		.srio_rxn1					(	srio_rxn					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_rxp1					(	srio_rxp					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_txn1					(	srio_txn					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_txp1					(	srio_txp					[	ii*	LINK_WIDTH	+1	+:	1]			),		
	`elsif	SRIO_4_LANE																							
		.srio_rxn1					(	srio_rxn					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_rxp1					(	srio_rxp					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_txn1					(	srio_txn					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_txp1					(	srio_txp					[	ii*	LINK_WIDTH	+1	+:	1]			),
		.srio_rxn2					(	srio_rxn					[	ii*	LINK_WIDTH	+2	+:	1]			),
		.srio_rxp2					(	srio_rxp					[	ii*	LINK_WIDTH	+2	+:	1]			),
		.srio_txn2					(	srio_txn					[	ii*	LINK_WIDTH	+2	+:	1]			),
		.srio_txp2					(	srio_txp					[	ii*	LINK_WIDTH	+2	+:	1]			),
		.srio_rxn3					(	srio_rxn					[	ii*	LINK_WIDTH	+3	+:	1]			),
		.srio_rxp3					(	srio_rxp					[	ii*	LINK_WIDTH	+3	+:	1]			),
		.srio_txn3					(	srio_txn					[	ii*	LINK_WIDTH	+3	+:	1]			),
		.srio_txp3					(	srio_txp					[	ii*	LINK_WIDTH	+3	+:	1]			),			
	`endif
		.gtrx_data					(	gtrx_data					[	ii*	LINK_WIDTH	*32	+:	LINK_WIDTH	*32]			),
		.gtrx_charisk				(	gtrx_charisk				[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			),
		.gtrx_chariscomma			(	gtrx_chariscomma			[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			),
		.gtrx_disperr				(	gtrx_disperr				[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			),
		.gtrx_notintable			(	gtrx_notintable				[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			),
		.gttx_inhibit				(	gttx_inhibit				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gtrx_chanisaligned			(	gtrx_chanisaligned			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gtrx_reset_req				(	gtrx_reset_req				[	ii*	01			*01	+:	01			*01]			),
		.gtrx_reset_done			(	gtrx_reset_done				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gtrx_reset					(	gtrx_reset					[	ii*	01			*01	+:	01			*01]			),
		.gtrx_chanbonden			(	gtrx_chanbonden				[	ii*	01			*01	+:	01			*01]			),
		.gttx_data					(	gttx_data					[	ii*	LINK_WIDTH	*32	+:	LINK_WIDTH	*32]			),
		.gttx_charisk				(	gttx_charisk				[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			)
	);


	srio_gen2_0_7s_gt_top_glu
	#(
		.LINK_WIDTH					(	LINK_WIDTH				)
	)
	i_srio_gen2_0_7s_gt_top_glu
	(
		.gt_txpmareset_in			(	gt_txpmareset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxpmareset_in			(	gt_rxpmareset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txpcsreset_in			(	gt_txpcsreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxpcsreset_in			(	gt_rxpcsreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_eyescanreset_in			(	gt_eyescanreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_eyescantrigger_in		(	gt_eyescantrigger_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
																						
		.gt_loopback_in				(	gt_loopback_in				[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
		.gt_rxpolarity_in			(	gt_rxpolarity_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txpolarity_in			(	gt_txpolarity_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxlpmen_in				(	gt_rxlpmen_in				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txprecursor_in			(	gt_txprecursor_in			[	ii*	LINK_WIDTH	*05	+:	LINK_WIDTH	*05]			),
		.gt_txpostcursor_in			(	gt_txpostcursor_in			[	ii*	LINK_WIDTH	*05	+:	LINK_WIDTH	*05]			),
		.gt_txdiffctrl_in			(	gt_txdiffctrl_in			[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			),
		.gt_txprbsforceerr_in		(	gt_txprbsforceerr_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_txprbssel_in			(	gt_txprbssel_in				[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
		.gt_rxprbssel_in			(	gt_rxprbssel_in				[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]			),
		.gt_rxprbscntreset_in		(	gt_rxprbscntreset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxcdrhold_in			(	gt_rxcdrhold_in				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_rxdfelpmreset_in		(	gt_rxdfelpmreset_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
																						
		.gt_drpdo_out				(	gt_drpdo_out				[	ii*	LINK_WIDTH	*16	+:	LINK_WIDTH	*16]			),
		.gt_drprdy_out				(	gt_drprdy_out				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_drpaddr_in				(	gt_drpaddr_in				[	ii*	LINK_WIDTH	*09	+:	LINK_WIDTH	*09]			),
		.gt_drpdi_in				(	gt_drpdi_in					[	ii*	LINK_WIDTH	*16	+:	LINK_WIDTH	*16]			),
		.gt_drpen_in				(	gt_drpen_in					[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
		.gt_drpwe_in				(	gt_drpwe_in					[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]			),
																						
		.gttx_data					(	gttx_data					[	ii*	LINK_WIDTH	*32	+:	LINK_WIDTH	*32]			),
		.gttx_charisk				(	gttx_charisk				[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]			)

	);	//srio_gen2_bm_top_glu

	`ifdef	SRIO_TYPE_1G1X8B	srio_gen2_1g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_gen2_1g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_gen2_1g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_gen2_2g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_gen2_2g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_gen2_2g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_gen2_3g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_gen2_3g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_gen2_3g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_gen2_5g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_gen2_5g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_gen2_5g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_gen2_6g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_gen2_6g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_gen2_6g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_gen2_1g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_gen2_1g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_gen2_1g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_gen2_2g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_gen2_2g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_gen2_2g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_gen2_3g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_gen2_3g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_gen2_3g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_gen2_5g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_gen2_5g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_gen2_5g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_gen2_6g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_gen2_6g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_gen2_6g_4x_gt_srio_rst		`endif
	i_srio_gen2_srio_rst
	(
		.cfg_clk					(	log_clk										),
		.log_clk					(	log_clk										),
		.phy_clk					(	phy_clk										),
		.gt_pcs_clk					(	gt_pcs_clk									),
						
		.sys_rst					(	sys_rst	||force_reinit	[ii*	1	+:	1]	),
		.force_reinit				(	1'b0										),
		.clk_lock					(	clk_lock									),
						
		.controlled_force_reinit	(	controlled_force_reinit	[ii*	1	+:	1]	),
				
		.port_initialized			(	any_gtrxaligned			[ii*	1	+:	1]	),
		.phy_rcvd_link_reset		(	1'b0										),
				
		.cfg_rst					(	cfg_rst					[ii*	1	+:	1]	),
		.log_rst					(	log_rst					[ii*	1	+:	1]	),
		.buf_rst					(	buf_rst					[ii*	1	+:	1]	),
		.phy_rst					(	phy_rst					[ii*	1	+:	1]	),
		.gt_pcs_rst					(	gt_pcs_rst				[ii*	1	+:	1]	)
	);


end	//	for	loop
end	else	if(P_DEVICE_TYPE_R	==	"XLNX_KU")	begin//	if

//	clock	share	in	neighbouring	bank
	`ifdef	SRIO_TYPE_1G1X8B	srio_1g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_1g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_1g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_2g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_2g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_2g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_3g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_3g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_3g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_5g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_5g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_5g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_6g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_6g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_6g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_1g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_1g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_1g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_2g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_2g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_2g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_3g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_3g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_3g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_5g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_5g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_5g_4x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_6g_1x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_6g_2x_gt_srio_clk		`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_6g_4x_gt_srio_clk		`endif
	i_srio_gen2_0_srio_clk
	(
		.	sys_clkp			(	sys_clkp						)	,	//	input			
		.	sys_clkn			(	sys_clkn						)	,	//	input			
		.	txoutclk			(	txoutclk					[0]	)	,	//	input			
		.	gtpowergood_out		(	&(gtpowergood_out)				)	,	//	input			
		.	gt_txpmaresetdone	(	1'b0							)	,	//	input	[0:0]	
		.	freerun_clk			(	freerun_clk						)	,	//	output			
		.	sys_rst				(	sys_rst							)	,	//	input			
		.	mode_1x				(	mode_1x							)	,	//	input			
		.	log_clk				(	log_clk							)	,	//	output			
		.	phy_clk				(	phy_clk							)	,	//	output			
		.	gt_pcs_clk			(	gt_pcs_clk						)	,	//	output			
		.	gt_clk				(	gt_clk							)	,	//	output			
		.	refclk				(	refclk							)	,	//	output			
		.	clk_lock            (	clk_lock            			)		//	output			
	);

	for(ii=0;ii<IPCORE_NUM;ii=ii+1)	begin	:	i_srgt
	`ifdef	SRIO_TYPE_1G1X8B	srio_gt_wrapper_srio_1g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_gt_wrapper_srio_1g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_gt_wrapper_srio_1g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_gt_wrapper_srio_2g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_gt_wrapper_srio_2g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_gt_wrapper_srio_2g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_gt_wrapper_srio_3g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_gt_wrapper_srio_3g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_gt_wrapper_srio_3g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_gt_wrapper_srio_5g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_gt_wrapper_srio_5g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_gt_wrapper_srio_5g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_gt_wrapper_srio_6g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_gt_wrapper_srio_6g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_gt_wrapper_srio_6g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_gt_wrapper_srio_1g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_gt_wrapper_srio_1g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_gt_wrapper_srio_1g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_gt_wrapper_srio_2g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_gt_wrapper_srio_2g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_gt_wrapper_srio_2g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_gt_wrapper_srio_3g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_gt_wrapper_srio_3g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_gt_wrapper_srio_3g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_gt_wrapper_srio_5g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_gt_wrapper_srio_5g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_gt_wrapper_srio_5g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_gt_wrapper_srio_6g_1x_gt_US_1x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_gt_wrapper_srio_6g_2x_gt_US_2x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_gt_wrapper_srio_6g_4x_gt_US_4x		#(.TCQ(100),.LINK_WIDTH(LINK_WIDTH))	`endif
//	#(
//		.TCQ						(	100						),
//		.LINK_WIDTH					(	LINK_WIDTH				)
//	)
	i_srio_gt_wrapper_srio_gen2_7
	(
		.	refclk                 		(	refclk																		)	,
		.	gt_clk                 		(	gt_clk       																)	,
		.	gt_pcs_clk             		(	gt_pcs_clk   																)	,
		.	gt_pcs_rst             		(	gt_pcs_rst   																)	,
		.	clk_lock               		(	clk_lock															)	,
		.	srio_rxn0              		(	srio_rxn    				[	ii* LINK_WIDTH	+0	+: 1]					)	,
		.	srio_rxp0              		(	srio_rxp    				[	ii* LINK_WIDTH	+0	+: 1]					)	,
		.	srio_txn0              		(	srio_txn					[	ii* LINK_WIDTH	+0	+: 1]					)	,
		.	srio_txp0              		(	srio_txp					[	ii* LINK_WIDTH	+0	+: 1]					)	,
	`ifdef	SRIO_2_LANE								                    	       	     							
		.	srio_rxn1              		(	srio_rxn					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_rxp1              		(	srio_rxp					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_txn1              		(	srio_txn					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_txp1              		(	srio_txp					[	ii* LINK_WIDTH	+1	+: 1]					)	,
	`elsif	SRIO_4_LANE											         	       	     							
		.	srio_rxn1              		(	srio_rxn					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_rxp1              		(	srio_rxp					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_txn1              		(	srio_txn					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_txp1              		(	srio_txp					[	ii* LINK_WIDTH	+1	+: 1]					)	,
		.	srio_rxn2              		(	srio_rxn					[	ii* LINK_WIDTH	+2	+: 1]					)	,
		.	srio_rxp2              		(	srio_rxp					[	ii* LINK_WIDTH	+2	+: 1]					)	,
		.	srio_txn2              		(	srio_txn					[	ii* LINK_WIDTH	+2	+: 1]					)	,
		.	srio_txp2              		(	srio_txp					[	ii* LINK_WIDTH	+2	+: 1]					)	,
		.	srio_rxn3              		(	srio_rxn					[	ii* LINK_WIDTH	+3	+: 1]					)	,
		.	srio_rxp3              		(	srio_rxp					[	ii* LINK_WIDTH	+3	+: 1]					)	,
		.	srio_txn3              		(	srio_txn					[	ii* LINK_WIDTH	+3	+: 1]					)	,
		.	srio_txp3              		(	srio_txp					[	ii* LINK_WIDTH	+3	+: 1]					)	,
	`endif												
		.	gt_drpaddr_in          		(	36'b0																		)	,
		.	gt_drpdi_in            		(	64'b0																		)	,
		.	gt_drpen_in            		(	4'b0																		)	,
		.	gt_drpwe_in            		(	4'b0																		)	,
		.	gt_drpdo_out           		(																				)	,
		.	gt_drprdy_out          		(																				)	,
		.	gt_pcsrsvdin_in        		(	64'b0																		)	,
		.	gt_gttxreset_in        		(	4'b0																		)	,
		.	gt_txpmareset_in       		(	4'b0																		)	,
		.	gt_txpcsreset_in       		(	4'b0																		)	,
		.	gt_txresetdone_out     		(																				)	,
		.	gt_rxpmareset_in       		(	4'b0																		)	,
		.	gt_rxpcsreset_in       		(	4'b0																		)	,
		.	gt_rxresetdone_out     		(																				)	,
		.	gt_rxpmaresetdone_out  		(																				)	,
		.	gt_txbufstatus_out     		(																				)	,
		.	gt_rxbufstatus_out     		(																				)	,
		.	gt_rxrate_in           		(	12'b0																		)	,
		.	gt_eyescantrigger_in   		(	4'b0																		)	,
		.	gt_eyescanreset_in     		(	4'b0																		)	,
		.	gt_eyescandataerror_out		(																				)	,
		.	gt_loopback_in         		(	12'b0																		)	,
		.	gt_rxpolarity_in       		(	4'b0																		)	,
		.	gt_txpolarity_in       		(	4'b0																		)	,
		.	gt_rxdfelpmreset_in    		(	4'b0																		)	,
		.	gt_rxlpmen_in          		(	4'b1111																		)	,
		.	gt_txprecursor_in      		(	20'b0																		)	,
		.	gt_txpostcursor_in     		(	20'b0																		)	,
		.	gt0_txdiffctrl_in      		(	4'b1000																		)	,
	`ifdef	SRIO_2_LANE 												
		.	gt1_txdiffctrl_in      		(	4'b1000																		)	,
	`elsif	SRIO_4_LANE													
		.	gt1_txdiffctrl_in      		(	4'b1000																		)	,
		.	gt2_txdiffctrl_in      		(	4'b1000																		)	,
		.	gt3_txdiffctrl_in      		(	4'b1000																		)	,
	`endif												
		.	gt_txprbsforceerr_in   		(	4'b0																		)	,
		.	gt_txprbssel_in        		(	12'b0																		)	,
		.	gt_rxprbssel_in        		(	12'b0																		)	,
		.	gt_rxprbserr_out       		(																				)	,
		.	gt_rxprbscntreset_in   		(	4'b0																		)	,
		.	gt_rxcdrhold_in        		(	4'b0																		)	,
		.	gt_dmonitorout_out     		(																				)	,
		.	gt_rxcommadet_out      		(																				)	,
		.	gt_txpmaresetdone_out  		(						  														)	, // output          gt_txpmaresetdone_out,
		.	txoutclk               		(	txoutclk             	[ii* 1 +: 1]										)	, // TXOUTCLK for BUFG_GTs
		.	freerun_clk            		(	freerun_clk          														)	, // GT freerun clock 
		.	gtpowergood_out        		(	gtpowergood_out		    [	ii* LINK_WIDTH	*01	+: LINK_WIDTH	*01]		)	, // output          gt_txresetdone_out,
		.	gt_rst                 		(	gt_rst               	[	ii* 01			*01	+: 01			*01]		)	, // GT reset
		.	gtrx_data			    	(	gtrx_data			   	[	ii* LINK_WIDTH	*32	+: LINK_WIDTH	*32]		)	,
		.	gtrx_charisk		    	(	gtrx_charisk		   	[	ii* LINK_WIDTH	*04	+: LINK_WIDTH	*04]		)	,
		.	gtrx_chariscomma	    	(	gtrx_chariscomma	   	[	ii* LINK_WIDTH	*04	+: LINK_WIDTH	*04]		)	,
		.	gtrx_disperr		    	(	gtrx_disperr		   	[	ii* LINK_WIDTH	*04	+: LINK_WIDTH	*04]		)	,
		.	gtrx_notintable		    	(	gtrx_notintable		   	[	ii* LINK_WIDTH	*04	+: LINK_WIDTH	*04]		)	,
		.	gttx_inhibit		    	(	gttx_inhibit		   	[	ii* LINK_WIDTH	*01	+: LINK_WIDTH	*01]		)	,
		.	gtrx_chanisaligned	    	(	gtrx_chanisaligned	   	[	ii* LINK_WIDTH	*01	+: LINK_WIDTH	*01]		)	,
		.	gtrx_reset_req		    	(	gtrx_reset_req		   	[	ii* 01			*01	+: 01			*01]		)	,
		.	gtrx_reset_done		    	(	gtrx_reset_done		   	[	ii* LINK_WIDTH	*01	+: LINK_WIDTH	*01]		)	,
		.	gtrx_reset			    	(	gtrx_reset			   	[	ii* 01			*01	+: 01			*01]		)	,
		.	gtrx_chanbonden		    	(	gtrx_chanbonden		   	[	ii* 01			*01	+: 01			*01]		)	,
		.	gttx_data			    	(	gttx_data			   	[	ii* LINK_WIDTH	*32	+: LINK_WIDTH	*32]		)	,
		.	gttx_charisk            	(	gttx_charisk           	[	ii* LINK_WIDTH	*04	+: LINK_WIDTH	*04]		)
	);


	srio_gen2_0_7s_gt_top_glu
	#(
		.LINK_WIDTH					(	LINK_WIDTH				)
	)
	i_srio_gen2_0_7s_gt_top_glu
	(
		.gt_txpmareset_in			(	gt_txpmareset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_rxpmareset_in			(	gt_rxpmareset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_txpcsreset_in			(	gt_txpcsreset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_rxpcsreset_in			(	gt_rxpcsreset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_eyescanreset_in			(	gt_eyescanreset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_eyescantrigger_in		(	gt_eyescantrigger_in	[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
																
		.gt_loopback_in				(	gt_loopback_in			[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]		)	,
		.gt_rxpolarity_in			(	gt_rxpolarity_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_txpolarity_in			(	gt_txpolarity_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_rxlpmen_in				(	gt_rxlpmen_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_txprecursor_in			(	gt_txprecursor_in		[	ii*	LINK_WIDTH	*05	+:	LINK_WIDTH	*05]		)	,
		.gt_txpostcursor_in			(	gt_txpostcursor_in		[	ii*	LINK_WIDTH	*05	+:	LINK_WIDTH	*05]		)	,
		.gt_txdiffctrl_in			(	gt_txdiffctrl_in		[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]		)	,
		.gt_txprbsforceerr_in		(	gt_txprbsforceerr_in	[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_txprbssel_in			(	gt_txprbssel_in			[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]		)	,
		.gt_rxprbssel_in			(	gt_rxprbssel_in			[	ii*	LINK_WIDTH	*03	+:	LINK_WIDTH	*03]		)	,
		.gt_rxprbscntreset_in		(	gt_rxprbscntreset_in	[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_rxcdrhold_in			(	gt_rxcdrhold_in			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_rxdfelpmreset_in		(	gt_rxdfelpmreset_in		[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
																
		.gt_drpdo_out				(	gt_drpdo_out			[	ii*	LINK_WIDTH	*16	+:	LINK_WIDTH	*16]		)	,
		.gt_drprdy_out				(	gt_drprdy_out			[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_drpaddr_in				(	gt_drpaddr_in			[	ii*	LINK_WIDTH	*09	+:	LINK_WIDTH	*09]		)	,
		.gt_drpdi_in				(	gt_drpdi_in				[	ii*	LINK_WIDTH	*16	+:	LINK_WIDTH	*16]		)	,
		.gt_drpen_in				(	gt_drpen_in				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
		.gt_drpwe_in				(	gt_drpwe_in				[	ii*	LINK_WIDTH	*01	+:	LINK_WIDTH	*01]		)	,
																
		.gttx_data					(	gttx_data				[	ii*	LINK_WIDTH	*32	+:	LINK_WIDTH	*32]		)	,
		.gttx_charisk				(	gttx_charisk			[	ii*	LINK_WIDTH	*04	+:	LINK_WIDTH	*04]		)	

	);	//srio_gen2_bm_top_glu

	`ifdef	SRIO_TYPE_1G1X8B	srio_1g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G2X8B	srio_1g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G4X8B	srio_1g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G1X8B	srio_2g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G2X8B	srio_2g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G4X8B	srio_2g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G1X8B	srio_3g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G2X8B	srio_3g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G4X8B	srio_3g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G1X8B	srio_5g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G2X8B	srio_5g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G4X8B	srio_5g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G1X8B	srio_6g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G2X8B	srio_6g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G4X8B	srio_6g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G1X16B	srio_1g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G2X16B	srio_1g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_1G4X16B	srio_1g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G1X16B	srio_2g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G2X16B	srio_2g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_2G4X16B	srio_2g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G1X16B	srio_3g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G2X16B	srio_3g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_3G4X16B	srio_3g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G1X16B	srio_5g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G2X16B	srio_5g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_5G4X16B	srio_5g_4x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G1X16B	srio_6g_1x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G2X16B	srio_6g_2x_gt_srio_rst		`endif
	`ifdef	SRIO_TYPE_6G4X16B	srio_6g_4x_gt_srio_rst		`endif
	i_srio_gen2_srio_rst
	(
	.	cfg_clk						(	log_clk												)	,	//		input		//	CFG	interface	clock
	.	log_clk						(	log_clk												)	,	//		input		//	LOG	interface	clock
	.	phy_clk						(	phy_clk												)	,	//		input		//	PHY	interface	clock
	.	gt_pcs_clk					(	gt_pcs_clk											)	,	//		input		//	GT	Fabric	interface	clock
	.	freerun_clk_in				(	freerun_clk											)	,   //		input		
	.	gt_rst						(	gt_rst					[ii*		1	+: 1]		)	,   //		output		
	.	sys_rst						(	sys_rst	||force_reinit  [ii*		1	+: 1]		)	,	//		input		//	Global	reset	signal
	.	port_initialized			(	any_gtrxaligned   		[ii*		1	+: 1]		)	,	//		input		//	Port	is	intialized
	.	phy_rcvd_link_reset			(	1'b0												)	,	//		input		//	Received	4	consecutive	reset	symbols
	.	force_reinit				(	1'b0												)	,	//		input		//	Force	reinitialization
	.	clk_lock					(	gtrx_reset_done			[ii* LINK_WIDTH	+: 1]		)	,	//		input		//	Indicates	the	MMCM	has	achieved	a	stable	clock
	.	controlled_force_reinit		(	controlled_force_reinit	[ii*		1	+: 1]		)	,	//		output	reg	//	Force	reinitialization
	.	cfg_rst						(	cfg_rst					[ii*		1	+: 1]		)	,	//		output		//	CFG	dedicated	reset
	.	log_rst						(	log_rst					[ii*		1	+: 1]		)	,	//		output		//	LOG	dedicated	reset
	.	buf_rst						(	buf_rst					[ii*		1	+: 1]		)	,	//		output		//	BUF	dedicated	reset
	.	phy_rst						(	phy_rst					[ii*		1	+: 1]		)	,	//		output		//	PHY	dedicated	reset
	.	gt_pcs_rst					(	gt_pcs_rst				[ii*		1	+: 1]		)		//		output		//	GT	dedicated	reset
	);
end	//	for
end	//	if
endgenerate
endmodule
