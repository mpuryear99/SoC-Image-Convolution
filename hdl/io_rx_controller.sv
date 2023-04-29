// Module to facilitate writing image data to SRAM

module io_rx_controller
(
  // input  logic clk,
  input  logic en,
  input  logic rstn,
  input  logic [7:0] nrows,
  input  logic [7:0] ncols,
  input  logic [7:0] din,

  output logic busy,

  img_sram_intf.mst  sram_img
);

  logic clk;
  assign clk = sram_img.clk;

  logic [8:0] row_idx;
  logic [8:0] col_idx;
  logic [7:0] din_hold;
  assign sram_img.sense_en = 1'b1;
  assign sram_img.write_en = busy;
  assign sram_img.row = row_idx[7:0];
  assign sram_img.col = col_idx[7:0];
  assign sram_img.din = din_hold;

  always_ff @(posedge clk) begin
    din_hold <= din;
  end

  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      busy <= 0;
      row_idx <= 0;
      col_idx <= 0;
    end
    else if ((en || busy) && (row_idx <= nrows)) begin
      if (col_idx < ncols) begin
        busy <= 1;
        col_idx <= col_idx + 1;
      end else begin
        busy    <= row_idx < nrows;
        row_idx <= row_idx < nrows ? (row_idx + 1) : '0;
        col_idx <= '0;
      end
    end else begin
      busy <= 1'b0;
      row_idx <= '0;
      col_idx <= '0;
    end
  end

endmodule