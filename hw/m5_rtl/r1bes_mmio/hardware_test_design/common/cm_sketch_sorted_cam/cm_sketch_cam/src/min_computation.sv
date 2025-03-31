module min_computation 
#(
  parameter W = 4096,
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input clk,
  input rst_n,

  input                   input_valid,
  input  [ADDR_SIZE-1:0]  input_addr,
  input  [CNT_SIZE-1:0]   input_cnt_array [0:NUM_HASH-1],

  output                  output_valid,
  output [ADDR_SIZE-1:0]  min_addr,
  output [CNT_SIZE-1:0]   min_cnt
);
  
  /////////////////////////////////////////////////////////////
  localparam NUM_STAGE = $clog2(NUM_HASH);
  genvar i, j;

  // stage register (for pipelining)
  logic                  valid_stage [0:NUM_STAGE];
  logic [ADDR_SIZE-1:0]  addr_stage [0:NUM_STAGE];
  logic [CNT_SIZE-1:0]   min_cnt_stage [0:NUM_STAGE][0:(2 ** NUM_STAGE) - 1]; 
  
  

  /*
  for (i = 0; i < NUM_STAGE + 1; i++) begin
    logic [CNT_SIZE-1:0]  min_cnt_stage[i][0:2 ** (NUM_STAGE - i) - 1]; 
    logic [ADDR_SIZE-1:0] addr_stage[i];
  end
  */

  /////////////////////////////////////////////////////////////
  // capture input addr, valid
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      addr_stage[0] <= {ADDR_SIZE{1'b0}};
      valid_stage[0] <= 1'b0;
    end
    else if (input_valid) begin
      addr_stage[0] <= input_addr;
      valid_stage[0] <= input_valid;
    end
    else begin
      addr_stage[0] <= {ADDR_SIZE{1'b0}};
      valid_stage[0] <= 1'b0;
    end
  end

  // capture input count
  generate
    for(i = 0 ; i < NUM_HASH ; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          min_cnt_stage[0][i] <= {CNT_SIZE{1'b0}};
        end
        else if (input_valid) begin
          min_cnt_stage[0][i] <= input_cnt_array[i];
        end
        else begin
          min_cnt_stage[0][i] <= {CNT_SIZE{1'b0}};
        end
      end
    end
  endgenerate

  // address pipeline
  generate
    for (i = 1; i < NUM_STAGE+1; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          addr_stage[i] <= {ADDR_SIZE{1'b0}};
          valid_stage[i] <= 1'b0;
        end
        else begin
          addr_stage[i] <= addr_stage[i-1];
          valid_stage[i] <= valid_stage[i-1];
        end
      end
    end
  endgenerate

  // min computation pipeline
  generate
    for (i = 1; i < NUM_STAGE+1; i++) begin
      for (j = 0; j < (NUM_HASH / (2**i)); j++) begin
        always_ff @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
            min_cnt_stage[i][j] <= {CNT_SIZE{1'b0}};
          end
          else begin
            min_cnt_stage[i][j] <= (min_cnt_stage[i-1][j*2] >= min_cnt_stage[i-1][j*2+1]) ? min_cnt_stage[i-1][j*2+1] : min_cnt_stage[i-1][j*2];
          end
        end
      end
    end
  endgenerate
    
  assign output_valid = valid_stage[NUM_STAGE];
  assign min_addr   = addr_stage[NUM_STAGE];
  assign min_cnt    = min_cnt_stage[NUM_STAGE][0];
  
endmodule


