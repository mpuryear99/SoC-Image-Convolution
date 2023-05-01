// Wrapper module for 256x256 SRAM of 8-bit words
// (Created using 4 64x256 SRAMS)
//
//
// Operation:
//   Write: ( write_en &  sense_en)  tied to clk low
//   Read:  (~write_en & ~sense_en)  begins on clk low, dout ready at clk high, then quickly tri-stated
//   Hold:  (~write_en &  sense_en)
//
//  *** Address must be set before negedge clk and held until posedge clk. ***
//  ***   As such, it is best to only change address on posedge clk.       ***

module img_sram_4_64
(
  img_sram_intf.slv intf
);

  logic [3:0] write_en;
  logic [3:0] sense_en;
  logic [7:0] dout [3:0];
  logic [1:0] dout_select;
  logic [7:0] din, row, col;

  assign din = intf.din;
  assign row = intf.row;
  assign col = intf.col;

  // might not need, but better safe than sorry...
  always_ff @(negedge intf.clk) begin
    dout_select <= row[7:6];
  end

  assign intf.dout = dout[dout_select];

  generate
    genvar i;
    for (i=0; i<4; i=i+1) begin
      assign write_en = (row[7:6] == i) ? intf.write_en : 1'b0;
      assign sense_en = (row[7:6] == i) ? intf.sense_en : 1'b1;

      sram_compiled_array sram_gen (
        .clk(intf.clk),
        .write_en(write_en[i]),
        .sense_en(sense_en[i]),

        .addr0(col[0]),   .addr8( row[0]),
        .addr1(col[1]),   .addr9( row[1]),
        .addr2(col[2]),   .addr10(row[2]),
        .addr3(col[3]),   .addr11(row[3]),
        .addr4(col[4]),   .addr12(row[4]),
        .addr5(col[5]),   .addr13(row[5]),
        .addr6(col[6]),   //.addr14(row[6]),
        .addr7(col[7]),   //.addr15(row[7]),

        .din0(din[0]),    .dout0(dout[i][0]),
        .din1(din[1]),    .dout1(dout[i][1]),
        .din2(din[2]),    .dout2(dout[i][2]),
        .din3(din[3]),    .dout3(dout[i][3]),
        .din4(din[4]),    .dout4(dout[i][4]),
        .din5(din[5]),    .dout5(dout[i][5]),
        .din6(din[6]),    .dout6(dout[i][6]),
        .din7(din[7]),    .dout7(dout[i][7])
      );
    end
  endgenerate

endmodule