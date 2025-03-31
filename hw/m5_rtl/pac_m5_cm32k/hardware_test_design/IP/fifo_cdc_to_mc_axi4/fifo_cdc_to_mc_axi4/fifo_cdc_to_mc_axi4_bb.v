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
endmodule

