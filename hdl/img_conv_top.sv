
import img_conv_pkg::*;

`define CONNECT_SRAM_INTFS(SRAM_MST, SRAM_SLV) \
  begin \
    SRAM_MST.din      = SRAM_SLV.din; \
    SRAM_MST.row      = SRAM_SLV.row; \
    SRAM_MST.col      = SRAM_SLV.col; \
    SRAM_MST.write_en = SRAM_SLV.write_en; \
    SRAM_MST.sense_en = SRAM_SLV.sense_en; \
    SRAM_SLV.dout     = SRAM_MST.dout; \
  end


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

  // Interface modports cannot be multiplexed directly.
  // To solve this issue, each controller gets their own interface
  // initialized with the same clk as the SRAM interface.
  // This can then be used to connect all the ports of a
  // controller interface (slv) to the SRAM interface (mst).
  // NOTE: If this doesn't work, use a macro.
  // task connect_sram_intfs
  // (
  //   img_sram_intf.mst  sram_mst,  // The SRAM
  //   img_sram_intf.slv  sram_slv   // The Controller
  // );
  //   sram_mst.din      = sram_slv.din;
  //   sram_mst.row      = sram_slv.row;
  //   sram_mst.col      = sram_slv.col;
  //   sram_mst.write_en = sram_slv.write_en;
  //   sram_mst.sense_en = sram_slv.sense_en;
  //   sram_slv.dout     = sram_mst.dout;
  // endtask


  // Global Registers
  logic [7:0] nrows;
  logic [7:0] ncols;
  logic [2:0] sigma;
  opcode_t currOp;


  // Create a hold state SRAM interface
  img_sram_intf sram_hold_intf( .clk(clk) );
  assign sram_hold_intf.mst.din = 8'hzz;
  assign sram_hold_intf.mst.row = 8'd0;
  assign sram_hold_intf.mst.col = 8'd0;
  assign sram_hold_intf.mst.write_en = 1'b0;
  assign sram_hold_intf.mst.sense_en = 1'b1;


  // Instantiate SRAMs w/ core interfaces
  img_sram_intf sram_img_intf( .clk(clk) );
  img_sram_intf sram_buf_intf( .clk(clk) );
  img_sram sram0( .intf(sram_img_intf.slv) );
  img_sram sram1( .intf(sram_buf_intf.slv) );



  // Instantiate IO RD/WR controllers w/ associated SRAM interfaces
  img_sram_intf io_rx_sram_img_intf( .clk(clk) );
  img_sram_intf io_tx_sram_img_intf( .clk(clk) );
  logic io_rx_en,   io_tx_en;
  logic io_rx_rstn, io_tx_rstn;
  logic io_rx_busy, io_tx_busy;

  io_rx_controller io_rxc
  (
    .rstn(io_rx_rstn),
    .en(io_rx_en),
    .nrows(nrows),
    .ncols(ncols),
    .din(din),
    .busy(io_tx_busy),
    .sram_img(io_rx_sram_img_intf.mst)
  );

  io_tx_controller io_txc
  (
    .en(io_tx_en),
    .rstn(io_tx_rstn),
    .nrows(nrows),
    .ncols(ncols),
    .dout(dout),
    .busy(io_tx_busy),
    .sram_img(io_tx_sram_img_intf.mst)
  );



  // Instantiate row convolution controller w/ associated SRAM interfaces
  img_sram_intf conv_sram_img_intf( .clk(clk) );
  img_sram_intf conv_sram_buf_intf( .clk(clk) );
  logic conv_rstn;
  logic conv_swap_sram;
  logic conv_busy;

  conv_row_controller convrc
  (
    .clk(clk),
    .rstn(conv_rstn),
    .nrows(conv_swap_sram ? ncols : nrows),
    .ncols(conv_swap_sram ? nrows : ncols),
    .transpose_to_buf(1'b1),
    .sigma(sigma),
    .busy(conv_busy),
    .sram_img(conv_sram_img_intf.mst),
    .sram_buf(conv_sram_buf_intf.mst)
  );



  // Implement SRAM interface controller multiplexing
  always_comb begin
    // sram_img
    unique case (currOp)
      OP_IMG_RX: `CONNECT_SRAM_INTFS(sram_img_intf.mst, io_rx_sram_img_intf.slv)
      OP_IMG_TX: `CONNECT_SRAM_INTFS(sram_img_intf.mst, io_tx_sram_img_intf.slv)
      OP_CONV: begin
        if (conv_swap_sram)
          `CONNECT_SRAM_INTFS(sram_img_intf.mst, conv_sram_buf_intf.slv)
        else
          `CONNECT_SRAM_INTFS(sram_img_intf.mst, conv_sram_img_intf.slv)
      end
      default:   `CONNECT_SRAM_INTFS(sram_img_intf.mst, sram_hold_intf.slv)
    endcase

    // sram_buf
    if (currOp != OP_CONV)
      `CONNECT_SRAM_INTFS(sram_buf_intf.mst, sram_hold_intf.slv)
    else if (conv_swap_sram)
      `CONNECT_SRAM_INTFS(sram_buf_intf.mst, conv_sram_img_intf.slv)
    else
      `CONNECT_SRAM_INTFS(sram_buf_intf.mst, conv_sram_buf_intf.slv)
  end


  // State machine control logic
  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      currOp <= OP_NOP;
      busy  <= 1'b0;
      nrows <= 8'd8;
      ncols <= 8'd8;
      sigma <= 3'b0;

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
          OP_GET_NROWS:  dout  <= nrows;
          OP_GET_NCOLS:  dout  <= ncols;
          OP_GET_SIGMA:  dout  <= sigma;   // may need to zero pad
          OP_SET_NROWS:  nrows <= din;
          OP_SET_NCOLS:  ncols <= din;
          OP_SET_SIGMA:  sigma <= din[2:0];

          OP_IMG_RX: begin
            currOp <= OP_IMG_RX;
            busy <= '1;
            io_rx_en <= '1;
          end
          OP_IMG_TX: begin
            currOp <= OP_IMG_TX;
            io_tx_en <= '1;
            busy <= '1;
          end
          OP_CONV: begin
            currOp <= OP_CONV;
            conv_rstn <= '1;
            conv_swap_sram <= '0;
            busy <= '1;
          end
          default:  currOp <= OP_NOP;  // do nothing
        endcase
      end
      else if (currOp == OP_IMG_RX) begin
        io_rx_en <= '0;
        busy <= io_rx_busy;
        currOp <= io_rx_busy ? OP_IMG_RX : OP_NOP;
      end
      else if (currOp == OP_IMG_TX) begin
        io_tx_en <= '0;
        busy <= io_tx_busy;
        currOp <= io_tx_busy ? OP_IMG_TX : OP_NOP;
      end
      else if (currOp == OP_CONV) begin
        // Convolution needs to run twice
        if (!conv_swap_sram) begin
          // First Pass:  Conv across rows
          busy <= '1;
          if (!conv_busy) begin
            conv_swap_sram <= '1;
            conv_rstn <= '0;
          end
        end else begin
          // Second Pass:  Conv down cols
          if (!conv_rstn) begin
            busy <= '1;
            conv_rstn <= '1;
          end
          else if (!conv_busy) begin
            // Done
            busy <= 0;
            conv_swap_sram <= '0;
            conv_rstn <= '0;
            currOp <= OP_NOP;
          end
        end
      end
    end
  end


endmodule