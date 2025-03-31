`timescale 1ns / 1ps

`ifndef XILINX 
`include "cxl_type2_defines.svh.iv"
`else
`include "cxl_type2_defines.svh"
`endif

import mc_axi_if_pkg::*;

module hot_tracker_top
#(
  parameter NUM_ENTRY = 50,
  parameter NUM_ENTRY_BITS = 6, // log2 (NUM_ENTRY)
  parameter TOP_K = 5,
  parameter ADDR_SIZE = 33, // Cache line input size
  parameter DATA_SIZE = 22,
  parameter CNT_SIZE = 13,
  parameter CMD_WIDTH = 4
)
(
  input clk_400mhz,
  input clk_200mhz,
  input rstn,

  input mc_axi_if_pkg::t_to_mc_axi4     cxlip2iafu_to_mc_axi4,
  input mc_axi_if_pkg::t_from_mc_axi4   mc2iafu_from_mc_axi4,

  // hot tracker interface
  input                   query_en,
  input  [CMD_WIDTH-1:0]  query_cmd,
  output                  query_ready,
  output                  mig_addr_en,
  output [ADDR_SIZE-1:0]  mig_addr,
  input                   mig_addr_ready,
  output                  mem_chan_rd_en,

  input  [ADDR_SIZE-1:0]  csr_addr_ub,
  input  [ADDR_SIZE-1:0]  csr_addr_lb
);


/////////////////////////////////
//--   Wire/Reg Definition   --//
/////////////////////////////////

// Interface to/from CXL IP
logic [mc_axi_if_pkg::MC_AXI_RAC_ADDR_BW-1:0] araddr;
logic                                         arvalid;
logic                                         arready;
logic                                         arvalid_fifo;
logic                                         addr_within_range;

logic                 mig_addr_en_r;
logic [ADDR_SIZE-1:0] mig_addr_r;

// CDC (Clock Domain Crossing) Asynchonous FIFOs
logic [ADDR_SIZE-1:0] even_cdc_data_in;
logic                 even_cdc_wrreq;
logic                 even_cdc_rdreq;
logic [1023:0]        even_cdc_q;
logic [ADDR_SIZE-1:0] even_cdc_data_out;
logic                 even_cdc_rdempty;
logic                 even_cdc_wrfull;
logic [ADDR_SIZE-1:0] odd_cdc_data_in;
logic                 odd_cdc_wrreq;
logic                 odd_cdc_rdreq;
logic [1023:0]        odd_cdc_q;
logic [ADDR_SIZE-1:0] odd_cdc_data_out;
logic                 odd_cdc_rdempty;
logic                 odd_cdc_wrfull;
logic [CMD_WIDTH-1:0] query_cdc_data_in;
logic                 query_cdc_wrreq;
logic                 query_cdc_rdreq;
logic [1023:0]        query_cdc_q;
logic [CMD_WIDTH-1:0] query_cdc_data_out;
logic                 query_cdc_rdempty;
logic                 query_cdc_wrfull;
logic [ADDR_SIZE-1:0] mig_cdc_data_in;
logic                 mig_cdc_wrreq;
logic                 mig_cdc_rdreq;
logic [1023:0]        mig_cdc_q;
logic [ADDR_SIZE-1:0] mig_cdc_data_out;
logic                 mig_cdc_rdempty;
logic                 mig_cdc_wrfull;

// Hot Tracker Core and FIFO
logic                 core_query_en;
logic [CMD_WIDTH-1:0] core_query_cmd;
logic [ADDR_SIZE-1:0] even_araddr;
logic                 even_arvalid;
logic                 even_query_ready;
logic                 even_mig_addr_ready;
logic [ADDR_SIZE-1:0] odd_araddr;
logic                 odd_arvalid;
logic                 odd_query_ready;
logic                 even_mig_en;
logic [ADDR_SIZE-1:0] even_top_1_addr;
logic [ADDR_SIZE-1:0] even_top_2_addr;
logic [ADDR_SIZE-1:0] even_top_3_addr;
logic [ADDR_SIZE-1:0] even_top_4_addr;
logic [ADDR_SIZE-1:0] even_top_5_addr;
logic [CNT_SIZE-1:0]  even_top_1_cnt;
logic [CNT_SIZE-1:0]  even_top_2_cnt;
logic [CNT_SIZE-1:0]  even_top_3_cnt;
logic [CNT_SIZE-1:0]  even_top_4_cnt;
logic [CNT_SIZE-1:0]  even_top_5_cnt;
logic [2:0]           even_num_mig;
logic                 odd_mig_en;
logic [ADDR_SIZE-1:0] odd_top_1_addr;
logic [ADDR_SIZE-1:0] odd_top_2_addr;
logic [ADDR_SIZE-1:0] odd_top_3_addr;
logic [ADDR_SIZE-1:0] odd_top_4_addr;
logic [ADDR_SIZE-1:0] odd_top_5_addr;
logic [CNT_SIZE-1:0]  odd_top_1_cnt;
logic [CNT_SIZE-1:0]  odd_top_2_cnt;
logic [CNT_SIZE-1:0]  odd_top_3_cnt;
logic [CNT_SIZE-1:0]  odd_top_4_cnt;
logic [CNT_SIZE-1:0]  odd_top_5_cnt;
logic [2:0]           odd_num_mig;

