// top module of heap

module heap
#(
  //parameter ADDR_SIZE = 32,
  parameter CNT_SIZE = 20,
  parameter ADDR_SIZE = 28,
  parameter TOTAL_LEVEL = 6
)
(
  input                     clk,
  input                     rst_n,
  input                     input_valid,
  input [CNT_SIZE-1:0]      input_cnt,
  input [ADDR_SIZE-1:0]     input_addr,
  input                     input_query

  /* TODO : when query : output */
  // output [CNT_SIZE-1:0]      output_cnt,
  // output [ADDR_SIZE-1:0]     output_addr
);
  localparam NUM_ENTRY = 2 ** TOTAL_LEVEL - 1;

  logic                       valid [0:TOTAL_LEVEL];
  logic                       opcode [0:TOTAL_LEVEL];
  logic [CNT_SIZE-1:0]        wcnt [0:TOTAL_LEVEL];
  logic [ADDR_SIZE-1:0]       waddr [0:TOTAL_LEVEL];
  logic [TOTAL_LEVEL-1:0]     insert_path [0:TOTAL_LEVEL];
  logic [TOTAL_LEVEL-1:0]     index [0:TOTAL_LEVEL];      
  logic [TOTAL_LEVEL-1:0]     heap_element_cnt [0:TOTAL_LEVEL];      
  logic                       write_en [0:TOTAL_LEVEL-1];
  logic [CNT_SIZE-1:0]        write_cnt [0:TOTAL_LEVEL-1];
  logic [ADDR_SIZE-1:0]       write_addr [0:TOTAL_LEVEL-1];
  logic [TOTAL_LEVEL-1:0]     write_index [0:TOTAL_LEVEL-1];

  logic [CNT_SIZE-1:0]        cnt_wire [1:2**TOTAL_LEVEL-1];
  logic [ADDR_SIZE-1:0]       addr_wire [1:2**TOTAL_LEVEL-1];
  
  logic                       input_valid_d1;

  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_valid_d1 <= 1'b0;
    end
    else begin
      input_valid_d1 <= input_valid;
    end
  end

  // heap_element_cnt[0] is current entry number in heap
  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      heap_element_cnt[0] <= {TOTAL_LEVEL{1'b0}};
    end
    else if (input_valid_d1 && (heap_element_cnt[0] < (2 ** TOTAL_LEVEL) - 1)) begin
      heap_element_cnt[0] = heap_element_cnt[0] + 1;
    end
    else begin
      heap_element_cnt[0] = heap_element_cnt[0];
    end
  end

  assign valid[0] = input_valid;
  assign opcode[0] = input_query ? 1'b1 : 1'b0;
  assign wcnt[0] = input_cnt;
  assign waddr[0] = input_addr;
  assign insert_path[0] = (heap_element_cnt[0] == NUM_ENTRY) ? NUM_ENTRY 
                          : (heap_element_cnt[0] + 1) - 2 ** ($clog2(heap_element_cnt[0] + 1));
  assign index[0] = {TOTAL_LEVEL{1'b0}};

  genvar i;

  generate
    for (i = 0; i < TOTAL_LEVEL; i = i + 1) begin
      heap_stage
      #(
        .CNT_SIZE(CNT_SIZE), 
        .ADDR_SIZE(ADDR_SIZE),
        .TOTAL_LEVEL(TOTAL_LEVEL), 
        .CURRENT_LEVEL(i+1)
      ) 
        stage
      (
        // Input
        .clk(clk), 
        .rst_n(rst_n), 

        .current_level_cnt(cnt_wire[(2**i):(2**(i+1))-1]),
        .current_level_addr(addr_wire[(2**i):(2**(i+1))-1]),

        .valid_i(valid[i]),
        .opcode_i(opcode[i]),
        .wcnt_i(wcnt[i]),
        .waddr_i(waddr[i]),
        .insert_path_i(insert_path[i]),
        .index_i(index[i]),
        .heap_element_cnt_i(heap_element_cnt[i]),

        // Output
        .valid_o(valid[i+1]),
        .opcode_o(opcode[i+1]),
        .wcnt_o(wcnt[i+1]),
        .waddr_o(waddr[i+1]),
        .insert_path_o(insert_path[i+1]),
        .index_o(index[i+1]),
        .heap_element_cnt_o(heap_element_cnt[i+1]),
        
        .write_cnt(write_cnt[i]),
        .write_addr(write_addr[i]),
        .write_index(write_index[i]),
        .write_en(write_en[i])
      );

      heap_store
      #(
        .CNT_SIZE(CNT_SIZE), 
        .ADDR_SIZE(ADDR_SIZE),
        .TOTAL_LEVEL(TOTAL_LEVEL), 
        .CURRENT_LEVEL(i+1)
      )
        store
      (
        // Input
        .clk(clk), 
        .rst_n(rst_n), 

        .write_en(write_en[i]),
        .write_index(write_index[i]),
        .write_cnt(write_cnt[i]),
        .write_addr(write_addr[i]),

        // Output
        .stored_cnt(cnt_wire[(2**i):((2**(i+1))-1)]),
        .stored_addr(addr_wire[(2**i):((2**(i+1))-1)])
      );
    end
  endgenerate

endmodule