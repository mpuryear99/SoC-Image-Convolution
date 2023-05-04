// Module to facilitate writing image data to SRAM

import img_sram_pkg::*;

module io_rx_controller
(
  input  logic       clk,
  input  logic       rstn,
  input  logic       en,
  input  logic [7:0] nrows,
  input  logic [7:0] ncols,
  input  logic [7:0] din,

  output logic       busy,

  output img_sram_ctrl_t sram_ctrl
);

  logic [8:0] row_idx;
  logic [8:0] col_idx;

  always_comb begin
    sram_ctrl.sense_en = 1'b1;
    sram_ctrl.write_en = busy;
    sram_ctrl.row = row_idx[7:0];
    sram_ctrl.col = col_idx[7:0];
    sram_ctrl.din = din;
  end


  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      busy  <= 1'b0;
      row_idx <= '0;
      col_idx <= '0;
    end
    else if ((en || busy) && (row_idx <= nrows)) begin
      if (col_idx < (ncols-1)) begin
        busy <= 1'b1;
        if (busy)
          col_idx <= col_idx + 1;
      end else begin
        busy    <= row_idx < nrows;
        row_idx <= row_idx < nrows ? (row_idx + 1) : '0;
        col_idx <= '0;
      end
    end else begin
      busy  <= 1'b0;
      row_idx <= '0;
      col_idx <= '0;
    end
  end

endmodule