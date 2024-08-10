module p_tag (
	input					i_clk, i_rstn,
	input					i_start,
	
	input					i_sig_msg,
	input		[255:0]		i_key,
	input		[127:0]		i_msg,
	input		[31:0]		i_len_msg,

	output	reg				o_sig_msg,
	output	reg	[127:0]		o_tag,
	output	wire			o_done
);

	// ***** local parameter definition *****
	parameter IDLE	= 3'd0;
	parameter ADD1	= 3'd1;
	parameter MUL	= 3'd2;
	parameter MOD1	= 3'd3;
	parameter WAIT	= 3'd4;
	parameter MOD2	= 3'd5;
	parameter ADD2	= 3'd6;
	parameter DONE	= 3'd7;

	parameter CLAMP 	= 128'h0ffffffc_0ffffffc_0ffffffc_0fffffff;
	parameter CONCAT	= 134'h00_00000000_00000000_00000000_00000001;

	// ***** local register definition *****
	reg		[2:0]	r_fsm;
	reg		[31:0]	r_cnt;
	reg		[127:0]	r_key_r, r_key_s;
	reg		[127:0]	r_msg;
	reg		[31:0]	r_len_msg;

	reg		[64:0]	r_acml0, r_acml1, r_acml2, r_acml3, r_acml4, r_acml5, r_acml6;
	reg		[63:0]	r_acml7;
	reg		[32:0]	r_a0, r_a1, r_a2, r_a3, r_a4;

	// ***** local wire definition *****
	wire	[31:0]	w_key_r0, w_key_r1, w_key_r2, w_key_r3;
	wire	[31:0]	w_key_s0, w_key_s1, w_key_s2, w_key_s3;
	wire	[135:0]	w_msg_exp;
	
	wire			w_msg_state;	// 1: have to BLOCK state
	wire			w_msg_start;	// 1: start BLOCK state
