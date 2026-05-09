`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/06 11:06:44
// Design Name: 
// Module Name: TenG_Mac_Rx
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


module TenG_Mac_Rx#(
    parameter       P_SOURCE_MAC  = 48'h00_00_00_00_00_00   ,
    parameter       P_TARGET_MAC  = 48'h00_00_00_00_00_00   
)(
    input           i_clk               ,
    input           i_rst               ,
    input  [63:0]   i_xgmii_rxd         ,
    input  [7 :0]   i_xgmii_rxc         ,

    input  [47:0]   i_set_source_mac    ,
    input           i_set_source_valid  ,
    input  [47:0]   i_set_target_mac    ,
    input           i_set_target_valid  ,

    output [63:0]   m_axis_data         ,
    output [79:0]   m_axis_user         ,//16'dlen,48'dsource_mac,16'dtype
    output [7 :0]   m_axis_keep         ,
    output          m_axis_last         ,
    output          m_axis_valid        ,

    output          o_crc_error         ,
    output          o_crc_valid         
);

reg  [47:0]         ri_set_source_mac   ;
reg  [47:0]         ri_set_target_mac   ;
reg  [63:0]         ri_xgmii_rxd        ;
reg  [7 :0]         ri_xgmii_rxc        ;
reg  [63:0]         ri_xgmii_rxd_1d     ;
reg  [7 :0]         ri_xgmii_rxc_1d     ;
reg  [63:0]         ri_xgmii_rxd_2d     ;
reg  [7 :0]         ri_xgmii_rxc_2d     ;
(* MARK_DEBUG = "TRUE" *)reg  [63:0]         rm_axis_data        ;
(* MARK_DEBUG = "TRUE" *)reg  [79:0]         rm_axis_user        ;
(* MARK_DEBUG = "TRUE" *)reg  [7 :0]         rm_axis_keep        ;
(* MARK_DEBUG = "TRUE" *)reg                 rm_axis_last        ;
(* MARK_DEBUG = "TRUE" *)reg                 rm_axis_valid       ;
(* MARK_DEBUG = "TRUE" *)reg  [15:0]         r_cnt               ;
(* MARK_DEBUG = "TRUE" *)reg  [47:0]         r_target_mac        ;
(* MARK_DEBUG = "TRUE" *)reg  [47:0]         r_source_mac        ;
(* MARK_DEBUG = "TRUE" *)reg  [15:0]         r_type              ;
(* MARK_DEBUG = "TRUE" *)reg                 r_commoa            ;
reg                 r_sof               ;
reg                 r_eof               ;
reg                 r_eof_1d            ;
reg                 r_eof_2d            ;
reg  [2 :0]         r_sof_local         ;
reg  [2 :0]         r_eof_local         ;
reg                 r_run               ;
reg                 r_run_1d            ;
(* MARK_DEBUG = "TRUE" *)reg  [63:0]         r_crc_data          ;
(* MARK_DEBUG = "TRUE" *)reg  [7 :0]         r_crc_keep          ;
reg  [7 :0]         r_crc_keep_1d       ;
(* MARK_DEBUG = "TRUE" *)reg                 r_crc_en            ;
reg                 r_crc_en_1d         ;
(* MARK_DEBUG = "TRUE" *)reg  [31:0]         r_crc_result        ;
reg                 ro_crc_valid        ;
reg  [2 :0]         r_eof_local_1d      ;
reg  [2 :0]         r_eof_local_2d      ;
(* MARK_DEBUG = "TRUE" *)reg  [31:0]         r_crc_source        ;
reg                 r_crc_error         ;
reg                 r_crc_check         ;   
reg                 r_crc_run           ;                    
reg                 r_crc_run_1d        ;
reg                 r_sof_1d            ;
reg  [15:0]         r_len               ;
reg                 r_mac_check         ;
reg                 r_out               ;

wire                w_sof               ;
wire                w_eof               ;
wire [2 :0]         w_sof_local         ;
wire [2 :0]         w_eof_local         ;
wire [31:0]         w_crc               ;
wire [31:0]         w_crc_1             ;
wire [31:0]         w_crc_2             ;
wire [31:0]         w_crc_3             ;
wire [31:0]         w_crc_4             ;
wire [31:0]         w_crc_5             ;
wire [31:0]         w_crc_6             ;
wire [31:0]         w_crc_7             ;

assign m_axis_data  = rm_axis_data      ;
assign m_axis_user  = rm_axis_user      ;
assign m_axis_keep  = rm_axis_keep      ;
assign m_axis_last  = rm_axis_last      ;
assign m_axis_valid = rm_axis_valid     ;

assign w_sof = (ri_xgmii_rxc[7] && ri_xgmii_rxd[63:56] == 8'hFB) || 
               (ri_xgmii_rxc[3] && ri_xgmii_rxd[31:24] == 8'hFB) ;
assign w_sof_local = (ri_xgmii_rxc[7] && ri_xgmii_rxd[63:56] == 8'hFB) ? 0 : 1;

assign w_eof = (ri_xgmii_rxc[0] && ri_xgmii_rxd[7 :  0] == 8'hFD) ||
               (ri_xgmii_rxc[1] && ri_xgmii_rxd[15:  8] == 8'hFD) ||
               (ri_xgmii_rxc[2] && ri_xgmii_rxd[23: 16] == 8'hFD) ||
               (ri_xgmii_rxc[3] && ri_xgmii_rxd[31: 24] == 8'hFD) ||
               (ri_xgmii_rxc[4] && ri_xgmii_rxd[39: 32] == 8'hFD) ||
               (ri_xgmii_rxc[5] && ri_xgmii_rxd[47: 40] == 8'hFD) ||
               (ri_xgmii_rxc[6] && ri_xgmii_rxd[55: 48] == 8'hFD) ||
               (ri_xgmii_rxc[7] && ri_xgmii_rxd[63: 56] == 8'hFD)  ;
assign w_eof_local = (ri_xgmii_rxc[1] && ri_xgmii_rxd[15:  8] == 8'hFD) ? 6 :
                     (ri_xgmii_rxc[2] && ri_xgmii_rxd[23: 16] == 8'hFD) ? 5 :
                     (ri_xgmii_rxc[3] && ri_xgmii_rxd[31: 24] == 8'hFD) ? 4 :
                     (ri_xgmii_rxc[4] && ri_xgmii_rxd[39: 32] == 8'hFD) ? 3 :
                     (ri_xgmii_rxc[5] && ri_xgmii_rxd[47: 40] == 8'hFD) ? 2 :
                     (ri_xgmii_rxc[6] && ri_xgmii_rxd[55: 48] == 8'hFD) ? 1 :
                     (ri_xgmii_rxc[7] && ri_xgmii_rxd[63: 56] == 8'hFD) ? 0 :
                     7 ;

assign o_crc_error = r_crc_error;
assign o_crc_valid  = ro_crc_valid;

CRC32_64bKEEP CRC32_64bKEEP_u0(
  .i_clk            (i_clk              ),
  .i_rst            (i_rst              ),
  .i_en             (r_crc_en           ),
  .i_data           (r_crc_data[63:56]  ),
  .i_data_1         (r_crc_data[55:48]  ),
  .i_data_2         (r_crc_data[47:40]  ),
  .i_data_3         (r_crc_data[39:32]  ),
  .i_data_4         (r_crc_data[31:24]  ),
  .i_data_5         (r_crc_data[23:16]  ),
  .i_data_6         (r_crc_data[15: 8]  ),
  .i_data_7         (r_crc_data[7 : 0]  ),
  .o_crc            (w_crc              ),
  .o_crc_1          (w_crc_1            ),
  .o_crc_2          (w_crc_2            ),
  .o_crc_3          (w_crc_3            ),
  .o_crc_4          (w_crc_4            ),
  .o_crc_5          (w_crc_5            ),
  .o_crc_6          (w_crc_6            ),
  .o_crc_7          (w_crc_7            )
);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_source_mac <= P_SOURCE_MAC;
    else if(i_set_source_valid)
        ri_set_source_mac <= i_set_source_mac;
    else 
        ri_set_source_mac <= ri_set_source_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ri_set_target_mac <= P_TARGET_MAC;
    else if(i_set_target_valid)
        ri_set_target_mac <= i_set_target_mac;
    else 
        ri_set_target_mac <= ri_set_target_mac;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_xgmii_rxd        <= 'd0;
        ri_xgmii_rxc        <= 'd0;
        r_run_1d            <= 'd0;
        ri_xgmii_rxd_1d     <= 'd0;
        ri_xgmii_rxc_1d     <= 'd0;
        r_sof               <= 'd0;
        r_eof               <= 'd0;
        ri_xgmii_rxd_2d     <= 'd0;
        ri_xgmii_rxc_2d     <= 'd0;
        r_eof_1d            <= 'd0;
        r_eof_2d            <= 'd0;
        r_crc_keep_1d       <= 'd0;
        r_crc_en_1d         <= 'd0;
        r_eof_local_1d      <= 'd0;
        r_eof_local_2d      <= 'd0;
        r_crc_run_1d        <= 'd0;
        r_sof_1d            <= 'd0;
    end else begin
        ri_xgmii_rxd        <= i_xgmii_rxd      ;
        ri_xgmii_rxc        <= i_xgmii_rxc      ;
        r_run_1d            <= r_run            ;
        ri_xgmii_rxd_1d     <= ri_xgmii_rxd     ;
        ri_xgmii_rxc_1d     <= ri_xgmii_rxc     ;
        r_sof               <= w_sof            ;
        r_eof               <= w_eof            ;
        ri_xgmii_rxd_2d     <= ri_xgmii_rxd_1d  ;
        ri_xgmii_rxc_2d     <= ri_xgmii_rxc_1d  ;
        r_eof_1d            <= r_eof            ;
        r_crc_keep_1d       <= r_crc_keep       ;
        r_crc_en_1d         <= r_crc_en         ;  
        r_eof_local_1d      <= r_eof_local      ;
        r_crc_run_1d        <= r_crc_run        ;
        r_sof_1d            <= r_sof            ;
        r_eof_local_2d      <= r_eof_local_1d   ; 
        r_eof_2d            <= r_eof_1d         ;
    end 
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_sof_local  <= 'd0;
    else if(w_sof)
        r_sof_local  <= w_sof_local;
    else    
        r_sof_local  <= r_sof_local;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_eof_local  <= 'd0;
    else if(w_eof)
        r_eof_local  <= w_eof_local;
    else 
        r_eof_local  <= r_eof_local;
end     
        
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_eof)
        r_cnt <= 'd0;
    else if(r_sof || r_cnt)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= r_cnt;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_commoa <= 'd0;
    else if(r_eof)
        r_commoa <= 'd0;                 
    else if(r_sof_local == 0 && r_sof && ri_xgmii_rxd_1d[55 :0] == 56'h555555_55555555 && ri_xgmii_rxd[63:56] == 8'hD5)
        r_commoa <= 'd1;
    else if(r_sof_local == 1 && r_sof && ri_xgmii_rxd_1d[23 :0] == 24'h555555 && ri_xgmii_rxd[63:24] == 40'h55555555_D5)
        r_commoa <= 'd1;
    else 
        r_commoa <= r_commoa;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_target_mac <= 'd0;
    else if(r_sof_local == 0 && r_cnt == 1)
        r_target_mac <= ri_xgmii_rxd_1d[55:8];
    else if(r_sof_local == 1 && r_cnt == 1)
        r_target_mac <= {ri_xgmii_rxd_1d[23:0],ri_xgmii_rxd[63:40]};
    else 
        r_target_mac <= r_target_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_source_mac <= 'd0;
    else if(r_sof_local == 0 && r_cnt == 1)
        r_source_mac <= {ri_xgmii_rxd_1d[7 :0],ri_xgmii_rxd[63:24]};
    else if(r_sof_local == 1 && r_cnt == 2)
        r_source_mac <= {ri_xgmii_rxd_1d[39:0],ri_xgmii_rxd[63:56]};
    else 
        r_source_mac <= r_source_mac;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_mac_check <= 'd0;
    else if(r_cnt == 2 && r_target_mac == 48'hff_ff_ff_ff_ff_ff)
        r_mac_check <= 'd1;
    else if(r_cnt == 2 && r_target_mac == ri_set_source_mac)
        r_mac_check <= 'd1;
    else if(r_cnt == 2 && r_target_mac != ri_set_source_mac)
        r_mac_check <= 'd0;
    else 
        r_mac_check <= r_mac_check;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_type <= 'd0;
    else if(r_sof_local == 0 && r_cnt == 2)
        r_type <= ri_xgmii_rxd_1d[23:8];
    else if(r_sof_local == 1 && r_cnt == 3)
        r_type <= ri_xgmii_rxd_1d[55:40];
    else 
        r_type <= r_type;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_run <= 'd0;
    else if(r_eof_1d)
        r_run <= 'd0;
    else if(r_sof_local == 0 && r_cnt == 2)
        r_run <= 'd1;
    else if(r_sof_local == 1 && r_cnt == 3)       
        r_run <= 'd1;
    else 
        r_run <= r_run;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_run <= 'd0;
    else if(r_eof_1d)
        r_crc_run <= 'd0;
    else if(r_sof_1d)
        r_crc_run <= 'd1;
    else 
        r_crc_run <= r_crc_run;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_data <= 'd0;
    else if(r_sof_local == 0 && r_crc_run)
        r_crc_data <= {ri_xgmii_rxd_2d[55: 0],ri_xgmii_rxd_1d[63: 56]};
    else if(r_sof_local == 1 && r_crc_run)
        r_crc_data <= {ri_xgmii_rxd_2d[23: 0],ri_xgmii_rxd_1d[63:24]};
    else 
        r_crc_data <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_keep <= 'd0;
    else if(r_sof_local == 0 && r_eof && (r_eof_local <= 5))
        case(r_eof_local)
            0           :r_crc_keep <= 8'b1110_0000;//提前1cycle
            1           :r_crc_keep <= 8'b1111_0000;//提前1cycle
            2           :r_crc_keep <= 8'b1111_1000;//提前1cycle
            3           :r_crc_keep <= 8'b1111_1100;//提前1cycle
            4           :r_crc_keep <= 8'b1111_1110;
            5           :r_crc_keep <= 8'b1111_1111;
            default     :r_crc_keep <= 8'b1111_1111;
        endcase
    else if(r_sof_local == 0 && r_eof_1d && r_eof_local_1d >= 6)
        case(r_eof_local_1d)
            6           :r_crc_keep <= 8'b1000_0000;
            7           :r_crc_keep <= 8'b1100_0000;
            default     :r_crc_keep <= 8'b1111_1111;
        endcase
    else if(r_sof_local == 1 && w_eof && w_eof_local <= 1)   
        case(w_eof_local)
            0           :r_crc_keep <= 8'b1111_1110;
            1           :r_crc_keep <= 8'b1111_1111;
            default     :r_crc_keep <= 8'b1111_1111;
        endcase
    else if(r_sof_local == 1 && r_eof && r_eof_local >= 2)   
        case(r_eof_local)
            2           :r_crc_keep <= 8'b1000_0000;
            3           :r_crc_keep <= 8'b1100_0000;
            4           :r_crc_keep <= 8'b1110_0000;//提前1cycle
            5           :r_crc_keep <= 8'b1111_0000;//提前1cycle
            6           :r_crc_keep <= 8'b1111_1000;//提前1cycle
            7           :r_crc_keep <= 8'b1111_1100;
            default     :r_crc_keep <= 8'b1111_1111;
        endcase
    else 
        r_crc_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_en <= 'd0;
    else if(r_crc_run && !r_crc_run_1d)
        r_crc_en <= 'd1;
    else if(r_sof_local == 1 && r_eof && r_eof_local <= 1)  
        r_crc_en <= 'd0;
    else if(r_sof_local == 1 && r_eof_1d && r_eof_local_1d >= 2)  
        r_crc_en <= 'd0;
    else if(r_sof_local == 0 && r_eof_1d && (r_eof_local <= 5))
        r_crc_en <= 'd0;
    else if(r_sof_local == 0 && r_eof_2d && r_eof_local_2d >= 3)
        r_crc_en <= 'd0;
    else 
        r_crc_en <= r_crc_en;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_result <= 'd0;
    else if(!r_crc_en && r_crc_en_1d) 
        case(r_crc_keep_1d)
            8'b1111_1111        :r_crc_result <= w_crc;
            8'b1111_1110        :r_crc_result <= w_crc_7;
            8'b1111_1100        :r_crc_result <= w_crc_6;
            8'b1111_1000        :r_crc_result <= w_crc_5;
            8'b1111_0000        :r_crc_result <= w_crc_4;
            8'b1110_0000        :r_crc_result <= w_crc_3;
            8'b1100_0000        :r_crc_result <= w_crc_2;
            8'b1000_0000        :r_crc_result <= w_crc_1;
            default             :r_crc_result <= w_crc;
        endcase
    else        
        r_crc_result <= r_crc_result;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_crc_valid <= 'd0;
    else if(r_crc_check && r_out)
        ro_crc_valid <= 'd1;
    else 
        ro_crc_valid <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_source <= 'd0;
    else if(r_eof && r_eof_local == 0)
        r_crc_source <= ri_xgmii_rxd_2d[31:0];
    else if(r_eof && r_eof_local == 1)
        r_crc_source <= {ri_xgmii_rxd_2d[23:0],ri_xgmii_rxd_1d[63:56]};
    else if(r_eof && r_eof_local == 2)
        r_crc_source <= {ri_xgmii_rxd_2d[15:0],ri_xgmii_rxd_1d[63:48]};
    else if(r_eof && r_eof_local == 3)
        r_crc_source <= {ri_xgmii_rxd_2d[7 :0],ri_xgmii_rxd_1d[63:40]};
    else if(r_eof && r_eof_local == 4)
        r_crc_source <= ri_xgmii_rxd_1d[63:32];
    else if(r_eof && r_eof_local == 5)
        r_crc_source <= ri_xgmii_rxd_1d[55:24];
    else if(r_eof && r_eof_local == 6)
        r_crc_source <= ri_xgmii_rxd_1d[47:16];
    else if(r_eof && r_eof_local == 7)
        r_crc_source <= ri_xgmii_rxd_1d[39: 8];
    else 
        r_crc_source <= r_crc_source;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_check <= 'd0;
    else if(!r_crc_en && r_crc_en_1d)
        r_crc_check <= 'd1;
    else 
        r_crc_check <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_crc_error <= 'd0;
    else if(r_crc_check && r_crc_source != {r_crc_result[7 :0],r_crc_result[15:8],r_crc_result[23:16],r_crc_result[31:24]})
        r_crc_error <= 'd1;
    else 
        r_crc_error <= 'd0;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_data <= 'd0;
    else if(r_sof_local == 0 && r_run)
        rm_axis_data <= {ri_xgmii_rxd_2d[7 :0],ri_xgmii_rxd_1d[63:8]};
    else if(r_sof_local == 1 && r_run)
        rm_axis_data <= {ri_xgmii_rxd_2d[39:0],ri_xgmii_rxd_1d[63:40]};
    else 
        rm_axis_data <= 'd0;
end 

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_user <= 'd0;
    else        
        rm_axis_user <= {r_len + 16'd1,r_source_mac,r_type};
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_keep <= 'd0;
    else if(r_sof_local == 0 && w_eof && w_eof_local <= 3)
        case(w_eof_local)
            0           :rm_axis_keep <= 8'b1111_1000;
            1           :rm_axis_keep <= 8'b1111_1100;
            2           :rm_axis_keep <= 8'b1111_1110;
            3           :rm_axis_keep <= 8'b1111_1111;
            default     :rm_axis_keep <= 8'b1111_1000;
        endcase
    else if(r_sof_local == 0 && r_eof && r_eof_local >= 4)
        case(r_eof_local)
            4           :rm_axis_keep <= 8'b1000_0000;
            5           :rm_axis_keep <= 8'b1100_0000;
            6           :rm_axis_keep <= 8'b1110_0000;
            7           :rm_axis_keep <= 8'b1111_0000;
            default     :rm_axis_keep <= 8'b1111_1000;
        endcase
    else if(r_sof_local == 1 && r_eof)   
        case(r_eof_local)
            0           :rm_axis_keep <= 8'b1000_0000;
            1           :rm_axis_keep <= 8'b1100_0000;
            2           :rm_axis_keep <= 8'b1110_0000;
            3           :rm_axis_keep <= 8'b1111_0000;
            4           :rm_axis_keep <= 8'b1111_1000;
            5           :rm_axis_keep <= 8'b1111_1100;
            6           :rm_axis_keep <= 8'b1111_1110;
            7           :rm_axis_keep <= 8'b1111_1111;
            default     :rm_axis_keep <= 8'b1111_1111;
        endcase
    // else if(r_sof_local == 1 && r_eof && r_eof_local >= 4)   
    //     case(r_eof_local)
    //         0           :rm_axis_keep <= 8'b1111_1000;
    //         1           :rm_axis_keep <= 8'b1111_1100;
    //         2           :rm_axis_keep <= 8'b1111_1110;
    //         3           :rm_axis_keep <= 8'b1111_1111;
    //         4           :rm_axis_keep <= 8'b1000_0000;
    //         5           :rm_axis_keep <= 8'b1100_0000;
    //         6           :rm_axis_keep <= 8'b1110_0000;
    //         7           :rm_axis_keep <= 8'b1111_0000;
    //         default     :rm_axis_keep <= 8'b1111_1111;
    //     endcase
    else 
        rm_axis_keep <= 8'b1111_1111;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_last <= 'd0;
    else if(r_sof_local == 0 && w_eof && w_eof_local <= 3 && rm_axis_valid)
        rm_axis_last <= 'd1;
    else if(r_sof_local == 0 && r_eof && r_eof_local >= 4 && rm_axis_valid)
        rm_axis_last <= 'd1;
    else if(r_sof_local == 1 && r_eof && rm_axis_valid)   
        rm_axis_last <= 'd1;
    else 
        rm_axis_last <= 'd0;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        rm_axis_valid <= 'd0;
    else if(rm_axis_valid && rm_axis_last)
        rm_axis_valid <= 'd0;
    else if(r_run && !r_run_1d && r_commoa && r_mac_check)
        rm_axis_valid <= 'd1;
    else 
        rm_axis_valid <= rm_axis_valid;
end     

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_len <= 'd0;
    else if(rm_axis_last)
        r_len <= 'd0;
    else if((r_run && !r_run_1d) || r_len)       
        r_len <= r_len + 1;
    else 
        r_len <= r_len;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_out <= 'd0;
    else if(r_crc_check)
        r_out <= 'd0;
    else if(rm_axis_valid)       
        r_out <= 'd1;
    else    
        r_out <= r_out;
end

endmodule
