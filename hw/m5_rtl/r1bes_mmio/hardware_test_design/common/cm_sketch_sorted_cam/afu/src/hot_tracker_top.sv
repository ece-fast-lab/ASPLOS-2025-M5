`timescale 1ns / 1ps

`ifndef XILINX 
`include "cxl_type2_defines.svh.iv"
`else
`include "cxl_type2_defines.svh"
`endif

import mc_axi_if_pkg::*;

module hot_tracker_top
#(
  // common parameter
  parameter ADDR_SIZE = 33,
  parameter DATA_SIZE = 21,
  parameter CNT_SIZE = 14,

  // CM-sketch parameter
  parameter W = 4096,
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter HASH_SIZE = $clog2(W),

  // sorted CAM parameter
  parameter NUM_ENTRY = 25,
  parameter INDEX_SIZE = 5 // $clog2(NUM_ENTRY)
)
(
  input clk,
  input rstn,

  input mc_axi_if_pkg::t_to_mc_axi4     cxlip2iafu_to_mc_axi4,
  input mc_axi_if_pkg::t_from_mc_axi4   mc2iafu_from_mc_axi4,

  // hot tracker interface
  input                   query_en,
  output                  query_ready,

  output                  mig_addr_en,
  output [ADDR_SIZE-1:0]  mig_addr,
  input                   mig_addr_ready,
  output                  mem_chan_rd_en,

  input  [ADDR_SIZE-1:0]  csr_addr_ub,
  input  [ADDR_SIZE-1:0]  csr_addr_lb
);

// state
localparam STATE_IDLE   = 2'b00;
localparam STATE_AWADDR = 2'b01;
localparam STATE_ARADDR = 2'b10;
localparam EMPTY        = 10'd0;

//logic [mc_axi_if_pkg::MC_AXI_WAC_ADDR_BW-1:0] awaddr;
//logic                                         awvalid;
//logic                                         awready;
logic [mc_axi_if_pkg::MC_AXI_RAC_ADDR_BW-1:0] araddr;
logic                                         arvalid;
logic                                         arready;

logic                                         addr_within_range;

//logic                      awvalid_fifo;
logic                      arvalid_fifo;  
//logic                      awready_fifo;
logic                      arready_fifo; 
//logic [9:0]                aw_entry;                    
logic [9:0]                ar_entry;
logic                      araddr_full;
logic                      mig_addr_full;
logic                      araddr_empty;
logic                      mig_addr_empty;

//logic                      awvalid_h2c;
//logic [ADDR_SIZE-1:0]      awaddr_h2c;
//logic                      awready_h2c;
logic                      arvalid_h2c;
logic [ADDR_SIZE-1:0]      araddr_h2c;
logic                      arready_h2c;

logic                      mig_addr_en_h2c;
logic [DATA_SIZE-1:0]      mig_addr_h2c;
logic                      mig_addr_ready_h2c;

logic                      input_addr_valid;
logic [ADDR_SIZE-1:0]      input_addr;
logic                      input_addr_ready;

logic [1:0]                state, next_state; 

always_comb
  begin
    //awaddr  = cxlip2iafu_to_mc_axi4.awaddr;
    //awvalid = cxlip2iafu_to_mc_axi4.awvalid;
    //awready = mc2iafu_from_mc_axi4.awready;

    araddr  = cxlip2iafu_to_mc_axi4.araddr;
    arvalid = cxlip2iafu_to_mc_axi4.arvalid;
    arready = mc2iafu_from_mc_axi4.arready;
  end

//assign awvalid_fifo = awvalid & awready;

logic [ADDR_SIZE-1:0]  csr_addr_ub_r;
logic [ADDR_SIZE-1:0]  csr_addr_lb_r;

assign addr_within_range = (araddr[ADDR_SIZE-1:0] <= csr_addr_ub_r) & (araddr[ADDR_SIZE-1:0] >= csr_addr_lb_r);
assign arvalid_fifo = arvalid & arready & addr_within_range; // for simulation, exclude addr_within_range
assign mem_chan_rd_en = arvalid_fifo;

always_ff @ (posedge clk) begin
    if(!rstn) begin
        csr_addr_ub_r <= 'b0;
        csr_addr_lb_r <= 'b0;
    end else begin // 125MHz CSR, assume stable and no CDC
        csr_addr_ub_r <= csr_addr_ub;
        csr_addr_lb_r <= csr_addr_lb;
    end
end

