// Testbench to simulate operation of the shift_reg2 module. 

`timescale 1ns/10ps

module shift_reg_tb
  #(parameter N=11, B=8);

  logic clk;
  logic rstn;  
  logic up_en;
  logic down_en;
  logic [B-1:0] din;
  logic [B-1:0] dout [N-1:0];

  shift_reg2 #(.N(N), .B(B)) uut(.*);

  // Setup clock with period of 10ns
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test shifting in values 
  initial begin
    rstn = 0;
    up_en = 0;
    down_en = 0;
    din = 3;
    
    @(posedge clk)  rstn = 1;

    // Test Upwards Shift in N+1 (12) values --
    @(negedge clk)  up_en = 1;
    for (int i=0; i<=N; i=i+1) begin
      @(negedge clk)  din = din + 13;
    end

    // Check that values hold when 'en' is low --
    @(negedge clk)  up_en = 0;
    @(negedge clk);
    @(negedge clk)  up_en = 1;

    // Set 'rstn' low to clear SRAM again --
    @(negedge clk)  rstn = 0;
    @(negedge clk);
    @(negedge clk)  rstn = 1; up_en = 0; down_en = 1; din = 3;

    // Test Downwards Shift in N+1 (12) values --
    @(negedge clk)      
    for (int i=0; i<=N; i=i+1) begin
      @(negedge clk)  din = din + 13;
    end

    // Set 'rstn' low to clear SRAM again --
    @(negedge clk)  rstn = 0;
    @(negedge clk);
    @(negedge clk)  rstn = 1; up_en = 1; down_en = 1; din = 3;

    // Test Central Shift in N+1 (12) values --
    @(negedge clk)
    for (int i=0; i<=N; i=i+1) begin
      @(negedge clk)  din = din + 13;
    end
    @(posedge clk);
    $stop;
  end

endmodule