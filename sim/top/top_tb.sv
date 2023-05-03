// Testbench for img_conv_top module

import img_conv_pkg::*;

module top_tb;

  localparam SIGMA = 5;
  localparam NROWS = 16;
  localparam NCOLS = 16;
  localparam FILE_RD = "../../images/noise_16_16.bin";
  localparam FILE_WR = "./tb_data_out.bin";
  localparam DO_CONV = 0;
  localparam DO_FILE_WRITE = 0;

  logic [7:0] img_data_in  [0:NROWS*NCOLS-1];
  logic [7:0] img_data_out [0:NROWS*NCOLS-1];

  logic clk, rstn;
  logic  en, busy;
  logic [7:0] din;
  logic [7:0] dout;
  opcode_t    op;

  img_conv_top uut(.(*));

  // Setup clock with period of 2ns
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end


  integer i;
  integer fd;
  initial begin

    // Power-on reset
    rstn = 0;
    en = 0;
    op = OP_NOP;
    @(posedge clk);
    rstn = 0;

    // test NOP (Check signals in sim)
    @(negedge clk);
    en = 1;
    @(negedge clk);

    // Test setting nrows, ncols, sigma
    @(negedge clk);
    din = NROWS;
    op = OP_SET_NROWS;
    @(negedge clk);
    op = OP_GET_NROWS;
    @(negedge clk);
    assert (dout == NROWS) $display ("OK. NROWS set.");

    din = NCOLS;
    op = OP_SET_NCOLS;
    @(negedge clk);
    op = OP_GET_NCOLS;
    @(negedge clk);
    assert (dout == NCOLS) $display ("OK. NCOLS set.");

    din = SIGMA;
    op = OP_SET_SIGMA;
    @(negedge clk);
    op = OP_GET_SIGMA;
    @(negedge clk);
    assert (dout == SIGMA) $display ("OK. SIGMA set.");

    // Basic param tests done
    en = 0;
    op = OP_NOP;
    @(posedge clk);


    // Read test file
    fd = $fopen(FILE_RD,"rb");
    if (fd==0) begin
      $display("Could not open input file.");
      $stop;
    end
    $fread(img_data_in, fd);
    $fclose(fd);


    // Start RX test
    @(negedge clk);
    op = OP_IMG_RX;
    en = 1;
    din = img_data_in[0];

    @(posedge busy); // wait for io_rx_controller start
    en = 0;
    for (i=1; i<(NROWS*NCOLS); i=i+1) begin
      @(posedge clk);
      io_din = img_data_in[i];
    end

    if (busy) @(negedge busy);
    en = 0;
    op = OP_NOP;
    din = 'X;
    @(posedge clk);


    // Start Convolution test
    if (DO_CONV) begin
      @(negedge clk);
        en = 1;
        op = OP_CONV;

      @(posedge busy);
      en = 0;
      @(negedge busy);
      op = OP_NOP;
      @(posedge clk);
      @(posedge clk);
    end


    // Start TX test
    @(negedge clk);
    op = OP_IMG_TX;
    en = 1;

    @(posedge busy); // wait for io_tx_controller start
    en = 0;
    @(posedge clk);  // TX first output starts 1 cycle after busy
    for (i=0; i<(NROWS*NCOLS); i=i+1) begin
      @(negedge clk);
      img_data_out[i];
    end

    if (busy) @(negedge busy);


    if (!DO_CONV) begin
      assert (img_data_in == img_data_out)
        $display ("OK. TX data matches RX.");
    end


    if (DO_FILE_WRITE) begin
      fd = $fopen(FILE_WR,"wb");
      if (fd==0) begin
        $display("Could not open output file.");
        $stop;
      end
      for (i=0; i<(ROWS*COLS); i=i+1)
        $fwrite(fd, "%c", img_data_out[i]);
      $fclose(fd);
    end

    $stop;
  end


endmodule