// Module to perform convolution across rows

import img_sram_pkg::*

// Not designed for ncols < 6
// Rather than using an enable signal, just hold rstn high.
//   (easy way to ensure everything is reset on start)
module conv_row_controller
(
  input  logic       clk,
  input  logic       rstn,
  input  logic [7:0] nrows,
  input  logic [7:0] ncols,
  input  logic [2:0] sigma,
  input  logic       transpose_to_buf,

  output logic       busy,

  input  logic [7:0]     sram_img_dout_in,
  output img_sram_ctrl_t sram_img_ctrl,   // input
  output img_sram_ctrl_t sram_buf_ctrl,   // output
);

  logic [7:0] conv_buff [10:0];
  logic [7:0] conv_dout;

  logic sr_rstn, sr_en;
  logic sr_center_shift;

  shift_reg2 sreg
  #(.N(11), .B(8))
  (
    .clk(clk),
    .rstn(sr_rstn),
    .up_en(sr_en),
    .down_en(sr_center_shift),
    .din(sram_img_dout_in),
    .dout(conv_buff)
  );

  gauss_kernel_dotprod gkdp
  (
    .sigma(sigma),
    .din(conv_buff),
    .dout(conv_dout)
  );



  logic [7:0] row_read_idx;
  logic [7:0] row_write_idx;
  logic [7:0] col_read_idx;
  logic [7:0] col_write_idx;
  logic [7:0] cols_read;

  logic [3:0] postload_offset;
  logic write_en;
  logic done;

  always_comb begin
    // Always read from main img sram
    sram_img_ctrl.write_en = 1'b0;
    sram_img_ctrl.sense_en = 1'b0;
    sram_img_ctrl.row = row_read_idx;
    sram_img_ctrl.col = col_read_idx;
    // sr_din = sram_img.dout;

    // Conditional write to buffer sram
    sram_buf_ctrl.write_en = write_en;
    sram_buf_ctrl.sense_en = 1'b1;
    sram_buf_ctrl.row = transpose_to_buf ? col_write_idx : row_write_idx;
    sram_buf_ctrl.col = transpose_to_buf ? row_write_idx : col_write_idx;
    sram_buf_ctrl.din = conv_dout;  // May need to create a ff for last_conv_dout
  end


  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      busy <= '0;
      done <= '0;

      sr_rstn <= '0;
      sr_en <= '0;
      sr_center_shift <= '0;

      row_read_idx <= '0;
      row_write_idx <= '0;
      col_read_idx <= '0;
      col_write_idx <= '0;

      cols_read <= '0;
      postload_offset <= '0;
    end
    else if (!done) begin
      busy <= 1;

      // always shift (Note: read takes 1 cycle so first shift is trash)
      sr_en <= 1;

      // This should always be delayed by 1 clock cycle
      row_write_idx <= row_read_idx;

      if (col_read_idx < 6) begin
        // new row preload (front mirror)
        sr_center_shift <= 1;
        col_write_idx <= 0;
        col_read_idx <= col_read_idx + 1;
        cols_read <= cols_read + 1;

        write_en <= 0;
      end
      else if (cols_read >= ncols) begin
        col_write_idx <= col_write_idx + 1;
        write_en <= 1;

        if (postload_offset < 5) begin
          // postload (mirror of last 5 cols, reverse read direction)
          // write_en <= 1;
          col_read_idx <= (ncols-1) - postload_offset;
          postload_offset <= postload_offset + 1;
        end
        else if (row_read_idx < nrows) begin
          // reset and start next row
          // write_en <= 1; // Still need to write the last col (VERIFY THIS)
          row_read_idx <= row_read_idx + 1;
          col_read_idx <= 0;
          cols_read <= 0;
          postload_offset <= 0;
        end
        else begin
          // done (no more rows)
          done <= 1;
          // write_en <= 1; // Still need to write the last col (VERIFY THIS)
        end
      end
      else begin
        // middle columns
        col_write_idx <= col_write_idx + 1;
        col_read_idx <= col_read_idx + 1;
        cols_read <= cols_read + 1;
        write_en <= 1;
      end
    end
    else begin
      // after done
      write_en <= 0;
      busy <= 0;
    end

  end


endmodule