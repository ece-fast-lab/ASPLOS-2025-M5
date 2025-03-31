import ctrl_signal_types::*;

module pac_top_tb ();

    logic clk, eclk, reset_n;
    always #5 clk = (clk === 1'b0);
    always #3 eclk = (eclk === 1'b0);
    // default clocking tb_clk @(negedge clk); endclocking

    pac_itf itf (clk, eclk, reset_n);

    pac_top dut (

        .mclk    (itf.clk),
        .reset_n (itf.reset_n),

        /* to/from EMIF */
        .emif_amm_read           (itf.emif_amm_read),                    
        .emif_amm_write          (itf.emif_amm_write),                 
        .emif_amm_address        (itf.emif_amm_address),   
        .emif_amm_writedata      (itf.emif_amm_writedata),
        .emif_amm_burstcount     (itf.emif_amm_burstcount),
        .emif_amm_byteenable     (itf.emif_amm_byteenable),
        .emif_amm_readdatavalid  (itf.emif_amm_readdatavalid), 
        .emif_amm_ready          (itf.emif_amm_ready),                   
        .emif_amm_readdata       (itf.emif_amm_readdata),

        /* to/from channel_adaptor */
        .mem_read_rmw_mclk               (itf.mem_read_rmw_mclk),
        .mem_write_rmw_mclk              (itf.mem_write_rmw_mclk),
        .mem_address_rmw_mclk            (itf.mem_address_rmw_mclk),
        .mem_writedata_rmw_mclk          (itf.mem_writedata_rmw_mclk),
        .mem_byteenable_rmw_mclk         (itf.mem_byteenable_rmw_mclk),
        .mem_readdata_rmw_mclk           (itf.mem_readdata_rmw_mclk),
        .mem_readdatavalid_rmw_mclk      (itf.mem_readdatavalid_rmw_mclk),
        .mem_ready_rmw_mclk              (itf.mem_ready_rmw_mclk),
        .mem_ecc_err_corrected_rmw_mclk  (itf.mem_ecc_err_corrected_rmw_mclk),
        .mem_ecc_err_detected_rmw_mclk   (itf.mem_ecc_err_detected_rmw_mclk),
        .mem_ecc_err_fatal_rmw_mclk      (itf.mem_ecc_err_fatal_rmw_mclk),
        .mem_ecc_err_syn_e_rmw_mclk      (itf.mem_ecc_err_syn_e_rmw_mclk),
        .mem_write_ras_sbe_mclk          (itf.mem_write_ras_sbe_mclk),
        .mem_write_ras_dbe_mclk          (itf.mem_write_ras_dbe_mclk), 
        .mem_write_poison_rmw_mclk       (itf.mem_write_poison_rmw_mclk),
        .mem_read_poison_rmw_mclk        (itf.mem_read_poison_rmw_mclk),

        // Clocks
		.axi4_mm_clk                           (itf.eclk), 
		// Resets
		.axi4_mm_rst_n                         (itf.reset_n),

		// AXI-MM interface - write address channel
		.awid                                  (itf.awid),
		.awaddr                                (itf.awaddr), 
		.awlen                                 (itf.awlen),
		.awsize                                (itf.awsize),
		.awburst                               (itf.awburst),
		.awprot                                (itf.awprot),
		.awqos                                 (itf.awqos),
		.awuser                                (itf.awuser),
		.awvalid                               (itf.awvalid),
		.awcache                               (itf.awcache),
		.awlock                                (itf.awlock),
		.awregion                              (itf.awregion),
		.awatop                                (itf.awatop),
		.awready                               (itf.awready),
		
		// AXI-MM interface - write data channel
		.wdata                                 (itf.wdata),
		.wstrb                                 (itf.wstrb),
		.wlast                                 (itf.wlast),
		.wuser                                 (itf.wuser),
		.wvalid                                (itf.wvalid),
		.wready                                (itf.wready),
		
		//  AXI-MM interface - write response channel
		.bid                                  (itf.bid),
		.bresp                                (itf.bresp),
		.buser                                (itf.buser),
		.bvalid                               (itf.bvalid),
		.bready                               (itf.bready),
		
		// AXI-MM interface - read address channel
		.arid                                  (itf.arid),
		.araddr                                (itf.araddr),
		.arlen                                 (itf.arlen),
		.arsize                                (itf.arsize),
		.arburst                               (itf.arburst),
		.arprot                                (itf.arprot),
		.arqos                                 (itf.arqos),
		.aruser                                (itf.aruser),
		.arvalid                               (itf.arvalid),
		.arcache                               (itf.arcache),
		.arlock                                (itf.arlock),
		.arregion                              (itf.arregion),
		.arready                               (itf.arready),

		// AXI-MM interface - read response channel
		.rid                                   (itf.rid),
		.rdata                                 (itf.rdata),
		.rresp                                 (itf.rresp),
		.rlast                                 (itf.rlast),
		.ruser                                 (itf.ruser),
		.rvalid                                (itf.rvalid),
		.rready                                (itf.rready),

        // from csr
        .csr_zero_out_aclk                  (itf.csr_zero_out),
        .csr_write_back_aclk                (itf.csr_write_back),
        .write_back_addr                    (itf.write_back_addr),
        .csr_write_back_cnt_aclk            (32'h0),
        .csr_monitor_region                 (itf.csr_monitor_region),
        // to csr
        .is_writing_back                    (itf.is_writing_back)
    );


    /* shadow CXL IP */
    always_ff @( posedge eclk ) begin : shadow_cxl_ip

        itf.awready <= 1'b1;
        itf.wready  <= 1'b1;
        itf.bresp   <= 2'b0;
        if (itf.wvalid) begin
            itf.bvalid <= 1'b1;
        end else begin
            itf.bvalid <= 1'b0;
        end

        
    end

    /* connect the signals we want to observe to the interface */
    assign itf.counter_buf_wren     = dut.buf_wren;
    assign itf.counter_buf_wraddress = dut.buf_wraddress;
    assign itf.counter_buf_wdata    = dut.buf_data;
    assign itf.state                = dut.counter_ctrl_inst.state;

    /* Set a timeout value */
    int timeout = 5000000;
    always @(posedge itf.clk) begin
        if (timeout == 0) begin
            $display("[WARNING] Timed out");
            $finish;
        end
        timeout <= timeout - 1;
    end

    test_zero_out t0; // FIXED: this line should be outside of the initial block
    test_counting t1;
    test_pass_through t2;
    test_write_back t3;
    test_counting_cacheline_gran t4;
    test_out_of_monitor_region t5;
    test_write_back_not_ready t6;
    test_writeback_cafu t7;

    initial begin
        $timeformat(-9, 1, "ns");

        #40
        @(itf.tb_clk);
        reset_n <= 1'b0; // FIXED: shouldn't drive itf.reset_n
        itf.csr_zero_out <= 1'b0;
        itf.csr_write_back <= 1'b0;
        repeat (4) @(itf.tb_clk);
        reset_n <= 1'b1;

        // NOTE: NOT ALL TESTS are designed for each variation
        
        // run test
        // t0 = new;
        // t0.vif = itf;
        // t0.e0.vif = itf;
        // t0.run();

        // t1 = new;
        // t1.vif = itf;
        // t1.e0.vif = itf;
        // t1.run();

        // t2 = new;
        // t2.vif = itf;
        // t2.e0.vif = itf;
        // t2.run();

        // t3 = new;
        // t3.vif = itf;
        // t3.e0.vif = itf;
        // t3.run();

        // t4 = new;
        // t4.vif = itf;
        // t4.e0.vif = itf;
        // t4.run();

        // t5 = new;
        // t5.vif = itf;
        // t5.e0.vif = itf;
        // t5.run();

        // t6 = new;
        // t6.vif = itf;
        // t6.e0.vif = itf;
        // t6.run();

        t7 = new;
        t7.vif = itf;
        t7.e0.vif = itf;
        t7.run();

        // Test the counter buffer only
        // @(itf.tb_clk);
        // buf_wren <= 1'b1;
        // buf_wraddress <= 'hf;
        // buf_rdaddress <= 'hf;
        // buf_data <= 512'h1;
        // @(itf.tb_clk);

        // buf_data <= 512'h2;
        // @(itf.tb_clk);

        // buf_data <= 512'h3;
        // @(itf.tb_clk);

        // buf_data <= 512'h4;
        // @(itf.tb_clk);

        // buf_data <= 512'h5;
        // @(itf.tb_clk);

        // buf_wren <= 1'b0;
        // @(itf.tb_clk);

        // tests are over, terminate the testbench after certain delay
        repeat (50) @(itf.tb_clk);
        $finish;
    end

    /* Dump the variables */
    initial begin
        // $dumpvars;
        // $dumpfile("pac_tb.vcd");

        $fsdbDumpfile("top_tb.fsdb");
        $fsdbDumpvars;
    end

endmodule
