
module  pcie3_other_itf (
	input             [1:0]     cfg_flr_in_process,
	output wire       [1:0]     cfg_flr_done,
	input             [5:0]     cfg_vf_flr_in_process,
	output wire       [5:0]     cfg_vf_flr_done,

	input                       user_clk,
	input                       user_reset
);

	reg                       [1:0]     cfg_flr_done_reg0;
	reg                       [5:0]     cfg_vf_flr_done_reg0;
	reg                       [1:0]     cfg_flr_done_reg1;
	reg                       [5:0]     cfg_vf_flr_done_reg1;

	always @(posedge user_clk)
	  begin
	   if (user_reset) begin
		  cfg_flr_done_reg0       <= 2'b0;
		  cfg_vf_flr_done_reg0    <= 6'b0;
		  cfg_flr_done_reg1       <= 2'b0;
		  cfg_vf_flr_done_reg1    <= 6'b0;
		end
	   else begin
		  cfg_flr_done_reg0       <= cfg_flr_in_process;
		  cfg_vf_flr_done_reg0    <= cfg_vf_flr_in_process;
		  cfg_flr_done_reg1       <= cfg_flr_done_reg0;
		  cfg_vf_flr_done_reg1    <= cfg_vf_flr_done_reg0;
		end
	  end

	assign cfg_flr_done[0] = ~cfg_flr_done_reg1[0] && cfg_flr_done_reg0[0]; assign cfg_flr_done[1] = ~cfg_flr_done_reg1[1] && cfg_flr_done_reg0[1];

	assign cfg_vf_flr_done[0] = ~cfg_vf_flr_done_reg1[0] && cfg_vf_flr_done_reg0[0]; assign cfg_vf_flr_done[1] = ~cfg_vf_flr_done_reg1[1] && cfg_vf_flr_done_reg0[1]; assign cfg_vf_flr_done[2] = ~cfg_vf_flr_done_reg1[2] && cfg_vf_flr_done_reg0[2]; assign cfg_vf_flr_done[3] = ~cfg_vf_flr_done_reg1[3] && cfg_vf_flr_done_reg0[3]; assign cfg_vf_flr_done[4] = ~cfg_vf_flr_done_reg1[4] && cfg_vf_flr_done_reg0[4]; assign cfg_vf_flr_done[5] = ~cfg_vf_flr_done_reg1[5] && cfg_vf_flr_done_reg0[5];

endmodule
