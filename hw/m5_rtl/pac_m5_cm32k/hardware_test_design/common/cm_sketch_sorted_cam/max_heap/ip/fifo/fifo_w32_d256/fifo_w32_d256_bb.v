module fifo_w32_d256 (
		input  wire [31:0] data,  //  fifo_input.datain
		input  wire        wrreq, //            .wrreq
		input  wire        rdreq, //            .rdreq
		input  wire        clock, //            .clk
		output wire [31:0] q,     // fifo_output.dataout
		output wire [7:0]  usedw, //            .usedw
		output wire        full,  //            .full
		output wire        empty  //            .empty
	);
endmodule

