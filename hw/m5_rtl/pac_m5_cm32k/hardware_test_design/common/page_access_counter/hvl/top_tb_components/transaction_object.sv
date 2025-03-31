import ctrl_signal_types::*;

class mem_request;

    // randc mean each time randomization happens, a value can only repeat
    //  after all the other possible values have been chosen once
    rand    bit [MC_HA_DP_DATA_WIDTH-1:0]   writedata;
            bit [MC_HA_DP_BE_WIDTH-1:0]     byteenable = '1;
            bit                             write_ras_sbe = 1'b0;
            bit                             write_ras_dbe = 1'b0;
    rand    bit [EMIF_AMM_ADDR_WIDTH-1:0]   address;
    rand    bit                             read;
    rand    bit                             write;
            bit                             write_poison = 1'b0;  

    constraint c_read { 
        solve write before read;
        read == !write;
    }

    function void print(string tag="");
        $timeformat(-9, 1, "ns");
        $display("Time=%0t [%s] addr=0x%0h cntAddr=0x%0h r/w=%0d/%0d wdata=0x%0h",
                $time, tag, address, address[(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY)+SRAM_ADDR_WIDTH-1):(COUNTER_GRAN+$clog2(COUNTER_PER_ENTRY))], read, write, writedata);
    endfunction


endclass //mem_request

class counter_request;
    logic                               buf_wren;
    logic [SRAM_ADDR_WIDTH-1:0]         buf_wraddress;
    logic [SRAM_DATA_WIDTH-1:0]         buf_wdata;

    function void print(string tag="");
        $timeformat(-9, 1, "ns");
        $display("Time=%0t [%s] Counter address 0x%0h updated to 0x%0h",
                $time, tag, buf_wraddress, buf_wdata);
    endfunction
endclass //counter_request

class emif_request;

    bit [MC_HA_DP_DATA_WIDTH-1:0]   writedata;
    bit [MC_HA_DP_BE_WIDTH-1:0]     byteenable;
    bit [EMIF_AMM_ADDR_WIDTH-1:0]   address;
    bit                             read;
    bit                             write;

    function void print(string tag="");
        $timeformat(-9, 1, "ns");
        $display("Time=%0t [%s] addr=0x%0h r/w=%0d/%0d wdata=0x%0h",
                $time, tag, address, read, write, writedata);
    endfunction


endclass //emif_request

class cafu_request;

    bit [511:0]     writedata;
    bit [63:0]      address;
    bit             read;
    bit             write;

    function void print(string tag="");
        $timeformat(-9, 1, "ns");
        $display("Time=%0t [%s] addr=0x%0h r/w=%0d/%0d wdata=0x%0h",
                $time, tag, address, read, write, writedata);
    endfunction


endclass //cafu_request