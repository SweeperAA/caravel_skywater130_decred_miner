# Skywater 130 Decred Miner	<!---

# SPDX-FileCopyrightText: 2020 Efabless Corporation
## Table of Contents	#
* [Introduction](#introduction)	# Licensed under the Apache License, Version 2.0 (the "License");
* [Implementation](#implementation)	# you may not use this file except in compliance with the License.
	* [Hash Unit Input Data](#hash-unit-input-data)	# You may obtain a copy of the License at
  * [ASIC Chaining Support](#asic-chaining-support)	#
	* [Register File](#register-file)	#      http://www.apache.org/licenses/LICENSE-2.0
  * [Verilog Module Hierarchy](#verilog-module-hierarchy)	#
* [Building](#building)	# Unless required by applicable law or agreed to in writing, software
  * [Check Out](#check-out)	# distributed under the License is distributed on an "AS IS" BASIS,
  * [Build Decred Flow](#build-decred-flow)	# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

# See the License for the specific language governing permissions and

# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
-->
# CIIC Harness  

A template SoC for Google SKY130 free shuttles. It is still WIP. The current SoC architecture is given below.

<p align="center">
<img src="/doc/ciic_harness.png" width="75%" height="75%"> 
</p>


## Getting Started:

* For information on tooling and versioning, please refer to [this][1].

Start by cloning the repo and uncompressing the files.
```bash
git clone https://github.com/efabless/caravel.git
cd caravel
make uncompress
```


## Introduction	Then you need to install the open_pdks prerequisite:
 - [Magic VLSI Layout Tool](http://opencircuitdesign.com/magic/index.html) is needed to run open_pdks -- version >= 8.3.60*


Decred is a blockchain-based cryptocurrency that utilizes a hybrid Proof-of-Work (PoW) and Proof-of-Stake (PoS) mining system. More about Decred can be found at https://docs.decred.org.	 > \* Note: You can avoid the need for the magic prerequisite by using the openlane docker to do the installation step in open_pdks. This could be done by cloning [openlane](https://github.com/efabless/openlane/tree/master) and following the instructions given there to use the Makefile.
The PoW element of Decred uses the BLAKE-256 (14 round) hashing function and is described in more detail at https://docs.decred.org/research/blake-256-hash-function.	Install the required version of the PDK by running the following commands:


The Skywater 130 Decred Miner project implements a BLAKE-256r14 hash unit that is optimized for the Decred blockchain (i.e., not a generic BLAKE-256r14 hash unit). In addition to the hash unit, the core also includes a SPI unit with addressable register space and a device interrupt; all to be used with a separate controller board. The core is implemented on Skywater’s SKY130 process.	```bash
export PDK_ROOT=<The place where you want to install the pdk>
make pdk
```


Several Decred ASICs have been produced in the past at process nodes much smaller than 130nm (some as small as 16nm). This project’s purpose is not intended to compete with the performance per watt of those commercially available units. Rather, this project was intended as a method to learn about the challenges of ASIC development and provide a stepping stone for open-source ASIC development.	Then, you can learn more about the caravel chip by watching these video:
- Caravel User Project Features -- https://youtu.be/zJhnmilXGPo
- Aboard Caravel -- How to put your design on Caravel? -- https://youtu.be/9QV8SDelURk
- Things to Clarify About Caravel -- What versions to use with Caravel? -- https://youtu.be/-LZ522mxXMw
    - You could only use openlane:rc6
    - Make sure you have the commit hashes provided here inside the [Makefile](./Makefile)
## Aboard Caravel:


## Implementation	Your area is the full user_project_wrapper, so feel free to add your project there or create a differnt macro and harden it seperately then insert it into the user_project_wrapper. For example, if your design is analog or you're using a different tool other than OpenLANE.


### Hash Unit Input Data	If you will use OpenLANE to harden your design, go through the instructions in this [README.md][0].


The Decred blockchain provides a 180-byte header that includes common blockchain fields such as previous block hash, merkle root, timestamp, nonce, and height. It also includes Decred-specific fields such as voting information that works with the PoS portion of Decred. The Decred header specification can be found at https://devdocs.decred.org/developer-guides/block-header-specifications.	You must copy your synthesized gate-level-netlist for `user_project_wrapper` to `verilog/gl/` and overwrite `user_project_wrapper.v`. Otherwise, you can point to it in [info.yaml](info.yaml).


The Decred PoW process runs variations of the header (plus 16-byte padding) through the BLAKE-256r14 hash function and compares that result to a numerical value (smaller value better). The varying data of the header is the nonce space. A Nonce field exists at the end of the Decred header. While the Nonce field is only 32-bits, the ExtraData field can be used to expand the nonce space. After the full header is initially hashed, only the last chunk of 64 bytes needs to be rehashed for each change in nonce space. This is because the Nonce and ExtraData fields are at the end of the header. The result of hashing the first 128 bytes of the header is referred to as the midstate. The controller board generates the header’s midstate and sends it, along with other static header data and the target difficulty information, to the core via the SPI interface. After the necessary data is sent, the controller board enables hashing. If the hash unit determines that a result suffices that target difficulty, an interrupt is generated from the core to the controller board and the solution nonce is saved. Once the interrupt is handled by the controller board, it reads the solution nonce from the core’s register space.	> Note: If you're using openlane to harden your design, this should happen automatically.
Midstate – 256 bytes	Then, you will need to put your design aboard the Caravel chip. Make sure you have the following:


Static Header Data – 16 bytes	- [Magic VLSI Layout Tool](http://opencircuitdesign.com/magic/index.html) installed on your machine. We may provide a Dockerized version later.\*
- You have your user_project_wrapper.gds under `./gds/` in the Caravel directory.


Threshold Mask – 4 bytes	 > \* **Note:** You can avoid the need for the magic prerequisite by using the openlane docker to run the make step. This [section](#running-make-using-openlane-magic) shows how.
Upper Nonce Start – 4 bytes	Run the following command:


Note that Decred’s minimum difficulty of 1.0 relates to a target that has 0 in the most significant 32-bits (i.e., 0x00000000 XXXXXXXX YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY) so the Threshold Mask only populates the second most significant word (i.e., X’s). Based on the expected hash performance, Decred difficulties greater than 2^32 were impractical to support. This allowed for optimizations in the hash unit.	```bash
export PDK_ROOT=<The place where the installed pdk resides. The same PDK_ROOT used in the pdk installation step>
make
```


### ASIC Chaining Support	This should merge the GDSes using magic and you'll end up with your version of `./gds/caravel.gds`. You should expect ~90 magic DRC violations with the current "development" state of caravel.


It is common for crypto currency mining machine manufacturers to chain several dozen ASIC chips together in a single unit to maximize hash rate SWaP (size, weight, and power). This project implements support for chaining ASICs to a single controller board.	## Running Make using OpenLANE Magic


### Register File	To use the magic installed inside Openlane to complete the final GDS streaming out step, export the following:


A small number of registers are provided at the register_bank level and accessed via the SPI interface.  Read/write operations can operate on different data (see R/W field).  A register window is used to interface with registers at the hash_macro level.	```bash
```	export PDK_ROOT=<The location where the pdk is installed>
register_bank	export OPENLANE_ROOT=<the absolute path to the openlane directory cloned or to be cloned>
0x00  RW  Macro address	export IMAGE_NAME=<the openlane image name installed on your machine. Preferably openlane:rc6>
0x01   W  Macro write data	export CARAVEL_PATH=$(pwd)
0x02  R   Macro interrupt status 	
0x02   W  Macro select (bit mapped)	
0x03  RW  Control byte	
        0 Macro read enable strobe	
	1 <unused>	
        2 Clk counter enable	
        3 LED output GPIO	
        4 M1 clk reset	
        5 Chain enable GPIO	
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
```	```
### Verilog Module Hierarchy	


Then, mount the docker:

```bash
docker run -it -v $CARAVEL_PATH:$CARAVEL_PATH -v $OPENLANE_ROOT:/openLANE_flow -v $PDK_ROOT:$PDK_ROOT -e CARAVEL_PATH=$CARAVEL_PATH -e PDK_ROOT=$PDK_ROOT -u $(id -u $USER):$(id -g $USER) $IMAGE_NAME
```	```
decred_top.v	
   |	Finally, once inside the docker run the following commands:
    - clock_div.v	```bash
   |	cd $CARAVEL_PATH
    - decred.v	make
         |	exit
          - addressalyzer.v	
         |	
          - spi_*.v	
         |	
          - register_bank.v	
               |	
                - hash_macro_nonblock.v	
```	```


## Building	This should merge the GDSes using magic and you'll end up with your version of `./gds/caravel.gds`. You should expect ~90 magic DRC violations with the current "development" state of caravel.
Follow the steps at https://github.com/efabless/openlane#quick-start. 	
Note that as of the time of this writing, openlane mpw-one-a was the current release branch for the shuttle (i.e., git clone https://github.com/efabless/openlane.git --branch mpw-one-a).	


After ```make test``` succeeds, proceed to check out step next.	


### Check Out	## IMPORTANT:
```	
cd openlane/designs	
git clone https://github.com/SweeperAA/caravel_skywater130_decred_miner.git	
cd caravel_skywater130_decred_miner	
make uncompress	
cd openlane	
```	


### Build Decred Flow	Please make sure to run `make compress` before commiting anything to your repository. Avoid having 2 versions of the gds/user_project_wrapper.gds or gds/caravel.gds one compressed and the other not compressed.
Building to integrate into the caravel test harness chip is done in several steps.	


Step 1: Build the hashing unit macro.	## Required Directory Structure
```	
make decred_hash_macro	
```	


Step 2: Build the controller macro.	- ./gds/ : includes all the gds files used or produced from the project.
```	- ./def/ : includes all the def files used or produced from the project.
make decred_controller	- ./lef/ : includes all the lef files used or produced from the project.
```	- ./mag/ : includes all the mag files used or produced from the project.
- ./maglef/ : includes all the maglef files used or produced from the project.
- ./spi/lvs/ : includes all the maglef files used or produced from the project.
- ./verilog/dv/ : includes all the simulation test benches and how to run them. 
- ./verilog/gl/ : includes all the synthesized/elaborated netlists. 
- ./verilog/rtl/ : includes all the Verilog RTLs and source files.
- ./openlane/`<macro>`/ : includes all configuration files used to run openlane on your project.
- info.yaml: includes all the info required in [this example](info.yaml). Please make sure that you are pointing to an elaborated caravel netlist as well as a synthesized gate-level-netlist for the user_project_wrapper


Step 3: Integrate macros inside decred_top design.	## Managment SoC
```	The managment SoC runs firmware that can be used to:
make decred_top	- Configure User Project I/O pads
```	- Observe and control User Project signals (through on-chip logic analyzer probes)
- Control the User Project power supply


Step 4: Integrate user_project_wrapper into caravel SOC.	The memory map of the management SoC can be found [here](verilog/rtl/README)
```	
cd ..	## User Project Area
make ship	This is the user space. It has limited silicon area (TBD, about 3.1mm x 3.8mm) as well as a fixed number of I/O pads (37) and power pads (10).  See [the Caravel  premliminary datasheet](doc/caravel_datasheet.pdf) for details.
```
