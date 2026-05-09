// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Sat May  9 17:28:37 2026
// Host        : ZHTY-DCM running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub D:/pcie3_dma_top.v
// Design      : pcie3_dma_top
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module pcie3_dma_top(user_lnk_up, phy_rdy_out, m_axis_rc_tvalid, 
  m_axis_rc_tready, m_axis_rc_tlast, m_axis_rc_tdata, m_axis_rc_tkeep, m_axis_rc_tuser, 
  s_axis_cc_tvalid, s_axis_cc_tready, s_axis_cc_tdata, s_axis_cc_tkeep, s_axis_cc_tlast, 
  s_axis_cc_tuser, s_axis_rq_tvalid, s_axis_rq_tready, s_axis_rq_tdata, s_axis_rq_tkeep, 
  s_axis_rq_tlast, s_axis_rq_tuser, pcie_rq_tag, pcie_rq_tag_vld, pcie_rq_tag_av, 
  pcie_tfc_nph_av, pcie_tfc_npd_av, pcie_rq_seq_num, pcie_rq_seq_num_vld, m_axis_cq_tvalid, 
  m_axis_cq_tready, m_axis_cq_tlast, m_axis_cq_tdata, m_axis_cq_tkeep, m_axis_cq_tuser, 
  pcie_cq_np_req_count, pcie_cq_np_req, cfg_interrupt_msi_enable, 
  cfg_interrupt_msi_mmenable, cfg_interrupt_msi_sent, cfg_interrupt_msi_fail, 
  cfg_interrupt_msi_int, inter_req_cnt, inter_send_cnt, inter_fail_cnt, inter_int_latch, 
  max_pay_size, max_req_size, cfg_current_speed, cfg_negotiated_width, 
  pl_initial_link_width, pl_link_gen2_cap, pl_link_partner_gen2_supported, 
  dma_s_axis_aclk, dma_s_axis_tdata, dma_s_axis_tid, dma_s_axis_tready, dma_s_axis_tvalid, 
  dma_s_axis_tstrb, dma_s_axis_tkeep, dma_s_axis_tlast, dma_s_axis_tuser, dma_s_axis_tdest, 
  dma_m_axis_aclk, dma_m_axis_tdata, dma_m_axis_tid, dma_m_axis_tready, dma_m_axis_tvalid, 
  dma_m_axis_tstrb, dma_m_axis_tkeep, dma_m_axis_tlast, dma_m_axis_tuser, dma_m_axis_tdest, 
  dma_up_int_req, dma_up_int_gnt, pab_axi_awaddr, pab_axi_awprot, pab_axi_awvalid, 
  pab_axi_awready, pab_axi_wdata, pab_axi_wstrb, pab_axi_wvalid, pab_axi_wready, 
  pab_axi_bresp, pab_axi_bvalid, pab_axi_bready, pab_axi_araddr, pab_axi_arprot, 
  pab_axi_arvalid, pab_axi_arready, pab_axi_rdata, pab_axi_rresp, pab_axi_rvalid, 
  pab_axi_rready, interrupt_bus_clk, interrupt_bus_req, interrupt_bus_gnt, 
  interrupt_bus_vector, c_os_config, c_os_big_endian, pcie_far_id, pcie_dev_id, rst, clk)
