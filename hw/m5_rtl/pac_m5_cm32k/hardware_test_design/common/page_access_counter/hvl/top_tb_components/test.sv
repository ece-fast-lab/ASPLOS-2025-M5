class test;

    environment e0;
    mailbox drv_mbx;
    virtual pac_itf vif;

    function new();
        e0 = new();
        drv_mbx = new();
    endfunction

    virtual task automatic run();
        e0.d0.drv_mbx = drv_mbx;

        fork
            e0.run();
        join_none

        apply_stim();
    endtask //automatic

    virtual task automatic apply_stim();
    
        mem_request req;
        req = new;

        for (int i = 0; i < 2; i++) begin
            req.randomize();
            drv_mbx.put(req);
        end

        // Check the final values in the counter buffer
        e0.s0.check_counter();
    endtask //automatic
    
endclass //test

/* Test 1: Zero out the counter buffer */
class test_zero_out extends test;

    task automatic apply_stim();
        $display("[INFO] Test Zero Out Starts.");

        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;

        vif.ckb.csr_zero_out <= 1'b1;
        repeat (4) @(vif.ckb);
        vif.ckb.csr_zero_out <= 1'b0;
        @(vif.ckb);

        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.ckb);
        end

        @(vif.ckb);
        e0.s0.check_counter_zero();
    endtask //automatic
endclass //test_zero_out



/* Test 2: Counter value verification */
class test_counting extends test;

    mem_request req;

    task automatic apply_stim();
        $display("[INFO] Test Counting Starts.");

        // zero out the counter
        for (int i = 0; i < 2**SRAM_ADDR_WIDTH; i++) begin
            e0.s0.counter_buf[i] = '0;
        end
        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;

        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;
        @(vif.tb_clk);

        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end
        e0.s0.check_counter();
        repeat (4) @(vif.tb_clk);

        // sending requests
        // e0.m0.verbose = 1'b1;
        // e0.s0.verbose = 1'b1;

        e0.m0.bufreq_cnt = 0;  // reset this counter since zero_out will change it
        e0.m0.memreq_cnt = 0;
        vif.emif_amm_ready[0] = 1'b1;
        // e0.s0.verbose = 1'b1;

        /* Writing to the same buf address */
        for (int i = 0; i < 100; i++) begin
            req = new;
            req.randomize() with { address < 'h100; }; // 'h100 -> only the first 4 pages
            // req.print("REQUEST generated");
            drv_mbx.put(req);
        end

        /* Writing to almost all addresses */
        for (int i = 0; i < 100; i++) begin
            req = new;
            req.randomize() with { address < 'h10000; };
            // req.print("REQUEST generated");
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 200) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);

        repeat (10) @(vif.tb_clk);
            
        @(vif.tb_clk);
        e0.s0.check_counter();
    endtask //automatic
endclass //test_counting extends test



/* Test 3: All memory requests are finally sent to the DRAM */
class test_pass_through extends test;

    mem_request mreq;
    emif_request ereq;
    mem_request q [$];
    int mreq_cnt = 0;

    task automatic apply_stim();

        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;
        vif.emif_amm_ready[0] = 1'b1;

        for (int i = 0; i < 100; i++) begin
            mreq = new;
            mreq.randomize();
            drv_mbx.put(mreq);
            q.push_back(mreq);
        end

        ereq = new;
        forever begin
            $display("Time=%0t [TEST] Waiting for EMIF request...", $time);
            e0.scb_emif_mbx.get(ereq);
            if (q.size() > 0) begin
                mreq = q.pop_front();
                if (mreq.address == ereq.address && mreq.byteenable == ereq.byteenable &&
                    mreq.writedata == ereq.writedata && mreq.read == ereq.read &&
                    mreq.write == ereq.write) begin
                    
                    mreq_cnt++;
                    $display("Time=%0t [TEST] Moinitored request being sent to EMIF. Idx = %0d", $time, mreq_cnt);

                    if (mreq_cnt == 100) begin
                        $display("Time=%0t [RESULT] All requests have been sent to EMIF. Wait some time for any further requests...", $time);
                        repeat (200) @(vif.tb_clk);
                        if (e0.scb_emif_mbx.num() > 0) begin
                            $display("Time=%0t [ERROR] There is a request to the EMIF that was not requested by the user!", $time);
                            $finish;
                        end else begin
                            $display("Time=%0t [TEST] Pass Through Test PASSED.", $time);
                            $finish;
                        end
                    end

                end else begin
                    $display("Time=%0t [ERROR] Mismatch between user's request (idx=%0d) and the request sent to EMIF!", $time, mreq_cnt);
                    $finish;
                end
            end else begin
                $display("Time=%0t [ERROR] There is a request to the EMIF that was not requested by the user!", $time);
                $finish;
            end
        end

    endtask //automatic
