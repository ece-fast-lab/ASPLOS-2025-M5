module hash_computation 
#(
  parameter W = 4096,
  parameter NUM_HASH = 4,
  parameter HASH_SIZE = $clog2(W),
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                        clk,
  input                        rst_n,

  input                        input_valid,
  input        [ADDR_SIZE-1:0] input_addr,

  output logic                 output_valid,
  output logic [ADDR_SIZE-1:0] output_addr,
  output       [HASH_SIZE-1:0] hash_value [0:NUM_HASH-1]
);
  
  /////////////////////////////////////////////////////////////
  logic  [ADDR_SIZE-1:0] addr, addr_d1, addr_d2, addr_d3, addr_d4, addr_d5;
  logic                  valid, valid_d1, valid_d2, valid_d3, valid_d4, valid_d5;
  logic  [HASH_SIZE-1:0] q_debug [0:NUM_HASH-1][0:31];

  genvar i;

  /////////////////////////////////////////////////////////////
  // valid, address pipeline
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      addr         <= {ADDR_SIZE{1'b0}};
      addr_d1      <= {ADDR_SIZE{1'b0}};
      addr_d2      <= {ADDR_SIZE{1'b0}};
      addr_d3      <= {ADDR_SIZE{1'b0}};
      addr_d4      <= {ADDR_SIZE{1'b0}};
      addr_d5      <= {ADDR_SIZE{1'b0}};
      output_addr  <= {ADDR_SIZE{1'b0}};
      valid        <= 1'b0;
      valid_d1     <= 1'b0;
      valid_d2     <= 1'b0;
      valid_d3     <= 1'b0;
      valid_d4     <= 1'b0;
      valid_d5     <= 1'b0;
      output_valid <= 1'b0;
    end
    else begin
      addr         <= input_addr;
      addr_d1      <= addr;
      addr_d2      <= addr_d1;
      addr_d3      <= addr_d2;
      addr_d4      <= addr_d3;
      addr_d5      <= addr_d4;
      output_addr  <= addr_d5;
      valid        <= input_valid;
      valid_d1     <= valid;
      valid_d2     <= valid_d1;
      valid_d3     <= valid_d2;
      valid_d4     <= valid_d3;
      valid_d5     <= valid_d4;
      output_valid <= valid_d5;
    end
  end

  /////////////////////////////////////////////////////////////
  // Hash computation instantiation 
  generate 
    for (i = 0; i < NUM_HASH; i++) begin : hash_compute
      one_hash_computation
      #(
        .W(W),
        .HASH_SIZE(HASH_SIZE),
        .ADDR_SIZE(ADDR_SIZE),
        .CNT_SIZE(CNT_SIZE)
      ) 
        compute_one_hash
      (
        // Input
        .clk(clk),
        .rst_n(rst_n),

        .input_addr(addr),

        // Output
        .hash_value(hash_value[i]),

        // For simulation debug
        .q_debug(q_debug[i])
      );
    end
  endgenerate

endmodule


