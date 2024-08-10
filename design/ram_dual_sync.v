module ram_dual_sync (
	w_clk, r_clk,
	w_en,
	w_data,
	w_addr,
	r_en,
	r_addr,
	r_data
);
	parameter	D_WIDTH = 128;
	parameter	A_WIDTH = 3;
	
	input					w_clk, r_clk;
	input					w_en;
	input	[A_WIDTH-1:0]	w_addr;
	input	[D_WIDTH-1:0]	w_data;
	input					r_en;
	input	[A_WIDTH-1:0]	r_addr;
	output	[D_WIDTH-1:0]	r_data;
	reg		[D_WIDTH-1:0]	r_data;


	reg		[D_WIDTH-1:0] ram [2**A_WIDTH-1:0];
	

	always @(posedge w_clk) begin
		if(w_en)
			ram[w_addr]	<=	w_data;
//		else
//			ram[w_addr]	<= ram[w_addr];
	end
	
	always @(posedge r_clk) begin
		if(r_en)
			r_data	<= ram[r_addr];
		else
			r_data	<= 128'bz;
	end
	
endmodule
