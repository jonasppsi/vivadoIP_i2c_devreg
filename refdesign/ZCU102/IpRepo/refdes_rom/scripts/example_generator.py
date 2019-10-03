# ----------------------------------------------------------
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
# ----------------------------------------------------------
from IicPkg import Device, Register, Component

def Generate():

    c = Component("ZCU102_I2C1")


    #SI5341 device
    si5341 = Device("SI5341", devAddr=0x36, hasMux=True, muxAddr=0x74, muxValue=(1 << 1))
    si5341.AddRegister(Register("SetPage0", cmdBytes=2, cmd=0x0100, dataBytes=0, autoWrite=True))                            #Switch to Page 0 required for reading revision
    si5341.AddRegister(Register("PartNumber", cmdBytes=1, cmd=0x02, dataBytes=2, autoRead=True, dataLsByteFirst=True))       #Read only register (Two bytes, reverse order)
    si5341.AddRegister(Register("LosIn_Mask", cmdBytes=1, cmd=0x18, dataBytes=1, autoRead=True))                             #R/W register
    c.AddDevice(si5341)

    c.UpdateVhdl("../hdl/i2c_devreg_rom.vhd")
    c.UpdateHdr("../inc/example_rom_regs.h")


########################################################################################################################
# CLI
########################################################################################################################
if __name__ == '__main__':
    Generate()


