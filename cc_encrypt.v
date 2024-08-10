module cc_encrypt (
	input					i_clk, i_rstn,
	input					i_start,

	input		[255:0]		i_key,
	input		[95:0]		i_non,
	input		[511:0]		i_pt,
	input		[31:0]		i_len_pt,

	output	reg	[511:0]		o_ct0, o_ct1,
	output	wire			o_done,
	output	wire			o_key_done
);

	// ***** local parameter definition *****
	parameter IDLE	= 3'b000;
	parameter RDY	= 3'b001;
	parameter BLOCK	= 3'b010;
	parameter CRYPT	= 3'b110;
	parameter DONE	= 3'b100;

	// ***** local register definition *****

	// ***** local wire definition *****
	wire			w_blk_done, w_blk_done0, w_blk_done1;	// 1: finish BLOCK state
	wire			w_blk_state;							// 1: have to BLOCK state
	wire			w_blk_start;							// 1: start BLOCK state
	wire	[31:0]	w_blk0_cnt, w_blk1_cnt;					// U0_CC_BLOCK: cnt*2, U1_CC_BLOCK: cnt*2+1
	wire	[511:0]	w_stream0, w_stream1;					// output 'cc_block'

	assign	w_blk_done	= w_blk0_done && w_blk1_done;
	assign	w_blk_state	= (!r_cnt) ? |r_len_pt[31:6] : |r_len_pt[31:7];	// len of pt that not crypt is big than 64byte & 128byte
	assign	w_blk_start	= (r_fsm == RDY) || ((r_fsm == CRYPT) && w_blk_state);
	assign	w_blk0_cnt	= {r_cnt, 1'b0};
	assign	w_blk1_cnt	= {r_cnt, 1'b1};

	assign	o_done = (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the design module *****

	cc_block U0_CC_BLOCK (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	w_blk_start	),
		.i_key		(	r_key		),
		.i_non		(	r_non		),
		.i_cnt		(	w_blk0_cnt	),

		.o_stream	(	w_stream0	),
		.o_done		(	w_blk0_done	)
	);

	cc_block U1_CC_BLOCK (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	w_blk_start	),
		.i_key		(	r_key		),
		.i_non		(	r_non		),
		.i_cnt		(	w_blk1_cnt	),

		.o_stream	(	w_stream1	),
		.o_done		(	w_blk1_done	)
	);

////////////////////////////////////////////////////////////////////////////////

	// Explanation of always statement

	reg	[2:0]	r_fsm;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_fsm	<= IDLE;
		else
			case (r_fsm)
				IDLE	: r_fsm <= (i_start) ? RDY : IDLE;
				RDY		: r_fsm <= BLOCK;
				BLOCK	: r_fsm <= (w_blk_done) ? CRYPT : BLOCK;
				CRYPT	: r_fsm <= (w_blk_start) ? BLOCK : DONE;
				DONE	: r_fsm <= IDLE;
			endcase
	end

	reg	[255:0] r_key;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_key	<= 256'd0;
		else
			r_key	<= (i_start) ? i_key : r_key;
	end

	reg [95:0] r_non;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_non	<= 96'd0;
		else
			r_non	<= (i_start) ? i_non : r_non;
	end

	reg	[511:0] r_pt;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_pt	<= 1024'd0;
		else
			r_pt	<= (i_start) ? i_pt : r_pt;
	end

	reg	[31:0] r_len_pt;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_len_pt	<= 32'd0;
		else if (i_start)
			r_len_pt	<= i_len_pt;
		else if (((r_fsm == RDY) || (r_fsm == CRYPT)) && (w_blk_state))
			r_len_pt	<= (!r_cnt) ? r_len_pt - 7'd64 : r_len_pt - 8'd128;
		else
			r_len_pt	<= r_len_pt;
	end

	// o_ct0
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_ct0	<= 512'd0;
		else
			o_ct0	<= (r_fsm == CRYPT) ? o_ct ^ r_pt : o_ct0;
	end
	
	// o_ct1
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_ct1	<= 512'd0;
		else
			o_ct1	<= (r_fsm == CRYPT) ? o_ct1 ^ r_pt : o_ct1;
	end

	reg [30:0] r_cnt;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt	<= 31'd0;
		else if ((r_fsm == BLOCK) && w_blk_done)
			r_cnt	<= r_cnt + 1'b1;
		else
			r_cnt	<= r_cnt;
	end

endmodule 
