# Design
set ::env(DESIGN_NAME) "decred_controller"

set script_dir [file dirname [file normalize [info script]]]

set ::env(VERILOG_FILES) "\
   $script_dir/../../verilog/rtl/defines.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/decred_defines.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/addressalyzer.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/clock_div_simple.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/decred_controller.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/register_bank.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/spi_passthrough.v \
   $script_dir/../../verilog/rtl/decred_top/rtl/src/spi_des.v"

set ::env(BASE_SDC_FILE) "$script_dir/decred_controller.sdc"
set ::env(CLOCK_PORT) "M1_CLK_IN PLL_INPUT S1_CLK_IN"
set ::env(CLOCK_NET) "m1_clk_local addressalyzerBlock.SPI_CLK"

set ::env(DESIGN_IS_CORE) 0

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 205 205"
set ::env(GLB_RT_OBS) "met5 0 0 0.205 0.205"

set ::env(CLOCK_PERIOD) "15.000"
#default is 50
#set ::env(FP_CORE_UTIL) "50"
set ::env(PL_TARGET_DENSITY) 0.65
set ::env(SYNTH_STRATEGY) "1"
set ::env(CELL_PAD) "4"
#default is 0.15
set ::env(GLB_RT_ADJUSTMENT) "0.15"
#default is 3
set ::env(DIODE_INSERTION_STRATEGY) "3"
set ::env(GLB_RT_MAX_DIODE_INS_ITERS) "10"

set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]

# default is 5
set ::env(SYNTH_MAX_FANOUT) "5"
#default is 1
set ::env(FP_ASPECT_RATIO) "1"
#default is 0
set ::env(FP_PDN_CORE_RING) 0
#default is 6
set ::env(GLB_RT_MAXLAYER) 5
#default is 0
set ::env(PL_BASIC_PLACEMENT) 0

set ::env(ROUTING_CORES) 4
