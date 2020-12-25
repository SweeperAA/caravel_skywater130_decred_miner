// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 100 ps

`include "caravel.v"
`include "spiflash.v"

module host_interface_tb;

`include "chip_support_tb.v"

`ifndef FULL_CHIP_SIM
#error
printf("FULL_CHIP_SIM not defined);
`endif

	reg clock;
    	reg RSTB;
	reg power1, power2;
	reg power3, power4;

    	wire gpio;
    	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;

	assign mprj_io_0 = mprj_io[7:0];

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter MAIN_CLK_HALF_PERIOD = 10;
  parameter MAIN_CLK_PERIOD = 2 * MAIN_CLK_HALF_PERIOD;

  parameter SPI_CLK_QTR_PERIOD = 250;
  parameter SPI_CLK_HALF_PERIOD = 2 * SPI_CLK_QTR_PERIOD;
  parameter SPI_CLK_PERIOD = 2 * SPI_CLK_HALF_PERIOD;

  parameter BUFFER_SIZE = 56;

  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg tb_main_clk = 0;
  reg tb_rst_n = 0;

  reg tb_sclk = 0;
  reg tb_scsn = 1;
  reg tb_mosi = 0;

  reg [7:0] miso_byte = 8'b0;
  wire tb_miso;
  wire tb_irq;

  // chain interconnect
  wire miso_1_0;
  wire miso_2_1;

  wire mosi_0_1;
  wire mosi_1_2;

  wire irq_1_0;
  wire irq_2_1;

  wire id_1_0;
  wire id_2_1;

  wire scsn_0_1;
  wire scsn_1_2;

  wire sclk_0_1;
  wire sclk_1_2;

  wire rst_n_0_1;
  wire rst_n_1_2;

  // globals
  reg [7:0] read_memory[BUFFER_SIZE - 1:0];
  reg [7:0] read_memory_copy[BUFFER_SIZE - 1:0];
  reg [7:0] write_memory[BUFFER_SIZE - 1:0];
  reg [7:0] write_memory_copy[BUFFER_SIZE - 1:0];
  reg [7:0] input_data[BUFFER_SIZE - 1:0];
  reg [7:0] selectedDevAddr = 8'h00;

  reg [7:0] threadCount = 8'h00;
  reg [7:0] macroCount  = 8'h00;
  reg [7:0] chainLength = 8'h00;

  reg [31 : 0] cycle_ctr;
  reg          display_cycle_ctr = 0;
  reg          display_ctrl_and_ctrs = 0;
  reg          display_qround = 0;
  reg          display_state = 0;

  integer file, i;

  assign mprj_io[18:8] = {1'b1, 1'b0, 1'b0, tb_mosi, tb_scsn, 2'b00, 1'b1, tb_main_clk, tb_sclk, tb_rst_n};
  assign scsn_0_1 = mprj_io[19:19];
  assign sclk_0_1 = mprj_io[20:20];
  assign mosi_0_1 = mprj_io[21:21];
  assign rst_n_0_1 = mprj_io[22:22];
  assign tb_miso = mprj_io[25:25];
  assign tb_irq = mprj_io[27:27];

  //----------------------------------------------------------------
  // clk_gen
  //
  // Clock generator processes.
  //----------------------------------------------------------------
  always
    begin : main_clk_gen
      #MAIN_CLK_HALF_PERIOD tb_main_clk = !tb_main_clk;
    end

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

  initial begin

		$dumpfile("host_interface.vcd");
		$dumpvars(0, host_interface_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (25) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end

    cycle_ctr = 0;

    # (MAIN_CLK_PERIOD)
    # 300

    # (0) tb_rst_n = 1'b0;
    # (2* SPI_CLK_PERIOD) tb_rst_n = 1'b1;
    # (SPI_CLK_HALF_PERIOD)

    # 100 chip_init_chain();

    # 100 chip_write_nonce_offsets();

    # 100 disable_asic_hash();

    # 100 enable_asic_hash_clock();

    # 0 read_input_data();

    # 0 write_midstate();
    # 0 write_threshold();
    # 0 write_headerdata();
    # 0 write_extranonce();

    display_cycle_ctr = 1;
    display_ctrl_and_ctrs = 1;
    display_qround = 1;
    display_state = 1;

    # 0 enable_asic_hashing();

    // wait for IRQ
    wait (tb_irq == 1) #1 ;

    display_cycle_ctr = 0;
    display_ctrl_and_ctrs = 0;
    display_qround = 0;
    display_state = 0;

    chip_find_and_select_next_macro();

    read_enonce();

    chip_disable_macro();

    $display($time,"\t: Test complete");

    $finish;
  end

	initial begin
		RSTB <= 1'b0;
		#2000;
		RSTB <= 1'b1;	    // Release reset
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
		#200;
		power3 <= 1'b1;
		#200;
		power4 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;

  //----------------------------------------------------------------
  // Generic memory interface routines
  //----------------------------------------------------------------

  task set_write_memory_16b ;
    input [15:0] value;

    begin

      write_memory[0] = value[7:0];
      write_memory[1] = value[15:8];

    end
  endtask

  task set_write_memory_24b ;
    input [23:0] value;

    begin

      write_memory[0] = value[7:0];
      write_memory[1] = value[15:8];
      write_memory[2] = value[23:16];

    end
  endtask

  task copy_write_buffer ;
    begin : copy_write_buffer_block
      integer i;

      for (i = 0; i < BUFFER_SIZE; i = i + 1) begin

        write_memory_copy[i] = write_memory[i];
      end
    end
  endtask

  //----------------------------------------------------------------
  // High level support functions.
  //----------------------------------------------------------------

  task read_input_data ;
    begin : read_input_data_block

      $readmemh("full_chip_input.dat", input_data);

    end
  endtask

  task copy_input_data ;
    input [7:0] offset;
    input [7:0] length;

    begin : copy_input_data_block

      integer i;
      integer source;

      source = offset;

      for (i = 0; i < length; i = i +1) begin

        write_memory[i] = input_data[source];
        source = source + 1;
      end

    end
  endtask

  task read_enonce ;
    begin : read_enonce_block

      integer i;

      chip_read_hashreg(0, CPLD_ENONCE_LEN);

      $display("Enonce read ");
      for (i = 0; i < CPLD_ENONCE_LEN; i = i + 1) begin
        $display("%x", read_memory_copy[i]);
      end

    end
  endtask

  task disable_asic_hash ;
    begin : disable_asic_hash_block

      reg [7:0] controlByte;

      chip_set_selected_device(BROADCAST_ADDR_VALUE);

      // Turn off LED and clear HASH_EN along while clock is running
      controlByte = CONTROL_LED_MASK_OFF | CONTROL_CLOCK_ON | CONTROL_ID_HIGH;
      chip_write_controlreg(REG_CONTROL, controlByte);

      // Turn off LED and clear HASH_EN along with clock disable
      controlByte = CONTROL_LED_MASK_OFF | CONTROL_CLOCK_OFF | CONTROL_ID_HIGH;
      chip_write_controlreg(REG_CONTROL, controlByte);

    end
  endtask

  task enable_asic_hash_clock ;
    begin : enable_asic_hash_clock_block

      reg [7:0] controlByte;

      chip_set_selected_device(BROADCAST_ADDR_VALUE);

      // Set init status for macros 
      controlByte = CONTROL_LED_MASK_OFF | CONTROL_HASH_MASK_STOP | CONTROL_CLOCK_OFF | CONTROL_ID_HIGH;
      chip_write_controlreg(REG_CONTROL, controlByte);

      controlByte = CONTROL_LED_MASK_OFF | CONTROL_HASH_MASK_STOP | CONTROL_CLOCK_ON | CONTROL_ID_HIGH;
      chip_write_controlreg(REG_CONTROL, controlByte);

    end
  endtask

  task enable_asic_hashing ;
    begin : enable_asic_hashing_block

      reg [7:0] controlByte;

      chip_set_selected_device(BROADCAST_ADDR_VALUE);

      // Turn on LED and set HASH_EN
      controlByte = CONTROL_LED_MASK_ON | CONTROL_HASH_MASK_START | CONTROL_CLOCK_ON | CONTROL_ID_HIGH;
      chip_write_controlreg(REG_CONTROL, controlByte);

    end
  endtask

  task write_midstate ;
    begin : write_midstate_block
      copy_input_data(0, 32); // prepare write from input file offset,length
      chip_write_hashreg(ALL_MACRO_MASK, 8'h00, 32);
    end
  endtask

  task write_threshold ;
    begin : write_threshold_block
      copy_input_data(32, 4); // prepare write from input file offset,length
      chip_write_hashreg(ALL_MACRO_MASK, 8'h20, 4);
    end
  endtask

  task write_headerdata ;
    begin : write_headerdata_block
      copy_input_data(36, 16); // prepare write from input file offset,length
      chip_write_hashreg(ALL_MACRO_MASK, 8'h24, 16);
    end
  endtask

  task write_extranonce ;
    begin : write_extranonce_block
      copy_input_data(52, 4); // prepare write from input file offset,length
      chip_write_hashreg(ALL_MACRO_MASK, 8'h34, 4);
    end
  endtask

  //----------------------------------------------------------------
  // SPI support routines.
  //----------------------------------------------------------------

  task spi_set_chipselect ;
    input value;

    begin

    # 0  tb_scsn = value;
    # SPI_CLK_HALF_PERIOD;

    end
  endtask

  task spi_send_data ;
    input  [7:0] data ;
    output [7:0] returnByte;

    integer i;
    begin 

    for (i = 8; i > 0; i = i - 1) begin
      # 0 clock_data_bit(data[i - 1], returnByte[i - 1]);
    end
    # SPI_CLK_HALF_PERIOD;
  end  
  endtask

  task clock_data_bit ;
    input  data ;
    output bitOut;
    begin 

    # SPI_CLK_QTR_PERIOD tb_mosi = data;  
    # SPI_CLK_QTR_PERIOD tb_sclk = !tb_sclk;  
    # SPI_CLK_QTR_PERIOD tb_sclk = !tb_sclk;  
    bitOut = tb_miso;
    # SPI_CLK_QTR_PERIOD tb_sclk = tb_sclk;  

  end  
  endtask

  //----------------------------------------------------------------
  // ASIC interface routines.
  //----------------------------------------------------------------

  task chip_read_memory ;
    input [15:0] address ;
    input [15:0] len ;

    integer i;
    begin : chip_read_mem_block

    reg [7:0] returnByte;

    spi_set_chipselect(0);

    spi_send_data(8'h80 | selectedDevAddr | address[15:8], returnByte);
    spi_send_data(address[7:0], returnByte);
    spi_send_data(8'hFF, returnByte);

    for (i = 0; i < len; i = i + 1) begin
      spi_send_data(8'hFF, read_memory[i]);
    end
    
    spi_set_chipselect(1);

    end
  endtask

  task chip_write_memory ;
    input [15:0] address ;
    input [15:0] len ;

    integer i;
    begin : chip_write_mem_block

      reg [7:0] returnByte;

      spi_set_chipselect(0);

      spi_send_data(selectedDevAddr | address[15:8], returnByte);
      spi_send_data(address[7:0], returnByte);

      for (i = 0; i < len; i = i + 1) begin
        spi_send_data(write_memory[i], read_memory[i]);
      end
    
      spi_set_chipselect(1);

    end
  endtask

  task chip_write_controlreg ;
    input [7:0] address;
    input [7:0] data;

    begin : task_chip_write_controlreg_block

      write_memory[0] = data;
      chip_write_memory(address, 1);

    end
  endtask

  task chip_read_hashreg ;
    input [7:0] address ;
    input [7:0] len ;

    begin : chip_read_hashreg_block

      reg [7:0] localAddr;
      integer i;

      localAddr = address;

      for (i = 0; i < len; i = i + 1) begin

        chip_write_controlreg(REG_MACRO_ADDR, localAddr);
        chip_read_memory(REG_READ_MACRO, 1);
        read_memory_copy[i] = read_memory[0];

        localAddr = localAddr + 1;

      end
    end

  endtask

  task chip_write_hashreg ;
    input [7:0] macroSelect;
    input [7:0] address ;
    input [7:0] len ;

    begin : chip_write_hashreg_block

      reg [7:0] localAddr;
      integer i;

      localAddr = address;

      copy_write_buffer();

      chip_write_controlreg(REG_MACRO_WREN, 0);

      for (i = 0; i < len; i = i + 1) begin

        chip_write_controlreg(REG_MACRO_ADDR, localAddr);
        chip_write_controlreg(REG_MACRO_DATA, write_memory_copy[i]);
        chip_write_controlreg(REG_MACRO_WREN, macroSelect);
        chip_write_controlreg(REG_MACRO_WREN, 0);

        localAddr = localAddr + 1;

      end
    end

  endtask

  task chip_set_selected_device ;
    input [7:0] value ;
    begin
      selectedDevAddr = value;
    end
  endtask

  task chip_init_chain ;

    begin : chip_init_chain_block

      reg [7:0] addr;
      reg running;

      addr = 0;
      running = 1;
      chainLength = 0;

      while (running) begin

        if (addr != 0) begin

          chip_write_controlreg(REG_CONTROL, CONTROL_ID_HIGH);

        end

        chip_set_selected_device(0);
        addr = addr + 1;

        chip_write_controlreg(REG_SPI_ADDR, addr);
        chip_set_selected_device(addr);

        chip_read_memory(REG_ID, 1);

        if (read_memory[0] == REG_ID_VALUE) begin

          chip_write_controlreg(REG_CONTROL, 0);
          chainLength = chainLength + 1;
        end else begin

          running = 0;
        end

      end

      chip_set_selected_device(1);
      chip_read_memory(REG_MACROINFO, 1);

      threadCount = read_memory[0] & 8'h0F;
      macroCount = ((read_memory[0] >> 4) & 8'h0F);

      chip_set_selected_device(BROADCAST_ADDR_VALUE);

      $display("Detected %d devices with %d macros and %d threads", chainLength, macroCount, threadCount);

    end
  endtask

  task chip_write_nonce_offsets ;
    begin : chip_write_nonce_offsets_block

    reg [7:0] addr;
    reg [23:0] nonceOffset;
    reg [15:0] stride;

    integer i;
    integer j;

    addr = 1;
    nonceOffset = 24'h3feccf; // test mode linked to data input
    stride = chainLength * macroCount * threadCount;
    for (i = 0; i < chainLength; i = i + 1) begin

      chip_set_selected_device(addr);
      addr = addr + 1;

      for (j = 0; j < macroCount; j = j + 1) begin

        set_write_memory_24b(nonceOffset);
        chip_write_hashreg((1 << j), HASH_REG_NONCEOFFSET, 3);

        set_write_memory_16b(stride);
        chip_write_hashreg((1 << j), HASH_REG_STRIDEOFFSET, 2);

        nonceOffset = nonceOffset + threadCount;
      end
    end

    chip_set_selected_device(BROADCAST_ADDR_VALUE);

    end
  endtask

  task chip_find_and_select_next_macro ;
    begin : chip_find_and_select_next_macro_block

      integer i;
      reg [7:0] addr;
      reg [7:0] activeMacro;
      reg [7:0] foundOne;

      addr = 1;
      foundOne = 0;

      for (i = 0; (foundOne == 0) && (i < chainLength); i = i + 1) begin

        chip_set_selected_device(addr);
        chip_read_memory(REG_MACRO_SEL, 1);
        activeMacro = read_memory[0];
        activeMacro = activeMacro & ((activeMacro ^ 8'hFF) + 1);

        if (activeMacro != 0) begin
          foundOne = 1;
          write_memory[0] = activeMacro;
          chip_write_memory(REG_MACRO_SEL, 1);

          $display("Solution found on FPGA: %d Macro: %d", addr, activeMacro);
        end

        addr = addr + 1;
      end
    end
  endtask

  task chip_disable_macro ;
    begin : chip_disable_macro_block

    reg [7:0] macro;

    macro = 0;
    chip_write_memory(REG_MACRO_SEL, 1);
    chip_set_selected_device(BROADCAST_ADDR_VALUE);

    end
  endtask

  //----------------------------------------------------------------
  // Chip chain device(s) under test.
  //----------------------------------------------------------------

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        	.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("host_interface.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
