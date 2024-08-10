`timescale 1ns/1ps
`define T_CLK 10

module tb_cc_encrypt;

	// ***** Reg/Wire description *****
	reg					i_clk, i_rstn;
	reg					i_start;
	reg					i_sig_pt;
	
	reg		[255:0]		i_key;
	reg		[95:0]		i_non;
	reg		[511:0]		i_pt;
	reg		[31:0]		i_len_pt;

	wire	[511:0]		o_ct;
	wire				o_done;
	wire				o_sig_pt;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****
	cc_encrypt U_CC_ENCRYPT (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	i_start		),
		.i_sig_pt	(	i_sig_pt	),
		
		.i_key		(	i_key		),
		.i_non		(	i_non		),
		.i_pt		(	i_pt		),
		.i_len_pt	(	i_len_pt	),

		.o_ct		(	o_ct		),
		.o_done		(	o_done		),
		.o_sig_pt	(	o_sig_pt	)
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
	
//	initial begin
//		i_key	= 256'h01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
//		i_non	= 96'h02000000_00000000_00000000;
//		i_len_pt= 32'd375;
//		i_pt	= 512'h696c6275_7020726f_6620726f_74756269_72746e6f_43206568_74207962_20646564_6e65746e_69204654_45492065_6874206f_74206e6f_69737369_6d627573_20796e41;
//		@(posedge o_sig_pt)
//	    #(`T_CLK *2)
//	    	i_sig_pt	= 1'b1;
//			i_pt	= 512'h7320796e_6120646e_61204346_5220726f_20746661_7244ed74_656e7265_746e4920_46544549_206e6120_666f2074_72617020_726f206c_6c612073_61206e6f_69746163;
//	    #(`T_CLK *1)
//	    	i_sig_pt	= 1'b0;
//		@(posedge o_sig_pt)
//	    #(`T_CLK *1)
//	    	i_sig_pt	= 1'b1;
//			i_pt	= 512'h72656469_736e6f63_20736920_79746976_69746361_20465445_49206e61_20666f20_74786574_6e6f6320_65687420_6e696874_69772065_64616d20_746e656d_65746174;
//	    #(`T_CLK *1)
//	    	i_sig_pt	= 1'b0;
//		@(posedge o_sig_pt)
//	    #(`T_CLK *2)
//	    	i_sig_pt	= 1'b1;
//			i_pt	= 512'h6e656d65_74617473_206c6172_6f206564_756c636e_69207374_6e656d65_74617473_20686375_53202e22_6e6f6974_75626972_746e6f43_20465445_4922206e_61206465;
//	    #(`T_CLK *1)
//	    	i_sig_pt	= 1'b0;
//		@(posedge o_sig_pt)
//	    #(`T_CLK *3)
//	    	i_sig_pt	= 1'b1;
//			i_pt	= 512'h6163696e_756d6d6f_63206369_6e6f7274_63656c65_20646e61_206e6574_74697277_20736120_6c6c6577_20736120_2c736e6f_69737365_73204654_4549206e_69207374;
//	    #(`T_CLK *1)
//	    	i_sig_pt	= 1'b0;
//		@(posedge o_sig_pt)
//	    #(`T_CLK *5)
//	    	i_sig_pt	= 1'b1;
//			i_pt	= 512'h00000000_00000000_006f7420_64657373_65726464_61206572_61206863_69687720_2c656361_6c702072_6f20656d_69742079_6e612074_61206564_616d2073_6e6f6974;
//	    #(`T_CLK *1)
//	    	i_sig_pt	= 1'b0;
//	end

	initial begin
		i_key	= 256'h1f1e1d1c_1b1a1918_17161514_13121110_0f0e0d0c_0b0a0908_07060504_03020100;
		i_non	= 96'h00000000_4a000000_00000000;
		i_len_pt= 32'd114;
		i_pt	= 512'h6f20756f_79207265_66666f20_646c756f_63204920_6649203a_39392720_666f2073_73616c63_20656874_20666f20_6e656d65_6c746e65_4720646e_61207365_6964614c;
		@(posedge o_sig_pt)
	    #(`T_CLK *2.2)
	    	i_sig_pt	= 1'b1;
			i_pt	= 512'h6f20756f_79207265_66666f20_646c756f_63204920_6649203a_39392720_666f2073_73616c63_20656874_20666f20_6e656d65_6c746e65_4720646e_61207365_6964614c;
	    #(`T_CLK *1)
	    	i_sig_pt	= 1'b0;
		@(posedge o_sig_pt)
	    #(`T_CLK *2.2)
	    	i_sig_pt	= 1'b1;
			i_pt	= 512'h00000000_00000000_00000000_00002e74_69206562_20646c75_6f77206e_65657263_736e7573_202c6572_75747566_20656874_20726f66_20706974_20656e6f_20796c6e;
	    #(`T_CLK *1)
	    	i_sig_pt	= 1'b0;
	end
	
	initial begin
		i_start		= 1'b0;
		i_sig_pt	= 1'b0;
		
		wait(i_rstn);
		
	    #(`T_CLK *2)
		i_start	= 1'b1;
	    #(`T_CLK *1)
		i_start	= 1'b0;
		
//		#(`T_CLK *12*20*8)
		#(`T_CLK *12*20*4)

		#(`T_CLK *10) $finish;
	end

	always @(posedge i_clk) begin
		if (((U_CC_ENCRYPT.U1_CC_BLOCK.r_fsm == 2'd1) && (U_CC_ENCRYPT.U1_CC_BLOCK.r_cnt_rnd == 5'd0) && (U_CC_ENCRYPT.U1_CC_BLOCK.r_cnt_calc == 4'd0)) || U_CC_ENCRYPT.U1_CC_BLOCK.r_fsm == 2'd2) begin
			$display("< ***** %2d count block ***** >\n", U_CC_ENCRYPT.U1_CC_BLOCK.i_cnt);
			$display("%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n%08h  %08h  %08h  %08h \n", 
			U_CC_ENCRYPT.U1_CC_BLOCK.r_block0,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block1,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block2,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block3,
			U_CC_ENCRYPT.U1_CC_BLOCK.r_block4,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block5,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block6,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block7,
			U_CC_ENCRYPT.U1_CC_BLOCK.r_block8,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block9,  U_CC_ENCRYPT.U1_CC_BLOCK.r_block10, U_CC_ENCRYPT.U1_CC_BLOCK.r_block11,
			U_CC_ENCRYPT.U1_CC_BLOCK.r_block12, U_CC_ENCRYPT.U1_CC_BLOCK.r_block13, U_CC_ENCRYPT.U1_CC_BLOCK.r_block14, U_CC_ENCRYPT.U1_CC_BLOCK.r_block15);
			$display("> ***************************** <\n\n");
		end
		else if (o_sig_pt || o_done) begin
			$display("< ***** %2d ciphertext ***** >\n", U_CC_ENCRYPT.r_cnt);
			$display("%h \n", o_ct);
			$display("> ************************** <\n\n");
		end
	end

endmodule 
