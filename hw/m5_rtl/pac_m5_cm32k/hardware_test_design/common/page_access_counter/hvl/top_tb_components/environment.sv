/* The environment is a container object simply holding all verification
 * components together
 */

class environment;
    driver d0;
    monitor m0;
    scoreboard s0;

    mailbox scb_req_mbx;
    mailbox scb_buf_mbx;
    mailbox scb_emif_mbx;
    mailbox scb_emif_writeback;
    mailbox scb_emif_user;
    mailbox scb_cafu_mbx;
    virtual pac_itf vif;

    // Instantiate all testbench components
    function new();
        d0 = new;
        m0 = new;
        s0 = new;
        scb_req_mbx = new();
        scb_buf_mbx = new();
        scb_emif_mbx = new();
        scb_emif_writeback = new();
        scb_emif_user = new();
        scb_cafu_mbx = new();
    endfunction

    // Assign handles and start all components
    virtual task automatic run();
        d0.vif = vif;
        m0.vif = vif;
        s0.vif = vif;
        m0.scb_req_mbx = scb_req_mbx;
        m0.scb_buf_mbx = scb_buf_mbx;
        m0.scb_emif_mbx = scb_emif_mbx;
        m0.scb_emif_writeback = scb_emif_writeback;
        m0.scb_emif_user = scb_emif_user;
        m0.scb_cafu_mbx = scb_cafu_mbx;
        
        s0.scb_req_mbx = scb_req_mbx;
        s0.scb_buf_mbx = scb_buf_mbx;
        s0.scb_cafu_mbx = scb_cafu_mbx;

        fork
            s0.run();
            d0.run();
            m0.run();
        join_any
    endtask //automatic

endclass //environment
