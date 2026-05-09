`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/07 15:46:11
// Design Name: LJY
// Module Name: PCIE_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pcie_dma_top #(
//==================================================================================================
//--parameter Instantation
    /*--------------------------------------------------------------------------------------
    --P_SIMULATION_R
    --------------------------------------------------------------------------------------*/
    parameter       P_SIMULATION_R              = "FALSE"                                   ,

    /*--------------------------------------------------------------------------------------
    --Version Information
    --------------------------------------------------------------------------------------*/
    parameter       P_Version1_R                = 32'h2020_0318                             ,
    parameter       P_Version2_R                = 32'h1405_1000                             ,
    /*--------------------------------------------------------------------------------------
    --PCIe DMA Config.
    --------------------------------------------------------------------------------------*/
    parameter       P_DMA_UP_NUM_R              = 1                                         ,
    parameter       P_DMA_DN_NUM_R              = 1                                         ,
    parameter       P_DMA_AXI_INTERFACE_R       = "TRUE"                                    ,
    parameter       P_DMA_OFFSET_DSC_R          = "TRUE"                                    ,
    /*--------------------------------------------------------------------------------------
    --PCIe IP parameter
    --------------------------------------------------------------------------------------*/
    parameter       DW                          =   256                                     ,   //  C_DATA_WIDTH
    parameter       EXT_PIPE_SIM                =   "FALSE"                                 ,   //  EXT_PIPE_SIM
    parameter       PCIE_LS                     =   4                                       ,   //  PL_LINK_CAP_MAX_LINK_SPEED
    parameter       PCIE_LW                     =   8                                           //  PL_LINK_CAP_MAX_LINK_WIDTH
)(
    input                                       pcie_ref_clk_p                              ,
    input                                       pcie_ref_clk_n                              ,

    output          [PCIE_LW - 1:0]             pci_exp_txp                                 ,
    output          [PCIE_LW - 1:0]             pci_exp_txn                                 ,
    input           [PCIE_LW - 1:0]             pci_exp_rxp                                 ,
    input           [PCIE_LW - 1:0]             pci_exp_rxn                                 ,
/*--------------------------------------------------------------------------------------
	--DMA上行通道 AXI Stream接口
	--------------------------------------------------------------------------------------*/
	input			[P_DMA_UP_NUM_R*1-1: 0]		dma_s_axis_aclk								,
	input			[P_DMA_UP_NUM_R*DW-1: 0]	dma_s_axis_tdata							,
	input			[P_DMA_UP_NUM_R*4-1: 0]		dma_s_axis_tid								,
	output			[P_DMA_UP_NUM_R*1-1: 0]		dma_s_axis_tready							,
	input			[P_DMA_UP_NUM_R*1-1: 0]		dma_s_axis_tvalid							,
	input			[P_DMA_UP_NUM_R*DW/8-1: 0]	dma_s_axis_tstrb							,
	input			[P_DMA_UP_NUM_R*DW/8-1: 0]	dma_s_axis_tkeep							,
	input			[P_DMA_UP_NUM_R*1-1: 0]		dma_s_axis_tlast							,
	input			[P_DMA_UP_NUM_R*64-1: 0]	dma_s_axis_tuser							,
	input			[P_DMA_UP_NUM_R*4-1: 0]		dma_s_axis_tdest							,
		
	/*--------------------------------------------------------------------------------------
	--DMA通道下行 AXI Stream接口
	--------------------------------------------------------------------------------------*/
	input			[P_DMA_DN_NUM_R*1-1	: 0]	dma_m_axis_aclk								,
	output			[P_DMA_DN_NUM_R*DW-1: 0]	dma_m_axis_tdata							,
	output			[P_DMA_DN_NUM_R*4-1	: 0]	dma_m_axis_tid								,
	input			[P_DMA_DN_NUM_R*1-1	: 0]	dma_m_axis_tready							,
	output			[P_DMA_DN_NUM_R*1-1	: 0]	dma_m_axis_tvalid							,
	output			[P_DMA_DN_NUM_R*DW/8-1: 0]	dma_m_axis_tstrb							,
	output			[P_DMA_DN_NUM_R*DW/8-1: 0]	dma_m_axis_tkeep							,
	output			[P_DMA_DN_NUM_R*1-1	: 0]	dma_m_axis_tlast							,
	output			[P_DMA_DN_NUM_R*64-1: 0]	dma_m_axis_tuser							,
	output			[P_DMA_DN_NUM_R*4-1	: 0]	dma_m_axis_tdest							,
	
    input                                       dma_up_status                               ,
    output          [31:0]                      dma_up_packet                               ,
    output          [31:0]                      dma_dn_packet                               ,
//----PAB Bus Interface-------------------------
	//-----Write Address Channel Signals
    output			[32-1:0] 					pab_axi_awaddr								,	//写命令地址
    output			[3-1:0]						pab_axi_awprot								,	//保护类型
    output			[1-1:0]						pab_axi_awvalid								,	//写命令有效
    input			[1-1:0]						pab_axi_awready								,	//对端Ready信号
  //-----Write Data Channel Signals
    output			[32-1:0]					pab_axi_wdata								,	//写数据
    output			[32/8-1:0]					pab_axi_wstrb								,	//写数据DATA Mask
    output			[1-1:0]						pab_axi_wvalid								,	//写数据有效
    input			[1-1:0]						pab_axi_wready								,	//写数据Ready信号
  //-----Write Response Channel Signals
    input			[2-1:0]						pab_axi_bresp								,	//写响应OKAY/EXOKAY/SLVERR/DECERR
    input			[1-1:0]						pab_axi_bvalid								,	//写响应有效
    output			[1-1:0]						pab_axi_bready								,	//主机就绪
    
//--PAB Interaface	
  //---Read Address Channel Signals
    output			[32-1:0]					pab_axi_araddr								,
    output			[3-1:0]						pab_axi_arprot								,
    output			[1-1:0]						pab_axi_arvalid								,
    input			[1-1:0]						pab_axi_arready								,
    //---Read Data Channel Signals
    input			[32-1:0]					pab_axi_rdata								,
    input			[2-1:0]						pab_axi_rresp								,
    input			[1-1:0]						pab_axi_rvalid								,
    output			[1-1:0]						pab_axi_rready								,

    output                                      o_pcie_clk                                  ,
    output                                      o_pcie_rst                                  ,
    
    output                                      o_gt_refclk                                 ,

    input                                       sys_rst_n
);
    
    localparam                                   P_DMA_Dpr_FIFO_NUM_R    = 1                ;
////==================================================================================================
////--PCIe start
//    /*--------------------------------------------------------------------------------------
//    --PCIe DMA Config.
//    --------------------------------------------------------------------------------------*/                   


////////////////////    localparam ///////////////
    localparam                                  AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE"    ;
    localparam                                  AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE"    ;
    localparam                                  AXISTEN_IF_RC_STRADDLE         = 0          ;
    localparam                                  AXISTEN_IF_ENABLE_RX_MSG_INTFC = 0          ;
    localparam                                  AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE"    ;
    localparam                                  AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE"    ;
    localparam                                  AXISTEN_IF_ENABLE_CLIENT_TAG   = 1          ;
    localparam                                  AXISTEN_IF_RQ_PARITY_CHECK     = 0          ;
    localparam                                  AXISTEN_IF_CC_PARITY_CHECK     = 0          ;
    localparam          [17:0]                  AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF  ;
    // localparam                                  DW                             = PCIE_DW    ;
    localparam                                  CQH_DW                         = 32*4       ;   //  axis_cq_* head bit
    localparam                                  CCH_DW                         = 32*3       ;
    localparam                                  RQH_DW                         = 32*4       ;
    localparam                                  RCH_DW                         = 32*3       ;
    
    // localparam          PCIE_FREQ_MHZ       =   PCIE_LS ==  4   ?   8000    *   10/10   *   PCIE_LW /   PCIE_DW :   //  GEN 3
    //                                             PCIE_LS ==  2   ?   5000    *   8/10    *   PCIE_LW /   PCIE_DW :   //  GEN 2
    //                                                                 2500    *   8/10    *   PCIE_LW /   PCIE_DW ;   //  GEN 1
    wire                                        pcie_rst                                    ;
    wire                                        pcie_clk                                    ;       
    wire                                        user_lnk_up                                 ;
    wire                                        phy_rdy_out                                 ; 


//    assign  dma_s_axis_aclk                     =   {P_DMA_UP_NUM_R{pcie_clk}}              ;   //  sysc    to pcei user_clk    
//    assign  dma_m_axis_aclk                     =   {P_DMA_UP_NUM_R{pcie_clk}}              ;   //  sysc    to pcei user_clk    
        
    assign  o_pcie_clk                          =   pcie_clk                                ;
    assign  o_pcie_rst                          =   pcie_rst                                ;
      

    /*--------------------------------------------------------------------------------------
    --Interrupt Bus interface
    --------------------------------------------------------------------------------------*/
    wire                                        interrupt_bus_clk       = pcie_clk          ;       
    wire                                        interrupt_bus_req       = 1'b0              ;       
    wire                                        interrupt_bus_gnt                           ;       
    wire        [31:16]                         interrupt_bus_vector    = 16'b0             ;
   
////////////////////    pcie ipcore inerface begin  ///////////////
    wire                                        m_axis_rc_tready                            ;
    wire                                        m_axis_rc_tvalid                            ;
    wire                                        m_axis_rc_tlast                             ;
    wire        [DW      - 1:0]                 m_axis_rc_tdata                             ;
    wire        [DW / 32 - 1:0]                 m_axis_rc_tkeep                             ;
    wire        [75      - 1:0]                 m_axis_rc_tuser                             ;
    
    wire                                        s_axis_cc_tvalid                            ;
    wire                                        s_axis_cc_tready                            ;
    wire        [DW      - 1:0]                 s_axis_cc_tdata                             ;
    wire        [DW / 32 - 1:0]                 s_axis_cc_tkeep                             ;
    wire                                        s_axis_cc_tlast                             ;
    wire        [33      - 1:0]                 s_axis_cc_tuser                             ;
    
    wire                                        s_axis_rq_tvalid                            ;
    wire                                        s_axis_rq_tready                            ;
    wire        [DW      - 1:0]                 s_axis_rq_tdata                             ;
    wire        [DW / 32 - 1:0]                 s_axis_rq_tkeep                             ;
    wire                                        s_axis_rq_tlast                             ;
    wire        [60      - 1:0]                 s_axis_rq_tuser                             ;
    
    wire        [6       - 1:0]                 pcie_rq_tag                                 ;
    wire                                        pcie_rq_tag_vld                             ;
    wire        [2       - 1:0]                 pcie_rq_tag_av                              ;
    wire        [2       - 1:0]                 pcie_tfc_nph_av                             ;
    wire        [2       - 1:0]                 pcie_tfc_npd_av                             ;
    wire        [4       - 1:0]                 pcie_rq_seq_num                             ;
    wire                                        pcie_rq_seq_num_vld                         ;
    
    wire                                        m_axis_cq_tready                            ;
    wire                                        m_axis_cq_tvalid                            ;
    wire                                        m_axis_cq_tlast                             ;
    wire        [DW      - 1:0]                 m_axis_cq_tdata                             ;
    wire        [DW / 32 - 1:0]                 m_axis_cq_tkeep                             ;
    wire        [85      - 1:0]                 m_axis_cq_tuser                             ;
    wire        [6       - 1:0]                 pcie_cq_np_req_count                        ;
    wire                                        pcie_cq_np_req                              ;

    wire        [ 3:0]                          cfg_interrupt_msi_enable                    ;
    wire        [11:0]                          cfg_interrupt_msi_mmenable                  ;
    wire        [31:0]                          cfg_interrupt_msi_int                       ;
    wire                                        cfg_interrupt_msi_sent                      ;
    wire                                        cfg_interrupt_msi_fail                      ;
    wire        [01:0]                          inter_req_cnt                               ;
    wire        [01:0]                          inter_send_cnt                              ;
    wire        [01:0]                          inter_fail_cnt                              ;
    wire        [31:0]                          inter_int_latch                             ;

    wire        [ 2:0]                          cfg_current_speed                           ;   
    wire        [ 3:0]                          cfg_negotiated_width                        ;       
    wire                                        cfg_phy_link_down                           ;       
    wire        [ 1:0]                          cfg_phy_link_status                         ;       

    wire                                        cfg_err_cor_out                             ;
    wire                                        cfg_err_nonfatal_out                        ;
    wire                                        cfg_err_fatal_out                           ;
    wire                                        cfg_local_error                             ;           
    wire        [ 2:0]                          cfg_max_payload                             ;//
    wire        [ 2:0]                          cfg_max_read_req                            ;//
    
    wire        [ 2:0]                          pl_initial_link_width           = 3'b000    ;//  no used in pcie gen3
    wire                                        pl_link_gen2_cap                = 1'b0      ;//  no used in pcie gen3
    wire                                        pl_link_partner_gen2_supported  = 1'b0      ;//  no used in pcie gen3 

    wire        [15:0]                          pcie_far_id                                 ;//output [1-1:0] 
    wire        [15:0]                          pcie_dev_id                                 ;//output [1-1:0]     
    
    wire                                        c_os_config                                 ;//output [1-1:0]     
    wire                                        c_os_big_endian                             ;//output [1-1:0]     

////////////////////    pcie ipcore inerface end    /////////////// 


    // Support Level Wrapper
    pcie3_ep_wrap #   (
        .   C_DATA_WIDTH                        (   DW                                      ),  //  RX/TX   interface   data    width
        .   EXT_PIPE_SIM                        (   "FALSE"                                 ),  //This    Parameter   has effect  on  selecting   Enable  External    PIPE    Interface   in  GUI.
        .   PL_LINK_CAP_MAX_LINK_SPEED          (   PCIE_LS                                 ),  //1->GEN1 , 2->GEN2 , 4->GEN3
        .   PL_LINK_CAP_MAX_LINK_WIDTH          (   PCIE_LW                                 )   //1->X1   , 2->X2   , 4->X4   , 8->X8
    )i_pcie3_ep_wrap(
        .   pci_exp_txp                         ( pci_exp_txp                               ),   //  output  
        .   pci_exp_txn                         ( pci_exp_txn                               ),   //  output  
        .   pci_exp_rxp                         ( pci_exp_rxp                               ),   //  input   
        .   pci_exp_rxn                         ( pci_exp_rxn                               ),   //  input   
        .   s_axis_rq_tlast                     ( s_axis_rq_tlast                           ),   //  input                    
        .   s_axis_rq_tdata                     ( s_axis_rq_tdata                           ),   //  input                    
        .   s_axis_rq_tuser                     ( s_axis_rq_tuser                           ),   //  input                    
        .   s_axis_rq_tkeep                     ( s_axis_rq_tkeep                           ),   //  input                    
        .   s_axis_rq_tready                    ( s_axis_rq_tready                          ),   //  output                   
        .   s_axis_rq_tvalid                    ( s_axis_rq_tvalid                          ),   //  input                    
        .   m_axis_rc_tdata                     ( m_axis_rc_tdata                           ),   //  output                   
        .   m_axis_rc_tuser                     ( m_axis_rc_tuser                           ),   //  output                    
        .   m_axis_rc_tlast                     ( m_axis_rc_tlast                           ),   //  output                    
        .   m_axis_rc_tkeep                     ( m_axis_rc_tkeep                           ),   //  output                    
        .   m_axis_rc_tvalid                    ( m_axis_rc_tvalid                          ),   //  output                    
        .   m_axis_rc_tready                    ( m_axis_rc_tready                          ),   //  input                     
        .   m_axis_cq_tdata                     ( m_axis_cq_tdata                           ),   //  output                    
        .   m_axis_cq_tuser                     ( m_axis_cq_tuser                           ),   //  output                    
        .   m_axis_cq_tlast                     ( m_axis_cq_tlast                           ),   //  output                    
        .   m_axis_cq_tkeep                     ( m_axis_cq_tkeep                           ),   //  output                    
        .   m_axis_cq_tvalid                    ( m_axis_cq_tvalid                          ),   //  output                    
        .   m_axis_cq_tready                    ( m_axis_cq_tready                          ),   //  input                     
        .   s_axis_cc_tdata                     ( s_axis_cc_tdata                           ),   //  input                     
        .   s_axis_cc_tuser                     ( s_axis_cc_tuser                           ),   //  input                     
        .   s_axis_cc_tlast                     ( s_axis_cc_tlast                           ),   //  input                     
        .   s_axis_cc_tkeep                     ( s_axis_cc_tkeep                           ),   //  input                     
        .   s_axis_cc_tvalid                    ( s_axis_cc_tvalid                          ),   //  input                     
        .   s_axis_cc_tready                    ( s_axis_cc_tready                          ),   //  output                    
        .   pcie_tfc_nph_av                     ( pcie_tfc_nph_av                           ),   //  output                    
        .   pcie_tfc_npd_av                     ( pcie_tfc_npd_av                           ),   //  output                    
        .   cfg_interrupt_msi_enable            ( cfg_interrupt_msi_enable                  ),   //  input             
        .   cfg_interrupt_msi_mmenable          ( cfg_interrupt_msi_mmenable                ),   //  input             
        .   cfg_interrupt_msi_int               ( cfg_interrupt_msi_int                     ),   //  input             
        .   cfg_interrupt_msi_sent              ( cfg_interrupt_msi_sent                    ),   //  output            
        .   cfg_interrupt_msi_fail              ( cfg_interrupt_msi_fail                    ),   //  output                     
        .   pcie_rq_seq_num                     ( pcie_rq_seq_num                           ),   //  output                    
        .   pcie_rq_seq_num_vld                 ( pcie_rq_seq_num_vld                       ),   //  output                   
        .   pcie_rq_tag                         ( pcie_rq_tag                               ),   //  output                   
        .   pcie_rq_tag_vld                     ( pcie_rq_tag_vld                           ),   //  output                   
        .   pcie_rq_tag_av                      ( pcie_rq_tag_av                            ),   //  output                   
        .   pcie_cq_np_req                      ( pcie_cq_np_req                            ),   //  input                    
        .   pcie_cq_np_req_count                ( pcie_cq_np_req_count                      ),   //  output                   
        .   cfg_max_payload                     ( cfg_max_payload                           ),   //  output                   
        .   cfg_max_read_req                    ( cfg_max_read_req                          ),   //  output                   
        .   cfg_current_speed                   ( cfg_current_speed                         ),   //  output                   
        .   cfg_negotiated_width                ( cfg_negotiated_width                      ),   //  output                   
        .   cfg_phy_link_down                   ( cfg_phy_link_down                         ),   //  output               
        .   cfg_phy_link_status                 ( cfg_phy_link_status                       ),   //  output                   
        .   cfg_err_cor_out                     ( cfg_err_cor_out                           ),   //  output                  
        .   cfg_err_nonfatal_out                ( cfg_err_nonfatal_out                      ),   //  output                  
        .   cfg_err_fatal_out                   ( cfg_err_fatal_out                         ),   //  output                  
        .   cfg_local_error                     ( cfg_local_error                           ),   //  output                  
        .   c_os_config                         ( c_os_config                               ),   //  input       
        .   c_os_big_endian                     ( c_os_big_endian                           ),   //  input       
        .   user_lnk_up                         ( user_lnk_up                               ),   //  output                  
        .   phy_rdy_out                         ( phy_rdy_out                               ),   //  output                 
        .   user_clk                            ( pcie_clk                                  ),   //  output                  
        .   user_reset                          ( pcie_rst                                  ),   //  output                  
        .   sys_clk_p                           ( pcie_ref_clk_p                            ),   //  input                   
        .   sys_clk_n                           ( pcie_ref_clk_n                            ),   //  input  
        .   o_gt_refclk                         ( o_gt_refclk                               ),   //  output               
        .   sys_rst_n                           ( sys_rst_n                                 )    //  input                   
    );
    
    pcie3_dma_top    pcie3_dma_top(
        .   user_lnk_up                         ( user_lnk_up                               ),   //  input   
        .   phy_rdy_out                         ( phy_rdy_out                               ),   //  input   
        .   m_axis_rc_tvalid                    ( m_axis_rc_tvalid                          ),   //  input   
        .   m_axis_rc_tready                    ( m_axis_rc_tready                          ),   //  output  
        .   m_axis_rc_tlast                     ( m_axis_rc_tlast                           ),   //  input   
        .   m_axis_rc_tdata                     ( m_axis_rc_tdata                           ),   //  input   
        .   m_axis_rc_tkeep                     ( m_axis_rc_tkeep                           ),   //  input   
        .   m_axis_rc_tuser                     ( m_axis_rc_tuser                           ),   //  input   
        .   s_axis_cc_tvalid                    ( s_axis_cc_tvalid                          ),   //  output  
        .   s_axis_cc_tready                    ( s_axis_cc_tready                          ),   //  input   
        .   s_axis_cc_tdata                     ( s_axis_cc_tdata                           ),   //  output  
        .   s_axis_cc_tkeep                     ( s_axis_cc_tkeep                           ),   //  output  
        .   s_axis_cc_tlast                     ( s_axis_cc_tlast                           ),   //  output  
        .   s_axis_cc_tuser                     ( s_axis_cc_tuser                           ),   //  output  
        .   s_axis_rq_tvalid                    ( s_axis_rq_tvalid                          ),   //  output  
        .   s_axis_rq_tready                    ( s_axis_rq_tready                          ),   //  input   
        .   s_axis_rq_tdata                     ( s_axis_rq_tdata                           ),   //  output  
        .   s_axis_rq_tkeep                     ( s_axis_rq_tkeep                           ),   //  output  
        .   s_axis_rq_tlast                     ( s_axis_rq_tlast                           ),   //  output  
        .   s_axis_rq_tuser                     ( s_axis_rq_tuser                           ),   //  output  
        .   pcie_rq_tag                         ( pcie_rq_tag                               ),   //  input   
        .   pcie_rq_tag_vld                     ( pcie_rq_tag_vld                           ),   //  input   
        .   pcie_rq_tag_av                      ( pcie_rq_tag_av                            ),   //  input  
        .   pcie_tfc_nph_av                     ( pcie_tfc_nph_av                           ),   //  input  
        .   pcie_tfc_npd_av                     ( pcie_tfc_npd_av                           ),   //  input  
        .   pcie_rq_seq_num                     ( pcie_rq_seq_num                           ),   //  input  
        .   pcie_rq_seq_num_vld                 ( pcie_rq_seq_num_vld                       ),   //  input 
        .   m_axis_cq_tvalid                    ( m_axis_cq_tvalid                          ),   //  input  
        .   m_axis_cq_tready                    ( m_axis_cq_tready                          ),   //  output 
        .   m_axis_cq_tlast                     ( m_axis_cq_tlast                           ),   //  input  
        .   m_axis_cq_tdata                     ( m_axis_cq_tdata                           ),   //  input  
        .   m_axis_cq_tkeep                     ( m_axis_cq_tkeep                           ),   //  input  
        .   m_axis_cq_tuser                     ( m_axis_cq_tuser                           ),   //  input  
        .   pcie_cq_np_req_count                ( pcie_cq_np_req_count                      ),   //  input  
        .   pcie_cq_np_req                      ( pcie_cq_np_req                            ),   //  output 
        .   cfg_interrupt_msi_enable            ( cfg_interrupt_msi_enable[0]               ),   //  input          
        .   cfg_interrupt_msi_mmenable          ( cfg_interrupt_msi_mmenable[5:0]           ),   //  input      
        .   cfg_interrupt_msi_sent              ( cfg_interrupt_msi_sent                    ),   //  input   
        .   cfg_interrupt_msi_fail              ( cfg_interrupt_msi_fail                    ),   //  input   
        .   cfg_interrupt_msi_int               ( cfg_interrupt_msi_int                     ),   //  output  
        .   inter_req_cnt                       ( inter_req_cnt                             ),   //  output  
        .   inter_send_cnt                      ( inter_send_cnt                            ),   //  output  
        .   inter_fail_cnt                      ( inter_fail_cnt                            ),   //  output  
        .   inter_int_latch                     ( inter_int_latch                           ),   //  output  
        .   max_pay_size                        ( cfg_max_payload                           ),   //  input   
        .   max_req_size                        ( cfg_max_read_req                          ),   //  input   
        .   cfg_current_speed                   ( cfg_current_speed                         ),   //  input   
        .   cfg_negotiated_width                ( cfg_negotiated_width                      ),   //  input   
        .   pl_initial_link_width               ( pl_initial_link_width                     ),   //  input   
        .   pl_link_gen2_cap                    ( pl_link_gen2_cap                          ),   //  input   
        .   pl_link_partner_gen2_supported      ( pl_link_partner_gen2_supported            ),   //  input      
        .   dma_s_axis_aclk                     ( dma_s_axis_aclk                           ),   //  input  
        .   dma_s_axis_tdata                    ( dma_s_axis_tdata                          ),   //  input  
        .   dma_s_axis_tid                      ( dma_s_axis_tid                            ),   //  input  
        .   dma_s_axis_tready                   ( dma_s_axis_tready                         ),   //  output 
        .   dma_s_axis_tvalid                   ( dma_s_axis_tvalid                         ),   //  input  
        .   dma_s_axis_tstrb                    ( dma_s_axis_tstrb                          ),   //  input  
        .   dma_s_axis_tkeep                    ( dma_s_axis_tkeep                          ),   //  input  
        .   dma_s_axis_tlast                    ( dma_s_axis_tlast                          ),   //  input  
        .   dma_s_axis_tuser                    ( dma_s_axis_tuser                          ),   //  input  
        .   dma_s_axis_tdest                    ( dma_s_axis_tdest                          ),   //  input  
        .   dma_m_axis_aclk                     ( dma_m_axis_aclk                           ),   //  input  
        .   dma_m_axis_tdata                    ( dma_m_axis_tdata                          ),   //  output 
        .   dma_m_axis_tid                      ( dma_m_axis_tid                            ),   //  output 
        .   dma_m_axis_tready                   ( dma_m_axis_tready                         ),   //  input  
        .   dma_m_axis_tvalid                   ( dma_m_axis_tvalid                         ),   //  output 
        .   dma_m_axis_tstrb                    ( dma_m_axis_tstrb                          ),   //  output 
        .   dma_m_axis_tkeep                    ( dma_m_axis_tkeep                          ),   //  output 
        .   dma_m_axis_tlast                    ( dma_m_axis_tlast                          ),   //  output 
        .   dma_m_axis_tuser                    ( dma_m_axis_tuser                          ),   //  output 
        .   dma_m_axis_tdest                    ( dma_m_axis_tdest                          ),   //  output 
        .   dma_up_int_req                      ( {P_DMA_UP_NUM_R{1'b0}}                    ),   //  input  
        .   dma_up_int_gnt                      (                                           ),   //  output  
        .   pab_axi_awaddr                      ( pab_axi_awaddr                            ),   //  output 
        .   pab_axi_awprot                      ( pab_axi_awprot                            ),   //  output 
        .   pab_axi_awvalid                     ( pab_axi_awvalid                           ),   //  output 
        .   pab_axi_awready                     ( pab_axi_awready                           ),   //  input  
        .   pab_axi_wdata                       ( pab_axi_wdata                             ),   //  output 
        .   pab_axi_wstrb                       ( pab_axi_wstrb                             ),   //  output 
        .   pab_axi_wvalid                      ( pab_axi_wvalid                            ),   //  output 
        .   pab_axi_wready                      ( pab_axi_wready                            ),   //  input  
        .   pab_axi_bresp                       ( pab_axi_bresp                             ),   //  input  
        .   pab_axi_bvalid                      ( pab_axi_bvalid                            ),   //  input  
        .   pab_axi_bready                      ( pab_axi_bready                            ),   //  output 
        .   pab_axi_araddr                      ( pab_axi_araddr                            ),   //  output 
        .   pab_axi_arprot                      ( pab_axi_arprot                            ),   //  output 
        .   pab_axi_arvalid                     ( pab_axi_arvalid                           ),   //  output 
        .   pab_axi_arready                     ( pab_axi_arready                           ),   //  input  
        .   pab_axi_rdata                       ( pab_axi_rdata                             ),   //  input  
        .   pab_axi_rresp                       ( pab_axi_rresp                             ),   //  input  
        .   pab_axi_rvalid                      ( pab_axi_rvalid                            ),   //  input  
        .   pab_axi_rready                      ( pab_axi_rready                            ),   //  output 
        .   interrupt_bus_clk                   ( interrupt_bus_clk                         ),   //  input  
        .   interrupt_bus_req                   ( interrupt_bus_req                         ),   //  input  
        .   interrupt_bus_gnt                   ( interrupt_bus_gnt                         ),   //  output 
        .   interrupt_bus_vector                ( interrupt_bus_vector                      ),   //  input  
        .   c_os_config                         ( c_os_config                               ),   //  output 
        .   c_os_big_endian                     ( c_os_big_endian                           ),   //  output 
        .   pcie_far_id                         ( pcie_far_id                               ),   //  output 
        .   pcie_dev_id                         ( pcie_dev_id                               ),   //  output 
        .   rst                                 ( pcie_rst                                  ),   //  input  
        .   clk                                 ( pcie_clk                                  )    //  input  
    );

//wire debug_test ;
//assign  debug_test = m_axis_rc_tvalid|s_axis_cc_tvalid|s_axis_rq_tvalid;
//
//
//
//  ila_debug_256x6 ila_debug_256x8_test0
//  (
//      .clk        (pcie_clk    ),
//      .probe0     (m_axis_rc_tdata  ),
//      .probe1     (s_axis_cc_tdata  ),
//      
//      .probe2     (s_axis_rq_tdata),
//      .probe3     ({
//                    44'b0,//           
//                     m_axis_rc_tvalid, //1
//                     m_axis_rc_tready, //1
//                     m_axis_rc_tlast , //1
//                     m_axis_rc_tkeep , //8
//                     m_axis_rc_tuser , //75
//                     s_axis_cc_tvalid, //1
//                     s_axis_cc_tready, //1
//                     s_axis_cc_tkeep ,//8 
//                     s_axis_cc_tlast ,//1 
//                     s_axis_cc_tuser ,//33 
//                     s_axis_rq_tvalid, //1
//                     s_axis_rq_tready, //1
//                     s_axis_rq_tkeep , //8
//                     s_axis_rq_tlast , //1
//                     s_axis_rq_tuser , //60
//  
//                     debug_test      ,//1
//                     c_os_config     ,//1
//                     c_os_big_endian ,//1
//                     user_lnk_up     //1
//  
//      }),
//      .probe4     (m_axis_cq_tdata),
//      .probe5      ({m_axis_cq_tready,m_axis_cq_tvalid,m_axis_cq_tlast,m_axis_cq_tkeep,cfg_current_speed,cfg_negotiated_width,cfg_phy_link_down,cfg_phy_link_status,
//                     m_axis_cq_tuser,pcie_cq_np_req_count,pcie_cq_np_req,pcie_rq_tag,pcie_rq_tag_vld,pcie_rq_tag_av
//                      })
//  
//  );
//
//
//ila_debug_256x4 ila_debug_256x8_pcie0
//(
//    .clk        (pcie_clk    ),
//    .probe0     (dma_s_axis_tdata[255:0]   ),
//    .probe1     (dma_m_axis_tdata[255:0]   ),
//    
//    .probe2     ({  
//                   interrupt_bus_req,//1
//                   interrupt_bus_gnt,//1
//                   interrupt_bus_vector,//18       
//                    dma_m_axis_tready[3:0]   ,
//                    dma_m_axis_tvalid [3:0]  ,
//                    dma_m_axis_tstrb [15:0]  ,
//                    dma_m_axis_tkeep [15:0]  ,
//                    dma_m_axis_tlast[3:0]    ,
//                    dma_m_axis_tuser[191:0]   
// 
//    
//    }),
//    .probe3     ({
//                    dma_s_axis_tready [4:0],
//                    dma_s_axis_tvalid [4:0],
//                    dma_s_axis_tstrb [15:0],
//                    dma_s_axis_tkeep [15:0],
//                    dma_s_axis_tlast [4:0] ,
//                    dma_s_axis_tuser[191:0]
//
//    })
//
//);



// dma_test    u_dma_test(
//     .rst               (pcie_rst          ),
//     .dma_up_status     (dma_up_status     ),
//     .dma_up_packet     (dma_up_packet     ),
//     .dma_dn_packet     (dma_dn_packet     ),
//     .dma_m_axis_aclk   (dma_m_axis_aclk   ),
//     .dma_m_axis_tdata  (dma_m_axis_tdata  ),
//     .dma_m_axis_tid    (dma_m_axis_tid    ),
//     .dma_m_axis_tready (dma_m_axis_tready ),
//     .dma_m_axis_tvalid (dma_m_axis_tvalid ),
//     .dma_m_axis_tstrb  (dma_m_axis_tstrb  ),
//     .dma_m_axis_tkeep  (dma_m_axis_tkeep  ),
//     .dma_m_axis_tlast  (dma_m_axis_tlast  ),
//     .dma_m_axis_tuser  (dma_m_axis_tuser  ),
//     .dma_m_axis_tdest  (dma_m_axis_tdest  ),
//     .dma_s_axis_aclk   (dma_s_axis_aclk   ),
//     .dma_s_axis_tdata  (dma_s_axis_tdata  ),
//     .dma_s_axis_tid    (dma_s_axis_tid    ),
//     .dma_s_axis_tready (dma_s_axis_tready ),
//     .dma_s_axis_tvalid (dma_s_axis_tvalid ),
//     .dma_s_axis_tstrb  (dma_s_axis_tstrb  ),
//     .dma_s_axis_tkeep  (dma_s_axis_tkeep  ),
//     .dma_s_axis_tlast  (dma_s_axis_tlast  ),
//     .dma_s_axis_tuser  (dma_s_axis_tuser  ),
//     .dma_s_axis_tdest  (dma_s_axis_tdest  )
// );


endmodule