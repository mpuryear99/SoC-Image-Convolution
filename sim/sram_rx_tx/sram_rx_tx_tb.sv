// io testbench

`timescale 1ns/10ps

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


  // Create a hold state SRAM interface
  img_sram_intf sram_hold_intf( .clk(clk) );
  assign sram_hold_intf.din = 8'hzz;
  assign sram_hold_intf.row = 8'd0;
  assign sram_hold_intf.col = 8'd0;
  assign sram_hold_intf.write_en = 1'b0;
  assign sram_hold_intf.sense_en = 1'b1;

  // Instantiate IO RD/WR controllers w/ associated SRAM interfaces
  img_sram_intf io_rx_sram_intf( .clk(clk) );
  img_sram_intf io_tx_sram_intf( .clk(clk) );
  logic io_rx_en,   io_tx_en;
  logic io_rx_rstn, io_tx_rstn;
  logic io_rx_busy, io_tx_busy;

  io_rx_controller uut_rx
  (
    .rstn(io_rx_rstn),
    .en(io_rx_en),
    .nrows(nrows),
    .ncols(ncols),
    .din(io_din),
    .busy(io_tx_busy),
    .sram_img(io_rx_sram_intf.mst)
  );

  io_tx_controller uut_tx
  (
    .en(io_tx_en),
    .rstn(io_tx_rstn),
    .nrows(nrows),
    .ncols(ncols),
    .dout(io_dout),
    .busy(io_tx_busy),
    .sram_img(io_tx_sram_intf.mst)
  );


  // Instantiate SRAM w/ interface
  img_sram_intf sram_intf( .clk(clk) );
  img_sram_4_64 sram0( .intf(sram_intf.slv) );


  // Setup SRAM connections
  logic connect_sram_tx;
  always_comb begin
    sram_intf.din      = connect_sram_tx ? io_tx_sram_intf.din      : io_rx_sram_intf.din;
    sram_intf.row      = connect_sram_tx ? io_tx_sram_intf.row      : io_rx_sram_intf.row;
    sram_intf.col      = connect_sram_tx ? io_tx_sram_intf.col      : io_rx_sram_intf.col;
    sram_intf.write_en = connect_sram_tx ? io_tx_sram_intf.write_en : io_rx_sram_intf.write_en;
    sram_intf.sense_en = connect_sram_tx ? io_tx_sram_intf.sense_en : io_rx_sram_intf.sense_en;

    io_rx_sram_intf.dout = sram_intf.dout;
    io_tx_sram_intf.dout = sram_intf.dout;
  end


  // Setup clock with period of 10ns
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end


  initial begin
    $readmemb("../../images/cat_128_128.bin", img_data_in);

    io_rx_rstn = 0;
    io_tx_rstn = 0;

    connect_sram_tx = 0;
    io_rx_en = 0;
    io_tx_en = 0;

    @(posedge clk);
    io_rx_rstn = 1;
    io_tx_rstn = 1;

    for (int i=0, i<(128*128); i=i+1) begin
      @(posedge clk);
      io_rx_en = i < 1;
      io_din = img_data_in[i];
    end

    @(negedge io_rx_busy);
    connect_sram_tx = 1;
    io_rx_en = 0;

    @(posedge clk);
    @(posedge clk);

    io_tx_en = 1;
    for (int i=0, i<(128*128); i=i+1) begin
      @(posedge clk);
      io_tx_en = 0;
      img_data_out[i] = io_dout;
    end

    @(negedge io_tx_busy);

    $writememb("cat_tb_128_128.bin", img_data_in);
    $stop;
  end

endmodule