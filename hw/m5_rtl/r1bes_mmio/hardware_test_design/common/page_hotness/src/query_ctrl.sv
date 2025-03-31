
module query_ctrl #(
  parameter NUM_ENTRY = 50,
  parameter NUM_ENTRY_BITS = 6, // log2 (NUM_ENTRY)
  parameter CACHE_TOP_K = 5,
  parameter PAGE_TOP_K  = 2,
  parameter ADDR_SIZE = 28, // Cache line input size
  parameter CNT_SIZE = 13,
  parameter CMD_WIDTH = 4
) (
    input                         clk,
    input                         rstn,
    input  [31:0]                 rate,
    input                         mem_chan_rd_en,

    output logic                  query_en,
    output logic [CMD_WIDTH-1:0]  query_cmd,
    input                         query_ready,
    input                         mig_addr_en,
    input  [ADDR_SIZE-1:0]        mig_addr,
    output logic                  mig_addr_ready
);

// query opcode
localparam QUERY_IDLE         = 4'd0;
localparam QUERY_MIG          = 4'd1;
localparam QUERY_FLUSH        = 4'd2;

    logic [31:0] rate_counter_r;
 
    //  ===================================
    //              Timing block
    //  ===================================

    task do_reset();
        rate_counter_r <= '0;
    endtask

    task inc_rate_traffic_ctrl();
        if (rate_counter_r[30:0] >= rate[30:0]) begin
            rate_counter_r <= '0;
        end else if (mem_chan_rd_en) begin
            rate_counter_r <= rate_counter_r + 'b1;
        end
    endtask

    task inc_rate();
        if (rate_counter_r >= rate) begin
            rate_counter_r <= '0;
        end else begin
            rate_counter_r <= rate_counter_r + 'b1;
        end
    endtask

    always_ff @ (posedge clk) begin
        if (!rstn) begin
            do_reset(); 
        end else begin
            if (rate[31]) begin
                inc_rate_traffic_ctrl();
            end else begin
                inc_rate();
            end
        end
    end

    //  ===================================
    //              Combinational block
    //  ===================================
    function void set_default();
        query_en = 1'b0;
        query_cmd = QUERY_MIG;
        mig_addr_ready = 1'b1;
    endfunction

    function void rate_control();
        if (rate_counter_r[30:0] == rate[30:0] && rate != 0) begin
            query_en = 1'b1;
            query_cmd = QUERY_MIG;
        end
    endfunction

    always_comb begin
        set_default();        
        rate_control();
    end
endmodule