always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    next_state <= 0;
  end
  else begin
    // first
    case(state)
      STATE_IDLE: begin
        //if (awvalid_h2c) begin
        //  next_state <= STATE_AWADDR;
        //end
        //else if (arvalid_h2c) begin
        if (arvalid_h2c) begin
          next_state <= STATE_ARADDR;
        end
        else begin
          next_state <= STATE_IDLE;
        end
      end
      /*
      STATE_AWADDR: begin
        if (input_addr_ready) begin
          if (ar_entry != EMPTY) begin
            next_state <= STATE_ARADDR;
          end
          else if (aw_entry != EMPTY) begin
            next_state <= STATE_AWADDR;
          end
          else begin
            next_state <= STATE_IDLE;
          end
        end
        else begin
          next_state <= STATE_AWADDR;
        end
      end
      */
      STATE_ARADDR: begin
        if (~arvalid_h2c) begin
          next_state <= STATE_IDLE;
        end
        else if (input_addr_ready) begin
          /*
          if (aw_entry != EMPTY) begin
            next_state <= STATE_AWADDR;
          end
          else if (ar_entry != EMPTY) begin
          */
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
        //input_addr  <= {ADDR_SIZE{1'b0}};
        input_addr  <= araddr_h2c;
        input_addr_valid <= 1'b0;
      end
      /*
      STATE_AWADDR: begin
        input_addr  <= awaddr_h2c;
        input_addr_valid <= awvalid_h2c;
      end
      */
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
      //awready_h2c <= 1'b0;
      arready_h2c = 1'b0;
    end
    STATE_ARADDR: begin
      if (input_addr_valid & input_addr_ready)
        arready_h2c = 1'b1;
      else                  
        arready_h2c = 1'b0;
      //awready_h2c <= 1'b0;
    end
    default:;
  endcase
end
/*
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    //awready_h2c <= 1'b0;
    arready_h2c <= 1'b0;
  end
  else begin
    case(state)
      STATE_IDLE: begin
        //awready_h2c <= 1'b0;
        arready_h2c <= 1'b0;
      end
      STATE_ARADDR: begin
        if (input_addr_valid & input_addr_ready & ~(query_en & (query_cmd == QUERY_MIG))) 
          arready_h2c <= 1'b1;
        else                  
          arready_h2c <= 1'b0;
        //awready_h2c <= 1'b0;
      end
      default:;
    endcase
  end
end
*/
/*
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    aw_entry <= 10'd0;
  end
  else begin
    // entry + 1
    if (awvalid_fifo & awready_fifo & awvalid_h2c & awready_h2c) begin
      aw_entry <= aw_entry;
    end
    else if (awvalid_fifo & awready_fifo) begin
      aw_entry <= aw_entry + 10'd1;
    end
    else if (awvalid_h2c & awready_h2c) begin
      aw_entry <= aw_entry - 10'd1;
    end
    else begin
      aw_entry <= aw_entry;
    end
  end
end
*/

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

/*
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    input_addr_valid <= 1'b0;
  end
  else begin
    input_addr_valid <= awvalid_h2c | arvalid_h2c;
  end
end
*/
always_ff @ (posedge clk or negedge rstn) begin
  if (!rstn) begin
    state <= STATE_IDLE;
  end
  else begin
    state <= next_state;
  end
end

// axis FIFO to CXL IP
/*
axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
  awaddr_fifo
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),
  .s_axis_tready  ( awready_fifo ),//( awready ),
  .m_axis_tready  ( awready_h2c ),
  .s_axis_tvalid  ( awvalid_fifo ),
  .s_axis_tdata   ( awaddr      ),
  //.s_axis_tkeep   ( s_axis_h2c_tkeep        ),
  //.s_axis_tlast   ( s_axis_h2c_tlast        ),
  .m_axis_tvalid  ( awvalid_h2c  ),
  .m_axis_tdata   ( awaddr_h2c   )
  //.m_axis_tkeep   ( s_axis_h2c_tkeep_fifo   ),
  //.m_axis_tlast   ( s_axis_h2c_tlast_fifo   )
);
*/

`ifndef XILINX
axis_data_fifo
`else
axis_data_fifo_0 // hot to cxl(h2c), cxl to hot(c2h)
`endif
  araddr_fifo
(
  .s_axis_aclk    ( clk            ),
  .s_axis_aresetn ( rstn           ),
  .s_axis_tready  ( arready_fifo),//( arready ),
  .m_axis_tready  ( arready_h2c ),
  .s_axis_tvalid  ( arvalid_fifo ),
  .s_axis_tdata   ({{(ADDR_SIZE-DATA_SIZE){1'b0}}, araddr[ADDR_SIZE-1:ADDR_SIZE-DATA_SIZE]}),  
  .m_axis_tvalid  ( arvalid_h2c  ),
  .m_axis_tdata   ( araddr_h2c   )
);

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
  .s_axis_tdata   ( mig_addr_h2c ),
  .m_axis_tvalid  ( mig_addr_en  ),
  .m_axis_tdata   ( mig_addr  )
);


// hot tracker
hot_tracker
#(
  // common parameter
  .ADDR_SIZE(ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE),

  // CM-sketch parameter
  .W(W),
  .NUM_HASH(NUM_HASH),
  .HASH_SIZE(HASH_SIZE),

  // sorted CAM parameter
  .NUM_ENTRY(NUM_ENTRY),
  .INDEX_SIZE(INDEX_SIZE)
)
  u_hot_tracker
(
  .clk                (clk),
  .rst_n              (rstn),

  .input_addr         (input_addr),
  .input_addr_valid   (input_addr_valid),
  .input_addr_ready   (input_addr_ready),

  .query_en           (query_en),
  .query_ready        (query_ready),

  .mig_addr_en        (mig_addr_en_h2c),
  .mig_addr           (mig_addr_h2c),
  .mig_addr_ready     (mig_addr_ready_h2c)
);

endmodule
