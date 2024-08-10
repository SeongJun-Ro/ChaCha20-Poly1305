module cc_encrypt (
	input					i_clk, i_rstn,
	input					i_start,

	input		[255:0]		i_key,
	input		[95:0]		i_non,
	input		[511:0]		i_pt,
	input		[31:0]		i_len_pt,

	output	reg	[511:0]		o_ct,
	output	wire			o_done
);

	// ***** local parameter definition *****
	parameter IDLE	= 3'd0;
	parameter RDY	= 3'd1;
	parameter BLOCK	= 3'd1;
	parameter CRYPT	= 3'd2;
	parameter DONE	= 3'd3;

	// ***** local register definition *****

	// ***** local wire definition *****
	wire			w_blk_state;	// 1: have to BLOCK state
	wire			w_blk_start;	// 1: start BLOCK state
	wire			w_blk_done;		// 1: finish BLOCK state
	wire	[511:0]	w_stream;		// output 'cc_block'
	
	assign	w_blk_state	= |r_len_pt[31:6];	// len of pt that not crypt is big than 64byte
	assign	w_blk_start	= (r_fsm == RDY) || ((r_fsm == CRYPT) && w_blk_state);

	assign	o_done = (r_fsm == DONE);

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
			r_len_pt	<= r_len_pt - 10'd64;
		else
			r_len_pt	<= r_len_pt;
	end

	// o_ct
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_ct	<= 512'd0;
		else
			o_ct	<= (r_fsm == CRYPT) ? o_ct ^ r_pt : o_ct;
	end

	reg [31:0] r_cnt;
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt	<= 31'd1;
		else if ((r_fsm == BLOCK) && w_blk_done)
			r_cnt	<= r_cnt + 1'b1;
		else
			r_cnt	<= r_cnt;
	end

endmodule 
