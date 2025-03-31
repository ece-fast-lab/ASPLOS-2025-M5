module sketch
#(
  parameter W = 16384,
  parameter W_UNIT = 4096,
  parameter NUM_SKETCH = W / W_UNIT,
  parameter SKETCH_INDEX_SIZE = $clog2(NUM_SKETCH),
  parameter COLUMN_INDEX_SIZE = $clog2(W_UNIT),
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter HASH_SIZE = $clog2(W),
  parameter ADDR_SIZE = 22,
  parameter CNT_SIZE = 32
)
(
  input                        clk,
  input                        rst_n,
  input                        query_rst_n,

  input                        input_valid,
  input [ADDR_SIZE-1:0]        input_addr,

  input [SKETCH_INDEX_SIZE:0]  input_sketch_index [0:NUM_HASH-1],
  input [COLUMN_INDEX_SIZE:0]  input_column_index [0:NUM_HASH-1],
  
  output                       output_valid,
  output [ADDR_SIZE-1:0]       output_addr,
  output [CNT_SIZE-1:0]        output_cnt_array [0:NUM_HASH-1]
);

  /////////////////////////////////////////////////////////////
  // wire and regs
  logic                           valid, valid_d1, valid_d2, valid_d3, valid_d4;
  logic [ADDR_SIZE-1:0]           addr, addr_d1, addr_d2, addr_d3, addr_d4;

  logic [SKETCH_INDEX_SIZE-1:0]   sketch_index [0:NUM_HASH-1];
  logic [COLUMN_INDEX_SIZE-1:0]   column_index [0:NUM_HASH-1];

  logic                           sketch_unit_valid_array [0:NUM_SKETCH-1][0:NUM_HASH-1];
  logic [CNT_SIZE-1:0]            sketch_unit_cnt_array [0:NUM_SKETCH-1][0:NUM_HASH-1];

  logic [CNT_SIZE-1:0]            cnt_array [0:NUM_SKETCH-1][0:NUM_HASH-1];
  logic [CNT_SIZE-1:0]            output_cnt_array_wire [0:NUM_HASH-1];

  genvar i, j;
  integer n, m;

  /////////////////////////////////////////////////////////////
  // valid, addr pipeline chain
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      valid        <= 1'b0;
      valid_d1     <= 1'b0;
      valid_d2     <= 1'b0;
      valid_d3     <= 1'b0;
      valid_d4     <= 1'b0;
      addr         <= {ADDR_SIZE{1'b0}};
      addr_d1      <= {ADDR_SIZE{1'b0}};
      addr_d2      <= {ADDR_SIZE{1'b0}};
      addr_d3      <= {ADDR_SIZE{1'b0}};
      addr_d4      <= {ADDR_SIZE{1'b0}};
    end
    else begin
      valid        <= input_valid;
      valid_d1     <= valid;
      valid_d2     <= valid_d1;
      valid_d3     <= valid_d2;
      valid_d4     <= valid_d3;
      addr         <= input_addr;
      addr_d1      <= addr;
      addr_d2      <= addr_d1;
      addr_d3      <= addr_d2;
      addr_d4      <= addr_d3;
    end
  end

  generate
    for (j = 0; j < NUM_HASH; j++) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          sketch_index[j] <= {SKETCH_INDEX_SIZE{1'b0}};
          column_index[j] <= {COLUMN_INDEX_SIZE{1'b0}};
        end
        else begin
          sketch_index[j] <= input_sketch_index[j];
          column_index[j] <= input_column_index[j];
        end
      end
    end
  endgenerate

  // sketch index demuxing
  generate 
    for (i = 0; i < NUM_SKETCH; i++) begin
      for (j = 0; j < NUM_HASH; j++) begin
        assign sketch_unit_valid_array[i][j] = valid && (sketch_index[j] == i);
      end
    end
  endgenerate

  /////////////////////////////////////////////////////////////
  // sketch unit instantiation
  generate 
    for (i = 0; i < NUM_SKETCH; i++) begin : sketch_unit_inst
      sketch_unit
      #(
        .W(W),
        .W_UNIT(W_UNIT),
        .NUM_SKETCH(NUM_SKETCH),
        .SKETCH_INDEX_SIZE(SKETCH_INDEX_SIZE),
        .COLUMN_INDEX_SIZE(COLUMN_INDEX_SIZE),
        .NUM_HASH(NUM_HASH),
        .ADDR_SIZE(ADDR_SIZE),
        .CNT_SIZE(CNT_SIZE)
      ) 
        u_sketch_unit
      (
        // Input
        .clk(clk),
        .rst_n(rst_n),
        .query_rst_n(query_rst_n),

        .input_valid_array(sketch_unit_valid_array[i]),
        .input_column_index_array(column_index),

        // Output
        .output_cnt_array(sketch_unit_cnt_array[i])
      );
    end
  endgenerate

  // output count muxing (by or gating), TODO : or tree if violation occur
  generate
    for (i = 0; i < NUM_SKETCH; i++) begin
      for (j = 0; j < NUM_HASH; j++) begin
        always_ff @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
            cnt_array[i][j] <= {CNT_SIZE{1'b0}};
          end
          else begin
            cnt_array[i][j] <= sketch_unit_cnt_array[i][j];
          end
        end
      end
    end
  endgenerate


  always_comb begin
    for (m = 0; m < NUM_HASH; m++) begin
      output_cnt_array_wire[m] = {CNT_SIZE{1'b0}};
      for (n = 0; n < NUM_SKETCH; n++) begin
        output_cnt_array_wire[m] |= cnt_array[n][m];
      end
    end
  end

  assign output_valid = valid_d4;
  assign output_addr = addr_d4;
  assign output_cnt_array = output_cnt_array_wire;

endmodule


