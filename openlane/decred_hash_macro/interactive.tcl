#!/usr/bin/tclsh
# Copyright 2020 Matt Aamold, James Aamold
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


package require openlane;

proc insert_diode {args} {
	puts_info " Insert diodes..."

	# Custom insertion script
	set ::env(SAVE_DEF) $::env(TMP_DIR)/placement/$::env(DESIGN_NAME).diodes.def
	try_catch python3 $::env(DESIGN_DIR)/scripts/place_diodes.py -l $::env(MERGED_LEF) -id $::env(CURRENT_DEF) -o $::env(SAVE_DEF) |& tee $::env(TERMINAL_OUTPUT) $::env(LOG_DIR)/diodes.log
	set_def $::env(SAVE_DEF)

	# Legalize
	detailed_placement
}



proc run_flow {args} {
	set script_dir [file dirname [file normalize [info script]]]
	set options {
		{-save_path optional}
		{-tag optional}
	}
	set flags {-save}
	parse_key_args "run_flow" args arg_values $options flags_map $flags -no_consume

	prep -design $script_dir -tag decred_hash_macro -overwrite

	run_synthesis
	run_floorplan
	run_placement
	run_cts
	insert_diode
	run_routing

	if { $::env(DIODE_INSERTION_STRATEGY) == 2 } {
		run_antenna_check
		heal_antenna_violators; # modifies the routed DEF
	}

	if { $::env(LVS_INSERT_POWER_PINS) } {
		write_powered_verilog
		set_netlist $::env(lvs_result_file_tag).powered.v
	}

	run_magic

	run_magic_spice_export

	save_views 	-lef_path $::env(magic_result_file_tag).lef \
			-def_path $::env(tritonRoute_result_file_tag).def \
			-gds_path $::env(magic_result_file_tag).gds \
			-mag_path $::env(magic_result_file_tag).mag \
			-mag_path $::env(magic_result_file_tag).lef.mag \
			-spice_path $::env(magic_result_file_tag).spice \
			-verilog_path $::env(CURRENT_NETLIST) \
			-save_path $script_dir/../../ \
			-tag $::env(RUN_TAG)

	# Physical verification

	run_magic_drc

	run_lvs; # requires run_magic_spice_export

	run_antenna_check

	generate_final_summary_report

	puts_success "Flow Completed Without Fatal Errors."
}

run_flow {*}$argv
