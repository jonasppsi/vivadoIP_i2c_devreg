# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Configuration [ipgui::add_page $IPINST -name "Configuration"]
  ipgui::add_param $IPINST -name "NumOfReg_g" -parent ${Configuration}


}

proc update_PARAM_VALUE.NumOfReg_g { PARAM_VALUE.NumOfReg_g } {
	# Procedure called to update NumOfReg_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NumOfReg_g { PARAM_VALUE.NumOfReg_g } {
	# Procedure called to validate NumOfReg_g
	return true
}


proc update_MODELPARAM_VALUE.NumOfReg_g { MODELPARAM_VALUE.NumOfReg_g PARAM_VALUE.NumOfReg_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NumOfReg_g}] ${MODELPARAM_VALUE.NumOfReg_g}
}

