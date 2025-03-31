module one_hash_computation 
#(
  parameter W = 4096,
  parameter HASH_SIZE = $clog2(W),
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                        clk,
  input                        rst_n,

  input        [ADDR_SIZE-1:0] input_addr,
  input        [HASH_SIZE-1:0] input_hash_seed [0:31],

  output       [HASH_SIZE-1:0] hash_value
);


  // XOR stage register (for pipelining)
  logic  [HASH_SIZE-1:0] xor_input_32 [0:31];
  logic  [HASH_SIZE-1:0] xor_input_16 [0:15];
  logic  [HASH_SIZE-1:0] xor_input_8  [0:7];
  logic  [HASH_SIZE-1:0] xor_input_4  [0:3];
  logic  [HASH_SIZE-1:0] xor_input_2  [0:1];

  genvar i;

  // Hash computation pipeline
  generate
    for (i = 0; i < 32; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          xor_input_32[i] <= {HASH_SIZE{1'b0}};
        end
        else if (i >= ADDR_SIZE) begin
          xor_input_32[i] <= {HASH_SIZE{1'b0}};
        end
        else if (input_addr[i]) begin
          xor_input_32[i] <= input_hash_seed[i];
        end
        else begin
          xor_input_32[i] <= {HASH_SIZE{1'b0}};
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < 16; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          xor_input_16[i] <= 0;
        end
        else begin
          xor_input_16[i] <= xor_input_32[i*2] ^ xor_input_32[i*2+1];
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < 8; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          xor_input_8[i] <= 0;
        end
        else begin
          xor_input_8[i] <= xor_input_16[i*2] ^ xor_input_16[i*2+1];
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < 4; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          xor_input_4[i] <= 0;
        end
        else begin
          xor_input_4[i] <= xor_input_8[i*2] ^ xor_input_8[i*2+1];
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < 2; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          xor_input_2[i] <= 0;
        end
        else begin
          xor_input_2[i] <= xor_input_4[i*2] ^ xor_input_4[i*2+1];
        end
      end
    end
  endgenerate
  
  assign hash_value = xor_input_2[0] ^ xor_input_2[1];

endmodule


