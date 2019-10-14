# ----------------------------------------------------------
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
# ----------------------------------------------------------
import re
from typing import Iterable, Tuple
from enum import Enum


__all__ = ["Device", "Register", "Component"]

def BoolToStdl(val : bool) -> str:
    if val:
        return "'1'"
    else:
        return "'0'"

class Register:
    """
    This class encapsulates the information about an I2C device register
    """

    def __init__(self, name : str, cmdBytes : int = 0, cmd : int = 0, dataBytes : int = 0,
                 autoRead : bool = False, autoWrite : bool = False, dataLsByteFirst : bool = False, comment : str = None):
        """
        Constructor

        :param name: Name of the register (used for constant name definition)
        :param cmdBytes: Number of command bytes (0-4)
        :param cmd: Command (only the lower bits may be used, depending on cmdBytes)
        :param dataBytes: Number of data bytes (0-4)
        :param autoRead: If true, the register is read during update cycles
        :param autoWrite: If true, the register is writting during udpdate cycles
        """
        self.name = name
        self.cmdBytes = cmdBytes
        self.cmd = cmd
        self.dataBytes = dataBytes
        self.autoRead = autoRead
        self.autoWrite = autoWrite
        self.dataLsByteFirst = dataLsByteFirst
        self.comment = comment
        if autoWrite and autoRead:
            raise Exception("A register can only be autoRead or autoWrite, not both!")

class Device:

    """
    This class encapsulates the information about an I2C device
    """

    def __init__(self, name : str, devAddr : int, hasMux : bool = False, muxAddr : int = 0, muxValue : int = 0):
        """
        Constructor

        :param name: Device name (used for constant name definition)
        :param devAddr: Device I2C address
        :param hasMux: True if an I2C mux must be written before accessing the device
        :param muxAddr: I2C address of the mux (only required if hasMux=True)
        :param muxValue: Value to write to the mux (only required if hasMux=True)
        """
        self.devAddr = devAddr
        self.name = name
        self.hasMux = hasMux
        self.muxAddr = muxAddr
        self.muxValue = muxValue
        self.registers = []

    def AddRegister(self, reg : Register):
        """
        Add a register to the device
        :param reg: Register to add
        """
        self.registers.append(reg)
        return self

    def AddMultiRegisters(self, regs : Iterable[Register]):
        """
        Add multiple registers to the device
        :param regs: Registers to add (as iterable)
        """
        for reg in regs:
            self.AddRegister(reg)
        return self

    def _GetAllRegisters(self) -> Iterable[Register]:
        return self.registers


