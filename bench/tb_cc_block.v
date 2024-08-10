`timescale 1ns/1ps
`define T_CLK 10

module tb_cc_block;

	// ***** Reg/Wire description *****
	reg				i_clk, i_rstn;
	reg				i_start;
	
	reg		[255:0]	i_key;
	reg		[95:0]	i_non;
	reg		[31:0]	i_cnt;
	
	wire	[511:0]	o_stream;
	wire			o_done;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****
	cc_block U0_CC_BLOCK (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	i_start		),
		
		.i_key		(	i_key		),
		.i_non		(	i_non		),
		.i_cnt		(	i_cnt		),
		
		.o_stream	(	o_stream	),
		.o_done		(	o_done		)
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
		i_start	= 1'b0;
		i_key	= 256'h1f1e1d1c_1b1a1918_17161514_13121110_0f0e0d0c_0b0a0908_07060504_03020100;
		i_cnt	= 32'd1;
		i_non	= 96'h00000000_4a000000_09000000;

		wait(i_rstn);
		
		#(`T_CLK *3)
			i_start = 1'b1;
		#(`T_CLK *1)
			i_start = 1'b0;
			
		#(`T_CLK *1)
		#(`T_CLK *12*20*2)

		#(`T_CLK *10) $finish;
	end

	always @(posedge i_clk) begin
		if ((U0_CC_BLOCK.r_fsm == 2'd1) && (U0_CC_BLOCK.r_cnt_rnd == 5'd0) && (U0_CC_BLOCK.r_cnt_calc == 4'd0)) begin
			$display("\n< ***** r_block init state ***** >\n");
			$display("%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n", 
			U0_CC_BLOCK.r_block0,  U0_CC_BLOCK.r_block1,  U0_CC_BLOCK.r_block2,  U0_CC_BLOCK.r_block3,
			U0_CC_BLOCK.r_block4,  U0_CC_BLOCK.r_block5,  U0_CC_BLOCK.r_block6,  U0_CC_BLOCK.r_block7,
			U0_CC_BLOCK.r_block8,  U0_CC_BLOCK.r_block9,  U0_CC_BLOCK.r_block10, U0_CC_BLOCK.r_block11,
			U0_CC_BLOCK.r_block12, U0_CC_BLOCK.r_block13, U0_CC_BLOCK.r_block14, U0_CC_BLOCK.r_block15);
			$display("> ****************************** <\n");
		end

		else if (U0_CC_BLOCK.r_fsm == 2'd3) begin
			$display("< ***** after 20 round ***** >\n");
			$display("%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n", 
			U0_CC_BLOCK.r_block0,  U0_CC_BLOCK.r_block1,  U0_CC_BLOCK.r_block2,  U0_CC_BLOCK.r_block3,
			U0_CC_BLOCK.r_block4,  U0_CC_BLOCK.r_block5,  U0_CC_BLOCK.r_block6,  U0_CC_BLOCK.r_block7,
			U0_CC_BLOCK.r_block8,  U0_CC_BLOCK.r_block9,  U0_CC_BLOCK.r_block10, U0_CC_BLOCK.r_block11,
			U0_CC_BLOCK.r_block12, U0_CC_BLOCK.r_block13, U0_CC_BLOCK.r_block14, U0_CC_BLOCK.r_block15);
			$display("> ****************************** <\n");
		end
		
		else if (U0_CC_BLOCK.r_fsm == 2'd2) begin
			$display("< ***** after add ***** >\n");
			$display("%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n", 
			U0_CC_BLOCK.r_block0,  U0_CC_BLOCK.r_block1,  U0_CC_BLOCK.r_block2,  U0_CC_BLOCK.r_block3,
			U0_CC_BLOCK.r_block4,  U0_CC_BLOCK.r_block5,  U0_CC_BLOCK.r_block6,  U0_CC_BLOCK.r_block7,
			U0_CC_BLOCK.r_block8,  U0_CC_BLOCK.r_block9,  U0_CC_BLOCK.r_block10, U0_CC_BLOCK.r_block11,
			U0_CC_BLOCK.r_block12, U0_CC_BLOCK.r_block13, U0_CC_BLOCK.r_block14, U0_CC_BLOCK.r_block15);
			$display("> ****************************** <\n");
		end
	end

endmodule
