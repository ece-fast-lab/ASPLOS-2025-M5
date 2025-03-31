/*
Module: hot_addr_pusher
Version: 0.0
Last Modified: July 18, 2024
Description: TODO
Workflow: 
    TODO
*/

// HAPB = Hot Address Pushing Buffer

module hot_addr_push
#(
  // common parameter
  parameter ADDR_SIZE = 33,
  parameter HAPB_SIZE = 64 * 1024      // 64kB
)
(

    input logic axi4_mm_clk,
    input logic axi4_mm_rst_n,

        // host pAddr input (Based on HW/SW sync buff)
        input logic [63:0]                  hapb_head,    // == host_pAddr, initial address assigned/last address read by software
        output logic [63:0]                 hapb_valid_count,    // hapb_valid_count * 512 = count of valid addresses in hapb

        // hot cache tracker interface (Unused for now, TODO)
        // input logic                         cache_mig_addr_en, 
        // input logic [ADDR_SIZE-1:0]         cache_mig_addr, 
        // output logic                        cache_mig_addr_ready, 

        // hot page tracker interface
        input logic                         page_mig_addr_en,
        input logic [ADDR_SIZE-1:0]         page_mig_addr,
        output logic                        page_mig_addr_ready,

        input logic [63:0] cxl_start_pa, // byte level address, start_pfn << 12
        input logic [63:0] cxl_addr_offset,
        input logic [32:0]  csr_addr_ub,
        input logic [32:0]  csr_addr_lb,


    input logic [5:0] csr_aruser,
    input logic [5:0] csr_awuser,

    // read address channel
    output logic [11:0]               arid,
    output logic [63:0]               araddr,
    output logic [9:0]                arlen,    // must tie to 10'd0
    output logic [2:0]                arsize,   // must tie to 3'b110
    output logic [1:0]                arburst,  // must tie to 2'b00
    output logic [2:0]                arprot,   // must tie to 3'b000
    output logic [3:0]                arqos,    // must tie to 4'b0000
    output logic [5:0]                aruser,   // 4'b0000": non-cacheable, 4'b0001: cacheable shared, 4'b0010: cacheable owned
    output logic                      arvalid,
    output logic [3:0]                arcache,  // must tie to 4'b0000
    output logic [1:0]                arlock,   // must tie to 2'b00
    output logic [3:0]                arregion, // must tie to 4'b0000
    input                             arready,

    // read response channel
    input [11:0]                      rid,    // no use
    input [511:0]                     rdata,  
    input [1:0]                       rresp,  // no use: 2'b00: OKAY, 2'b01: EXOKAY, 2'b10: SLVERR
    input                             rlast,  // no use
    input                             ruser,  // no use
    input                             rvalid,
    output logic                      rready,


    // write address channel
    output logic [11:0]               awid,
    output logic [63:0]               awaddr, 
    output logic [9:0]                awlen,    // must tie to 10'd0
    output logic [2:0]                awsize,   // must tie to 3'b110 (64B/T)
    output logic [1:0]                awburst,  // must tie to 2'b00            : CXL IP limitation
    output logic [2:0]                awprot,   // must tie to 3'b000
    output logic [3:0]                awqos,    // must tie to 4'b0000
    output logic [5:0]                awuser,
    output logic                      awvalid,
    output logic [3:0]                awcache,  // must tie to 4'b0000
    output logic [1:0]                awlock,   // must tie to 2'b00
    output logic [3:0]                awregion, // must tie to 4'b0000
    output logic [5:0]                awatop,   // must tie to 6'b000000
    input                             awready,

    // write data channel
    output logic [511:0]              wdata,
    output logic [(512/8)-1:0]        wstrb,
    output logic                      wlast,
    output logic                      wuser,  // must tie to 1'b0
    output logic                      wvalid,
    input                             wready,

    // write response channel
    input [11:0]                      bid,    // no use
    input [1:0]                       bresp,  // no use: 2'b00: OKAY, 2'b01: EXOKAY, 2'b10: SLVERR
    input [3:0]                       buser,  // must tie to 4'b0000
    input                             bvalid,
    output logic                      bready
);



assign  awlen        = '0   ;
assign  awsize       = 3'b110   ; // must tie to 3'b110
assign  awburst      = '0   ;
assign  awprot       = '0   ;
assign  awqos        = '0   ;

assign  awcache      = '0   ;
assign  awlock       = '0   ;
assign  awregion     = '0   ;
assign  awatop       = '0   ; 

assign  wuser        = '0   ;

