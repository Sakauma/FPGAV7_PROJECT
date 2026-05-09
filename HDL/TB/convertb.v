`timescale 1ns/1ns
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			ZHTY				
// Engineer:		DuCHaoMing	        
//                                      
// Create Date:		2014/6/12 9:49:39   
// Design Name:                         
// Module Name:		module_name.v       
// Project Name:		                
// Target Devices:	XC7Z045FFG600-2L    
// Tool versions:	ISE 14.6 or Vivado  
// Description:                         
// 										
// Dependencies:						
// 										
// Top File:							
// 										
// Inst File£º							
// 										
// Revision:							
// 										
////////////////////////////////////////////////////////////////////////////////////////////////////
module convertb	(	);
//==================================================================================================
//--Signals Define------------------------------  

	localparam 	SRIO_DW		=64	;
	localparam 	PCIE_DW		=256	;



	

	wire	[	        1			-1 :	0	]  dma_m_axis_tvalid	  ;
	wire	[	        1			-1 :	0	]  dma_m_axis_tready	  ;
	wire	[	        1			-1 :	0	]  dma_m_axis_tlast	  ;
	wire	[	        256			-1 :	0	]  dma_m_axis_tdata	  ;
	wire	[	        64			-1 :	0	]  dma_m_axis_tuser	  ;
	wire	[	        256/8		-1 :	0	]  dma_m_axis_tkeep	  ;
	wire	[	        256/8		-1 :	0	]  dma_m_axis_tstrb	  ;
	wire	[	        4			-1 :	0	]  dma_m_axis_tdest	  ;
	wire	[	        4			-1 :	0	]  dma_m_axis_tid		  ;
	reg											 pcie_rst	=1				;
	reg											 fst_clk		=0				;
	reg											 pcie_clk	=0				;
	wire	[	        1			-1 :	0 ]  dma_rio_tx_tvalid	  ;
	wire	[	        1			-1 :	0 ]  dma_rio_tx_tready	  ;
	wire	[	        1			-1 :	0 ]  dma_rio_tx_tlast	  ;
	wire	[	        64			-1 :	0 ]  dma_rio_tx_tdata	  ;
	wire	[	        64			-1 :	0 ]  dma_rio_tx_tuser	  ;
	wire	[	        64/8		-1 :	0 ]  dma_rio_tx_tkeep	  ;
	wire	[	        64/8		-1 :	0 ]  dma_rio_tx_tstrb	  ;
	wire	[	        4			-1 :	0 ]  dma_rio_tx_tdest	  ;
	wire	[	        4			-1 :	0 ]  dma_rio_tx_tid		  ;

	
	always  #4 pcie_clk	= ~pcie_clk ;
	
	always  #2 fst_clk  = ~fst_clk	;
	
	
	initial  begin 
		pcie_rst			= 1 ;
		
	#500;	pcie_rst		= 0 ;	
		
		
		
		
		
		
		
		
		
		
	end

//==================================================================================================
//--Parameter Define----------------------------

 User_Data_Test datatest(
     . i_clk              (		fst_clk			) ,// input         
     . i_rst              (		pcie_rst				) ,// input         
                                    
     . m_axis_data        (		dma_rio_tx_tdata  	 ) ,// output     [63:0] 
     . m_axis_user        (		dma_rio_tx_tuser     ) ,// output	 [31:0] //16'dlen,48'dsource_mac,16'dtype
     . m_axis_keep        (		dma_rio_tx_tkeep     ) ,// output	 [7 :0] 
     . m_axis_last        (		dma_rio_tx_tlast  	 ) ,// output            
     . m_axis_valid       (		dma_rio_tx_tvalid 	 ) ,// output            
     . m_axis_ready       (		dma_rio_tx_tready 	 ) ,// input             
                                        
     . s_axis_data        (		                ) ,// input  [63:0] 
     . s_axis_user        (		                  ) ,// input  [31:0] //16'dlen,48'dsource_mac,16'dtype
     . s_axis_keep        (		                 ) ,// input  [7 :0] 
     . s_axis_last        (		                ) ,// input         
     . s_axis_valid       (		                )  // input         
);                           	






axis_convert_top#(
		.	DW		(	SRIO_DW	)	,
		.	QW		(	PCIE_DW	)	
	)sp_tx_convert(
		.	axsr_tvalid			(	dma_rio_tx_tvalid	                        )			,	//	input		                     									
		.	axsr_tready			(	dma_rio_tx_tready	                        )			,	//	output		                     									
		.	axsr_tlast			(	dma_rio_tx_tlast	                        )			,	//	input		                     									
		.	axsr_tdata			(	dma_rio_tx_tdata	                        )			,	//	input		                     [	DW		-	1	:	0	]		
		.	axsr_tuser			(	dma_rio_tx_tuser	                        )			,	//	input		                     [	64		-	1	:	0	]		
		.	axsr_tkeep			(	dma_rio_tx_tkeep	                        )			,	//	input		                     [	DW/8	-	1	:	0	]		
		.	axsr_tstrb			(	8'hff	 			                        )			,	//	input		                     [	DW/8	-	1	:	0	]		
		.	axsr_tdest			(	0	                       					 )			,	//	input						                     [	4		-	1	:	0	]		
		.	axsr_tid			(	0	                        				)			,	//	input						                     [	4		-	1	:	0	]		
		.	i_rst				(	pcie_rst	                        )			,	//	input		pcie_rst			                     									
		.	i_clk				(	fst_clk	                        )			,	//	input		pcie_clk			                     									
		.	axst_tvalid			(	dma_m_axis_tvalid	                        )			,	//	output		                     									
		.	axst_tready			(	1 					                        )			,	//	input		                     									
		.	axst_tlast			(	dma_m_axis_tlast	                        )			,	//	output		                     									
		.	axst_tdata			(	dma_m_axis_tdata	                        )			,	//	output		                     [	QW		-	1	:	0	]		
		.	axst_tuser			(	dma_m_axis_tuser	                        )			,	//	output		                     [	64		-	1	:	0	]		
		.	axst_tkeep			(	dma_m_axis_tkeep	                        )			,	//	output		                     [	QW/8	-	1	:	0	]		
		.	axst_tstrb			(	dma_m_axis_tstrb							)			,	//	output							 [	QW/8	-	1	:	0	]		
		.	axst_tdest			(	dma_m_axis_tdest							)			,	//	output							 [	4		-	1	:	0	]		
		.	axst_tid			(	dma_m_axis_tid								)			,	//	output							 [	4		-	1	:	0	]		
		.	o_rst				(		pcie_rst	 						)			,	//	input	pcie_rst								 										
		.	o_clk				(		pcie_clk		 					)			 	//	input		fst_clk									 									
	);




endmodule
