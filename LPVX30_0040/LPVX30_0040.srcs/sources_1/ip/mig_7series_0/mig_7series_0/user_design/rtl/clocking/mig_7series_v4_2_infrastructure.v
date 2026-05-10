//*****************************************************************************
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
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
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: %version
//  \   \         Application: MIG
//  /   /         Filename: infrastructure.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 08:34:56 $
// \   \  /  \    Date Created:Tue Jun 30 2009
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose:
//   Clock generation/distribution and reset synchronization
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: infrastructure.v,v 1.1 2011/06/02 08:34:56 mishra Exp $
**$Date: 2011/06/02 08:34:56 $
**$Author: mishra $
**$Revision: 1.1 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_3/data/dlib/7series/ddr3_sdram/verilog/rtl/clocking/infrastructure.v,v $
******************************************************************************/

`timescale 1ps/1ps


module mig_7series_v4_2_infrastructure #
  (
   parameter CALIB_FAST      ="FASLE",
   parameter SIMULATION      = "FALSE",  // Should be TRUE during design simulations and
                                         // FALSE during implementations
   parameter TCQ             = 100,      // clk->out delay (sim only)
   parameter CLKIN_PERIOD    = 3000,     // Memory clock period
   parameter nCK_PER_CLK     = 2,        // Fabric clk period:Memory clk period
   parameter SYSCLK_TYPE     = "DIFFERENTIAL",
                                         // input clock type
                                         // "DIFFERENTIAL","SINGLE_ENDED"
   parameter UI_EXTRA_CLOCKS = "FALSE",
                                         // Generates extra clocks as
                                         // 1/2, 1/4 and 1/8 of fabrick clock.
                                         // Valid for DDR2/DDR3 AXI interfaces
                                         // based on GUI selection
   parameter CLKFBOUT_MULT   = 4,        // write PLL VCO multiplier
   parameter DIVCLK_DIVIDE   = 1,        // write PLL VCO divisor
   parameter CLKOUT0_PHASE   = 45.0,     // VCO output divisor for clkout0
   parameter CLKOUT0_DIVIDE   = 16,      // VCO output divisor for PLL clkout0
   parameter CLKOUT1_DIVIDE   = 4,       // VCO output divisor for PLL clkout1
   parameter CLKOUT2_DIVIDE   = 64,      // VCO output divisor for PLL clkout2
   parameter CLKOUT3_DIVIDE   = 16,      // VCO output divisor for PLL clkout3
   parameter MMCM_VCO             = 1200,     // Max Freq (MHz) of MMCM VCO
   parameter MMCM_MULT_F          = 4,        // write MMCM VCO multiplier
   parameter MMCM_DIVCLK_DIVIDE   = 1,        // write MMCM VCO divisor
   parameter MMCM_CLKOUT0_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout0
   parameter MMCM_CLKOUT1_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout1
   parameter MMCM_CLKOUT2_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout2
   parameter MMCM_CLKOUT3_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout3
   parameter MMCM_CLKOUT4_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout4
   parameter MMCM_CLKOUT0_DIVIDE   = 1,  // VCO output divisor for MMCM clkout0
   parameter MMCM_CLKOUT1_DIVIDE   = 1,  // VCO output divisor for MMCM clkout1
   parameter MMCM_CLKOUT2_DIVIDE   = 1,  // VCO output divisor for MMCM clkout2
   parameter MMCM_CLKOUT3_DIVIDE   = 1,  // VCO output divisor for MMCM clkout3
   parameter MMCM_CLKOUT4_DIVIDE   = 1,  // VCO output divisor for MMCM clkout4
   parameter RST_ACT_LOW           = 1,
   parameter tCK                   = 1250,
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   parameter MEM_TYPE              = "DDR3",
   parameter ADJ_LEVEL = 0
   )
  (
   input init_calib_complete,
   input calib_error,
   input drp_clk,
   // Clock inputs
   input  mmcm_clk,           // System clock diff input
   // System reset input
   input  sys_rst,            // core reset from user application
   // PLLE2/IDELAYCTRL Lock status
   input  [1:0] iodelay_ctrl_rdy,   // IDELAYCTRL lock status
   // Clock outputs

   output clk,                // fabric clock freq ; either  half rate or quarter rate and is
                              // determined by  PLL parameters settings.
   output clk_div2,           // mem_refclk divided by 2 for PI incdec
   output rst_div2,           // reset in clk_div2 domain
   output mem_refclk,         // equal to  memory clock
   output freq_refclk,        // freq above 400 MHz:  set freq_refclk = mem_refclk
                              // freq below 400 MHz:  set freq_refclk = 2* mem_refclk or 4* mem_refclk;
                              // to hard PHY for phaser
   output sync_pulse,         // exactly 1/16 of mem_refclk and the sync pulse is exactly 1 memref_clk wide
//   output auxout_clk,         // IO clk used to clock out Aux_Out ports
   output mmcm_ps_clk,        // Phase shift clock
   output poc_sample_pd,      // Tell POC when to sample phase detector output.
   output ui_addn_clk_0,      // MMCM out0 clk
   output ui_addn_clk_1,      // MMCM out1 clk
   output ui_addn_clk_2,      // MMCM out2 clk
   output ui_addn_clk_3,      // MMCM out3 clk
   output ui_addn_clk_4,      // MMCM out4 clk
   output pll_locked,         // locked output from PLLE2_ADV
   output mmcm_locked,        // locked output from MMCME2_ADV
   // Reset outputs
   output rstdiv0,             // Reset CLK and CLKDIV logic (incl I/O),
   output iddr_rst

   ,output rst_phaser_ref
   ,input  ref_dll_lock
   ,input  psen
   ,input  psincdec
   ,output psdone
   ,output reg [3:0] adj_flag
   );

  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on DCM lock status)
  localparam RST_SYNC_NUM = 25;

  // Round up for clk reset delay to ensure that CLKDIV reset deassertion
  // occurs at same time or after CLK reset deassertion (still need to
  // consider route delay - add one or two extra cycles to be sure!)
  localparam RST_DIV_SYNC_NUM = (RST_SYNC_NUM+1)/2;

  // Input clock is assumed to be equal to the memory clock frequency
  // User should change the parameter as necessary if a different input
  // clock frequency is used
  localparam real CLKIN1_PERIOD_NS = CLKIN_PERIOD / 1000.0;
  localparam CLKOUT4_DIVIDE = 2 * CLKOUT1_DIVIDE;

  localparam integer VCO_PERIOD
             = (CLKIN1_PERIOD_NS * DIVCLK_DIVIDE * 1000) / CLKFBOUT_MULT;

  localparam CLKOUT0_PERIOD = VCO_PERIOD * CLKOUT0_DIVIDE;
  localparam CLKOUT1_PERIOD = VCO_PERIOD * CLKOUT1_DIVIDE;
  localparam CLKOUT2_PERIOD = VCO_PERIOD * CLKOUT2_DIVIDE;
  localparam CLKOUT3_PERIOD = VCO_PERIOD * CLKOUT3_DIVIDE;
  localparam CLKOUT4_PERIOD = VCO_PERIOD * CLKOUT4_DIVIDE;

  localparam CLKOUT4_PHASE  = (SIMULATION == "TRUE") ? 22.5 : 168.75;

  localparam real CLKOUT3_PERIOD_NS = CLKOUT3_PERIOD / 1000.0;
  localparam real CLKOUT4_PERIOD_NS = CLKOUT4_PERIOD / 1000.0;

  //synthesis translate_off
  initial begin
    $display("############# Write Clocks PLLE2_ADV Parameters #############\n");
    $display("nCK_PER_CLK      = %7d",   nCK_PER_CLK     );
    $display("CLK_PERIOD       = %7d",   CLKIN_PERIOD    );
    $display("CLKIN1_PERIOD    = %7.3f", CLKIN1_PERIOD_NS);
    $display("DIVCLK_DIVIDE    = %7d",   DIVCLK_DIVIDE   );
    $display("CLKFBOUT_MULT    = %7d",   CLKFBOUT_MULT );
    $display("VCO_PERIOD       = %7.1f", VCO_PERIOD      );
    $display("CLKOUT0_DIVIDE_F = %7d",   CLKOUT0_DIVIDE  );
    $display("CLKOUT1_DIVIDE   = %7d",   CLKOUT1_DIVIDE  );
    $display("CLKOUT2_DIVIDE   = %7d",   CLKOUT2_DIVIDE  );
    $display("CLKOUT3_DIVIDE   = %7d",   CLKOUT3_DIVIDE  );
    $display("CLKOUT0_PERIOD   = %7d",   CLKOUT0_PERIOD  );
    $display("CLKOUT1_PERIOD   = %7d",   CLKOUT1_PERIOD  );
    $display("CLKOUT2_PERIOD   = %7d",   CLKOUT2_PERIOD  );
    $display("CLKOUT3_PERIOD   = %7d",   CLKOUT3_PERIOD  );
    $display("CLKOUT4_PERIOD   = %7d",   CLKOUT4_PERIOD  );
    $display("############################################################\n");
  end
  //synthesis translate_on

  wire                       clk_bufg;
  wire                       clk_pll_i;
  wire                       clkfbout_pll;
  wire                       pll_clkfbout;
  wire                       pll_locked_i
                             /* synthesis syn_maxfan = 10 */;
  (* max_fanout = 50 *) reg [RST_DIV_SYNC_NUM-2:0] rstdiv0_sync_r;
  wire                       rst_tmp;
  (* max_fanout = 50 *) reg rstdiv0_sync_r1
                            /* synthesis syn_maxfan = 50 */;
  reg [RST_DIV_SYNC_NUM-2:0] rst_sync_r;
 (* max_fanout = 10  *) reg rst_sync_r1
                             /* synthesis syn_maxfan = 10 */;
  reg [RST_DIV_SYNC_NUM-2:0] rstdiv2_sync_r;
  (* max_fanout = 10  *) reg rstdiv2_sync_r1
                             /* synthesis syn_maxfan = 10 */;
  wire                       sys_rst_act_hi;

  wire                       rst_tmp_phaser_ref;
  (* max_fanout = 50 *) reg [RST_DIV_SYNC_NUM-1:0] rst_phaser_ref_sync_r
                             /* synthesis syn_maxfan = 10 */;

  // Instantiation of the MMCM primitive
  wire        clkfbout;
  wire        MMCM_Locked_i;

  wire        mmcm_clkout0;
  wire        mmcm_clkout1;
  wire        mmcm_clkout2;
  wire        mmcm_clkout3;
  wire        mmcm_clkout4;
  wire        mmcm_ps_clk_bufg_in;
  wire        clk_div2_bufg_in;

  wire        pll_clk3_out;
  wire        pll_clk3;

  assign sys_rst_act_hi = RST_ACT_LOW ? ~sys_rst: sys_rst;

  //***************************************************************************
  // Assign global clocks:
  //   2. clk     : Half rate / Quarter rate(used for majority of internal logic)
  //***************************************************************************

  assign clk        = clk_bufg;
  assign pll_locked = pll_locked_i & MMCM_Locked_i;
  assign mmcm_locked = MMCM_Locked_i;


  //***************************************************************************
  // Global base clock generation and distribution
  //***************************************************************************

  //*****************************************************************
  // NOTES ON CALCULTING PROPER VCO FREQUENCY
  //  1. VCO frequency =
  //     1/((DIVCLK_DIVIDE * CLKIN_PERIOD)/(CLKFBOUT_MULT * nCK_PER_CLK))
  //  2. VCO frequency must be in the range [TBD, TBD]
  //*****************************************************************

wire [15:0]DO;
wire [15:0]DI;
wire [6:0]DADDR;
(* ASYNC_REG = "TRUE" *)  reg [1:0] sys_rst_act_hi_sync_r;
(* ASYNC_REG = "TRUE" *)  reg [1:0] init_calib_complete_r;
(* ASYNC_REG = "TRUE" *)  reg [1:0] pll_locked_i_r;
(* ASYNC_REG = "TRUE" *)  reg [2:0] calib_error_r;
wire calib_error_posedge;
reg [3:0] adj_flag_r1;
  PLLE2_ADV #
    (
     .BANDWIDTH          ("OPTIMIZED"),
     .COMPENSATION       ("INTERNAL"),
     .STARTUP_WAIT       ("FALSE"),
     .CLKOUT0_DIVIDE     (CLKOUT0_DIVIDE),  // 4 freq_ref
     .CLKOUT1_DIVIDE     (CLKOUT1_DIVIDE),  // 4 mem_ref
     .CLKOUT2_DIVIDE     (CLKOUT2_DIVIDE),  // 16 sync
     .CLKOUT3_DIVIDE     (CLKOUT3_DIVIDE),  // 16 sysclk
     .CLKOUT4_DIVIDE     (CLKOUT4_DIVIDE),
     .CLKOUT5_DIVIDE     (),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKFBOUT_MULT      (CLKFBOUT_MULT),
     .CLKFBOUT_PHASE     (0.000),
     .CLKIN1_PERIOD      (CLKIN1_PERIOD_NS),
     .CLKIN2_PERIOD      (),
     .CLKOUT0_DUTY_CYCLE (0.500),
     .CLKOUT0_PHASE      (CLKOUT0_PHASE),
     .CLKOUT1_DUTY_CYCLE (0.500),
     .CLKOUT1_PHASE      (0.000),
     .CLKOUT2_DUTY_CYCLE (1.0/16.0),
     .CLKOUT2_PHASE      (9.84375),     // PHASE shift is required for sync pulse generation.
     .CLKOUT3_DUTY_CYCLE (0.500),
     .CLKOUT3_PHASE      (0.000),
     .CLKOUT4_DUTY_CYCLE (0.500),
     .CLKOUT4_PHASE      (CLKOUT4_PHASE),
     .CLKOUT5_DUTY_CYCLE (0.500),
     .CLKOUT5_PHASE      (0.000),
     .REF_JITTER1        (0.010),
     .REF_JITTER2        (0.010)
     )
    plle2_i
      (
       .CLKFBOUT (pll_clkfbout),
       .CLKOUT0  (freq_refclk),
       .CLKOUT1  (mem_refclk),
       .CLKOUT2  (sync_pulse),  // always 1/16 of mem_ref_clk
       .CLKOUT3  (pll_clk3_out),
//       .CLKOUT4  (auxout_clk_i),
       .CLKOUT4  (),
       .CLKOUT5  (),
       .DO       (DO),
       .DRDY     (DRDY),
       .LOCKED   (pll_locked_i),
       .CLKFBIN  (pll_clkfbout),
       .CLKIN1   (mmcm_clk),
       .CLKIN2   (),
       .CLKINSEL (1'b1),
       .DADDR    (DADDR),
       .DCLK     (DCLK),
       .DEN      (DEN),
       .DI       (DI),
       .DWE      (DWE),
       .PWRDWN   (1'b0),
       .RST      ( sys_rst_act_hi | RST_PLL | rst_adj)
       );


//  BUFH u_bufh_auxout_clk
//    (
//     .O (auxout_clk),
//     .I (auxout_clk_i)
//     );

  BUFG u_bufg_clkdiv0
    (
     .O (clk_bufg),
     .I (clk_pll_i)
     );

  BUFH u_bufh_pll_clk3
    (
     .O (pll_clk3),
     .I (pll_clk3_out)
     );

  localparam  real    MMCM_VCO_PERIOD       = 1000000.0/MMCM_VCO;

  //synthesis translate_off
  initial begin
    $display("############# MMCME2_ADV Parameters #############\n");
    $display("MMCM_MULT_F           = %d", MMCM_MULT_F);
//    $display("MMCM_VCO_FREQ (MHz)   = %7.3f", MMCM_VCO*1000.0);
    $display("MMCM_VCO_FREQ (MHz)   = %7.3f", MMCM_VCO*1.000);
    $display("MMCM_VCO_PERIOD       = %7.3f", MMCM_VCO_PERIOD);
    $display("#################################################\n");
  end
  //synthesis translate_on

  generate
    if (UI_EXTRA_CLOCKS == "TRUE") begin: gen_ui_extra_clocks

      localparam MMCM_CLKOUT0_DIVIDE_CAL = (MMCM_CLKOUT0_EN == "TRUE") ? MMCM_CLKOUT0_DIVIDE : MMCM_MULT_F;
      localparam MMCM_CLKOUT1_DIVIDE_CAL = (MMCM_CLKOUT1_EN == "TRUE") ? MMCM_CLKOUT1_DIVIDE : MMCM_MULT_F;
      localparam MMCM_CLKOUT2_DIVIDE_CAL = (MMCM_CLKOUT2_EN == "TRUE") ? MMCM_CLKOUT2_DIVIDE : MMCM_MULT_F;
      localparam MMCM_CLKOUT3_DIVIDE_CAL = (MMCM_CLKOUT3_EN == "TRUE") ? MMCM_CLKOUT3_DIVIDE : MMCM_MULT_F;
      localparam MMCM_CLKOUT4_DIVIDE_CAL = (MMCM_CLKOUT4_EN == "TRUE") ? MMCM_CLKOUT4_DIVIDE : MMCM_MULT_F;

      MMCME2_ADV
      #(.BANDWIDTH            ("HIGH"),
        .CLKOUT4_CASCADE      ("FALSE"),
        .COMPENSATION         ("BUF_IN"),
        .STARTUP_WAIT         ("FALSE"),
//        .DIVCLK_DIVIDE        (1),
        .DIVCLK_DIVIDE        (MMCM_DIVCLK_DIVIDE),
        .CLKFBOUT_MULT_F      (MMCM_MULT_F),
        .CLKFBOUT_PHASE       (0.000),
        .CLKFBOUT_USE_FINE_PS ("FALSE"),
        .CLKOUT0_DIVIDE_F     (MMCM_CLKOUT0_DIVIDE_CAL),
        .CLKOUT0_PHASE        (0.000),
        .CLKOUT0_DUTY_CYCLE   (0.500),
        .CLKOUT0_USE_FINE_PS  ("FALSE"),
        .CLKOUT1_DIVIDE       (MMCM_CLKOUT1_DIVIDE_CAL),
        .CLKOUT1_PHASE        (0.000),
        .CLKOUT1_DUTY_CYCLE   (0.500),
        .CLKOUT1_USE_FINE_PS  ("FALSE"),
        .CLKOUT2_DIVIDE       (MMCM_CLKOUT2_DIVIDE_CAL),
        .CLKOUT2_PHASE        (0.000),
        .CLKOUT2_DUTY_CYCLE   (0.500),
        .CLKOUT2_USE_FINE_PS  ("FALSE"),
        .CLKOUT3_DIVIDE       (MMCM_CLKOUT3_DIVIDE_CAL),
        .CLKOUT3_PHASE        (0.000),
        .CLKOUT3_DUTY_CYCLE   (0.500),
        .CLKOUT3_USE_FINE_PS  ("FALSE"),
        .CLKOUT4_DIVIDE       (MMCM_CLKOUT4_DIVIDE_CAL),
        .CLKOUT4_PHASE        (0.000),
        .CLKOUT4_DUTY_CYCLE   (0.500),
        .CLKOUT4_USE_FINE_PS  ("FALSE"),
        .CLKOUT5_DIVIDE       (((MMCM_MULT_F*2)/MMCM_DIVCLK_DIVIDE)),
        .CLKOUT5_PHASE        (0.000),
        .CLKOUT5_DUTY_CYCLE   (0.500),
        .CLKOUT5_USE_FINE_PS  ("TRUE"),
        .CLKOUT6_DIVIDE       (MMCM_MULT_F/2),
        .CLKOUT6_PHASE        (0.000),
        .CLKOUT6_DUTY_CYCLE   (0.500),
        .CLKOUT6_USE_FINE_PS  ("FALSE"),
        .CLKIN1_PERIOD        (CLKOUT3_PERIOD_NS),
        .REF_JITTER1          (0.000))
      mmcm_i
        // Output clocks
       (.CLKFBOUT            (clk_pll_i),
        .CLKFBOUTB           (),
        .CLKOUT0             (mmcm_clkout0),
        .CLKOUT0B            (),
        .CLKOUT1             (mmcm_clkout1),
        .CLKOUT1B            (),
        .CLKOUT2             (mmcm_clkout2),
        .CLKOUT2B            (),
        .CLKOUT3             (mmcm_clkout3),
        .CLKOUT3B            (),
        .CLKOUT4             (mmcm_clkout4),
        .CLKOUT5             (mmcm_ps_clk_bufg_in),
        .CLKOUT6             (clk_div2_bufg_in),
         // Input clock control
        .CLKFBIN             (clk_bufg),      // From BUFH network
        .CLKIN1              (pll_clk3),      // From PLL
        .CLKIN2              (1'b0),
         // Tied to always select the primary input clock
        .CLKINSEL            (1'b1),
        // Ports for dynamic reconfiguration
        .DADDR               (7'h0),
        .DCLK                (1'b0),
        .DEN                 (1'b0),
        .DI                  (16'h0),
        .DO                  (),
        .DRDY                (),
        .DWE                 (1'b0),
        // Ports for dynamic phase shift
        .PSCLK               (clk),
        .PSEN                (psen),
        .PSINCDEC            (psincdec),
        .PSDONE              (psdone),
        // Other control and status signals
        .LOCKED              (MMCM_Locked_i),
        .CLKINSTOPPED        (),
        .CLKFBSTOPPED        (),
        .PWRDWN              (1'b0),
        .RST                 (~pll_locked_i));

      BUFG u_bufg_ui_addn_clk_0
        (
         .O (ui_addn_clk_0),
         .I (mmcm_clkout0)
         );

      BUFG u_bufg_ui_addn_clk_1
        (
         .O (ui_addn_clk_1),
         .I (mmcm_clkout1)
         );

      BUFG u_bufg_ui_addn_clk_2
        (
         .O (ui_addn_clk_2),
         .I (mmcm_clkout2)
         );

      BUFG u_bufg_ui_addn_clk_3
        (
         .O (ui_addn_clk_3),
         .I (mmcm_clkout3)
         );

      BUFG u_bufg_ui_addn_clk_4
        (
         .O (ui_addn_clk_4),
         .I (mmcm_clkout4)
         );

      BUFG u_bufg_mmcm_ps_clk
        (
         .O (mmcm_ps_clk),
         .I (mmcm_ps_clk_bufg_in)
         );
       
      BUFG u_bufg_clk_div2
        (
         .O (clk_div2),
         .I (clk_div2_bufg_in)
         );
    end else begin: gen_mmcm

      MMCME2_ADV
      #(.BANDWIDTH            ("HIGH"),
        .CLKOUT4_CASCADE      ("FALSE"),
        .COMPENSATION         ("BUF_IN"),
        .STARTUP_WAIT         ("FALSE"),
//        .DIVCLK_DIVIDE        (1),
        .DIVCLK_DIVIDE        (MMCM_DIVCLK_DIVIDE),
        .CLKFBOUT_MULT_F      (MMCM_MULT_F),
        .CLKFBOUT_PHASE       (0.000),
        .CLKFBOUT_USE_FINE_PS ("FALSE"),
        .CLKOUT0_DIVIDE_F     (((MMCM_MULT_F*2)/MMCM_DIVCLK_DIVIDE)),
        .CLKOUT0_PHASE        (0.000),
        .CLKOUT0_DUTY_CYCLE   (0.500),
        .CLKOUT0_USE_FINE_PS  ("TRUE"),
        .CLKOUT1_DIVIDE       (MMCM_MULT_F/2),
        .CLKOUT1_PHASE        (0.000),
        .CLKOUT1_DUTY_CYCLE   (0.500),
        .CLKOUT1_USE_FINE_PS  ("FALSE"),
        .CLKIN1_PERIOD        (CLKOUT3_PERIOD_NS),
        .REF_JITTER1          (0.000))
      mmcm_i
        // Output clocks
       (.CLKFBOUT            (clk_pll_i),
        .CLKFBOUTB           (),
        .CLKOUT0             (mmcm_ps_clk_bufg_in),
        .CLKOUT0B            (),
        .CLKOUT1             (clk_div2_bufg_in),
        .CLKOUT1B            (),
        .CLKOUT2             (),
        .CLKOUT2B            (),
        .CLKOUT3             (),
        .CLKOUT3B            (),
        .CLKOUT4             (),
        .CLKOUT5             (),
        .CLKOUT6             (),
         // Input clock control
        .CLKFBIN             (clk_bufg),      // From BUFH network
        .CLKIN1              (pll_clk3),      // From PLL
        .CLKIN2              (1'b0),
         // Tied to always select the primary input clock
        .CLKINSEL            (1'b1),
        // Ports for dynamic reconfiguration
        .DADDR               (7'h0),
        .DCLK                (1'b0),
        .DEN                 (1'b0),
        .DI                  (16'h0),
        .DO                  (),
        .DRDY                (),
        .DWE                 (1'b0),
        // Ports for dynamic phase shift
        .PSCLK               (clk),
        .PSEN                (psen),
        .PSINCDEC            (psincdec),
        .PSDONE              (psdone),
        // Other control and status signals
        .LOCKED              (MMCM_Locked_i),
        .CLKINSTOPPED        (),
        .CLKFBSTOPPED        (),
        .PWRDWN              (1'b0),
        .RST                 (~pll_locked_i));

    BUFG u_bufg_mmcm_ps_clk
    (
     .O (mmcm_ps_clk),
     .I (mmcm_ps_clk_bufg_in)
     );
	 
    BUFG u_bufg_clk_div2
    (
     .O (clk_div2),
     .I (clk_div2_bufg_in)
     );
	 
    end // block: gen_mmcm
  endgenerate

  //***************************************************************************
  // Generate poc_sample_pd.
  //
  // As the phase shift clocks precesses around kclk, it also precesses
  // around the fabric clock.  Noise may be generated as output of the
  // IDDR is registered into the fabric clock domain.
  //
  // The mmcm_ps_clk signal runs at half the rate of the fabric clock.
  // This means that there are two rising edges of fabric clock per mmcm_ps_clk.
  // If we can guarantee that the POC uses the data sampled on the second
  // fabric clock, then we are certain that the setup time to the second
  // fabric clock is greater than 1 fabric clock cycle.
  //
  // To predict when the phase detctor output is from this second edge, we
  // need to know two things.  The initial phase of fabric clock and mmcm_ps_clk
  // and the number of phase offsets set into the mmcm.  The later is a
  // trivial count of the PSEN signal.
  //
  // The former is a bit tricky because latching a clock with a clock is
  // not well defined.  This problem is solved by generating a signal
  // the goes high on the first rising edge of mmcm_ps_clk.  Logic in
  // the fabric domain can look at this signal and then develop an analog
  // the mmcm_ps_clk with zero offset.
  //
  // This all depends on the timing tools making the timing work when
  // when the mmcm phase offset is zero.
  //
  // poc_sample_pd tells the POC when to sample the phase detector output.
  // Setup from the IDDR to the fabric clock is always one plus some
  // fraction of the fabric clock.
  //***************************************************************************

  localparam ONE = 1;
  localparam integer TAPSPERFCLK = 56 * MMCM_MULT_F;
  localparam TAPSPERFCLK_MINUS_ONE = TAPSPERFCLK - 1;
  localparam QCNTR_WIDTH = clogb2(TAPSPERFCLK);
  
  function integer clogb2 (input integer size); // ceiling logb2
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
            size = size >> 1;
    end
  endfunction // clogb2

  reg [QCNTR_WIDTH-1:0] qcntr_ns, qcntr_r;
  always @(posedge clk) qcntr_r <= #TCQ qcntr_ns;

  reg inv_poc_sample_ns, inv_poc_sample_r;
  always @(posedge clk) inv_poc_sample_r <= #TCQ inv_poc_sample_ns;
  
  always @(*) begin
    qcntr_ns = qcntr_r;
    inv_poc_sample_ns = inv_poc_sample_r;
    if (rstdiv0) begin
      qcntr_ns = 'b0;
      inv_poc_sample_ns = 'b0;
    end else if (psen) begin
      if (qcntr_r < TAPSPERFCLK_MINUS_ONE[QCNTR_WIDTH-1:0])
        qcntr_ns = (qcntr_r + ONE[QCNTR_WIDTH-1:0]);
      else begin
        qcntr_ns = {QCNTR_WIDTH{1'b0}};
	inv_poc_sample_ns = ~inv_poc_sample_r;
      end
    end
  end 

  // Be vewy vewy careful to make sure this path is aligned with the
  // phase detector out pipeline.  
  reg first_rising_ps_clk_ns, first_rising_ps_clk_r;
  always @(posedge mmcm_ps_clk) first_rising_ps_clk_r <= #TCQ first_rising_ps_clk_ns;
  always @(*) first_rising_ps_clk_ns = ~rstdiv0;

  reg mmcm_hi0_ns, mmcm_hi0_r;
  always @(posedge clk) mmcm_hi0_r <= #TCQ mmcm_hi0_ns;
  always @(*) mmcm_hi0_ns = ~first_rising_ps_clk_r || ~mmcm_hi0_r;

  reg poc_sample_pd_ns, poc_sample_pd_r;
  always @(*) poc_sample_pd_ns = inv_poc_sample_ns ^ mmcm_hi0_r;
  always @(posedge clk) poc_sample_pd_r <= #TCQ poc_sample_pd_ns;
  assign poc_sample_pd = poc_sample_pd_r;

  //***************************************************************************
  // Make sure logic acheives 90 degree setup time from rising mmcm_ps_clk
  // to the appropriate edge of fabric clock
  //***************************************************************************

  //synthesis translate_off
  generate 
    if ( tCK <= 2500 ) begin : check_ocal_timing
      localparam CLK_PERIOD_PS = MMCM_VCO_PERIOD * MMCM_MULT_F;
      localparam integer CLK_PERIOD_PS_DIV4 = CLK_PERIOD_PS/4;

      time rising_mmcm_ps_clk;
      always @(posedge mmcm_ps_clk) rising_mmcm_ps_clk = $time();

      time pdiff;  // Not used, except in waveform plots.
      always @(posedge clk) pdiff = $time() - rising_mmcm_ps_clk;
    end
  endgenerate

  //synthesis translate_on

  //***************************************************************************
  // RESET SYNCHRONIZATION DESCRIPTION:
  //  Various resets are generated to ensure that:
  //   1. All resets are synchronously deasserted with respect to the clock
  //      domain they are interfacing to. There are several different clock
  //      domains - each one will receive a synchronized reset.
  //   2. The reset deassertion order starts with deassertion of SYS_RST,
  //      followed by deassertion of resets for various parts of the design
  //      (see "RESET ORDER" below) based on the lock status of PLLE2s.
  // RESET ORDER:
  //   1. User deasserts SYS_RST
  //   2. Reset PLLE2 and IDELAYCTRL
  //   3. Wait for PLLE2 and IDELAYCTRL to lock
  //   4. Release reset for all I/O primitives and internal logic
  // OTHER NOTES:
  //   1. Asynchronously assert reset. This way we can assert reset even if
  //      there is no clock (needed for things like 3-stating output buffers
  //      to prevent initial bus contention). Reset deassertion is synchronous.
  //***************************************************************************

  //*****************************************************************
  // CLKDIV logic reset
  //*****************************************************************

  // Wait for PLLE2 and IDELAYCTRL to lock before releasing reset

  // current O,25.0 unisim phaser_ref never locks.  Need to find out why .
  generate
    if (MEM_TYPE == "DDR3" && tCK <= 1500) begin: rst_tmp_300_400
      assign rst_tmp = sys_rst_act_hi | ~iodelay_ctrl_rdy[1] |
                       ~ref_dll_lock | ~MMCM_Locked_i;
    end else begin: rst_tmp_200
      assign rst_tmp = sys_rst_act_hi | ~iodelay_ctrl_rdy[0] |
                       ~ref_dll_lock | ~MMCM_Locked_i;
    end
  endgenerate

  always @(posedge clk_bufg or posedge rst_tmp) begin
    if (rst_tmp) begin
      rstdiv0_sync_r  <= #TCQ {RST_DIV_SYNC_NUM-1{1'b1}};
      rstdiv0_sync_r1 <= #TCQ 1'b1 ;
    end else begin
      rstdiv0_sync_r  <= #TCQ rstdiv0_sync_r << 1;
      rstdiv0_sync_r1 <= #TCQ rstdiv0_sync_r[RST_DIV_SYNC_NUM-2];
    end
  end

  assign rstdiv0 = rstdiv0_sync_r1 ;

//IDDR rest
  always @(posedge mmcm_ps_clk  or posedge rst_tmp) begin
    if (rst_tmp) begin
      rst_sync_r  <= #TCQ {RST_DIV_SYNC_NUM-1{1'b1}};
      rst_sync_r1 <= #TCQ 1'b1 ;
    end else begin
      rst_sync_r  <= #TCQ rst_sync_r << 1;
      rst_sync_r1 <= #TCQ rst_sync_r[RST_DIV_SYNC_NUM-2];
    end
  end

  assign iddr_rst = rst_sync_r1 ;
  
// Sync reset in the clk_div2 domain
  always @(posedge clk_div2  or posedge rst_tmp) begin
    if (rst_tmp) begin
      rstdiv2_sync_r  <= #TCQ {RST_DIV_SYNC_NUM-1{1'b1}};
      rstdiv2_sync_r1 <= #TCQ 1'b1 ;
    end else begin
      rstdiv2_sync_r  <= #TCQ rstdiv2_sync_r << 1;
      rstdiv2_sync_r1 <= #TCQ rstdiv2_sync_r[RST_DIV_SYNC_NUM-2];
    end
  end

  assign rst_div2 = rstdiv2_sync_r1 ;

  generate
    if (MEM_TYPE == "DDR3" && tCK <= 1500) begin: rst_tmp_phaser_ref_300_400
      assign rst_tmp_phaser_ref = sys_rst_act_hi | ~MMCM_Locked_i | ~iodelay_ctrl_rdy[1];
    end else begin: rst_tmp_phaser_ref_200
      assign rst_tmp_phaser_ref = sys_rst_act_hi | ~MMCM_Locked_i | ~iodelay_ctrl_rdy[0];
    end
  endgenerate

  always @(posedge clk_bufg or posedge rst_tmp_phaser_ref)
    if (rst_tmp_phaser_ref)
      rst_phaser_ref_sync_r <= #TCQ {RST_DIV_SYNC_NUM{1'b1}};
    else
      rst_phaser_ref_sync_r <= #TCQ rst_phaser_ref_sync_r << 1;

  assign rst_phaser_ref = rst_phaser_ref_sync_r[RST_DIV_SYNC_NUM-1];

		  
  always @(posedge drp_clk or posedge sys_rst_act_hi) begin
	  if (sys_rst_act_hi) begin
      		sys_rst_act_hi_sync_r <= #TCQ 2'b11 ;
	  end else begin
      		sys_rst_act_hi_sync_r <= #TCQ {sys_rst_act_hi_sync_r[0],1'b0} ;
          end
  end

  always @(posedge drp_clk) begin
	init_calib_complete_r <= #TCQ {init_calib_complete_r[0],init_calib_complete} ;
  end
   
  always @(posedge drp_clk) begin
	calib_error_r[0] <= #TCQ calib_error;
	calib_error_r[1] <= #TCQ calib_error_r[0];
	calib_error_r[2] <= #TCQ calib_error_r[1];
  end
 assign calib_error_posedge = calib_error_r[1] && ~calib_error_r[2];

  always @(posedge drp_clk) begin
	pll_locked_i_r <= #TCQ {pll_locked_i_r[0],pll_locked_i} ;
  end
  
  wire [3:0] adj_flag_r;
  always @(posedge clk_bufg) begin
   	adj_flag_r1  <= #TCQ adj_flag_r ;
      	adj_flag     <= #TCQ adj_flag_r1 ;
  end
		
		


phase_switch #(
    .CALIB_FAST      (CALIB_FAST),
    .tCK(tCK),
    .nCK_PER_CLK(nCK_PER_CLK),
    .CLKOUT0_DIVIDE(CLKOUT0_DIVIDE),
    .CLKOUT0_PHASE(CLKOUT0_PHASE),
    .CLKOUT0_DUTY(0.5),
    .CLKOUT1_DIVIDE(CLKOUT1_DIVIDE),
    .CLKOUT1_PHASE(0),
    .CLKOUT1_DUTY(0.5),
    .CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
    .CLKOUT2_PHASE(9.84375),
    .CLKOUT2_DUTY(1.0/16.0),
	.ADJ_LEVEL(ADJ_LEVEL)
)
    u_switch(
        .sys_rst(sys_rst_act_hi_sync_r[1]),
        .sys_clk(drp_clk),
        .init_complete(init_calib_complete_r[1]),
        .calib_error(calib_error_posedge),		
//signal from/to PLL_DRP
// These signals are to be connected to the pll_ADV by port name.
// Their use matches the MMCM port description in the Device User Guide.
        .DO(DO),
   .DRDY(DRDY),
   .LOCKED(pll_locked_i_r[1]),
   .DWE(DWE),
   .DEN(DEN),
   .DADDR(DADDR),
   .DI(DI),
   .DCLK(DCLK),
   .RST_PLL(RST_PLL),
   .rst_adj(rst_adj),
   .adj_flag(adj_flag_r)
);
        
endmodule



////////////////
//phase_switch//
////////////////

//`timescale 1ps/1ps

