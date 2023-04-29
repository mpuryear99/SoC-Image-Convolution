//Verilog HDL for "sram_logic", "INVC" "functional"


`timescale 1ns / 1ns
module INVD ( Y, A );

  input A;
  output Y;

 assign Y = ~A;
endmodule