class Component:
    """
    This class encapsulates the information for a complete I2c_devreg component
    """

    def __init__(self, name : str):
        """
        Constructor

        :param name: Name of the component (used for constant name definition
        """
        self.name = name
        self.devices = []

    def AddDevice(self, dev : Device, idxOffset : int = None):
        """
        Add an I2C device

        :param dev: Device to add
        :param idxOffset: Start index number (optional). If not given, indexes are placed continuously without any gaps in between.
        """
        self.devices.append((idxOffset, dev))
        return self

    def _GetAllDevices(self) -> Iterable[Tuple[int, Device]]:
        return self.devices

    def UpdateHdr(self, path : str):
        """
        Update C-header files
        :param path: Path of the header file to update
        """
        hdrStr = ""

        def CharConv(inp : str):
            return inp.replace(" ", "_").replace("-", "_").upper()


        hdrStr += "\n"
        usedIndexes = [-1]
        for devOffs, dev in self._GetAllDevices():
            hdrStr += "/* {name}, (0x{addr:02x}, ".format(name=dev.name, addr=dev.devAddr)
            if dev.hasMux:
                hdrStr += "MuxAddr=0x{muxAddr:02x}, MuxValue=0x{muxValue:02x}".format(muxAddr=dev.muxAddr, muxValue=dev.muxValue)
            else:
                hdrStr += "No Mux"
            hdrStr += ") */\n"
            #If device has no specified offset, use the next free address
            if devOffs is None:
                devOffs = max(usedIndexes)+1
            for offs, reg in enumerate(dev._GetAllRegisters()):
                #Generate and check index
                thisIdx = devOffs+offs
                if thisIdx in usedIndexes:
                    raise Exception("The index {} is used more than once, error occured in {}.{}".format(thisIdx, dev.name, reg.name))
                else:
                    usedIndexes.append(thisIdx)
                #Create header Line
                hdrStr += "#define {:40} 0x{:08x} // DataBytes = {}, CmdBytes = {}, Cmd = 0x{:08x}, AutoRead = {}, AutoWrite = {}, DataLSByteFirst = {}"\
                    .format("{}_{}_{}".format(CharConv(self.name), CharConv(dev.name), CharConv(reg.name)), thisIdx, reg.dataBytes, reg.cmdBytes, reg.cmd, reg.autoRead, reg.autoWrite, reg.dataLsByteFirst)
                if reg.comment is not None:
                    hdrStr += " Comment: {}".format(reg.comment)
                hdrStr += "\n"

        with open(path, "r") as f:
            content = f.read()

        content = re.sub(   "// <<START_GENERATED>>.*// <<END_GENERATED>>",
                            "// <<START_GENERATED>>\n{}// <<END_GENERATED>>".format(hdrStr),
                            content, flags=re.DOTALL)
        with open(path, "w+") as f:
            f.write(content)



    def UpdateVhdl(self, path : str):
        """
        Update VHDL ROM defintion

        :param path: VHDL File to update
        """
        vhdlStr = ""

        def GetComment(reg : Register):
            s = ""
            s += reg.dir.name
            if reg.epics is not None:
                s += ", {}".format(reg.epics)
            if reg.comment is not None:
                s += ", \"{}\"".format(reg.comment)
            return s

        vhdlStr += "\n"
        usedIndexes = [-1]
        for devOffs, dev in self._GetAllDevices():
            #If device has no specified offset, use the next free address
            if devOffs is None:
                devOffs = max(usedIndexes)+1
            vhdlStr += "\t\t-----------------------------------------------------------------------------\n"
            vhdlStr += "\t\t-- {}\n".format(dev.name)
            vhdlStr += "\t\t-----------------------------------------------------------------------------\n"
            for offs, reg in enumerate(dev._GetAllRegisters()):
                #Generate and check index
                thisIdx = devOffs+offs
                if thisIdx in usedIndexes:
                    raise Exception("The index {} is used more than once, error occured in {}.{}".format(thisIdx, dev.name, reg.name))
                else:
                    usedIndexes.append(thisIdx)
                #Create VHDL Line
                vhdlStr +=  ("\t\t{idx}\t=> (" +
                            "AutoRead => {autoRd}, AutoWrite => {autoWr}, HasMux => {hasMux}, " +
                            "MuxAddr => X\"{muxAddr:02X}\", MuxValue => X\"{muxValue:02X}\", " +
                            "DevAddr => X\"{devAddr:02X}\", CmdBytes => {cmdBytes}, CmdData => X\"{cmdData:08X}\", "+
                            "DatBytes => {datBytes}, DataLSByteFirst => {dataLsbFirst}), -- {comment}")\
                            .format(idx=thisIdx, autoRd=BoolToStdl(reg.autoRead), autoWr=BoolToStdl(reg.autoWrite),
                                    hasMux=BoolToStdl(dev.hasMux), muxAddr=dev.muxAddr, muxValue=dev.muxValue,
                                    devAddr=dev.devAddr, cmdBytes=reg.cmdBytes, cmdData=reg.cmd, datBytes=reg.dataBytes,
                                    dataLsbFirst=BoolToStdl(reg.dataLsByteFirst) ,comment=reg.name)
                if reg.comment is not None:
                    vhdlStr += " - {}".format(reg.comment)
                vhdlStr += "\n"
            vhdlStr += "\n"

        #Substitute Content in VHDL file
        with open(path, "r") as f:
            content = f.read()
        content = re.sub(   "-- << ROM_CONTENT >>.*-- << END_ROM_CONTENT >>",
                            "-- << ROM_CONTENT >>\n{}\t\t-- << END_ROM_CONTENT >>".format(vhdlStr),
                            content, flags=re.DOTALL)
        with open(path, "w+") as f:
            f.write(content)






