// Module to facilitate reading image data from SRAM

import img_sram_pkg::*;

module io_tx_controller
(
  input  logic       clk,
  input  logic       rstn,
  input  logic       en,
  input  logic [7:0] nrows,
  input  logic [7:0] ncols,

  output logic [7:0] dout,
  output logic       busy,

  output img_sram_ctrl_t sram_ctrl,
  input  logic [7:0]     sram_dout_in
);

  logic [8:0] row_idx;
  logic [8:0] col_idx;

  always_comb begin
    sram_ctrl.sense_en = ~busy;
    sram_ctrl.write_en = 1'b0;
    sram_ctrl.row = row_idx[7:0];
    sram_ctrl.col = col_idx[7:0];
    sram_ctrl.din = '0;  // not wring, so doesn't matter
  end

  always_ff @(posedge clk) begin
    dout <= sram_dout_in;
  end


  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      busy  <= 1'b0;
      row_idx <= '0;
      col_idx <= '0;
    end
    else if ((en || busy) && (row_idx <= nrows)) begin
      // output starts one clock cycle after en, so check if busy is set yet
      if (busy) begin
        if (col_idx < ncols) begin
          busy <= 1'b1;  // don't need, but keep anyways
          col_idx <= col_idx + 1;
        end else begin
          // TODO (MAYBE):  delay end by one cycle to ensure final output is written
          busy    <= row_idx < nrows;
          row_idx <= row_idx < nrows ? (row_idx + 1) : '0;
          col_idx <= '0;
        end
      end else busy <= 1'b1;
    end else begin
      busy  <= 1'b0;
      row_idx <= '0;
      col_idx <= '0;
    end
  end

endmodule