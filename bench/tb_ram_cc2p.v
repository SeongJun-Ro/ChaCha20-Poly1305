`timescale 1ns/1ps
`define T_CLK 10
`define TEST

module tb_ram_cc2p;

	// ***** Parameter description *****
	parameter	P_D_WIDTH	= 128;
`ifdef TEST
	parameter	P_A_WIDTH	= 3;
`else
	parameter	P_A_WIDTH	= 16;
`endif

	// ***** Reg/Wire description *****
	reg					i_clk;
	reg					i_rstn;
	reg					i_en_w;
	reg					i_en_r;
	reg		[511:0]		i_data;

	wire	[127:0]		o_data;
	wire				o_sig;
	wire				o_full;
	wire				o_empty;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****

	ram_cc2p #(
		.D_WIDTH	(	P_D_WIDTH	),
		.A_WIDTH	(	P_A_WIDTH	)
	) U_RAM_CC2P (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_en_w		(	i_en_w		),
		.i_en_r		(	i_en_r		),
		.i_data		(	i_data		),

		.o_data		(	o_data		),
		.o_sig		(	o_sig		),
		.o_full		(	o_full		),
		.o_empty	(	o_empty		)
	);

////////////////////////////////////////////////////////////////////////////////

	// ***** Dump wave infomation to VCD file *****
	`ifdef VCD
	initial begin
		$dumpfile("wave.vcd");
	end
	initial begin
		$dumpvars(0);
	end
	`endif

	// ***** Clock Generation *****
	initial begin
	    i_clk	= 1'b1;
	    i_rstn	= 1'b0;
	    #(`T_CLK *2.2) i_rstn = 1'b1;
	end
	always #(`T_CLK/2) i_clk = ~i_clk;

	// Specify the user define stimulus
	initial begin
		i_en_w = 1'd0;
		i_en_r = 1'd0;
		i_data = 512'd0;

		wait(i_rstn);

		#(`T_CLK *1)
			i_data = 512'h3333_3333_3333_3333_3333_3333_3333_3333__2222_2222_2222_2222_2222_2222_2222_2222_1111_1111_1111_1111_1111_1111_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000;
			i_en_w = 1'h1;
		#(`T_CLK *1)
			i_en_w = 1'h0;
		#(`T_CLK *4)

		#(`T_CLK *1)
			i_en_r = 1'h1;
		#(`T_CLK *1)
			i_en_r = 1'h0;
		#(`T_CLK *1)
			i_en_r = 1'h1;
		#(`T_CLK *1)
			i_en_r = 1'h0;
		#(`T_CLK *1)
			i_en_r = 1'h1;
		#(`T_CLK *1)
			i_en_r = 1'h0;
		#(`T_CLK *1)
			i_en_r = 1'h1;
		#(`T_CLK *1)
			i_en_r = 1'h0;
		#(`T_CLK *1)
			i_en_r = 1'h1;
		#(`T_CLK *1)
			i_en_r = 1'h0;

		#(`T_CLK *6)
			i_data = 512'h7777_7777_7777_7777_7777_7777_7777_7777_6666_6666_6666_6666_6666_6666_6666_6666_5555_5555_5555_5555_5555_5555_5555_5555_4444_4444_4444_4444_4444_4444_4444_4444;
			i_en_w = 1'h1;
		#(`T_CLK *1)
			i_en_w = 1'h0;

		#(`T_CLK *100) $finish;
	end

endmodule
