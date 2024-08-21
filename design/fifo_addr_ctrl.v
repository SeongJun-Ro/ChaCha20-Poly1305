module fifo_addr_ctrl (
	input			i_clk, i_rstn,
	input			i_w_en, i_r_en,
	input	[511:0]	i_data,
	
	output	[127:0]	o_data,
	output	reg		o_sig
);
	
	// ***** local parameter definition *****
	parameter	D_WIDTH = 128;
	parameter	A_WIDTH = 3;

	// ***** local register definition *****
	reg		[A_WIDTH-1:0]	r_addr_w, r_addr_r;
	reg		[511:0]			r_stream;
	reg		[2:0]			r_cnt_w;

	// ***** local wire definition *****
	wire			w_en_w;
	wire	[127:0]	w_stream;
	
	assign	w_en_w		= (r_cnt_w!=3'd0);
	assign	w_stream	= r_stream[127:0];

////////////////////////////////////////////////////////////////////////////////

	ram_dual_sync #(
		.D_WIDTH	(	D_WIDTH		),
		.A_WIDTH	(	A_WIDTH		)
	) RAM_DUAL_SYNC (
		.w_clk		(	i_clk		),
		.r_clk		(	i_clk		),
		.w_en		(	w_en_w		),
		.w_addr		(	r_addr_w	),
		.w_data		(	w_stream	),
		.r_en		(	i_r_en		),
		.r_addr		(	r_addr_r	),
		.r_data		(	o_data		)
	);

////////////////////////////////////////////////////////////////////////////////

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_stream	<= 512'd0;
		else if(i_w_en)
			r_stream	<= i_data;
		else if(r_cnt_w!=0)
			r_stream	<= {128'd0, r_stream[511:128]};
//		else
//			r_steam		<= r_stream;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_cnt_w	<=	3'd0;
		else
			r_cnt_w	<=	(r_cnt_w==3'd4) ? 3'd0 :
						(i_w_en || (r_cnt_w!=3'd0)) ? r_cnt_w + 1'b1 : r_cnt_w;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_addr_w	<=	3'd0;
		else if(w_en_w)
			r_addr_w	<=	r_addr_w + 1'b1;
		else
			r_addr_w	<=	(r_cnt_w!=3'd0) ? r_addr_w + 1'b1 : r_addr_w;
	end

	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			r_addr_r	<=	3'd0;
		else
			r_addr_r	<=	(i_r_en) ? r_addr_r + 1'b1 : r_addr_r;
	end


	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn)
			o_sig	<=	1'd0;
		else
			o_sig	<=	i_r_en;
	end

endmodule
