// this module contains the logic for priority queue with min heap algorithm.
// assumptions: input is 32 bits wide.
// storage element is 32 bits wide and 32 depth. 
// heap_count max value is 32 (32 bits wide) .

module heap_stage 
#(
  parameter CNT_SIZE = 20,
  parameter ADDR_SIZE = 28,
  parameter TOTAL_LEVEL = 6,
  parameter CURRENT_LEVEL = 3
)
(
  input                     clk,
  input                     rst_n,

  input [CNT_SIZE-1:0]      current_level_cnt [0:(2 ** (CURRENT_LEVEL - 1))-1],
  input [ADDR_SIZE-1:0]     current_level_addr [0:(2 ** (CURRENT_LEVEL - 1))-1],

  input                     valid_i,
  input                     opcode_i,
  input [CNT_SIZE-1:0]      wcnt_i,
  input [ADDR_SIZE-1:0]     waddr_i,
  input [TOTAL_LEVEL-1:0]   insert_path_i,
  input [TOTAL_LEVEL-1:0]   index_i,
  input [TOTAL_LEVEL-1:0]   heap_element_cnt_i,
  
  output                    valid_o,
  output                    opcode_o,
  output [CNT_SIZE-1:0]     wcnt_o,
  output [ADDR_SIZE-1:0]    waddr_o,
  output [TOTAL_LEVEL-1:0]  insert_path_o,
  output [TOTAL_LEVEL-1:0]  index_o,
  output [TOTAL_LEVEL-1:0]  heap_element_cnt_o,

  output [CNT_SIZE-1:0]     write_cnt,
  output [ADDR_SIZE-1:0]    write_addr,
  output [TOTAL_LEVEL-1:0]  write_index,
  output                    write_en
);

  localparam NUM_CNT = 2 ** (CURRENT_LEVEL - 1);

  // Parameters for FSM states
  localparam STATE_IDLE  				= 3'd0;
  localparam STATE_INSERT_1  		= 3'd1;
  localparam STATE_INSERT_2   	= 3'd2;
  localparam STATE_QUERY        = 3'd3;

  logic                       valid;
  logic [1:0]                 opcode;
  logic [CNT_SIZE-1:0]        wcnt;
  logic [ADDR_SIZE-1:0]       waddr;
  logic [TOTAL_LEVEL-1:0]     insert_path;
  logic [TOTAL_LEVEL-1:0]     index;
  logic [TOTAL_LEVEL-1:0]     heap_element_cnt;

  logic [2:0]                 state, next_state;

  always_comb begin
    next_state = STATE_IDLE;
    case(state)
      STATE_IDLE: begin
        if ((opcode_i == 1'b0) && valid_i) begin
          next_state = STATE_INSERT_1;
        end
        else if (opcode_i == 1'b1) begin
          next_state = STATE_QUERY;
        end
        else begin
          next_state = STATE_IDLE;
        end
      end
      STATE_INSERT_1: begin
        next_state = STATE_INSERT_2;
      end
      STATE_INSERT_2: begin
        if ((opcode_i == 1'b0) && valid_i) begin
          next_state = STATE_INSERT_1;
        end
        else if (opcode_i == 1'b1) begin
          next_state = STATE_QUERY;
        end
        else begin
          next_state = STATE_IDLE;
        end
      end
      default:;
    endcase
  end

  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 3'b0;
    end
    else begin
      state <= next_state;
    end
  end

  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid <= 1'b0;
      opcode <= 1'b0;
      wcnt <= {CNT_SIZE{1'b0}};
      waddr <= {ADDR_SIZE{1'b0}};
      insert_path <= {TOTAL_LEVEL{1'b0}};
      index <= {TOTAL_LEVEL{1'b0}};
      heap_element_cnt <= {TOTAL_LEVEL{1'b0}};
    end
    else if ((state == STATE_IDLE) || (state == STATE_INSERT_2)) begin
      valid <= valid_i;
      opcode <= opcode_i;
      wcnt <= wcnt_i;
      waddr <= waddr_i;
      insert_path <= insert_path_i;
      index <= index_i;
      heap_element_cnt <= heap_element_cnt_i;
    end
    else begin
      valid <= valid;
      opcode <= opcode;
      wcnt <= wcnt;
      waddr <= waddr;
      insert_path <= insert_path;
      index <= index;
    end
  end

  assign wcnt_o = (heap_element_cnt == 0) ? {CNT_SIZE{1'b0}} : (wcnt > current_level_cnt[index]) ? current_level_cnt[index] : wcnt;
  assign waddr_o = (heap_element_cnt == 0) ? {ADDR_SIZE{1'b0}} : (wcnt > current_level_cnt[index]) ? current_level_addr[index] : waddr;
  assign index_o = (insert_path[$clog2(heap_element_cnt+2)-CURRENT_LEVEL-1] == 1'b0) ? index * 2 : index * 2 + 1;
  assign valid_o = ((2**CURRENT_LEVEL) - 1 <= heap_element_cnt) ? valid : 1'b0;
  assign opcode_o = opcode;
  assign insert_path_o = insert_path;
  assign heap_element_cnt_o = heap_element_cnt;

  assign write_cnt = wcnt;
  assign write_addr = waddr;
  assign write_index = index;
  assign write_en = (state != STATE_INSERT_2) ? 1'b0 : (heap_element_cnt == 0) ? 1'b1 : (wcnt > current_level_cnt[index]) ? 1'b1 : 1'b0;

endmodule