//	wire			w_blk_done;		// 1: finish BLOCK state
//	wire	[511:0]	w_mask;
	
	
	assign	w_key_r0	= r_key_r[31:0];
	assign	w_key_r1	= r_key_r[63:32];
	assign	w_key_r2	= r_key_r[95:64];
	assign	w_key_r3	= r_key_r[127:96];
	assign	w_key_s0	= r_key_s[31:0];
	assign	w_key_s1	= r_key_s[63:32];
	assign	w_key_s2	= r_key_s[95:64];
	assign	w_key_s3	= r_key_s[127:96];
	
	assign	w_msg_exp	= (r_len_msg<32'd16) ? (1'b1 << {r_len_msg,3'd0}) + r_msg 
												: {8'h01,r_msg};
	
	assign	w_msg_state	= r_len_msg!=32'd0;
	assign	w_msg_start	= ((r_fsm == WAIT) && (i_sig_msg));
	
	assign	o_done		= (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_fsm	<= IDLE;
		else
			case (r_fsm)
				IDLE	: r_fsm <=	(i_start)		? ADD1	: IDLE;
				ADD1	: r_fsm <=	(r_cnt=='d2)	? MUL	: ADD1;
				MUL		: r_fsm <=	(r_cnt=='d2)	? MOD1	: MUL;
				MOD1	: r_fsm <=	(r_cnt=='d7)	? WAIT	: MOD1;
				WAIT	: r_fsm <=	(!w_msg_state)	? MOD2	:
									(w_msg_start)	? ADD1	: WAIT;
				MOD2	: r_fsm <=	(r_cnt=='d2)	? ADD2	: MOD2;
				ADD2	: r_fsm <=	(r_cnt=='d1)	? DONE	: ADD2;
				DONE	: r_fsm <= IDLE;
			endcase
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt <= 3'd0;
		else
			r_cnt	<=	(r_fsm==ADD2) ? (r_cnt==3'd1) ? 3'd0 : r_cnt+1'b1 :
						(r_fsm==ADD1 ||r_fsm==MUL || r_fsm==MOD2)  ? (r_cnt==3'd2) ? 3'd0 : r_cnt+1'b1 :
						(r_fsm==MOD1)				 ? (r_cnt==3'd7) ? 3'd0 : r_cnt+1'b1
													 : 3'd0;
//		else
//			r_cnt	<=	((r_fsm==ADD1 || r_fsm==ADD2) && (r_cnt==3'd1)) ||
//						((r_fsm==MUL || r_fsm==MOD2) && (r_cnt==3'd2)) ||
//						((r_fsm==MOD1) && (r_cnt==3'd7)) ? 3'd0 : r_cnt+1'b1
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_key_r	<= 128'd0;
		else
			r_key_r	<= (i_start) ? CLAMP & i_key[127:0] : r_key_r;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_key_s	<= 128'd0;
		else
			r_key_s	<= (i_start) ? i_key[255:128] : r_key_s;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_msg	<= 128'd0;
		else if (i_start || i_sig_msg)
			r_msg	<= i_msg;
//		else
//			r_msg	<= r_msg;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_len_msg	<= 32'd0;
		else if (i_start)
			r_len_msg	<= i_len_msg;
		else if (r_fsm==MOD1 && r_cnt==3'd7)
			r_len_msg	<= (r_len_msg<32'd16) ? 32'd0 : r_len_msg - 32'd16;
//		else
//			r_len_msg	<= r_len_msg;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn) begin
			r_acml0	<=	65'd0;
			r_acml1	<=	65'd0;
			r_acml2	<=	65'd0;
			r_acml3	<=	65'd0;
			r_acml4	<=	65'd0;
			r_acml5	<=	65'd0;
			r_acml6	<=	65'd0;
			r_acml7	<=	64'd0;
		end
		else if(r_fsm==ADD1) begin
			if (r_cnt=='d0) begin
				r_acml0	<= r_acml0 + w_msg_exp[31:0];
				r_acml1	<= r_acml1 + w_msg_exp[63:32];
				r_acml2	<= r_acml2 + w_msg_exp[95:64];
				r_acml3	<= r_acml3 + w_msg_exp[127:96];
				r_acml4	<= r_acml4 + w_msg_exp[135:128];
			end
			else if(r_cnt=='d1) begin
				r_acml1	<= r_acml1 + r_acml0[63:32];
				r_acml2	<= r_acml2 + r_acml1[63:32];
				r_acml3	<= r_acml3 + r_acml2[63:32];
				r_acml4	<= r_acml4 + r_acml3[63:32];
//				r_acml1	<= r_acml1 + r_acml0[32];
//				r_acml2	<= r_acml2 + r_acml1[32];
//				r_acml3	<= r_acml3 + r_acml2[32];
//				r_acml4	<= r_acml4 + r_acml3[32];
			end
		end
		else if(r_fsm==MUL) begin
			if(r_cnt=='d0) begin
				r_acml0	<=	r_a0 * w_key_r0;
				r_acml1	<=	r_a0 * w_key_r1 + r_a1 * w_key_r0;
				r_acml2	<=	r_a0 * w_key_r2 + r_a1 * w_key_r1 + r_a2 * w_key_r0;
				r_acml3	<=	r_a0 * w_key_r3 + r_a1 * w_key_r2 + r_a2 * w_key_r1 + r_a3 * w_key_r0;
				r_acml4	<=	r_a1 * w_key_r3 + r_a2 * w_key_r2 + r_a3 * w_key_r1 + r_a4 * w_key_r0;
				r_acml5	<=	r_a2 * w_key_r3 + r_a3 * w_key_r2 + r_a4 * w_key_r1;
				r_acml6	<=	r_a3 * w_key_r3 + r_a4 * w_key_r2;
				r_acml7	<=	r_a4 * w_key_r3;
			end
			else if(r_cnt=='d1) begin
				r_acml1	<= r_acml1 + r_acml0[63:32];
				r_acml2	<= r_acml2 + r_acml1[63:32];
				r_acml3	<= r_acml3 + r_acml2[63:32];
				r_acml4	<= r_acml4 + r_acml3[63:32];
				r_acml5	<= r_acml5 + r_acml4[63:32];
				r_acml6	<= r_acml6 + r_acml5[63:32];
				r_acml7	<= r_acml7 + r_acml6[63:32];
			end
			else if(r_cnt=='d8) begin
				r_acml0	<= {33'd0, r_acml0[31:0]};
				r_acml1	<= {33'd0, r_acml1[31:0]};
				r_acml2	<= {33'd0, r_acml2[31:0]};
				r_acml3	<= {33'd0, r_acml3[31:0]};
				r_acml4	<= {63'd0, r_acml4[1:0]};
			end
		end
		else if(r_fsm==MOD1) begin
			if(r_cnt=='d0) begin
				r_acml0	<= r_acml0 + r_a0;
				r_acml1	<= r_acml1 + r_a1;
				r_acml2	<= r_acml2 + r_a2;
				r_acml3	<= r_acml3 + r_a3;
//				r_acml0[32:0]	<= r_acml0[31:0] + r_a0[31:0];
//				r_acml1[32:0]	<= r_acml1[31:0] + r_a1[31:0];
//				r_acml2[32:0]	<= r_acml2[31:0] + r_a2[31:0];
//				r_acml3[32:0]	<= r_acml3[31:0] + r_a3[31:0];
			end
			else if(r_cnt=='d1) begin
				r_acml0	<= r_acml0 + {r_a1[1:0], r_a0[31:2]};
				r_acml1	<= r_acml1 + {r_a2[1:0], r_a1[31:2]};
				r_acml2	<= r_acml2 + {r_a3[1:0], r_a2[31:2]};
				r_acml3	<= r_acml3 + {     2'd0, r_a3[31:2]};
//				r_acml0[33:0]	<= r_acml0[32:0] + {r_a1[1:0], r_a0[31:2]};
//				r_acml1[33:0]	<= r_acml1[32:0] + {r_a2[1:0], r_a1[31:2]};
//				r_acml2[33:0]	<= r_acml2[32:0] + {r_a3[1:0], r_a2[31:2]};
//				r_acml3[33:0]	<= r_acml3[32:0] + {     2'd0, r_a3[31:2]};
			end
			else if(r_cnt=='d2) begin
				r_acml1	<= r_acml1 + r_acml0[63:32];
				r_acml2	<= r_acml2 + r_acml1[63:32];
				r_acml3	<= r_acml3 + r_acml2[63:32];
				r_acml4	<= r_acml4 + r_acml3[63:32];
//				r_acml1[34:0]	<= r_acml1[33:0] + r_acml0[33:32];
//				r_acml2[34:0]	<= r_acml2[33:0] + r_acml1[33:32];
//				r_acml3[34:0]	<= r_acml3[33:0] + r_acml2[33:32];
//				r_acml4[32:0]	<= r_acml4[1:0]  + r_acml3[33:32];
			end
			else if(r_cnt=='d3) begin
				r_acml0	<= {33'd0, r_acml0[31:0]};
				r_acml1	<= {33'd0, r_acml1[31:0]};
				r_acml2	<= {33'd0, r_acml2[31:0]};
				r_acml3	<= {33'd0, r_acml3[31:0]};
				r_acml4	<= {63'd0, r_acml4[1:0]};
//				r_acml0[34:0]	<= {3'd0,  r_acml0[31:0]};
//				r_acml1[34:0]	<= {3'd0,  r_acml1[31:0]};
//				r_acml2[34:0]	<= {3'd0,  r_acml2[31:0]};
//				r_acml3[34:0]	<= {3'd0,  r_acml3[31:0]};
//				r_acml4[34:0]	<= {33'd0, r_acml4[1:0]};
			end
			else if(r_cnt=='d4) begin
				r_acml0	<= r_acml0 + r_a0;
//				r_acml0[32:0]	<= r_acml0[31:0] + r_a0[31:0];
			end
			else if(r_cnt=='d5) begin
				r_acml0	<= r_acml0 + {2'd0, r_a0[31:2]};
//				r_acml0[33:0]	<= r_acml0[32:0] + {2'd0, r_a3[31:2]};
			end
			else if(r_cnt=='d6) begin
				r_acml1	<= r_acml1 + r_acml0[63:32];
				r_acml2	<= r_acml2 + r_acml1[63:32];
				r_acml3	<= r_acml3 + r_acml2[63:32];
				r_acml4	<= r_acml4 + r_acml3[63:32];
			end
			else if(r_cnt=='d7) begin
				r_acml0	<= {33'd0, r_acml0[31:0]};
				r_acml1	<= {33'd0, r_acml1[31:0]};
				r_acml2	<= {33'd0, r_acml2[31:0]};
				r_acml3	<= {33'd0, r_acml3[31:0]};
				r_acml4	<= {63'd0, r_acml4[1:0]};
//				r_acml0[34:0]	<= {3'd0,  r_acml0[31:0]};
//				r_acml1[34:0]	<= {3'd0,  r_acml1[31:0]};
//				r_acml2[34:0]	<= {3'd0,  r_acml2[31:0]};
//				r_acml3[34:0]	<= {3'd0,  r_acml3[31:0]};
//				r_acml4[34:0]	<= {33'd0, r_acml4[1:0]};
			end
		end
		else if(r_fsm==MOD2) begin
			if(r_cnt=='d0) begin
				r_acml0	<= r_acml0 + 3'd5;
			end
			else if(r_cnt=='d1) begin
				r_acml1	<= r_acml1 + r_acml0[63:32];
				r_acml2	<= r_acml2 + r_acml1[63:32];
				r_acml3	<= r_acml3 + r_acml2[63:32];
				r_acml4	<= r_acml4 + r_acml3[63:32];
			end
			else if(r_cnt=='d2) begin
				r_acml0	<= (r_acml4[3]) ? r_acml0 : r_a0;
				r_acml1	<= (r_acml4[3]) ? r_acml1 : r_a1;
				r_acml2	<= (r_acml4[3]) ? r_acml2 : r_a2;
				r_acml3	<= (r_acml4[3]) ? r_acml3 : r_a3;
			end
		end
		else if(r_fsm==ADD2) begin
			if(r_cnt=='d0) begin
				r_acml0	<= r_acml0 + w_key_s0;
				r_acml1	<= r_acml1 + w_key_s1;
				r_acml2	<= r_acml2 + w_key_s2;
				r_acml3	<= r_acml3 + w_key_s3;
			end
			else if(r_cnt=='d1) begin
				r_acml1	<= r_acml1 + r_acml0[63:32];
				r_acml2	<= r_acml2 + r_acml1[63:32];
				r_acml3	<= r_acml3 + r_acml2[63:32];
				r_acml4	<= r_acml4 + r_acml3[63:32];
			end
		end
//		else begin
//			r_acml0	<= r_acml0;
//			r_acml1	<= r_acml1;
//			r_acml2	<= r_acml2;
//			r_acml3	<= r_acml3;
//			r_acml4	<= r_acml4;
//			r_acml5	<= r_acml5;
//			r_acml6	<= r_acml6;
//			r_acml7	<= r_acml7;
//		end
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn) begin
			r_a0	<=	33'd0;
			r_a1	<=	33'd0;
			r_a2	<=	33'd0;
			r_a3	<=	33'd0;
			r_a4	<=	32'd0;
		end
		else if((r_fsm==ADD1) && (r_cnt=='d2)) begin
			r_a0	<= r_acml0[31:0];
			r_a1	<= r_acml1[31:0];
			r_a2	<= r_acml2[31:0];
			r_a3	<= r_acml3[31:0];
			r_a4	<= r_acml4[31:0];
		end
		else if((r_fsm==MUL) && (r_cnt=='d2)) begin
			r_a0	<= {1'd0, r_acml4[31:2], 2'd0};
			r_a1	<= {1'd0, r_acml5[31:0]};
			r_a2	<= {1'd0, r_acml6[31:0]};
			r_a3	<= {1'd0, r_acml7[31:0]};
		end
		else if((r_fsm==MOD1) && (r_cnt=='d3)) begin
			r_a0	<= {r_acml4[31:2], 2'd0};
		end
		else if(w_msg_start) begin
			r_a0	<= r_acml0[31:0];
			r_a1	<= r_acml1[31:0];
			r_a2	<= r_acml2[31:0];
			r_a3	<= r_acml3[31:0];
		end
		else begin
			r_a0 <= r_a0;
			r_a1 <= r_a1;
			r_a2 <= r_a2;
			r_a3 <= r_a3;
			r_a4 <= r_a4;
		end
	end

	// input msg
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_sig_msg	<= 1'd0;
		else if ((w_msg_state) && (r_cnt=='d7))
			o_sig_msg	<= (r_len_msg<32'd16) ? 1'b0 : 1'b1;
		else
			o_sig_msg	<= 1'd0;
	end
	
	// encrypt plain text
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_tag	<= 128'd0;
		else
			o_tag	<= (r_fsm==DONE) ? {r_acml3[31:0],r_acml2[31:0],r_acml1[31:0],r_acml0[31:0]}
									: o_tag;
	end

endmodule 
