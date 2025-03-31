/* This stretcher stretches the signal for certain cycles 
    The signal must be positively asserted.
*/
module stretcher #(
    parameter STRETCH_LENGTH = 5,
    parameter SIGNAL_WIDTH = 1
)(
    input logic                     clk,
    input logic  [SIGNAL_WIDTH-1:0] signal_in,
    output logic [SIGNAL_WIDTH-1:0] signal_out
);

    logic [$clog2(STRETCH_LENGTH)-1:0] cnt;
    logic [SIGNAL_WIDTH-1:0] signal_buf;

    assign signal_out = (cnt > 0) ? signal_buf : '0;

    always_ff @( posedge clk ) begin
        if (signal_in) begin
            cnt <= STRETCH_LENGTH;
        end else begin
            cnt <= (cnt > 0) ? (cnt - 1) : 0;
        end

        signal_buf <= signal_in;
    end
    
endmodule