logic                 both_query_ready;

assign both_query_ready = even_query_ready & odd_query_ready;

// Delays
logic  even_cdc_rdreq_d1;
logic  odd_cdc_rdreq_d1;
logic  query_cdc_rdreq_d1;
logic  mig_cdc_rdreq_d1;

//////////////////////////////////////
//--   Interface To/From CXL IP   --//
//////////////////////////////////////

always_comb begin
  araddr  = cxlip2iafu_to_mc_axi4.araddr;
  arvalid = cxlip2iafu_to_mc_axi4.arvalid;
  arready = mc2iafu_from_mc_axi4.arready;
end

logic [ADDR_SIZE-1:0]  csr_addr_ub_r;
logic [ADDR_SIZE-1:0]  csr_addr_lb_r;

assign addr_within_range = (araddr[ADDR_SIZE-1:0] <= csr_addr_ub_r) & (araddr[ADDR_SIZE-1:0] >= csr_addr_lb_r);
assign arvalid_fifo = arvalid & arready & addr_within_range;
assign mem_chan_rd_en = arvalid_fifo;

always_ff @ (posedge clk_400mhz) begin
    if(!rstn) begin
        csr_addr_ub_r <= 'b0;
        csr_addr_lb_r <= 'b0;
    end else begin // 125MHz CSR, assume stable and no CDC
        csr_addr_ub_r <= csr_addr_ub;
        csr_addr_lb_r <= csr_addr_lb;
    end
end


/////////////////////////////////////
//--   CXL IP To/From CDC FIFO   --//
/////////////////////////////////////

// We don't care fullness of CDC FIFOs considering sampling (skipping).

