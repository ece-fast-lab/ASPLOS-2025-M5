/* The driver is responsible for driving the DUT */

class driver;
    event drv_done;
    mailbox drv_mbx;
    virtual pac_itf vif;
    bit verbose = 1'b1;

    task automatic run();
        $display("Time=%0t [Driver] Starting...", $time);
        @(vif.ckb);

        /* Try to get a new memory request and assign it to
         the interface. Do this only when mem_ready is asserted
         */
        forever begin
            mem_request req;

            if (drv_mbx.num() > 0) begin
                drv_mbx.get(req);
            end else begin
                @(vif.ckb);
                vif.ckb.mem_read_rmw_mclk[0]       <= 1'b0;
                vif.ckb.mem_write_rmw_mclk[0]      <= 1'b0;
                vif.ckb.mem_address_rmw_mclk[0]    <= '0;
                vif.ckb.mem_writedata_rmw_mclk[0]  <= '0;
                vif.ckb.mem_byteenable_rmw_mclk[0] <= '0;
                // vif.mem_read_rmw_mclk[0]       <= 1'b0;
                // vif.mem_write_rmw_mclk[0]      <= 1'b0;
                // vif.mem_address_rmw_mclk[0]    <= '0;
                // vif.mem_writedata_rmw_mclk[0]  <= '0;
                // vif.mem_byteenable_rmw_mclk[0] <= '0;
                // @(vif.ckb);
                $display("Time=%0t [Driver] Waiting for item...", $time);
                drv_mbx.get(req);
                // @(vif.ckb); // FIXED: without this the first request would be missing
            end

            while (!vif.mem_ready_rmw_mclk[0]) begin // corresponds to reg ON scenario
                $display("Time=%0t [Driver] Wait until mem_ready is asserted...", $time);
                @(vif.ckb);
            end

            @(vif.ckb);
            if (verbose) req.print("Driver");
            vif.ckb.mem_read_rmw_mclk[0]       <= req.read;
            vif.ckb.mem_write_rmw_mclk[0]      <= req.write;
            vif.ckb.mem_address_rmw_mclk[0]    <= req.address;
            vif.ckb.mem_writedata_rmw_mclk[0]  <= req.writedata;
            vif.ckb.mem_byteenable_rmw_mclk[0] <= req.byteenable;
            // vif.mem_read_rmw_mclk[0]       <= req.read;
            // vif.mem_write_rmw_mclk[0]      <= req.write;
            // vif.mem_address_rmw_mclk[0]    <= req.address;
            // vif.mem_writedata_rmw_mclk[0]  <= req.writedata;
            // vif.mem_byteenable_rmw_mclk[0] <= req.byteenable;
            // @(vif.ckb);

            // drive the interface. We ONLY drive channel 0 for now.
            // if (req.read || req.write) begin
            //     vif.mem_read_rmw_mclk[0]       <= req.read;
            //     vif.mem_write_rmw_mclk[0]      <= req.write;
            //     vif.mem_address_rmw_mclk[0]    <= req.address;
            //     vif.mem_writedata_rmw_mclk[0]  <= req.writedata;
            //     vif.mem_byteenable_rmw_mclk[0] <= req.byteenable;
            //     @(posedge vif.clk);
            // end else begin
            //     vif.mem_read_rmw_mclk[0]       <= 1'b0;
            //     vif.mem_write_rmw_mclk[0]      <= 1'b0;
            //     vif.mem_address_rmw_mclk[0]    <= '0;
            //     vif.mem_writedata_rmw_mclk[0]  <= '0;
            //     vif.mem_byteenable_rmw_mclk[0] <= '0;
            //     @(posedge vif.clk);
            // end

            // while (!vif.mem_ready_rmw_mclk[0]) begin
            //     $display("Time=%0t [Driver] Wait until mem_ready is asserted...", $time);
            //     @(vif.ckb);
            // end

            // raise the done event
            ->drv_done;
        end

    endtask //automatic

endclass //driver