endclass //test_pass_through


/* Test 4: Write back functionality */
class test_write_back extends test;

    mem_request req;
    emif_request ereq;
    logic [SRAM_DATA_WIDTH-1:0] shadow_wb_buf [2**SRAM_ADDR_WIDTH]; // shadow write back buffer
    logic [SRAM_ADDR_WIDTH-1:0] sram_addr;
    int err_cnt = 0;

    task automatic apply_stim();
        $display("[INFO] Test Write Back Starts.");

        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;
        vif.csr_monitor_region = 0;
        e0.s0.monitor_region = 0;

        /* zero out the counter */
        @(vif.tb_clk);
        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;


        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end

        /* Fill up the counter buffer */
        e0.m0.bufreq_cnt = 0;
        e0.m0.memreq_cnt = 0;
        e0.m0.emif_mbx_enable = 1'b0; // Do not fill up EMIF mailbox now
        vif.emif_amm_ready[0] = 1'b1;

        for (int i = 0; i < 1000; i++) begin
            req = new;
            req.randomize() with { address < 'h1000; }; // all available regions
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 1000) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);
        repeat (10) @(vif.tb_clk);
        e0.s0.check_counter();

        /* In case some requests haven't gone through the counter */
        repeat (10) @(vif.ckb);

        /* Send the write back command. Note that we use synchronous clock here */
        e0.m0.emif_mbx_enable = 1'b1; // now start to monitor EMIF
        @(vif.ckb)
        vif.csr_write_back  <= 1'b1;
        vif.write_back_addr <= 64'hf0000;
        repeat (2) @(vif.ckb);
        vif.csr_write_back  <= 1'b0;
        vif.write_back_addr <= 0;

        /* Monitor the EMIF signals and fill in shadow buffer */
        $display("Time=%0t [TEST] Start to write back...", $time);
        $display("Time=%0t [DEBUG] EMIF mailbox entries: %0d", $time, e0.scb_emif_mbx.num());
        ereq = new;
        @(vif.tb_clk);
        while (vif.state != IDLE_S) begin
            if (e0.scb_emif_mbx.num() > 0) begin
                e0.scb_emif_mbx.get(ereq);
                sram_addr = ereq.address - 64'hf0000;
                // if (ereq.writedata != '0) $display("Time=%12t [DEBUG] Write back address %0h. Counter relative address: %0h", $time, ereq.address, sram_addr);

                if (sram_addr >= 0 && sram_addr < 2**SRAM_ADDR_WIDTH) begin
                    shadow_wb_buf[sram_addr] = ereq.writedata;
                end else begin
                    $display("Time=%0t [ERROR] Write back address exceeds the range! ereq.address=%0x", $time, ereq.address);
                end
            end
            @(vif.tb_clk);
        end

        /* Check the shadow buffer */
        $display("Time=%0t [TEST] Write back finished. Checking shadow buffer...", $time);
        for (int i = 0; i < 2**SRAM_ADDR_WIDTH; i++) begin
            for (int j = 0; j < COUNTER_PER_ENTRY; j++) begin
                if (e0.s0.counter_buf[COUNTER_PER_ENTRY * i + j] != shadow_wb_buf[i][j * COUNTER_WIDTH +: COUNTER_WIDTH]) begin
                    if (err_cnt < 10) begin
                        $display("Time=%0t [ERROR] shadow writeback buffer and counter_buf don't match! sram_addr=%0x counter_idx=%0d expect=%0x actual=%0x",
                            $time, i, j, e0.s0.counter_buf[COUNTER_PER_ENTRY*i + j], shadow_wb_buf[i][COUNTER_WIDTH*j +: COUNTER_WIDTH]);
                    end else if (err_cnt == 10) begin
                       $display("Time=%0t [ERROR] Only the first 10 errors are shown.", $time); 
                    end
                    err_cnt++;
                end
            end
        end
        if (err_cnt > 0) begin
            $display("Time=%0t [TEST] Test failed. Total error count: %0d", $time, err_cnt);
        end else begin
            $display("Time=%0t [TEST] Test passed!", $time);
        end

    endtask
