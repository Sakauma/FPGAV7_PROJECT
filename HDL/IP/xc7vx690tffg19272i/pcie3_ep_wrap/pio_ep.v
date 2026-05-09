//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
// File       : pio_ep.v
// Version    : 4.4 
//-----------------------------------------------------------------------------
//
// Description: Endpoint Programmed I/O module.
//
//--------------------------------------------------------------------------------

`timescale 1ps/1ps

module pio_ep #(
  parameter        TCQ = 1,
  parameter [1:0]  AXISTEN_IF_WIDTH = 00,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE    = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE    = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE    = 0,
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE    = 0,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG    = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_RC_STRADDLE          = 0,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC  = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE     = 18'h2FFFF,

  //Do not modify the parameters below this line
  parameter C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0])? 128 : 64,
  parameter PARITY_WIDTH = C_DATA_WIDTH /8,
  parameter KEEP_WIDTH   = C_DATA_WIDTH /32
) (

  input                            user_clk,
  input                            reset_n,


  input                            cfg_msg_transmit_done,
  output wire                      cfg_msg_transmit,
  output wire              [2:0]   cfg_msg_transmit_type,
  output wire             [31:0]   cfg_msg_transmit_data,

  //Tag availability and Flow control Information

  input                    [5:0]   pcie_rq_tag,
  input                            pcie_rq_tag_vld,
  input                    [1:0]   pcie_tfc_nph_av,
  input                    [1:0]   pcie_tfc_npd_av,
  input                            pcie_tfc_np_pl_empty,
  input                    [3:0]   pcie_rq_seq_num,
  input                            pcie_rq_seq_num_vld,

  //Cfg Flow Control Information

  input                    [7:0]   cfg_fc_ph,
  input                    [7:0]   cfg_fc_nph,
  input                    [7:0]   cfg_fc_cplh,
  input                   [11:0]   cfg_fc_pd,
  input                   [11:0]   cfg_fc_npd,
  input                   [11:0]   cfg_fc_cpld,
  output                    [2:0]   cfg_fc_sel,


  // RX Message Interface

  input                            cfg_msg_received,
  input                    [4:0]   cfg_msg_received_type,
  input                    [7:0]   cfg_msg_data,

  // PIO Interrupt Interface

  output wire                      interrupt_done,  // Indicates whether interrupt is done or in process

  // Legacy Interrupt Interface

  input                            cfg_interrupt_sent, // Core asserts this signal when it sends out a Legacy interrupt
  output wire              [3:0]   cfg_interrupt_int,  // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)

  // MSI Interrupt Interface

  // input                            cfg_interrupt_msi_enable,
  // input                            cfg_interrupt_msi_sent,
  // input                            cfg_interrupt_msi_fail,

  // output wire             [31:0]   cfg_interrupt_msi_int,

  //MSI-X Interrupt Interface

  input                            cfg_interrupt_msix_enable,
  input                            cfg_interrupt_msix_sent,
  input                            cfg_interrupt_msix_fail,

  output wire                      cfg_interrupt_msix_int,
  output wire             [63:0]   cfg_interrupt_msix_address,
  output wire             [31:0]   cfg_interrupt_msix_data,

  input wire                      	req_compl,
  input wire                      	req_compl_wd,
  input wire                      	req_compl_ur,
  input wire                      	compl_done,
  
  
  output                           req_completion,
  output                           completion_done

);



  //
  // Local-Link Receive Controller
  //

  pio_rx_engine #(
    .TCQ(TCQ),
    .AXISTEN_IF_WIDTH               ( AXISTEN_IF_WIDTH ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE   ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE   ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_STRADDLE         ( AXISTEN_IF_RC_STRADDLE ),
    .AXISTEN_IF_ENABLE_RX_MSG_INTFC ( AXISTEN_IF_ENABLE_RX_MSG_INTFC ),
    .AXISTEN_IF_ENABLE_MSG_ROUTE    ( AXISTEN_IF_ENABLE_MSG_ROUTE )
  ) ep_rx (

    .user_clk( user_clk ),
    .reset_n( reset_n ),
    .cfg_msg_received( cfg_msg_received ),
    .cfg_msg_received_type( cfg_msg_received_type ),
    .cfg_msg_data( cfg_msg_data )
  );

    //
    // Local-Link Transmit Controller
    //

  pio_tx_engine #(
    .TCQ( TCQ ),
    .AXISTEN_IF_WIDTH             ( AXISTEN_IF_WIDTH ),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_ENABLE_CLIENT_TAG ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
    .AXISTEN_IF_RQ_PARITY_CHECK   ( AXISTEN_IF_RQ_PARITY_CHECK ),
    .AXISTEN_IF_CC_PARITY_CHECK   ( AXISTEN_IF_CC_PARITY_CHECK )
  ) ep_tx (
    .user_clk( user_clk ),
    .reset_n( reset_n ),

    // TX Message Interface

    .cfg_msg_transmit_done( cfg_msg_transmit_done ),
    .cfg_msg_transmit( cfg_msg_transmit ),
    .cfg_msg_transmit_type( cfg_msg_transmit_type ),
    .cfg_msg_transmit_data( cfg_msg_transmit_data ),

     // Cfg Flow Control Information

    .cfg_fc_ph( cfg_fc_ph ),
    .cfg_fc_nph( cfg_fc_nph ),
    .cfg_fc_cplh( cfg_fc_cplh ),
    .cfg_fc_pd( cfg_fc_pd ),
    .cfg_fc_npd( cfg_fc_npd ),
    .cfg_fc_cpld( cfg_fc_cpld ),
    .cfg_fc_sel( cfg_fc_sel )
    );

  pio_intr_ctrl ep_intr_ctrl(

    .user_clk( user_clk ),
    .reset_n( reset_n ),

    // Trigger to generate interrupts (to / from Mem access Block)

    .gen_leg_intr( gen_leg_intr ),
    .gen_msi_intr( gen_msi_intr ),
    .gen_msix_intr( gen_msix_intr ),
    .interrupt_done( interrupt_done ),

    // Legacy Interrupt Interface

    .cfg_interrupt_sent( cfg_interrupt_sent ),
    .cfg_interrupt_int( cfg_interrupt_int ),

    // MSI Interrupt Interface

    // .cfg_interrupt_msi_enable( cfg_interrupt_msi_enable ),
    // .cfg_interrupt_msi_sent( cfg_interrupt_msi_sent ),
    // .cfg_interrupt_msi_fail( cfg_interrupt_msi_fail ),

    // .cfg_interrupt_msi_int( cfg_interrupt_msi_int ),

    //MSI-X Interrupt Interface

    .cfg_interrupt_msix_enable( cfg_interrupt_msix_enable ),
    .cfg_interrupt_msix_sent( cfg_interrupt_msix_sent ),
    .cfg_interrupt_msix_fail( cfg_interrupt_msix_fail ),

    .cfg_interrupt_msix_int( cfg_interrupt_msix_int ),
    .cfg_interrupt_msix_address( cfg_interrupt_msix_address ),
    .cfg_interrupt_msix_data( cfg_interrupt_msix_data )

    );

    assign req_completion = req_compl || req_compl_wd || req_compl_ur;
    assign completion_done = compl_done || interrupt_done ;

endmodule // pio_ep



