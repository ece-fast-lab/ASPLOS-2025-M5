import ctrl_signal_types::mem_request_t;

module priority_arbiter #(
    parameter NUM_INPUT_PORT = 2
)(
    input logic clk,

    input  logic [NUM_INPUT_PORT-1:0] req,
    output logic [NUM_INPUT_PORT-1:0] grant

    // input  mem_request_t in_request [NUM_INPUT_PORT],
    // output mem_request_t out_request
);

    assign grant[0] = req[0];

    genvar i;

    for (i = 1; i < NUM_INPUT_PORT; i++) begin
        assign grant[i] = req[i] & ~(| req[i-1:0]);
    end

    // always_comb begin
    //     for (int i = 0; i < NUM_INPUT_PORT; i++) begin
    //         if (grant[i]) begin
    //             out_request = in_request[i];
    //             break;
    //         end
    //     end
    // end
    
endmodule