endclass //test_write_back extends test

/* Test 5: EMIF ready unasserted for certain time */

/* Test 6: Cacheline granularity counting and zero out */
class test_counting_cacheline_gran extends test;

    mem_request req;

    task automatic apply_stim();
        $display("[INFO] Test Counting Starts.");

        // zero out the counter
        for (int i = 0; i < 2**SRAM_ADDR_WIDTH; i++) begin
            e0.s0.counter_buf[i] = '0;
        end
        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;

        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;
        @(vif.tb_clk);

        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end
        e0.s0.check_counter_zero();
        repeat (4) @(vif.tb_clk);

        e0.m0.bufreq_cnt = 0;  // reset this counter since zero_out will change it
        e0.m0.memreq_cnt = 0;
        vif.emif_amm_ready[0] = 1'b1;
        vif.csr_monitor_region = 0; // set this to the corresponding range before you run any tests below
        e0.s0.monitor_region = 0;

        /* Writing to the same buf address inside monitor region */
        for (int i = 0; i < 100; i++) begin
            req = new;
            req.randomize() with { address < 'h4; }; // 'h4 -> only the first 4 cachelines
            // req.print("REQUEST generated");
            drv_mbx.put(req);
        end

        /* Writing to almost all addresses inside monitor region */
        for (int i = 0; i < 900; i++) begin
            req = new;
            req.randomize() with { address < 'h800000; }; // 512MB=2^29 addr=2^23
            // req.print("REQUEST generated");
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 1000) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);

        repeat (10) @(vif.tb_clk);
            
        @(vif.tb_clk);
        e0.s0.check_counter();

        /* Check if we can zero out the contents in the SRAM */
        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;
        @(vif.tb_clk);

        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end
        e0.s0.check_counter_zero();

    endtask //automatic
endclass //test_counting_cacheline_gran extends test

/* Test 7: Write to places outside monitor region*/
class test_out_of_monitor_region extends test;

    mem_request req;

    task automatic apply_stim();
        $display("[INFO] Test <out of monitor region> Starts.");

        /* zero out the counter */
        for (int i = 0; i < 2**SRAM_ADDR_WIDTH; i++) begin
            e0.s0.counter_buf[i] = '0;
        end
        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;

        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;
        @(vif.tb_clk);

        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end
        e0.s0.check_counter_zero();
        repeat (4) @(vif.tb_clk);

        
        /* Configure the testbench */
        e0.m0.bufreq_cnt = 0;  // reset this counter since zero_out will change it
        e0.m0.memreq_cnt = 0;
        // e0.s0.shadow_counter_enable = 1'b0; // turn off shadow counter increment
        e0.s0.monitor_region = 0;
        vif.emif_amm_ready[0] = 1'b1;
        vif.csr_monitor_region = 0; // set this to the corresponding range before you run any tests below

        /* Writing to almost all addresses outside monitor region */
        $display("Time=%0t [TEST] Send requests to addresses outside monitor region.", $time);
        for (int i = 0; i < 200; i++) begin
            req = new;
            req.randomize() with { address > 'h800000; address < 'h1000000; }; // 512MB=2^29 addr=2^23
            // req.print("REQUEST generated");
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 200) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);

        repeat (10) @(vif.tb_clk);
        e0.s0.check_counter();

        /* Writing to almost all addresses inside monitor region */
        $display("Time=%0t [TEST] Send requests to addresses inside monitor region.", $time);
        // vif.csr_monitor_region = 1; // change monitor region to the second region
        e0.m0.memreq_cnt = 0; // reset mem request counter
        // e0.s0.shadow_counter_enable = 1'b1;
        for (int i = 0; i < 200; i++) begin
            req = new;
            req.randomize() with { address > 'h800000; address < 'h1000000; }; // 512MB=2^29 addr=2^23
            // req.print("REQUEST generated");
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 200) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);

        repeat (10) @(vif.tb_clk);
        e0.s0.check_counter();

    endtask //automatic
