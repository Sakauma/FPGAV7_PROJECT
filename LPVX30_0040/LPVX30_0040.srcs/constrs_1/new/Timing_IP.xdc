
	create_generated_clock	-name	srgtbk0_7clkout0	[get_pins {i_SUPPT_G[0].i_srio_support/normal.u_srio_support/srio_clk_inst/srio_mmcm_inst/CLKOUT0}]
	create_generated_clock	-name	srgtbk0_7clkout1	[get_pins {i_SUPPT_G[0].i_srio_support/normal.u_srio_support/srio_clk_inst/srio_mmcm_inst/CLKOUT1}]
	create_generated_clock	-name	srgtbk0_7clkout2	[get_pins {i_SUPPT_G[0].i_srio_support/normal.u_srio_support/srio_clk_inst/srio_mmcm_inst/CLKOUT2}]

	#create_generated_clock	-name	srgtbk1_7clkout0	[get_pins {i_SUPPT_G[1].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT0}]
	#create_generated_clock	-name	srgtbk1_7clkout1	[get_pins {i_SUPPT_G[1].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT1}]
	#create_generated_clock	-name	srgtbk1_7clkout2	[get_pins {i_SUPPT_G[1].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT2}]
	#
	#create_generated_clock	-name	srgtbk2_7clkout0	[get_pins {i_SUPPT_G[2].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT0}]
	#create_generated_clock	-name	srgtbk2_7clkout1	[get_pins {i_SUPPT_G[2].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT1}]
	#create_generated_clock	-name	srgtbk2_7clkout2	[get_pins {i_SUPPT_G[2].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT2}]
	#								#[get_pins {i_SUPPT_G[0].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT2}]]
	#create_generated_clock	-name	srgtbk3_7clkout0	[get_pins {i_SUPPT_G[3].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT0}]
	#create_generated_clock	-name	srgtbk3_7clkout1	[get_pins {i_SUPPT_G[3].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT1}]
	#create_generated_clock	-name	srgtbk3_7clkout2	[get_pins {i_SUPPT_G[3].i_srgt_support/i_srio_gt_support/i_srio_gen2_0_srio_clk/srio_mmcm_inst/CLKOUT2}]
	
	
#	set_false_path	-from	[get_clocks	srgtbk*_7clkout0]	-to	[get_clocks	srgtbk*_7clkout1]
#	set_false_path	-from	[get_clocks	srgtbk*_7clkout1]	-to	[get_clocks	srgtbk*_7clkout0]
#	set_false_path	-from	[get_clocks	srgtbk*_7clkout0]	-to	[get_clocks	srgtbk*_7clkout2]
#	set_false_path	-from	[get_clocks	srgtbk*_7clkout2]	-to	[get_clocks	srgtbk*_7clkout0]
#	set_false_path	-from	[get_clocks	srgtbk*_7clkout2]	-to	[get_clocks	srgtbk*_7clkout1]
#	set_false_path	-from	[get_clocks	srgtbk*_7clkout1]	-to	[get_clocks	srgtbk*_7clkout2]

	set_false_path	-from	[get_clocks	pciexy0_user_clk]	-to	[get_clocks	srgtbk*_7clkout*]
	set_false_path	-from	[get_clocks	srgtbk*_7clkout*]	-to	[get_clocks	pciexy0_user_clk]

	set_false_path	-from	[get_clocks	clk_wiz_fast_clk]	-to	[get_clocks	srgtbk*_7clkout*]
	set_false_path	-from	[get_clocks	srgtbk*_7clkout*]	-to	[get_clocks	clk_wiz_fast_clk]


	set_false_path -from [get_clocks ref_clk_125_srio_bk*] -to [get_clocks srgtbk*_7clkout1]
	set_false_path -from [get_clocks srgtbk*_7clkout1] -to [get_clocks ref_clk_125_srio_bk*]





#	set_false_path	-from	[get_clocks	sriobk*_7clkout0]	-to	[get_clocks	sriobk*_7clkout1]
#	set_false_path	-from	[get_clocks	sriobk*_7clkout1]	-to	[get_clocks	sriobk*_7clkout0]
#	set_false_path	-from	[get_clocks	sriobk*_7clkout0]	-to	[get_clocks	sriobk*_7clkout2]
#	set_false_path	-from	[get_clocks	sriobk*_7clkout2]	-to	[get_clocks	sriobk*_7clkout0]
#	set_false_path	-from	[get_clocks	sriobk*_7clkout2]	-to	[get_clocks	sriobk*_7clkout1]
#	set_false_path	-from	[get_clocks	sriobk*_7clkout1]	-to	[get_clocks	sriobk*_7clkout2]







