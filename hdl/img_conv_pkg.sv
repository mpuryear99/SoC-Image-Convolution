
package img_conv_pkg;

  typedef enum bit [3:0] {
    OP_NOP       = 4'b0000,
    OP_GET_NROWS = 4'b0001,
    OP_GET_NCOLS = 4'b0010,
    OP_GET_SIGMA = 4'b0011,
    // NOP gap   = 4'b0100,
    OP_SET_NROWS = 4'b0101,
    OP_SET_NCOLS = 4'b0110,
    OP_SET_SIGMA = 4'b0111,
    OP_IMG_RX    = 4'b1000,
    OP_IMG_TX    = 4'b1001,
    // NOP gap
    OP_CONV      = 4'b1111
  } opcode_t;

endpackage