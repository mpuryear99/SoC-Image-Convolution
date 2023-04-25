// Module to facilitate reading image data from SRAM

module io_tx_controller
(
  // input  logic clk,
  input  logic en,
  input  logic rstn,
  input  logic [7:0] nrows,
  input  logic [7:0] ncols,

  output logic [7:0] dout,
  output logic busy,

  img_sram_intf.mst  sram_img
);

  logic clk;
  assign clk = sram_img.clk;

  logic [8:0] row_idx;
  logic [8:0] col_idx;
  assign sram_img.sense_en = ~busy;
  assign sram_img.write_en = 0;
  assign sram_img.row = row_idx[7:0];
  assign sram_img.col = col_idx[7:0];
  assign sram_img.din = 8'hzz; // tristate

  always_ff @(posedge clk) begin
    dout <= sram_img.dout;
  end


  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn || !(en || busy)) begin
      busy <= 0;
      row_idx <= 0;
      col_idx <= 0;
    end
    else if (en || busy) begin
      // output starts one clock cycle after en
      if (row_idx < nrows) begin
        if (busy) begin
          if (col_idx < ncols) begin
            col_idx <= col_idx + 1;
          end else begin
            row_idx <= row_idx + 1;
            col_idx <= 0;
          end
        end else busy <= 1;
      end else begin
        // TODO (MAYBE):  delay end by one cycle to ensure final output is written
        busy <= 0;
        row_idx <= 0;
        col_idx <= 0;
      end
    end
  end

endmodule