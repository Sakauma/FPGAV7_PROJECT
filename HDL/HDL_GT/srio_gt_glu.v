
module srio_gen2_0_7s_gt_top_glu
    #(
        parameter       LINK_WIDTH      = 4
    )
	(
        output  wire    [LINK_WIDTH     -1:0]       gt_txpmareset_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxpmareset_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_txpcsreset_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxpcsreset_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_eyescanreset_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_eyescantrigger_in	    ,

        output  wire    [LINK_WIDTH* 3  -1:0]       gt_loopback_in			    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxpolarity_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_txpolarity_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxlpmen_in			    ,
        output  wire    [LINK_WIDTH* 5  -1:0]       gt_txprecursor_in		    ,
        output  wire    [LINK_WIDTH* 5  -1:0]       gt_txpostcursor_in		    ,
        output  wire    [LINK_WIDTH* 4  -1:0]       gt_txdiffctrl_in		    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_txprbsforceerr_in	    ,
        output  wire    [LINK_WIDTH* 3  -1:0]       gt_txprbssel_in		        ,
        output  wire    [LINK_WIDTH* 3  -1:0]       gt_rxprbssel_in		        ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxprbscntreset_in	    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxcdrhold_in		        ,
        output  wire    [LINK_WIDTH     -1:0]       gt_rxdfelpmreset_in	        ,

    //  input   wire    [LINK_WIDTH     -1:0]       gt_eyescandataerror_out     ,
    //  input   wire    [LINK_WIDTH     -1:0]       gt_rxprbserr_out		    ,
    //  input   wire    [LINK_WIDTH* 8  -1:0]       gt_dmonitorout_out		    ,
    //  input   wire    [LINK_WIDTH     -1:0]       gt_rxcommadet_out		    ,
    //  input   wire    [LINK_WIDTH     -1:0]       gt_rxresetdone_out		    ,
    //  input   wire    [LINK_WIDTH     -1:0]       gt_txresetdone_out		    ,
      
    //  input   wire    [LINK_WIDTH* 2  -1:0]       gt_txbufstatus_out		    ,
    //  input   wire    [LINK_WIDTH* 3  -1:0]       gt_rxbufstatus_out		    ,

        input   wire    [LINK_WIDTH*16  -1:0]       gt_drpdo_out 			    ,
        input   wire    [LINK_WIDTH     -1:0]       gt_drprdy_out			    ,
        output  wire    [LINK_WIDTH* 9  -1:0]       gt_drpaddr_in			    ,
        output  wire    [LINK_WIDTH*16  -1:0]       gt_drpdi_in  			    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_drpen_in  			    ,
        output  wire    [LINK_WIDTH     -1:0]       gt_drpwe_in  			    ,

        output  wire    [LINK_WIDTH*4*8 -1:0]       gttx_data                   ,
        output  wire    [LINK_WIDTH*4   -1:0]       gttx_charisk

	); //srio_gen2_bm_top_glu


	//------------------------Parameter----------------------

	//------------------------Local signal-------------------

	//------------------------Body---------------------------

    assign      gttx_data               = {LINK_WIDTH{32'haaaa_aaaa}}   ;
    assign      gttx_charisk            = {LINK_WIDTH{4'hf}}            ;
            
    assign      gt_drpaddr_in           = {LINK_WIDTH{ 9'b0}}           ;
    assign      gt_drpdi_in             = {LINK_WIDTH{16'b0}}           ;
    assign      gt_drpen_in             = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_drpwe_in             = {LINK_WIDTH{ 1'b0}}           ;

    assign      gt_txpmareset_in        = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_rxpmareset_in        = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_txpcsreset_in        = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_rxpcsreset_in        = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_eyescanreset_in      = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_eyescantrigger_in    = {LINK_WIDTH{ 1'b0}}           ;

    assign      gt_loopback_in          = {LINK_WIDTH{ 3'b0}}           ;
    assign      gt_rxpolarity_in        = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_txpolarity_in        = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_rxlpmen_in           = {LINK_WIDTH{ 1'b1}}           ;
    assign      gt_txprecursor_in       = {LINK_WIDTH{ 5'b0}}           ;
    assign      gt_txpostcursor_in      = {LINK_WIDTH{ 5'b0}}           ;
    assign      gt_txprbsforceerr_in    = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_txprbssel_in         = {LINK_WIDTH{ 3'b0}}           ;
    assign      gt_rxprbssel_in         = {LINK_WIDTH{ 3'b0}}           ;
    assign      gt_rxprbscntreset_in    = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_rxcdrhold_in         = {LINK_WIDTH{ 1'b0}}           ;
    assign      gt_rxdfelpmreset_in     = {LINK_WIDTH{ 1'b0}}           ;

    assign      gt_txdiffctrl_in        = {LINK_WIDTH{4'b1000}}         ;

	//------------------------Instantiation------------------

endmodule


