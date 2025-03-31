module request_fifo_tb ();

    /* generate the clock */
    logic clk;
    always #5 clk = (clk === 1'b0);
    default clocking tb_clk @(negedge clk); endclocking

    localparam WIDTH = 640;

    /* define the signals */
    logic                   reset_n;
    logic                   pop_en;
    logic [WIDTH-1:0]       data_out;
    logic                   push_en;
    logic [WIDTH-1:0]       data_in;
    logic                   empty;
    logic                   full;

    request_fifo dut(.*);

    task automatic reset();
        reset_n <= 1'b0;
        pop_en <= 1'b0;
        push_en <= 1'b0;
        repeat(5) @(tb_clk);
        reset_n <= 1'b1;
        @(tb_clk);
    endtask : reset

    task finish();
        repeat (20) @(posedge clk);
        $display("[INFO] Test finished.");
        $finish;
    endtask : finish

    task push(input logic [WIDTH-1:0] d_in);
        data_in <= d_in;
        push_en <= 1'b1;
        @(tb_clk);
    endtask

    task pop();
        pop_en <= 1'b1;
        @(tb_clk);
        pop_en <= 1'b0;
        @(tb_clk);
    endtask //

    task check_equity(input logic [WIDTH-1:0] expected, input logic [WIDTH-1:0] x);
        assert (x == expected) 
            $display("[INFO] Check pass.\n");
        else   $error("[ERROR] Expected output 0x%0h, \n got 0x%0h\n", expected, x);
    endtask

    /* variables */
    logic [WIDTH-1:0] shadow_fifo [$];
    logic [WIDTH-1:0] data;

    initial begin
        reset();
        
        /* Test 1: Push and pop to limits */
        $display("[INFO] Test 1: Push and pop to limits");
        for (int i = 0; i < 32; i++) begin
            data = $urandom;
            shadow_fifo.push_back(data);
            push(data);
        end
        push_en <= 1'b0;
        @(tb_clk);
        for (int i = 0; i < 31; i++) begin
            data = shadow_fifo.pop_front();
            check_equity(data, data_out); // should check equity first because the output will always be there
            pop();
        end

        finish();
    end

    initial begin
        // $dumpfile("request_fifo.vcd");
        // $dumpvars;
        $fsdbDumpfile("request_fifo.fsdb");
        $fsdbDumpvars;
    end

endmodule
    