// Wrapper module for 256x256 SRAM of 8-bit words
// (Created using 4 64x256 SRAMS)
//
// Operation:
//   Write: ( write_en &  sense_en)  tied to clk low
//   Read:  (~write_en & ~sense_en)  begins on clk low, dout ready at clk high, then quickly tri-stated
//   Hold:  (~write_en &  sense_en)
//
//  *** Address must be set before negedge clk and held until posedge clk. ***
//  ***   As such, it is best to only change address on posedge clk.       ***

import img_sram_pkg::*;

module img_sram_4_64
(
  input  logic           clk,
  input  img_sram_ctrl_t ctrl,
  output logic [7:0]     dout
);

  logic [3:0] write_en;
  logic [3:0] sense_en;
  logic [7:0] dout_n [3:0];
  logic [1:0] dout_select;
  logic [7:0] din, row, col;

  assign din = ctrl.din;
  assign row = ctrl.row;
  assign col = ctrl.col;

  // might not need, but better safe than sorry...
  always_ff @(negedge clk) begin
    dout_select <= row[7:6];
  end

  assign dout = dout_n[dout_select];

  generate
    genvar i;
    for (i=0; i<4; i=i+1) begin
      assign write_en[i] = (row[7:6] == i) ? ctrl.write_en : 1'b0;
      assign sense_en[i] = (row[7:6] == i) ? ctrl.sense_en : 1'b1;

      sram_compiled_array sram_gen (
        .clk(clk),
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

        .din0(din[0]),    .dout0(dout_n[i][0]),
        .din1(din[1]),    .dout1(dout_n[i][1]),
        .din2(din[2]),    .dout2(dout_n[i][2]),
        .din3(din[3]),    .dout3(dout_n[i][3]),
        .din4(din[4]),    .dout4(dout_n[i][4]),
        .din5(din[5]),    .dout5(dout_n[i][5]),
        .din6(din[6]),    .dout6(dout_n[i][6]),
        .din7(din[7]),    .dout7(dout_n[i][7])
      );
    end
  endgenerate

endmodule