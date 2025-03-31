import ctrl_signal_types::mem_request_t;

module roundrobin_arbiter #(
    parameter NUM_INPUT_PORT = 2
)(
    input logic clk,
    input logic reset_n,

    input  logic out_port_ready,
    input  logic [NUM_INPUT_PORT-1:0] req,
    output logic [NUM_INPUT_PORT-1:0] grant,
    
    input  mem_request_t in_request [NUM_INPUT_PORT],
    output mem_request_t out_request

);

    logic [NUM_INPUT_PORT-1:0] mask, mask_next;
    logic [NUM_INPUT_PORT-1:0] masked_req;
    logic [NUM_INPUT_PORT-1:0] grant_masked, grant_unmasked;
    logic [NUM_INPUT_PORT-1:0] grant_if_ready;
    // mem_request_t masked_arbiter_out, unmasked_arbiter_out;

    priority_arbiter #(
        .NUM_INPUT_PORT(NUM_INPUT_PORT)
    ) arbiter_inst (
        .clk(clk),
        .req(req),
        .grant(grant_unmasked)
    );

    priority_arbiter #(
        .NUM_INPUT_PORT(NUM_INPUT_PORT)
    ) masked_arbiter_inst (
        .clk(clk),
        .req(masked_req),
        .grant(grant_masked)
    );

    assign masked_req = mask & req;
    assign grant_if_ready = (masked_req == '0) ? grant_unmasked : grant_masked; // If no req after masking, revert back to priority arbiter
    assign grant = grant_if_ready & NUM_INPUT_PORT'(signed'(out_port_ready)); // If output port is not ready, grant nothing.

    always_comb begin
        /* Mask out the requests before the port that has just been granted (if there is any) */
        mask_next = '1; // FIXED: this line should be outside of the if statement
        if (grant != '0) begin
            for (int i = 0; i < NUM_INPUT_PORT; i++) begin
                mask_next[i] = 1'b0;
                if (grant[i]) begin
                    break;
                end
            end
        end

        /* select output request based on grant */
        out_request = '0;
        if (masked_req == '0) begin
            for (int i = 0; i < NUM_INPUT_PORT; i++) begin
                if (grant_unmasked[i]) out_request = in_request[i];
            end
        end else begin
            for (int i = 0; i < NUM_INPUT_PORT; i++) begin
                if (grant_masked[i]) out_request = in_request[i];
            end
        end
    end

    always_ff @( posedge clk ) begin : mask_update
        if (~reset_n) begin
            mask <= '1;
        end else begin
            mask <= mask_next;
        end
    end


    
endmodule