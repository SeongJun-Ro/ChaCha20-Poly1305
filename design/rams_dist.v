/*
 * https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Block-RAM-Read/Write-Synchronization-Modes
 * retrieved on Sep. 24, 2024
 *
 * Dual-Port RAM with Asynchronous Read (Distributed RAM)
 * File: rams_dist.v
 */

module rams_dist #(
	parameter	D_WIDTH	= 128,
	parameter	A_WIDTH	= 3
)(
	input						clk,
	input						we,
	input		[A_WIDTH-1:0]	a,
	input		[A_WIDTH-1:0]	dpra,
	input		[D_WIDTH-1:0]	di,
	output		[D_WIDTH-1:0]	spo,
	output		[D_WIDTH-1:0]	dpra
);

	reg		[D_WIDTH-1:0] ram [0:2**A_WIDTH-1];
	
	always @(posedge clk) begin
		if (we)
			ram[a] <= di;
	end
	
	assign spo = ram[a];
	assign dpo = ram[dpra];

endmodule


/*
module rams_dist (clk, we, a, dpra, di, spo, dpo);

input clk;
input we;
input [5:0] a;
input [5:0] dpra;
input [15:0] di;
output [15:0] spo;
output [15:0] dpo;
reg [15:0] ram [63:0];

always @(posedge clk)
begin
if (we)
ram[a] <= di;
end

assign spo = ram[a];
assign dpo = ram[dpra];

endmodule
*/
