# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Configuration [ipgui::add_page $IPINST -name "Configuration"]
  ipgui::add_param $IPINST -name "ClockFrequencyHz_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "I2cFrequencyHz_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "BusBusyTimeoutUs_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "UpdatePeriodMs_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "InternalTriState_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "NumOfReg_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Configuration}


}

proc update_PARAM_VALUE.BusBusyTimeoutUs_g { PARAM_VALUE.BusBusyTimeoutUs_g } {
	# Procedure called to update BusBusyTimeoutUs_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BusBusyTimeoutUs_g { PARAM_VALUE.BusBusyTimeoutUs_g } {
	# Procedure called to validate BusBusyTimeoutUs_g
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

proc update_PARAM_VALUE.ClockFrequencyHz_g { PARAM_VALUE.ClockFrequencyHz_g } {
	# Procedure called to update ClockFrequencyHz_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ClockFrequencyHz_g { PARAM_VALUE.ClockFrequencyHz_g } {
	# Procedure called to validate ClockFrequencyHz_g
	return true
}

proc update_PARAM_VALUE.I2cFrequencyHz_g { PARAM_VALUE.I2cFrequencyHz_g } {
	# Procedure called to update I2cFrequencyHz_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.I2cFrequencyHz_g { PARAM_VALUE.I2cFrequencyHz_g } {
	# Procedure called to validate I2cFrequencyHz_g
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

proc update_PARAM_VALUE.UpdatePeriodMs_g { PARAM_VALUE.UpdatePeriodMs_g } {
	# Procedure called to update UpdatePeriodMs_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.UpdatePeriodMs_g { PARAM_VALUE.UpdatePeriodMs_g } {
	# Procedure called to validate UpdatePeriodMs_g
	return true
}


proc update_MODELPARAM_VALUE.ClockFrequencyHz_g { MODELPARAM_VALUE.ClockFrequencyHz_g PARAM_VALUE.ClockFrequencyHz_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ClockFrequencyHz_g}] ${MODELPARAM_VALUE.ClockFrequencyHz_g}
}

proc update_MODELPARAM_VALUE.I2cFrequencyHz_g { MODELPARAM_VALUE.I2cFrequencyHz_g PARAM_VALUE.I2cFrequencyHz_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.I2cFrequencyHz_g}] ${MODELPARAM_VALUE.I2cFrequencyHz_g}
}

proc update_MODELPARAM_VALUE.BusBusyTimeoutUs_g { MODELPARAM_VALUE.BusBusyTimeoutUs_g PARAM_VALUE.BusBusyTimeoutUs_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BusBusyTimeoutUs_g}] ${MODELPARAM_VALUE.BusBusyTimeoutUs_g}
}

proc update_MODELPARAM_VALUE.UpdatePeriodMs_g { MODELPARAM_VALUE.UpdatePeriodMs_g PARAM_VALUE.UpdatePeriodMs_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.UpdatePeriodMs_g}] ${MODELPARAM_VALUE.UpdatePeriodMs_g}
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

