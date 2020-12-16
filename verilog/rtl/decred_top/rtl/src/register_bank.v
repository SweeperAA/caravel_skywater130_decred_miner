`timescale 1ns / 1ps
`include "decred_defines.v"

module regBank #(
  parameter DATA_WIDTH=8,
  parameter ADDR_WIDTH=8
)(
  input  wire                  SPI_CLK,
  input  wire                  RST_S1,
  input  wire                  M1_CLK,
  input  wire                  RST_M1,
  input  wire [ADDR_WIDTH-1:0] address,
  input  wire [DATA_WIDTH-1:0] data_in,
  input  wire                  read_strobe,
  input  wire                  write_strobe,
  output reg  [DATA_WIDTH-1:0] data_out,

  output wire                  hash_clock_reset,
  output wire                  LED_out,
  output wire [6:0]            spi_addr,
  output wire                  ID_out,
  output wire                  interrupt_out,

  output wire                            HASH_EN,
  output wire [`NUMBER_OF_MACROS - 1: 0] MACRO_WR_SELECT,
  output wire [7: 0]                     DATA_TO_HASH,
  output wire [`NUMBER_OF_MACROS - 1: 0] MACRO_RD_SELECT,
  output wire [5: 0]                     HASH_ADDR,
  input wire  [3 :0]                     THREAD_COUNT,
  input wire  [`NUMBER_OF_MACROS - 1: 0] DATA_AVAILABLE,
  input wire  [7: 0]                     DATA_FROM_HASH
  );

  localparam REGISTERS = 6;

  // //////////////////////////////////////////////////////
  // reg array

  reg  [DATA_WIDTH-1:0] registers [REGISTERS-1:0];

  reg  [7: 0] macro_data_read_rs[1:0];

  reg [31:0] perf_counter;
  always @(posedge M1_CLK)
    if (RST_M1)
      perf_counter <= 0;    
    else if (registers[3][2] == 1'b1) 
      perf_counter <= perf_counter + 1'b1;

  always @(posedge SPI_CLK) begin : REG_WRITE_BLOCK
    integer i;
    if(RST_S1) begin 
      for (i = 0; i < REGISTERS; i = i + 1) begin
        registers[i] <= 0;
      end
    end
    else begin
      if (write_strobe) begin
        registers[address] <= data_in;
      end
    end
  end

  always @(posedge SPI_CLK) begin
    if (read_strobe) begin
      if (address[7:0] == 8'h02) begin
      // interrupt active register
      data_out <= macro_rs[1];
    end else
    if (address[7:0] == 8'h05) begin
      // ID register
      data_out <= 8'h11;
    end else
    if (address[7:0] == 8'h06) begin
      // MACRO_INFO register
      data_out <= ((`NUMBER_OF_MACROS << 4) | (THREAD_COUNT));
    end else
      if (address[7:0] == 8'h07) begin
        data_out <= perf_counter[7:0];
    end else
      if (address[7:0] == 8'h08) begin
        data_out <= perf_counter[15:8];
    end else
      if (address[7:0] == 8'h09) begin
        data_out <= perf_counter[23:16];
    end else
      if (address[7:0] == 8'h0A) begin
        data_out <= perf_counter[31:24];
    end else
      if (address[7] == 0) begin
        data_out <= registers[address[6:0]];
      end
      else begin
        data_out <= macro_data_read_rs[1];
      end
    end
  end

  //  WRITE REGS
  // MACRO_ADDR  =  0     : 0x00
  // MACRO_DATA  =  1     : 0x01 (write only)
  // MACRO_SELECT=  2     : 0x02 (int status on readback)
  // CONTROL     =  3     : 0x03
  //   CONTROL.0 = HASHCTRL
  //   CONTROL.1 = <available>
  //   CONTROL.2 = PERF_COUNTER run
  //   CONTROL.3 = LED output
  //   CONTROL.4 = hash_clock_reset
  //   CONTROL.5 = ID_out
  // SPI_ADDR    =  4     : 0x04
  //   SPI_ADDR.x= Address on SPI bus (6:0)
  // ID REG      =  5     : 0x05 (read-only)
  // MACRO_WR_EN =  5     : macro write enable
  // MACRO_INFO  =  6     : 0x06 macro count (read-only)
  // PERF_CTR    = 10-7   : 0x0A - 0x07 (read-only)

  assign spi_addr = registers[4][6:0];

  assign LED_out = registers[3][3];
  assign ID_out = registers[3][5];

  assign hash_clock_reset = registers[3][4];

  // //////////////////////////////////////////////////////
  // resync - signals to hash_macro 

  reg [1:0] hash_en_rs;

  always @(posedge M1_CLK) begin
    if (RST_M1) begin
      hash_en_rs <= 0;
    end
    else begin
      hash_en_rs <= {hash_en_rs[0], registers[3][0]};
    end
  end
  assign HASH_EN = hash_en_rs[1];

  reg		[`NUMBER_OF_MACROS - 1: 0]	wr_select_rs[1:0];
  always @(posedge M1_CLK) begin
    if (RST_M1) begin
      wr_select_rs[1] <= 0;
      wr_select_rs[0] <= 0;
    end
    else begin
      wr_select_rs[1] <= wr_select_rs[0];
      wr_select_rs[0] <= registers[5][`NUMBER_OF_MACROS - 1: 0];
    end
  end
  assign MACRO_WR_SELECT = wr_select_rs[1];

  reg		[7: 0]	macro_data_write_rs[1:0];
  always @(posedge M1_CLK) begin
    if (RST_M1) begin
      macro_data_write_rs[1] <= 0;
      macro_data_write_rs[0] <= 0;
    end
    else begin
      macro_data_write_rs[1] <= macro_data_write_rs[0];
      macro_data_write_rs[0] <= registers[1];
    end
  end
  assign DATA_TO_HASH = macro_data_write_rs[1];

  reg		[`NUMBER_OF_MACROS - 1: 0]	rd_select_rs[1:0];
  always @(posedge M1_CLK) begin
    if (RST_M1) begin
      rd_select_rs[1] <= 0;
      rd_select_rs[0] <= 0;
    end
    else begin
      rd_select_rs[1] <= rd_select_rs[0];
      rd_select_rs[0] <= registers[2][`NUMBER_OF_MACROS - 1: 0];
    end
  end
  assign MACRO_RD_SELECT = rd_select_rs[1];

  reg		[5: 0]	macro_addr_rs[1:0];
  always @(posedge M1_CLK) begin
    if (RST_M1) begin
      macro_addr_rs[1] <= 0;
      macro_addr_rs[0] <= 0;
    end
    else begin
      macro_addr_rs[1] <= macro_addr_rs[0];
      macro_addr_rs[0] <= registers[0][5:0];
    end
  end
  assign HASH_ADDR = macro_addr_rs[1];

  // //////////////////////////////////////////////////////
  // resync - signals from hash_macro 

  wire	[`NUMBER_OF_MACROS - 1: 0]	macro_interrupts;
  reg		[`NUMBER_OF_MACROS - 1: 0]	macro_rs[1:0];

  always @(posedge SPI_CLK) begin
    if (RST_S1) begin
      macro_rs[1] <= 0;
      macro_rs[0] <= 0;
    end
    else begin
      macro_rs[1] <= macro_rs[0];
      macro_rs[0] <= macro_interrupts;
    end
  end
  assign macro_interrupts = DATA_AVAILABLE;

  assign interrupt_out = |macro_rs[1];

  wire [7: 0] macro_data_readback;

  always @(posedge SPI_CLK) begin
    if (RST_S1) begin
      macro_data_read_rs[1] <= 0;
      macro_data_read_rs[0] <= 0;
    end
    else begin
      macro_data_read_rs[1] <= macro_data_read_rs[0];
      macro_data_read_rs[0] <= macro_data_readback;
    end
  end
  assign macro_data_readback = DATA_FROM_HASH;
endmodule // regBank
