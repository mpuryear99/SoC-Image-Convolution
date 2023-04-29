`timescale 1ns / 1ps 
module tb_sram_test ();
  logic clk, resetn;
  logic write_en, sense_en;
  logic [7:0]  dout;
  logic [7:0]  din;
  logic [11:0] addr;
  integer i = 0;

  logic clk_w;
  logic resetn_w;
  logic write_en_w;
  logic sense_en_w;
  logic [11:0] addr_w;
  logic [7:0]  din_w;

  initial begin
    clk = 'b0;
    resetn = 'b1;
    write_en = 'b0;
    sense_en = 'b1;
    addr = 'd0;
    din = 'd0;
  end

  assign clk_w = clk;
  assign resetn_w = resetn;
  assign write_en_w = write_en;
  assign sense_en_w = sense_en;
  assign addr_w = addr[11:0];
  assign din_w = din[7:0];

  always #20 clk = ~clk;

  initial begin
    @(posedge clk);
    addr = 2058;
    din = 50;
    write_en = 'b1;
    sense_en = 'b1;
    repeat(1) @(posedge clk);
    addr = 2058;
    din = 0;
    write_en = 'b0;
    sense_en = 'b0;
    repeat(1) @(posedge clk);
    addr = 18456;
    din = 40;
    write_en = 'b1;
    sense_en = 'b1;
    repeat(1) @(posedge clk);
    addr = 18442;
    din = 40;
    write_en = 'b1;
    sense_en = 'b1;
    repeat(1) @(posedge clk);
    addr = 18446;
    din = 40;
    write_en = 'b1;
    sense_en = 'b1;
    repeat(1) @(posedge clk);
    addr = 2058;
    din = 0;
    write_en = 'b0;
    sense_en = 'b0;
    repeat(50) @(posedge clk);
    $finish;
  end

  sram_4kb_256x128x8 SRAM_inst (
    .sense_en(sense_en_w), .write_en(write_en_w), .clk(clk_w),

    .addr11(addr_w[11]), .addr10(addr_w[10]), .addr9(addr_w[9]), .addr8(addr_w[8]),
    .addr7(addr_w[7]), .addr6(addr_w[6]), .addr5(addr_w[5]), .addr4(addr_w[4]),
    .addr3(addr_w[3]), .addr2(addr_w[2]), .addr1(addr_w[1]), .addr0(addr_w[0]),

    .din7(din_w[7]), .din6(din_w[6]), .din5(din_w[5]), .din4(din_w[4]),
    .din3(din_w[3]), .din2(din_w[2]), .din1(din_w[1]), .din0(din_w[0]),

    .dout7(dout[7]), .dout6(dout[6]), .dout5(dout[5]), .dout4(dout[4]),
    .dout3(dout[3]), .dout2(dout[2]), .dout1(dout[1]), .dout0(dout[0])
  );
endmodule
 