/* synthesis syn_black_box black_box_pad_pin="user_lnk_up,phy_rdy_out,m_axis_rc_tvalid,m_axis_rc_tready,m_axis_rc_tlast,m_axis_rc_tdata[255:0],m_axis_rc_tkeep[7:0],m_axis_rc_tuser[74:0],s_axis_cc_tvalid,s_axis_cc_tready,s_axis_cc_tdata[255:0],s_axis_cc_tkeep[7:0],s_axis_cc_tlast,s_axis_cc_tuser[32:0],s_axis_rq_tvalid,s_axis_rq_tready,s_axis_rq_tdata[255:0],s_axis_rq_tkeep[7:0],s_axis_rq_tlast,s_axis_rq_tuser[59:0],pcie_rq_tag[5:0],pcie_rq_tag_vld,pcie_rq_tag_av[1:0],pcie_tfc_nph_av[1:0],pcie_tfc_npd_av[1:0],pcie_rq_seq_num[3:0],pcie_rq_seq_num_vld,m_axis_cq_tvalid,m_axis_cq_tready,m_axis_cq_tlast,m_axis_cq_tdata[255:0],m_axis_cq_tkeep[7:0],m_axis_cq_tuser[84:0],pcie_cq_np_req_count[5:0],pcie_cq_np_req,cfg_interrupt_msi_enable,cfg_interrupt_msi_mmenable[5:0],cfg_interrupt_msi_sent,cfg_interrupt_msi_fail,cfg_interrupt_msi_int[31:0],inter_req_cnt[1:0],inter_send_cnt[1:0],inter_fail_cnt[1:0],inter_int_latch[31:0],max_pay_size[2:0],max_req_size[2:0],cfg_current_speed[2:0],cfg_negotiated_width[3:0],pl_initial_link_width[2:0],pl_link_gen2_cap,pl_link_partner_gen2_supported,dma_s_axis_aclk[1:0],dma_s_axis_tdata[511:0],dma_s_axis_tid[7:0],dma_s_axis_tready[1:0],dma_s_axis_tvalid[1:0],dma_s_axis_tstrb[63:0],dma_s_axis_tkeep[63:0],dma_s_axis_tlast[1:0],dma_s_axis_tuser[127:0],dma_s_axis_tdest[7:0],dma_m_axis_aclk[1:0],dma_m_axis_tdata[511:0],dma_m_axis_tid[7:0],dma_m_axis_tready[1:0],dma_m_axis_tvalid[1:0],dma_m_axis_tstrb[63:0],dma_m_axis_tkeep[63:0],dma_m_axis_tlast[1:0],dma_m_axis_tuser[127:0],dma_m_axis_tdest[7:0],dma_up_int_req[1:0],dma_up_int_gnt[1:0],pab_axi_awaddr[31:0],pab_axi_awprot[2:0],pab_axi_awvalid[0:0],pab_axi_awready[0:0],pab_axi_wdata[31:0],pab_axi_wstrb[3:0],pab_axi_wvalid[0:0],pab_axi_wready[0:0],pab_axi_bresp[1:0],pab_axi_bvalid[0:0],pab_axi_bready[0:0],pab_axi_araddr[31:0],pab_axi_arprot[2:0],pab_axi_arvalid[0:0],pab_axi_arready[0:0],pab_axi_rdata[31:0],pab_axi_rresp[1:0],pab_axi_rvalid[0:0],pab_axi_rready[0:0],interrupt_bus_clk,interrupt_bus_req,interrupt_bus_gnt,interrupt_bus_vector[31:16],c_os_config,c_os_big_endian,pcie_far_id[15:0],pcie_dev_id[15:0],rst,clk" */;
  input user_lnk_up;
  input phy_rdy_out;
  input m_axis_rc_tvalid;
  output m_axis_rc_tready;
  input m_axis_rc_tlast;
  input [255:0]m_axis_rc_tdata;
  input [7:0]m_axis_rc_tkeep;
  input [74:0]m_axis_rc_tuser;
  output s_axis_cc_tvalid;
  input s_axis_cc_tready;
  output [255:0]s_axis_cc_tdata;
  output [7:0]s_axis_cc_tkeep;
  output s_axis_cc_tlast;
  output [32:0]s_axis_cc_tuser;
  output s_axis_rq_tvalid;
  input s_axis_rq_tready;
  output [255:0]s_axis_rq_tdata;
  output [7:0]s_axis_rq_tkeep;
  output s_axis_rq_tlast;
  output [59:0]s_axis_rq_tuser;
  input [5:0]pcie_rq_tag;
  input pcie_rq_tag_vld;
  input [1:0]pcie_rq_tag_av;
  input [1:0]pcie_tfc_nph_av;
  input [1:0]pcie_tfc_npd_av;
  input [3:0]pcie_rq_seq_num;
  input pcie_rq_seq_num_vld;
  input m_axis_cq_tvalid;
  output m_axis_cq_tready;
  input m_axis_cq_tlast;
  input [255:0]m_axis_cq_tdata;
  input [7:0]m_axis_cq_tkeep;
  input [84:0]m_axis_cq_tuser;
  input [5:0]pcie_cq_np_req_count;
  output pcie_cq_np_req;
  input cfg_interrupt_msi_enable;
  input [5:0]cfg_interrupt_msi_mmenable;
  input cfg_interrupt_msi_sent;
  input cfg_interrupt_msi_fail;
  output [31:0]cfg_interrupt_msi_int;
  output [1:0]inter_req_cnt;
  output [1:0]inter_send_cnt;
  output [1:0]inter_fail_cnt;
  output [31:0]inter_int_latch;
  input [2:0]max_pay_size;
  input [2:0]max_req_size;
  input [2:0]cfg_current_speed;
  input [3:0]cfg_negotiated_width;
  input [2:0]pl_initial_link_width;
  input pl_link_gen2_cap;
  input pl_link_partner_gen2_supported;
  input [1:0]dma_s_axis_aclk;
  input [511:0]dma_s_axis_tdata;
  input [7:0]dma_s_axis_tid;
  output [1:0]dma_s_axis_tready;
  input [1:0]dma_s_axis_tvalid;
  input [63:0]dma_s_axis_tstrb;
  input [63:0]dma_s_axis_tkeep;
  input [1:0]dma_s_axis_tlast;
  input [127:0]dma_s_axis_tuser;
  input [7:0]dma_s_axis_tdest;
  input [1:0]dma_m_axis_aclk;
  output [511:0]dma_m_axis_tdata;
  output [7:0]dma_m_axis_tid;
  input [1:0]dma_m_axis_tready;
  output [1:0]dma_m_axis_tvalid;
  output [63:0]dma_m_axis_tstrb;
  output [63:0]dma_m_axis_tkeep;
  output [1:0]dma_m_axis_tlast;
  output [127:0]dma_m_axis_tuser;
  output [7:0]dma_m_axis_tdest;
  input [1:0]dma_up_int_req;
  output [1:0]dma_up_int_gnt;
  output [31:0]pab_axi_awaddr;
  output [2:0]pab_axi_awprot;
  output [0:0]pab_axi_awvalid;
  input [0:0]pab_axi_awready;
  output [31:0]pab_axi_wdata;
  output [3:0]pab_axi_wstrb;
  output [0:0]pab_axi_wvalid;
  input [0:0]pab_axi_wready;
  input [1:0]pab_axi_bresp;
  input [0:0]pab_axi_bvalid;
  output [0:0]pab_axi_bready;
  output [31:0]pab_axi_araddr;
  output [2:0]pab_axi_arprot;
  output [0:0]pab_axi_arvalid;
  input [0:0]pab_axi_arready;
  input [31:0]pab_axi_rdata;
  input [1:0]pab_axi_rresp;
  input [0:0]pab_axi_rvalid;
  output [0:0]pab_axi_rready;
  input interrupt_bus_clk;
  input interrupt_bus_req;
  output interrupt_bus_gnt;
  input [31:16]interrupt_bus_vector;
  output c_os_config;
  output c_os_big_endian;
  output [15:0]pcie_far_id;
  output [15:0]pcie_dev_id;
  input rst;
  input clk;
endmodule
