// Top module of SoC

import img_conv_pkg::*;
import img_sram_pkg::*;

module img_conv_top
(
  input  logic clk,
  input  logic rstn,
  input  logic en,

  input  opcode_t op,
  input  logic [7:0] din,   //rx
  output logic [7:0] dout,  //tx

  output logic busy
);

  // Global Registers
  logic [7:0] nrows;
  logic [7:0] ncols;
  logic [2:0] sigma;
  opcode_t currOp;


  // Instantiate SRAMs w/ core interface structs
  img_sram_ctrl_t sram_img_ctrl, sram_buf_ctrl;
  logic [7:0]     sram_img_dout, sram_buf_dout;

  img_sram_4_64 sram0
  (
    .clk(clk),
    .ctrl(sram_img_ctrl),
    .dout(sram_img_dout)
  );

  img_sram_4_64 sram1
  (
    .clk(clk),
    .ctrl(sram_buf_ctrl),
    .dout(sram_buf_dout)
  );



  // Instantiate IO RD/WR controllers w/ associated SRAM interface structs
  img_sram_ctrl_t io_rx_sram_ctrl;
  img_sram_ctrl_t io_tx_sram_ctrl;
  logic io_rx_en,   io_tx_en;
  logic io_rx_rstn, io_tx_rstn;
  logic io_rx_busy, io_tx_busy;
  logic [7:0] io_tx_dout;

  io_rx_controller io_rxc
  (
    .clk(clk),
    .rstn(io_rx_rstn),
    .en(io_rx_en),
    .nrows(nrows),
    .ncols(ncols),
    .din(din),
    .busy(io_rx_busy),
    .sram_ctrl(io_rx_sram_ctrl)
  );

  io_tx_controller io_txc
  (
    .clk(clk),
    .rstn(io_tx_rstn),
    .en(io_tx_en),
    .nrows(nrows),
    .ncols(ncols),
    .dout(io_tx_dout),
    .busy(io_tx_busy),
    .sram_ctrl(io_tx_sram_ctrl),
    .sram_dout_in(sram_img_dout)
  );



  // Instantiate row convolution controller w/ associated SRAM interface structs
  img_sram_ctrl_t conv_sram_img_ctrl;
  img_sram_ctrl_t conv_sram_buf_ctrl;
  logic conv_rstn;
  logic conv_swap_sram;
  logic conv_busy;

  conv_row_controller convrc
  (
    .clk(clk),
    .rstn(conv_rstn),
    .nrows(conv_swap_sram ? ncols : nrows),
    .ncols(conv_swap_sram ? nrows : ncols),
    .sigma(sigma),
    .transpose_to_buf(1'b1),
    .busy(conv_busy),
    .sram_img_dout_in(conv_swap_sram ? sram_buf_dout : sram_img_dout),
    .sram_img_ctrl(conv_sram_img_ctrl),
    .sram_buf_ctrl(conv_sram_buf_ctrl)
  );



  // Implement SRAM interface controller multiplexing w/ hold state o/w
  img_sram_ctrl_t sram_ctrl_hold;
  assign sram_ctrl_hold.din = '0;
  assign sram_ctrl_hold.row = '0;
  assign sram_ctrl_hold.col = '0;
  assign sram_ctrl_hold.write_en = 1'b0;
  assign sram_ctrl_hold.sense_en = 1'b1;

  always_comb begin
    sram_img_ctrl = sram_ctrl_hold;
    sram_buf_ctrl = sram_ctrl_hold;

    // sram ctrl multiplexing
    case (currOp)
      OP_IMG_RX :   sram_img_ctrl = io_rx_sram_ctrl;
      OP_IMG_TX :   sram_img_ctrl = io_tx_sram_ctrl;
      OP_CONV   : begin
                    sram_img_ctrl = conv_swap_sram ? conv_sram_buf_ctrl : conv_sram_img_ctrl;
                    sram_buf_ctrl = conv_swap_sram ? conv_sram_img_ctrl : conv_sram_buf_ctrl;
                  end
    endcase
  end


  // busy signal multiplexing
  //  This is not set by ff to get sychronized insight into controller functionality
  always_comb begin
    case (currOp)
      OP_IMG_RX : busy = io_rx_busy;
      OP_IMG_TX : busy = io_tx_busy;
      OP_CONV   : busy = 1'b1;
      default   : busy = 1'b0;
    endcase
  end


  // dout multiplexing
  opcode_t dout_op_select;
  always_latch begin
    case (dout_op_select)
      OP_GET_NROWS : dout = nrows;
      OP_GET_NCOLS : dout = ncols;
      OP_GET_SIGMA : dout = sigma;
      // OP_SET_NROWS : dout = nrows;
      // OP_SET_NCOLS : dout = ncols;
      // OP_SET_SIGMA : dout = sigma;
      OP_IMG_TX    : dout = io_tx_dout;
      OP_CONV      : dout = 8'h01;
      OP_NOP       : dout = '0;
    endcase
  end



  // State machine control logic
  logic conv_op_starting;
  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      currOp <= OP_NOP;
      conv_op_starting = 0'b0;
      nrows <= 8'd8;
      ncols <= 8'd8;
      sigma <= 3'b0;
      dout_op_select <= OP_NOP;

      io_rx_en   <= 1'b0;
      io_tx_en   <= 1'b0;
      io_rx_rstn <= 1'b0;
      io_tx_rstn <= 1'b0;
      conv_rstn  <= 1'b0;
      conv_swap_sram <= 1'b0;
    end else begin
      io_rx_rstn <= 1'b1;
      io_tx_rstn <= 1'b1;

      if ((currOp == OP_NOP) && en) begin
        // start new op
        case (op)
          OP_GET_NROWS:  dout_op_select <= OP_GET_NROWS;
          OP_GET_NCOLS:  dout_op_select <= OP_GET_NCOLS;
          OP_GET_SIGMA:  dout_op_select <= OP_GET_SIGMA;
          OP_SET_NROWS:  begin nrows <= (din) ? din : 1;  dout_op_select <= OP_GET_NROWS; end
          OP_SET_NCOLS:  begin ncols <= (din) ? din : 1;  dout_op_select <= OP_GET_NCOLS; end
          OP_SET_SIGMA:  begin sigma <= din[2:0];         dout_op_select <= OP_GET_SIGMA; end

          OP_IMG_RX: begin
            currOp <= OP_IMG_RX;
            io_rx_en <= '1;
          end
          OP_IMG_TX: begin
            currOp <= OP_IMG_TX;
            io_tx_en <= '1;
            dout_op_select <= OP_IMG_TX;
          end
          OP_CONV: begin
            currOp <= OP_CONV;
            conv_rstn <= '1;
            conv_swap_sram <= '0;
            conv_op_starting <= 1;
            dout_op_select <= OP_NOP;
          end
          default:  currOp <= OP_NOP;  // do nothing
        endcase
      end
      else if (currOp == OP_IMG_RX) begin
        if (io_rx_en) begin
          io_rx_en <= ~io_rx_busy;
        end else begin
          currOp <= io_rx_busy ? OP_IMG_RX : OP_NOP;
        end
      end
      else if (currOp == OP_IMG_TX) begin
        if (io_tx_en) begin
          io_tx_en <= ~io_tx_busy;
        end else begin
          currOp <= io_tx_busy ? OP_IMG_TX : OP_NOP;
        end
      end
      else if (currOp == OP_CONV) begin
        // Convolution needs to run twice
        if (conv_op_starting) begin
          conv_op_starting <= ~conv_busy;
        end
        else if (!conv_swap_sram) begin
          // First Pass:  Conv across rows
          if (!conv_busy) begin
            conv_swap_sram <= '1;
            conv_rstn <= '0;
          end
        end
        else begin
          // Second Pass:  Conv down cols
          if (!conv_rstn) begin
            conv_rstn <= '1;
            conv_op_starting <= '1;
            dout_op_select <= OP_CONV;
          end
          else if (!conv_busy) begin
            // Done
            conv_swap_sram <= '0;
            conv_rstn <= '0;
            currOp <= OP_NOP;
          end
        end
      end
    end
  end

endmodule