module phase_switch #(
    parameter CALIB_FAST      ="FASLE",
    parameter tCK = 1250,
    parameter nCK_PER_CLK = 4,
    parameter CLKOUT0_DIVIDE = 1,
    parameter CLKOUT0_PHASE = 0,
    parameter CLKOUT0_DUTY = 0.5,
    parameter CLKOUT1_DIVIDE = 1,
    parameter CLKOUT1_PHASE = 0,
    parameter CLKOUT1_DUTY = 0.5,
    parameter CLKOUT2_DIVIDE = 1,
    parameter CLKOUT2_PHASE = 0,
    parameter CLKOUT2_DUTY = 0.5,
	parameter ADJ_LEVEL = 0
) (
        //signal from system
        input sys_rst,
        input sys_clk,
        input init_complete,
		input calib_error,
        //signal from/to PLL_DRP
        // These signals are to be connected to the pll_ADV by port name.
        // Their use matches the MMCM port description in the Device User Guide.
        input      [15:0] DO,
        input             DRDY,
        input             LOCKED,
        output        DWE,
        output        DEN,
        output [6:0]  DADDR,
        output [15:0] DI,
        output            DCLK,
        output        RST_PLL,
		output rst_adj,
        output [3:0] adj_flag
);

localparam  TCQ = 100;
localparam  integer VALUE  =  (CALIB_FAST == "TRUE") ? 5e3*(tCK*nCK_PER_CLK) : 6e4*(tCK*nCK_PER_CLK);
//localparam integer MAX_ADJ_FLAG = (ADJ_LEVEL == 2) ? 7 : ((ADJ_LEVEL == 1) ? 1 : 0);
//when ADJ_LEVEL == 2,	the ck coarse range is [2,3,4]
  localparam integer MAX_ADJ_FLAG = (ADJ_LEVEL == 2) ? 9 : ((ADJ_LEVEL == 1) ? 1 : 0);
