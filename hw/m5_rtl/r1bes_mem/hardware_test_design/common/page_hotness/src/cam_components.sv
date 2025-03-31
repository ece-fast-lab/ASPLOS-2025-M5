



module SR_FF
(
  input clk,
  input s,
  input r,
  output q
);

  reg q_r;
  assign q = q_r;
  
  always @ (posedge clk) begin
    if(s == 1) begin
      q_r <= 1;
    end
    else if(r == 1) begin
      q_r <= 0;
    end
    else if(s == 0 & r == 0) begin 
      q_r <= q_r;
    end
  end
endmodule




// Flip Flop array
module FF_array
#(
  parameter WORD_SIZE = 22
)
(
  input                  clk,
  input  [WORD_SIZE-1:0] data_in,
  input                  write_en,
  input                  search_en,

  output [WORD_SIZE-1:0] data_out,
  output                 match
);

  wire s_array [0:WORD_SIZE-1];
  wire r_array [0:WORD_SIZE-1];

  genvar i;
  generate for (i = 0; i < WORD_SIZE; i = i+1) begin: FF_inst
      assign s_array[i] = write_en ? data_in[i]  : 0;
      assign r_array[i] = write_en ? ~data_in[i] : 0;

      SR_FF
        Flipflops
        (
          .clk ( clk         ),
          .s   ( s_array[i]  ),
          .r   ( r_array[i]  ),
          .q   ( data_out[i] )
        );
    end
  endgenerate

  assign match = search_en ? (data_out == data_in) : 0;
endmodule




