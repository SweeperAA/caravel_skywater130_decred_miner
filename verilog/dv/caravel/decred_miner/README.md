<!---
# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
-->
# decred_miner test(s)

The directory includes a test for the decred_miner

1) Host Interface Test: 

	* Configures the user space pins as outputs, where required
	* Initializes the decred_controller and executes a pre-determined test case resulting in the expected solution
	* The test runs for approx 45min on slower machines and requires > 5GB disk space

Both iverilog 11.0 (or greater) and the riscv compiler are required to execute these tests.

To build the riscv compiler:

`git clone --recursive https://github.com/riscv/riscv-gnu-toolchain`

`cd riscv-gnu-toolchain/`

`mkdir build`

`cd build/`

`../configure --prefix=/opt/riscv32 --with-arch=rv32imc --with-abi=ilp32`

`sudo make`


To execute test: `make`