endclass



/* Test 8: Write back functionality with EMIF intermittent not ready */
class test_write_back_not_ready extends test;

    mem_request req;
    mem_request mreq;
    emif_request ereq;
    logic [SRAM_DATA_WIDTH-1:0] shadow_wb_buf [2**SRAM_ADDR_WIDTH]; // shadow write back buffer
    logic [SRAM_ADDR_WIDTH-1:0] sram_addr;
    mem_request q [$];
    int err_cnt = 0;
    int nonzero_cnt = 0;
    int user_req_cnt = 0;
    int writeback_idx = 0;

    task automatic apply_stim();
        $display("[INFO] Test Write Back Not Ready Starts.");

        /* Testbench config */
        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;
        vif.csr_monitor_region = 0;
        e0.s0.monitor_region = 0;

        /* zero out the counter */
        @(vif.tb_clk);
        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;


        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end

        /* Fill up the counter buffer */
        e0.m0.bufreq_cnt = 0;
        e0.m0.memreq_cnt = 0;
        // e0.m0.emif_mbx_enable = 1'b0; // Do not fill up EMIF mailbox now
        vif.emif_amm_ready[0] = 1'b1;

        for (int i = 0; i < 2000; i++) begin
            req = new;
            req.randomize() with { address < 'h1000; }; // In first region
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 2000) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);
        repeat (10) @(vif.tb_clk);
        e0.s0.check_counter();

        /* In case some requests haven't gone through the counter */
        repeat (10) @(vif.ckb);

        /* Send the write back command. Note that we use synchronous clock here */
        @(vif.ckb)
        vif.csr_write_back  <= 1'b1;
        vif.write_back_addr <= 64'hf0000;
        repeat (2) @(vif.ckb); // repeat at least 2 cycles for mem_updater to pick up the signal
        vif.csr_write_back  <= 1'b0;
        vif.write_back_addr <= 0;

        /* Monitor the EMIF signals and fill in shadow buffer */
        $display("Time=%0t [TEST] Start to write back...", $time);
        // $display("Time=%12t [DEBUG] EMIF mailbox entries: %0d", $time, e0.scb_emif_mbx.num());

        ereq = new;
        @(vif.tb_clk);
        while (vif.state != IDLE_S) begin
            // Monitor the writeback throughput
            if (e0.scb_emif_writeback.num() > 0) begin
                e0.scb_emif_writeback.get(ereq);
                sram_addr = ereq.address - 'hf0000;
                // if (ereq.writedata != '0) $display("Time=%12t [DEBUG] Write back address %0h, writedata is non-zero.", $time, ereq.address);

                if (sram_addr >= 0 && sram_addr < 2**SRAM_ADDR_WIDTH) begin
                    shadow_wb_buf[sram_addr] = ereq.writedata;
                end else begin
                    $display("Time=%0t [ERROR] Write back address exceeds the range! ereq.address=%0x", $time, ereq.address);
                end
                writeback_idx++;
            end
            // $display("Time=%0t [DEBUG] writeback_idx = 0x%0h", $time, writeback_idx);

            // insert some gap in the writeback process
            if (writeback_idx == 'h100) begin // gap, nothing else
                $display("Time=%0t [TEST] Deassert memory ready signal.", $time);
                writeback_idx++; // to prevent this block getting executed multiple times
                vif.emif_amm_ready[0] = 1'b0;
            end else if (writeback_idx == 'h400) begin // send user requests in between
                $display("Time=%0t [TEST] Assert memory ready signal.", $time);
                vif.emif_amm_ready[0] = 1'b1;
                writeback_idx++;
            end else if (writeback_idx == 'h800) begin
                // send some user requests
                $display("Time=%0t [TEST] Sending some user requests.", $time);
                for (int i = 0; i < 800; i++) begin
                    req = new;
                    req.randomize() with { address >= 'hf0000 + 'h20000;};
                    drv_mbx.put(req);
                    q.push_back(req);
                end
                writeback_idx++;
            end

            @(vif.tb_clk);
        end

        /* Check the shadow buffer */
        $display("Time=%0t [TEST] Write back finished. Checking shadow buffer...", $time);
        for (int i = 0; i < 2**SRAM_ADDR_WIDTH; i++) begin
            for (int j = 0; j < COUNTER_PER_ENTRY; j++) begin
                if (e0.s0.counter_buf[COUNTER_PER_ENTRY * i + j] != shadow_wb_buf[i][j * COUNTER_WIDTH +: COUNTER_WIDTH]) begin
                    if (err_cnt < 10) begin
                        $display("Time=%0t [ERROR] shadow writeback buffer and counter_buf don't match! sram_addr=%0x counter_idx=%0d expect=%0x actual=%0x",
                            $time, i, j, e0.s0.counter_buf[COUNTER_PER_ENTRY*i + j], shadow_wb_buf[i][COUNTER_WIDTH*j +: COUNTER_WIDTH]);
                    end else if (err_cnt == 10) begin
                       $display("Time=%0t [ERROR] Only the first 10 errors are shown.", $time); 
                    end
                    err_cnt++;
                end else begin
                    if (shadow_wb_buf[i][j * COUNTER_WIDTH +: COUNTER_WIDTH] != '0) nonzero_cnt++;
                        
                end
            end
        end
        if (err_cnt > 0) begin
            $display("Time=%0t [TEST] Test failed. Total error count: %0d", $time, err_cnt);
        end else begin
            $display("Time=%0t [TEST] Shadow Buffer Check Passed!", $time);
        end
        $display("Time=%0t [TEST] Number of non-zero entries in the shadow writeback buffer: %0d", $time, nonzero_cnt);



        // Wait until all user requests have been consumed
        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 2000 + 800) begin
            @(vif.tb_clk);
        end


        // Check if the user requests got through
        mreq = new;
        $display("Time=%0t [DEBUG] EMIF user mailbox: %0d, user request queue: %0d", $time, e0.scb_emif_user.num(), q.size());
        while (e0.scb_emif_user.num() > 0 && q.size() > 0) begin
            e0.scb_emif_user.get(ereq);
            mreq = q.pop_front();
            if (mreq.address == ereq.address && mreq.byteenable == ereq.byteenable &&
                mreq.writedata == ereq.writedata && mreq.read == ereq.read &&
                mreq.write == ereq.write) begin
                
                user_req_cnt++;
                $display("Time=%0t [TEST] Moinitored request being sent to EMIF. Idx = %0d", $time, user_req_cnt);

            end else begin
                $display("Time=%0t [ERROR] Mismatch between user's request (idx=%0d) and the request sent to EMIF!", $time, user_req_cnt);
                $finish;
            end
        end

        if (e0.scb_emif_user.num() == 0 && q.size() > 0) begin
            $display("Time=%0t [ERROR] There is a request not sent to the EMIF! Number of requests left: %0d", $time, q.size());
            $finish;
        end else if (e0.scb_emif_user.num() > 0 && q.size() == 0) begin
            $display("Time=%0t [ERROR] There is a request to the EMIF that was not requested by the user!", $time);
            $finish;
        end else if (e0.scb_emif_user.num() == 0 && q.size() == 0 && user_req_cnt == 800) begin
            $display("Time=%0t [RESULT] All requests have been sent to EMIF.", $time);
            $display("Time=%0t [RESULT] Pass Through Test PASSED.", $time);
            $finish;
        end else begin
            $display("Time=%0t [ERROR] Unkown error type!", $time);
            $finish;
        end

    endtask
endclass //test_write_back extends test


/* Test 9: Cacheline granularity counting and zero out with CAFU writeback scheme */
class test_writeback_cafu extends test;

    mem_request req;
    cafu_request cafureq;
    logic [SRAM_DATA_WIDTH-1:0] shadow_wb_buf [2**SRAM_ADDR_WIDTH]; // shadow write back buffer
    logic [SRAM_ADDR_WIDTH-1:0] sram_addr;
    int err_cnt = 0;

    task automatic apply_stim();
        $display("[INFO] Test Write Back Starts.");

        e0.m0.verbose = 1'b0;
        e0.s0.verbose = 1'b0;
        e0.d0.verbose = 1'b0;
        vif.csr_monitor_region = 0;
        e0.s0.monitor_region = 0;

        /* zero out the counter */
        @(vif.tb_clk);
        vif.csr_zero_out <= 1'b1;
        repeat (4) @(vif.tb_clk);
        vif.csr_zero_out <= 1'b0;


        $display("Time=%0t [TEST] Waiting for zero out to finish...", $time);
        while (vif.state != IDLE_S) begin
            @(vif.tb_clk);
        end

        /* Fill up the counter buffer */
        e0.m0.bufreq_cnt = 0;
        e0.m0.memreq_cnt = 0;
        e0.m0.emif_mbx_enable = 1'b0; // Do not fill up EMIF mailbox now
        vif.emif_amm_ready[0] = 1'b1;

        for (int i = 0; i < 1000; i++) begin
            req = new;
            req.randomize() with { address < 'h1000; }; // all available regions
            drv_mbx.put(req);
        end

        $display("Time=%0t [TEST] Waiting for all the request being updated to the counter buffer...", $time);
        while (e0.m0.memreq_cnt < 1000) begin
            @(vif.tb_clk);
        end
        $display("Time=%0t [TEST] All requests have been consumed.", $time);
        repeat (10) @(vif.tb_clk);
        e0.s0.check_counter();

        /* In case some requests haven't gone through the counter */
        repeat (10) @(vif.ckb);

        /* Send the write back command. Note that we use synchronous clock here */
        $display("Time=%0t [TEST] Start to write back...", $time);
        @(vif.ckb)
        vif.csr_write_back  <= 1'b1;
        vif.write_back_addr <= 64'h1000000;
        repeat (20) @(vif.ckb);
        vif.csr_write_back  <= 1'b0;

        /* Monitor the EMIF signals and fill in shadow buffer */
        $display("Time=%0t [DEBUG] CAFU mailbox entries: %0d", $time, e0.scb_cafu_mbx.num());
        cafureq = new;
        @(vif.tb_clk);
        while (vif.state != IDLE_S) begin
            if (e0.scb_cafu_mbx.num() > 0) begin
                e0.scb_cafu_mbx.get(cafureq);
                sram_addr = (cafureq.address - 64'h1000000) >> 6;
                // if (cafureq.writedata != '0) $display("Time=%12t [DEBUG] Write back address %0h. Counter relative address: %0h", $time, cafureq.address, sram_addr);

                if (sram_addr >= 0 && sram_addr < 2**SRAM_ADDR_WIDTH) begin
                    shadow_wb_buf[sram_addr] = cafureq.writedata;
                end else begin
                    $display("Time=%0t [ERROR] Write back address exceeds the range! cafureq.address=%0x", $time, cafureq.address);
                end
            end
            @(vif.tb_clk);
        end

        /* Check the shadow buffer */
        $display("Time=%0t [TEST] Write back finished. Checking shadow buffer...", $time);
        for (int i = 0; i < 2**SRAM_ADDR_WIDTH; i++) begin
            for (int j = 0; j < COUNTER_PER_ENTRY; j++) begin
                if (e0.s0.counter_buf[COUNTER_PER_ENTRY * i + j] != shadow_wb_buf[i][j * COUNTER_WIDTH +: COUNTER_WIDTH]) begin
                    if (err_cnt < 10) begin
                        $display("Time=%0t [ERROR] shadow writeback buffer and counter_buf don't match! sram_addr=%0x counter_idx=%0d expect=%0x actual=%0x",
                            $time, i, j, e0.s0.counter_buf[COUNTER_PER_ENTRY*i + j], shadow_wb_buf[i][COUNTER_WIDTH*j +: COUNTER_WIDTH]);
                    end else if (err_cnt == 10) begin
                       $display("Time=%0t [ERROR] Only the first 10 errors are shown.", $time); 
                    end
                    err_cnt++;
                end
            end
        end
        if (err_cnt > 0) begin
            $display("Time=%0t [TEST] Test failed. Total error count: %0d", $time, err_cnt);
        end else begin
            $display("Time=%0t [TEST] Test passed!", $time);
        end

    endtask
endclass
