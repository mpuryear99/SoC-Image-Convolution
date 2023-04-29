
package img_conv_pkg;

  typedef enum bit [3:0] {
    OP_NOP = 0,
    OP_GET_NROWS,
    OP_GET_NCOLS,
    OP_GET_SIGMA,
    OP_SET_NROWS,
    OP_SET_NCOLS,
    OP_SET_SIGMA,
    OP_IMG_RX,
    OP_IMG_TX,
    OP_CONV
  } opcode_t;

endpackage