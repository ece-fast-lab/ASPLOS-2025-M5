
module bus_synchronizer #(
    parameter SIGNAL_WIDTH = 1
)(
    input logic clk,
    input logic [SIGNAL_WIDTH-1:0] data_in,
    output logic [SIGNAL_WIDTH-1:0] data_out
);
    
    generate
        for (genvar i = 0; i < SIGNAL_WIDTH; i++) begin : bus_synchronizer_generate_block
            altera_std_synchronizer_nocut #(
                .depth(3)
            ) bus_synchronizer_inst (
                .clk            (clk),
                .reset_n        (1'b1),
                .din            (data_in[i]),
                .dout           (data_out[i])
            );
        end
    endgenerate
    

endmodule