// io testbench

`timescale 1ns/10ps
import img_sram_pkg::*;

module sram_rx_tx_tb;

  localparam ROWS = 128;
  localparam COLS = 128;

  logic clk;
  logic [7:0] nrows;
  logic [7:0] ncols;
  logic [7:0] img_data_in  [0:ROWS*COLS-1];
  logic [7:0] img_data_out [0:ROWS*COLS-1];
  logic [7:0] io_din;
  logic [7:0] io_dout;

  assign nrows = ROWS;
  assign ncols = COLS;


  // Instantiate SRAM w/ interface struct
  img_sram_ctrl_t sram_ctrl;
  logic [7:0]     sram_dout;

  img_sram_4_64 uut_sram
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
    .clk(clk),
    .rstn(io_rx_rstn),
    .en(io_rx_en),
    .nrows(nrows),
    .ncols(ncols),
    .din(io_din),
    .busy(io_rx_busy),
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


  // Setup clock with period of 2ns
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end


  integer i;
  integer fd;
  initial begin

    fd = $fopen("cat_128_128.bin","rb");
    if (fd==0) begin
      $display("Could not open file image file.");
      $stop;
    end
    $fread(img_data_in, fd);
    $fclose(fd);


    io_rx_rstn = 0;
    io_tx_rstn = 0;

    connect_sram_rx = 1;
    io_rx_en = 0;
    io_tx_en = 0;

    @(posedge clk);
    io_rx_rstn = 1;
    io_tx_rstn = 1;

    @(posedge clk);
    @(negedge clk);
    io_rx_en = 1;
    io_din = img_data_in[0];

    for (i=0; i<(ROWS*COLS); i=i+1) begin
      @(posedge clk);
      io_rx_en = i < 1;
      io_din = img_data_in[i];
    end

    @(negedge io_rx_busy);
    connect_sram_rx = 0;
    io_rx_en = 0;

    @(posedge clk);
    @(negedge clk);

    io_tx_en = 1;
    @(posedge clk);  // start tx
    @(posedge clk);  // first tx valid 
    for (i=0; i<(ROWS*COLS); i=i+1) begin
      @(negedge clk);
      io_tx_en = 0;
      img_data_out[i] = io_dout;
    end

    // @(negedge io_tx_busy);


    fd = $fopen("cat_tb_128_128.bin","wb");
    if (fd==0) begin
      $display("Could not open file image output file.");
      $stop;
    end
    $fclose(fd);
    for (i=0; i<(ROWS*COLS); i=i+1)
      $fwrite(fd, "%u", img_data_out[i]);

    $stop;
  end

endmodule