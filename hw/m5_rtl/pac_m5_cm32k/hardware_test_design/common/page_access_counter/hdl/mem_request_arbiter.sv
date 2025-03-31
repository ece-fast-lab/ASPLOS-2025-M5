import ctrl_signal_types::*;

module mem_request_arbiter (
    input   logic           sel,
    input   mem_request_t   request_in_1,
    input   mem_request_t   request_in_2,
    output  mem_request_t   request_out
);

    always_comb begin
        if (sel) begin
            request_out = request_in_2;
        end else begin
            request_out = request_in_1;
        end
    end
    
endmodule
