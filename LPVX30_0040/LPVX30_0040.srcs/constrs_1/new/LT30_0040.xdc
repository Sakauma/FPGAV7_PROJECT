#
#	set_property	IOSTANDARD	DIFF_SSTL15	[get_ports	SYS_CLK_P]
#	set_property	PACKAGE_PIN	AK17		[get_ports	SYS_CLK_P]
#	set_property	IOSTANDARD	DIFF_SSTL15	[get_ports	SYS_CLK_N]
#	set_property	PACKAGE_PIN	AK16		[get_ports	SYS_CLK_N]

 	set_property	IOSTANDARD	LVCMOS18	[get_ports	sys_rst_n]
 	set_property	PACKAGE_PIN	AN16		[get_ports	sys_rst_n]
 	set_property	PULLUP		true		[get_ports	sys_rst_n]
#
set_property PACKAGE_PIN E10 [get_ports pcie_ref_clk_p]


#	|--------------------------------------|
#	|                 	        ___________|___
#	|  SR2300         	       |______________|	--bank_group2	IP_GROUP0	BK214->216
#	|  V7690T         	        ___________|___
#	|  PCIE           	       |______________|	--bank_group1	IP_GROUP1	BK217->219
#	|  BOARD          	        ___________|___
#	|                 	       |______________|	--bank_group4	IP_GROUP2	BK117->129
#	|                 	        ___________|___
#	|                 	       |______________|	--bank_group3	IP_GROUP3	BK114->116
#	|									   |
#	|		|------------------------------|
#	|       |     ||  |||||||||||	  ||
#	|_______|


#====================================================================================================================================================
#GTX ±÷”‘º ¯	SRIO




#############################	adjust for hardware map	#############################
set_property PACKAGE_PIN AE1 [get_ports {srio_txn0[0]}]
set_property PACKAGE_PIN AE2 [get_ports {srio_txp0[0]}]
set_property PACKAGE_PIN AC2 [get_ports {srio_txp0[1]}]
set_property PACKAGE_PIN AC1 [get_ports {srio_txn0[1]}]
set_property PACKAGE_PIN AA1 [get_ports {srio_txn0[2]}]
set_property PACKAGE_PIN AA2 [get_ports {srio_txp0[2]}]
set_property PACKAGE_PIN W1 [get_ports {srio_txn0[3]}]
set_property PACKAGE_PIN W2 [get_ports {srio_txp0[3]}]

set_property PACKAGE_PIN AC5 [get_ports {srio_rxn0[0]}]
set_property PACKAGE_PIN AC6 [get_ports {srio_rxp0[0]}]
set_property PACKAGE_PIN AB3 [get_ports {srio_rxn0[1]}]
set_property PACKAGE_PIN AB4 [get_ports {srio_rxp0[1]}]
set_property PACKAGE_PIN AA5 [get_ports {srio_rxn0[2]}]
set_property PACKAGE_PIN AA6 [get_ports {srio_rxp0[2]}]
set_property PACKAGE_PIN Y3 [get_ports {srio_rxn0[3]}]
set_property PACKAGE_PIN Y4 [get_ports {srio_rxp0[3]}]


set_property PACKAGE_PIN Y8 [get_ports {srio_sys_clk_p_125[0]}]
set_property PACKAGE_PIN Y7 [get_ports {srio_sys_clk_n_125[0]}]



#N10 flash clk
# AK34 v7 50Mhz Clk
set_property PACKAGE_PIN AK34 [get_ports ext_clk]
set_property IOSTANDARD LVCMOS18 [get_ports ext_clk]
#create_clock	-period	20.000	-name	EXT_IO_CLK	-waveform	{0.000	10.000}	[get_ports	ext_clk]


#create_clock -period 40.000 -name clk_wiz1_in -waveform {0.000 20.000} [get_ports ext_clk]

create_clock -period 10.000 -name pciexy0_ref_clk -waveform {0.000 5.000} [get_ports pcie_ref_clk_p]

create_clock -period 8.000 -name ref_clk_125_srio_bk0 -waveform {0.000 4.000} [get_ports {srio_sys_clk_p_125[0]}]

create_clock -period 6.400 -name ref_clk_156_teng_bk0 -waveform {0.000 3.200} [get_ports teng_refclk_p ]


#	create_generated_clock	-name	pciexy0_user_clk	[get_pins	pcie3_ep_wrap/pcie3_8x8g_0_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]
create_generated_clock -name pciexy0_user_clk [get_pins u_pcie_dma_top/i_pcie3_ep_wrap/pcie3_8x8g_0_i/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]


