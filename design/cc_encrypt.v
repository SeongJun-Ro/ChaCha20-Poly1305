module cc_encrypt (
	input					i_clk, i_rstn,
	input					i_start,		// module start

	input					i_en_pt,		// enable plaintext
	input		[255:0]		i_key,			// key
	input		[95:0]		i_non,			// nonce
	input		[511:0]		i_pt,			// plaintext
	input		[31:0]		i_len_pt,		// plaintext length

	output	reg	[511:0]		o_ct,			// ciphertext
	output	reg				o_rqst_pt,		// request plaintext & using 'o_ct'
	output	wire			o_done			// module done & using final 'o_ct'
);

	// fsm parameter
	parameter IDLE	= 2'b00;
	parameter BLOCK	= 2'b01;
	parameter CRYPT	= 2'b11;
	parameter DONE	= 2'b10;
	// mask parameter
	parameter MASK	= 512'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

	reg		[1:0]	r_fsm;
	reg		[255:0] r_key;
	reg		[95:0]	r_non;
	reg		[31:0]	r_cnt;
	reg		[511:0]	r_pt;
	reg		[31:0]	r_len_pt;

	wire			w_blk_state;	// 1: have to BLOCK state
	wire			w_blk_start;	// 1: start BLOCK state
	wire			w_blk_done;		// 1: finish BLOCK state
	wire	[511:0]	w_stream;		// output 'cc_block'
	wire	[511:0]	w_mask;

	// If r_len_pt is not 0, it means there are still plaintexts to be processed
	// 0 if r_len_pt is 0, 1 otherwise
	assign	w_blk_state	= r_len_pt!=32'd0;
	// start signal for 'U1_CC_BLOCK'
	// w_blk_state is not 0, wait i_en_pt high
	assign	w_blk_start	= (i_start) || ((r_fsm == CRYPT) && i_en_pt);
	// if the r_pt_len to process is less than 64, mask the data that is not applicable
	assign	w_mask		= (r_len_pt<32'd64) ? (MASK >> {32'd64-r_len_pt, 3'd0}) : MASK;
	// 1 when the module is done
	assign	o_done		= (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	cc_block U1_CC_BLOCK (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	w_blk_start	),
		.i_key		(	i_key		),
		.i_non		(	i_non		),
		.i_cnt		(	r_cnt		),
		.o_stream	(	w_stream	),
		.o_done		(	w_blk_done	)
	);

////////////////////////////////////////////////////////////////////////////////

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_fsm	<= IDLE;
		else
			case (r_fsm)
				IDLE	: r_fsm <=	(i_start)		? BLOCK : IDLE;
				BLOCK	: r_fsm <=	(w_blk_done)	? CRYPT : BLOCK;
				CRYPT	: r_fsm <=	(!w_blk_state)	? DONE :
									(w_blk_start)	? BLOCK : CRYPT;
				DONE	: r_fsm <= IDLE;
			endcase
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_key	<= 256'd0;
		else
			r_key	<= (i_start) ? i_key : r_key;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_non	<= 96'd0;
		else
			r_non	<= (i_start) ? i_non : r_non;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt	<= 32'd1;
		else if (o_rqst_pt)
			r_cnt	<= r_cnt + 1'b1;
//		else
//			r_cnt	<= r_cnt;
	end

	// if module start or enable plaintext, load i_pt
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_pt	<= 512'd0;
		else if (i_start || i_en_pt)
			r_pt	<= i_pt;
//		else
//			r_pt	<= r_pt;
	end

	// after the BLOCK state is completed, r_len_pt is reduced by 16
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_len_pt	<= 32'd0;
		else if (i_start)
			r_len_pt	<= i_len_pt;
		else if (w_blk_done)
			r_len_pt	<= (r_len_pt<32'd64) ? 32'd0 : r_len_pt - 32'd64;
//		else
//			r_len_pt	<= r_len_pt;
	end

	// request plaintext & use o_ct signal
	// if w_blk_state is 1 when the BLOCK state is completed, 1 otherwise, 0
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_rqst_pt	<= 1'd0;
		else if (w_blk_done && w_blk_state)
			o_rqst_pt	<= (r_len_pt<32'd64) ? 1'b0 : 1'b1;
		else
			o_rqst_pt	<= 1'd0;
	end

	// encrypt plain text
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_ct	<= 512'd0;
		else
			o_ct	<= (w_blk_done) ? w_mask & (w_stream ^ r_pt) : o_ct;
	end

endmodule
