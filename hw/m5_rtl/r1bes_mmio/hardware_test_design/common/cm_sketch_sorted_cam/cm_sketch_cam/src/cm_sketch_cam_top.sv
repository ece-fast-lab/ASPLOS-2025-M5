module cm_sketch_cam_top
#(
  // common parameter
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32,

  // CM-sketch parameter
  parameter W = 4096,
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter HASH_SIZE = $clog2(W),

  // sorted CAM parameter
  parameter NUM_ENTRY = 25,
  parameter INDEX_SIZE = 5 // $clog2(NUM_ENTRY)
)
(
  input                        clk,
  input                        rst_n,
  input                        input_valid,
  input [ADDR_SIZE-1:0]        input_addr

  /* TODO*/
  /* 
  output                       top k implementation!
  */
);

  /////////////////////////////////////////////////////////////
  // module wires
  logic                        cm_sketch_valid;
  logic [ADDR_SIZE-1:0]        cm_sketch_addr;
  logic [CNT_SIZE-1:0]         cm_sketch_cnt;


  /////////////////////////////////////////////////////////////
  // module instantination
  cm_sketch
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .HASH_SIZE(HASH_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  ) 
    cm_sketch_0
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),

    .input_valid(input_valid),
    .input_addr(input_addr),

    // Output
    .output_valid(cm_sketch_valid),
    .output_addr(cm_sketch_addr),
    .output_cnt(cm_sketch_cnt)
  );

    cam
  #(
    .NUM_ENTRY(NUM_ENTRY),
    .INDEX_SIZE(INDEX_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  ) 
    cam_0
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),

    .input_valid(cm_sketch_valid),
    .input_addr(cm_sketch_addr),
    .input_cnt(cm_sketch_cnt)

    // Output
    /* TODO : Top-K Query*/
  );



endmodule


