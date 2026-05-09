// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Mon Mar 30 19:23:27 2026
// Host        : ZHTY-DCM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               F:/SVN/VX/VX3000/03_FPGA/LTVX30_0040/HDL/IP/xc7vx690tffg19272i/srio_support/srio_support_5g_1x_8b/srio_gen2_5g_1x_8b/srio_gen2_5g_1x_8b_stub.v
// Design      : srio_gen2_5g_1x_8b
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "srio_gen2_v4_1_5,Vivado 2015.1.0" *)
module srio_gen2_5g_1x_8b(log_clk_in, phy_clk_in, gt_clk_in, 
  gt_pcs_clk_in, drpclk_in, refclk_in, clk_lock_in, cfg_rst_in, log_rst_in, buf_rst_in, 
  phy_rst_in, gt_pcs_rst_in, gt0_qpll_clk_in, gt0_qpll_out_refclk_in, srio_rxn0, srio_rxp0, 
  srio_txn0, srio_txp0, s_axis_iotx_tvalid, s_axis_iotx_tready, s_axis_iotx_tlast, 
  s_axis_iotx_tdata, s_axis_iotx_tkeep, s_axis_iotx_tuser, m_axis_iorx_tvalid, 
  m_axis_iorx_tready, m_axis_iorx_tlast, m_axis_iorx_tdata, m_axis_iorx_tkeep, 
  m_axis_iorx_tuser, s_axi_maintr_rst, s_axi_maintr_awvalid, s_axi_maintr_awready, 
  s_axi_maintr_awaddr, s_axi_maintr_wvalid, s_axi_maintr_wready, s_axi_maintr_wdata, 
  s_axi_maintr_bvalid, s_axi_maintr_bready, s_axi_maintr_bresp, s_axi_maintr_arvalid, 
  s_axi_maintr_arready, s_axi_maintr_araddr, s_axi_maintr_rvalid, s_axi_maintr_rready, 
  s_axi_maintr_rdata, s_axi_maintr_rresp, sim_train_en, force_reinit, phy_mce, 
  phy_link_reset, phy_rcvd_mce, phy_rcvd_link_reset, phy_debug, gtrx_disperr_or, 
  gtrx_notintable_or, port_error, port_timeout, srio_host, port_decode_error, deviceid, 
  idle2_selected, phy_lcl_master_enable_out, buf_lcl_response_only_out, 
  buf_lcl_tx_flow_control_out, buf_lcl_phy_buf_stat_out, phy_lcl_phy_next_fm_out, 
  phy_lcl_phy_last_ack_out, phy_lcl_phy_rewind_out, phy_lcl_phy_rcvd_buf_stat_out, 
  phy_lcl_maint_only_out, port_initialized, link_initialized, idle_selected, mode_1x)
