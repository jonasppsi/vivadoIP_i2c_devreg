--Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
--Date        : Wed Oct  2 10:44:37 2019
--Host        : PC12955 running 64-bit major release  (build 9200)
--Command     : generate_target system_wrapper.bd
--Design      : system_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_wrapper is
  port (
    I2cScl : inout STD_LOGIC;
    I2cSda : inout STD_LOGIC
  );
end system_wrapper;

architecture STRUCTURE of system_wrapper is
  component system is
  port (
    I2cScl : inout STD_LOGIC;
    I2cSda : inout STD_LOGIC
  );
  end component system;
begin
system_i: component system
     port map (
      I2cScl => I2cScl,
      I2cSda => I2cSda
    );
end STRUCTURE;