//2e8

(* mark_debug="true" *) (* keep_hierarchy="soft" *) reg [31:0] timer;
(* keep_hierarchy="soft" *) reg switch_start = 1'b0;
(* mark_debug="true" *) (* keep_hierarchy="soft" *) reg [2:0] switch_cnt = 3'b000;

(* mark_debug="true" *) (* keep_hierarchy="soft" *) reg [3:0] adj_flag_r;
(* keep_hierarchy="soft" *)reg [3:0] pulse_cnt;
(* keep_hierarchy="soft" *)reg rst_adj_r;
(* keep_hierarchy="soft" *)reg rst_pulse;

//reg [3:0] pulse_cnt;
//reg rst_adj_r;
//reg rst_pulse;

assign adj_flag[0] = (ADJ_LEVEL > 0) ? adj_flag_r[0] : 0;
//assign adj_flag[3:1] = (ADJ_LEVEL == 2) ? adj_flag_r[3:1] : 3'b001;
assign adj_flag[3:1] = (ADJ_LEVEL == 2) ? adj_flag_r[3:1] : 3'b010;
assign rst_adj = rst_adj_r;

always @(posedge sys_clk or posedge sys_rst)begin
    if(sys_rst)begin
        timer<= #TCQ 32'd0;
        switch_start <= #TCQ 1'b0;
		switch_cnt <= #TCQ 5'h0;
		adj_flag_r <= 4'd4;
		rst_pulse <= 1'b1;
    end
    else begin
        if(init_complete)begin
            switch_start <= #TCQ 1'b0;
            timer <= timer;
			rst_pulse <= 1'b0;
        end
        else if(timer == VALUE || calib_error)begin
            if(switch_start | &switch_cnt)begin
                timer<= #TCQ 32'd0;
                switch_start <= #TCQ 1'b0;
            end
			else if (~init_complete) begin
				timer <= #TCQ 32'd0;
				if (adj_flag_r < MAX_ADJ_FLAG) begin
					adj_flag_r <= #TCQ adj_flag_r + 1;
					rst_pulse <= 1'b1;
				end
				else begin
					adj_flag_r <= 4'd4;
					rst_pulse <= 1'b0;
                    switch_start <= #TCQ 1'b1;
		            switch_cnt <= #TCQ switch_cnt + 1;
                end
			end
            //else if(switch_start && SRDY) begin
        end
        else begin
			rst_pulse <= 1'b0;
            timer <= #TCQ timer+1;
            switch_start <= #TCQ 1'b0;
        end
    end
