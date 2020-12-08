# Skywater 130 Decred Miner

## Table of Contents
* [Introduction](#introduction)
* [Implementation](#implementation)
	* [Hash Unit Input Data](#hash-unit-input-data)
  * [ASIC Chaining Support](#asic-chaining-support)
	* [Register File](#register-file)
  * [Verilog Module Hierarchy](#verilog-module-hierarchy)
* [Building](#building)
  * [Check Out](#check-out)
  * [Build Decred Flow](#build-decred-flow)
  
  

## Introduction

Decred is a blockchain-based cryptocurrency that utilizes a hybrid Proof-of-Work (PoW) and Proof-of-Stake (PoS) mining system. More about Decred can be found at https://docs.decred.org.

The PoW element of Decred uses the BLAKE-256 (14 round) hashing function and is described in more detail at https://docs.decred.org/research/blake-256-hash-function.

The Skywater 130 Decred Miner project implements a BLAKE-256r14 hash unit that is optimized for the Decred blockchain (i.e., not a generic BLAKE-256r14 hash unit). In addition to the hash unit, the core also includes a SPI unit with addressable register space and a device interrupt; all to be used with a separate controller board. The core is implemented on Skywater’s SKY130 process.

Several Decred ASICs have been produced in the past at process nodes much smaller than 130nm (some as small as 16nm). This project’s purpose is not intended to compete with the performance per watt of those commercially available units. Rather, this project was intended as a method to learn about the challenges of ASIC development and provide a stepping stone for open-source ASIC development.

## Implementation

### Hash Unit Input Data

The Decred blockchain provides a 180-byte header that includes common blockchain fields such as previous block hash, merkle root, timestamp, nonce, and height. It also includes Decred-specific fields such as voting information that works with the PoS portion of Decred. The Decred header specification can be found at https://devdocs.decred.org/developer-guides/block-header-specifications.

The Decred PoW process runs variations of the header (plus 16-byte padding) through the BLAKE-256r14 hash function and compares that result to a numerical value (smaller value better). The varying data of the header is the nonce space. A Nonce field exists at the end of the Decred header. While the Nonce field is only 32-bits, the ExtraData field can be used to expand the nonce space. After the full header is initially hashed, only the last chunk of 64 bytes needs to be rehashed for each change in nonce space. This is because the Nonce and ExtraData fields are at the end of the header. The result of hashing the first 128 bytes of the header is referred to as the midstate. The controller board generates the header’s midstate and sends it, along with other static header data and the target difficulty information, to the core via the SPI interface. After the necessary data is sent, the controller board enables hashing. If the hash unit determines that a result suffices that target difficulty, an interrupt is generated from the core to the controller board and the solution nonce is saved. Once the interrupt is handled by the controller board, it reads the solution nonce from the core’s register space.

Midstate – 256 bytes

Static Header Data – 16 bytes

Threshold Mask – 4 bytes

Upper Nonce Start – 4 bytes

Note that Decred’s minimum difficulty of 1.0 relates to a target that has 0 in the most significant 32-bits (i.e., 0x00000000 XXXXXXXX YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY) so the Threshold Mask only populates the second most significant word (i.e., X’s). Based on the expected hash performance, Decred difficulties greater than 2^32 were impractical to support. This allowed for optimizations in the hash unit.

### ASIC Chaining Support

It is common for crypto currency mining machine manufacturers to chain several dozen ASIC chips together in a single unit to maximize hash rate SWaP (size, weight, and power). This project implements support for chaining ASICs to a single controller board.

### Register File

A small number of registers are provided at the register_bank level and accessed via the SPI interface.  Read/write operations can operate on different data (see R/W field).  A register window is used to interface with registers at the hash_macro level.
```
register_bank
0x00  RW  Macro address
0x01   W  Macro write data
0x02  R   Macro interrupt status 
0x02   W  Macro select (bit mapped)
0x03  RW  Control byte
        0 Macro read enable
        2 Clk counter enable
        3 LED output
        4 M1 clk reset
        5 Chain enable
0x04  RW  SPI address [6:0]
0x05  R   ID register
0x05   W  Macro write stobe
0x06  R   Macro ID register
0x07  R   Perf counter [7:0]
0x08  R   Perf counter [15:8]
0x09  R   Perf counter [23:16]
0x0A  R   Perf counter [31:24]
0x80  R   Macro data

hash_macro
0x00 - 0x1F Midstate
0x20 - 0x23 Threshold Mask
0x24 - 0x33 Static Header Data
0x34 - 0x37 Upper nonce start
0x38 - 0x39 Nonce start
0x3A - 0x3B Stride
```
### Verilog Module Hierarchy

```
decred_top.v
   |
    - clock_div.v
   |
    - decred.v
         |
          - addressalyzer.v
         |
          - spi_passthrough.v
         |
          - spi_slave_des.v
         |
          - register_bank.v
               |
                - hash_macro_nonblock.v
```

## Building
Follow the steps at https://github.com/efabless/openlane#quick-start. 
Note that as of the time of this writing, openlane rc5 was the current release branch (i.e., git clone https://github.com/efabless/openlane.git --branch rc5).

After ```make test``` succeeds, proceed to check out step next.

### Check Out
```
cd openlane/designs
git clone https://github.com/SweeperAA/caravel_skywater130_decred_miner.git
cd caravel_skywater130_decred_miner
make uncompress
```

### Build Decred Flow
Building to integrate into the caravel test harness chip is done in two steps.

Step 1: Build the macro independent of the caravel chip.
```
cd caravel_skywater130_decred_miner/openlane
make decred_top
```

Step 2: Integrate macro into caravel user space.
```
make user_project_wrapper
```

