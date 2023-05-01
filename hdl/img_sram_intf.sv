// Interface to img_sram module
// *** DEPRECATED ***

interface img_sram_intf
(
  input logic clk
);

  logic [7:0] row;
  logic [7:0] col;
  logic [7:0] din;
  logic [7:0] dout;
  logic write_en, sense_en;

  modport mst
  (
    input  clk,

    input  dout,

    output din,
    output row,
    output col,
    output write_en,
    output sense_en
  );

  modport slv
  (
    input  clk,

    output dout,

    input  din,
    input  row,
    input  col,
    input  write_en,
    input  sense_en
  );

endinterface