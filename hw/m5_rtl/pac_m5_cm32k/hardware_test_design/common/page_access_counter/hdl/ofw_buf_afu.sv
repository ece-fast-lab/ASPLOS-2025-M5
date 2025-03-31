module ofw_buf_afu #(
    parameter OFW_BUF_SIZE = 4096       // in bytes
)
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
  
    input   logic [5:0]                 csr_awuser,
    input   logic [63:0]                ofw_buf_head,
    input   logic [63:0]                csr_ofw_buf_tail_max,
    output  logic [63:0]                ofw_buf_vld_cnt,

    input   logic                       ofw_q_empty,
    output  logic                       ofw_q_rdreq,
    input   logic [511:0]               ofw_q_rddata
);

    /* These are WRITE signals*/
    assign  awid         = '0     ; // Write address ID
    // assign  awaddr       = '0     ; // Write address. [63:52] are not used
    assign  awlen        = '0     ; // Burst length. Must be tied to 10'd0 = 1T/R
    assign  awsize       = 3'b110 ; // Burst size. Must be tied to 3'b110 = 64B/T
    assign  awburst      = '0     ; // Write burst type. Must be tied to 2'b00
    assign  awprot       = '0     ; // Write protection type. Must be tied to 3'b000
    assign  awqos        = '0     ; // Write quality of service indicator. Must be tied to 4'b0000
    // assign  awuser       = '0     ; // [3:0] Used for cache hint information. 4'b0 = Non-cacheable. [5] indicates the target memory type. 1 means HDM, 0 means host memory.
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

    /* User-defined variables */
    logic [63:0]    ofw_buf_base;
    logic [63:0]    ofw_buf_tail;
    logic [31:0]    ofw_buf_tail_ptr;
    logic ofw_q_rd_allowed;


    enum bit [1:0] {
        S_IDLE,
        S_WADDR,
        S_WDATA,
        S_WRESP
    } state, next_state;

    always_ff @( posedge axi4_mm_clk ) begin : state_machine_transition
        
        if (~axi4_mm_rst_n) begin
            state       <= S_IDLE;
            ofw_buf_vld_cnt <= '0;
            ofw_buf_base <= '0;
            ofw_buf_tail_ptr <= '0;
        end else begin
            state <= next_state;
            if (ofw_buf_head != '0 && ofw_buf_base == 0) begin          // only updates once
                ofw_buf_base <= ofw_buf_head;
            end

            if (bready & bvalid) begin
                if (ofw_buf_tail_ptr >= 32'(csr_ofw_buf_tail_max)) begin
                    ofw_buf_tail_ptr <= '0; 
                end else begin
                    ofw_buf_tail_ptr <= ofw_buf_tail_ptr + 1'b1;
                end
                ofw_buf_vld_cnt <= ofw_buf_vld_cnt + 1'b1;
            end
        end
    end

    assign ofw_buf_tail = ofw_buf_base + (ofw_buf_tail_ptr << 6); // was * 512 / 8, = * 64, = << 6
    assign ofw_q_rd_allowed = (ofw_buf_base != '0) && (~ofw_q_empty) && ((ofw_buf_vld_cnt == '0) || (ofw_buf_tail != ofw_buf_head));

    always_comb begin
        ofw_q_rdreq = '0;
        next_state = state;
        unique case (state)
            S_IDLE: begin
                if (ofw_q_rd_allowed) begin
                    next_state = S_WADDR;
                    ofw_q_rdreq = '1;
                end
            end

            S_WADDR: begin
                if (awvalid & awready & ~(wvalid & wready)) begin           // couldn't perform addr and data writes in this state
                    next_state = S_WDATA;
                end else begin
                    next_state = S_WRESP;
                end
            end


            S_WDATA: begin
                if (wvalid & wready) begin
                    next_state = S_WRESP;
                end
            end

            S_WRESP: begin
                if (bvalid) begin
                    if (ofw_q_rd_allowed) begin
                        next_state = S_WADDR;
                        ofw_q_rdreq = '1;
                    end else begin
                        next_state = S_IDLE;
                    end 
                end 
            end

            default:;
        endcase 
    end


    always_comb begin

        /* Set default values */
        awuser          = csr_awuser;
        awaddr          = ofw_buf_tail;
        awvalid         = 1'b0;

        wvalid          = 1'b0;
        wdata           = ofw_q_rddata;

        bready          = 1'b0;

        unique case (state)

            S_WADDR: begin
                awvalid         = 1'b1;
                wvalid          = 1'b1;         // Try to write here, if it fails we will anyways move to S_WDATA
            end

            S_WDATA: begin
                wvalid          = 1'b1;
            end

            S_WRESP: begin
                bready          = 1'b1;
            end

            default: ;
        endcase
    end



endmodule
