// Wrapper module for 256x256 SRAM of 8-bit words
//
// Operation:
//   Write: ( write_en &  sense_en)  tied to clk low
//   Read:  (~write_en & ~sense_en)  begins on clk low, dout ready at clk high, then quickly tri-stated
//   Hold:  (~write_en &  sense_en)

module img_sram
(
  img_sram_intf.slv intf
);

  sram_compiled_array sram (
    .clk(intf.clk),
    .write_en(intf.write_en),
    .sense_en(intf.sense_en),

    .addr0(intf.col[0]),   .addr8( intf.row[0]),
    .addr1(intf.col[1]),   .addr9( intf.row[1]),
    .addr2(intf.col[2]),   .addr10(intf.row[2]),
    .addr3(intf.col[3]),   .addr11(intf.row[3]),
    .addr4(intf.col[4]),   .addr12(intf.row[4]),
    .addr5(intf.col[5]),   .addr13(intf.row[5]),
    .addr6(intf.col[6]),   .addr14(intf.row[6]),
    .addr7(intf.col[7]),   .addr15(intf.row[7]),

    .din0(intf.din[0]),    .dout0(intf.dout[0]),
    .din1(intf.din[1]),    .dout1(intf.dout[1]),
    .din2(intf.din[2]),    .dout2(intf.dout[2]),
    .din3(intf.din[3]),    .dout3(intf.dout[3]),
    .din4(intf.din[4]),    .dout4(intf.dout[4]),
    .din5(intf.din[5]),    .dout5(intf.dout[5]),
    .din6(intf.din[6]),    .dout6(intf.dout[6]),
    .din7(intf.din[7]),    .dout7(intf.dout[7])
  );

endmodule