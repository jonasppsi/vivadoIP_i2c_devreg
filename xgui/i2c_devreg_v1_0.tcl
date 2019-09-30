# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Configuration [ipgui::add_page $IPINST -name "Configuration"]
  ipgui::add_param $IPINST -name "ClockFrequency_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "I2cFrequency_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "BusBusyTimeout_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "UpdatePeriod_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "InternalTriState_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "NumOfReg_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Configuration}


}

proc update_PARAM_VALUE.BusBusyTimeout_g { PARAM_VALUE.BusBusyTimeout_g } {
	# Procedure called to update BusBusyTimeout_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BusBusyTimeout_g { PARAM_VALUE.BusBusyTimeout_g } {
	# Procedure called to validate BusBusyTimeout_g
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to update C_S00_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to validate C_S00_AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.ClockFrequency_g { PARAM_VALUE.ClockFrequency_g } {
	# Procedure called to update ClockFrequency_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ClockFrequency_g { PARAM_VALUE.ClockFrequency_g } {
	# Procedure called to validate ClockFrequency_g
	return true
}

proc update_PARAM_VALUE.I2cFrequency_g { PARAM_VALUE.I2cFrequency_g } {
	# Procedure called to update I2cFrequency_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.I2cFrequency_g { PARAM_VALUE.I2cFrequency_g } {
	# Procedure called to validate I2cFrequency_g
	return true
}

proc update_PARAM_VALUE.InternalTriState_g { PARAM_VALUE.InternalTriState_g } {
	# Procedure called to update InternalTriState_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.InternalTriState_g { PARAM_VALUE.InternalTriState_g } {
	# Procedure called to validate InternalTriState_g
	return true
}

proc update_PARAM_VALUE.NumOfReg_g { PARAM_VALUE.NumOfReg_g } {
	# Procedure called to update NumOfReg_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NumOfReg_g { PARAM_VALUE.NumOfReg_g } {
	# Procedure called to validate NumOfReg_g
	return true
}

proc update_PARAM_VALUE.UpdatePeriod_g { PARAM_VALUE.UpdatePeriod_g } {
	# Procedure called to update UpdatePeriod_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.UpdatePeriod_g { PARAM_VALUE.UpdatePeriod_g } {
	# Procedure called to validate UpdatePeriod_g
	return true
}


proc update_MODELPARAM_VALUE.ClockFrequency_g { MODELPARAM_VALUE.ClockFrequency_g PARAM_VALUE.ClockFrequency_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ClockFrequency_g}] ${MODELPARAM_VALUE.ClockFrequency_g}
}

proc update_MODELPARAM_VALUE.I2cFrequency_g { MODELPARAM_VALUE.I2cFrequency_g PARAM_VALUE.I2cFrequency_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.I2cFrequency_g}] ${MODELPARAM_VALUE.I2cFrequency_g}
}

proc update_MODELPARAM_VALUE.BusBusyTimeout_g { MODELPARAM_VALUE.BusBusyTimeout_g PARAM_VALUE.BusBusyTimeout_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BusBusyTimeout_g}] ${MODELPARAM_VALUE.BusBusyTimeout_g}
}

proc update_MODELPARAM_VALUE.UpdatePeriod_g { MODELPARAM_VALUE.UpdatePeriod_g PARAM_VALUE.UpdatePeriod_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.UpdatePeriod_g}] ${MODELPARAM_VALUE.UpdatePeriod_g}
}

proc update_MODELPARAM_VALUE.InternalTriState_g { MODELPARAM_VALUE.InternalTriState_g PARAM_VALUE.InternalTriState_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.InternalTriState_g}] ${MODELPARAM_VALUE.InternalTriState_g}
}

proc update_MODELPARAM_VALUE.NumOfReg_g { MODELPARAM_VALUE.NumOfReg_g PARAM_VALUE.NumOfReg_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NumOfReg_g}] ${MODELPARAM_VALUE.NumOfReg_g}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