always_ff @ (posedge clk_400mhz or negedge rstn) begin
  if (!rstn) begin
    even_cdc_wrreq   <= 1'b0;
    even_cdc_data_in <= {ADDR_SIZE{1'b1}};
  end 
  else begin
    if (arvalid_fifo & araddr[ADDR_SIZE-DATA_SIZE] == 1'b0) begin
      even_cdc_wrreq   <= 1'b1;
      even_cdc_data_in <= araddr[ADDR_SIZE-1:0];
    end 
    else begin
      even_cdc_wrreq   <= 1'b0;
      even_cdc_data_in <= {ADDR_SIZE{1'b1}};
    end 
  end 
end

always_ff @ (posedge clk_400mhz or negedge rstn) begin
  if (!rstn) begin
    odd_cdc_wrreq   <= 1'b0;
    odd_cdc_data_in <= {ADDR_SIZE{1'b1}};
  end 
  else begin
    if (arvalid_fifo & araddr[ADDR_SIZE-DATA_SIZE] == 1'b1) begin
      odd_cdc_wrreq   <= 1'b1;
      odd_cdc_data_in <= araddr[ADDR_SIZE-1:0];
    end 
    else begin
      odd_cdc_wrreq   <= 1'b0;
      odd_cdc_data_in <= {ADDR_SIZE{1'b1}};
    end 
  end 
end

always_ff @ (posedge clk_400mhz or negedge rstn) begin
  if (!rstn) begin
    query_cdc_wrreq   <= 1'b0;
    query_cdc_data_in <= {ADDR_SIZE{1'b0}};
  end 
  else begin
    if (query_en & query_ready) begin
      query_cdc_wrreq   <= 1'b1;
      query_cdc_data_in <= query_cmd;
    end 
    else begin
      query_cdc_wrreq   <= 1'b0;
      query_cdc_data_in <= {ADDR_SIZE{1'b0}};
    end 
  end 
end

assign query_ready = ~query_cdc_wrfull;


//////////////////////////////////////////////
//--   CDC FIFO To/From Hot Tracker Core  --//
//////////////////////////////////////////////

assign even_cdc_rdreq = ~even_cdc_rdempty;

always_ff @ (posedge clk_200mhz or negedge rstn) begin
  if (!rstn) begin
    even_arvalid <= 1'b0;
    even_araddr  <= {ADDR_SIZE{1'b1}};
  end 
  else begin
    if (even_arvalid) begin // For preventing consecutive memory reqeusts (kinds of sampling)
      even_arvalid <= 1'b0;
      even_araddr  <= {ADDR_SIZE{1'b1}};
    end
    else if (even_cdc_rdreq_d1) begin
      even_arvalid <= 1'b1;
      even_araddr  <= even_cdc_data_out;
    end
    else begin
      even_arvalid <= 1'b0;
      even_araddr  <= {ADDR_SIZE{1'b1}};
    end
  end 
end

assign odd_cdc_rdreq  = ~odd_cdc_rdempty;

always_ff @ (posedge clk_200mhz or negedge rstn) begin
  if (!rstn) begin
    odd_arvalid <= 1'b0;
    odd_araddr  <= {ADDR_SIZE{1'b1}};
  end 
  else begin
    if (odd_arvalid) begin // For preventing consecutive memory reqeusts (kinds of sampling)
      odd_arvalid <= 1'b0;
      odd_araddr  <= {ADDR_SIZE{1'b1}};
    end
    else if (odd_cdc_rdreq_d1) begin
      odd_arvalid <= 1'b1;
      odd_araddr  <= odd_cdc_data_out;
    end
    else begin
      odd_arvalid <= 1'b0;
      odd_araddr  <= {ADDR_SIZE{1'b1}};
    end
  end 
end

assign query_cdc_rdreq  = (~query_cdc_rdempty);

always_ff @ (posedge clk_200mhz or negedge rstn) begin
  if (!rstn) begin
    core_query_en  <= 1'b0;
    core_query_cmd <= {CMD_WIDTH{1'b0}};
  end 
  else begin
    if (core_query_en) begin
      core_query_en  <= 1'b0;
      core_query_cmd <= {CMD_WIDTH{1'b0}};
    end
    else if (query_cdc_rdreq_d1) begin
      core_query_en  <= 1'b1;
      core_query_cmd <= query_cdc_data_out;
    end
    else begin
      core_query_en  <= 1'b0;
      core_query_cmd <= {CMD_WIDTH{1'b0}};
    end
  end 
end

assign mig_cdc_rdreq = mig_addr_ready & (~mig_cdc_rdempty);

always_ff @ (posedge clk_400mhz or negedge rstn) begin
  if (!rstn) begin
    mig_addr_en_r   <= 1'b0;
    mig_addr_r <= {ADDR_SIZE{1'b1}};
  end 
  else begin
    if (mig_cdc_rdreq_d1) begin
      mig_addr_en_r   <= 1'b1;
      mig_addr_r <= mig_cdc_data_out;
    end
    else begin
      mig_addr_en_r <= 1'b0;
      mig_addr_r    <= {ADDR_SIZE{1'b1}};
    end
  end 
end

assign mig_addr_en = mig_addr_en_r;
assign mig_addr = mig_addr_r;

////////////////////
//--   Delays   --//
////////////////////
always_ff @ (posedge clk_200mhz or negedge rstn) begin
  if (!rstn) begin
    even_cdc_rdreq_d1  <= 1'b0;
    odd_cdc_rdreq_d1   <= 1'b0;
    query_cdc_rdreq_d1 <= 1'b0;
  end 
  else begin
    even_cdc_rdreq_d1  <= even_cdc_rdreq;
    odd_cdc_rdreq_d1   <= odd_cdc_rdreq;
    query_cdc_rdreq_d1 <= query_cdc_rdreq;
  end 
end

always_ff @ (posedge clk_400mhz or negedge rstn) begin
  if (!rstn) begin
    mig_cdc_rdreq_d1   <= 1'b0;
  end 
  else begin
    mig_cdc_rdreq_d1   <= mig_cdc_rdreq;
  end 
end


////////////////////////////////////////////////
//--   CDC Asynchonous FIFO Instantiation   --//
////////////////////////////////////////////////

// From CXL IP to Hot Tracker
fifo_cdc_to_mc_axi4
  even_cdc_async_fifo
(
  .data    ( {{(1024-ADDR_SIZE){1'b0}}, even_cdc_data_in} ), //   input,  width = 1024,  fifo_input.datain
  .wrreq   ( even_cdc_wrreq                               ), //   input,     width = 1,            .wrreq
  .rdreq   ( even_cdc_rdreq                               ), //   input,     width = 1,            .rdreq
  .wrclk   ( clk_400mhz                                   ), //   input,     width = 1,            .wrclk
  .rdclk   ( clk_200mhz                                   ), //   input,     width = 1,            .rdclk
  .q       ( even_cdc_q                                   ), //  output,  width = 1024, fifo_output.dataout
  .rdempty ( even_cdc_rdempty                             ), //  output,     width = 1,            .rdempty
  .wrfull  ( even_cdc_wrfull                              )  //  output,     width = 1,            .wrfull
);  

assign even_cdc_data_out = even_cdc_q[ADDR_SIZE-1:0];

// From CXL IP to Hot Tracker
fifo_cdc_to_mc_axi4
  odd_cdc_async_fifo
(
  .data    ( {{(1024-ADDR_SIZE){1'b0}}, odd_cdc_data_in} ), //   input,  width = 1024,  fifo_input.datain
  .wrreq   ( odd_cdc_wrreq                               ), //   input,     width = 1,            .wrreq
  .rdreq   ( odd_cdc_rdreq                               ), //   input,     width = 1,            .rdreq
  .wrclk   ( clk_400mhz                                  ), //   input,     width = 1,            .wrclk
  .rdclk   ( clk_200mhz                                  ), //   input,     width = 1,            .rdclk
  .q       ( odd_cdc_q                                   ), //  output,  width = 1024, fifo_output.dataout
  .rdempty ( odd_cdc_rdempty                             ), //  output,     width = 1,            .rdempty
  .wrfull  ( odd_cdc_wrfull                              )  //  output,     width = 1,            .wrfull
);  

assign odd_cdc_data_out = odd_cdc_q[ADDR_SIZE-1:0];

// From CXL IP to Hot Tracker
fifo_cdc_to_mc_axi4
  query_cdc_async_fifo
(
  .data    ( {{(1024-CMD_WIDTH){1'b0}}, query_cdc_data_in} ), //   input,  width = 1024,  fifo_input.datain
  .wrreq   ( query_cdc_wrreq                               ), //   input,     width = 1,            .wrreq
  .rdreq   ( query_cdc_rdreq                               ), //   input,     width = 1,            .rdreq
  .wrclk   ( clk_400mhz                                    ), //   input,     width = 1,            .wrclk
  .rdclk   ( clk_200mhz                                    ), //   input,     width = 1,            .rdclk
  .q       ( query_cdc_q                                   ), //  output,  width = 1024, fifo_output.dataout
  .rdempty ( query_cdc_rdempty                             ), //  output,     width = 1,            .rdempty
  .wrfull  ( query_cdc_wrfull                              )  //  output,     width = 1,            .wrfull
);

assign query_cdc_data_out = query_cdc_q[CMD_WIDTH-1:0];

// From Hot Tracker to CXL IP
fifo_cdc_to_mc_axi4
  mig_cdc_async_fifo
(
  .data    ( {{(1024-ADDR_SIZE){1'b0}}, mig_cdc_data_in} ), //   input,  width = 1024,  fifo_input.datain
  .wrreq   ( mig_cdc_wrreq                               ), //   input,     width = 1,            .wrreq
  .rdreq   ( mig_cdc_rdreq                               ), //   input,     width = 1,            .rdreq
  .wrclk   ( clk_200mhz                                  ), //   input,     width = 1,            .wrclk
  .rdclk   ( clk_400mhz                                  ), //   input,     width = 1,            .rdclk
  .q       ( mig_cdc_q                                   ), //  output,  width = 1024, fifo_output.dataout
  .rdempty ( mig_cdc_rdempty                             ), //  output,     width = 1,            .rdempty
  .wrfull  ( mig_cdc_wrfull                              )  //  output,     width = 1,            .wrfull
);

assign mig_cdc_data_out = mig_cdc_q[ADDR_SIZE-1:0];

////////////////////////////////////////////////////
//--   Hot Tracker Core and FIFO Instantiation  --//
////////////////////////////////////////////////////

core_n_fifo
#(
  .NUM_ENTRY(NUM_ENTRY),
  .NUM_ENTRY_BITS(NUM_ENTRY_BITS), // log2 (NUM_ENTRY)
  .TOP_K(TOP_K),
  .ADDR_SIZE(ADDR_SIZE),
  .DATA_SIZE(DATA_SIZE),
  .CNT_SIZE(CNT_SIZE),
  .CMD_WIDTH(CMD_WIDTH)
)
  even_core_n_fifo
(
  .clk                (clk_200mhz),
  .rstn               (rstn),
  .araddr             (even_araddr),
  .arvalid            (even_arvalid),

  .query_en           (core_query_en),
  .query_cmd          (core_query_cmd),
  .query_ready        (even_query_ready),
  .both_query_ready   (both_query_ready),
  .mig_en             (even_mig_en),
  .top_1_addr         (even_top_1_addr),
  .top_2_addr         (even_top_2_addr),
  .top_3_addr         (even_top_3_addr),
  .top_4_addr         (even_top_4_addr),
  .top_5_addr         (even_top_5_addr),
  .top_1_cnt          (even_top_1_cnt),
  .top_2_cnt          (even_top_2_cnt),
  .top_3_cnt          (even_top_3_cnt),
  .top_4_cnt          (even_top_4_cnt),
  .top_5_cnt          (even_top_5_cnt),
  .num_mig            (even_num_mig)
);

core_n_fifo
#(
  .NUM_ENTRY(NUM_ENTRY),
  .NUM_ENTRY_BITS(NUM_ENTRY_BITS), // log2 (NUM_ENTRY)
  .TOP_K(TOP_K),
  .ADDR_SIZE(ADDR_SIZE),
  .DATA_SIZE(DATA_SIZE),
  .CNT_SIZE(CNT_SIZE),
  .CMD_WIDTH(CMD_WIDTH)
)
  odd_core_n_fifo
(
  .clk                (clk_200mhz),
  .rstn               (rstn),
  .araddr             (odd_araddr),
  .arvalid            (odd_arvalid),

  .query_en           (core_query_en),
  .query_cmd          (core_query_cmd),
  .query_ready        (odd_query_ready),
  .both_query_ready   (both_query_ready),
  .mig_en           (odd_mig_en),
  .top_1_addr         (odd_top_1_addr),
  .top_2_addr         (odd_top_2_addr),
  .top_3_addr         (odd_top_3_addr),
  .top_4_addr         (odd_top_4_addr),
  .top_5_addr         (odd_top_5_addr),
  .top_1_cnt          (odd_top_1_cnt),
  .top_2_cnt          (odd_top_2_cnt),
  .top_3_cnt          (odd_top_3_cnt),
  .top_4_cnt          (odd_top_4_cnt),
  .top_5_cnt          (odd_top_5_cnt),
  .num_mig            (odd_num_mig)
);


/////////////////////////////////////////////////////
//--   Migration Address Selector Instantiation  --//
/////////////////////////////////////////////////////

mig_addr_selector
#(
  .ADDR_SIZE(ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE),
  .TOP_K(TOP_K)
)
  u_mig_addr_selctor
(
  .clk                  (clk_200mhz),
  .rstn                 (rstn),
  .mig_cdc_fifo_valid   (mig_cdc_wrreq),
  .mig_cdc_fifo_data_in (mig_cdc_data_in),
  .mig_cdc_fifo_ready   (~mig_cdc_wrfull),
  .even_mig_en          (even_mig_en),
  .even_top_1_addr      (even_top_1_addr),
  .even_top_2_addr      (even_top_2_addr),
  .even_top_3_addr      (even_top_3_addr),
  .even_top_4_addr      (even_top_4_addr),
  .even_top_5_addr      (even_top_5_addr),
  .even_top_1_cnt       (even_top_1_cnt),
  .even_top_2_cnt       (even_top_2_cnt),
  .even_top_3_cnt       (even_top_3_cnt),
  .even_top_4_cnt       (even_top_4_cnt),
  .even_top_5_cnt       (even_top_5_cnt),
  .even_num_mig         (even_num_mig),
  .odd_mig_en           (odd_mig_en),
  .odd_top_1_addr       (odd_top_1_addr),
  .odd_top_2_addr       (odd_top_2_addr),
  .odd_top_3_addr       (odd_top_3_addr),
  .odd_top_4_addr       (odd_top_4_addr),
  .odd_top_5_addr       (odd_top_5_addr),
  .odd_top_1_cnt        (odd_top_1_cnt),
  .odd_top_2_cnt        (odd_top_2_cnt),
  .odd_top_3_cnt        (odd_top_3_cnt),
  .odd_top_4_cnt        (odd_top_4_cnt),
  .odd_top_5_cnt        (odd_top_5_cnt),
  .odd_num_mig          (odd_num_mig)
);


endmodule
