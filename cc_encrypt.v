module cc_encrypt (
	input					i_clk, i_rstn,
	input					i_enc,
	input		[255:0]		i_key,
	input		[95:0]		i_non,
	input		[1023:0]	i_pt,
	input		[9:0]		i_pt_len,  // test vecter is 912bit 114byte
	
	output		[255:0]		o_poly_key,
	output	reg	[1023:0]	o_ct
);

	// ***** local parameter definition *****
	parameter IDLE	= 3'd0;
	parameter LOAD	= 3'd1;
	parameter BLOCK	= 3'd2;
	parameter XOR	= 3'd3;
	parameter DONE	= 3'd4;

	// ***** local register definition *****
	reg		[255:0]		r_key;
	reg		[95:0]		r_non;
	reg		[1023:0]	r_pt;
	reg		[15:0]		r_pt_len;
	reg		[2:0]		r_fsm;
	reg		[2:0]		r_fsm_d1;
	reg		[31:0]		r_cnt_block;

	// ***** local wire definition *****
	wire	[7:0]		w_rnd_block;
	wire	[9:0]		w_pt_mod;
	wire				w_start_block;
	wire				w_done_block;
	wire	[511:0]		w_stream;

	assign w_rnd_block		= r_pt_len / 512 + 1;  // if len==912: w_rnd_block = 1.xxx
	assign w_pt_mod			= r_pt_len - (512*(r_cnt_block-1));
	assign w_start_block	= (((r_fsm==BLOCK)&&(r_fsm_d1==LOAD)) || ((w_done_block)&&(w_rnd_block!=r_cnt_block)));
//	assign o_poly_key		= w_poly_key[511:256]; 

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the design module *****
	cc_block	U0_CC_BLOCK (
		.i_clk		(	i_clk			),
		.i_rstn		(	i_rstn			),
		.i_qr		(	w_start_block	),
		.i_key		(	r_key			),
		.i_non		(	r_non			),
		.i_cnt		(	r_cnt_block		),

		.o_done		(	w_done_block	),
		.o_block	(	w_stream		)
	);

//	cc_block	U1_CC_BLOCK (
//		.i_clk		(	i_clk					),
//		.i_rstn		(	i_rstn					),
//		.i_qr		(	w_start_block			),
//		.i_key		(	r_key					),
//		.i_non		(	r_non					),
//		.i_cnt		(	r_cnt_block	),
//
//		.o_done		(	w_done_block[1]			),
//		.o_block	(	w_stream[511:0]			)
//	);
//
//	cc_block	U2_CC_BLOCK (
//		.i_clk		(	i_clk					),
//		.i_rstn		(	i_rstn					),
//		.i_qr		(	w_start_block			),
//		.i_key		(	r_key					),
//		.i_non		(	r_non					),
//		.i_cnt		(	r_cnt_block	),
//
//		.o_done		(	w_done_block[2]			),
//		.o_block	(	w_stream[1023:512]		)
//	);

////////////////////////////////////////////////////////////////////////////////

	// Explanation of always statement

	// [2:0] r_fsm
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_fsm <= IDLE;
		else
			case(r_fsm)
				IDLE	: r_fsm <= (i_enc) ? LOAD	: IDLE;
				LOAD	: r_fsm <= BLOCK;
				BLOCK	: r_fsm <= ((w_rnd_block==r_cnt_block) && (w_done_block)) ? XOR : BLOCK;
				XOR		: r_fsm <= DONE;
				DONE	: r_fsm <= IDLE;
			endcase
	end
	
	// r_fsm_d1
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_fsm_d1 <= 3'd0;
		else
			r_fsm_d1 <= r_fsm;
	end

	// [255:0] r_key
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_key <= 256'd0;
		else if (r_fsm==LOAD)
			r_key <= i_key;
//		else
//			r_key <= r_key;
	end

	// [95:0] r_non
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_non <= 96'd0;
		else if (r_fsm==LOAD)
			r_non <= i_non;
//		else
//			r_non <= r_non;
	end

	// [1023:0] r_pt
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_pt <= 1024'd0;
		else if (r_fsm==LOAD)
			r_pt <= i_pt;
//		else
//			r_pt <= r_pt;
	end

	// [15:0] r_pt_len
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_pt_len <= 16'd0;
		else if (r_fsm==LOAD)
			r_pt_len <= i_pt_len;
//		else
//			r_pt_len <= r_pt_len;
	end

	// r_cnt_block
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_cnt_block <= 8'd0;
		else
			r_cnt_block <= (w_done_block) ? r_cnt_block + 1'b1 : r_cnt_block;
	end

	// [1023:0] o_ct
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			o_ct <= 1024'd0;
		else if (r_fsm==XOR)
			o_ct <= r_pt ^ o_ct;
//		else
//			o_ct <= o_ct;
	end

//	// r_
//	always @(posedge i_clk, negedge i_rstn) begin
//		if (!i_rstn)
//		
//		else if ()
//		
//		else
//		
//	end

endmodule 