// Basic FIFO shift register.
// Reference: https://www.chipverify.com/verilog/verilog-n-bit-shift-register

module shift_reg2_FIFO
#(parameter N=11, B=8)
(
  input  logic clk,
  input  logic rstn,
  input  logic en,
  input  logic [B-1:0] din,
  output logic [B-1:0] dout [N-1:0]
);

  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn)
      dout <= '{default: B'0};
    else if (en) begin
      dout[0] <= din;
      dout[N-1:1] <= dout[N-2:0];
    end
  end

endmodule