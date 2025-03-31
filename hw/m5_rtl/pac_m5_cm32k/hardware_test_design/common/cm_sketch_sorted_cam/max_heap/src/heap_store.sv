// top module of heap

module heap_store
#(
  //parameter ADDR_SIZE = 32,
  parameter CNT_SIZE = 20,
  parameter ADDR_SIZE = 28,
  parameter TOTAL_LEVEL = 6,
  parameter CURRENT_LEVEL = 3
)
(
  input                     clk,
  input                     rst_n,
  input                     write_en,
  input [TOTAL_LEVEL-1:0]   write_index,
  input [CNT_SIZE-1:0]      write_cnt,
  input [ADDR_SIZE-1:0]     write_addr,
  
  output [CNT_SIZE-1:0]     stored_cnt [0:(2**(CURRENT_LEVEL - 1))-1],
  output [ADDR_SIZE-1:0]    stored_addr [0:(2**(CURRENT_LEVEL - 1))-1]
);

  localparam NUM_CNT = 2 ** (CURRENT_LEVEL - 1);

  logic [CNT_SIZE-1:0]        cnt_array [0:NUM_CNT-1];
  logic [ADDR_SIZE-1:0]       addr_array [0:NUM_CNT-1];

  genvar i;

  generate
    for (i = 0; i < NUM_CNT; i = i + 1) begin
      always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          cnt_array[i] = {CNT_SIZE{1'b0}};
          addr_array[i] = {ADDR_SIZE{1'b0}};
        end
        else if (write_en && (i == write_index)) begin
          cnt_array[i] = write_cnt;
          addr_array[i] = write_addr;
        end
        else begin
          cnt_array[i] = cnt_array[i];
          addr_array[i] = addr_array[i];
        end
      end
    end
  endgenerate

  assign stored_cnt   = cnt_array;
  assign stored_addr  = addr_array;
endmodule