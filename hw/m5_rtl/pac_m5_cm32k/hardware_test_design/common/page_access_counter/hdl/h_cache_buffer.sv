module h_cache_buffer #(
    parameter NUM_ENTRIES = 8192,
    parameter ENTRY_WDITH = 64,
    parameter NUM_IDX_BIT = $clog2(NUM_ENTRIES)
)(
   input logic                     clk,
   input logic                     reset_n,

   // read by CSR unit
   input logic[NUM_IDX_BIT-1:0]    rd_idx,
   input logic                     rd_en,
   output logic[ENTRY_WDITH-1:0]              cache_addr_o,
   // Output to CSR unit / M5 manager
   output logic[NUM_IDX_BIT-1:0]   wr_idx_o,
   output logic                    wr_overflow,
   // reset write idx by CSR unit
   input logic                     wr_idx_rst,
    
   // write by tracker
   input logic                     wr_en,
   input logic[ENTRY_WDITH-1:0]    cache_addr_i
);
    logic[NUM_IDX_BIT-1:0]    wr_idx;
    logic wr_en_guard;
    assign wr_en_guard = wr_en & (wr_idx != '1);

	w64_d8192 bram_w64_d8192_inst (
		.data      (cache_addr_i),      //   input,  width = 64,      data.datain
		.q         (cache_addr_o),      //  output,  width = 64,         q.dataout
		.wraddress (wr_idx),  //   input,  width = 13, wraddress.wraddress
		.rdaddress (rd_idx),  //   input,  width = 13, rdaddress.rdaddress
		.wren      (wr_en),   //   input,   width = 1,      wren.wren
		.clock     (clk),     //   input,   width = 1,     clock.clk
        .sclr      (~reset_n)
	);

    assign wr_idx_o = wr_idx;

    task do_reset();
        wr_idx <= '0;
    endtask

    task do_write();
        if (wr_en) begin
            if (wr_idx != '1) begin
                wr_idx <= wr_idx + 'b1;
            end
            // otherwise, assert overflow in comb
        end
    endtask

    task do_wr_idx_rst();
        if (wr_idx_rst) begin
            wr_idx <= 'b0;
        end
    endtask

    always_ff@(posedge clk) begin
        if(~reset_n) begin
            do_reset();
        end else begin
            do_write();
            do_wr_idx_rst();
        end
    end

    always_comb begin
        wr_overflow = 1'b0;
        // just to let the user know there is an overflow
        //      This is an indication that the user should pull faster
        //      Which should reset the wr_idx faster
        if (wr_en && wr_idx == '1) begin
            wr_overflow = 1'b1;
        end
    end
endmodule

