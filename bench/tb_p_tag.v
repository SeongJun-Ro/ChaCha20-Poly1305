`timescale 1ns/1ps
`define T_CLK 10

module tb_p_tag;

	// ***** Reg/Wire description *****
	reg					i_clk, i_rstn;
	reg					i_start;
	
	reg					i_sig_msg;
	reg		[255:0]		i_key;
	reg		[127:0]		i_msg;
	reg		[31:0]		i_len_msg;

	wire				o_sig_msg;
	wire	[127:0]		o_tag;
	wire				o_done;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****
	p_tag U_P_TAG (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	i_start		),
		.i_sig_msg	(	i_sig_msg	),
		
		.i_key		(	i_key		),
		.i_msg		(	i_msg		),
		.i_len_msg	(	i_len_msg	),

		.o_sig_msg	(	o_sig_msg	),
		.o_tag		(	o_tag		),
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
		i_key	= 256'h1bf54941_aff6bf4a_fdb20dfb_8a800301_a806d542_fe52447f_336d5557_78bed685;
		i_len_msg= 32'd34;
		i_msg	= 127'h6f462063_69687061_72676f74_70797243;
		@(posedge o_sig_msg)
	    #(`T_CLK *5.2)
	    	i_sig_msg	= 1'b1;
			i_msg	= 127'h6f724720_68637261_65736552_206d7572;
	    #(`T_CLK *1)
	    	i_sig_msg	= 1'b0;
		@(posedge o_sig_msg)
	    #(`T_CLK *2.2)
	    	i_sig_msg	= 1'b1;
			i_msg	= 127'h00000000_00000000_00000000_00007075;
	    #(`T_CLK *1)
	    	i_sig_msg	= 1'b0;
	end
	
	initial begin
		i_start		= 1'b0;
		i_sig_msg	= 1'b0;
		
		wait(i_rstn);
		
	    #(`T_CLK *2)
		i_start	= 1'b1;
	    #(`T_CLK *1)
		i_start	= 1'b0;
		
		#(`T_CLK *150)

		#(`T_CLK *10) $finish;
	end


	// print U_P_TAG. 'r_acml' and 'r_a' state
	task print;
		begin
			$display("r_acml [63:32] : %08h %08h %08h %08h %08h %08h %08h %08h", 
					U_P_TAG.r_acml7[63:32], U_P_TAG.r_acml6[63:32], U_P_TAG.r_acml5[63:32], U_P_TAG.r_acml4[63:32], 
					U_P_TAG.r_acml3[63:32], U_P_TAG.r_acml2[63:32], U_P_TAG.r_acml1[63:32], U_P_TAG.r_acml0[63:32]);
			$display("r_acml [31:0]  : %08h %08h %08h %08h %08h %08h %08h %08h", 
					U_P_TAG.r_acml7[31:0], U_P_TAG.r_acml6[31:0], U_P_TAG.r_acml5[31:0], U_P_TAG.r_acml4[31:0], 
					U_P_TAG.r_acml3[31:0], U_P_TAG.r_acml2[31:0], U_P_TAG.r_acml1[31:0], U_P_TAG.r_acml0[31:0]);
			$display("r_a    [31:0]  :\t\t\t    %08h %08h %08h %08h %08h", 
					U_P_TAG.r_a4, U_P_TAG.r_a3, U_P_TAG.r_a2, U_P_TAG.r_a1, U_P_TAG.r_a0);
		end
	endtask

	always @(posedge i_clk) begin
		if(U_P_TAG.r_fsm==3'd1&&U_P_TAG.r_cnt=='d0) begin
			$display("\n***** i_start ***** {\n");
			$display("msg_len : %3d \n", U_P_TAG.r_len_msg);
			$display("msg   : %08h %08h %08h %08h", U_P_TAG.r_msg[127:96], U_P_TAG.r_msg[95:64], U_P_TAG.r_msg[63:32], U_P_TAG.r_msg[31:0]);
			$display("key_r : %08h %08h %08h %08h", U_P_TAG.w_key_r3, U_P_TAG.w_key_r2, U_P_TAG.w_key_r1, U_P_TAG.w_key_r0);
			$display("key_s : %08h %08h %08h %08h", U_P_TAG.w_key_s3, U_P_TAG.w_key_s2, U_P_TAG.w_key_s1, U_P_TAG.w_key_s0);
			$display("\n******************* }\n\n");
		end


		//////////////////// ADD state simulation ////////////////////

		else if(U_P_TAG.r_fsm==3'd1&&U_P_TAG.r_cnt=='d1) begin
			if(U_P_TAG.r_cnt=='d1) begin
				$display("***** ADD1 state ***** {\n");
				$display("r_cnt : %02d / acml = acml + msg", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d5) begin
				$display("r_cnt : %02d / carry add", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_P_TAG.r_fsm==3'd2&&U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 05 / a = acml[31:0]");
			print();
			$display();
			$display("********************** }\n\n");
		end


		//////////////////// MUL state simulation ////////////////////

		else if(U_P_TAG.r_fsm==3'd2) begin
			if(U_P_TAG.r_cnt=='d1) begin
				$display("***** MUL state ***** {\n");
				$display("r_cnt : %02d / acml = a * r", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d8) begin
				$display("r_cnt : %02d / carry add", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_P_TAG.r_fsm==3'd3&&U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 08 / mask: a <-130bit-> acml");
			print();
			$display();
			$display("********************** }\n\n");
		end
		
		
		//////////////////// MOD1 state simulation ////////////////////

		else if(U_P_TAG.r_fsm==3'd3) begin
			if(U_P_TAG.r_cnt=='d1) begin
				$display("***** MOD1 state ***** {\n");
				$display("r_cnt : %02d / acml = acml + a", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d2) begin
				$display("r_cnt : %02d / acmln = acmln + {a(n+1)[1:0],an[31:2]}", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d6) begin
				$display("r_cnt : %02d / carry add", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d7) begin
				$display("r_cnt : %02d / mask a <-130-> acml", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d8) begin
				$display("r_cnt : %02d / acml0 = acml0 + a0", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d9) begin
				$display("r_cnt : %02d / acml0 = acml0 + {2'b0,an[31:2]}", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d13) begin
				$display("r_cnt : %02d / carry add", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_P_TAG.r_fsm==3'd4&&U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 13 / mask 130-> acml");
			print();
			$display();
			$display("********************** }\n\n");
		end


		//////////////////// MOD2 state simulation ////////////////////
		
		else if(U_P_TAG.r_fsm==3'd4&&U_P_TAG.r_cnt=='d0) begin
			$display("\n***** WAIT state ***** {\n");
			$display("msg_len : %3d \n", U_P_TAG.r_len_msg);
			$display("msg   : %08h %08h %08h %08h", U_P_TAG.r_msg[127:96], U_P_TAG.r_msg[95:64], U_P_TAG.r_msg[63:32], U_P_TAG.r_msg[31:0]);
			$display("key_r : %08h %08h %08h %08h", U_P_TAG.w_key_r3, U_P_TAG.w_key_r2, U_P_TAG.w_key_r1, U_P_TAG.w_key_r0);
			$display("key_s : %08h %08h %08h %08h", U_P_TAG.w_key_s3, U_P_TAG.w_key_s2, U_P_TAG.w_key_s1, U_P_TAG.w_key_s0);
			$display("\n******************* }\n\n");
		end
		else if(U_P_TAG.r_fsm==3'd5&&U_P_TAG.r_cnt=='d0) begin
			$display("\n***** WAIT state ***** {\n");
			$display("msg_len : %3d \n", U_P_TAG.r_len_msg);
			$display("msg   : %08h %08h %08h %08h", U_P_TAG.r_msg[127:96], U_P_TAG.r_msg[95:64], U_P_TAG.r_msg[63:32], U_P_TAG.r_msg[31:0]);
			$display("key_r : %08h %08h %08h %08h", U_P_TAG.w_key_r3, U_P_TAG.w_key_r2, U_P_TAG.w_key_r1, U_P_TAG.w_key_r0);
			$display("key_s : %08h %08h %08h %08h", U_P_TAG.w_key_s3, U_P_TAG.w_key_s2, U_P_TAG.w_key_s1, U_P_TAG.w_key_s0);
			$display("\n******************* }\n\n");
		end


		//////////////////// MOD2 state simulation ////////////////////

		else if(U_P_TAG.r_fsm==3'd5) begin
			if(U_P_TAG.r_cnt=='d1) begin
				$display("***** MOD2 state ***** {\n");
				$display("r_cnt : %02d / acml = acml+5", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
			else if(U_P_TAG.r_cnt=='d5) begin
				$display("r_cnt : %02d / =", U_P_TAG.r_cnt-1);
				print();
				$display();
			end
		end
		else if(U_P_TAG.r_fsm==3'd6&&U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 05 / if (a + 5) >= 2^130 ...");
			print();
			$display();
			$display("********************** }\n\n");
		end


		//////////////////// ADD2 state simulation ////////////////////

		else if(U_P_TAG.r_fsm==3'd6&&U_P_TAG.r_cnt=='d1) begin
			$display("***** ADD2 state ***** {\n");
			$display("r_cnt : %02d / acml = acml+s", U_P_TAG.r_cnt-1);
			print();
			$display();
		end
		else if(U_P_TAG.r_fsm==3'd7&&U_P_TAG.r_cnt=='d0) begin
			$display("r_cnt : 02 / carry add");
			print();
			$display("\n********************** }\n\n");
			$display("%d \n %d", U_P_TAG.w_p, U_P_TAG.r_mod);
			$display("%x \n %x", U_P_TAG.w_p, U_P_TAG.r_mod);
//			28d31b7caff946c77c8844335369d03a7
//			3fffffffffffffffffffffffffffffffb
		end
	end

endmodule 