#	create_generated_clock	-name	clk_wiz_fast_clk	[get_pins	FAST_CLK_400M.clk_wiz_fast/inst/mmcme3_adv_inst/CLKOUT0]	KU
#	create_generated_clock	-name	clk_wiz_fast_clk	[get_pins	FAST_CLK_400M.clk_wiz_fast/inst/mmcm_adv_inst/CLKOUT0]		7S
create_generated_clock -name clk_wiz_fast_clk [get_pins clk_wiz_fast/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name clk_wiz_flsh_clk [get_pins clk_wiz_fast/inst/mmcm_adv_inst/CLKOUT1]
#	set_property	CLOCK_DEDICATED_ROUTE	BACKBONE	[get_nets	FAST_CLK_400M.clk_wiz_fast/inst/clk_in1_clk_wiz_0]
#	set_property	CLOCK_DEDICATED_ROUTE	BACKBONE	[get_nets	clk_wiz_fast/inst/clk_in1_clk_wiz_0]


#set_false_path -from [get_clocks pciexy0_user_clk] -to [get_clocks SPI_FLASH_EMCCLK]
#set_false_path -from [get_clocks SPI_FLASH_EMCCLK] -to [get_clocks pciexy0_user_clk]

set_false_path -from [get_clocks pciexy0_user_clk] -to [get_clocks clk_wiz_fast_clk]
set_false_path -from [get_clocks clk_wiz_fast_clk] -to [get_clocks pciexy0_user_clk]

set_false_path -from [get_clocks pciexy0_user_clk] -to [get_clocks clk_wiz_flsh_clk]
set_false_path -from [get_clocks clk_wiz_flsh_clk] -to [get_clocks pciexy0_user_clk]

set_false_path -from [get_clocks pciexy0_user_clk] -to [get_clocks clk_250mhz_mux_x0y2]
set_false_path -from [get_clocks clk_250mhz_mux_x0y2] -to [get_clocks pciexy0_user_clk]

	set_false_path -from [get_pins {u_pcie_dma_top/i_pcie3_ep_wrap/user_reset_dup_reg[3]/C}]     
	set_false_path -from [get_pins {u_TenG_ETH_TOP/ten_gig_eth_support/ten_gig_eth_pcs_pma_shared_clock_reset_block/reset_pulse_reg[0]/C}]  
####set_false_path -from [get_pins pcie3_ep_wrap/pcie_rst_cnt_rst_pre_reg/C]          
####set_false_path -from [get_pins {pcie3_ep_wrap/pcie_rst_cnt_rst_reg*/C}]           
####set_false_path -from [get_pins {pcie3_ep_wrap/pcie_rst_cnt_rst_n_reg*/C}]         
####set_false_path -from [get_pins pcie3_ep_wrap/pcie3_8x8g_0_i/inst/user_reset_reg/C]
####set_false_path -from [get_pins pcie3_dma_top/int_i/c_dma_soft_rst_reg/C]          
	                                                                                  

                                                                             
                                                                                  
                                                                                  
                                                                                  
                                                                                  
##
##
##
##
#set_property LOC GTHE2_CHANNEL_X1Y35 [get_cells {pcie3_ep_wrap/pcie3_8x8g_0_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN E5 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN E6 [get_ports {pci_exp_rxp[0]}]
#set_property LOC GTHE2_CHANNEL_X1Y34 [get_cells {pcie3_ep_wrap/pcie3_8x8g_0_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN F7 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN F8 [get_ports {pci_exp_rxp[1]}]
#set_property LOC GTHE2_CHANNEL_X1Y33 [get_cells {pcie3_ep_wrap/pcie3_8x8g_0_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN G5 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN G6 [get_ports {pci_exp_rxp[2]}]
#set_property LOC GTHE2_CHANNEL_X1Y32 [get_cells {pcie3_ep_wrap/pcie3_8x8g_0_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN  H7 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN  H8 [get_ports {pci_exp_rxp[3]}]
#set_property	PACKAGE_PIN	AP8		[get_ports	{pci_exp_rxp[4]}]
#set_property	PACKAGE_PIN	AP7		[get_ports	{pci_exp_rxn[4]}]
#set_property	PACKAGE_PIN	AR6		[get_ports	{pci_exp_rxp[5]}]
#set_property	PACKAGE_PIN	AR5		[get_ports	{pci_exp_rxn[5]}]
#set_property	PACKAGE_PIN	AU6		[get_ports	{pci_exp_rxp[6]}]
#set_property	PACKAGE_PIN	AU5		[get_ports	{pci_exp_rxn[6]}]
#set_property	PACKAGE_PIN	AV8		[get_ports	{pci_exp_rxp[7]}]
#set_property	PACKAGE_PIN	AV7		[get_ports	{pci_exp_rxn[7]}]

                                                      
                                                      
set_property PACKAGE_PIN K8 [get_ports teng_refclk_p]    
set_property PACKAGE_PIN K7 [get_ports teng_refclk_n]     
                                                       
set_property PACKAGE_PIN P8    	 [get_ports teng_rxp ] ; 
set_property PACKAGE_PIN P7      [get_ports teng_rxn ] ; 
set_property PACKAGE_PIN N2    	 [get_ports teng_txp ] ; 
set_property PACKAGE_PIN N1      [get_ports teng_txn ] ; 
                                                      
 

#	Flash

#set_property PACKAGE_PIN ak34 [get_ports EMCCLK]
#set_property IOSTANDARD LVCMOS18 [get_ports EMCCLK]

set_property PACKAGE_PIN AM36 [get_ports {spi_0_dq[0]}]
set_property PACKAGE_PIN AN36 [get_ports {spi_0_dq[1]}]
#	set_property	PACKAGE_PIN	BD29		[get_ports	spi_0_dq[2]]
#	set_property	PACKAGE_PIN	BD30		[get_ports	spi_0_dq[3]]
set_property IOSTANDARD LVCMOS18 [get_ports {spi_0_dq[*]}]
set_property PACKAGE_PIN BA29 [get_ports spi_0_ss]
set_property IOSTANDARD LVCMOS18 [get_ports spi_0_ss]


##IPROG	options	for	loading	the	second	bitream
#	set_property	BITSTREAM.CONFIG.CONFIGFALLBACK	Enable	[current_design]
#	set_property	BITSTREAM.CONFIG.TIMER_CFG	32'h00050000	[current_design]
##	Golden	Bitstream	settings
#	set_property	BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT	Enable	[current_design]
#	set_property	BITSTREAM.CONFIG.NEXT_CONFIG_ADDR	32'h00F50000	[current_design]


#####################################################################################################
# The following section list the board specific constraints (with/without STARTUPE2/E3 primitive)   #
# as per guidance given in product guide.                                                           #
# User should uncomment, update constraints based on board delays and use                           #
#####################################################################################################

#####################################################################################################
# STARTUPE2 primitive included inside IP                                                            #
#####################################################################################################

#### All the delay numbers have to be provided by the user

#### CCLK delay is 0.5, 6.7 ns min/max for K7-2; refer Data sheet
#### Consider the max delay for worst case analysis

#### Following are the SPI device parameters
#### Max Tco
#### Min Tco
#### Setup time requirement
#### Hold time requirement


#### Following are the board/trace delay numbers
#### Assumption is that all Data lines are matched
##### End of user provided delay numbers

#### This is to ensure min routing delay from SCK generation to STARTUP input
#### User should change this value based on the results having more delay on this net reduces the Fmax
set_max_delay -datapath_only -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 1.500
set_min_delay -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 0.100

#### Following command creates a divide by 2 clock
#### It also takes into account the delay added by STARTUP block to route the CCLK
create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk] -edges {3 5 7} -edge_shift {6.700 6.700 6.700} [get_pins -hierarchical *USRCCLKO]

#### Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
#### Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk
set_input_delay -clock clk_sck -clock_fall -max 7.450 [get_ports spi_*]
set_input_delay -clock clk_sck -clock_fall -min 1.450 [get_ports spi_*]
set_multicycle_path -setup -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 2
set_multicycle_path -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 1

#### Data is captured into SPI on the following rising edge of SCK
#### Data is driven by the IP on alternate rising_edge of the ext_spi_clk
set_output_delay -clock clk_sck -max 2.050 [get_ports spi_*]
set_output_delay -clock clk_sck -min -2.950 [get_ports spi_*]
set_multicycle_path -setup -start -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck 2
set_multicycle_path -hold -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck 1
#####################################################################################################

#set_false_path -from [get_clocks clk_sck] -to [get_clocks SPI_FLASH_EMCCLK]
#set_false_path -from [get_clocks SPI_FLASH_EMCCLK] -to [get_clocks clk_sck]

#e
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 2 [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets pcie_clk]