end

always @(posedge sys_clk or posedge sys_rst) begin
	if (sys_rst) begin
		pulse_cnt <= 4'd0;
		rst_adj_r <= 1'b1;
	end
	else if (rst_pulse) begin
		pulse_cnt <= 4'd15;
		rst_adj_r <= 1'b1;
	end
	else if (pulse_cnt > 0) begin
		rst_adj_r <= 1'b1;
		pulse_cnt <= pulse_cnt - 1;
	end
	else begin
		pulse_cnt <= 4'd0;
		rst_adj_r <= 1'b0;
	end
end

reg [2:0] SADDR=3'h0;
reg SEN=1'b0;

reg [2:0] next_SADDR=3'h0;
reg next_SEN=1'b0;
wire SRDY;

plle2_drp_ddr3 #(
    .CLKOUT0_DIVIDE(CLKOUT0_DIVIDE),
    .CLKOUT0_PHASE(CLKOUT0_PHASE*1000),
    .CLKOUT0_DUTY(CLKOUT0_DUTY*100000),
    .CLKOUT1_DIVIDE(CLKOUT1_DIVIDE),
    .CLKOUT1_PHASE(CLKOUT1_PHASE*1000),
    .CLKOUT1_DUTY(CLKOUT1_DUTY*100000),
    .CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
    .CLKOUT2_PHASE(CLKOUT2_PHASE*1000),
    .CLKOUT2_DUTY(CLKOUT2_DUTY*100000)
)
    u_plle2_drp(
    .SADDR(SADDR),
    .SEN(SEN),
    .SCLK(sys_clk),
    .RST(sys_rst),
    .SRDY(SRDY),
    //drp ports
    .DO(DO),
    .DRDY(DRDY),
    .LOCKED(LOCKED),
    .DWE(DWE),
    .DEN(DEN),
    .DADDR(DADDR),
    .DI(DI),
    .DCLK(DCLK),
    .RST_PLL(RST_PLL)
);

