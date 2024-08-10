module cc_block (
	input				i_clk, i_rstn,
	input				i_start,
	
	input		[255:0]	i_key,
	input		[95:0]	i_non,
	input		[31:0]	i_cnt,
	
	output	reg	[511:0]	o_stream,
	output	wire		o_done
);

	// ***** local parameter definition *****
	// constant / block 0,1,2,3
	parameter CONSTANT0 = 32'h61707865;
	parameter CONSTANT1 = 32'h3320646e;
	parameter CONSTANT2 = 32'h79622d32;
	parameter CONSTANT3 = 32'h6b206574;
	// state
	parameter IDLE	= 3'b000;
	parameter RDY	= 3'b001;
	parameter RND	= 3'b010;
	parameter ADD	= 3'b110;
	parameter DONE	= 3'b100;

	// ***** local register definition *****
	reg [2:0] r_fsm;
	reg [4:0] r_cnt_rnd;
	reg [3:0] r_cnt_calc;
	reg		[31:0]	r_block0, r_block1, r_block2, r_block3, r_block4, r_block5, r_block6, r_block7, r_block8, r_block9, r_block10, r_block11, r_block12, r_block13, r_block14, r_block15;

	// ***** local wire definition *****
	wire	[31:0]	w_block4, w_block5, w_block6, w_block7, w_block8, w_block9, w_block10, w_block11, w_block13, w_block14, w_block15;

	assign	w_block4	= i_key[31:0];
	assign	w_block5	= i_key[63:32];
	assign	w_block6	= i_key[95:64];
	assign	w_block7	= i_key[127:96];
	assign	w_block8	= i_key[159:128];
	assign	w_block9	= i_key[191:160];
	assign	w_block10	= i_key[223:192];
	assign	w_block11	= i_key[255:224];
	assign	w_block13	= i_non[31:0];
	assign	w_block14	= i_non[63:32];
	assign	w_block15	= i_non[95:64];

	assign o_done = (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	// Explanation of always statement

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_fsm <= IDLE;
		else
			case(r_fsm)
				IDLE	: r_fsm <= (i_start) ? RDY : IDLE;
				RDY		: r_fsm <= RND;
				RND		: r_fsm <= (r_cnt_rnd == 5'd19 && r_cnt_calc == 4'd11) ? ADD : RND;
				ADD		: r_fsm <= DONE;
				DONE	: r_fsm <= IDLE;
				default : r_fsm	<= IDLE;
			endcase
	end

	// count 20 round
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt_rnd <= 5'd0;
		else if (r_fsm == IDLE)
			r_cnt_rnd <= 5'd0;
		else if (r_fsm == RND)
			r_cnt_rnd <= (r_cnt_calc == 4'd11) ? r_cnt_rnd + 1'b1 : r_cnt_rnd;
		else
			r_cnt_rnd <= r_cnt_rnd;
	end
	
	// count 12 calc
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt_calc <= 4'd0;
		else if (r_fsm == IDLE)
			r_cnt_calc <= 4'd0;
		else if (r_fsm == RND)
			r_cnt_calc <= (r_cnt_calc == 4'd11) ? 4'd0 : r_cnt_calc + 1'b1;
		else
			r_cnt_calc <= r_cnt_calc;
	end

	// calc quarter round & block += state
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn) begin
			r_block0	<= 32'd0;
			r_block1	<= 32'd0;
			r_block2	<= 32'd0;
			r_block3	<= 32'd0;
			r_block4	<= 32'd0;
			r_block5	<= 32'd0;
			r_block6	<= 32'd0;
			r_block7	<= 32'd0;
			r_block8	<= 32'd0;
			r_block9	<= 32'd0;
			r_block10	<= 32'd0;
			r_block11	<= 32'd0;
			r_block12	<= 32'd0;
			r_block13	<= 32'd0;
			r_block14	<= 32'd0;
			r_block15	<= 32'd0;
		end
		else if (r_fsm == RDY) begin
			r_block0	<= CONSTANT0;
			r_block1	<= CONSTANT1;
			r_block2	<= CONSTANT2;
			r_block3	<= CONSTANT3;
			r_block4	<= w_block4;
			r_block5	<= w_block5;
			r_block6	<= w_block6;
			r_block7	<= w_block7;
			r_block8	<= w_block8;
			r_block9	<= w_block9;
			r_block10	<= w_block10;
			r_block11	<= w_block11;
			r_block12	<= i_cnt;
			r_block13	<= w_block13;
			r_block14	<= w_block14;
			r_block15	<= w_block15;
		end
		else if(r_fsm==RND) begin
			if (r_cnt_rnd[0]==0)  // odd round
				case (r_cnt_calc)
					4'd0: begin  // a+=b
						r_block0	<= r_block0 + r_block4;
						r_block1	<= r_block1 + r_block5;
						r_block2	<= r_block2 + r_block6;
						r_block3	<= r_block3 + r_block7;
					end
					4'd1: begin  // d^=a
						r_block12	<= r_block12 ^ r_block0;
						r_block13	<= r_block13 ^ r_block1;
						r_block14	<= r_block14 ^ r_block2;
						r_block15	<= r_block15 ^ r_block3;
					end
					4'd2: begin  // d<<<=16
						r_block12	<= {r_block12[15:0],r_block12[31:16]};
						r_block13	<= {r_block13[15:0],r_block13[31:16]};
						r_block14	<= {r_block14[15:0],r_block14[31:16]};
						r_block15	<= {r_block15[15:0],r_block15[31:16]};
					end
					4'd3: begin  // c+=d
						r_block8	<= r_block8  + r_block12;
						r_block9	<= r_block9  + r_block13;
						r_block10	<= r_block10 + r_block14;
						r_block11	<= r_block11 + r_block15;
					end
					4'd4: begin  // b^=c
						r_block4	<= r_block4 ^ r_block8;
						r_block5	<= r_block5 ^ r_block9;
						r_block6	<= r_block6 ^ r_block10;
						r_block7	<= r_block7 ^ r_block11;
					end
					4'd5: begin  // b<<<=12
						r_block4	<= {r_block4[19:0],r_block4[31:20]};
						r_block5	<= {r_block5[19:0],r_block5[31:20]};
						r_block6	<= {r_block6[19:0],r_block6[31:20]};
						r_block7	<= {r_block7[19:0],r_block7[31:20]};
					end
					4'd6: begin  // a+=b
						r_block0	<= r_block0 + r_block4;
						r_block1	<= r_block1 + r_block5;
						r_block2	<= r_block2 + r_block6;
						r_block3	<= r_block3 + r_block7;
					end
					4'd7: begin  // d^=a
						r_block12	<= r_block12 ^ r_block0;
						r_block13	<= r_block13 ^ r_block1;
						r_block14	<= r_block14 ^ r_block2;
						r_block15	<= r_block15 ^ r_block3;
					end
					4'd8: begin  // d<<<=8
						r_block12	<= {r_block12[23:0],r_block12[31:24]};
						r_block13	<= {r_block13[23:0],r_block13[31:24]};
						r_block14	<= {r_block14[23:0],r_block14[31:24]};
						r_block15	<= {r_block15[23:0],r_block15[31:24]};
					end
					4'd9: begin  // c+=d
						r_block8	<= r_block8  + r_block12;
						r_block9	<= r_block9  + r_block13;
						r_block10	<= r_block10 + r_block14;
						r_block11	<= r_block11 + r_block15;
					end
					4'd10: begin  // b^=c
						r_block4	<= r_block4 ^ r_block8;
						r_block5	<= r_block5 ^ r_block9;
						r_block6	<= r_block6 ^ r_block10;
						r_block7	<= r_block7 ^ r_block11;
					end
					4'd11: begin  // b<<<=7
						r_block4	<= {r_block4[24:0],r_block4[31:25]};
						r_block5	<= {r_block5[24:0],r_block5[31:25]};
						r_block6	<= {r_block6[24:0],r_block6[31:25]};
						r_block7	<= {r_block7[24:0],r_block7[31:25]};
					end
					default: begin
						r_block0	<= 32'd0;
						r_block1	<= 32'd0;
						r_block2	<= 32'd0;
						r_block3	<= 32'd0;
						r_block4	<= 32'd0;
						r_block5	<= 32'd0;
						r_block6	<= 32'd0;
						r_block7	<= 32'd0;
						r_block8	<= 32'd0;
						r_block9	<= 32'd0;
						r_block10	<= 32'd0;
						r_block11	<= 32'd0;
						r_block12	<= 32'd0;
						r_block13	<= 32'd0;
						r_block14	<= 32'd0;
						r_block15	<= 32'd0;
					end
				endcase
			else  // even round
				case (r_cnt_calc)
					4'd0: begin  // a+=b
						r_block0	<= r_block0 + r_block5;
						r_block1	<= r_block1 + r_block6;
						r_block2	<= r_block2 + r_block7;
						r_block3	<= r_block3 + r_block4;
					end
					4'd1: begin  // d^=a
						r_block15	<= r_block15 ^ r_block0;
						r_block12	<= r_block12 ^ r_block1;
						r_block13	<= r_block13 ^ r_block2;
						r_block14	<= r_block14 ^ r_block3;
					end
					4'd2: begin  // d<<<=16
						r_block15	<= {r_block15[15:0],r_block15[31:16]};
						r_block12	<= {r_block12[15:0],r_block12[31:16]};
						r_block13	<= {r_block13[15:0],r_block13[31:16]};
						r_block14	<= {r_block14[15:0],r_block14[31:16]};
					end
					4'd3: begin  // c+=d
						r_block10	<= r_block10 + r_block15;
						r_block11	<= r_block11 + r_block12;
						r_block8	<= r_block8  + r_block13;
						r_block9	<= r_block9  + r_block14;
					end
					4'd4: begin  // b^=c
						r_block5	<= r_block5 ^ r_block10;
						r_block6	<= r_block6 ^ r_block11;
						r_block7	<= r_block7 ^ r_block8;
						r_block4	<= r_block4 ^ r_block9;
					end
					4'd5: begin  // b<<<=12
						r_block5	<= {r_block5[19:0],r_block5[31:20]};
						r_block6	<= {r_block6[19:0],r_block6[31:20]};
						r_block7	<= {r_block7[19:0],r_block7[31:20]};
						r_block4	<= {r_block4[19:0],r_block4[31:20]};
					end
					4'd6: begin  // a+=b
						r_block0	<= r_block0 + r_block5;
						r_block1	<= r_block1 + r_block6;
						r_block2	<= r_block2 + r_block7;
						r_block3	<= r_block3 + r_block4;
					end
					4'd7: begin  // d^=a
						r_block15	<= r_block15 ^ r_block0;
						r_block12	<= r_block12 ^ r_block1;
						r_block13	<= r_block13 ^ r_block2;
						r_block14	<= r_block14 ^ r_block3;
					end
					4'd8: begin  // d<<<=8
						r_block15	<= {r_block15[23:0],r_block15[31:24]};
						r_block12	<= {r_block12[23:0],r_block12[31:24]};
						r_block13	<= {r_block13[23:0],r_block13[31:24]};
						r_block14	<= {r_block14[23:0],r_block14[31:24]};
					end
					4'd9: begin  // c+=d
						r_block10	<= r_block10 + r_block15;
						r_block11	<= r_block11 + r_block12;
						r_block8	<= r_block8  + r_block13;
						r_block9	<= r_block9  + r_block14;
					end
					4'd10: begin  // b^=c
						r_block5	<= r_block5 ^ r_block10;
						r_block6	<= r_block6 ^ r_block11;
						r_block7	<= r_block7 ^ r_block8;
						r_block4	<= r_block4 ^ r_block9;
					end
					4'd11: begin  // b<<<=7
						r_block5	<= {r_block5[24:0],r_block5[31:25]};
						r_block6	<= {r_block6[24:0],r_block6[31:25]};
						r_block7	<= {r_block7[24:0],r_block7[31:25]};
						r_block4	<= {r_block4[24:0],r_block4[31:25]};
					end
					default: begin
						r_block0	<= 32'd0;
						r_block1	<= 32'd0;
						r_block2	<= 32'd0;
						r_block3	<= 32'd0;
						r_block4	<= 32'd0;
						r_block5	<= 32'd0;
						r_block6	<= 32'd0;
						r_block7	<= 32'd0;
						r_block8	<= 32'd0;
						r_block9	<= 32'd0;
						r_block10	<= 32'd0;
						r_block11	<= 32'd0;
						r_block12	<= 32'd0;
						r_block13	<= 32'd0;
						r_block14	<= 32'd0;
						r_block15	<= 32'd0;
					end
				endcase
		end
		else if(r_fsm==ADD) begin
			r_block0	<= r_block0  + CONSTANT0;
			r_block1	<= r_block1  + CONSTANT1;
			r_block2	<= r_block2  + CONSTANT2;
			r_block3	<= r_block3  + CONSTANT3;
			r_block4	<= r_block4  + w_block4;
			r_block5	<= r_block5  + w_block5;
			r_block6	<= r_block6  + w_block6;
			r_block7	<= r_block7  + w_block7;
			r_block8	<= r_block8  + w_block8;
			r_block9	<= r_block9  + w_block9;
			r_block10	<= r_block10 + w_block10;
			r_block11	<= r_block11 + w_block11;
			r_block12	<= r_block12 + i_cnt;
			r_block13	<= r_block13 + w_block13;
			r_block14	<= r_block14 + w_block14;
			r_block15	<= r_block15 + w_block15;
		end
//		else begin
//			r_block0	<= r_block0;
//			r_block1	<= r_block1;
//			r_block2	<= r_block2;
//			r_block3	<= r_block3;
//			r_block4	<= r_block4;
//			r_block5	<= r_block5;
//			r_block6	<= r_block6;
//			r_block7	<= r_block7;
//			r_block8	<= r_block8;
//			r_block9	<= r_block9;
//			r_block10	<= r_block10;
//			r_block11	<= r_block11;
//			r_block12	<= r_block12;
//			r_block13	<= r_block13;
//			r_block14	<= r_block14;
//			r_block15	<= r_block15;
//		end
	end

	// serialize block
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			o_stream <= 511'd0;
		else if(r_fsm==DONE)
			o_stream <={r_block0,  r_block1,  r_block2,  r_block3,
						r_block4,  r_block5,  r_block6,  r_block7,
						r_block8,  r_block9,  r_block10, r_block11,
						r_block12, r_block13, r_block14, r_block15};
	end

endmodule 
