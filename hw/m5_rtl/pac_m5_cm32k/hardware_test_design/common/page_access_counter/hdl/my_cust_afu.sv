import ctrl_signal_types::SRAM_ADDR_WIDTH;
import ctrl_signal_types::SRAM_DATA_WIDTH;

module my_cust_afu
(

	// Clocks
    input logic  axi4_mm_clk, 

    // Resets
    input logic  axi4_mm_rst_n,

    /*
        AXI-MM interface - write address channel
    */
    output logic [11:0]               awid,
    output logic [63:0]               awaddr, 
    output logic [9:0]                awlen,
    output logic [2:0]                awsize,
    output logic [1:0]                awburst,
    output logic [2:0]                awprot,
    output logic [3:0]                awqos,
    output logic [5:0]                awuser,
    output logic                      awvalid,
    output logic [3:0]                awcache,
    output logic [1:0]                awlock,
    output logic [3:0]                awregion,
    output logic [5:0]                awatop,
    input                             awready,
  
    /*
        AXI-MM interface - write data channel
    */
    output logic [511:0]              wdata,
    output logic [(512/8)-1:0]        wstrb,
    output logic                      wlast,
    output logic                      wuser,
    output logic                      wvalid,
    // output logic [7:0]                wid,
    input                             wready,
  
    /*
        AXI-MM interface - write response channel
    */ 
    input [11:0]                     bid,
    input [1:0]                      bresp,
    input [3:0]                      buser,
    input                            bvalid,
    output logic                     bready,
  
    /*
        AXI-MM interface - read address channel
    */
    output logic [11:0]               arid,
    output logic [63:0]               araddr,
    output logic [9:0]                arlen,
    output logic [2:0]                arsize,
    output logic [1:0]                arburst,
    output logic [2:0]                arprot,
    output logic [3:0]                arqos,
    output logic [4:0]                aruser,
    output logic                      arvalid,
    output logic [3:0]                arcache,
    output logic [1:0]                arlock,
    output logic [3:0]                arregion,
    input                             arready,

    /*
        AXI-MM interface - read response channel
    */ 
    input logic [11:0]               rid,
    input logic [511:0]              rdata,
    input logic [1:0]                rresp,
    input logic                      rlast,
    input logic                      ruser,
    input logic                      rvalid,
    output logic                     rready,
  
    /* From CSR */
    input logic [63:0]              write_back_base_addr,

    /* Control signals */
    input  logic                    write_back_start,
    output logic                    write_back_done,

    /* From/To buffer */
    output logic [SRAM_ADDR_WIDTH-1:0]  cafu2buf_rdaddress,
    input  logic [SRAM_DATA_WIDTH-1:0]  buf2cafu_q,
    input  logic                        buf2cafu_q_valid, // for synchronization purpose
    output logic                        cafu2buf_req
);

// These are INPUTs

