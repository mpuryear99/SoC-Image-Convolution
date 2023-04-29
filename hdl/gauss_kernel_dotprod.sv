// Calculates the internal product (dot product) of an array
// and a gaussian kernel of given standard deviation (sigma).
// Sigma of zero returns the center value of the array.

module gauss_kernel_dotprod
(
  input  logic [2:0] sigma,
  input  logic [7:0] din [10:0],
  output logic [7:0] dout
);

  logic [ 7:0] kernel [10:0];
  logic [16:0] dp_sum;

  // kernel selector (all values are fractional)
  always_comb begin
    unique0 case (sigma)
      3'b001:  kernel <= '{8'h00, 8'h00, 8'h00, 8'h00, 8'h1b, 8'hca, 8'h1b, 8'h00, 8'h00, 8'h00, 8'h00};
      3'b010:  kernel <= '{8'h00, 8'h00, 8'h01, 8'h0e, 8'h3e, 8'h66, 8'h3e, 8'h0e, 8'h01, 8'h00, 8'h00};
      3'b011:  kernel <= '{8'h00, 8'h02, 8'h09, 8'h1c, 8'h37, 8'h44, 8'h37, 8'h1c, 8'h09, 8'h02, 8'h00};
      3'b100:  kernel <= '{8'h03, 8'h07, 8'h11, 8'h1f, 8'h2d, 8'h33, 8'h2d, 8'h1f, 8'h11, 8'h07, 8'h03};
      3'b101:  kernel <= '{8'h08, 8'h0c, 8'h14, 8'h1e, 8'h26, 8'h29, 8'h26, 8'h1e, 8'h14, 8'h0c, 8'h08};
      3'b110:  kernel <= '{8'h0d, 8'h10, 8'h16, 8'h1c, 8'h20, 8'h22, 8'h20, 8'h1c, 8'h16, 8'h10, 8'h0d};
      3'b111:  kernel <= '{8'h11, 8'h13, 8'h16, 8'h1a, 8'h1d, 8'h1e, 8'h1d, 8'h1a, 8'h16, 8'h13, 8'h11};
      //   0:  kernel <= dirac delta
    endcase
  end

  always_comb begin
    dp_sum = 0;
    if (sigma == 0)
      dout = din[5];
    else begin
      foreach(din[i])
        dp_sum += kernel[i] * din[i];
      if (dp_sum[16])
        // This should never happen
        dout = 8'hFF;
      else
        dout = dp_sum[15:8];
    end
  end

endmodule