##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

###############################################################
# Include PSI packaging commands
###############################################################
set FW_LIB_PATH ../../../../../../../
source $FW_LIB_PATH/TCL/PsiIpPackage/PsiIpPackage.tcl
namespace import -force psi::ip_package::latest::*

###############################################################
# General Information
###############################################################
set IP_NAME i2c_devreg_refdes_rom
set IP_VERSION 1.0
set IP_REVISION "auto"
set IP_LIBRARY PSI
set IP_DESCIRPTION "Example Config ROM for I2C device register mirroring"

init $IP_NAME $IP_VERSION $IP_REVISION $IP_LIBRARY
set_description $IP_DESCIRPTION
set_logo_relative "../doc/psi_logo_150.gif"
set_datasheet_relative "../doc/$IP_NAME.pdf"

###############################################################
# Add Source Files
###############################################################

#Relative Source Files
add_sources_relative { \
	../hdl/i2c_devreg_rom.vhd \
	../hdl/i2c_devreg_pkg.vhd \
}

#PSI Common
add_lib_relative \
	"$FW_LIB_PATH/VHDL/psi_common/hdl"	\
	{ \
		psi_common_array_pkg.vhd \
		psi_common_math_pkg.vhd \
	}	

###############################################################
# GUI Parameters
###############################################################

#User Parameters
gui_add_page "Configuration"

gui_create_parameter "NumOfReg_g" "Number of I2C registers to support (must match i2c_devreg)"
gui_add_parameter

###############################################################
# Interface Clocks
###############################################################
set_interface_clock "I2cRom" "aclk"
set_interface_clock "RomI2c" "aclk"

###############################################################
# Optional Ports
###############################################################

#None

###############################################################
# Package Core
###############################################################
set TargetDir ".."
#											Edit  Synth	
package_ip $TargetDir 						false true




