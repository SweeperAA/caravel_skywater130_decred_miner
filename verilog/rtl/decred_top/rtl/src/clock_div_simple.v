`timescale 1ns / 1ps

module clock_div_simple (
  input  wire  iCLK,
  input  wire  RST,

  output reg   clk_out
  );

  // this is really x2: period. CLOCK_DIVISOR = 2 means divide by 4
  localparam CLOCK_DIVISOR = 4; // match the next size with divisor = LOG2(divisor)
  reg [3:0] counter;

  // assume reset is resync'd to iCLK
  // build reset pulse bank
  reg [2:0] reset_pls;
  always @(posedge iCLK)
    reset_pls = {reset_pls[1:0], RST};

  wire reset_pls_qual;
  assign reset_pls_qual = reset_pls[2] & !reset_pls[1] & !reset_pls[0];

  always @(posedge iCLK)
    if (reset_pls_qual)
      counter <= 0;
    else if (counter == CLOCK_DIVISOR - 1) 
      counter <= 0;
    else
      counter <= counter + 1;

  always @(posedge iCLK)
    if (reset_pls_qual)
      clk_out <= 0;
    else if (counter == CLOCK_DIVISOR - 1) 
      clk_out <= ~clk_out;
    else
      clk_out <= clk_out;

endmodule // clock_div