assign  arlen        = '0   ;
assign  arsize       = 3'b110   ; // must tie to 3'b110
assign  arburst      = '0   ;
assign  arprot       = '0   ;
assign  arqos        = '0   ;

assign  arcache      = '0   ;
assign  arlock       = '0   ;
assign  arregion     = '0   ;


logic w_handshake;
logic aw_handshake;

// Assuming HAPB_SIZE is continuous in physical memory, no need to worry about page boundaries

logic [63:0]                                    hapb_pAddr_base;
logic                                           hapb_pAddr_ready;
logic [$clog2(HAPB_SIZE / (512/8)) - 1:0]       hapb_pAddr_offset; // log_2 ( HAPB_SIZE / (512 {bits/axi} / 8 {bits/bytes}) )

localparam HAPB_LOCAL_BUFF_SIZE = 12800;       // 400 addresses * 32 bits each

logic [HAPB_LOCAL_BUFF_SIZE-1:0]                hot_addr_pg_data;
logic [$clog2(HAPB_LOCAL_BUFF_SIZE/(ADDR_SIZE-1)) - 1:0]         hot_addr_pg_ptr;
logic                                           hot_addr_pg_valid;
logic                                           hot_addr_pg_ready;


// ================ hardware address conversion

logic                     h_pfn_en;
logic                     h_pfn_valid_pfn_guarded;
logic[31:0]               h_pfn_addr_i;
logic[63:0]               h_pfn_addr_cvtr_b4_module;
logic[63:0]               h_pfn_addr_cvtr;


logic [ADDR_SIZE-1:0]         page_mig_addr_r;
logic                         page_mig_addr_en_r;

