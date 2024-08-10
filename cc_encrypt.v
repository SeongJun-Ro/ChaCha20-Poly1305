module cc_encrypt (
	input					i_clk, i_rstn,
	input					i_start,

	input		[255:0]		i_key,
	input		[95:0]		i_non,
	input		[511:0]		i_pt,
	input		[31:0]		i_len_pt,

	output	reg	[511:0]		o_ct,
	output	wire			o_done,
	output	wire			o_read_pt
);

	// ***** local parameter definition *****
//	parameter IDLE	= 2'b00;
//	parameter BLOCK	= 2'b01;
//	parameter CRYPT	= 2'b11;
//	parameter DONE	= 2'b10;
	parameter IDLE	= 2'd0;
	parameter BLOCK	= 2'd1;
	parameter CRYPT	= 2'd2;
	parameter DONE	= 2'd3;

	// ***** local register definition *****
	reg		[1:0]	r_fsm;
	reg		[255:0] r_key;
	reg		[95:0]	r_non;
	reg		[31:0]	r_cnt;
	reg		[511:0]	r_pt;
	reg		[31:0]	r_len_pt;

	// ***** local wire definition *****
	wire			w_blk_state;	// 1: have to BLOCK state
	wire			w_blk_start;	// 1: start BLOCK state
	wire			w_blk_done;		// 1: finish BLOCK state
	wire	[511:0]	w_stream;		// output 'cc_block'
	
	assign	w_blk_state	= r_len_pt!=32'd0;
	assign	w_blk_start	= (i_start) || ((r_fsm == CRYPT) && w_blk_state);
	
	assign	o_read_pt	= (w_blk_done && w_blk_state);
	assign	o_done		= (r_fsm == DONE);

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the design module *****

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

	// Explanation of always statement

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_fsm	<= IDLE;
		else
			case (r_fsm)
				IDLE	: r_fsm <= (i_start) ? BLOCK : IDLE;
				BLOCK	: r_fsm <= (w_blk_done) ? CRYPT : BLOCK;
				CRYPT	: r_fsm <= (w_blk_start) ? BLOCK : DONE;
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
		else if (o_read_pt)
			r_cnt	<= r_cnt + 1'b1;
//		else
//			r_cnt	<= r_cnt;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_pt	<= 512'd0;
		else if (i_start || o_read_pt)
			r_pt	<= i_pt;
//		else
//			r_pt	<= r_pt;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_len_pt	<= 32'd0;
		else if (i_start)
			r_len_pt	<= i_len_pt;
		else if (o_read_pt)
			r_len_pt	<= (r_len_pt<32'd64) ? 32'd0 : r_len_pt - 32'd64;
//		else
//			r_len_pt	<= r_len_pt;
	end

	// encrypt plain text
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_ct	<= 512'd0;
		else
			o_ct	<= (w_blk_done) ? w_stream ^ r_pt : o_ct;
	end

endmodule 
