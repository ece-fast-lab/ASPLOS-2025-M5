module hash_computation 
#(
  parameter W = 16384,
  parameter W_UNIT = 4096,
  parameter NUM_SKETCH = W / W_UNIT,
  parameter SKETCH_INDEX_SIZE = $clog2(NUM_SKETCH),
  parameter COLUMN_INDEX_SIZE = $clog2(W_UNIT),
  parameter NUM_HASH = 4,
  parameter HASH_SIZE = $clog2(W),
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                              clk,
  input                              rst_n,

  input                              input_valid,
  input        [ADDR_SIZE-1:0]       input_addr,

  output                             output_valid,
  output       [ADDR_SIZE-1:0]       output_addr,
  output       [SKETCH_INDEX_SIZE:0] output_sketch_index [0:NUM_HASH-1],
  output       [COLUMN_INDEX_SIZE:0] output_column_index [0:NUM_HASH-1]
);
  
  /////////////////////////////////////////////////////////////
  logic  [ADDR_SIZE-1:0] addr, addr_d1, addr_d2, addr_d3, addr_d4, addr_d5;
  logic                  valid, valid_d1, valid_d2, valid_d3, valid_d4, valid_d5;
  
  logic  [HASH_SIZE-1:0] hash_seed_matrix [0:3][0:31];
  logic  [HASH_SIZE-1:0] hash_value [0:NUM_HASH-1];

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
      valid        <= 1'b0;
      valid_d1     <= 1'b0;
      valid_d2     <= 1'b0;
      valid_d3     <= 1'b0;
      valid_d4     <= 1'b0;
      valid_d5     <= 1'b0;
    end
    else begin
      addr         <= input_addr;
      addr_d1      <= addr;
      addr_d2      <= addr_d1;
      addr_d3      <= addr_d2;
      addr_d4      <= addr_d3;
      addr_d5      <= addr_d4;
      valid        <= input_valid;
      valid_d1     <= valid;
      valid_d2     <= valid_d1;
      valid_d3     <= valid_d2;
      valid_d4     <= valid_d3;
      valid_d5     <= valid_d4;
    end
  end

  // assign
  assign output_addr = addr_d5;
  assign output_valid = valid_d5;
   
  generate 
    for (i = 0; i < NUM_HASH; i++) begin : sketch_column_index_assign
      assign output_sketch_index[i] = hash_value[i] / W_UNIT;
      assign output_column_index[i] = hash_value[i] % W_UNIT;
    end
  endgenerate

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
        .input_hash_seed(hash_seed_matrix[i]),
        // Output
        .hash_value(hash_value[i])
      );
    end
  endgenerate

  /////////////////////////////////////////////////////////////
  // Hash seed array
  assign hash_seed_matrix[0][0] = 17'h06CFA;
  assign hash_seed_matrix[0][1] = 17'h0BD4A;
  assign hash_seed_matrix[0][2] = 17'h1BB21;
  assign hash_seed_matrix[0][3] = 17'h04D2E;
  assign hash_seed_matrix[0][4] = 17'h03045;
  assign hash_seed_matrix[0][5] = 17'h19DD1;
  assign hash_seed_matrix[0][6] = 17'h1185D;
  assign hash_seed_matrix[0][7] = 17'h0693C;
  assign hash_seed_matrix[0][8] = 17'h1CB38;
  assign hash_seed_matrix[0][9] = 17'h074D5;
  assign hash_seed_matrix[0][10] = 17'h05E49;
  assign hash_seed_matrix[0][11] = 17'h0AC9B;
  assign hash_seed_matrix[0][12] = 17'h17FA2;
  assign hash_seed_matrix[0][13] = 17'h1D8FE;
  assign hash_seed_matrix[0][14] = 17'h021DB;
  assign hash_seed_matrix[0][15] = 17'h06A38;
  assign hash_seed_matrix[0][16] = 17'h141A7;
  assign hash_seed_matrix[0][17] = 17'h03A51;
  assign hash_seed_matrix[0][18] = 17'h0FB4C;
  assign hash_seed_matrix[0][19] = 17'h0A3BC;
  assign hash_seed_matrix[0][20] = 17'h10FBA;
  assign hash_seed_matrix[0][21] = 17'h11702;
  assign hash_seed_matrix[0][22] = 17'h04323;
  assign hash_seed_matrix[0][23] = 17'h0173E;
  assign hash_seed_matrix[0][24] = 17'h007CF;
  assign hash_seed_matrix[0][25] = 17'h1BA8A;
  assign hash_seed_matrix[0][26] = 17'h07057;
  assign hash_seed_matrix[0][27] = 17'h09663;
  assign hash_seed_matrix[0][28] = 17'h15408;
  assign hash_seed_matrix[0][29] = 17'h0DB0B;
  assign hash_seed_matrix[0][30] = 17'h12E50;
  assign hash_seed_matrix[0][31] = 17'h1A12A;
  assign hash_seed_matrix[1][0] = 17'h18F26;
  assign hash_seed_matrix[1][1] = 17'h026E4;
  assign hash_seed_matrix[1][2] = 17'h10C5B;
  assign hash_seed_matrix[1][3] = 17'h0D606;
  assign hash_seed_matrix[1][4] = 17'h11329;
  assign hash_seed_matrix[1][5] = 17'h1E532;
  assign hash_seed_matrix[1][6] = 17'h0BC35;
  assign hash_seed_matrix[1][7] = 17'h0D3D6;
  assign hash_seed_matrix[1][8] = 17'h16B2B;
  assign hash_seed_matrix[1][9] = 17'h137EB;
  assign hash_seed_matrix[1][10] = 17'h1C11F;
  assign hash_seed_matrix[1][11] = 17'h079E8;
  assign hash_seed_matrix[1][12] = 17'h0CFA8;
  assign hash_seed_matrix[1][13] = 17'h1E216;
  assign hash_seed_matrix[1][14] = 17'h19C5F;
  assign hash_seed_matrix[1][15] = 17'h085D4;
  assign hash_seed_matrix[1][16] = 17'h028D4;
  assign hash_seed_matrix[1][17] = 17'h13BEB;
  assign hash_seed_matrix[1][18] = 17'h1144A;
  assign hash_seed_matrix[1][19] = 17'h0FB5C;
  assign hash_seed_matrix[1][20] = 17'h10605;
  assign hash_seed_matrix[1][21] = 17'h00A70;
  assign hash_seed_matrix[1][22] = 17'h0C9D6;
  assign hash_seed_matrix[1][23] = 17'h01B4C;
  assign hash_seed_matrix[1][24] = 17'h1093C;
  assign hash_seed_matrix[1][25] = 17'h1ED35;
  assign hash_seed_matrix[1][26] = 17'h0E1D0;
  assign hash_seed_matrix[1][27] = 17'h1C14F;
  assign hash_seed_matrix[1][28] = 17'h1E090;
  assign hash_seed_matrix[1][29] = 17'h1C011;
  assign hash_seed_matrix[1][30] = 17'h042CA;
  assign hash_seed_matrix[1][31] = 17'h16426;
  assign hash_seed_matrix[2][0] = 17'h05BB6;
  assign hash_seed_matrix[2][1] = 17'h1A544;
  assign hash_seed_matrix[2][2] = 17'h090CB;
  assign hash_seed_matrix[2][3] = 17'h079E0;
  assign hash_seed_matrix[2][4] = 17'h143D2;
  assign hash_seed_matrix[2][5] = 17'h1F7D5;
  assign hash_seed_matrix[2][6] = 17'h03BB8;
  assign hash_seed_matrix[2][7] = 17'h1E787;
  assign hash_seed_matrix[2][8] = 17'h1977A;
  assign hash_seed_matrix[2][9] = 17'h0DE27;
  assign hash_seed_matrix[2][10] = 17'h0F7E2;
  assign hash_seed_matrix[2][11] = 17'h0530E;
  assign hash_seed_matrix[2][12] = 17'h11B43;
  assign hash_seed_matrix[2][13] = 17'h1C2A6;
  assign hash_seed_matrix[2][14] = 17'h15A4E;
  assign hash_seed_matrix[2][15] = 17'h0EEE5;
  assign hash_seed_matrix[2][16] = 17'h1DC8F;
  assign hash_seed_matrix[2][17] = 17'h131B1;
  assign hash_seed_matrix[2][18] = 17'h173D9;
  assign hash_seed_matrix[2][19] = 17'h1B4CA;
  assign hash_seed_matrix[2][20] = 17'h17E26;
  assign hash_seed_matrix[2][21] = 17'h131DF;
  assign hash_seed_matrix[2][22] = 17'h1A819;
  assign hash_seed_matrix[2][23] = 17'h045A4;
  assign hash_seed_matrix[2][24] = 17'h06536;
  assign hash_seed_matrix[2][25] = 17'h00AB9;
  assign hash_seed_matrix[2][26] = 17'h10F6C;
  assign hash_seed_matrix[2][27] = 17'h1E3B4;
  assign hash_seed_matrix[2][28] = 17'h046D2;
  assign hash_seed_matrix[2][29] = 17'h04786;
  assign hash_seed_matrix[2][30] = 17'h0ED40;
  assign hash_seed_matrix[2][31] = 17'h0C84C;
  assign hash_seed_matrix[3][0] = 17'h11B8D;
  assign hash_seed_matrix[3][1] = 17'h074E4;
  assign hash_seed_matrix[3][2] = 17'h07C4F;
  assign hash_seed_matrix[3][3] = 17'h1E1A8;
  assign hash_seed_matrix[3][4] = 17'h144B9;
  assign hash_seed_matrix[3][5] = 17'h17971;
  assign hash_seed_matrix[3][6] = 17'h1D60E;
  assign hash_seed_matrix[3][7] = 17'h034AF;
  assign hash_seed_matrix[3][8] = 17'h14C8B;
  assign hash_seed_matrix[3][9] = 17'h16375;
  assign hash_seed_matrix[3][10] = 17'h09195;
  assign hash_seed_matrix[3][11] = 17'h1C56D;
  assign hash_seed_matrix[3][12] = 17'h079AA;
  assign hash_seed_matrix[3][13] = 17'h02F9E;
  assign hash_seed_matrix[3][14] = 17'h06A9F;
  assign hash_seed_matrix[3][15] = 17'h007A9;
  assign hash_seed_matrix[3][16] = 17'h010C6;
  assign hash_seed_matrix[3][17] = 17'h07EEC;
  assign hash_seed_matrix[3][18] = 17'h17823;
  assign hash_seed_matrix[3][19] = 17'h066A0;
  assign hash_seed_matrix[3][20] = 17'h08B28;
  assign hash_seed_matrix[3][21] = 17'h1A186;
  assign hash_seed_matrix[3][22] = 17'h0E1C6;
  assign hash_seed_matrix[3][23] = 17'h0F08A;
  assign hash_seed_matrix[3][24] = 17'h08D96;
  assign hash_seed_matrix[3][25] = 17'h100BB;
  assign hash_seed_matrix[3][26] = 17'h06366;
  assign hash_seed_matrix[3][27] = 17'h1E923;
  assign hash_seed_matrix[3][28] = 17'h17E41;
  assign hash_seed_matrix[3][29] = 17'h067D0;
  assign hash_seed_matrix[3][30] = 17'h0DFCA;
  assign hash_seed_matrix[3][31] = 17'h1FE95;

endmodule


