module sketch_unit
#(
  parameter W = 16384,
  parameter W_UNIT = 4096,
  parameter NUM_SKETCH = W / W_UNIT,
  parameter SKETCH_INDEX_SIZE = $clog2(NUM_SKETCH),
  parameter COLUMN_INDEX_SIZE = $clog2(W_UNIT),
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                                 clk,
  input                                 rst_n,
  input                                 query_rst_n,

  input                                 input_valid_array [0:NUM_HASH-1],
  input [COLUMN_INDEX_SIZE-1:0]         input_column_index_array [0:NUM_HASH-1],
  
  output logic [CNT_SIZE-1:0]           output_cnt_array [0:NUM_HASH-1]
);

  /////////////////////////////////////////////////////////////
  // wire and regs
  logic                         query_rst_n_d1;

  logic                         valid                 [0:NUM_HASH-1];
  logic                         valid_d1              [0:NUM_HASH-1];
  logic                         valid_d2              [0:NUM_HASH-1];
  logic [COLUMN_INDEX_SIZE-1:0] column_index_array    [0:NUM_HASH-1];
  logic [COLUMN_INDEX_SIZE-1:0] column_index_array_d1 [0:NUM_HASH-1];

  logic [COLUMN_INDEX_SIZE-1:0] bram_addr [0:NUM_HASH-1];
  logic [CNT_SIZE-1:0]          bram_output_cnt [0:NUM_HASH-1]; 
  logic [CNT_SIZE-1:0]          bram_write_cnt [0:NUM_HASH-1]; 
  
  logic [CNT_SIZE-1:0]          hit_cnt_array [0:NUM_HASH-1];

  logic                         sketch_valid_bit [0:NUM_HASH-1][0:W_UNIT-1];
  logic                         is_entry_valid [0:NUM_HASH-1];

  genvar i, j;

  /////////////////////////////////////////////////////////////
  generate
    for (i = 0; i < NUM_HASH; i++) begin 
      for (j = 0; j < W_UNIT; j++) begin
        always_ff @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
            sketch_valid_bit[i][j] <= 1'b0;
          end
          else if (!query_rst_n_d1) begin
            sketch_valid_bit[i][j] <= 1'b0;
          end
          else if (!sketch_valid_bit[i][j] && valid_d1[i] && (j == column_index_array_d1[i])) begin
            sketch_valid_bit[i][j] <= 1'b1;
          end
          else begin
            sketch_valid_bit[i][j] <= sketch_valid_bit[i][j];
          end
        end
      end
    end
  endgenerate

  /////////////////////////////////////////////////////////////
  // When input_valid, read corresponding count value from sketch (cycle 1)
  generate
    for (i = 0; i < NUM_HASH; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          hit_cnt_array[i] <= {CNT_SIZE{1'b0}};
        end
        else if (!query_rst_n_d1) begin
          hit_cnt_array[i] <= {CNT_SIZE{1'b0}};
        end
        else if (valid_d1[i]) begin
          hit_cnt_array[i] <= bram_write_cnt[i];
        end
        else begin
          hit_cnt_array[i] <= {CNT_SIZE{1'b0}}; 
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < NUM_HASH; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          is_entry_valid[i] <= 1'b0;
        end
        else if (!query_rst_n_d1) begin
          is_entry_valid[i] <= 1'b0;
        end
        else if (valid[i]) begin
          is_entry_valid[i] <= sketch_valid_bit[i][column_index_array[i]];
        end
        else begin
          is_entry_valid[i] <= 1'b0; 
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < NUM_HASH; i++) begin
      assign bram_addr[i] = valid[i] ? column_index_array[i] : column_index_array_d1[i];
      assign bram_write_cnt[i] = is_entry_valid[i] ? bram_output_cnt[i] + 1 : 1'b1;
    end
  endgenerate

  // When valid_d1, update sketch (cycle 2)
  generate
    for (i = 0; i < NUM_HASH; i++) begin : BRAM_inst
      port_1_ram bram_0 (
        .data      (bram_write_cnt[i]),
        .q         (bram_output_cnt[i]),      
        .address   (bram_addr[i]),      
        .wren      (valid_d1[i]), 
        .clock     (clk)
      );
    end
  endgenerate

  generate
    for (i = 0; i < NUM_HASH; i++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          valid[i]                 <= 1'b0;
          valid_d1[i]              <= 1'b0;
          valid_d2[i]              <= 1'b0;
          column_index_array[i]    <= {COLUMN_INDEX_SIZE{1'b0}};
          column_index_array_d1[i] <= {COLUMN_INDEX_SIZE{1'b0}};
        end
        else if (!query_rst_n_d1) begin
          valid[i]                 <= 1'b0;
          valid_d1[i]              <= 1'b0;
          valid_d2[i]              <= 1'b0;
          column_index_array[i]    <= {COLUMN_INDEX_SIZE{1'b0}};
          column_index_array_d1[i] <= {COLUMN_INDEX_SIZE{1'b0}};
        end
        else begin
          valid[i]                 <= input_valid_array[i];
          valid_d1[i]              <= valid[i];
          valid_d2[i]              <= valid_d1[i];
          column_index_array[i]    <= input_column_index_array[i];
          column_index_array_d1[i] <= column_index_array[i];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      query_rst_n_d1 <= 1'b1;
    end
    else begin
      query_rst_n_d1 <= query_rst_n;
    end
  end
  
  // output cnt
  generate
    for (i = 0; i < NUM_HASH; i++) begin
      assign output_cnt_array[i] = valid_d2[i] ? hit_cnt_array[i] : 0;
    end
  endgenerate

endmodule