module sketch
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
  input [HASH_SIZE-1:0]        input_hash_array [0:NUM_HASH-1],
  
  output logic                 output_valid,
  output logic [ADDR_SIZE-1:0] output_addr,
  output logic [CNT_SIZE-1:0]  output_cnt_array [0:NUM_HASH-1]
);

  /////////////////////////////////////////////////////////////
  // wire and regs
  logic [CNT_SIZE-1:0]  cnt_array [0:NUM_HASH-1][0:W-1];
  logic                 hot_array [0:NUM_HASH-1][0:W-1];

  logic                 valid_d1;
  logic [ADDR_SIZE-1:0] addr_d1;
  logic [HASH_SIZE-1:0] input_hash_array_d1 [0:NUM_HASH-1];
  logic [CNT_SIZE-1:0]  hit_cnt_array [0:NUM_HASH-1];

  genvar i, j;

  /////////////////////////////////////////////////////////////
  // When input_valid, read corresponding count value from sketch (cycle 1)
  generate
    for (i = 0; i < NUM_HASH; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          hit_cnt_array[i] <= {CNT_SIZE{1'b0}};
          input_hash_array_d1[i] <= {HASH_SIZE{1'b0}};
        end 
        else if (input_valid) begin
          hit_cnt_array[i] <= cnt_array[i][input_hash_array[i]];
          input_hash_array_d1[i] <= input_hash_array[i];
        end
        else begin
          hit_cnt_array[i] <= {CNT_SIZE{1'b0}}; 
          input_hash_array_d1[i] <= {HASH_SIZE{1'b0}};
        end
      end
    end
  endgenerate

  // When valid_d1, update sketch (cycle 2)
  generate
    for (i = 0; i < NUM_HASH; i++) begin
      for (j = 0; j < W; j++) begin
        always_ff @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
            cnt_array[i][j] <= {CNT_SIZE{1'b0}};
          end 
          else if (valid_d1 && j == input_hash_array_d1[i]) begin
            cnt_array[i][j] <= hit_cnt_array[i] + 1;
          end
          else begin
            cnt_array[i][j] <= cnt_array[i][j];
          end
        end
      end
    end
  endgenerate

  // Valid, addr pipeline
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      valid_d1 <= 1'b0;
      output_valid <= 1'b0;
      addr_d1 <= {ADDR_SIZE{1'b0}};
      output_addr <= {ADDR_SIZE{1'b0}};
    end 
    else begin
      valid_d1 <= input_valid;
      output_valid <= valid_d1;
      addr_d1 <= input_addr;
      output_addr <= addr_d1;
    end
  end

  // output cnt
  generate
    for (i = 0; i < NUM_HASH; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          output_cnt_array[i] <= {CNT_SIZE{1'b0}};
        end 
        else if (valid_d1) begin
          output_cnt_array[i] <= hit_cnt_array[i] + 1;
        end
        else begin
          output_cnt_array[i] <= output_cnt_array[i];
        end
      end
    end
  endgenerate

  // (**Temp**) hot bit
  generate
    for (i = 0; i < NUM_HASH; i++) begin
      for (j = 0; j < W; j++) begin
        always_ff @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
            hot_array[i][j] <= 1'b0;
          end 
          else begin
            hot_array[i][j] <= hot_array[i][j];
          end
        end
      end
    end
  endgenerate

endmodule


