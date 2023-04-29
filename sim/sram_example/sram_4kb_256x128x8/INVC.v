//Verilog HDL for "sram_logic", "INVC" "functional"
//Manu Rathore


`timescale 1ns / 1ns
module INVC ( Y, A );

  input A;
  output Y;

 assign Y = ~A;
endmodule
