module cc_encrypt (
	input					i_clk, i_rstn,
	input					i_start,
	
	input					i_en_pt,
	input		[255:0]		i_key,
	input		[95:0]		i_non,
	input		[511:0]		i_pt,
	input		[31:0]		i_len_pt,

	output	reg	[511:0]		o_ct,
	output	reg				o_rqst_pt,
	output	wire			o_done
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
	
	parameter MASK	= 512'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

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
	wire	[511:0]	w_mask;
	
	assign	w_blk_state	= r_len_pt!=32'd0;
	assign	w_blk_start	= (i_start) || ((r_fsm == CRYPT) && i_en_pt);
	assign	w_mask		= (r_len_pt<32'd64) ? (MASK >> {32'd64-r_len_pt, 3'd0}) : MASK;
	
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
			r_cnt	<= 32'd0;
		else if (o_rqst_pt)
			r_cnt	<= r_cnt + 1'b1;
//		else
//			r_cnt	<= r_cnt;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_pt	<= 512'd0;
		else if (i_start || i_en_pt)
			r_pt	<= i_pt;
//		else
//			r_pt	<= r_pt;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_len_pt	<=	32'd0;
		else if (i_start)
			r_len_pt	<=	i_len_pt;
		else if (w_blk_done)
			r_len_pt	<=	(!r_cnt==32'd0) ? 
							(r_len_pt<32'd64) ? 32'd0 : r_len_pt - 32'd64
							: r_len_pt;
//		else
//			r_len_pt	<= r_len_pt;
	end

	// read o_ct and input pt
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
			o_ct	<=	512'd0;
		else
			o_ct	<=	(w_blk_done) ? 
						(r_cnt==32'd0) ? w_stream : w_mask & (w_stream ^ r_pt) 
						: o_ct;
	end

endmodule 
