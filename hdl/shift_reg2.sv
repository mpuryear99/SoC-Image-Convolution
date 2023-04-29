// Shift register with up, down, and inward center shift.
// Reference: https://www.chipverify.com/verilog/verilog-n-bit-shift-register

module shift_reg2
#(parameter N=11, B=8)
(
  input  logic clk,
  input  logic rstn,
  input  logic en,
  input  logic center,
  input  logic [B-1:0] din,
  output logic [B-1:0] dout [N-1:0]
);

  localparam N2 = (N+1)/2;  // ceil(N/2)  This adds preference to up shifted center values

  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn)
      dout <= '{default: B'0};
    else if (up_en && down_en) begin
      // shift inward to center from both directions 
      dout[0]   <= din;
      dout[N-1] <= din;
      dout[N2-1:1] <= dout[N2-2:0];
      dout[N-2:N2] <= dout[N-1:N2+1];
    end
    else if (up_en) begin
      // shift toward MSB
      dout[0] <= din;
      dout[N-1:1] <= dout[N-2:0];
    end
    else if (down_en) begin
      // shift toward LSB
      dout[N-1] <= din;
      dout[N-2:0] <= dout[N-1:1];
    end
  end

endmodule