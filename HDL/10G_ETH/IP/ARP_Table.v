`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/22 14:19:39
// Design Name: 
// Module Name: ARP_Table
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


module ARP_Table(
    input           i_clk           ,
    input           i_rst           ,

    input  [47:0]   i_write_mac     ,
    input  [31:0]   i_write_ip      ,
    input           i_write_valid   ,

    input  [31:0]   i_query_ip      ,
    input           i_query_valid   ,
    output [47:0]   o_read_mac      ,
    output          o_read_valid   
);

reg  [47:0]         ri_write_mac    ;
reg  [31:0]         ri_write_ip     ;
reg                 ri_write_valid  ;
reg                 r_rewrite       ;
reg                 r_rewrite_1d    ;
reg  [2 :0]         r_readdr        ;
reg  [2 :0]         r_write_addr    ;
reg  [2 :0]         r_write_addr_ed ;
reg  [2 :0]         r_read_addr     ;  
reg  [31:0]         r_ram_ip[0:7]   ;
reg  [47:0]         r_ram_mac[0:7]  ;
reg  [47:0]         ro_read_mac     ;
reg                 ro_read_valid   ;

assign o_read_mac   = ro_read_mac   ;
assign o_read_valid = ro_read_valid ;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_write_mac   <= 'd0;
        ri_write_ip    <= 'd0;
        ri_write_valid <= 'd0;
        r_rewrite_1d   <= 'd0;
    end else begin
        ri_write_mac   <= i_write_mac  ;  
        ri_write_ip    <= i_write_ip   ; 
        ri_write_valid <= i_write_valid; 
        r_rewrite_1d   <= r_rewrite;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_readdr <= 'd0;
    else if(r_ram_ip[0] == i_write_ip && i_write_valid)
        r_readdr <= 'd0;
    else if(r_ram_ip[1] == i_write_ip && i_write_valid)
        r_readdr <= 'd1;
    else if(r_ram_ip[2] == i_write_ip && i_write_valid)
        r_readdr <= 'd2;
    else if(r_ram_ip[3] == i_write_ip && i_write_valid)
        r_readdr <= 'd3;
    else if(r_ram_ip[4] == i_write_ip && i_write_valid)
        r_readdr <= 'd4;
    else if(r_ram_ip[5] == i_write_ip && i_write_valid)
        r_readdr <= 'd5;
    else if(r_ram_ip[6] == i_write_ip && i_write_valid)
        r_readdr <= 'd6;
    else if(r_ram_ip[7] == i_write_ip && i_write_valid)
        r_readdr <= 'd7;
    else 
        r_readdr <= 'd0;

end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_rewrite <= 'd0;
    else if(r_ram_ip[0] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[1] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[2] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[3] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[4] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[5] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[6] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else if(r_ram_ip[7] == i_write_ip && i_write_valid)
        r_rewrite <= 'd1;
    else 
        r_rewrite <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_write_addr <= 'd0;
    else if(r_rewrite)
        r_write_addr <= r_readdr;
    else if(!r_rewrite && r_rewrite_1d)
        r_write_addr <= r_write_addr_ed;
    else if(ri_write_valid)
        r_write_addr <= r_write_addr + 1;
    else 
        r_write_addr <= r_write_addr;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_write_addr_ed <= 'd0;
    else 
        r_write_addr_ed <= r_write_addr;
end

genvar i;
generate for(i = 0;i < 8;i = i + 1) 
begin

    always@(posedge i_clk,posedge i_rst)
    begin
        if(i_rst)
            r_ram_ip[i] <= 'd0;
        else if((i == r_write_addr && ri_write_valid && !r_rewrite) || (r_rewrite_1d && i == r_write_addr))
            r_ram_ip[i] <= ri_write_ip;
        else
            r_ram_ip[i] <= r_ram_ip[i];
    end

    always@(posedge i_clk,posedge i_rst)
    begin
        if(i_rst)
            r_ram_mac[i] <= 48'hff_ff_ff_ff_ff_ff;
        else if((i == r_write_addr && ri_write_valid && !r_rewrite) || (r_rewrite_1d && i == r_write_addr))
            r_ram_mac[i] <= ri_write_mac;
        else
            r_ram_mac[i] <= r_ram_mac[i];
    end
end

endgenerate

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_read_mac <= 'd0;
    else if(i_query_valid && i_query_ip == r_ram_ip[0])
        ro_read_mac <= r_ram_mac[0];
    else if(i_query_valid && i_query_ip == r_ram_ip[1])
        ro_read_mac <= r_ram_mac[1];
    else if(i_query_valid && i_query_ip == r_ram_ip[2])
        ro_read_mac <= r_ram_mac[2];
    else if(i_query_valid && i_query_ip == r_ram_ip[3])
        ro_read_mac <= r_ram_mac[3];
    else if(i_query_valid && i_query_ip == r_ram_ip[4])
        ro_read_mac <= r_ram_mac[4];
    else if(i_query_valid && i_query_ip == r_ram_ip[5])
        ro_read_mac <= r_ram_mac[5];
    else if(i_query_valid && i_query_ip == r_ram_ip[6])
        ro_read_mac <= r_ram_mac[6];
    else if(i_query_valid && i_query_ip == r_ram_ip[7])
        ro_read_mac <= r_ram_mac[7];
    else 
        ro_read_mac <= ro_read_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_read_valid <= 'd0;
    else if(i_query_valid)
        ro_read_valid <= 'd1;
    else 
        ro_read_valid <= 'd0;
end    

endmodule
