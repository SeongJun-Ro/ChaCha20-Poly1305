// `define TEST

module ram_cc2p (
	input					i_clk, i_rstn,
	input					i_en_w, i_en_r,
	input			[511:0]	i_data,

	output			[127:0]	o_data,
	output	reg				o_sig,
//	output	reg				o_full,
//	output	reg				o_empty
	output					o_full,
	output	reg				o_empty
);

	// ***** local parameter definition *****
	parameter	D_WIDTH = 128;
	parameter	A_WIDTH = 3;

	// ***** local register definition *****
	reg		[A_WIDTH:0]		r_addr_w, r_addr_r;
	reg		[511:0]			r_stream;
	reg		[2:0]			r_cnt_w;
	reg						r_empty_d1;
	reg						r_en_r;

	// ***** local wire definition *****
	wire					w_en_w;
	wire	[A_WIDTH-1:0]	w_addr_w, w_addr_r;
	wire	[127:0]			w_stream;
	wire	[A_WIDTH:0]		w_chk_full;

	assign	w_en_w		=	(r_cnt_w!=3'd0);
	assign	w_addr_w	=	r_addr_w[A_WIDTH-1:0];
	assign	w_addr_r	=	r_addr_r[A_WIDTH-1:0];
	assign	w_stream	=	r_stream[127:0];
	assign	w_chk_full	=	r_addr_w + 3'd4;
	
	assign o_full		=	((w_chk_full[A_WIDTH]!=r_addr_r[A_WIDTH]) && (w_chk_full[A_WIDTH-1:0]>=r_addr_r[A_WIDTH-1:0])) ? 1'd1 : 1'd0;

////////////////////////////////////////////////////////////////////////////////

	// ***** Instantiate the design module *****

	rams_dist #(
		.D_WIDTH	(	D_WIDTH		),
		.A_WIDTH	(	A_WIDTH		)
	) U0_RAMS_DIST (
		.clk		(	i_clk		),
		.we			(	w_en_w		),
		.a			(	w_addr_w	),
		.dpra		(	w_addr_r	),
		.di			(	w_stream	),
		.spo		(				),
		.dpo		(	o_data		)
	);

////////////////////////////////////////////////////////////////////////////////

	// Explanation of always statement

`ifdef TEST
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_addr_w	<=	4'd1;
		else
			r_addr_w	<=	(w_en_w || r_cnt_w!=3'd0) ? r_addr_w + 1'd1 : r_addr_w;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_addr_r	<=	4'd0;
		else
			r_addr_r	<=	(r_en_r && !o_empty) ? r_addr_r + 1'd1 : r_addr_r;
	end
`else
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_addr_w	<=	17'd1;
		else
			r_addr_w	<=	(w_en_w || r_cnt_w!=3'd0) ? r_addr_w + 1'd1 : r_addr_w;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_addr_r	<=	17'd0;
		else
			r_addr_r	<=	(i_en_r) ? r_addr_r + 1'd1 : r_addr_r;
	end
`endif

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_stream	<= 512'd0;
		else if(i_en_w)
			r_stream	<= i_data;
		else if(r_cnt_w!=3'd0)
			r_stream	<= {128'd0, r_stream[511:128]};
//		else
//			r_steam		<= r_stream;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_cnt_w	<=	3'd0;
		else
			r_cnt_w	<=	(r_cnt_w==3'd4) ? 3'd0 :
						(i_en_w || (r_cnt_w!=3'd0)) ? r_cnt_w + 1'd1 : r_cnt_w;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_empty_d1	<=	1'd0;
		else
			r_empty_d1	<=	o_empty;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_en_r	<=	1'd0;
		else if(i_en_r)
			r_en_r	<=	1'd1;
		else if(!o_empty && r_empty_d1)
			r_en_r	<=	1'd0;
		else if(!o_empty && r_en_r)
			r_en_r	<=	1'd0;
		else
			r_en_r	<=	r_en_r;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			o_sig	<=	1'd0;
		else if(r_en_r && !o_empty && r_empty_d1)
			o_sig	<=	1'd1;
		else if(!o_empty && r_en_r)
			o_sig	<=	1'd1;
		else
			o_sig	<=	1'd0;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			o_empty	<=	1'd0;
		else
			o_empty	<=	(w_addr_w==w_addr_r+1'b1) ? 1'd1 : 1'd0;
	end

endmodule