localparam IDLE = 2'h0;
localparam WAIT_FOR_SWITCH = 2'h1;
localparam SWITCH = 2'h2;
localparam WAIT_FOR_COMPLETE = 2'h3;
//state sync
reg [1:0] current_state = IDLE;
reg [1:0] next_state = IDLE;

always @(posedge sys_clk)begin
    SADDR <=  #TCQ next_SADDR;
    SEN <= #TCQ  next_SEN;
end

always @(posedge sys_clk or posedge sys_rst)begin
    if(sys_rst)begin
        current_state<= #TCQ IDLE;
    end
    else begin
        current_state<= #TCQ next_state;
    end
end

always @* begin
    
    next_SADDR = SADDR;
    next_SEN = SEN;

    case(current_state)
        IDLE: begin
            next_SEN = 1'b0;
            next_state = WAIT_FOR_SWITCH;
        end

        WAIT_FOR_SWITCH: begin
            //if(switch_start & SRDY)begin
            if(switch_start)begin
                next_state = SWITCH;
            end
            else begin
                next_state = WAIT_FOR_SWITCH;
            end
        end

        SWITCH: begin
            next_SADDR = next_SADDR + 3;
            next_SEN = 1'b1;
            next_state = WAIT_FOR_COMPLETE;
        end

        WAIT_FOR_COMPLETE: begin
            next_SEN = 1'b0;
            if(SRDY)begin
                next_state = IDLE;
            end
            else begin
                next_state = WAIT_FOR_COMPLETE;
            end
        end
    endcase
end

endmodule

//////////////////
//plle2_drp_ddr3//
//////////////////


//`timescale 1ps/1ps

module plle2_drp_ddr3 #(
        parameter CLKOUT0_DIVIDE = 1,
        parameter CLKOUT0_PHASE = 0,
        parameter CLKOUT0_DUTY = 50000,
        parameter CLKOUT1_DIVIDE = 1,
        parameter CLKOUT1_PHASE = 0,
        parameter CLKOUT1_DUTY = 50000,
        parameter CLKOUT2_DIVIDE = 1,
        parameter CLKOUT2_PHASE = 0,
        parameter CLKOUT2_DUTY = 50000
        )(
      // These signals are controlled by user logic interface and are covered
      // in more detail within the XAPP.
      input      [2:0]  SADDR,
      input             SEN,
      input             SCLK,
      input             RST,
      output reg        SRDY,

      // These signals are to be connected to the pll_ADV by port name.
      // Their use matches the MMCM port description in the Device User Guide.
      input      [15:0] DO,
      input             DRDY,
      input             LOCKED,
      output reg        DWE,
      output reg        DEN,
      output reg [6:0]  DADDR,
      output reg [15:0] DI,
      output            DCLK,
      output reg        RST_PLL
   );

   // 100 ps delay for behavioral simulations
   localparam  TCQ = 100;

   // Make sure the memory is implemented as distributed
   (* rom_style = "distributed" *)
   reg [38:0]  rom [127:0];  // 39 bit word 128 words deep, 16*6
   reg [9:0]   rom_addr;
   reg [38:0]  rom_do;

   reg         next_srdy;

   reg [9:0]   next_rom_addr;
   reg [6:0]   next_daddr;
   reg         next_dwe;
   reg         next_den;
   reg         next_RST_PLL;
   reg [15:0]  next_di;

   // Integer used to initialize remainder of unused ROM
   integer     ii;

   // Pass SCLK to DCLK for the MMCM
   assign DCLK = SCLK;

//************************************************
//reconfiguration function
//************************************************
// Define debug to provide extra messages durring elaboration
//`define DEBUG 1

// FRAC_PRECISION describes the width of the fractional portion of the fixed
//    point numbers.  These should not be modified, they are for development
//    only
`define FRAC_PRECISION  10
// FIXED_WIDTH describes the total size for fixed point calculations(int+frac).
// Warning: L.50 and below will not calculate properly with FIXED_WIDTHs
//    greater than 32
`define FIXED_WIDTH     32

