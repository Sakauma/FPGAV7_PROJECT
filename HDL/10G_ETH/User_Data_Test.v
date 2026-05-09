`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/28 14:30:13
// Design Name: 
// Module Name: User_Data_Test
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


module User_Data_Test(
    input           i_clk               ,
    input           i_rst               ,

    output [63:0]   m_axis_data         ,
    output [63:0]   m_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]   m_axis_keep         ,
    output          m_axis_last         ,
    output          m_axis_valid        ,
    input           m_axis_ready        ,
    
    input  [63:0]   s_axis_data         ,
    input  [31:0]   s_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    input  [7 :0]   s_axis_keep         ,
    input           s_axis_last         ,
    input           s_axis_valid        
);

localparam          P_LEN = 16'd34    ;
localparam          P_GAP = 10        ;//MACï¿½ï¿½ï¿? = P_GAP - 1

reg  [63:0]         rs_axis_data        ;
reg  [31:0]         rs_axis_user        ;
reg  [7 :0]         rs_axis_keep        ;
reg                 rs_axis_last        ;
reg                 rs_axis_valid       ;
reg  [63:0]         rm_axis_data        ;
reg  [79:0]         rm_axis_user        ;
reg  [7 :0]         rm_axis_keep        ;
reg                 rm_axis_last        ;
reg                 rm_axis_valid       ;
reg                 r_run_1d            ;

reg  [31:0]         r_wait_cnt          ;
reg                 r_trigger           ;
reg  [15:0]         r_cnt               ;
reg                 r_run               ;

assign m_axis_data  = rm_axis_data      ;
assign m_axis_user  = rm_axis_user      ;
assign m_axis_keep  = rm_axis_keep      ;
assign m_axis_last  = rm_axis_last      ;
assign m_axis_valid = rm_axis_valid     ;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        rs_axis_data  <= 'd0;
        rs_axis_user  <= 'd0;
        rs_axis_keep  <= 'd0;
        rs_axis_last  <= 'd0;
        rs_axis_valid <= 'd0;
        r_run_1d      <= 'd0;
    end else begin
        rs_axis_data  <= s_axis_data ;
        rs_axis_user  <= s_axis_user ;
        rs_axis_keep  <= s_axis_keep ;
        rs_axis_last  <= s_axis_last ;
        rs_axis_valid <= s_axis_valid;
        r_run_1d      <= r_run;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_wait_cnt <= 'd0;
    else if(r_wait_cnt == P_GAP && m_axis_ready)
        r_wait_cnt <= 'd0;
    else if(r_wait_cnt == P_GAP)
        r_wait_cnt <= r_wait_cnt;
    else if(!rm_axis_valid)
        r_wait_cnt <= r_wait_cnt + 1;
    else 
        r_wait_cnt <= r_wait_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_trigger <= 'd0;
    else if(r_wait_cnt == P_GAP && m_axis_ready)
        r_trigger <= 'd1;
    else        
        r_trigger <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_run <= 'd0;
    else if(r_cnt == P_LEN - 1)
        r_run <= 'd0;
    else if(r_trigger)
        r_run <= 'd1;
    else 
        r_run <= r_run;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == P_LEN - 1)
        r_cnt <= 'd0;
    else if(r_run)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user <= 'd0;
    else 
        rm_axis_user <= {16'd0,16'h44};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_keep <= 8'b0000_0000;
    else 
        rm_axis_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_data <= 'd0;
    else 
        rm_axis_data <= {4{r_cnt}};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_last <= 'd0;
    else if(r_cnt == P_LEN - 1)
        rm_axis_last <= 'd1;
    else 
        rm_axis_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_valid <= 'd0;
    else if(rm_axis_last)
        rm_axis_valid <= 'd0;
    else if(r_run && !r_run_1d)
        rm_axis_valid <= 'd1;
    else 
        rm_axis_valid <= rm_axis_valid;
end

endmodule