assign h_pfn_valid_pfn_guarded = (page_mig_addr_r != '1);
// PFN to byte address
// 28 + 12 = 40
assign h_pfn_addr_cvtr_b4_module = ({24'h0, page_mig_addr_r, 12'h0} + cxl_addr_offset); // adding current address by offset, circular map to 8GB
assign h_pfn_addr_cvtr = {31'h0, h_pfn_addr_cvtr_b4_module[32:0]}; // modulo by 8GB = [32:0]

assign h_pfn_en = page_mig_addr_en_r & h_pfn_valid_pfn_guarded;
assign h_pfn_addr_i = h_pfn_addr_cvtr[43:12] + cxl_start_pa[63:12]; // taking PFN from byte address

// ================ hardware address conversion (end)

enum logic [4:0] {
    STATE_RESET,
    STATE_WR_SUB,
    STATE_WR_SUB_RESP
} state, next_state;

/*---------------------------------
functions
-----------------------------------*/
function void set_default();
    awvalid = 1'b0;
    wvalid = 1'b0;
    bready = 1'b0;
    arvalid = 1'b0;
    rready = 1'b0;
    arid = 'b0;
    araddr = 'b0;
    wdata = hot_addr_pg_data[(hot_addr_pg_ptr[$clog2(HAPB_LOCAL_BUFF_SIZE/(ADDR_SIZE-1)) - 1 : 4] - 1'b1) * 512 +: 512];
    aruser = 'b0;
    awaddr = 'b0;
    awid = 'b0;
    awuser = 'b0; 
    wlast = 1'b0;
    wstrb = 64'h0;

    page_mig_addr_ready = '0;
endfunction

function void reset_ff();
    state <= STATE_RESET;

    w_handshake <= 1'b0;
    aw_handshake <= 1'b0;

    hapb_pAddr_base <= '0;
    hapb_pAddr_offset <= '0;
    hapb_valid_count <= '0;

    hot_addr_pg_data <= '0;
    hot_addr_pg_ptr <= '0;
    hot_addr_pg_valid <= '0;

    page_mig_addr_r <= '0;
    page_mig_addr_en_r <= '0;
endfunction

always_ff @(posedge axi4_mm_clk) begin
    if (!axi4_mm_rst_n || hapb_head == '0) begin
        reset_ff();
    end

    else begin
        state <= next_state;
        unique case(state) 

            STATE_WR_SUB: begin
                if (awvalid & awready) begin
                    aw_handshake <= 1'b1;
                end
                if (wvalid & wready) begin  // nc-p-write can start, otherwise wait 
                    w_handshake <= 1'b1;
                    // the next installment for HAPB has already been sent, invalidate for next request
                    hot_addr_pg_valid <= '0;
                    hapb_pAddr_offset <= hapb_pAddr_offset + 'd1;
                end
            end

            STATE_WR_SUB_RESP: begin
                if (bvalid & bready) begin  // nc-p-write done
                    aw_handshake <= 1'b0;
                    w_handshake <= 1'b0;

                    // update valid count when transaction ended
                    hapb_valid_count <= hapb_valid_count + 'd1;
                end
            end
            default ;
        endcase

        // handle update for hapb_pAddr_base (should only happen once)
        if (hapb_pAddr_base == '0 & hapb_head != '0) begin
            hapb_pAddr_base <= hapb_head;
        end

        // load m5 addresses into a buffer
        if (page_mig_addr_ready & h_pfn_en & (h_pfn_addr_i != '0)) begin
            hot_addr_pg_data[hot_addr_pg_ptr*32 +: 32] <= h_pfn_addr_i[ADDR_SIZE-2:0];     // ignore bit 33 (ready) for now
            hot_addr_pg_ptr <= hot_addr_pg_ptr + 'd1;
            hot_addr_pg_valid <= '1;
        end

        page_mig_addr_en_r <= page_mig_addr_en;
        page_mig_addr_r <= page_mig_addr;
    end
end

// Start requesting m5 addresses when buffer is valid and full 
assign hot_addr_pg_ready = hot_addr_pg_valid & (hot_addr_pg_ptr[3:0] == '0);

// If hapb_pAddr_base is valid, and circular buffer (HAPB) doesn't overwrite valid unread addresses
assign hapb_pAddr_ready = (hapb_pAddr_base != '0) && ((hapb_valid_count == '0) || ((hapb_pAddr_base + (hapb_pAddr_offset*512)/8) != hapb_head));

// assign hapb_pAddr_ready = (hapb_pAddr_base != '0) & (((hapb_pAddr_base + ((hapb_pAddr_offset+1'b1) *512)/8 - hapb_head) != '0) == (hapb_valid_count != '0));

// (((hapb_pAddr_base + (hapb_pAddr_offset*512)/8) == hapb_head & hapb_valid_count == 0) | ((hapb_pAddr_base + (hapb_pAddr_offset*512)/8) != hapb_head & hapb_valid_count > 0))
// ((~(hapb_pAddr_base + (hapb_pAddr_offset*512)/8 - hapb_head) & ~hapb_valid_count) | ((hapb_pAddr_base + (hapb_pAddr_offset*512)/8 - hapb_head) & hapb_valid_count))

/*---------------------------------
FSM
-----------------------------------*/

always_comb begin
    next_state = state;
    unique case(state)
        STATE_RESET: begin
            // Can move to write requests if m5 buffer full, hapb_pAddr_ready valid
            if (hot_addr_pg_ready & hapb_pAddr_ready) begin
                next_state = STATE_WR_SUB;
            end else begin
                next_state = STATE_RESET;
            end
        end
        STATE_WR_SUB: begin         // TODO check AXI protocol implementation
            if (awready & wready) begin
                next_state = STATE_WR_SUB_RESP;
            end
            else if (wvalid == 1'b0) begin
                if (awready) begin
                    next_state = STATE_WR_SUB_RESP;
                end
                else begin
                    next_state = STATE_WR_SUB;
                end
            end
            else if (awvalid == 1'b0) begin
                if (wready) begin
                    next_state = STATE_WR_SUB_RESP;
                end
                else begin
                    next_state = STATE_WR_SUB;
                end
            end
            else begin
                next_state = STATE_WR_SUB;
            end
        end

        STATE_WR_SUB_RESP: begin
            if (bvalid & bready) begin
                next_state = STATE_RESET; 
            end
            else begin
                next_state = STATE_WR_SUB_RESP;
            end
        end

        default: begin
            next_state = STATE_RESET;
        end
    endcase
end

always_comb begin
    set_default();
    unique case(state)
        STATE_RESET: begin
            page_mig_addr_ready = ~hot_addr_pg_ready;
        end
        STATE_WR_SUB: begin
            if (aw_handshake == 1'b0) begin
                awvalid = 1'b1;
            end
            else begin
                awvalid = 1'b0;
            end
            awid = 12'd2;
            awuser = csr_awuser; 
            awaddr = hapb_pAddr_base + (hapb_pAddr_offset*512)/8;

            if (w_handshake == 1'b0) begin
                wvalid = 1'b1;
            end
            else begin
                wvalid = 1'b0;
            end
            wlast = 1'b1;
            wstrb = 64'hffffffffffffffff;
        end

        STATE_WR_SUB_RESP: begin
            bready = 1'b1;
        end

        default: begin

        end
    endcase
end

endmodule
