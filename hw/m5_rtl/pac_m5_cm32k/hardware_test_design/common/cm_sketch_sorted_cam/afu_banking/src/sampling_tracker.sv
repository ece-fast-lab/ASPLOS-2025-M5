module sampling_tracker 
#(
  // common parameter
  parameter ADDR_SIZE = 22
)
(
  input                        clk,
  input                        rst_n,

  input [ADDR_SIZE-1:0]        input_addr,
  input                        input_addr_valid,
  output logic                 input_addr_ready,

  // hot tracker interface
  input                         query_en,
  output logic                  query_ready,
  output logic                  mig_addr_en,
  output logic [ADDR_SIZE-1:0]  mig_addr,
  input                         mig_addr_ready
);

  logic [ADDR_SIZE-1:0]     addr_r;  
  assign mig_addr = addr_r;
  assign input_addr_ready = 1'b1;
  assign query_ready = 1'b1;

  always_ff @(posedge clk) begin
    if(!rst_n) begin
      mig_addr_en <= 1'b0;
      addr_r <= '0;
    end else begin
      addr_r <= addr_r;
      mig_addr_en <= query_en;
      if (input_addr_valid) begin
        addr_r <= input_addr;
      end
    end
  end
endmodule


