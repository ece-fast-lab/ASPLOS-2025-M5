module request_fifo #(WIDTH = 640, DEPTH = 32) (
    input   logic                   clk,
    input   logic                   reset_n,
    // pop
    input   logic                   pop_en,
    output  logic [WIDTH-1:0]       data_out,
    // push
    input   logic                   push_en,
    input   logic [WIDTH-1:0]       data_in,
    // status
    output  logic                   empty,
    output  logic                   full
);

    logic [$clog2(DEPTH)-1:0] read_ptr, write_ptr, write_ptr_next;
    logic [WIDTH-1:0] fifo [DEPTH];

    always_ff @( posedge clk ) begin
        if (!reset_n) begin
            read_ptr    <= 'b0;
            write_ptr   <= 'b0;
        end else begin

            if (pop_en & !empty) begin
                // data_out <= fifo[read_ptr];
                read_ptr <= read_ptr + 1;
            end

            if (push_en & !full) begin
                fifo[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1;
            end

        end
    end

    always_comb begin
        data_out = fifo[read_ptr];
        write_ptr_next = write_ptr + 1;
        empty = (read_ptr == write_ptr);
        full = (read_ptr == write_ptr_next); 
    end
    
endmodule