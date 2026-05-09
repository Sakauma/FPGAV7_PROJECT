#-----------------------------------------------------------------------------
#
# File name:    srio_gen2_1g_1x_8b_ooc.xdc
# Rev:          4.0
# Description:  Constrains the core for out-of-context implementation
#
#-----------------------------------------------------------------------------


    create_clock -period 63.97 -name log_clk_in  [get_ports log_clk_in]

    create_clock -period 63.97 -name phy_clk_in  [get_ports phy_clk_in]

    create_clock -period 32 -name gt_pcs_clk_in  [get_ports gt_pcs_clk_in]


    create_clock -period 16.0 -name gt_clk_in  [get_ports gt_clk_in]

    create_clock -period 8 -name refclk_in  [get_ports refclk_in]

    create_clock -period 63.97 -name drpclk_in  [get_ports drpclk_in]




