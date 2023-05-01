// io testbench

`timescale 1ns/10ps
import img_sram_pkg::*;

module sram_rx_tx_tb;

  logic clk;
  logic [7:0] nrows;
  logic [7:0] ncols;
  logic [7:0] img_data_in  [0:128*128-1];
  logic [7:0] img_data_out [0:128*128-1];
  logic [7:0] io_din;
  logic [7:0] io_dout;

  assign nrows = 128;
  assign ncols = 128;


  // Instantiate SRAM w/ interface struct
  img_sram_ctrl_t sram_ctrl;
  logic [7:0]     sram_dout;

  img_sram uut_sram
  (
    .clk(clk),
    .ctrl(sram_ctrl),
    .dout(sram_dout)
  );


  // Instantiate IO RD/WR controllers w/ associated SRAM interface structs
  img_sram_ctrl_t io_rx_sram_ctrl;
  img_sram_ctrl_t io_tx_sram_ctrl;
  logic io_rx_en,   io_tx_en;
  logic io_rx_rstn, io_tx_rstn;
  logic io_rx_busy, io_tx_busy;

  io_rx_controller uut_rx
  (
    .clk(clk)
    .rstn(io_rx_rstn),
    .en(io_rx_en),
    .nrows(nrows),
    .ncols(ncols),
    .din(io_din),
    .busy(io_tx_busy),
    .sram_ctrl(io_rx_sram_ctrl)
  );

  io_tx_controller uut_tx
  (
    .clk(clk),
    .rstn(io_tx_rstn),
    .en(io_tx_en),
    .nrows(nrows),
    .ncols(ncols),
    .dout(io_dout),
    .busy(io_tx_busy),
    .sram_ctrl(io_tx_sram_ctrl),
    .sram_dout_in(sram_dout)
  );


  // Setup SRAM connections
  logic connect_sram_rx;
  assign sram_ctrl = connect_sram_rx ? io_rx_sram_ctrl : io_tx_sram_ctrl;


  // Setup clock with period of 10ns
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end


  integer i;
  initial begin
    $readmemb("../../images/cat_128_128.bin", img_data_in);

    io_rx_rstn = 0;
    io_tx_rstn = 0;

    connect_sram_rx = 1;
    io_rx_en = 0;
    io_tx_en = 0;

    @(posedge clk);
    io_rx_rstn = 1;
    io_tx_rstn = 1;

    for (i=0; i<(128*128); i=i+1) begin
      @(posedge clk);
      io_rx_en = i < 1;
      io_din = img_data_in[i];
    end

    @(negedge io_rx_busy);
    connect_sram_rx = 0;
    io_rx_en = 0;

    @(posedge clk);
    @(posedge clk);

    io_tx_en = 1;
    for (i=0; i<(128*128); i=i+1) begin
      @(posedge clk);
      io_tx_en = 0;
      img_data_out[i] = io_dout;
    end

    @(negedge io_tx_busy);

    $writememb("cat_tb_128_128.bin", img_data_in);
    $stop;
  end

endmodule