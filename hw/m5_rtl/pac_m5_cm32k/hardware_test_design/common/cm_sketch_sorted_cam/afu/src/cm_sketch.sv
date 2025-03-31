module cm_sketch
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
  input                        input_query_en,
  
  output logic                 input_ready,

  output                       output_valid,
  output [ADDR_SIZE-1:0]       output_addr,
  output [CNT_SIZE-1:0]        output_cnt
);

  /////////////////////////////////////////////////////////////
  // registers for capture
  logic                        valid;
  logic [ADDR_SIZE-1:0]        addr;
  
  // module wires
  logic                        hash_computation_valid;
  logic [ADDR_SIZE-1:0]        hash_computation_addr;
  logic [HASH_SIZE-1:0]        hash_value [0:NUM_HASH-1];

  logic                        sketch_valid;
  logic [ADDR_SIZE-1:0]        sketch_addr;
  logic [CNT_SIZE-1:0]         sketch_cnt_array [0:NUM_HASH-1];

  logic                        query_rst_n;
  
  logic [2:0]                  state, next_state;

  localparam STATE_IDLE  				= 3'd0;
  localparam STATE_REQ_1  			= 3'd1;
  localparam STATE_REQ_2        = 3'd2;
  localparam STATE_FLUSH_1      = 3'd3;
  localparam STATE_FLUSH_2      = 3'd4;
  localparam STATE_FLUSH_3      = 3'd5;
  localparam STATE_FLUSH_4      = 3'd6;

  /////////////////////////////////////////////////////////////
  // capture valid, address
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      addr <= {ADDR_SIZE{1'b0}};
    end
    else if (next_state == STATE_REQ_1) begin
      addr <= input_addr;
    end
    else begin
      addr <= {ADDR_SIZE{1'b0}};
    end
  end

  always_comb begin
    valid = 1'b0;
    if (state == STATE_REQ_1) begin
      valid = input_valid & input_ready;
    end
  end
/*
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      valid <= 1'b0;
      addr <= {ADDR_SIZE{1'b0}};
    end
    else if (next_state == STATE_REQ_1) begin
      valid <= input_valid;
      addr <= input_addr;
    end
    else begin
      valid <= 1'b0;
      addr <= {ADDR_SIZE{1'b0}};
    end
  end
*/


  // state transition
  always_comb begin
    next_state = STATE_IDLE;
    case(state)
      STATE_IDLE: begin
        if (input_query_en) begin
          next_state = STATE_FLUSH_1;
        end
        else if (input_valid & ~input_query_en) begin
          next_state = STATE_REQ_1;
        end
      end
      STATE_REQ_1: begin 
        if (input_valid & input_ready) begin
          next_state = STATE_REQ_2;
        end
        else if (~input_valid) begin
          next_state = STATE_IDLE;
        end
        else begin
          next_state = STATE_REQ_1;
        end
      end
      STATE_REQ_2: begin 
        if (input_query_en) begin
          next_state = STATE_FLUSH_1;
        end
        else if (input_valid & ~input_query_en) begin
          next_state = STATE_REQ_1;
        end        
      end   
      STATE_FLUSH_1: begin 
        next_state = STATE_FLUSH_2;
      end  
      STATE_FLUSH_2: begin 
        next_state = STATE_FLUSH_3;
      end  
      STATE_FLUSH_3: begin 
        next_state = STATE_FLUSH_4;
      end  
      STATE_FLUSH_4: begin 
        next_state = STATE_IDLE;
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
      input_ready <= 1'b1;
    end
    else begin
      if (next_state == STATE_REQ_1) begin
        if (input_valid)
          input_ready <= 1'b1;
        else 
          input_ready <= 1'b0;
      end
      else begin
        input_ready <= 1'b0;
      end
    end
  end
  
  always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      query_rst_n <= 1'b1;
    end
    else if (state == STATE_FLUSH_1 || state == STATE_FLUSH_2 || state == STATE_FLUSH_3 || state == STATE_FLUSH_4) begin
      query_rst_n <= 1'b0;
    end
    else begin
      query_rst_n <= 1'b1;
    end
  end
	
  /////////////////////////////////////////////////////////////
  // module instantination

  hash_computation
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .HASH_SIZE(HASH_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  ) 
    compute_hash
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),

    .input_valid(valid),
    .input_addr(input_addr),

    // Output
    .output_valid(hash_computation_valid),
    .output_addr(hash_computation_addr),
    .hash_value(hash_value)
  );

  sketch
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .HASH_SIZE(HASH_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  )
    sketch_
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),
    .query_rst_n(query_rst_n),

    .input_valid(hash_computation_valid),
    .input_addr(hash_computation_addr),
    .input_hash_array(hash_value),
    
    // Output
    .output_valid(sketch_valid),
    .output_addr(sketch_addr),
    .output_cnt_array(sketch_cnt_array)
  );
    
  min_computation
  #(
    .W(W),
    .NUM_HASH(NUM_HASH),
    .ADDR_SIZE(ADDR_SIZE),
    .CNT_SIZE(CNT_SIZE)
  ) 
    compute_min
  (
    // Input
    .clk(clk),
    .rst_n(rst_n),
    .query_rst_n(query_rst_n),

    .input_valid(sketch_valid),
    .input_addr(sketch_addr),
    .input_cnt_array(sketch_cnt_array),

    // Output
    .output_valid(output_valid),
    .min_addr(output_addr),
    .min_cnt(output_cnt)
  );

endmodule


