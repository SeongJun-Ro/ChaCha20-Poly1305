`timescale 1ns/1ps
`define T_CLK 10

module tb_ccp_aead;

	// ***** Parameter description *****
	parameter	CC_D_WIDTH = 512;
	parameter	P_D_WIDTH = 128;
	parameter	P_A_WIDTH = 3;

	// ***** Reg/Wire description *****
	reg					i_clk, i_rstn;
	reg					i_start;

	reg					i_enc_dec;
	reg		[127:0]		i_tag;

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
	wire				o_authen;
	wire				o_done;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****
	ccp_aead #(
		.P_D_WIDTH	(	P_D_WIDTH	),
		.P_A_WIDTH	(	P_A_WIDTH	)
	) U_CCP_AEAD (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	i_start		),
		
		.i_enc_dec	(	i_enc_dec	),
		.i_tag		(	i_tag		),
		
		.i_en_pt	(	i_en_pt		),
		.i_key		(	i_key		),
		.i_iv		(	i_iv		),
		.i_constant	(	i_constant	),
		.i_pt		(	i_pt		),
		.i_len_pt	(	i_len_pt	),

		.i_en_ad	(	i_en_ad		),
		.i_ad		(	i_ad		),
		.i_len_ad	(	i_len_ad	),

		.o_rqst_pt	(	o_rqst_pt	),
		.o_rqst_ad	(	o_rqst_ad	),
		
		.o_done		(	o_done		),
		.o_tag		(	o_tag		),
		.o_authen	(	o_authen	)
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

