module ccp_aead (
	input						i_clk, i_rstn,
	input						i_start,
	
	input						i_enc_dec,  // 1: encrypt, 0: decrypt
	input			[127:0]		i_tag,		// if use this module for decryption

	input			[255:0]		i_key,
	input			[63:0]		i_iv,
	input			[31:0]		i_constant,
	input						i_en_pt,
	input			[511:0]		i_pt,
	input			[31:0]		i_len_pt,
	
	input						i_en_ad,
	input			[127:0]		i_ad,
	input			[63:0]		i_len_ad,

	output	reg					o_rqst_pt,
	output						o_rqst_ad,
	output			[127:0]		o_tag,
	output						o_authen,	// 1 if authenticate, 0 if not
	output						o_done
);

	// ***** local parameter definition *****
//	parameter	CC_D_WIDTH	= 512;
//	parameter	CC_A_WIDTH	= 16;
	parameter	P_D_WIDTH	= 128;
	parameter	P_A_WIDTH	= 16;

	// ***** local register definition *****
	reg				r_start_d1;
	reg				r_rqst_p_d1, r_rqst_p_d2;
	reg				r_done_d1;
	reg				r_enc_dec;
	reg		[255:0] r_key;
	reg		[95:0]	r_non;
	reg		[1:0]	r_sel_p;
	reg		[64:0]	r_len_ad;
	reg		[95:0]	r_msg_len;
	reg				r_rqst_pt;
	reg				r_authen;

	// ***** local wire definition *****
	wire	[511:0]	w_otk;
	wire			w_rqst_cc;
	wire			w_done_cc;
	wire	[511:0]	w_ct;
	wire			w_busy_cc;
	wire			w_full;
	wire			w_w_ing_ram;
	wire			w_empty_ram;
	wire			w_en_r2p;
	wire	[127:0]	w_data_r2p;
	wire			w_rqst_p;
	wire	[127:0]	w_tag;

	wire	[127:0]	w_otk_r;
	wire	[127:0]	w_otk_s;
	wire			w_en_ram;
	wire	[31:0]	w_len_padpt;
	wire	[63:0]	w_len_padad;
	wire	[64:0]	w_len_msg;
	wire			w_en_p;
	wire	[127:0]	w_data_p;
	wire			w_rqst_p2r;

	// cc_block outputs key stream [511:0] with count 0, 
	// key r uses [127:0] of the key stream, and key s uses [255:128] of the key stream.
	assign	w_otk_r			=	w_otk[127:0];
	assign	w_otk_s			=	w_otk[255:128];
	// Every time cc_encrypt outputs ct, it reads a signal to ram.
	assign	w_en_ram		=	(r_enc_dec) ? (w_rqst_cc || w_done_cc) : 1'd0;
	assign	w_len_padpt		=	i_len_pt + (5'd16-i_len_pt[3:0]);
	assign	w_len_padad		= 	i_len_ad + (5'd16-i_len_ad[3:0]);
	// Poly1305 use {AD, pad(AD), CT, pad(CT), len(AD), len(CT)}
	assign	w_len_msg		=	w_len_padpt + w_len_padad + 5'd16;
	// ad 를 다 처리 하기 전 까지는 외부와 주고받기(2'b10)
	// ad 를 다 처리하고 cc_encrypt가 작동 중이면 ram에서 데이터를 받고(2'b00),
	//   cc_encrypt가 작동이 완료되고 ram이 비면 {32'd0, len(pt), len(ad)}를 마지막 입력 데이터로 넣어준다(2'b01)
	assign	w_en_p			=	(r_sel_p[1]) ? i_en_ad		: 
								(r_sel_p[0]) ? w_en_r2p 	: r_rqst_p_d2;
	assign	w_data_p		= 	(r_sel_p[1]) ? i_ad			: 
								(r_sel_p[0]) ? w_data_r2p	: {32'd0, r_msg_len};
	assign	w_rqst_p2r		=	(r_sel_p[1]) ? 1'd0			:
								(r_sel_p[0]) ? r_rqst_p_d2	: 1'd0;
	assign	o_rqst_ad		=	(r_sel_p[1]) ? r_rqst_p_d2	: 1'd0;
	assign	o_tag			=	(r_enc_dec) ? w_tag			: 128'bz;
	assign	o_authen		=	(r_enc_dec) ? 1'bz			: r_authen;
	assign	o_done			=	(r_enc_dec) ? w_done_p		: 
								(w_done_cc || w_done_p)		? ((r_done_cc && w_done_p) || (w_done_cc && r_done_p)) : 1'd0;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the DUT module *****

	cc_block U0_CC_BLOCK (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	r_start_d1	),
		
		.i_key		(	r_key		),
		.i_non		(	r_non		),
		.i_cnt		(	32'd0		),
		
		.o_stream	(	w_otk		),
		.o_done		(	w_otk_done	)
	);

	cc_encrypt U_CC_ENCRYPT (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	r_start_d1	),

		.i_en_pt	(	i_en_pt		),
		.i_key		(	r_key		),
		.i_non		(	r_non		),
		.i_pt		(	i_pt		),
		.i_len_pt	(	i_len_pt	),

		.o_rqst_pt	(	w_rqst_cc	),
		.o_done		(	w_done_cc	),
		.o_ct		(	w_ct		),
		.o_busy		(	w_busy_cc	)
	);

	ram_cc2p #(
		.D_WIDTH	(	P_D_WIDTH	),
		.A_WIDTH	(	P_A_WIDTH	)
	) U_RAM_CC2P (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_en_w		(	w_en_ram	),
		.i_en_r		(	w_rqst_p2r	),
		.i_data		(	w_ct		),

		.o_data		(	w_data_r2p	),
		.o_sig_r	(	w_en_r2p	),
		.o_full		(	w_full		),
		.o_empty	(	w_empty_ram	),
		.o_w_ing	(	w_w_ing_ram	)
	);

	p_tag U_P_TAG (
		.i_clk		(	i_clk		),
		.i_rstn		(	i_rstn		),
		.i_start	(	w_otk_done	),

		.i_key_r	(	w_otk_r		),
		.i_key_s	(	w_otk_s		),
		.i_en_msg	(	w_en_p		),
		.i_msg		(	w_data_p	),
		.i_len_msg	(	w_len_msg	),

		.o_rqst_msg	(	w_rqst_p	),
		.o_done		(	w_done_p	),
		.o_tag		(	w_tag		)
	);

////////////////////////////////////////////////////////////////////////////////

	// Explanation of always statement
	
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_sel_p	<= 2'b10;
		else begin
			if(r_enc_dec)
				r_sel_p <=	(r_len_ad != 65'd0)	? 2'b10 :
							(!w_busy_cc && w_empty_ram && !w_w_ing_ram) ? 2'b00 : 2'b01; 
			else
				r_sel_p	<=	(r_len_ad != 65'd0)	? 2'b10 : 2'b00;
		end
	end
	
	// r_start_d1 waits for values ​​such as key and msg to be stored.
	// r_rqst_p_d1 waits 
	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn) begin
			r_start_d1		<= 1'd0;
			r_rqst_p_d1		<= 1'd0;
			r_rqst_p_d2		<= 1'd0;
			r_done_d1		<= 1'd0;
		end
		else begin
			r_start_d1		<= i_start;
			r_rqst_p_d1		<= w_rqst_p;
			r_rqst_p_d2		<= r_rqst_p_d1;
		end
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if (!i_rstn)
			r_enc_dec	<= 1'd0;
		else
			r_enc_dec	<= (i_start) ? i_enc_dec : r_enc_dec;
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
			r_non	<= (i_start) ? {i_iv, i_constant} : r_non;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_len_ad	<= 65'd0;
		else if(r_start_d1)
			r_len_ad	<= (r_enc_dec) ? w_len_padad : w_len_padad+w_len_padpt;
		else if(w_rqst_p)
			r_len_ad	<= (r_len_ad<65'd16) ? 65'd0 : r_len_ad - 65'd16;
//		else
//			r_len_ad	<= r_len_ad;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_msg_len	<= 96'd0;
		else
			r_msg_len	<= (i_start) ? {i_len_pt, i_len_ad} : r_msg_len;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_rqst_pt	<=	1'd0;
		else if(w_rqst_cc)
			r_rqst_pt	<=	1'd1;
		else if(!w_full && r_rqst_pt)
			r_rqst_pt	<=	1'd0;
//		else
//			r_rqst_pt	<=	r_rqst_pt;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			o_rqst_pt	<=	1'd0;
		else
			o_rqst_pt	<=	(!w_full && r_rqst_pt) ? 1'd1 : 1'd0;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_authen	<=	1'd0;
		else if(w_done_p)
			r_authen	<=	~|(i_tag ^ w_tag);
//		else
//			r_authen	<=	r_authen;
	end

	reg	r_done_cc;
	reg	r_done_p;
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_done_cc	<=	1'd0;
		else if(w_done_cc)
//			r_done_cc	<=	(r_done_p) ? 1'd0 : 1'd1;
			r_done_cc	<=	1'd1;
//		else
//			r_done_cc	<= r_done_cc;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_done_p	<=	1'd0;
		else if(w_done_p)
//			r_done_p	<=	(r_done_cc) ? 1'd0 : 1'd1;
			r_done_p	<=	1'd1;
//		else
//			r_done_p	<= r_done_p;
	end

endmodule
