import ctrl_signal_types::MONITOR_REGION_WIDTH;

module custom_csr_top #(
    parameter REGFILE_SIZE = 32,
    parameter UPDATE_SIZE  = 8
)(
 
// AVMM Slave Interface
    input               avmm_clk,
    input               reset_n,
    input  logic [63:0] writedata,
    input  logic        read,
    input  logic        write,
    input  logic [7:0]  byteenable,
    output logic [63:0] readdata,
    output logic        readdatavalid,
    input  logic [21:0] address,
    output logic        waitrequest,
    

    // for monitor
    input               afu_clk,
    input               afu_reset_n,
    input logic cxlip2iafu_read_eclk,
    input logic cxlip2iafu_write_eclk,

    // for tracker
    output logic [31:0] page_query_rate,
    output logic [31:0] cache_query_rate,
    output logic [63:0] cxl_start_pa, // byte level address, start_pfn << 12
    output logic [63:0] cxl_addr_offset,
    input logic page_mig_addr_en,
    input logic [27:0]  page_mig_addr,
    input logic cache_mig_addr_en,
    input logic [27:0]  cache_mig_addr,

    // old eac signals
    input  logic        is_writing_back,
    output logic        csr_zero_out,
    output logic        csr_write_back,
    output logic [63:0] write_back_addr,
    output logic [31:0] csr_write_back_cnt,
    output logic [MONITOR_REGION_WIDTH-1:0]  csr_monitor_region,
    output logic [63:0] csr_ofw_buf_tail_max,

    output	logic [5:0]  csr_awuser,
    output	logic [63:0] csr_ofw_buf_head,
    input	logic [63:0] csr_ofw_buf_vld_cnt,

    output logic [63:0] cfg_reg

);

    logic [63:0] data [REGFILE_SIZE];    // CSR regfile
    logic [63:0] readdata_gray;
    logic [63:0] csr_config;
    logic [63:0] mask;
    logic [19:0] address_shift3;
    logic config_access; 
    logic [1:0] stretch_cnt;
    logic is_writing_back_aclk;

    logic[63:0] csr_ofw_buf_vld_cnt_eclk, csr_ofw_buf_vld_cnt_aclk;

    assign mask[7:0]   = byteenable[0]? 8'hFF:8'h0; 
    assign mask[15:8]  = byteenable[1]? 8'hFF:8'h0; 
    assign mask[23:16] = byteenable[2]? 8'hFF:8'h0; 
    assign mask[31:24] = byteenable[3]? 8'hFF:8'h0; 
    assign mask[39:32] = byteenable[4]? 8'hFF:8'h0; 
    assign mask[47:40] = byteenable[5]? 8'hFF:8'h0; 
    assign mask[55:48] = byteenable[6]? 8'hFF:8'h0; 
    assign mask[63:56] = byteenable[7]? 8'hFF:8'h0; 

    assign config_access = address[21];  
    assign address_shift3 = address[21:3];

    assign cfg_reg = csr_config;

    enum int unsigned { IDLE = 0, WRITE = 2, READ_GRAY = 3, READ_GRAY_2 = 4, READ = 5 } state, next_state;
    // =================================
    //          h_pfn logics
    // =================================
    // read by CSR unit
    logic[9:0]                h_pfn_rd_idx;
    logic[31:0]               h_pfn_addr_o;
    // Output to CSR unit / M5 manager
    logic[9:0]                h_pfn_wr_idx_o;
    logic                     h_pfn_wr_overflow;
    // reset write idx by CSR unit, ok
    logic                     h_pfn_wr_idx_rst;

    // write by tracker, ok
    logic                     h_pfn_wr_en;
    logic[31:0]               h_pfn_addr_i;

    logic                     h_pfn_rd_en;
    logic                     h_pfn_valid_pfn_guarded;
    logic[63:0]               h_pfn_addr_cvtr_b4_module;
    logic[63:0]               h_pfn_addr_cvtr;
    logic                     is_h_pfn;


    assign h_pfn_valid_pfn_guarded = (page_mig_addr != '1);
    // PFN to byte address
    // 28 + 12 = 40
    assign h_pfn_addr_cvtr_b4_module = ({24'h0, page_mig_addr, 12'h0} + cxl_addr_offset); // adding current address by offset, circular map to 8GB
    assign h_pfn_addr_cvtr = {31'h0, h_pfn_addr_cvtr_b4_module[32:0]}; // modulo by 8GB = [32:0]

    assign h_pfn_rd_idx = address_shift3 - 20'd4096;
    assign h_pfn_wr_en = page_mig_addr_en & h_pfn_valid_pfn_guarded;
    assign h_pfn_addr_i = h_pfn_addr_cvtr[43:12] + cxl_start_pa[63:12]; // taking PFN from byte address
    assign h_pfn_rd_en = read && address_shift3 >= 20'd4096 && address_shift3 < 20'd8192 && (state == IDLE);

    // =================================
    //          h_cache logics
    // =================================
    // read by CSR unit
    logic[12:0]               h_cache_rd_idx;
    logic[63:0]               h_cache_addr_o;
    // Output to core_push kmod
    logic[12:0]               h_cache_wr_idx_o;
    logic                     h_cache_wr_overflow;
    // reset write idx by CSR unit, ok
    logic                     h_cache_wr_idx_rst;

    // write by tracker, ok
    logic                     h_cache_wr_en;
    logic[63:0]               h_cache_addr_i;

    logic                     h_cache_rd_en;
    logic                     h_cache_valid_pfn_guarded;
    logic[63:0]               h_cache_addr_cvtr_b4_module;
    logic[63:0]               h_cache_addr_cvtr;
    logic                     is_h_cache;


    assign h_cache_valid_pfn_guarded = (cache_mig_addr != '1);
    // PFN to byte address
    // 28 + 6 = 34
    assign h_cache_addr_cvtr_b4_module = ({30'h0, cache_mig_addr, 6'h0} + cxl_addr_offset); // adding current address by offset, circular map to 8GB
    assign h_cache_addr_cvtr = {31'h0, h_cache_addr_cvtr_b4_module[32:0]}; // modulo by 8GB = [32:0]

    assign h_cache_rd_idx = address_shift3 - 20'd8192;
    //assign h_cache_wr_en = cache_mig_addr_en & h_cache_valid_pfn_guarded;
    assign h_cache_wr_en = 1'b0; // remove h cache for M5 + PAC 
    assign h_cache_addr_i = {h_cache_addr_cvtr[63:6] + cxl_start_pa[63:6], 6'h0}; // taking PFN from byte address
    //assign h_cache_rd_en = read && address_shift3 >= 20'd8192 && address_shift3 < 20'd16384 && (state == IDLE);
    assign h_cache_rd_en = 1'b0; // remove h cache for M5 + PAC 


    altera_std_synchronizer_nocut #(
        .depth(3)
    ) synchronizer_inst_isWritingBack (
		.clk            (avmm_clk),
		.reset_n        (1'b1),
		.din            (is_writing_back),
		.dout           (is_writing_back_aclk)
	);


    //Write logic
    always @(posedge avmm_clk) begin : config_write_logic
        if (!reset_n) begin
            csr_config <= '0;
            for (int i = UPDATE_SIZE; i < REGFILE_SIZE; i++) begin
                // if (write && address_shift3 == i) begin // why do we need this in for reset??
                //     data[i] <= '0;
                // end
                data[i] <= '0;
            end
        end else begin
            /* bit 21 = 0: memory space; bit 21 = 1: config space */
            // if (write && (address[20:0] == '0) && config_access) begin // changed the way we reset the counters
            //     csr_config <= writedata & mask;
            // end 

            if (write && address[20:0] == 'b0 && writedata == 64'hACE0BEEF) begin
                csr_config <= 100;
            end

            /* count down the csr_config[0] to 0 after it is set to 100 */
            if (csr_config > 0) begin
                csr_config <= csr_config - 1;
            end 

            for (int i = UPDATE_SIZE; i < REGFILE_SIZE; i++) begin
                if (write && address_shift3 == i) begin
                    data[i] <= writedata & mask;
                end
            end

            data[23] <= csr_ofw_buf_vld_cnt_aclk;
        end    
    end 

    //Read logic
    always @(posedge avmm_clk) begin
        if (!reset_n) begin
            readdata  <= 64'h0;
        end
        else begin
            readdata <= readdata_gray;    
            if (read && (address_shift3 < REGFILE_SIZE) && (state == IDLE)) begin 
                readdata_gray <= data[address_shift3] & mask; // Use synchronizer
            end else if(read && (address[20:0] == '0) && config_access && (state == IDLE)) begin
                readdata_gray <= csr_config & mask;
            end else if (is_h_pfn && (state == READ_GRAY_2)) begin
                // read from fifo
                // maybe do not do gray ' <if fifo next cycle output>
                    // state = IDLE, assert read, send out address
                    // state = READ_GRAY, data out, load to readdata
                    // (skipping readdata_gray)
                    // state = READ, readdata output the right content
                readdata <= {16'h7469, address[15:0], h_pfn_addr_o};
                readdata_gray <= {16'h7469, address[15:0], h_pfn_addr_o};
            end else if (is_h_cache && (state == READ_GRAY_2)) begin
                // read from fifo
                // maybe do not do gray ' <if fifo next cycle output>
                    // state = IDLE, assert read, send out address
                    // state = READ_GRAY, data out, load to readdata
                    // (skipping readdata_gray)
                    // state = READ, readdata output the right content
                readdata <= {h_cache_addr_o};
                readdata_gray <= {h_cache_addr_o};
            end else begin
                readdata_gray <= {32'hFEDCBA00, address[15:0], 16'hABCD};
            end    
        end    
    end 


    //Control Logic

    always_comb begin : next_state_logic
        next_state = IDLE;
            case(state)
            IDLE    : begin 
                if( write ) begin
                    next_state = WRITE;
                end else if (read) begin
                    next_state = READ_GRAY;
                end else begin
                    next_state = IDLE;
                end
            end

            WRITE     : begin
                next_state = IDLE;
            end

            READ_GRAY : begin
                if (is_h_pfn | is_h_cache) begin
                    next_state = READ_GRAY_2;
                end else begin
                    next_state = READ;
                end
            end

            READ_GRAY_2: begin
                next_state = READ;
            end

            READ      : begin
                next_state = IDLE;
            end

            default : next_state = IDLE;
        endcase
    end


    always_comb begin
    case(state)
        IDLE    : begin
            waitrequest  = 1'b1;
            readdatavalid= 1'b0;
        end
        WRITE     : begin 
            waitrequest  = 1'b0;
            readdatavalid= 1'b0;
        end
        READ_GRAY: begin
            waitrequest  = 1'b0;
            readdatavalid= 1'b0;
        end
        READ     : begin 
            waitrequest  = 1'b0;
            readdatavalid= 1'b1;
        end
        default : begin 
            waitrequest  = 1'b1;
            readdatavalid= 1'b0;
        end
    endcase
    end

    always_ff@(posedge avmm_clk) begin
        if(~reset_n) begin
            state <= IDLE;
            is_h_pfn <= 1'b0;
            is_h_cache <= 1'b0;
        end else if (state == IDLE & read) begin
            is_h_pfn <= address_shift3 >= 20'd4096 && address_shift3 < 32'd8192;
            is_h_cache <= address_shift3 >= 20'd8192 && address_shift3 < 32'd16384;
            state <= next_state;
        end else begin
            state <= next_state;
        end
    end

    // ==============================
    // input --> register 
    // ==============================
    logic [63:0] debug_counter;
    logic [63:0] memRead_counter;
    logic [63:0] memWrite_counter;
    logic [63:0] memRead_counter_buf;
    logic [63:0] memWrite_counter_buf;
    logic [63:0] memRead_counter_aclk;
    logic [63:0] memWrite_counter_aclk;
    logic [63:0] page_mig_counter;
    logic [63:0] cache_mig_counter;
    logic [31:0] page_mig_addr_reg;
    logic [31:0] cache_mig_addr_reg;
    logic [31:0] h_pfn_overflow_counter;
    logic [31:0] h_cache_overflow_counter;
    logic [5:0]  sync_cnt;

    always_ff @( posedge afu_clk ) begin
        if (~afu_reset_n) begin
            sync_cnt            <= '0;
            memRead_counter     <= '0;
            memWrite_counter    <= '0;
            memRead_counter_buf     <= '0;
            memWrite_counter_buf    <= '0;
            csr_ofw_buf_vld_cnt_eclk <= 0;
        end else begin
            if (cxlip2iafu_read_eclk != 0) begin
                memRead_counter <= memRead_counter + 1;
            end
            if (cxlip2iafu_write_eclk != 0) begin
                memWrite_counter <= memWrite_counter + 1;
            end 
            // Assign the counter to the counter buffer every 2^6 cycles
            sync_cnt <= sync_cnt + 1'b1;
            if (sync_cnt == 0) begin
                csr_ofw_buf_vld_cnt_eclk <= csr_ofw_buf_vld_cnt;
                memRead_counter_buf     <= memRead_counter;
                memWrite_counter_buf    <= memWrite_counter;
            end
        end
    end

    always_ff @( posedge avmm_clk ) begin
        // A naive two-stage synchronizer
        csr_ofw_buf_vld_cnt_aclk <= csr_ofw_buf_vld_cnt_eclk;
        memRead_counter_aclk    <= memRead_counter_buf;
        memWrite_counter_aclk   <= memWrite_counter_buf;
    end

    task reset_reg();
        read_flag           <= 1'b0;
        write_flag          <= 1'b0;
        debug_counter       <= '0;
        // memRead_counter     <= '0;
        // memWrite_counter    <= '0;
        page_mig_counter    <= '0;
        cache_mig_counter   <= '0;
        page_mig_addr_reg   <= '0;
        cache_mig_addr_reg  <= '0;
        h_pfn_overflow_counter <= '0;
        h_cache_overflow_counter <= '0;

        for (int i = 0; i < UPDATE_SIZE; i++) begin
            data[i] <= '0;
        end
    endtask

    task set_reg_0();
        // clock
        debug_counter <= debug_counter + 1;
        if (debug_counter >= 10000) begin
            data[0]         <= data[0] + 1;
            debug_counter   <= '0;
        end
    endtask

    task set_reg_1();
        // cxl read count
        // if (cxlip2iafu_read_eclk != 0) begin
        //     memRead_counter <= memRead_counter + 1;
        // end
        data[1] <= memRead_counter_aclk;
    endtask

    task set_reg_2();
        // if (cxlip2iafu_write_eclk != 0) begin
        //     memWrite_counter <= memWrite_counter + 1;
        // end 
        data[2] <= memWrite_counter_aclk;
    endtask

    task set_reg_3();
        if (page_mig_addr_en) begin
            page_mig_counter <= page_mig_counter + 1;
        end
        data[3] <= page_mig_counter;
    endtask

    task set_reg_4();
        if (cache_mig_addr_en) begin
            cache_mig_counter <= cache_mig_counter + 1;
        end
        data[4] <= cache_mig_counter;
    endtask

    //      used for debug for now
    // upper 32 bit = page migration address
    // lower 32 bit = cache migration address 
    task set_reg_5();
        /*
        // debug DDEE / DDEC tag
        if (page_mig_addr_en) begin
            page_mig_addr_reg <= {4'hDDEC, page_mig_addr};
        end
        if (cache_mig_addr_en) begin
            cache_mig_addr_reg <= {4'hDDEE, cache_mig_addr};
        end*/
        page_mig_addr_reg <= {4'h9, page_mig_addr};
        cache_mig_addr_reg <= {4'h4, cache_mig_addr};
        data[5] <= {page_mig_addr_reg, cache_mig_addr_reg};
    endtask

    task set_reg_6();
        if (h_pfn_wr_overflow) begin
            h_pfn_overflow_counter <= h_pfn_overflow_counter + 1;
        end
        if (h_cache_wr_overflow) begin
            h_cache_overflow_counter <= h_cache_overflow_counter + 1;
        end
        // lower 32 bit = 22'h0, wr_idx
        // upper 32 bit = overflow counter 
        data[6] <= {h_pfn_overflow_counter[15:0], 6'h0, h_pfn_wr_idx_o[9:0], 
                    h_cache_overflow_counter[15:0], 3'h0, h_cache_wr_idx_o[12:0]
                    };
    endtask

    always_ff @( posedge avmm_clk ) begin : m5_monitor_logic
        if (!reset_n) begin
            reset_reg();
        end else begin 

            set_reg_0();

            set_reg_1();

            set_reg_2();

            set_reg_3();

            set_reg_4();

            set_reg_5();

            set_reg_6();
        end
    end


    // update logic
    // Counter 0~7 are updated right here. Counter 8~16 are updated by csr_updater, which might not work.
    logic read_flag;
    logic write_flag;
    logic [63:0] debug_counter;

    // csr controlling outputs. Can be written by host.
    //      only send out control upon transition
    // data[16]: if being written any non-zero value, send out zero_out command.
    // data[17]: if being written any non-zero value, send out write back command.
    // data[18]: the address for write back, specified by the host.
    // data[19]: for debug (by Yan?)
    // data[20]: the specified region to monitor for cacheline granularity counting.
    always_comb begin
        // reg_8 -- page rate 
        page_query_rate = data[8][31:0];
        // reg_9 -- cache rate
        cache_query_rate = data[9][31:0];
        // reg_10 -- cxl_start_pa, from /proc/zoneinfo "start_pfn"
        cxl_start_pa = data[10];

        // reg_11 -- reset h_pfn write index
        h_pfn_wr_idx_rst = 1'b0;

        // reg_14 -- retrived from deadbeef test, this will be used for 
        //      address modulo to get the true PA address wrt CPU 
        cxl_addr_offset = data[14];

        // reg_17 -- reset h_cache write index
        h_cache_wr_idx_rst = 1'b0;

        case(address_shift3) 
            'd11: begin
                h_pfn_wr_idx_rst = write & ((writedata & mask) != 0);
            end
            'd17: begin
                h_cache_wr_idx_rst = write & ((writedata & mask) != 0);
            end
            default: begin
            end
        endcase


        write_back_addr = data[18];
        csr_write_back_cnt = data[19][31:0];
        //csr_monitor_region = data[20][MONITOR_REGION_WIDTH-1:0];
        csr_monitor_region = 1'b1;

        csr_awuser = data[21][37:32];
        csr_ofw_buf_head = data[22];
        csr_ofw_buf_tail_max = data[24];

    end

    always_ff @( posedge avmm_clk ) begin // FIXED: this clock should be avmm_clk, not afu_clk

        if (~reset_n) begin
            csr_zero_out    <= 1'b0;
            csr_write_back  <= 1'b0;
            stretch_cnt     <= '0;
        end else begin
            
            /* stretch the signal */
            stretch_cnt     <= (stretch_cnt > 0) ? stretch_cnt - 1 : '0;
            csr_zero_out    <= (stretch_cnt > 0) ? csr_zero_out : 1'b0;
            csr_write_back  <= (stretch_cnt > 0) ? csr_write_back : 1'b0;

            if (write & ((writedata & mask) != 0)) begin
                case(address_shift3) 
                    'd16: begin
                        csr_zero_out <= 1'b1;
                        stretch_cnt  <= 3'd3;
                    end

                    'd17: begin
                        csr_write_back  <= 1'b1;
                        stretch_cnt     <= 3'd3;
                    end
                endcase
            end
        end
    end

    h_pfn_buffer h_pfn_buffer_inst(
        .clk(avmm_clk),
        .reset_n(reset_n),
        // CSR shift3
        .rd_idx(h_pfn_rd_idx),
        .rd_en(h_pfn_rd_en),
        // output to CSR 
        .pfn_addr_o(h_pfn_addr_o),
        .wr_idx_o(h_pfn_wr_idx_o),

        // send to increment CSR counter
        .wr_overflow(h_pfn_wr_overflow),
        .wr_idx_rst(h_pfn_wr_idx_rst),
        //.wr_en(1'b1), 
        .wr_en(h_pfn_wr_en), 

        //FIXME
        //.pfn_addr_i({16'hEF35, debug_counter[15:0]})
        .pfn_addr_i(h_pfn_addr_i)
    );

    h_cache_buffer h_cache_buffer_inst(
        .clk(avmm_clk),
        .reset_n(reset_n),
        // CSR shift3
        .rd_idx(h_cache_rd_idx),
        .rd_en(h_cache_rd_en),
        // output to CSR 
        .cache_addr_o(h_cache_addr_o),
        .wr_idx_o(h_cache_wr_idx_o),

        // send to increment CSR counter
        .wr_overflow(h_cache_wr_overflow),
        .wr_idx_rst(h_cache_wr_idx_rst),
        //.wr_en(1'b1), 
        .wr_en(h_cache_wr_en), 

        .cache_addr_i(h_cache_addr_i)
    );
endmodule
