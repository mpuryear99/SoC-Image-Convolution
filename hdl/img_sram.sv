// Wrapper module for 256x256 SRAM of 8-bit words
//
// Operation:
//   Write: ( write_en &  sense_en)  tied to clk low
//   Read:  (~write_en & ~sense_en)  begins on clk low, dout ready at clk high, then quickly tri-stated
//   Hold:  (~write_en &  sense_en)

import img_sram_pkg::*;

module img_sram
(
  input  logic            clk,
  input  img_sram_ctrl_t  ctrl,
  output [7:0]            dout
);

  sram_compiled_array sram (
    .clk(clk),
    .write_en(ctrl.write_en),
    .sense_en(ctrl.sense_en),

    .addr0(ctrl.col[0]),   .addr8( ctrl.row[0]),
    .addr1(ctrl.col[1]),   .addr9( ctrl.row[1]),
    .addr2(ctrl.col[2]),   .addr10(ctrl.row[2]),
    .addr3(ctrl.col[3]),   .addr11(ctrl.row[3]),
    .addr4(ctrl.col[4]),   .addr12(ctrl.row[4]),
    .addr5(ctrl.col[5]),   .addr13(ctrl.row[5]),
    .addr6(ctrl.col[6]),   .addr14(ctrl.row[6]),
    .addr7(ctrl.col[7]),   .addr15(ctrl.row[7]),

    .din0(ctrl.din[0]),    .dout0(dout[0]),
    .din1(ctrl.din[1]),    .dout1(dout[1]),
    .din2(ctrl.din[2]),    .dout2(dout[2]),
    .din3(ctrl.din[3]),    .dout3(dout[3]),
    .din4(ctrl.din[4]),    .dout4(dout[4]),
    .din5(ctrl.din[5]),    .dout5(dout[5]),
    .din6(ctrl.din[6]),    .dout6(dout[6]),
    .din7(ctrl.din[7]),    .dout7(dout[7])
  );

endmodule