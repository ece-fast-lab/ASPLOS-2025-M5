
module m5_ctrl #(
  parameter NUM_ENTRY = 100,
  parameter NUM_ENTRY_BITS = 7, // log2 (NUM_ENTRY)
  parameter PAGE_TOP_K  = 5,
  parameter CACHE_TOP_K = 2,
  parameter ADDR_SIZE = 28, // Cache line input size
  parameter CNT_SIZE = 13
)(
    input clk,
    input rstn,

    input  [31:0]           cache_query_rate,
    input  [31:0]           page_query_rate,
    input                   mem_chan_rd_en,

    // hot page tracker interface
    output logic                  cache_query_en,
    input                         cache_query_ready,
    input                         cache_mig_addr_en,
    input  [ADDR_SIZE-1:0]        cache_mig_addr,
    output logic                  cache_mig_addr_ready,

    // hot cache tracker interface
    output logic                  page_query_en,
    input                         page_query_ready,
    input                         page_mig_addr_en,
    input  [ADDR_SIZE-1:0]        page_mig_addr,
    output logic                  page_mig_addr_ready
);

    query_ctrl page_query_ctrl(
        .clk                  (clk),
        .rstn                 (rstn),
        .rate                 (page_query_rate),
        .mem_chan_rd_en       (mem_chan_rd_en),
        .query_en             (page_query_en),
        .query_ready          (page_query_ready),
        .mig_addr_en          (page_mig_addr_en),
        .mig_addr             (page_mig_addr),
        .mig_addr_ready       (page_mig_addr_ready)
    );

    query_ctrl cache_query_ctrl(
        .clk                  (clk),
        .rstn                 (rstn),
        .rate                 (cache_query_rate),
        .mem_chan_rd_en       (mem_chan_rd_en),
        .query_en             (cache_query_en),
        .query_ready          (cache_query_ready),
        .mig_addr_en          (cache_mig_addr_en),
        .mig_addr             (cache_mig_addr),
        .mig_addr_ready       (cache_mig_addr_ready)
    );


endmodule
