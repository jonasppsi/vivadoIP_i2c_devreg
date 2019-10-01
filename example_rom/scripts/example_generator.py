# ----------------------------------------------------------
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
# ----------------------------------------------------------
from IicPkg import Device, Register, Component

def Generate():


    # This example implements the following I2C structure
    #
    # -----------+                           +------------+      +-------------+
    #            |                           |            |      |             |
    #  FPGA      +------------+--------------+ mux (0xA0) +------+ devB : LM73 |
    #            |            |              |            |      |             |
    # -----------+     +------+-------+      +------------+      +-------------+
    #                  |              |
    #                  | devA : LM73  |
    #                  |              |
    #                  +--------------+

    c = Component("Example I2C")

    devA = Device("LM73", devAddr=0x48, hasMux=False)                                               #This device is connected directly without a I2C mux
    devA.AddRegister(Register("Temperature", cmdBytes=1, cmd=0x00, dataBytes=2, autoRead=True))     #The temperature value shall always be read
    devA.AddRegister(Register("Config", cmdBytes=1, cmd=0x01, dataBytes=1, autoRead=False))         #The config register is only written (do not update periodically)
    c.AddDevice(devA)

    devB = Device("LM73 behind Mux", devAddr=0x48, hasMux=True, muxAddr=0xA0, muxValue=0x20)        #To access this device, first the value 0x20 has to be written to the mux at address 0xA0
    devB.AddRegister(Register("Temperature", cmdBytes=1, cmd=0x00, dataBytes=2, autoRead=True))     # The temperature value shall always be read
    devB.AddRegister(Register("Config", cmdBytes=1, cmd=0x01, dataBytes=1, autoRead=False))         # The config register is only written (do not update periodically)
    c.AddDevice(devB, idxOffset=0x10)   #Leave some free spaces between devices

    c.UpdateVhdl("../hdl/i2c_devreg_rom.vhd")
    c.UpdateHdr("../inc/example_rom_regs.h")


########################################################################################################################
# CLI
########################################################################################################################
if __name__ == '__main__':
    Generate()


