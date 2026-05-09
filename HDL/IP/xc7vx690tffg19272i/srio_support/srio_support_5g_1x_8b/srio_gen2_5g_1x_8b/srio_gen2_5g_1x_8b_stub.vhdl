-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
-- Date        : Mon Mar 30 19:23:27 2026
-- Host        : ZHTY-DCM running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               F:/SVN/VX/VX3000/03_FPGA/LTVX30_0040/HDL/IP/xc7vx690tffg19272i/srio_support/srio_support_5g_1x_8b/srio_gen2_5g_1x_8b/srio_gen2_5g_1x_8b_stub.vhdl
-- Design      : srio_gen2_5g_1x_8b
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx690tffg1761-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity srio_gen2_5g_1x_8b is
  Port ( 
    log_clk_in : in STD_LOGIC;
    phy_clk_in : in STD_LOGIC;
    gt_clk_in : in STD_LOGIC;
    gt_pcs_clk_in : in STD_LOGIC;
    drpclk_in : in STD_LOGIC;
    refclk_in : in STD_LOGIC;
    clk_lock_in : in STD_LOGIC;
    cfg_rst_in : in STD_LOGIC;
    log_rst_in : in STD_LOGIC;
    buf_rst_in : in STD_LOGIC;
    phy_rst_in : in STD_LOGIC;
    gt_pcs_rst_in : in STD_LOGIC;
    gt0_qpll_clk_in : in STD_LOGIC;
    gt0_qpll_out_refclk_in : in STD_LOGIC;
    srio_rxn0 : in STD_LOGIC;
    srio_rxp0 : in STD_LOGIC;
    srio_txn0 : out STD_LOGIC;
    srio_txp0 : out STD_LOGIC;
    s_axis_iotx_tvalid : in STD_LOGIC;
    s_axis_iotx_tready : out STD_LOGIC;
    s_axis_iotx_tlast : in STD_LOGIC;
    s_axis_iotx_tdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    s_axis_iotx_tkeep : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_axis_iotx_tuser : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axis_iorx_tvalid : out STD_LOGIC;
    m_axis_iorx_tready : in STD_LOGIC;
    m_axis_iorx_tlast : out STD_LOGIC;
    m_axis_iorx_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_iorx_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_iorx_tuser : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_maintr_rst : in STD_LOGIC;
    s_axi_maintr_awvalid : in STD_LOGIC;
    s_axi_maintr_awready : out STD_LOGIC;
    s_axi_maintr_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_maintr_wvalid : in STD_LOGIC;
    s_axi_maintr_wready : out STD_LOGIC;
    s_axi_maintr_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_maintr_bvalid : out STD_LOGIC;
    s_axi_maintr_bready : in STD_LOGIC;
    s_axi_maintr_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_maintr_arvalid : in STD_LOGIC;
    s_axi_maintr_arready : out STD_LOGIC;
    s_axi_maintr_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_maintr_rvalid : out STD_LOGIC;
    s_axi_maintr_rready : in STD_LOGIC;
    s_axi_maintr_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_maintr_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    sim_train_en : in STD_LOGIC;
    force_reinit : in STD_LOGIC;
    phy_mce : in STD_LOGIC;
    phy_link_reset : in STD_LOGIC;
    phy_rcvd_mce : out STD_LOGIC;
    phy_rcvd_link_reset : out STD_LOGIC;
    phy_debug : out STD_LOGIC_VECTOR ( 223 downto 0 );
    gtrx_disperr_or : out STD_LOGIC;
    gtrx_notintable_or : out STD_LOGIC;
    port_error : out STD_LOGIC;
    port_timeout : out STD_LOGIC_VECTOR ( 23 downto 0 );
    srio_host : out STD_LOGIC;
    port_decode_error : out STD_LOGIC;
    deviceid : out STD_LOGIC_VECTOR ( 15 downto 0 );
    idle2_selected : out STD_LOGIC;
    phy_lcl_master_enable_out : out STD_LOGIC;
    buf_lcl_response_only_out : out STD_LOGIC;
    buf_lcl_tx_flow_control_out : out STD_LOGIC;
    buf_lcl_phy_buf_stat_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    phy_lcl_phy_next_fm_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    phy_lcl_phy_last_ack_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    phy_lcl_phy_rewind_out : out STD_LOGIC;
    phy_lcl_phy_rcvd_buf_stat_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    phy_lcl_maint_only_out : out STD_LOGIC;
    port_initialized : out STD_LOGIC;
    link_initialized : out STD_LOGIC;
    idle_selected : out STD_LOGIC;
    mode_1x : out STD_LOGIC
  );

end srio_gen2_5g_1x_8b;

architecture stub of srio_gen2_5g_1x_8b is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "log_clk_in,phy_clk_in,gt_clk_in,gt_pcs_clk_in,drpclk_in,refclk_in,clk_lock_in,cfg_rst_in,log_rst_in,buf_rst_in,phy_rst_in,gt_pcs_rst_in,gt0_qpll_clk_in,gt0_qpll_out_refclk_in,srio_rxn0,srio_rxp0,srio_txn0,srio_txp0,s_axis_iotx_tvalid,s_axis_iotx_tready,s_axis_iotx_tlast,s_axis_iotx_tdata[63:0],s_axis_iotx_tkeep[7:0],s_axis_iotx_tuser[31:0],m_axis_iorx_tvalid,m_axis_iorx_tready,m_axis_iorx_tlast,m_axis_iorx_tdata[63:0],m_axis_iorx_tkeep[7:0],m_axis_iorx_tuser[31:0],s_axi_maintr_rst,s_axi_maintr_awvalid,s_axi_maintr_awready,s_axi_maintr_awaddr[31:0],s_axi_maintr_wvalid,s_axi_maintr_wready,s_axi_maintr_wdata[31:0],s_axi_maintr_bvalid,s_axi_maintr_bready,s_axi_maintr_bresp[1:0],s_axi_maintr_arvalid,s_axi_maintr_arready,s_axi_maintr_araddr[31:0],s_axi_maintr_rvalid,s_axi_maintr_rready,s_axi_maintr_rdata[31:0],s_axi_maintr_rresp[1:0],sim_train_en,force_reinit,phy_mce,phy_link_reset,phy_rcvd_mce,phy_rcvd_link_reset,phy_debug[223:0],gtrx_disperr_or,gtrx_notintable_or,port_error,port_timeout[23:0],srio_host,port_decode_error,deviceid[15:0],idle2_selected,phy_lcl_master_enable_out,buf_lcl_response_only_out,buf_lcl_tx_flow_control_out,buf_lcl_phy_buf_stat_out[5:0],phy_lcl_phy_next_fm_out[5:0],phy_lcl_phy_last_ack_out[5:0],phy_lcl_phy_rewind_out,phy_lcl_phy_rcvd_buf_stat_out[5:0],phy_lcl_maint_only_out,port_initialized,link_initialized,idle_selected,mode_1x";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "srio_gen2_v4_1_5,Vivado 2015.1.0";
begin
end;