// Match (result of search) encoder
module encoder
#(
  parameter NUM_ENTRY   = 50,
  parameter ENTRY_WIDTH = 6
)
(
  input  [NUM_ENTRY-1:0]   match_array,
  output [ENTRY_WIDTH-1:0] match_addr,
  output                   match
);

  reg [ENTRY_WIDTH-1:0] match_addr_r;

  assign match_addr = match_addr_r;

  assign match = |match_array;
  

  /*
  always_comb begin
    casex(match_array)
      100'b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd99;
      100'bx100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd98;
      100'bxx10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd97;
      100'bxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd96;
      100'bxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd95;
      100'bxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd94;
      100'bxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd93;
      100'bxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd92;
      100'bxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd91;
      100'bxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd90;
      100'bxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd89;
      100'bxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd88;
      100'bxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd87;
      100'bxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd86;
      100'bxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd85;
      100'bxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd84;
      100'bxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd83;
      100'bxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd82;
      100'bxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd81;
      100'bxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd80;
      100'bxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd79;
      100'bxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd78;
      100'bxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd77;
      100'bxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd76;
      100'bxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd75;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd74;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd73;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd72;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd71;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd70;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd69;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd68;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd67;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd66;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd65;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd64;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd63;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd62;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd61;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd60;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd59;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd58;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd57;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd56;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd55;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000000: match_addr_r = 7'd54;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000000: match_addr_r = 7'd53;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000000: match_addr_r = 7'd52;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000000: match_addr_r = 7'd51;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000000: match_addr_r = 7'd50;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000000: match_addr_r = 7'd49;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000000: match_addr_r = 7'd48;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000000: match_addr_r = 7'd47;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000000: match_addr_r = 7'd46;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000000: match_addr_r = 7'd45;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000000: match_addr_r = 7'd44;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000000: match_addr_r = 7'd43;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000000: match_addr_r = 7'd42;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000000: match_addr_r = 7'd41;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000000: match_addr_r = 7'd40;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000000: match_addr_r = 7'd39;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000000: match_addr_r = 7'd38;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000000: match_addr_r = 7'd37;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000000: match_addr_r = 7'd36;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000000: match_addr_r = 7'd35;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000000: match_addr_r = 7'd34;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000000: match_addr_r = 7'd33;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000000: match_addr_r = 7'd32;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000000: match_addr_r = 7'd31;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000: match_addr_r = 7'd30;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000: match_addr_r = 7'd29;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000: match_addr_r = 7'd28;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000: match_addr_r = 7'd27;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000: match_addr_r = 7'd26;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000: match_addr_r = 7'd25;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000: match_addr_r = 7'd24;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000: match_addr_r = 7'd23;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000: match_addr_r = 7'd22;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000: match_addr_r = 7'd21;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000: match_addr_r = 7'd20;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000: match_addr_r = 7'd19;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000: match_addr_r = 7'd18;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000: match_addr_r = 7'd17;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000: match_addr_r = 7'd16;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000: match_addr_r = 7'd15;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000: match_addr_r = 7'd14;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000: match_addr_r = 7'd13;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000: match_addr_r = 7'd12;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000: match_addr_r = 7'd11;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000: match_addr_r = 7'd10;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000: match_addr_r = 7'd9;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000: match_addr_r = 7'd8;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000: match_addr_r = 7'd7;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000: match_addr_r = 7'd6;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000: match_addr_r = 7'd5;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000: match_addr_r = 7'd4;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000: match_addr_r = 7'd3;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100: match_addr_r = 7'd2;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10: match_addr_r = 7'd1;
      100'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1: match_addr_r = 7'd0;
      default: match_addr_r = 7'd0;
    endcase
  end
  */

  always_comb begin
    casex(match_array)
      50'b10000000000000000000000000000000000000000000000000: match_addr_r = 6'd49;
      50'bx1000000000000000000000000000000000000000000000000: match_addr_r = 6'd48;
      50'bxx100000000000000000000000000000000000000000000000: match_addr_r = 6'd47;
      50'bxxx10000000000000000000000000000000000000000000000: match_addr_r = 6'd46;
      50'bxxxx1000000000000000000000000000000000000000000000: match_addr_r = 6'd45;
      50'bxxxxx100000000000000000000000000000000000000000000: match_addr_r = 6'd44;
      50'bxxxxxx10000000000000000000000000000000000000000000: match_addr_r = 6'd43;
      50'bxxxxxxx1000000000000000000000000000000000000000000: match_addr_r = 6'd42;
      50'bxxxxxxxx100000000000000000000000000000000000000000: match_addr_r = 6'd41;
      50'bxxxxxxxxx10000000000000000000000000000000000000000: match_addr_r = 6'd40;
      50'bxxxxxxxxxx1000000000000000000000000000000000000000: match_addr_r = 6'd39;
      50'bxxxxxxxxxxx100000000000000000000000000000000000000: match_addr_r = 6'd38;
      50'bxxxxxxxxxxxx10000000000000000000000000000000000000: match_addr_r = 6'd37;
      50'bxxxxxxxxxxxxx1000000000000000000000000000000000000: match_addr_r = 6'd36;
      50'bxxxxxxxxxxxxxx100000000000000000000000000000000000: match_addr_r = 6'd35;
      50'bxxxxxxxxxxxxxxx10000000000000000000000000000000000: match_addr_r = 6'd34;
      50'bxxxxxxxxxxxxxxxx1000000000000000000000000000000000: match_addr_r = 6'd33;
      50'bxxxxxxxxxxxxxxxxx100000000000000000000000000000000: match_addr_r = 6'd32;
      50'bxxxxxxxxxxxxxxxxxx10000000000000000000000000000000: match_addr_r = 6'd31;
      50'bxxxxxxxxxxxxxxxxxxx1000000000000000000000000000000: match_addr_r = 6'd30;
      50'bxxxxxxxxxxxxxxxxxxxx100000000000000000000000000000: match_addr_r = 6'd29;
      50'bxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000000: match_addr_r = 6'd28;
      50'bxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000000: match_addr_r = 6'd27;
      50'bxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000000: match_addr_r = 6'd26;
      50'bxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000000: match_addr_r = 6'd25;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000000: match_addr_r = 6'd24;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000000: match_addr_r = 6'd23;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000000: match_addr_r = 6'd22;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000000: match_addr_r = 6'd21;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000000: match_addr_r = 6'd20;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000000: match_addr_r = 6'd19;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000000: match_addr_r = 6'd18;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000000: match_addr_r = 6'd17;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000000: match_addr_r = 6'd16;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000000: match_addr_r = 6'd15;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000000: match_addr_r = 6'd14;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000000: match_addr_r = 6'd13;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000000: match_addr_r = 6'd12;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000000: match_addr_r = 6'd11;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000000: match_addr_r = 6'd10;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000000: match_addr_r = 6'd9;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000000: match_addr_r = 6'd8;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000000: match_addr_r = 6'd7;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000000: match_addr_r = 6'd6;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100000: match_addr_r = 6'd5;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10000: match_addr_r = 6'd4;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1000: match_addr_r = 6'd3;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx100: match_addr_r = 6'd2;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx10: match_addr_r = 6'd1;
      50'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1: match_addr_r = 6'd0;
      default: match_addr_r = 7'd0;
    endcase
  end

  /*
  integer i;
  always @(*) begin
    match_addr_r = 0;
    for (i = NUM_ENTRY - 1; i >= 0; i = i-1) begin
      if (match_array[i] == 1'b1) begin
        match_addr_r = i;
      end
    end
  end
  */
endmodule


