// Testbench to simulate operation of the gauss_kernel_dotprod module. 

`timescale 1ns/10ps

module gauss_dotprod_tb
  logic [2:0] sigma;
  logic [7:0] din [10:0];
  logic [7:0] dout;

  gauss_kernel_dotprod uut(.*);

  initial begin
    din = '{default:8'hff};   #5
    for (int=0; i<8; i=i+1)
      sigma = i;              #5

    din = '{default:8'7f};    #5
    for (int=0; i<8; i=i+1)
      sigma = i;              #5

    //     [12 198 30 142 172 225 227 220 246 129 134]
    din = '{8'h0c, 8'hc6, 8'h1e, 8'h8e, 8'hac, 8'he1, 8'he3, 8'hdc, 8'hf6, 8'h81, 8'h86};   #5
    for (int=0; i<8; i=i+1)
      sigma = i;              #5

    $stop;
  end

endmodule
