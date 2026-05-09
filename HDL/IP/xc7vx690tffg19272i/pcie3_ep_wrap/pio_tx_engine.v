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
// File       : pio_tx_engine.v
// Version    : 4.4 
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
// File       : pio_tx_engine.v
// Version    : 1.3
//
// Description: Local-Link Transmit Unit.
//
//--------------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_tx_engine    #(

  parameter        TCQ = 1,
  parameter [1:0] AXISTEN_IF_WIDTH = 00,
  parameter       AXISTEN_IF_RQ_ALIGNMENT_MODE = "FALSE",
  parameter       AXISTEN_IF_CC_ALIGNMENT_MODE = "FALSE",
  parameter       AXISTEN_IF_ENABLE_CLIENT_TAG = 0,
  parameter       AXISTEN_IF_RQ_PARITY_CHECK   = 0,
  parameter       AXISTEN_IF_CC_PARITY_CHECK   = 0,

  //Do not modify the parameters below this line
  parameter C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0])? 128 : 64,
  parameter PARITY_WIDTH = C_DATA_WIDTH /8,
  parameter KEEP_WIDTH   = C_DATA_WIDTH /32,
  parameter STRB_WIDTH   = C_DATA_WIDTH / 8
)(

  input                          user_clk,
  input                          reset_n,

  input                          cfg_msg_transmit_done,
  output reg                     cfg_msg_transmit,
  output reg              [2:0]  cfg_msg_transmit_type,
  output reg             [31:0]  cfg_msg_transmit_data,

  input                   [7:0]  cfg_fc_ph,
  input                   [7:0]  cfg_fc_nph,
  input                   [7:0]  cfg_fc_cplh,
  input                  [11:0]  cfg_fc_pd,
  input                  [11:0]  cfg_fc_npd,
  input                  [11:0]  cfg_fc_cpld,
  output                  [2:0]  cfg_fc_sel

);

always@(posedge	user_clk)	begin
	cfg_msg_transmit		<=	0	;
	cfg_msg_transmit_type	<=	0	;
	cfg_msg_transmit_data	<=	0	;
end

 // CFG func sel
 assign cfg_fc_sel = 3'b100;


endmodule // pio_tx_engine
