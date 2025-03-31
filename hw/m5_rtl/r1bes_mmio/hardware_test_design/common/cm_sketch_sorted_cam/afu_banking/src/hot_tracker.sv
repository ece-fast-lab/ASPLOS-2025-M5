module hot_tracker
#(
  // common parameter
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 18,

  // CM-sketch parameter
  parameter W = 4096,
  parameter W_UNIT = 4096,
  parameter NUM_SKETCH = W / W_UNIT,
  parameter SKETCH_INDEX_SIZE = $clog2(NUM_SKETCH),
  parameter COLUMN_INDEX_SIZE = $clog2(W_UNIT),
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter HASH_SIZE = $clog2(W),

  // sorted CAM parameter
  parameter NUM_ENTRY = 25,
  parameter INDEX_SIZE = 5 // $clog2(NUM_ENTRY)
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

  /////////////////////////////////////////////////////////////
  // module wires
  logic                        cm_sketch_valid;
  logic [ADDR_SIZE-1:0]        cm_sketch_addr;
  logic [CNT_SIZE-1:0]         cm_sketch_cnt;
  
  logic [ADDR_SIZE-1:0]        mig_addr_array [0:NUM_ENTRY-1];

  logic [ADDR_SIZE-1:0]        top_addr [0:NUM_ENTRY-1];

  genvar i;
  
  /////////////////////////////////////////////////////////////
  // Process Query

  // mig_addr_en
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mig_addr_en <= 1'b0;
    end
    else begin
      if (query_ready) begin // TODO check: query_ready or query_ready_d1?  
        mig_addr_en <= 1'b1; // (e.g, after STATE_FLUSH at CAM?)
      end 
      else if (top_addr[1] == {ADDR_SIZE{1'b1}}) begin
        mig_addr_en <= 1'b0;
      end
      else begin
        mig_addr_en <= mig_addr_en;
      end
    end
  end

  // Top-K
  generate
    for (i = 0; i < NUM_ENTRY; i++) begin
      always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          top_addr[i] <= {ADDR_SIZE{1'b1}};
        end
        else begin
          // send mig address
          if (mig_addr_en & mig_addr_ready) begin
            if (i != NUM_ENTRY-1) begin
              top_addr[i] <= top_addr[i+1];
            end
            else begin
              top_addr[i] <= {ADDR_SIZE{1'b1}};
            end
          end
          // capture top-k address
          else if (query_ready) begin
            top_addr[i] <= mig_addr_array[i];
          end
          else begin 
            top_addr[i] <= top_addr[i];
          end
        end
      end    
    end
  endgenerate

  assign mig_addr = top_addr[0];

  /////////////////////////////////////////////////////////////
  // module instantination
  cm_sketch
  #(
    .W(W),
    .W_UNIT(W_UNIT),
    .NUM_SKETCH(NUM_SKETCH),
    .SKETCH_INDEX_SIZE(SKETCH_INDEX_SIZE),
    .COLUMN_INDEX_SIZE(COLUMN_INDEX_SIZE),
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

    .input_valid(input_addr_valid),
    .input_addr(input_addr),
    .input_query_en(query_en),

    // Output (to host)
    .input_ready(input_addr_ready),

    // Output (to sorted CAM)
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
    .input_cnt(cm_sketch_cnt),
    .input_query_en(query_en),

    // Output
    .output_query_ready(query_ready),
    .output_mig_addr(mig_addr_array)
  );

endmodule


