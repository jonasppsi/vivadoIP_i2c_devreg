##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

###############################################################
# Include PSI packaging commands
###############################################################
source ../../../TCL/PsiIpPackage/PsiIpPackage.tcl
namespace import -force psi::ip_package::latest::*

###############################################################
# General Information
###############################################################
set IP_NAME i2c_devreg
set IP_VERSION 1.0
set IP_REVISION "auto"
set IP_LIBRARY PSI
set IP_DESCIRPTION "I2C device register mirroring"

init $IP_NAME $IP_VERSION $IP_REVISION $IP_LIBRARY
set_description $IP_DESCIRPTION
set_logo_relative "../doc/psi_logo_150.gif"
set_datasheet_relative "../doc/$IP_NAME.pdf"

###############################################################
# Add Source Files
###############################################################

#Relative Source Files
add_sources_relative { \
	../hdl/i2c_devreg_pkg.vhd \
	../hdl/i2c_devreg.vhd \
	../hdl/i2c_devreg_vivado_wrp.vhd \
}

#PSI Common
add_lib_relative \
	"../../../VHDL/psi_common/hdl"	\
	{ \
		psi_common_math_pkg.vhd \
		psi_common_array_pkg.vhd \
		psi_common_logic_pkg.vhd \
		psi_common_bit_cc.vhd \
		psi_common_tdp_ram.vhd \
		psi_common_sdp_ram.vhd \
		psi_common_sync_fifo.vhd \
		psi_common_i2c_master.vhd \
		psi_common_pl_stage.vhd \
		psi_common_axi_slave_ipif.vhd \
	}			

###############################################################
# GUI Parameters
###############################################################

#User Parameters
gui_add_page "Configuration"

gui_create_parameter "ClockFrequency_g" {Clock Frequency [Hz]}
gui_add_parameter

gui_create_parameter "I2cFrequency_g" {I2C Clock Frequency [Hz]}
gui_add_parameter

gui_create_parameter "BusBusyTimeout_g" {Bus Busy Timeout [sec]}
gui_add_parameter

gui_create_parameter "UpdatePeriod_g" {Automatic Update Period [sec]}
gui_add_parameter

gui_create_parameter "InternalTriState_g" "Use IP-Core internal tri-state buffers"
gui_parameter_set_widget_checkbox
gui_add_parameter

gui_create_parameter "NumOfReg_g" "Number of I2C registers to support (must match ROM)"
gui_add_parameter

gui_create_parameter "C_S00_AXI_ADDR_WIDTH" "Axi address width in bits"
gui_add_parameter

#Remove reset interface (Vivado messes up polarity...)
remove_autodetected_interface Rst

###############################################################
# Optional Ports
###############################################################

add_port_enablement_condition "I2cScl" "\$InternalTriState_g == true"
add_port_enablement_condition "I2cSda" "\$InternalTriState_g == true"

add_port_enablement_condition "I2cScl_I" "\$InternalTriState_g == false"
add_port_enablement_condition "I2cScl_O" "\$InternalTriState_g == false"
add_port_enablement_condition "I2cScl_T" "\$InternalTriState_g == false"
add_port_enablement_condition "I2cSda_I" "\$InternalTriState_g == false"
add_port_enablement_condition "I2cSda_O" "\$InternalTriState_g == false"
add_port_enablement_condition "I2cSda_T" "\$InternalTriState_g == false"


###############################################################
# Package Core
###############################################################
set TargetDir ".."
#											Edit  Synth	
package_ip $TargetDir 						false true




