import ctrl_signal_types::*;

module my_buffer (
    input logic clock,
    input logic [SRAM_DATA_WIDTH-1:0] data,
    input logic [SRAM_ADDR_WIDTH-1:0] rdaddress,
    input logic [SRAM_ADDR_WIDTH-1:0] wraddress,
    input logic wren,
    
    output logic [SRAM_DATA_WIDTH-1:0] q
);

    logic [511:0] mem [2**SRAM_ADDR_WIDTH];

    always_ff @( posedge clock ) begin
        
        if (wren) begin
            mem[wraddress] <= data;
            if (rdaddress == wraddress) begin
                q <= data;
            end else begin
                q <= mem[rdaddress];
            end
        end else begin
            q <= mem[rdaddress];
        end
    end
    
endmodule