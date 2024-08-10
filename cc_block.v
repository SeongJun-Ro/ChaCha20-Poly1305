module cc_block (
	input				i_clk, i_rstn,
	input		[255:0]	i_key,
	input		[95:0]	i_non,
	input		[31:0]	i_cnt,
	input				i_qr,
	
	output	reg	[511:0]	o_block,
	output	wire		o_done
);

	// ***** local parameter definition *****

	// fsm
	parameter IDLE		= 3'd0;
	parameter RDY		= 3'd1;
	parameter R_CALC	= 3'd2;
	parameter ADD		= 3'd3;
	parameter DONE		= 3'd4;

	// constant
	parameter CONSTANT0 = 32'h61707865;
	parameter CONSTANT1 = 32'h3320646e;
	parameter CONSTANT2 = 32'h79622d32;
	parameter CONSTANT3 = 32'h6b206574;

	// ***** local register definition *****
	reg	[2:0]	r_fsm;
	reg	[3:0]	r_cnt_calc;  // 12
	reg	[4:0]	r_cnt_r;  // 20
	reg [31:0]	r_state	[15:0];
	reg [31:0]	r_block	[15:0];

	// ***** local wire definition *****
	assign o_done = (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	// Explanation of always statement
	
	// [2:0] r_fsm
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_fsm <= 3'd0;
		else
			case(r_fsm)
				IDLE	: r_fsm <= (i_qr) ? RDY	: IDLE;
				RDY		: r_fsm <= R_CALC;
				R_CALC	: r_fsm <= ((r_cnt_r==5'd20-1) && (r_cnt_calc==5'd12-1)) ? ADD : R_CALC;
				ADD		: r_fsm <= DONE;
				DONE	: r_fsm <= (i_qr) ? RDY	: IDLE;
			endcase
	end
	
	// [3:0] r_cnt_calc
	// 12 cnt
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_cnt_calc <= 4'd0;
		else if(r_fsm==R_CALC)
			r_cnt_calc <= (r_cnt_calc == 4'd12-1) ? 4'd0 : r_cnt_calc + 1'b1;
//		else
//			r_cnt_calc <= r_cnt_calc;
	end
	
	// [4:0] r_cnt_r
	// cnt 20
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_cnt_r <=	5'd0;
		else if(r_fsm==R_CALC)
//			r_cnt_r <=	(r_cnt_r == 5'd20-1) ? 5'd0 : r_cnt_r + 1'b1;
			r_cnt_r <=	(r_cnt_calc == 4'd12-1) ?
						(r_cnt_r == 5'd20-1) ? 5'd0 : r_cnt_r + 1'b1
						: r_cnt_r;
//		else
//			r_cnt_r <= r_cnt_r;
	end
	

	// [31:0] r_state [15:0];
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn) begin
			r_state[0]	<= 32'd0;
			r_state[1]	<= 32'd0;
			r_state[2]	<= 32'd0;
			r_state[3]	<= 32'd0;
			r_state[4]	<= 32'd0;
			r_state[5]	<= 32'd0;
			r_state[6]	<= 32'd0;
			r_state[7]	<= 32'd0;
			r_state[8]	<= 32'd0;
			r_state[9]	<= 32'd0;
			r_state[10]	<= 32'd0;
			r_state[11]	<= 32'd0;
			r_state[12]	<= 32'd0;
			r_state[13]	<= 32'd0;
			r_state[14]	<= 32'd0;
			r_state[15]	<= 32'd0;
		end
		else if(r_fsm==RDY) begin  // init block
			r_state[0]	<= CONSTANT0;
			r_state[1]	<= CONSTANT1;
			r_state[2]	<= CONSTANT2;
			r_state[3]	<= CONSTANT3;
			r_state[4]	<= i_key[31:0];
			r_state[5]	<= i_key[63:32];
			r_state[6]	<= i_key[95:64];
			r_state[7]	<= i_key[127:96];
			r_state[8]	<= i_key[159:128];
			r_state[9]	<= i_key[191:160];
			r_state[10]	<= i_key[223:192];
			r_state[11]	<= i_key[255:224];
			r_state[12]	<= i_cnt;
			r_state[13]	<= i_non[31:0];
			r_state[14]	<= i_non[63:32];
			r_state[15]	<= i_non[95:64];
		end
	end

	// [31:0] r_block [15:0];
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn) begin
			r_block[0]	<= 32'd0;
			r_block[1]	<= 32'd0;
			r_block[2]	<= 32'd0;
			r_block[3]	<= 32'd0;
			r_block[4]	<= 32'd0;
			r_block[5]	<= 32'd0;
			r_block[6]	<= 32'd0;
			r_block[7]	<= 32'd0;
			r_block[8]	<= 32'd0;
			r_block[9]	<= 32'd0;
			r_block[10]	<= 32'd0;
			r_block[11]	<= 32'd0;
			r_block[12]	<= 32'd0;
			r_block[13]	<= 32'd0;
			r_block[14]	<= 32'd0;
			r_block[15]	<= 32'd0;
		end
		else if(r_fsm==RDY) begin  // init block
			r_block[0]	<= CONSTANT0;
			r_block[1]	<= CONSTANT1;
			r_block[2]	<= CONSTANT2;
			r_block[3]	<= CONSTANT3;
			r_block[4]	<= i_key[31:0];
			r_block[5]	<= i_key[63:32];
			r_block[6]	<= i_key[95:64];
			r_block[7]	<= i_key[127:96];
			r_block[8]	<= i_key[159:128];
			r_block[9]	<= i_key[191:160];
			r_block[10]	<= i_key[223:192];
			r_block[11]	<= i_key[255:224];
			r_block[12]	<= i_cnt;
			r_block[13]	<= i_non[31:0];
			r_block[14]	<= i_non[63:32];
			r_block[15]	<= i_non[95:64];
		end
		else if(r_fsm==R_CALC) begin
			if (r_cnt_r % 2==0)  // odd round
				case (r_cnt_calc)
					4'd0: begin  // a+=b
						r_block[0]	<= r_block[0] + r_block[4];
						r_block[1]	<= r_block[1] + r_block[5];
						r_block[2]	<= r_block[2] + r_block[6];
						r_block[3]	<= r_block[3] + r_block[7];
					end
					4'd1: begin  // d^=a
						r_block[12]	<= r_block[12] ^ r_block[0];
						r_block[13]	<= r_block[13] ^ r_block[1];
						r_block[14]	<= r_block[14] ^ r_block[2];
						r_block[15]	<= r_block[15] ^ r_block[3];
					end
					4'd2: begin  // d<<<=16
						r_block[12]	<= {r_block[12][15:0],r_block[12][31:16]};
						r_block[13]	<= {r_block[13][15:0],r_block[13][31:16]};
						r_block[14]	<= {r_block[14][15:0],r_block[14][31:16]};
						r_block[15]	<= {r_block[15][15:0],r_block[15][31:16]};
					end
					4'd3: begin  // c+=d
						r_block[8]	<= r_block[8]  + r_block[12];
						r_block[9]	<= r_block[9]  + r_block[13];
						r_block[10]	<= r_block[10] + r_block[14];
						r_block[11]	<= r_block[11] + r_block[15];
					end
					4'd4: begin  // b^=c
						r_block[4]	<= r_block[4] ^ r_block[8];
						r_block[5]	<= r_block[5] ^ r_block[9];
						r_block[6]	<= r_block[6] ^ r_block[10];
						r_block[7]	<= r_block[7] ^ r_block[11];
					end
					4'd5: begin  // b<<<=12
						r_block[4]	<= {r_block[4][19:0],r_block[4][31:20]};
						r_block[5]	<= {r_block[5][19:0],r_block[5][31:20]};
						r_block[6]	<= {r_block[6][19:0],r_block[6][31:20]};
						r_block[7]	<= {r_block[7][19:0],r_block[7][31:20]};
					end
					4'd6: begin  // a+=b
						r_block[0]	<= r_block[0] + r_block[4];
						r_block[1]	<= r_block[1] + r_block[5];
						r_block[2]	<= r_block[2] + r_block[6];
						r_block[3]	<= r_block[3] + r_block[7];
					end
					4'd7: begin  // d^=a
						r_block[12]	<= r_block[12] ^ r_block[0];
						r_block[13]	<= r_block[13] ^ r_block[1];
						r_block[14]	<= r_block[14] ^ r_block[2];
						r_block[15]	<= r_block[15] ^ r_block[3];
					end
					4'd8: begin  // d<<<=8
						r_block[12]	<= {r_block[12][23:0],r_block[12][31:24]};
						r_block[13]	<= {r_block[13][23:0],r_block[13][31:24]};
						r_block[14]	<= {r_block[14][23:0],r_block[14][31:24]};
						r_block[15]	<= {r_block[15][23:0],r_block[15][31:24]};
					end
					4'd9: begin  // c+=d
						r_block[8]	<= r_block[8]  + r_block[12];
						r_block[9]	<= r_block[9]  + r_block[13];
						r_block[10]	<= r_block[10] + r_block[14];
						r_block[11]	<= r_block[11] + r_block[15];
					end
					4'd10: begin  // b^=c
						r_block[4]	<= r_block[4] ^ r_block[8];
						r_block[5]	<= r_block[5] ^ r_block[9];
						r_block[6]	<= r_block[6] ^ r_block[10];
						r_block[7]	<= r_block[7] ^ r_block[11];
					end
					4'd11: begin  // b<<<=7
						r_block[4]	<= {r_block[4][24:0],r_block[4][31:25]};
						r_block[5]	<= {r_block[5][24:0],r_block[5][31:25]};
						r_block[6]	<= {r_block[6][24:0],r_block[6][31:25]};
						r_block[7]	<= {r_block[7][24:0],r_block[7][31:25]};
					end
					default: begin
						r_block[0]	<= 32'd0;
						r_block[1]	<= 32'd0;
						r_block[2]	<= 32'd0;
						r_block[3]	<= 32'd0;
						r_block[4]	<= 32'd0;
						r_block[5]	<= 32'd0;
						r_block[6]	<= 32'd0;
						r_block[7]	<= 32'd0;
						r_block[8]	<= 32'd0;
						r_block[9]	<= 32'd0;
						r_block[10]	<= 32'd0;
						r_block[11]	<= 32'd0;
						r_block[12]	<= 32'd0;
						r_block[13]	<= 32'd0;
						r_block[14]	<= 32'd0;
						r_block[15]	<= 32'd0;
					end
				endcase
			else  // even round
				case (r_cnt_calc)
					4'd0: begin  // a+=b
						r_block[0]	<= r_block[0] + r_block[5];
						r_block[1]	<= r_block[1] + r_block[6];
						r_block[2]	<= r_block[2] + r_block[7];
						r_block[3]	<= r_block[3] + r_block[4];
					end
					4'd1: begin  // d^=a
						r_block[15]	<= r_block[15] ^ r_block[0];
						r_block[12]	<= r_block[12] ^ r_block[1];
						r_block[13]	<= r_block[13] ^ r_block[2];
						r_block[14]	<= r_block[14] ^ r_block[3];
					end
					4'd2: begin  // d<<<=16
						r_block[15]	<= {r_block[15][15:0],r_block[15][31:16]};
						r_block[12]	<= {r_block[12][15:0],r_block[12][31:16]};
						r_block[13]	<= {r_block[13][15:0],r_block[13][31:16]};
						r_block[14]	<= {r_block[14][15:0],r_block[14][31:16]};
					end
					4'd3: begin  // c+=d
						r_block[10]	<= r_block[10] + r_block[15];
						r_block[11]	<= r_block[11] + r_block[12];
						r_block[8]	<= r_block[8]  + r_block[13];
						r_block[9]	<= r_block[9]  + r_block[14];
					end
					4'd4: begin  // b^=c
						r_block[5]	<= r_block[5] ^ r_block[10];
						r_block[6]	<= r_block[6] ^ r_block[11];
						r_block[7]	<= r_block[7] ^ r_block[8];
						r_block[4]	<= r_block[4] ^ r_block[9];
					end
					4'd5: begin  // b<<<=12
						r_block[5]	<= {r_block[5][19:0],r_block[5][31:20]};
						r_block[6]	<= {r_block[6][19:0],r_block[6][31:20]};
						r_block[7]	<= {r_block[7][19:0],r_block[7][31:20]};
						r_block[4]	<= {r_block[4][19:0],r_block[4][31:20]};
					end
					4'd6: begin  // a+=b
						r_block[0]	<= r_block[0] + r_block[5];
						r_block[1]	<= r_block[1] + r_block[6];
						r_block[2]	<= r_block[2] + r_block[7];
						r_block[3]	<= r_block[3] + r_block[4];
					end
					4'd7: begin  // d^=a
						r_block[15]	<= r_block[15] ^ r_block[0];
						r_block[12]	<= r_block[12] ^ r_block[1];
						r_block[13]	<= r_block[13] ^ r_block[2];
						r_block[14]	<= r_block[14] ^ r_block[3];
					end
					4'd8: begin  // d<<<=8
						r_block[15]	<= {r_block[15][23:0],r_block[15][31:24]};
						r_block[12]	<= {r_block[12][23:0],r_block[12][31:24]};
						r_block[13]	<= {r_block[13][23:0],r_block[13][31:24]};
						r_block[14]	<= {r_block[14][23:0],r_block[14][31:24]};
					end
					4'd9: begin  // c+=d
						r_block[10]	<= r_block[10] + r_block[15];
						r_block[11]	<= r_block[11] + r_block[12];
						r_block[8]	<= r_block[8]  + r_block[13];
						r_block[9]	<= r_block[9]  + r_block[14];
					end
					4'd10: begin  // b^=c
						r_block[5]	<= r_block[5] ^ r_block[10];
						r_block[6]	<= r_block[6] ^ r_block[11];
						r_block[7]	<= r_block[7] ^ r_block[8];
						r_block[4]	<= r_block[4] ^ r_block[9];
					end
					4'd11: begin  // b<<<=7
						r_block[5]	<= {r_block[5][24:0],r_block[5][31:25]};
						r_block[6]	<= {r_block[6][24:0],r_block[6][31:25]};
						r_block[7]	<= {r_block[7][24:0],r_block[7][31:25]};
						r_block[4]	<= {r_block[4][24:0],r_block[4][31:25]};
					end
					default: begin
						r_block[0]	<= 32'd0;
						r_block[1]	<= 32'd0;
						r_block[2]	<= 32'd0;
						r_block[3]	<= 32'd0;
						r_block[4]	<= 32'd0;
						r_block[5]	<= 32'd0;
						r_block[6]	<= 32'd0;
						r_block[7]	<= 32'd0;
						r_block[8]	<= 32'd0;
						r_block[9]	<= 32'd0;
						r_block[10]	<= 32'd0;
						r_block[11]	<= 32'd0;
						r_block[12]	<= 32'd0;
						r_block[13]	<= 32'd0;
						r_block[14]	<= 32'd0;
						r_block[15]	<= 32'd0;
					end
				endcase
		end
		else if(r_fsm==ADD) begin
			r_block[0]	<= r_block[0]  + r_state[0];
			r_block[1]	<= r_block[1]  + r_state[1];
			r_block[2]	<= r_block[2]  + r_state[2];
			r_block[3]	<= r_block[3]  + r_state[3];
			r_block[4]	<= r_block[4]  + r_state[4];
			r_block[5]	<= r_block[5]  + r_state[5];
			r_block[6]	<= r_block[6]  + r_state[6];
			r_block[7]	<= r_block[7]  + r_state[7];
			r_block[8]	<= r_block[8]  + r_state[8];
			r_block[9]	<= r_block[9]  + r_state[9];
			r_block[10]	<= r_block[10] + r_state[10];
			r_block[11]	<= r_block[11] + r_state[11];
			r_block[12]	<= r_block[12] + r_state[12];
			r_block[13]	<= r_block[13] + r_state[13];
			r_block[14]	<= r_block[14] + r_state[14];
			r_block[15]	<= r_block[15] + r_state[15];
		end
//		else
//			r_block <= r_block;
	end
	
	// o_block
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			o_block <= 512'd0;
		else if(r_fsm==DONE)
			o_block = {
				r_block[15], r_block[14], r_block[13], r_block[12],
				r_block[11], r_block[10], r_block[9],  r_block[8],
				r_block[7],  r_block[6],  r_block[5],  r_block[4],
				r_block[3],  r_block[2],  r_block[1],  r_block[0]
			};
	end

endmodule 