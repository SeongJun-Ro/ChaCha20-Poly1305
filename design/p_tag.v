module p_tag (
	input					i_clk, i_rstn,
	input					i_start,

	input					i_en_msg,
	input		[127:0]		i_key_r,
	input		[127:0]		i_key_s,
	input		[127:0]		i_msg,
	input		[64:0]		i_len_msg,

	output	reg				o_rqst_msg,
	output	reg	[127:0]		o_tag,
	output	wire			o_done
);

	// fsm parameter
	parameter IDLE	= 3'd0;
	parameter ADD1	= 3'd1;
	parameter MUL	= 3'd2;
	parameter MOD1	= 3'd3;
	parameter WAIT	= 3'd4;
	parameter MOD2	= 3'd5;
	parameter ADD2	= 3'd6;
	parameter DONE	= 3'd7;
	// clamp for i_key_r
	parameter CLAMP 	= 128'h0ffffffc_0ffffffc_0ffffffc_0fffffff;
	// concate 0x01 | i_msg
	parameter CONCAT	= 134'h00_00000000_00000000_00000000_00000001;

	reg		[2:0]	r_fsm;
	reg		[31:0]	r_cnt;
	reg		[127:0]	r_msg;
	reg		[64:0]	r_len_msg;
	reg		[63:0]	r_acml0, r_acml1, r_acml2, r_acml3, r_acml4, r_acml5, r_acml6, r_acml7;
	reg		[31:0]	r_a0, r_a1, r_a2, r_a3, r_a4;

	wire	[127:0]	w_key_r;
	wire	[31:0]	w_key_r0, w_key_r1, w_key_r2, w_key_r3;
	wire	[31:0]	w_key_s0, w_key_s1, w_key_s2, w_key_s3;
	wire	[135:0]	w_msg_exp; 
	wire			w_msg_state;
	wire			w_msg_start;

	// clap i_key_r
	assign	w_key_r		= i_key_r & CLAMP;
	// split the key into 32bit
	assign	w_key_r0	= w_key_r[31:0];
	assign	w_key_r1	= w_key_r[63:32];
	assign	w_key_r2	= w_key_r[95:64];
	assign	w_key_r3	= w_key_r[127:96];
	assign	w_key_s0	= i_key_s[31:0];
	assign	w_key_s1	= i_key_s[63:32];
	assign	w_key_s2	= i_key_s[95:64];
	assign	w_key_s3	= i_key_s[127:96];
	// 
	assign	w_msg_exp	= (r_len_msg<65'd16) ? (1'b1 << {r_len_msg,3'd0}) + r_msg : {8'h01,r_msg};
	// 
	assign	w_msg_state	= r_len_msg!=65'd0;
	// 
	assign	w_msg_start	= ((r_fsm == WAIT) && (i_en_msg));
	// 
	assign	o_done		= (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_fsm	<= IDLE;
		else
			case (r_fsm)
				IDLE	: r_fsm <=	(i_start)		? ADD1	: IDLE;
				ADD1	: r_fsm <=	(r_cnt=='d5)	? MUL	: ADD1;
				MUL		: r_fsm <=	(r_cnt=='d8)	? MOD1	: MUL;
				MOD1	: r_fsm <=	(r_cnt=='d13)	? WAIT	: MOD1;
				WAIT	: r_fsm <=	(!w_msg_state)	? MOD2	:
									(w_msg_start)	? ADD1	: WAIT;
				MOD2	: r_fsm <=	(r_cnt=='d5)	? ADD2	: MOD2;
				ADD2	: r_fsm <=	(r_cnt=='d4)	? DONE	: ADD2;
				DONE	: r_fsm <= IDLE;
			endcase
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt <= 'd0;
		else
			if (r_fsm==ADD1)
				r_cnt <= (r_cnt=='d5)  ? 'd0 : r_cnt+1'b1;
			else if (r_fsm==MUL)
				r_cnt <= (r_cnt=='d8)  ? 'd0 : r_cnt+1'b1;
			else if (r_fsm==MOD1)
				r_cnt <= (r_cnt=='d13) ? 'd0 : r_cnt+1'b1;
			else if (r_fsm==MOD2)
				r_cnt <= (r_cnt=='d5)  ? 'd0 : r_cnt+1'b1;
			else if (r_fsm==ADD2)
				r_cnt <= (r_cnt=='d4)  ? 'd0 : r_cnt+1'b1;
			else
				r_cnt <= 'd0;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_msg	<= 128'd0;
		else if (i_start || i_en_msg)
			r_msg	<= i_msg;
//		else
//			r_msg	<= r_msg;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_len_msg	<= 65'd0;
		else if (i_start)
			r_len_msg	<= i_len_msg;
		else if (r_fsm==MOD1 && r_cnt=='d13)
			r_len_msg	<= (r_len_msg<65'd16) ? 33'd0 : r_len_msg - 65'd16;
//		else
//			r_len_msg	<= r_len_msg;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn) begin
			r_acml0	<=	64'd0;
			r_acml1	<=	64'd0;
			r_acml2	<=	64'd0;
			r_acml3	<=	64'd0;
			r_acml4	<=	64'd0;
			r_acml5	<=	64'd0;
			r_acml6	<=	64'd0;
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
			else if(r_cnt=='d1)
				r_acml1	<= r_acml1 + r_acml0[63:32];
			else if(r_cnt=='d2)
				r_acml2	<= r_acml2 + r_acml1[63:32];
			else if(r_cnt=='d3)
				r_acml3	<= r_acml3 + r_acml2[63:32];
			else if(r_cnt=='d4)
				r_acml4	<= r_acml4 + r_acml3[63:32];
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
			else if(r_cnt=='d1)
				r_acml1	<= r_acml1 + r_acml0[63:32];
			else if(r_cnt=='d2)
				r_acml2	<= r_acml2 + r_acml1[63:32];
			else if(r_cnt=='d3)
				r_acml3	<= r_acml3 + r_acml2[63:32];
			else if(r_cnt=='d4)
				r_acml4	<= r_acml4 + r_acml3[63:32];
			else if(r_cnt=='d5)
				r_acml5	<= r_acml5 + r_acml4[63:32];
			else if(r_cnt=='d6)
				r_acml6	<= r_acml6 + r_acml5[63:32];
			else if(r_cnt=='d7)
				r_acml7	<= r_acml7 + r_acml6[63:32];
			else if(r_cnt=='d8) begin
				r_acml0	<= {32'd0, r_acml0[31:0]};
				r_acml1	<= {32'd0, r_acml1[31:0]};
				r_acml2	<= {32'd0, r_acml2[31:0]};
				r_acml3	<= {32'd0, r_acml3[31:0]};
				r_acml4	<= {62'd0, r_acml4[1:0]};
			end
		end
		else if(r_fsm==MOD1) begin
			if(r_cnt=='d0) begin
				r_acml0	<= r_acml0 + r_a0;
				r_acml1	<= r_acml1 + r_a1;
				r_acml2	<= r_acml2 + r_a2;
				r_acml3	<= r_acml3 + r_a3;
			end
			else if(r_cnt=='d1) begin
				r_acml0	<= r_acml0 + {r_a1[1:0], r_a0[31:2]};
				r_acml1	<= r_acml1 + {r_a2[1:0], r_a1[31:2]};
				r_acml2	<= r_acml2 + {r_a3[1:0], r_a2[31:2]};
				r_acml3	<= r_acml3 + {     2'd0, r_a3[31:2]};
			end
			else if(r_cnt=='d2)
				r_acml1	<= r_acml1 + r_acml0[63:32];
			else if(r_cnt=='d3)
				r_acml2	<= r_acml2 + r_acml1[63:32];
			else if(r_cnt=='d4)
				r_acml3	<= r_acml3 + r_acml2[63:32];
			else if(r_cnt=='d5)
				r_acml4	<= r_acml4 + r_acml3[63:32];
			else if(r_cnt=='d6) begin
				r_acml0	<= {32'd0, r_acml0[31:0]};
				r_acml1	<= {32'd0, r_acml1[31:0]};
				r_acml2	<= {32'd0, r_acml2[31:0]};
				r_acml3	<= {32'd0, r_acml3[31:0]};
				r_acml4	<= {62'd0, r_acml4[1:0]};
			end
			else if(r_cnt=='d7)
				r_acml0	<= r_acml0 + r_a0;
			else if(r_cnt=='d8)
				r_acml0	<= r_acml0 + {2'd0, r_a0[31:2]};
			else if(r_cnt=='d9)
				r_acml1	<= r_acml1 + r_acml0[63:32];
			else if(r_cnt=='d10)
				r_acml2	<= r_acml2 + r_acml1[63:32];
			else if(r_cnt=='d11)
				r_acml3	<= r_acml3 + r_acml2[63:32];
			else if(r_cnt=='d12)
				r_acml4	<= r_acml4 + r_acml3[63:32];
			else if(r_cnt=='d13) begin
				r_acml0	<= {32'd0, r_acml0[31:0]};
				r_acml1	<= {32'd0, r_acml1[31:0]};
				r_acml2	<= {32'd0, r_acml2[31:0]};
				r_acml3	<= {32'd0, r_acml3[31:0]};
				r_acml4	<= {62'd0, r_acml4[1:0]};
			end
		end
		else if(r_fsm==MOD2) begin
			if(r_cnt=='d0)
				r_acml0	<= r_acml0 + 3'd5;
			else if(r_cnt=='d1)
				r_acml1	<= r_acml1 + r_acml0[63:32];
			else if(r_cnt=='d2)
				r_acml2	<= r_acml2 + r_acml1[63:32];
			else if(r_cnt=='d3)
				r_acml3	<= r_acml3 + r_acml2[63:32];
			else if(r_cnt=='d4)
				r_acml4	<= r_acml4 + r_acml3[63:32];
			else if(r_cnt=='d5) begin
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
			else if(r_cnt=='d1)
				r_acml1	<= r_acml1 + r_acml0[63:32];
			else if(r_cnt=='d2)
				r_acml2	<= r_acml2 + r_acml1[63:32];
			else if(r_cnt=='d3)
				r_acml3	<= r_acml3 + r_acml2[63:32];
//			else if(r_cnt=='d4)
//				r_acml4	<= r_acml4 + r_acml3[63:32];
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
			r_a0	<=	32'd0;
			r_a1	<=	32'd0;
			r_a2	<=	32'd0;
			r_a3	<=	32'd0;
			r_a4	<=	32'd0;
		end
		else if((r_fsm==ADD1) && (r_cnt=='d5)) begin
			r_a0	<=	r_acml0[31:0];
			r_a1	<=	r_acml1[31:0];
			r_a2	<=	r_acml2[31:0];
			r_a3	<=	r_acml3[31:0];
			r_a4	<=	r_acml4[31:0];
		end
		else if((r_fsm==MUL) && (r_cnt=='d8)) begin
			r_a0	<=	{r_acml4[31:2], 2'd0};
			r_a1	<=	r_acml5[31:0];
			r_a2	<=	r_acml6[31:0];
			r_a3	<=	r_acml7[31:0];
		end
		else if((r_fsm==MOD1) && (r_cnt=='d6))
			r_a0	<= {r_acml4[31:2], 2'd0};
		else if(r_fsm==WAIT) begin
			r_a0	<=	r_acml0[31:0];
			r_a1	<=	r_acml1[31:0];
			r_a2	<=	r_acml2[31:0];
			r_a3	<=	r_acml3[31:0];
			r_a4	<=	{30'd0, r_acml4[1:0]};
		end
//		else begin
//			r_a0 <= r_a0;
//			r_a1 <= r_a1;
//			r_a2 <= r_a2;
//			r_a3 <= r_a3;
//			r_a4 <= r_a4;
//		end
	end

	// input msg
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_rqst_msg	<= 1'd0;
		else if ((w_msg_state) && (r_cnt=='d13))
			o_rqst_msg	<= (r_len_msg<65'd16) ? 1'b0 : 1'b1;
		else
			o_rqst_msg	<= 1'd0;
	end

	// encrypt plain text
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_tag	<= 128'd0;
		else
			o_tag	<= ((r_fsm==ADD2) && (r_cnt=='d4)) ? {r_acml3[31:0],r_acml2[31:0],r_acml1[31:0],r_acml0[31:0]} : o_tag;
	end

//	wire	[135:0]	w_p;
//	assign	w_p	= ((135'd1<<130)-5);
//	reg		[255:0]	r_mod;
//	always @(posedge i_clk, negedge i_rstn) begin
//		if (!i_rstn)
//			r_mod	<= 256'd0;
//		else if (r_fsm == MUL && r_cnt=='d8)
//			r_mod	<=	{r_acml7[31:0],r_acml6[31:0],r_acml5[31:0],r_acml4[31:0],r_acml3[31:0],r_acml2[31:0],r_acml1[31:0],r_acml0[31:0]};
//		else if (r_fsm == MOD1 && r_cnt=='d0)
//			r_mod	<=	r_mod % w_p;
////		else
//	end

endmodule
