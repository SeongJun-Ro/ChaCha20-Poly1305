`timescale 1ns/1ps
`define T_CLK 10

module tb_ccp_aead;

	// ***** Parameter description *****
	parameter	CC_D_WIDTH = 512;
	parameter	P_D_WIDTH = 128;
	parameter	P_A_WIDTH = 5;

	// ***** Reg/Wire description *****
	reg					i_clk, i_rstn;
	reg					i_start;

	reg					i_en_pt;
	reg		[255:0]		i_key;
	reg		[63:0]		i_iv;
	reg		[31:0]		i_constant;
	reg		[511:0]		i_pt;
	reg		[31:0]		i_len_pt;

	reg					i_en_ad;
	reg		[127:0]		i_ad;
	reg		[63:0]		i_len_ad;

	wire				o_rqst_pt;
	wire				o_rqst_ad;
	wire	[127:0]		o_tag;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****
	ccp_aead #(
		.P_D_WIDTH	(	P_D_WIDTH	),
		.P_A_WIDTH	(	P_A_WIDTH	)
	) U_CCP_AEAD (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	i_start		),
		
		.i_en_pt	(	i_en_pt		),
		.i_key		(	i_key		),
		.i_iv		(	i_iv		),
		.i_constant	(	i_constant	),
		.i_pt		(	i_pt		),
		.i_len_pt	(	i_len_pt	),

		.i_en_ad	(	i_en_ad		),
		.i_ad		(	i_ad		),
		.i_len_ad	(	i_len_ad	),
//
		.o_rqst_pt	(	o_rqst_pt	),
		.o_rqst_ad	(	o_rqst_ad	),
		
		.o_done		(	o_done		),
		.o_tag		(	o_tag		)
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

	//------------------------------------------------------------------------//
	// *** test_vector-1 ***

	// ***** File Input/Output *****
	reg [CC_D_WIDTH-1:0] pt [0:1];
	reg [255:0] key [0:0];
	reg [63:0] iv [0:0];
	reg [31:0] constant [0:0];
	reg [P_D_WIDTH-1:0] ad [0:0];

	initial $readmemh("./test_vector/pt1.txt", pt);
	initial $readmemh("./test_vector/key1.txt", key);
	initial $readmemh("./test_vector/iv1.txt", iv);
	initial $readmemh("./test_vector/constant1.txt", constant);
	initial $readmemh("./test_vector/ad1.txt", ad);

	// Specify the user define stimulus
	initial begin
		i_start		= 1'b0;
		i_key		= key[0];
		i_iv		= iv[0];
		i_constant	= constant[0];

		wait(i_rstn);

	    #(`T_CLK *2)
			i_start	= 1'b1;
	    #(`T_CLK *1)
			i_start	= 1'b0;

//		wait(o_done);
		#(`T_CLK *1000) $finish;
	end

	// ChaCha20
	initial begin
		i_en_pt		= 1'b0;
		i_len_pt	= 32'd114;
		i_pt		= pt[0];

		@(posedge o_rqst_pt)

	    #(`T_CLK *2.2)
	    	i_en_pt	= 1'b1;
			i_pt	= pt[1];
	    #(`T_CLK *1)
	    	i_en_pt	= 1'b0;
	end

	// Poly1305
	initial begin
		i_en_ad	= 1'b0;
		i_len_ad	= 64'd12;
		i_ad		= ad[0];

//		@(posedge o_rqst_pt)
//	    #(`T_CLK *2.2)
//	    	i_en_pt	= 1'b1;
//			i_pt	= pt[1];
//	    #(`T_CLK *1)
//	    	i_en_pt	= 1'b0;
	end
	//------------------------------------------------------------------------//

endmodule 
