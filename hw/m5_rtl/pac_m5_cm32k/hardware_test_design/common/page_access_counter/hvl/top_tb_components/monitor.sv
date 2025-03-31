/* The monitor has a virtual interface handle with which it can monitor the events
    happening on the interface. It sees new requests and then captures info into a packet
    and sends it to the scoreboard.
*/

class monitor;

    virtual pac_itf vif;

    mailbox scb_req_mbx;
    mailbox scb_buf_mbx;
    mailbox scb_emif_mbx;
    mailbox scb_emif_writeback;
    mailbox scb_emif_user;
    mailbox scb_cafu_mbx;

    mem_request req;
    counter_request creq;
    emif_request ereq;
    cafu_request cafureq;

    bit verbose = 1'b1;
    bit emif_mbx_enable = 1'b1;
    int memreq_cnt = 0;
    int bufreq_cnt = 0;
    int emifreq_cnt = 0;
    int cafureq_cnt = 0;

    task automatic run();

        $display("Time=%0t [Monitor] Starting...", $time);
        
        // If the request is valid, send it to the scoreboard 
        forever begin

            // @(posedge vif.clk);
            @(vif.tb_clk);

            req = new;
            creq = new;
            ereq = new;
            cafureq = new;

            if ((vif.mem_read_rmw_mclk[0] | vif.mem_write_rmw_mclk[0]) && vif.mem_ready_rmw_mclk[0]) begin
                req.address = vif.mem_address_rmw_mclk[0];
                req.read = vif.mem_read_rmw_mclk[0];
                req.write = vif.mem_write_rmw_mclk[0];
                req.writedata = vif.mem_writedata_rmw_mclk[0];
                memreq_cnt++;
                if (verbose) $display("Time=%0t [MEM REQUEST = %0d]", $time, memreq_cnt);

                if (verbose) req.print("Monitor Mem");
                scb_req_mbx.put(req);
            end

            // @(vif.tb_clk); 

            if (vif.counter_buf_wren) begin
                creq.buf_wren = vif.counter_buf_wren;
                creq.buf_wraddress = vif.counter_buf_wraddress;
                creq.buf_wdata = vif.counter_buf_wdata;
                bufreq_cnt++;

                if (verbose) creq.print("Monitor Counter");
                scb_buf_mbx.put(creq);
            end

            //  
            if (emif_mbx_enable && (vif.emif_amm_read || vif.emif_amm_write)) begin
                ereq.writedata = vif.emif_amm_writedata[0];
                ereq.write = vif.emif_amm_write[0];
                ereq.read = vif.emif_amm_read[0];
                ereq.address = vif.emif_amm_address[0];
                ereq.byteenable = vif.emif_amm_byteenable[0];
                emifreq_cnt++;

                if (verbose) ereq.print("Monitor EMIF");
                scb_emif_mbx.put(ereq);
            end

            if ((vif.emif_amm_read || vif.emif_amm_write) && (vif.emif_amm_address[0] >= 'hf0000) && (vif.emif_amm_address[0] < 'hf0000 + 'h20000)) begin
                ereq.writedata = vif.emif_amm_writedata[0];
                ereq.write = vif.emif_amm_write[0];
                ereq.read = vif.emif_amm_read[0];
                ereq.address = vif.emif_amm_address[0];
                ereq.byteenable = vif.emif_amm_byteenable[0];

                scb_emif_writeback.put(ereq);
            end

            if ((vif.emif_amm_read || vif.emif_amm_write) && (vif.emif_amm_address[0] >= 'hf0000 + 'h20000)) begin
                ereq.writedata = vif.emif_amm_writedata[0];
                ereq.write = vif.emif_amm_write[0];
                ereq.read = vif.emif_amm_read[0];
                ereq.address = vif.emif_amm_address[0];
                ereq.byteenable = vif.emif_amm_byteenable[0];

                scb_emif_user.put(ereq);
            end

            /* This is a tricky way to monitor CAFU request. Only works in this scenario. */
            if (vif.awvalid == 1'b1) begin
                cafureq.address = vif.awaddr;
            end else if (vif.wvalid == 1'b1) begin
                cafureq.writedata = vif.wdata;
                cafureq.write = 1'b1;
                scb_cafu_mbx.put(cafureq);
            end
            
        end

    endtask //automatic
    
endclass //monitor
