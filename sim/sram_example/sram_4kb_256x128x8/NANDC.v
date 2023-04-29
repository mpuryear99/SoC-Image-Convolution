//Verilog HDL for "sram_logic", "NANDC2x1" "functional"


`timescale 1ns / 1ns
module NANDC2x1 ( Y, A, B );

  input A;
  output Y;
  input B;


  assign Y = !(A & B);

endmodule
