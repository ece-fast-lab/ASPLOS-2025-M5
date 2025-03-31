import ctrl_signal_types::mem_request_t;

module roundrobin_arbiter_tb ();

    /* generate the clock */
    logic clk;
    always #5 clk = (clk === 1'b0);
    default clocking tb_clk @(negedge clk); endclocking


    /* variable definitions */

    localparam NUM_INPUT_PORT = 2;
    logic reset_n;
    logic out_port_ready;
    logic [NUM_INPUT_PORT-1:0] req;
    logic [NUM_INPUT_PORT-1:0] grant;
    mem_request_t in_request [NUM_INPUT_PORT];
    mem_request_t out_request;
    logic [63:0] test_var;

    assign req = {in_request[1].read | in_request[1].write, in_request[0].read | in_request[0].write};


    /* instantiate the module */

    roundrobin_arbiter #(.NUM_INPUT_PORT(2)) dut (.*);


    /* task definitions */

    task automatic reset();
        reset_n                 <= 1'b0;
        for (int i = 0; i < NUM_INPUT_PORT; i++) begin
            in_request[i].read      <= 1'b0;
            in_request[i].write     <= 1'b0;
        end
        repeat(5) @(tb_clk);
        reset_n <= 1'b1;
        @(tb_clk);
    endtask : reset

    task check_req_equity(input mem_request_t expected, input mem_request_t x);
        assert (x.address == expected.address && x.read == expected.read && x.write == expected.write) 
            $display("Time=%0t [INFO] Request Check pass.\n", $time);
        else   $error("Time=%0t [ERROR] Expected  request output 0x%0h, \n got 0x%0h\n", $time, expected, x);
    endtask

    task check_grant_equity(input logic [NUM_INPUT_PORT-1:0] expected, input logic [NUM_INPUT_PORT-1:0] x);
        assert (x == expected) 
            $display("Time=%0t [INFO] Grant Check pass.\n", $time);
        else   $error("Time=%0t [ERROR] Expected grant output 0x%0h, \n got 0x%0h\n", $time, expected, x);
    endtask


    /* Stimulus */

    // Registered Version
    initial begin
        $timeformat(-9, 1, "ns");
        reset();


        /* Test 1: Only one port has requests */
        $display("Time=%0t [TEST] Test 1 begins.", $time);

        @(posedge clk);
        out_port_ready          = 1'b1;
        // send one request in port0
        in_request[0].read      = 1'b1;
        in_request[0].address   = 27'h8;
        in_request[1].write     = 1'b0;
        in_request[1].address   = 27'hA;
        // check output
        @(tb_clk); 
        // $display("[DEBUG] req is %h\n", req);
        check_req_equity(in_request[0], out_request);
        check_grant_equity(2'b01, grant);
        @(tb_clk);
        check_req_equity(in_request[0], out_request);
        check_grant_equity(2'b01, grant);
        @(tb_clk);
        check_req_equity(in_request[0], out_request);
        check_grant_equity(2'b01, grant);
    end
    
    // Combinational Version
    // initial begin
    //     $timeformat(-9, 1, "ns");
    //     reset();


    //     /* Test 1: Only one port has requests */
    //     $display("Time=%0t [TEST] Test 1 begins.", $time);

    //     @(posedge clk);
    //     out_port_ready          = 1'b1;
    //     // send one request in port0
    //     in_request[0].read      = 1'b1;
    //     in_request[0].address   = 27'h8;
    //     in_request[1].write     = 1'b0;
    //     in_request[1].address   = 27'hA;
    //     // check output
    //     @(tb_clk); 
    //     // $display("[DEBUG] req is %h\n", req);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);

    //     @(posedge clk);
    //     // send one request in port1
    //     in_request[0].read      = 1'b0;
    //     in_request[0].address   = 27'h8;
    //     in_request[1].write     = 1'b1;
    //     in_request[1].address   = 27'hA;
    //     // check output
    //     @(tb_clk); 
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);
    //     @(tb_clk); 
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);


    //     /* Test 2: Both ports have requests */
    //     $display("Time=%0t [TEST] Test 2 begins.", $time);

    //     @(posedge clk);
    //     in_request[0].read      = 1'b1;
    //     in_request[0].address   = 27'h8;
    //     in_request[1].write     = 1'b1;
    //     in_request[1].address   = 27'hA;
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);

    //     /* Test 3: If EMIF is not ready. */
    //     $display("Time=%0t [TEST] Test 3 begins.", $time);

    //     @(posedge clk);
    //     out_port_ready          = 1'b0;
    //     in_request[0].read      = 1'b1;
    //     in_request[0].address   = 27'h86;
    //     in_request[1].write     = 1'b1;
    //     in_request[1].address   = 27'hA4;
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b00, grant);
    //     @(posedge clk);
    //     out_port_ready          = 1'b1;
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b01, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[1], out_request);
    //     check_grant_equity(2'b10, grant);
    //     // The out request should stay there when EMIF is not ready
    //     @(posedge clk);
    //     out_port_ready          = 1'b0;
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b00, grant);
    //     @(tb_clk);
    //     check_req_equity(in_request[0], out_request);
    //     check_grant_equity(2'b00, grant);

    //     // @(tb_clk);
    //     test_var = '1;
    //     $display("[DEBUG] test variable: %0x", test_var);

    //     repeat(5) @(tb_clk);
    //     $finish;

    // end

    initial begin
        // $dumpfile("request_fifo.vcd");
        // $dumpvars;
        $fsdbDumpfile("rr_arbiter.fsdb");
        $fsdbDumpvars;
    end

    
endmodule