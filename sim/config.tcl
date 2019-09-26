##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

#Constants
set LibPath "../../.."
namespace import psi::sim::*

#Set library
psi::sim::add_library spi_simple

#suppress messages
psi::sim::compile_suppress 135,1236,1370
psi::sim::run_suppress 8684,3479,3813,8009,3812

# libraries
psi::sim::add_sources "$LibPath/VHDL/psi_common/hdl" {
	psi_common_array_pkg.vhd \
	psi_common_math_pkg.vhd \
	psi_common_logic_pkg.vhd \
	psi_common_bit_cc.vhd \
	psi_common_tdp_ram.vhd  \
	psi_common_i2c_master.vhd \
} -tag lib

# psi_tb_v1_0	
psi::sim::add_sources "$LibPath/VHDL/psi_tb/hdl" {
	psi_tb_txt_util.vhd \
	psi_tb_compare_pkg.vhd \
	psi_tb_activity_pkg.vhd \
	psi_tb_i2c_pkg.vhd \
} -tag lib

# project sources
psi::sim::add_sources "../hdl" {
	i2c_devreg_pkg.vhd \
	i2c_devreg.vhd \
} -tag src

#testbenches
psi::sim::add_sources "../tb" {
	i2c_devreg_tb.vhd \
} -tag tb
	
#TB Runs
psi::sim::create_tb_run "i2c_devreg_tb"
psi::sim::add_tb_run