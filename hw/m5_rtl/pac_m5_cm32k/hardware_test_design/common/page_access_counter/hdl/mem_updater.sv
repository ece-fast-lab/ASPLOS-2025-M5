import ctrl_signal_types::*;

module mem_updater (

    input logic mclk,
    input logic reset_n,

    // control signals
    input   logic           start,
    input   updater_mode_t  mode, 
    input   logic [63:0]    buffer_addr,
    output  logic           done,
    output  logic           hold_reqfifo,

    // from EMIF
    input logic [MC_CHANNEL-1:0]            mem_ready_mclk,
    input logic [MC_HA_DP_DATA_WIDTH-1:0]   mem_readdata_mclk [MC_CHANNEL-1:0],
    input logic [MC_CHANNEL-1:0]            mem_readdatavalid_mclk,

    // to/from counter buffer
    output  logic [SRAM_DATA_WIDTH-1:0] buf_data,      
    input   logic [SRAM_DATA_WIDTH-1:0] buf_q,         
    output  logic [SRAM_ADDR_WIDTH-1:0] buf_wraddress, 
    output  logic [SRAM_ADDR_WIDTH-1:0] buf_rdaddress, 
    output  logic        buf_wren,    

    // to EMIF
    output mem_request_t mem_request,
    
    // DEBUG
    input logic [31:0] write_back_cnt
);

    
    logic           clear_sram_addr;
    logic           inc_sram_addr;
    logic [SRAM_ADDR_WIDTH-1:0] sram_buff_addr_r;  // used for read write to sram. 1 bit wider than address to prevent overflow.

    logic           clear_mem_addr;
    logic           inc_mem_addr;
    logic [SRAM_ADDR_WIDTH-1:0] mem_buff_addr_r;  // points to the counter we are operating
    
    logic           load_dump_data;
    logic [511:0]   dump_data;
    logic [63:0]    buffer_addr_reg;
    
    enum bit [4:0] { IDLE, ZERO_OUT_INIT, ZERO_OUT_WR, 
                    COPY_TO_DRAM_INIT, COPY_TO_DRAM_FETCH, COPY_TO_DRAM_FETCH_DONE, 
                    COPY_TO_DRAM_DUMP, DONE } state_r, state_n;

    // =====================================================
    //                    registers 
    // =====================================================

    task set_sram_addr();
        sram_buff_addr_r <= sram_buff_addr_r; // default to hold the same value
        case ({clear_sram_addr, inc_sram_addr}) 
            2'b10: sram_buff_addr_r <= '0;
            2'b01: sram_buff_addr_r <= sram_buff_addr_r + 1'b1;
            // the other cases are more/less errors
        endcase
    endtask

    task set_mem_addr();
        mem_buff_addr_r <= mem_buff_addr_r; // default to hold the same value
        case ({clear_mem_addr, inc_mem_addr}) 
            2'b10: mem_buff_addr_r <= '0;
            2'b01: mem_buff_addr_r <= mem_buff_addr_r + 1'b1; // emif write step = 64 bytes. EMIF operates on 64 bytes granularity
            // the other cases are more/less errors
        endcase
    endtask
    
    task set_dump_data();
        dump_data <= dump_data;
        if (load_dump_data) begin
            //dump_data <= {dump_data[511-SRAM_DATA_WIDTH:0], buf_q};
            dump_data <= buf_q;
        end
    endtask

    always_ff @( posedge mclk ) begin : update_logic
        if (~reset_n) begin
            state_r          <= IDLE;
            sram_buff_addr_r <= '0;
            mem_buff_addr_r  <= '0;
            dump_data        <= '0;
            buffer_addr_reg  <= '0;
        end else begin
            state_r <= state_n; // update in state_machine
            set_sram_addr();
            set_mem_addr();
            set_dump_data();
            
            if (start & (mode == WRITE_BACK_COUNTER) & (state_r == IDLE)) begin
                buffer_addr_reg <= buffer_addr;
            end
        end
    end


    // =====================================================
    //                     states 
    // =====================================================

    // state machine only mark transition
    //      default to not transit
    always_comb begin : state_machine
        state_n = state_r; // default
        case (state_r)
            IDLE: begin
                if (start & mode == WRITE_BACK_COUNTER) begin
                    // state_n = COPY_TO_DRAM_INIT;
                    state_n = IDLE; // turn off the original writeback functionality
                end else if (start & mode == ZERO_OUT_COUNTER) begin
                    state_n = ZERO_OUT_INIT;
                end
            end

            // ============================================
            //              clear sram 
            // ============================================
            ZERO_OUT_INIT: state_n = ZERO_OUT_WR;

            ZERO_OUT_WR: begin
                if (sram_buff_addr_r == '1) state_n = DONE;
            end

            // ============================================
            //              copy to dram
            // ============================================
            COPY_TO_DRAM_INIT: state_n = COPY_TO_DRAM_FETCH;

            COPY_TO_DRAM_FETCH: begin
                // FIXME, assume 16 bit, dump every 32 fetch
                // if (sram_buff_addr_r[4:0] & 5'h1F == 5'h1F) state_n = COPY_TO_DRAM_FETCH_DONE;
                // assume 512 bits
                state_n = COPY_TO_DRAM_FETCH_DONE;
            end

            // This is a buffering state, last sram data is shifted into
            // dump_data. See waveform for more detail
            COPY_TO_DRAM_FETCH_DONE: state_n = COPY_TO_DRAM_DUMP;
            
            COPY_TO_DRAM_DUMP: begin
                if (mem_ready_mclk) begin
                    //FIXME, DEBUG, write back 1024 entries
                    if (sram_buff_addr_r == write_back_cnt) begin
                        state_n = DONE;
                    end else begin
                        state_n = COPY_TO_DRAM_FETCH;
                    end
                end  // else, stay and hold

                // FIXME, remove this after debugging
                // state_n = DONE;
            end

            DONE: state_n = IDLE;

            default: state_n = IDLE;

        endcase
    end


    // =====================================================
    //                      signals
    // =====================================================
    function void set_signal_default();
        buf_data        = '0;
        buf_rdaddress   = sram_buff_addr_r;
        buf_wraddress   = sram_buff_addr_r;
        buf_wren        = 1'b0;
        done            = 1'b0;

        clear_sram_addr = 1'b0;
        inc_sram_addr   = 1'b0;

        clear_mem_addr  = 1'b0;
        inc_mem_addr    = 1'b0;

        load_dump_data  = 1'b0;

        mem_request = mem_request_t'(0); // request.write is set to 0 here

        hold_reqfifo = 1'b0; // FIXED: no default value was given.
    endfunction

    // set buf to all to 0
    function void do_zero_out();
        buf_wren      = 1'b1;
        buf_data      = '0;
        inc_sram_addr = 1'b1;
    endfunction

    function void do_sram_fetch();
        buf_rdaddress  = sram_buff_addr_r;
        inc_sram_addr  = 1'b1;
        load_dump_data = 1'b1;
    endfunction

    /*
    function void do_mem_dump();
        mem_request.writedata       = dump_data;
        mem_request.byteenable      = {MC_HA_DP_BE_WIDTH{1'b1}};
        mem_request.address         = mem_buff_addr_r + buffer_addr_reg;
        mem_request.write           = mem_ready_mclk;
        inc_mem_addr                = mem_ready_mclk;
    endfunction
    */
    // FIXME, remove this after debugging
    function void do_mem_dump();
        //mem_request.writedata       = {510'hA1B2C3D4E5F6A2B3C4D5E6F, mem_buff_addr_r[1:0]};
        //mem_request.writedata        = dump_data;
        mem_request.writedata       = dump_data;
        mem_request.byteenable      = {MC_HA_DP_BE_WIDTH{1'b1}};

        mem_request.address         = mem_buff_addr_r + buffer_addr_reg;
        //mem_request.address         = buffer_addr_reg;
        
        // mem_request.write           = mem_ready_mclk;
        mem_request.write           = 1'b1;
        inc_mem_addr                = mem_ready_mclk;
    endfunction

    always_comb begin : state_signals
        set_signal_default();

        case (state_r)
            IDLE: ;

            ZERO_OUT_INIT: begin // read out val
                clear_sram_addr = 1'b1;
            end
            ZERO_OUT_WR: begin
                do_zero_out();
            end

            COPY_TO_DRAM_INIT: begin
                clear_sram_addr = 1'b1;
                clear_mem_addr  = 1'b1;
            end

            COPY_TO_DRAM_FETCH: begin
                do_sram_fetch();
            end

            COPY_TO_DRAM_FETCH_DONE: begin
                hold_reqfifo = 1'b1;
            end

            COPY_TO_DRAM_DUMP: begin
                do_mem_dump();
                if (~mem_ready_mclk) hold_reqfifo = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

            default: ;
        endcase
    end
endmodule
