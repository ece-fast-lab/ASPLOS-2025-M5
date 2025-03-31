import ctrl_signal_types::*;

class scoreboard;
    
    mailbox scb_req_mbx;
    mailbox scb_buf_mbx;
    mailbox scb_cafu_mbx;
    virtual pac_itf vif;

    localparam NUM_COUNTERS = (SRAM_DATA_WIDTH/COUNTER_WIDTH)*2**SRAM_ADDR_WIDTH;

    logic [COUNTER_WIDTH-1:0] counter_buf        [NUM_COUNTERS]; // this buffer records the counter_buf write port
    logic [COUNTER_WIDTH-1:0] shadow_counter_buf [NUM_COUNTERS]; // this buffer should reflect the true counter values
    logic [COUNTER_WIDTH-1:0] cafu_counter_buf   [NUM_COUNTERS]; // this buffer record the counter values written back by CAFU
    logic [MONITOR_REGION_WIDTH-1:0] monitor_region;
    logic [SRAM_ADDR_WIDTH-1:0] buf_addr;
    bit verbose = 1'b1;
    bit shadow_counter_enable = 1'b1;

    function new();
        // counter_buf = '{default:'0};
        for (int i = 0; i < NUM_COUNTERS; i++) begin
            // counter_buf[i] = 0; // don't initialize this buffer because we should zero out the entries manually
            shadow_counter_buf[i] = '0; 
        end
    endfunction

    task automatic run();
        fork
            forever begin
                mem_request mreq;
                scb_req_mbx.get(mreq);
                // if (verbose) mreq.print("Scoreboard Memory");

                /* To accommodate regional write back */
                // if (shadow_counter_enable) begin
                if (mreq.address[(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN+MONITOR_REGION_WIDTH-1):(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN)] == monitor_region) begin
                    shadow_counter_buf[mreq.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)+SRAM_ADDR_WIDTH-1):COUNTER_GRAN]] += 1;
                end else begin
                    // $display("[DEBUG] Request is out of monitor region. Req: %b, target region: %b", mreq.address[(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN+MONITOR_REGION_WIDTH-1):(SRAM_ADDR_WIDTH+$clog2(COUNTER_PER_ENTRY)+COUNTER_GRAN)], monitor_region);
                end

                if (verbose) $display("[SCB-SHADOW] Addr %0h updated to %0h i=%0d", mreq.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)+SRAM_ADDR_WIDTH-1):COUNTER_GRAN], shadow_counter_buf[mreq.address[(COUNTER_GRAN+($clog2(COUNTER_PER_ENTRY)+SRAM_ADDR_WIDTH)-1):COUNTER_GRAN]],
                    mreq.address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)-1):COUNTER_GRAN]);
            end

            forever begin
                counter_request creq;
                scb_buf_mbx.get(creq);
                
                for (int i = 0; i < COUNTER_PER_ENTRY; i++) begin
                    if (counter_buf[creq.buf_wraddress * COUNTER_PER_ENTRY + i] != creq.buf_wdata[COUNTER_WIDTH*i +: COUNTER_WIDTH]) begin
                        if (verbose) $display("[SCB-COUNTER] Addr %0h updated to %0h buf_wraddr is %03h i=%0d", creq.buf_wraddress * COUNTER_PER_ENTRY + i, creq.buf_wdata[COUNTER_WIDTH*i +: COUNTER_WIDTH],
                            creq.buf_wraddress, i);
                    end

                    counter_buf[creq.buf_wraddress * COUNTER_PER_ENTRY + i] = creq.buf_wdata[COUNTER_WIDTH*i +: COUNTER_WIDTH];
                end
            end

            forever begin
                cafu_request cafureq;
                scb_cafu_mbx.get(cafureq);

                buf_addr = (cafureq.address - vif.write_back_addr) >> 6;
                for (int i = 0; i < COUNTER_PER_ENTRY; i++) begin
                    if (cafu_counter_buf[buf_addr * COUNTER_PER_ENTRY + i] != cafureq.writedata[COUNTER_WIDTH * i +: COUNTER_WIDTH]) begin
                        if (verbose) $display("[SCB-COUNTER] Addr %0h updated to %0h buf_wraddr is %03h i=%0d", buf_addr * COUNTER_PER_ENTRY + i, cafureq.writedata[COUNTER_WIDTH*i +: COUNTER_WIDTH],
                            buf_addr, i);
                    end

                    cafu_counter_buf[buf_addr * COUNTER_PER_ENTRY + i] = cafureq.writedata[COUNTER_WIDTH * i +: COUNTER_WIDTH];
                end
            end
        join
    endtask

    task automatic check_counter();
        int num_mismatch = 0;
        for (int i = 0; i < NUM_COUNTERS; i++) begin
            if (counter_buf[i] != shadow_counter_buf[i]) begin
                // Do not print error info if the # of error is larger than 10
                if (num_mismatch < 20) begin
                    $display("Time=%0t [ERROR] Counter value mismatch! addr:0x%0h, exp:0x%0h act:0x%0h", 
                        $time, i, shadow_counter_buf[i], counter_buf[i]);
                end else if (num_mismatch == 20) begin
                    $display("Time=%0t [ERROR] More errors are hidden!", $time);
                end
                num_mismatch++;
            end
        end
        $display("Time=%0t [RESULT] Total number of mismatches is %0d", $time, num_mismatch);
        if (num_mismatch == 0) $display("Time=%0t [RESULT] Check Counter Test Passed.", $time);
    endtask


    task automatic check_counter_cafuwb();
        int num_mismatch = 0;
        for (int i = 0; i < NUM_COUNTERS; i++) begin
            if (cafu_counter_buf[i] != shadow_counter_buf[i]) begin
                // Do not print error info if the # of error is larger than 10
                if (num_mismatch < 20) begin
                    $display("Time=%0t [ERROR] CAFU Counter value mismatch! addr:0x%0h, exp:0x%0h act:0x%0h", 
                        $time, i, shadow_counter_buf[i], cafu_counter_buf[i]);
                end else if (num_mismatch == 20) begin
                    $display("Time=%0t [ERROR] More errors are hidden!", $time);
                end
                num_mismatch++;
            end
        end
        $display("Time=%0t [RESULT] In CAFU counter buffer, total number of mismatches is %0d", $time, num_mismatch);
        if (num_mismatch == 0) $display("Time=%0t [RESULT] Check CAFU Counter Test Passed.", $time);
    endtask


    task automatic check_counter_zero();
        int num_mismatch = 0;
        for (int i = 0; i < NUM_COUNTERS; i++) begin
            if (counter_buf[i] != 0) begin
                // Do not print error info if the # of error is larger than 10
                if (num_mismatch < 20) begin
                    $display("Time=%0t [ERROR] Counter value mismatch! addr:0x%0h, exp:0x%0h act:0x%0h", 
                        $time, i, 0, counter_buf[i]);
                end else if (num_mismatch == 20) begin
                    $display("Time=%0t [ERROR] More errors are hidden!", $time);
                end
                num_mismatch++;
            end
        end
        $display("Time=%0t [RESULT] Total number of mismatches is %0d", $time, num_mismatch);
        if (num_mismatch == 0) $display("Time=%0t [RESULT] Check Counter Zero-out Test Passed.", $time);
    endtask //automatic

endclass //scoreboard