// This function takes a fixed point number and rounds it to the nearest
//    fractional precision bit.
function [`FIXED_WIDTH:1] round_frac
   (
      // Input is (FIXED_WIDTH-FRAC_PRECISION).FRAC_PRECISION fixed point number
      input [`FIXED_WIDTH:1] decimal,

      // This describes the precision of the fraction, for example a value
      //    of 1 would modify the fractional so that instead of being a .16
      //    fractional, it would be a .1 (rounded to the nearest 0.5 in turn)
      input [`FIXED_WIDTH:1] precision
   );

   begin

`ifdef DEBUG
      $display("round_frac - decimal: %h, precision: %h", decimal, precision);
`endif
      // If the fractional precision bit is high then round up
      if( decimal[(`FRAC_PRECISION-precision)] == 1'b1) begin
         round_frac = decimal + (1'b1 << (`FRAC_PRECISION-precision));
      end else begin
         round_frac = decimal;
      end
`ifdef DEBUG
      $display("round_frac: %h", round_frac);
`endif
   end
endfunction

// This function calculates high_time, low_time, w_edge, and no_count
//    of a non-fractional counter based on the divide and duty cycle
//
// NOTE: high_time and low_time are returned as integers between 0 and 63
//    inclusive.  64 should equal 6'b000000 (in other words it is okay to
//    ignore the overflow)
function [13:0] pll_divider
   (
      input [7:0] divide,        // Max divide is 128
      input [31:0] duty_cycle    // Duty cycle is multiplied by 100,000
   );

   reg [`FIXED_WIDTH:1]    duty_cycle_fix;
      // min/max allowed duty cycle range calc for divide => 64
   reg [`FIXED_WIDTH:1]    duty_cycle_min;
   reg [`FIXED_WIDTH:1]    duty_cycle_max;


   // High/Low time is initially calculated with a wider integer to prevent a
   // calculation error when it overflows to 64.
   reg [6:0]               high_time;
   reg [6:0]               low_time;
   reg                     w_edge;
   reg                     no_count;

   reg [`FIXED_WIDTH:1]    temp;

   begin
      // Duty Cycle must be between 0 and 1,000
      if(duty_cycle <=0 || duty_cycle >= 100000) begin
         $display("ERROR: duty_cycle: %d is invalid", duty_cycle);
         $finish;
      end
      if (divide >= 64) begin     // DCD and frequency generation fix if O divide => 64
          duty_cycle_min = ((divide - 64) * 100_000) / divide;
          duty_cycle_max = (64.5 / divide) * 100_000;
          if (duty_cycle > duty_cycle_max)  duty_cycle = duty_cycle_max;
          if (duty_cycle < duty_cycle_min)  duty_cycle = duty_cycle_min;
      end

      // Convert to FIXED_WIDTH-FRAC_PRECISION.FRAC_PRECISION fixed point
      duty_cycle_fix = (duty_cycle << `FRAC_PRECISION) / 100_000;

`ifdef DEBUG
      $display("duty_cycle_fix: %h", duty_cycle_fix);
`endif

      // If the divide is 1 nothing needs to be set except the no_count bit.
      //    Other values are dummies
      if(divide == 7'h01) begin
         high_time   = 7'h01;
         w_edge      = 1'b0;
         low_time    = 7'h01;
         no_count    = 1'b1;
      end else begin
         temp = round_frac(duty_cycle_fix*divide, 1);

         // comes from above round_frac
         high_time   = temp[`FRAC_PRECISION+7:`FRAC_PRECISION+1];
         // If the duty cycle * divide rounded is .5 or greater then this bit
         //    is set.
         w_edge      = temp[`FRAC_PRECISION]; // comes from round_frac

         // If the high time comes out to 0, it needs to be set to at least 1
         // and w_edge set to 0
         if(high_time == 7'h00) begin
            high_time   = 7'h01;
            w_edge      = 1'b0;
         end

         if(high_time == divide) begin
            high_time   = divide - 1;
            w_edge      = 1'b1;
         end

         // Calculate low_time based on the divide setting and set no_count to
         //    0 as it is only used when divide is 1.
         low_time    = divide - high_time;
         no_count    = 1'b0;
      end

      // Set the return value.
      pll_divider = {w_edge,no_count,high_time[5:0],low_time[5:0]};
   end
endfunction

// This function calculates mx, delay_time, and phase_mux
//  of a non-fractional counter based on the divide and phase
//
// NOTE: The only valid value for the MX bits is 2'b00 to ensure the coarse mux
//    is used.
function [10:0] pll_phase
   (
      // divide must be an integer (use fractional if not)
      //  assumed that divide already checked to be valid
      input [7:0] divide, // Max divide is 128

      // Phase is given in degrees (-360,000 to 360,000)
      input signed [31:0] phase
   );

   reg [`FIXED_WIDTH:1] phase_in_cycles;
   reg [`FIXED_WIDTH:1] phase_fixed;
   reg [1:0]            mx;
   reg [5:0]            delay_time;
   reg [2:0]            phase_mux;

   reg [`FIXED_WIDTH:1] temp;

   begin
`ifdef DEBUG
      $display("pll_phase-divide:%d,phase:%d",
         divide, phase);
`endif

      if ((phase < -360000) || (phase > 360000)) begin
         $display("ERROR: phase of $phase is not between -360000 and 360000");
         $finish;
      end

      // If phase is less than 0, convert it to a positive phase shift
      // Convert to (FIXED_WIDTH-FRAC_PRECISION).FRAC_PRECISION fixed point
      if(phase < 0) begin
         phase_fixed = ( (phase + 360000) << `FRAC_PRECISION ) / 1000;
      end else begin
         phase_fixed = ( phase << `FRAC_PRECISION ) / 1000;
      end

      // Put phase in terms of decimal number of vco clock cycles
      phase_in_cycles = ( phase_fixed * divide ) / 360;

`ifdef DEBUG
      $display("phase_in_cycles: %h", phase_in_cycles);
`endif


	 temp  =  round_frac(phase_in_cycles, 3);

	 // set mx to 2'b00 that the phase mux from the VCO is enabled
	 mx    			=  2'b00;
	 phase_mux      =  temp[`FRAC_PRECISION:`FRAC_PRECISION-2];
	 delay_time     =  temp[`FRAC_PRECISION+6:`FRAC_PRECISION+1];

`ifdef DEBUG
      $display("temp: %h", temp);
`endif

      // Setup the return value
      pll_phase={mx, phase_mux, delay_time};
   end
endfunction

// This function takes the divide value and outputs the necessary lock values
function [39:0] pll_lock_lookup
   (
      input [6:0] divide // Max divide is 64
   );

   reg [2559:0]   lookup;

   begin
      lookup = {
         // This table is composed of:
         // LockRefDly_LockFBDly_LockCnt_LockSatHigh_UnlockCnt
         40'b00110_00110_1111101000_1111101001_0000000001,
         40'b00110_00110_1111101000_1111101001_0000000001,
         40'b01000_01000_1111101000_1111101001_0000000001,
         40'b01011_01011_1111101000_1111101001_0000000001,
         40'b01110_01110_1111101000_1111101001_0000000001,
         40'b10001_10001_1111101000_1111101001_0000000001,
         40'b10011_10011_1111101000_1111101001_0000000001,
         40'b10110_10110_1111101000_1111101001_0000000001,
         40'b11001_11001_1111101000_1111101001_0000000001,
         40'b11100_11100_1111101000_1111101001_0000000001,
         40'b11111_11111_1110000100_1111101001_0000000001,
         40'b11111_11111_1100111001_1111101001_0000000001,
         40'b11111_11111_1011101110_1111101001_0000000001,
         40'b11111_11111_1010111100_1111101001_0000000001,
         40'b11111_11111_1010001010_1111101001_0000000001,
         40'b11111_11111_1001110001_1111101001_0000000001,
         40'b11111_11111_1000111111_1111101001_0000000001,
         40'b11111_11111_1000100110_1111101001_0000000001,
         40'b11111_11111_1000001101_1111101001_0000000001,
         40'b11111_11111_0111110100_1111101001_0000000001,
         40'b11111_11111_0111011011_1111101001_0000000001,
         40'b11111_11111_0111000010_1111101001_0000000001,
         40'b11111_11111_0110101001_1111101001_0000000001,
         40'b11111_11111_0110010000_1111101001_0000000001,
         40'b11111_11111_0110010000_1111101001_0000000001,
         40'b11111_11111_0101110111_1111101001_0000000001,
         40'b11111_11111_0101011110_1111101001_0000000001,
         40'b11111_11111_0101011110_1111101001_0000000001,
         40'b11111_11111_0101000101_1111101001_0000000001,
         40'b11111_11111_0101000101_1111101001_0000000001,
         40'b11111_11111_0100101100_1111101001_0000000001,
         40'b11111_11111_0100101100_1111101001_0000000001,
         40'b11111_11111_0100101100_1111101001_0000000001,
         40'b11111_11111_0100010011_1111101001_0000000001,
         40'b11111_11111_0100010011_1111101001_0000000001,
         40'b11111_11111_0100010011_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001
      };

      // Set lookup_entry with the explicit bits from lookup with a part select
      pll_lock_lookup = lookup[ ((64-divide)*40) +: 40];
`ifdef DEBUG
      $display("lock_lookup: %b", pll_lock_lookup);
`endif
   end
endfunction

// This function takes the divide value and the bandwidth setting of the PLL
//  and outputs the digital filter settings necessary.
function [9:0] pll_filter_lookup
  (
     input [6:0] divide, // Max divide is 64
     input [8*9:0] BANDWIDTH
  );

  reg [639:0] lookup_low;
  reg [639:0] lookup_high;
  reg [639:0] lookup_optimized;

  reg [9:0] lookup_entry;

  begin
      lookup_low = {
        // CP_RES_LFHF
        10'b0010_1111_00,  // 1
        10'b0010_1111_00,  // 2
        10'b0010_0111_00,  // 3
        10'b0010_1101_00,  // 4
        10'b0010_0101_00,  // ....
        10'b0010_0101_00,
        10'b0010_1001_00,
        10'b0010_1110_00,
        10'b0010_1110_00,
        10'b0010_0001_00,
        10'b0010_0001_00,
        10'b0010_0110_00,
        10'b0010_0110_00,
        10'b0010_0110_00,
        10'b0010_0110_00,
        10'b0010_1010_00,
        10'b0010_1010_00,
        10'b0010_1010_00,
        10'b0010_1010_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_1100_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0010_0010_00,
        10'b0011_1100_00,
        10'b0011_1100_00,
        10'b0011_1100_00,
        10'b0011_1100_00,
        10'b0011_1100_00,
        10'b0011_1100_00,
        10'b0011_1100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,
        10'b0010_0100_00,  // ......
        10'b0010_0100_00,  // 61
        10'b0010_0100_00,  // 62
        10'b0010_0100_00,  // 63
        10'b0010_0100_00   // 64
      };

      lookup_high = {
        // CP_RES_LFHF
        10'b0011_0111_00,  // 1
        10'b0011_0111_00,  // 2
        10'b0101_1111_00,  // 3
        10'b0111_1111_00,  // 4
        10'b0111_1011_00,  // ....
        10'b1101_0111_00,
        10'b1110_1011_00,
        10'b1110_1101_00,
        10'b1111_1101_00,
        10'b1111_0111_00,
        10'b1111_1011_00,
        10'b1111_1101_00,
        10'b1111_0011_00,
        10'b1110_0101_00,
        10'b1111_0101_00,
        10'b1111_0101_00,
        10'b1111_0101_00,
        10'b1111_0101_00,
        10'b0111_0110_00,
        10'b0111_0110_00,
        10'b0111_0110_00,
        10'b0111_0110_00,
        10'b0101_1100_00,
        10'b0101_1100_00,
        10'b0101_1100_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b0100_0010_00,
        10'b0100_0010_00,
        10'b0100_0010_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0011_0100_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,  // .....
        10'b0010_0100_00,  // 61
        10'b0010_0100_00,  // 62
        10'b0010_0100_00,  // 63
        10'b0010_0100_00   // 64
      };

      lookup_optimized = {
        // CP_RES_LFHF
        10'b0011_0111_00,  // 1
        10'b0011_0111_00,  // 2
        10'b0101_1111_00,  // 3
        10'b0111_1111_00,  // 4
        10'b0111_1011_00,  // .
        10'b1101_0111_00,
        10'b1110_1011_00,
        10'b1110_1101_00,
        10'b1111_1101_00,
        10'b1111_0111_00,
        10'b1111_1011_00,
        10'b1111_1101_00,
        10'b1111_0011_00,
        10'b1110_0101_00,
        10'b1111_0101_00,
        10'b1111_0101_00,
        10'b1111_0101_00,
        10'b1111_0101_00,
        10'b0111_0110_00,
        10'b0111_0110_00,
        10'b0111_0110_00,
        10'b0111_0110_00,
        10'b0101_1100_00,
        10'b0101_1100_00,
        10'b0101_1100_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b1100_0001_00,
        10'b0100_0010_00,
        10'b0100_0010_00,
        10'b0100_0010_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0011_0100_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0010_1000_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,
        10'b0100_1100_00,  // ..
        10'b0010_0100_00,  // 61
        10'b0010_0100_00,  // 62
        10'b0010_0100_00,  // 63
        10'b0010_0100_00   // 64
      };

    // Set lookup_entry with the explicit bits from lookup with a part select
    if (BANDWIDTH == "LOW") begin
      // Low Bandwidth
      pll_filter_lookup = lookup_low[((64-divide)*10) +: 10];
    end
    else if (BANDWIDTH == "HIGH") begin
      // High Bandwidth
      pll_filter_lookup = lookup_high[((64-divide)*10) +: 10];
    end
    else if (BANDWIDTH == "OPTIMIZED") begin
      //  Optimized Bandwidth
      pll_filter_lookup = lookup_optimized[((64-divide)*10) +: 10];
    end

    `ifdef DEBUG
          $display("filter_lookup: %b", pll_filter_lookup);
    `endif
  end
endfunction

// This function takes in the divide, phase, and duty cycle
// setting to calculate the upper and lower counter registers.
function [37:0] pll_count_calc
   (
      input [7:0] divide, // Max divide is 128
      input signed [31:0] phase,
      input [31:0] duty_cycle // Multiplied by 100,000
   );

   reg [13:0] div_calc;
   reg [16:0] phase_calc;

   begin
`ifdef DEBUG
      $display("pll_count_calc- divide:%h, phase:%d, duty_cycle:%d",
         divide, phase, duty_cycle);
`endif

      // w_edge[13], no_count[12], high_time[11:6], low_time[5:0]
      div_calc = pll_divider(divide, duty_cycle);
      // mx[10:9], pm[8:6], dt[5:0]
      phase_calc = pll_phase(divide, phase);

      // Return value is the upper and lower address of counter
      //    Upper address is:
      //       RESERVED    [31:26]
      //       MX          [25:24]
      //       EDGE        [23]
      //       NOCOUNT     [22]
      //       DELAY_TIME  [21:16]
      //    Lower Address is:
      //       PHASE_MUX   [15:13]
      //       RESERVED    [12]
      //       HIGH_TIME   [11:6]
      //       LOW_TIME    [5:0]

`ifdef DEBUG
      $display("div:%d dc:%d phase:%d ht:%d lt:%d ed:%d nc:%d mx:%d dt:%d pm:%d",
         divide, duty_cycle, phase, div_calc[11:6], div_calc[5:0],
         div_calc[13], div_calc[12],
         phase_calc[16:15], phase_calc[5:0], phase_calc[14:12]);
`endif

      pll_count_calc =
         {
            // Upper Address
            6'h00, phase_calc[10:9], div_calc[13:12], phase_calc[5:0],
            // Lower Address
            phase_calc[8:6], 1'b0, div_calc[11:0]
         };
   end
endfunction


   //*********************************************************************
   //phase 0 calculation
   //*********************************************************************
   localparam [37:0] P0_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE, CLKOUT0_DUTY);
   localparam [37:0] P0_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE, CLKOUT1_DUTY);
   localparam [37:0] P0_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE, CLKOUT2_DUTY);

   //*********************************************************************
   //phase 1 calculation
   //*********************************************************************
   localparam [37:0] P1_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*1*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P1_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*1, CLKOUT1_DUTY);
   localparam [37:0] P1_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*1*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);
   
   //*********************************************************************
   //phase 2 calculation
   //*********************************************************************
   localparam [37:0] P2_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*2*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P2_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*2, CLKOUT1_DUTY);
   localparam [37:0] P2_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*2*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);
   
   //*********************************************************************
   //phase 3 calculation
   //*********************************************************************
   localparam [37:0] P3_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*3*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P3_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*3, CLKOUT1_DUTY);
   localparam [37:0] P3_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*3*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);
   
   //*********************************************************************
   //phase 4 calculation
   //*********************************************************************
   localparam [37:0] P4_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*4*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P4_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*4, CLKOUT1_DUTY);
   localparam [37:0] P4_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*4*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);
   
   //*********************************************************************
   //phase 5 calculation
   //*********************************************************************
   localparam [37:0] P5_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*5*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P5_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*5, CLKOUT1_DUTY);
   localparam [37:0] P5_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*5*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);
   
   //*********************************************************************
   //phase 6 calculation
   //*********************************************************************
   localparam [37:0] P6_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*6*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P6_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*6, CLKOUT1_DUTY);
   localparam [37:0] P6_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*6*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);
   
   //*********************************************************************
   //phase 7 calculation
   //*********************************************************************
   localparam [37:0] P7_CLKOUT0 = pll_count_calc(CLKOUT0_DIVIDE, CLKOUT0_PHASE + 45000*7*CLKOUT1_DIVIDE/CLKOUT0_DIVIDE, CLKOUT0_DUTY);
   localparam [37:0] P7_CLKOUT1 = pll_count_calc(CLKOUT1_DIVIDE, CLKOUT1_PHASE + 45000*7, CLKOUT1_DUTY);
   localparam [37:0] P7_CLKOUT2 = pll_count_calc(CLKOUT2_DIVIDE, CLKOUT2_PHASE + 45000*7*CLKOUT1_DIVIDE/CLKOUT2_DIVIDE, CLKOUT2_DUTY);

   initial begin
      // rom entries contain (in order) the address, a bitmask, and a bitset
      // Initialize the rest of the ROM
      
      //***********************************************************************
      // phase 0
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[0]  = {7'h08, 16'h1FFF, P0_CLKOUT0[15:13], 13'h0};
      rom[1]  = {7'h09, 16'hFFC0, 10'h0, P0_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[2]  = {7'h0A, 16'h1FFF, P0_CLKOUT1[15:13], 13'h0};
      rom[3]  = {7'h0B, 16'hFFC0, 10'h0, P0_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[4]  = {7'h0C, 16'h1FFF, P0_CLKOUT2[15:13], 13'h0};
      rom[5]  = {7'h0D, 16'hFFC0, 10'h0, P0_CLKOUT2[21:16]};

      //***********************************************************************
      // phase 1
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[6]  = {7'h08, 16'h1FFF, P1_CLKOUT0[15:13], 13'h0};
      rom[7]  = {7'h09, 16'hFFC0, 10'h0, P1_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[8]  = {7'h0A, 16'h1FFF, P1_CLKOUT1[15:13], 13'h0};
      rom[9]  = {7'h0B, 16'hFFC0, 10'h0, P1_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[10]  = {7'h0C, 16'h1FFF, P1_CLKOUT2[15:13], 13'h0};
      rom[11]  = {7'h0D, 16'hFFC0, 10'h0, P1_CLKOUT2[21:16]};

      //***********************************************************************
      // phase 2
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[12]  = {7'h08, 16'h1FFF, P2_CLKOUT0[15:13], 13'h0};
      rom[13]  = {7'h09, 16'hFFC0, 10'h0, P2_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[14]  = {7'h0A, 16'h1FFF, P2_CLKOUT1[15:13], 13'h0};
      rom[15]  = {7'h0B, 16'hFFC0, 10'h0, P2_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[16]  = {7'h0C, 16'h1FFF, P2_CLKOUT2[15:13], 13'h0};
      rom[17]  = {7'h0D, 16'hFFC0, 10'h0, P2_CLKOUT2[21:16]};
      //***********************************************************************
      // phase 3
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[18]  = {7'h08, 16'h1FFF, P3_CLKOUT0[15:13], 13'h0};
      rom[19]  = {7'h09, 16'hFFC0, 10'h0, P3_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[20]  = {7'h0A, 16'h1FFF, P3_CLKOUT1[15:13], 13'h0};
      rom[21]  = {7'h0B, 16'hFFC0, 10'h0, P3_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[22]  = {7'h0C, 16'h1FFF, P3_CLKOUT2[15:13], 13'h0};
      rom[23]  = {7'h0D, 16'hFFC0, 10'h0, P3_CLKOUT2[21:16]};
      //***********************************************************************
      // phase 4
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[24]  = {7'h08, 16'h1FFF, P4_CLKOUT0[15:13], 13'h0};
      rom[25]  = {7'h09, 16'hFFC0, 10'h0, P4_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[26]  = {7'h0A, 16'h1FFF, P4_CLKOUT1[15:13], 13'h0};
      rom[27]  = {7'h0B, 16'hFFC0, 10'h0, P4_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[28]  = {7'h0C, 16'h1FFF, P4_CLKOUT2[15:13], 13'h0};
      rom[29]  = {7'h0D, 16'hFFC0, 10'h0, P4_CLKOUT2[21:16]};
      //***********************************************************************
      // phase 5
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[30]  = {7'h08, 16'h1FFF, P5_CLKOUT0[15:13], 13'h0};
      rom[31]  = {7'h09, 16'hFFC0, 10'h0, P5_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[32]  = {7'h0A, 16'h1FFF, P5_CLKOUT1[15:13], 13'h0};
      rom[33]  = {7'h0B, 16'hFFC0, 10'h0, P5_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[34]  = {7'h0C, 16'h1FFF, P5_CLKOUT2[15:13], 13'h0};
      rom[35]  = {7'h0D, 16'hFFC0, 10'h0, P5_CLKOUT2[21:16]};
      //***********************************************************************
      // phase 6
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[36]  = {7'h08, 16'h1FFF, P6_CLKOUT0[15:13], 13'h0};
      rom[37]  = {7'h09, 16'hFFC0, 10'h0, P6_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[38]  = {7'h0A, 16'h1FFF, P6_CLKOUT1[15:13], 13'h0};
      rom[39]  = {7'h0B, 16'hFFC0, 10'h0, P6_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[40]  = {7'h0C, 16'h1FFF, P6_CLKOUT2[15:13], 13'h0};
      rom[41]  = {7'h0D, 16'hFFC0, 10'h0, P6_CLKOUT2[21:16]};
      //***********************************************************************
      // phase 7
      //***********************************************************************
      // Store CLKOUT0 divide and phase
      rom[42]  = {7'h08, 16'h1FFF, P7_CLKOUT0[15:13], 13'h0};
      rom[43]  = {7'h09, 16'hFFC0, 10'h0, P7_CLKOUT0[21:16]};

      // Store CLKOUT1 divide and phase
      rom[44]  = {7'h0A, 16'h1FFF, P7_CLKOUT1[15:13], 13'h0};
      rom[45]  = {7'h0B, 16'hFFC0, 10'h0, P7_CLKOUT1[21:16]};

      // Store CLKOUT2 divide and phase
      rom[46]  = {7'h0C, 16'h1FFF, P7_CLKOUT2[15:13], 13'h0};
      rom[47]  = {7'h0D, 16'hFFC0, 10'h0, P7_CLKOUT2[21:16]};


      for(ii = 48; ii < 128; ii = ii +1) begin
         rom[ii] = 0;
      end
   end

   // Output the initialized rom value based on rom_addr each clock cycle
   always @(posedge SCLK) begin
      rom_do<= #TCQ rom[rom_addr];
   end

   //**************************************************************************
   // Everything below is associated whith the state machine that is used to
   // Read/Modify/Write to the MMCM.
   //**************************************************************************

   // State Definitions
   localparam RESTART      = 4'h1;
   localparam WAIT_LOCK    = 4'h2;
   localparam WAIT_SEN     = 4'h3;
   localparam ADDRESS      = 4'h4;
   localparam WAIT_A_DRDY  = 4'h5;
   localparam BITMASK      = 4'h6;
   localparam BITSET       = 4'h7;
   localparam WRITE        = 4'h8;
   localparam WAIT_DRDY    = 4'h9;

   // State sync
   reg [3:0]  current_state   = RESTART;
   reg [3:0]  next_state      = RESTART;

   // These variables are used to keep track of the number of iterations that
   //    each state takes to reconfigure.
   // STATE_COUNT_CONST is used to reset the counters and should match the
   //    number of registers necessary to reconfigure each state.
   localparam STATE_COUNT_CONST  = 6; //was 23 but removing 2 registers because CLKOUT6 doesn't exist and low/high regs
   reg [4:0] state_count         = STATE_COUNT_CONST;
   reg [4:0] next_state_count    = STATE_COUNT_CONST;

   // This block assigns the next register value from the state machine below
   always @(posedge SCLK) begin
      DADDR       <= #TCQ next_daddr;
      DWE         <= #TCQ next_dwe;
      DEN         <= #TCQ next_den;
      RST_PLL    <= #TCQ next_RST_PLL;
      DI          <= #TCQ next_di;

      SRDY        <= #TCQ next_srdy;

      rom_addr    <= #TCQ next_rom_addr;
      state_count <= #TCQ next_state_count;
   end

   // This block assigns the next state, reset is syncronous.
   always @(posedge SCLK) begin
      if(RST) begin
         current_state <= #TCQ RESTART;
      end else begin
         current_state <= #TCQ next_state;
      end
   end

   always @* begin
      // Setup the default values
      next_srdy         = 1'b0;
      next_daddr        = DADDR;
      next_dwe          = 1'b0;
      next_den          = 1'b0;
      next_RST_PLL     = RST_PLL;
      next_di           = DI;
      next_rom_addr     = rom_addr;
      next_state_count  = state_count;

      case (current_state)
         // If RST is asserted reset the machine
         RESTART: begin
            next_daddr     = 7'h00;
            next_di        = 16'h0000;
            next_rom_addr  = 6'h00;
            next_RST_PLL  = 1'b1;
            next_state     = WAIT_LOCK;
         end

         // Waits for the MMCM to assert LOCKED - once it does asserts SRDY
         WAIT_LOCK: begin
            // Make sure reset is de-asserted
            next_RST_PLL   = 1'b0;
            // Reset the number of registers left to write for the next
            // reconfiguration event.
            next_state_count = STATE_COUNT_CONST;
            next_rom_addr = SADDR*6;

            if(LOCKED) begin
               // MMCM is locked, go on to wait for the SEN signal
               next_state  = WAIT_SEN;
               // Assert SRDY to indicate that the reconfiguration module is
               // ready
               next_srdy   = 1'b1;
            end else begin
               // Keep waiting, locked has not asserted yet
               next_state  = WAIT_LOCK;
            end
         end

         // Wait for the next SEN pulse and set the ROM addr appropriately
         //    based on SADDR
         WAIT_SEN: begin
            if (SEN) begin
               // SEN was asserted
               next_rom_addr = SADDR*6;
               // Go on to address the MMCM
               next_state = ADDRESS;
            end else begin
               // Keep waiting for SEN to be asserted
               next_state = WAIT_SEN;
            end
         end

         // Set the address on the MMCM and assert DEN to read the value
         ADDRESS: begin
            // Reset the DCM through the reconfiguration
            next_RST_PLL  = 1'b1;
            // Enable a read from the MMCM and set the MMCM address
            next_den       = 1'b1;
            next_daddr     = rom_do[38:32];

            // Wait for the data to be ready
            next_state     = WAIT_A_DRDY;
         end

         // Wait for DRDY to assert after addressing the MMCM
         WAIT_A_DRDY: begin
            if (DRDY) begin
               // Data is ready, mask out the bits to save
               next_state = BITMASK;
            end else begin
               // Keep waiting till data is ready
               next_state = WAIT_A_DRDY;
            end
         end

         // Zero out the bits that are not set in the mask stored in rom
         BITMASK: begin
            // Do the mask
            next_di     = rom_do[31:16] & DO;
            // Go on to set the bits
            next_state  = BITSET;
         end

         // After the input is masked, OR the bits with calculated value in rom
         BITSET: begin
            // Set the bits that need to be assigned
            next_di           = rom_do[15:0] | DI;
            // Set the next address to read from ROM
            next_rom_addr     = rom_addr + 1'b1;
            // Go on to write the data to the MMCM
            next_state        = WRITE;
         end

         // DI is setup so assert DWE, DEN, and RST_PLL.  Subtract one from the
         //    state count and go to wait for DRDY.
         WRITE: begin
            // Set WE and EN on MMCM
            next_dwe          = 1'b1;
            next_den          = 1'b1;

            // Decrement the number of registers left to write
            next_state_count  = state_count - 1'b1;
            // Wait for the write to complete
            next_state        = WAIT_DRDY;
         end

         // Wait for DRDY to assert from the MMCM.  If the state count is not 0
         //    jump to ADDRESS (continue reconfiguration).  If state count is
         //    0 wait for lock.
         WAIT_DRDY: begin
            if(DRDY) begin
               // Write is complete
               if(state_count > 0) begin
                  // If there are more registers to write keep going
                  next_state  = ADDRESS;
               end else begin
                  // There are no more registers to write so wait for the MMCM
                  // to lock
                  next_state  = WAIT_LOCK;
               end
            end else begin
               // Keep waiting for write to complete
               next_state     = WAIT_DRDY;
            end
         end

         // If in an unknown state reset the machine
         default: begin
            next_state = RESTART;
         end
      endcase
   end
endmodule
  
//ECOed