//assign awready = 1'b0;    IP ready to accept write address
//assign wready  = 1'b0;    IP ready to accept write data
//assign arready = 1'b0;
//assign bid     = 16'h0;   Write response ID
//assign bresp   = 4'h0;    Write response status
//assign buser   = 4'h0;    Always 0
//assign bvalid  = 1'b0;    Write response valid
//
//assign rid     = 16'h0; 
//assign rdata   = 512'h0;
//assign rresp   = 4'h0;
//assign rlast   = 1'b0;
//assign ruser   = 4'h0;
//assign rvalid  = 1'b0;


    /* These are WRITE signals*/
    assign  awid         = '0     ; // Write address ID
    // assign  awaddr       = '0     ; // Write address. [63:52] are not used
    assign  awlen        = '0     ; // Burst length. Must be tied to 10'd0 = 1T/R
    assign  awsize       = 3'b110 ; // Burst size. Must be tied to 3'b110 = 64B/T
    assign  awburst      = '0     ; // Write burst type. Must be tied to 2'b00
    assign  awprot       = '0     ; // Write protection type. Must be tied to 3'b000
    assign  awqos        = '0     ; // Write quality of service indicator. Must be tied to 4'b0000
    assign  awuser       = '0     ; // [3:0] Used for cache hint information. 4'b0 = Non-cacheable. [5] indicates the target memory type. 1 means HDM, 0 means host memory.
    // assign  awvalid      = '0     ; // Write address valid indicator
    assign  awcache      = '0     ; // Write memory type. Must be tied to 4'b0000
    assign  awlock       = '0     ; // Write lock access type. Must be tied to 2'b00
    assign  awregion     = '0     ; // Write region indicator. Must be tied to to 4'b0000
    assign  awatop       = '0     ; // atmoic operation. '0 = Non-atomic operation
    // assign  wdata        = '0     ; // Write data [511:0]
    assign  wstrb        = '1     ; // Write strobes [63:0]. Indicates which lanes are in use.
    assign  wlast        = 1'b1   ; // Indicates the last write transfer in a burst. Since the burst length is always 1, set to 1 for convenince.
    assign  wuser        = '0     ; // Write data poison
    // assign  wvalid       = '0     ; // Write data valid indicator



    // assign  wid          = '0   ;

    /* These are READ related signals */
    // assign  bready       = '0     ; // We are ready to accept write response
    assign  arid         = '0   ;
    assign  araddr       = '0   ;
    assign  arlen        = '0   ;
    assign  arsize       = '0   ;
    assign  arburst      = '0   ;
    assign  arprot       = '0   ;
    assign  arqos        = '0   ;
    assign  aruser       = '0   ;
    assign  arvalid      = '0   ;
    assign  arcache      = '0   ;
    assign  arlock       = '0   ;
    assign  arregion     = '0   ;
    assign  rready       = '0   ;

    localparam BUF_SIZE = 2**SRAM_ADDR_WIDTH*2**6; // 2^16*2^6=2^22=4MB region

    /* User-defined variables */
    logic [63:0]    awaddr_reg;
    logic [63:0]    awaddr_next;
    logic [SRAM_ADDR_WIDTH-1:0] bufaddr_reg;
    logic [SRAM_ADDR_WIDTH-1:0] bufaddr_next;
    logic [511:0]   wdata_reg;
    logic [511:0]   wdata_next;
    logic [511:0]   wdata_test;
    logic [3:0]     done_cnt; // in order to cross time domain


    /* Generate test writedata */
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            wdata_test[64*i +: 64] = awaddr_reg + i;
        end
    end


    enum bit [3:0] {
        S_IDLE,
        S_SEND_BUF_REQ,
        S_WADDR,
        S_WDATA,
        S_WRESP,
        S_WAIT_BUF_RESP_DEASSERT,
        S_DONE
    } state;

    always_ff @( posedge axi4_mm_clk ) begin : state_machine_transition
        
        if (~axi4_mm_rst_n) begin
            state       <= S_IDLE;
            done_cnt    <= '0;
            awaddr_reg  <= '0;
            bufaddr_reg <= '0;
            wdata_reg   <= '0;
        end else begin

            awaddr_reg  <= awaddr_next;
            wdata_reg   <= wdata_next;
            bufaddr_reg <= bufaddr_next;

            case (state)
                S_IDLE: begin
                    if (write_back_start) begin
                        state <= S_SEND_BUF_REQ;
                    end
                end

                S_SEND_BUF_REQ: begin
                    if (buf2cafu_q_valid) begin
                        state <= S_WADDR;
                    end
                end

                S_WADDR: begin
                    if (awready) begin
                        state <= S_WDATA;
                    end
                end

                S_WDATA: begin
                    if (wready) begin
                        state <= S_WRESP;
                    end
                end

                S_WRESP: begin
                    if (bvalid && bresp == 2'b00) begin
                        state <= S_WAIT_BUF_RESP_DEASSERT; // else we stuck in this state. Check it with isWritingBack signal
                    end 
                end

                S_WAIT_BUF_RESP_DEASSERT: begin
                    if (buf2cafu_q_valid == 1'b0) begin
                        if (awaddr_next >= (write_back_base_addr + BUF_SIZE)) begin
                            state <= S_DONE;
                        end else begin
                            state <= S_SEND_BUF_REQ;
                        end
                    end
                end

                S_DONE: begin
                    done_cnt <= done_cnt + 1;
                    if (done_cnt == 15) state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase


        end

    end

    always_comb begin

        /* Set default values */
        wvalid          = 1'b0;
        wdata           = 512'b0;
        wdata_next      = wdata_reg;
        awvalid         = 1'b0;
        bready          = 1'b0;
        awaddr          = 64'b0; 
        awaddr_next     = awaddr_reg;
        bufaddr_next    = bufaddr_reg;
        cafu2buf_req  = 1'b0; // this signal will be 1 until we finished writing bac this entry
        write_back_done = 1'b0;
        cafu2buf_rdaddress = bufaddr_reg;

        case (state)
            S_IDLE: begin
                awaddr_next     = write_back_base_addr; // FIXED: write_back_base_addr was never used!
                bufaddr_next    = '0;
            end

            S_SEND_BUF_REQ: begin
                cafu2buf_req     = 1'b1;
                if (buf2cafu_q_valid) begin
                    wdata_next = buf2cafu_q;
                end
            end

            S_WADDR: begin
                cafu2buf_req    = 1'b1;
                awaddr          = awaddr_reg;
                awvalid         = 1'b1;
            end

            S_WDATA: begin
                cafu2buf_req    = 1'b1;
                wvalid          = 1'b1;
                wdata           = wdata_reg;
            end

            S_WRESP: begin
                cafu2buf_req    = 1'b1;
                bready          = 1'b1;
                if (bvalid) begin
                    awaddr_next  = awaddr_reg + 64;
                    bufaddr_next = bufaddr_reg + 1;
                end
            end

            S_WAIT_BUF_RESP_DEASSERT: begin
                // deasserted the q_req signal
            end

            S_DONE: begin
                write_back_done = 1'b1; 
            end

            default: ;
        endcase
    end



endmodule


