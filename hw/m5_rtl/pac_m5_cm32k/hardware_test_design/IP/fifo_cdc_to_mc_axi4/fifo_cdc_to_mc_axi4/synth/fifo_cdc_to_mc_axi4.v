// fifo_cdc_to_mc_axi4.v

// Generated using ACDS version 23.3 104

`timescale 1 ps / 1 ps
module fifo_cdc_to_mc_axi4 (
		input  wire [1023:0] data,    //  fifo_input.datain
		input  wire          wrreq,   //            .wrreq
		input  wire          rdreq,   //            .rdreq
		input  wire          wrclk,   //            .wrclk
		input  wire          rdclk,   //            .rdclk
		output wire [1023:0] q,       // fifo_output.dataout
		output wire          rdempty, //            .rdempty
		output wire          wrfull   //            .wrfull
	);

	fifo_cdc_to_mc_axi4_fifo_1923_jz4pbri fifo_0 (
		.data    (data),    //   input,  width = 1024,  fifo_input.datain
		.wrreq   (wrreq),   //   input,     width = 1,            .wrreq
		.rdreq   (rdreq),   //   input,     width = 1,            .rdreq
		.wrclk   (wrclk),   //   input,     width = 1,            .wrclk
		.rdclk   (rdclk),   //   input,     width = 1,            .rdclk
		.q       (q),       //  output,  width = 1024, fifo_output.dataout
		.rdempty (rdempty), //  output,     width = 1,            .rdempty
		.wrfull  (wrfull)   //  output,     width = 1,            .wrfull
	);

endmodule
