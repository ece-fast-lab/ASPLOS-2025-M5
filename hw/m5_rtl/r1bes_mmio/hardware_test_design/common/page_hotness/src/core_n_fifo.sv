`timescale 1ns / 1ps

module core_n_fifo
#(
  parameter NUM_ENTRY = 50,
  parameter NUM_ENTRY_BITS = 6, // log2 (NUM_ENTRY)
  parameter TOP_K = 5,
  parameter ADDR_SIZE = 28, // Cache line input size
  parameter DATA_SIZE = 22,
  parameter CNT_SIZE = 13,
  parameter CMD_WIDTH = 4
)
(
  input clk,
  input rstn,

  input  [ADDR_SIZE-1:0] araddr,
  input                  arvalid,

  // hot tracker interface
  input                  query_en,
  input  [CMD_WIDTH-1:0] query_cmd,
  output                 query_ready,
  input                  both_query_ready,
//  output                 mig_addr_en,
//  output [ADDR_SIZE-1:0] mig_addr,
//  input                  mig_addr_ready,

  output                 mig_en,
  output [ADDR_SIZE-1:0] top_1_addr,
  output [ADDR_SIZE-1:0] top_2_addr,
  output [ADDR_SIZE-1:0] top_3_addr,
  output [ADDR_SIZE-1:0] top_4_addr,
  output [ADDR_SIZE-1:0] top_5_addr,
  output [CNT_SIZE-1:0]  top_1_cnt,
  output [CNT_SIZE-1:0]  top_2_cnt,
  output [CNT_SIZE-1:0]  top_3_cnt,
  output [CNT_SIZE-1:0]  top_4_cnt,
  output [CNT_SIZE-1:0]  top_5_cnt,

  input  [2:0]           num_mig
);

// state
localparam STATE_IDLE   = 2'b00;
localparam STATE_ARADDR = 2'b10;
localparam EMPTY        = 10'd0;


logic                      arvalid_fifo;  
logic                      arready_fifo; 
logic [9:0]                ar_entry;

logic                      arvalid_h2c;
logic [ADDR_SIZE-1:0]      araddr_h2c;
logic                      arready_h2c;

//logic                      mig_addr_en_h2c;
//logic [ADDR_SIZE-1:0]      mig_addr_h2c;
//logic                      mig_addr_ready_h2c;

logic                      input_addr_valid;
logic [ADDR_SIZE-1:0]      input_addr;
logic                      input_addr_ready;

logic [1:0]                state, next_state; 


assign arvalid_fifo = arvalid;


always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    next_state <= 0;
  end
  else begin
    // first
    case(state)
      STATE_IDLE: begin
        if (arvalid_h2c) begin
          next_state <= STATE_ARADDR;
        end
        else begin
          next_state <= STATE_IDLE;
        end
      end
      STATE_ARADDR: begin
        if (~arvalid_h2c) begin
          next_state <= STATE_IDLE;
        end
        else if (input_addr_ready) begin
          if (ar_entry != EMPTY) begin
            next_state <= STATE_ARADDR;
          end
          else begin
            next_state <= STATE_IDLE;
          end
        end
        else begin
          next_state <= STATE_ARADDR;
        end
      end
      default:;
    endcase
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    input_addr  <= {ADDR_SIZE{1'b0}};
    input_addr_valid <= 1'b0;
  end
  else begin
    case(state)
      STATE_IDLE: begin
        input_addr  <= araddr_h2c;
        input_addr_valid <= 1'b0;
      end
      STATE_ARADDR: begin
        input_addr  <= araddr_h2c;
        input_addr_valid <= arvalid_h2c;
      end
      default:;
    endcase
  end
end

always_comb begin
  arready_h2c = 1'b0;
  case(state)
    STATE_IDLE: begin
      arready_h2c = 1'b0;
    end
    STATE_ARADDR: begin
      if (input_addr_valid & input_addr_ready)
        arready_h2c = 1'b1;
      else                  
        arready_h2c = 1'b0;
    end
    default:;
  endcase
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    ar_entry <= 10'd0;
  end
  else begin
    // entry + 1
    if (arvalid_fifo & arready_fifo & arvalid_h2c & arready_h2c) begin
      ar_entry <= ar_entry;
    end
    else if (arvalid_fifo & arready_fifo) begin
      ar_entry <= ar_entry + 10'd1;
    end
    else if (arvalid_h2c & arready_h2c) begin
      ar_entry <= ar_entry - 10'd1;
    end
    else begin
      ar_entry <= ar_entry;
    end
  end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    state <= STATE_IDLE;
  end
  else begin
    state <= next_state;
  end
end

// axis FIFO from CXL IP
logic [32:0] m_axis_tdata;
`ifndef XILINX
axis_data_fifo #(.DATA_WIDTH(33))
`else
// hot to cxl(h2c), cxl to hot(c2h)
axis_data_fifo_0 #(.DATA_WIDTH(33))
`endif
  araddr_fifo 
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),
  .s_axis_tready  ( arready_fifo),//( arready ),
  .m_axis_tready  ( arready_h2c ),
  .s_axis_tvalid  ( arvalid_fifo ),
  //.s_axis_tdata   ( {araddr[ADDR_SIZE-1:ADDR_SIZE-DATA_SIZE], {{ADDR_SIZE-DATA_SIZE}{1'b0}}} ),
  //.s_axis_tdata   ( {{(33-ADDR_SIZE){1'b0}}, araddr[ADDR_SIZE-1:ADDR_SIZE-DATA_SIZE], {(ADDR_SIZE-DATA_SIZE){1'b0}}} ),
  .s_axis_tdata   ( {{(33-DATA_SIZE){1'b0}}, araddr[ADDR_SIZE-1:ADDR_SIZE-DATA_SIZE]} ),
  .m_axis_tvalid  ( arvalid_h2c  ),
  .m_axis_tdata   ( m_axis_tdata )
);

assign araddr_h2c = m_axis_tdata[ADDR_SIZE-1:0];

/*
// axis FIFO to CXL IP
`ifndef XILINX
axis_data_fifo
`else
axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
`endif
  mig_addr_fifo
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),
  .s_axis_tready  ( mig_addr_ready_h2c ),
  .m_axis_tready  ( mig_addr_ready        ),
  .s_axis_tvalid  ( mig_addr_en_h2c ),
  .s_axis_tdata   ( mig_addr_h2c  ),
  .m_axis_tvalid  ( mig_addr_en  ),
  .m_axis_tdata   ( mig_addr        )
);
*/

// hot tracker core
hot_tracker_core
#(
  .NUM_ENTRY(NUM_ENTRY),
  .NUM_ENTRY_BITS(NUM_ENTRY_BITS), // log2 (NUM_ENTRY)
  .TOP_K(TOP_K),
  .ADDR_SIZE(ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE),
  .CMD_WIDTH(CMD_WIDTH)
)
  u_hot_tracker_core
(
  .clk                (clk),
  .rstn               (rstn),
  .input_addr         (input_addr),
  .input_addr_valid   (input_addr_valid),
  .input_addr_ready   (input_addr_ready),
  .query_en           (query_en),
  .query_cmd          (query_cmd),
  .query_ready        (query_ready),
  .both_query_ready   (both_query_ready),
//  .mig_addr_en        (mig_addr_en_h2c),
//  .mig_addr           (mig_addr_h2c),
//  .mig_addr_ready     (mig_addr_ready_h2c)
  .mig_en             (mig_en),
  .top_1_addr         (top_1_addr),
  .top_2_addr         (top_2_addr),
  .top_3_addr         (top_3_addr),
  .top_4_addr         (top_4_addr),
  .top_5_addr         (top_5_addr),
  .top_1_cnt          (top_1_cnt),
  .top_2_cnt          (top_2_cnt),
  .top_3_cnt          (top_3_cnt),
  .top_4_cnt          (top_4_cnt),
  .top_5_cnt          (top_5_cnt),
  .num_mig            (num_mig)
);

endmodule
