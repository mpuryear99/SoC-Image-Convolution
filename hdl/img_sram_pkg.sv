
package img_sram_pkg;

  // Control signals associated with img_sram
  typedef struct {
    logic write_en;
    logic sense_en;
    logic [7:0] din;
    logic [7:0] row;
    logic [7:0] col;
  } img_sram_ctrl_t;

endpackage : img_sram_pkg