set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_project_wrapper
set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(PDN_CFG) $script_dir/pdn.tcl
set ::env(FP_PDN_CORE_RING) 1
set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2920 3520"

set ::unit 2.4
set ::env(FP_IO_VEXTEND) [expr 2*$::unit]
set ::env(FP_IO_HEXTEND) [expr 2*$::unit]
set ::env(FP_IO_VLENGTH) $::unit
set ::env(FP_IO_HLENGTH) $::unit

set ::env(FP_IO_VTHICKNESS_MULT) 4
set ::env(FP_IO_HTHICKNESS_MULT) 4

set ::env(CLOCK_PORT) "m1_clk_local"
set ::env(CLOCK_PERIOD) "15"

set ::env(GLB_RT_TILES) "16"
set ::env(GLB_RT_MINLAYER) 2
set ::env(GLB_RT_MAXLAYER) 5

set ::env(PL_OPENPHYSYN_OPTIMIZATIONS) 0
set ::env(DIODE_INSERTION_STRATEGY) 0

# Need to fix a FastRoute bug for this to work, but it's good
# for a sense of "isolation"
set ::env(MAGIC_ZEROIZE_ORIGIN) 0
set ::env(MAGIC_WRITE_FULL_LEF) 0

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
        $script_dir/../../verilog/rtl/decred_top/rtl/src/decred_defines.v \
	$script_dir/../../verilog/rtl/user_project_wrapper.v"

set ::env(VERILOG_FILES_BLACKBOX) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/*.v"

set ::env(EXTRA_LEFS) "\
	$script_dir/../../lef/decred_hash_macro.lef \
	$script_dir/../../lef/decred_controller.lef"

set ::env(EXTRA_GDS_FILES) "\
	$script_dir/../../gds/decred_hash_macro.gds \
	$script_dir/../../gds/decred_controller.gds"