/* synthesis syn_black_box black_box_pad_pin="log_clk_in,phy_clk_in,gt_clk_in,gt_pcs_clk_in,drpclk_in,refclk_in,clk_lock_in,cfg_rst_in,log_rst_in,buf_rst_in,phy_rst_in,gt_pcs_rst_in,gt0_qpll_clk_in,gt0_qpll_out_refclk_in,srio_rxn0,srio_rxp0,srio_txn0,srio_txp0,s_axis_iotx_tvalid,s_axis_iotx_tready,s_axis_iotx_tlast,s_axis_iotx_tdata[63:0],s_axis_iotx_tkeep[7:0],s_axis_iotx_tuser[31:0],m_axis_iorx_tvalid,m_axis_iorx_tready,m_axis_iorx_tlast,m_axis_iorx_tdata[63:0],m_axis_iorx_tkeep[7:0],m_axis_iorx_tuser[31:0],s_axi_maintr_rst,s_axi_maintr_awvalid,s_axi_maintr_awready,s_axi_maintr_awaddr[31:0],s_axi_maintr_wvalid,s_axi_maintr_wready,s_axi_maintr_wdata[31:0],s_axi_maintr_bvalid,s_axi_maintr_bready,s_axi_maintr_bresp[1:0],s_axi_maintr_arvalid,s_axi_maintr_arready,s_axi_maintr_araddr[31:0],s_axi_maintr_rvalid,s_axi_maintr_rready,s_axi_maintr_rdata[31:0],s_axi_maintr_rresp[1:0],sim_train_en,force_reinit,phy_mce,phy_link_reset,phy_rcvd_mce,phy_rcvd_link_reset,phy_debug[223:0],gtrx_disperr_or,gtrx_notintable_or,port_error,port_timeout[23:0],srio_host,port_decode_error,deviceid[15:0],idle2_selected,phy_lcl_master_enable_out,buf_lcl_response_only_out,buf_lcl_tx_flow_control_out,buf_lcl_phy_buf_stat_out[5:0],phy_lcl_phy_next_fm_out[5:0],phy_lcl_phy_last_ack_out[5:0],phy_lcl_phy_rewind_out,phy_lcl_phy_rcvd_buf_stat_out[5:0],phy_lcl_maint_only_out,port_initialized,link_initialized,idle_selected,mode_1x" */;
  input log_clk_in;
  input phy_clk_in;
  input gt_clk_in;
  input gt_pcs_clk_in;
  input drpclk_in;
  input refclk_in;
  input clk_lock_in;
  input cfg_rst_in;
  input log_rst_in;
  input buf_rst_in;
  input phy_rst_in;
  input gt_pcs_rst_in;
  input gt0_qpll_clk_in;
  input gt0_qpll_out_refclk_in;
  input srio_rxn0;
  input srio_rxp0;
  output srio_txn0;
  output srio_txp0;
  input s_axis_iotx_tvalid;
  output s_axis_iotx_tready;
  input s_axis_iotx_tlast;
  input [63:0]s_axis_iotx_tdata;
  input [7:0]s_axis_iotx_tkeep;
  input [31:0]s_axis_iotx_tuser;
  output m_axis_iorx_tvalid;
  input m_axis_iorx_tready;
  output m_axis_iorx_tlast;
  output [63:0]m_axis_iorx_tdata;
  output [7:0]m_axis_iorx_tkeep;
  output [31:0]m_axis_iorx_tuser;
  input s_axi_maintr_rst;
  input s_axi_maintr_awvalid;
  output s_axi_maintr_awready;
  input [31:0]s_axi_maintr_awaddr;
  input s_axi_maintr_wvalid;
  output s_axi_maintr_wready;
  input [31:0]s_axi_maintr_wdata;
  output s_axi_maintr_bvalid;
  input s_axi_maintr_bready;
  output [1:0]s_axi_maintr_bresp;
  input s_axi_maintr_arvalid;
  output s_axi_maintr_arready;
  input [31:0]s_axi_maintr_araddr;
  output s_axi_maintr_rvalid;
  input s_axi_maintr_rready;
  output [31:0]s_axi_maintr_rdata;
  output [1:0]s_axi_maintr_rresp;
  input sim_train_en;
  input force_reinit;
  input phy_mce;
  input phy_link_reset;
  output phy_rcvd_mce;
  output phy_rcvd_link_reset;
  output [223:0]phy_debug;
  output gtrx_disperr_or;
  output gtrx_notintable_or;
  output port_error;
  output [23:0]port_timeout;
  output srio_host;
  output port_decode_error;
  output [15:0]deviceid;
  output idle2_selected;
  output phy_lcl_master_enable_out;
  output buf_lcl_response_only_out;
  output buf_lcl_tx_flow_control_out;
  output [5:0]buf_lcl_phy_buf_stat_out;
  output [5:0]phy_lcl_phy_next_fm_out;
  output [5:0]phy_lcl_phy_last_ack_out;
  output phy_lcl_phy_rewind_out;
  output [5:0]phy_lcl_phy_rcvd_buf_stat_out;
  output phy_lcl_maint_only_out;
  output port_initialized;
  output link_initialized;
  output idle_selected;
  output mode_1x;
endmodule