//	//------------------------------------------------------------------------//
//	// *** test_vector-(1) Encrypt ***
//
//	// ***** File Input/Output *****
//	reg [CC_D_WIDTH-1:0] pt [0:1];
//	reg [255:0] key [0:0];
//	reg [63:0] iv [0:0];
//	reg [31:0] constant [0:0];
//	reg [P_D_WIDTH-1:0] ad [0:0];
//
//	initial $readmemh("./test_vector/pt1.txt", pt);
//	initial $readmemh("./test_vector/key1.txt", key);
//	initial $readmemh("./test_vector/iv1.txt", iv);
//	initial $readmemh("./test_vector/constant1.txt", constant);
//	initial $readmemh("./test_vector/ad1.txt", ad);
//
//	// Specify the user define stimulus
//	initial begin
//		i_enc_dec	= 1'b1;
//		i_tag		= 128'd0;
//	
//		i_start		= 1'b0;
//		i_key		= key[0];
//		i_iv		= iv[0];
//		i_constant	= constant[0];
//
//		wait(i_rstn);
//
//	    #(`T_CLK *2)
//			i_start	= 1'b1;
//	    #(`T_CLK *1)
//			i_start	= 1'b0;
//
////		wait(o_done);
//		#(`T_CLK *1000) $finish;
//	end
//
//	// ChaCha20
//	initial begin
//		i_en_pt		= 1'b0;
//		i_len_pt	= 32'd114;
//		i_pt		= pt[0];
//
//		@(posedge o_rqst_pt)
//
//	    #(`T_CLK *2.2)
//	    	i_en_pt	= 1'b1;
//			i_pt	= pt[1];
//	    #(`T_CLK *1)
//	    	i_en_pt	= 1'b0;
//	end
//
//	// Poly1305
//	initial begin
//		i_en_ad	= 1'b0;
//		i_len_ad	= 64'd12;
//		i_ad		= ad[0];
//
////		@(posedge o_rqst_pt)
////	    #(`T_CLK *2.2)
////	    	i_en_pt	= 1'b1;
////			i_pt	= pt[1];
////	    #(`T_CLK *1)
////	    	i_en_pt	= 1'b0;
//	end
//	//------------------------------------------------------------------------//
	// *** test_vector-(2) Decrypt ***

	// ***** File Input/Output *****
	reg [CC_D_WIDTH-1:0] pt [0:4];
	reg [255:0] key [0:0];
	reg [63:0] iv [0:0];
	reg [31:0] constant [0:0];
	reg [P_D_WIDTH-1:0] ad [0:17];

	initial $readmemh("./test_vector/pt2.txt", pt);
	initial $readmemh("./test_vector/key2.txt", key);
	initial $readmemh("./test_vector/iv2.txt", iv);
	initial $readmemh("./test_vector/constant2.txt", constant);
	initial $readmemh("./test_vector/ad2.txt", ad);

	// Specify the user define stimulus
	initial begin
		i_enc_dec	= 1'b0;
		i_tag		= 128'h381f85a1_fe362339_22bb0c89_679dadee;
	
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
		#(`T_CLK *1500) $finish;
	end

	// ChaCha20
	integer c;
	initial begin
		i_en_pt		= 1'b0;
		i_len_pt	= 32'd265;
		i_pt		= pt[0];

		for (c=1;c<5;c=c+1) begin
			@(posedge o_rqst_pt)
		    #(`T_CLK *2.2)
		    	i_en_pt	= 1'b1;
				i_pt	= pt[c];
		    #(`T_CLK *1)
		    	i_en_pt	= 1'b0;
		end
		
	end

	// Poly1305
	integer p;
	initial begin
		i_en_ad	= 1'b0;
		i_len_ad	= 64'd12;
		i_ad		= ad[0];

		for (p=1;p<18;p=p+1) begin
			@(posedge o_rqst_ad)
		    #(`T_CLK *2.2)
		    	i_en_ad	= 1'b1;
				i_ad	= ad[p];
		    #(`T_CLK *1)
		    	i_en_ad	= 1'b0;
		end
	end
	//------------------------------------------------------------------------//


	// print U_CCP_AEAD.U_P_TAG. 'r_acml' and 'r_a' state
	task print;
		begin
			$display("r_acml [63:32] : %08h %08h %08h %08h %08h %08h %08h %08h", 
					U_CCP_AEAD.U_P_TAG.r_acml7[63:32], U_CCP_AEAD.U_P_TAG.r_acml6[63:32], U_CCP_AEAD.U_P_TAG.r_acml5[63:32], U_CCP_AEAD.U_P_TAG.r_acml4[63:32], 
					U_CCP_AEAD.U_P_TAG.r_acml3[63:32], U_CCP_AEAD.U_P_TAG.r_acml2[63:32], U_CCP_AEAD.U_P_TAG.r_acml1[63:32], U_CCP_AEAD.U_P_TAG.r_acml0[63:32]);
			$display("r_acml [31:0]  : %08h %08h %08h %08h %08h %08h %08h %08h", 
					U_CCP_AEAD.U_P_TAG.r_acml7[31:0], U_CCP_AEAD.U_P_TAG.r_acml6[31:0], U_CCP_AEAD.U_P_TAG.r_acml5[31:0], U_CCP_AEAD.U_P_TAG.r_acml4[31:0], 
					U_CCP_AEAD.U_P_TAG.r_acml3[31:0], U_CCP_AEAD.U_P_TAG.r_acml2[31:0], U_CCP_AEAD.U_P_TAG.r_acml1[31:0], U_CCP_AEAD.U_P_TAG.r_acml0[31:0]);
			$display("r_a    [31:0]  :\t\t\t    %08h %08h %08h %08h %08h", 
					U_CCP_AEAD.U_P_TAG.r_a4, U_CCP_AEAD.U_P_TAG.r_a3, U_CCP_AEAD.U_P_TAG.r_a2, U_CCP_AEAD.U_P_TAG.r_a1, U_CCP_AEAD.U_P_TAG.r_a0);
		end
	endtask

	always @(posedge i_clk) begin
		if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd1&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("\n***** i_start ***** {\n");
			$display("msg_len : %3d \n", U_CCP_AEAD.U_P_TAG.r_len_msg);
			$display("msg   : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.r_msg[127:96], U_CCP_AEAD.U_P_TAG.r_msg[95:64], U_CCP_AEAD.U_P_TAG.r_msg[63:32], U_CCP_AEAD.U_P_TAG.r_msg[31:0]);
			$display("key_r : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.w_key_r3, U_CCP_AEAD.U_P_TAG.w_key_r2, U_CCP_AEAD.U_P_TAG.w_key_r1, U_CCP_AEAD.U_P_TAG.w_key_r0);
			$display("key_s : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.w_key_s3, U_CCP_AEAD.U_P_TAG.w_key_s2, U_CCP_AEAD.U_P_TAG.w_key_s1, U_CCP_AEAD.U_P_TAG.w_key_s0);
			$display("\n******************* }\n\n");
		end


		//////////////////// ADD state simulation ////////////////////

		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd1&&U_CCP_AEAD.U_P_TAG.r_cnt=='d1) begin
			if(U_CCP_AEAD.U_P_TAG.r_cnt=='d1) begin
				$display("***** ADD1 state ***** {\n");
				$display("r_cnt : %02d / acml = acml + msg", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d5) begin
				$display("r_cnt : %02d / carry add", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd2&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 05 / a = acml[31:0]");
			print();
			$display();
			$display("********************** }\n\n");
		end


		//////////////////// MUL state simulation ////////////////////

		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd2) begin
			if(U_CCP_AEAD.U_P_TAG.r_cnt=='d1) begin
				$display("***** MUL state ***** {\n");
				$display("r_cnt : %02d / acml = a * r", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d8) begin
				$display("r_cnt : %02d / carry add", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd3&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 08 / mask: a <-130bit-> acml");
			print();
			$display();
			$display("********************** }\n\n");
		end
		
		
		//////////////////// MOD1 state simulation ////////////////////

		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd3) begin
			if(U_CCP_AEAD.U_P_TAG.r_cnt=='d1) begin
				$display("***** MOD1 state ***** {\n");
				$display("r_cnt : %02d / acml = acml + a", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d2) begin
				$display("r_cnt : %02d / acmln = acmln + {a(n+1)[1:0],an[31:2]}", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d6) begin
				$display("r_cnt : %02d / carry add", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d7) begin
				$display("r_cnt : %02d / mask a <-130-> acml", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d8) begin
				$display("r_cnt : %02d / acml0 = acml0 + a0", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d9) begin
				$display("r_cnt : %02d / acml0 = acml0 + {2'b0,an[31:2]}", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d13) begin
				$display("r_cnt : %02d / carry add", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd4&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 13 / mask 130-> acml");
			print();
			$display();
			$display("********************** }\n\n");
		end


		//////////////////// MOD2 state simulation ////////////////////
		
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd4&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("\n***** WAIT state ***** {\n");
			$display("msg_len : %3d \n", U_CCP_AEAD.U_P_TAG.r_len_msg);
			$display("msg   : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.r_msg[127:96], U_CCP_AEAD.U_P_TAG.r_msg[95:64], U_CCP_AEAD.U_P_TAG.r_msg[63:32], U_CCP_AEAD.U_P_TAG.r_msg[31:0]);
			$display("key_r : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.w_key_r3, U_CCP_AEAD.U_P_TAG.w_key_r2, U_CCP_AEAD.U_P_TAG.w_key_r1, U_CCP_AEAD.U_P_TAG.w_key_r0);
			$display("key_s : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.w_key_s3, U_CCP_AEAD.U_P_TAG.w_key_s2, U_CCP_AEAD.U_P_TAG.w_key_s1, U_CCP_AEAD.U_P_TAG.w_key_s0);
			$display("\n******************* }\n\n");
		end
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd5&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("\n***** WAIT state ***** {\n");
			$display("msg_len : %3d \n", U_CCP_AEAD.U_P_TAG.r_len_msg);
			$display("msg   : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.r_msg[127:96], U_CCP_AEAD.U_P_TAG.r_msg[95:64], U_CCP_AEAD.U_P_TAG.r_msg[63:32], U_CCP_AEAD.U_P_TAG.r_msg[31:0]);
			$display("key_r : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.w_key_r3, U_CCP_AEAD.U_P_TAG.w_key_r2, U_CCP_AEAD.U_P_TAG.w_key_r1, U_CCP_AEAD.U_P_TAG.w_key_r0);
			$display("key_s : %08h %08h %08h %08h", U_CCP_AEAD.U_P_TAG.w_key_s3, U_CCP_AEAD.U_P_TAG.w_key_s2, U_CCP_AEAD.U_P_TAG.w_key_s1, U_CCP_AEAD.U_P_TAG.w_key_s0);
			$display("\n******************* }\n\n");
		end


		//////////////////// MOD2 state simulation ////////////////////

		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd5) begin
			if(U_CCP_AEAD.U_P_TAG.r_cnt=='d1) begin
				$display("***** MOD2 state ***** {\n");
				$display("r_cnt : %02d / acml = acml+5", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_CCP_AEAD.U_P_TAG.r_cnt=='d5) begin
				$display("r_cnt : %02d / =", U_CCP_AEAD.U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd6&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 05 / if (a + 5) >= 2^130 ...");
			print();
			$display();
			$display("********************** }\n\n");
		end


		//////////////////// ADD2 state simulation ////////////////////

		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd6&&U_CCP_AEAD.U_P_TAG.r_cnt=='d1) begin
			$display("***** ADD2 state ***** {\n");
			$display("r_cnt : %02d / acml = acml+s", U_CCP_AEAD.U_P_TAG.r_cnt-1);
			print();
			$display();
		end
		else if(U_CCP_AEAD.U_P_TAG.r_fsm==3'd7&&U_CCP_AEAD.U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 02 / carry add");
			print();
//			$display("\n********************** }\n\n");
//			$display("%d \n %d", U_CCP_AEAD.U_P_TAG.w_p, U_CCP_AEAD.U_P_TAG.r_mod);
//			$display("%x \n %x", U_CCP_AEAD.U_P_TAG.w_p, U_CCP_AEAD.U_P_TAG.r_mod);
////			28d31b7caff946c77c8844335369d03a7
////			3fffffffffffffffffffffffffffffffb
		end
	end



endmodule 
