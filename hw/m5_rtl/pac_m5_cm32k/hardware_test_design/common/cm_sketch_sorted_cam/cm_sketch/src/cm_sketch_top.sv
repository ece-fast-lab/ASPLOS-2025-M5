module cm_sketch_top
#(
  parameter W = 4096,
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter HASH_SIZE = $clog2(W),
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                        clk,
  input                        rst_n,
  input                        input_valid,
  input [ADDR_SIZE-1:0]        input_addr,

  output                       output_valid,
  output [ADDR_SIZE-1:0]       output_addr,
  output [CNT_SIZE-1:0]        output_cnt
);

  /////////////////////////////////////////////////////////////
  // registers for capture
  logic                        valid;
  logic [ADDR_SIZE-1:0]        addr;
  
  // module wires
  logic                        hash_computation_valid;
  logic [ADDR_SIZE-1:0]        hash_computation_addr;
  logic [HASH_SIZE-1:0]        hash_value [0:NUM_HASH-1];

  logic                        sketch_valid;
  logic [ADDR_SIZE-1:0]        sketch_addr;
  logic [CNT_SIZE-1:0]         sketch_cnt_array [0:NUM_HASH-1];

  /////////////////////////////////////////////////////////////
  // capture valid, address
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      valid <= 1'b0;
      addr <= {ADDR_SIZE{1'b0}};
    end
    else if (input_valid) begin
      valid <= input_valid;
      addr <= input_addr;
    end
    else begin
      valid <= 1'b0;
      addr <= {ADDR_SIZE{1'b0}};
    end
  end

  /////////////////////////////////////////////////////////////
  // module instantination

  hash_computation
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .HASH_SIZE(HASH_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  ) 
    compute_hash
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),

    .input_valid(valid),
    .input_addr(addr),

    // Output
    .output_valid(hash_computation_valid),
    .output_addr(hash_computation_addr),
    .hash_value(hash_value)
  );

  sketch
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .HASH_SIZE(HASH_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  )
    sketch_
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),

    .input_valid(hash_computation_valid),
    .input_addr(hash_computation_addr),
    .input_hash_array(hash_value),
    
    // Output
    .output_valid(sketch_valid),
    .output_addr(sketch_addr),
    .output_cnt_array(sketch_cnt_array)
  );
    
  min_computation
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  ) 
    compute_min
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),

    .input_valid(sketch_valid),
    .input_addr(sketch_addr),
    .input_cnt_array(sketch_cnt_array),

    // Output
    .output_valid(output_valid),
    .min_addr(output_addr),
    .min_cnt(output_cnt)
  );


endmodule


