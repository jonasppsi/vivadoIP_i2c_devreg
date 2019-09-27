------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	
------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package i2c_devreg_pkg is
		
	-- Record type to nicely define configuration ROM entries
	type CfgRomEntry_t is record	
		HasMux		: std_logic;
		MuxAddr		: std_logic_vector(7 downto 0);	-- Bit 7 unused and only present to allow hex entry
		MuxValue	: std_logic_vector(7 downto 0);
		DevAddr		: std_logic_vector(7 downto 0);	-- Bit 7 unused and only present to allow hex entry
		CmdBytes	: integer range 0 to 4;
		CmdData		: std_logic_vector(31 downto 0);
		DatBytes	: integer range 0 to 4;
		AutoRead	: std_logic;
	end record;		
	type CfgRom_t is array (natural range <>) of CfgRomEntry_t;

	-- Indexes to sue when MAP
	constant Idx_HasMux		: integer	:= 0;
	subtype Rng_MuxAddr		is natural range Idx_HasMux+8 downto Idx_HasMux+1;
	subtype Rng_MuxValue		is natural range Rng_MuxAddr'high+8 downto Rng_MuxAddr'high+1;
	subtype Rng_DevAddr		is natural range Rng_MuxValue'high+8 downto Rng_MuxValue'high+1;
	subtype Rng_CmdBytes		is natural range Rng_DevAddr'high+3 downto Rng_DevAddr'high+1;
	subtype Rng_CmdData		is natural range Rng_CmdBytes'high+32 downto Rng_CmdBytes'high+1;
	subtype Rng_DatBytes		is natural range Rng_CmdData'high+3 downto Rng_CmdData'high+1;
	constant Idx_AutoRead	: integer	:= Rng_DatBytes'high+1;	
	
	-- Size of the std_logic_vector to reperesent a ROM entry
	constant RomEntrySlvBits_c			: integer	:= Idx_AutoRead+1;
	
	-- Convert record to std_logic_vector									
	function RomEntryRomToSlv(Inp : in CfgRomEntry_t) return std_logic_vector;
	
	-- Convert std_logic_vector to record
	function SlvToRomEntry(	Inp : in std_logic_vector) return CfgRomEntry_t;

end package;

package body i2c_devreg_pkg is


	function RomEntryRomToSlv(Inp : in CfgRomEntry_t) return std_logic_vector is
		variable Slv_v : std_logic_vector(RomEntrySlvBits_c-1 downto 0);
	begin
		Slv_v(Idx_HasMux) 	:= Inp.HasMux;
		Slv_v(Rng_MuxAddr) 	:= Inp.MuxAddr;
		Slv_v(Rng_MuxValue) 	:= Inp.MuxValue;
		Slv_v(Rng_DevAddr) 	:= Inp.DevAddr;
		Slv_v(Rng_CmdBytes) 	:= std_logic_vector(to_unsigned(Inp.CmdBytes, 3));
		Slv_v(Rng_CmdData) 	:= Inp.CmdData;
		Slv_v(Rng_DatBytes) 	:= std_logic_vector(to_unsigned(Inp.DatBytes, 3));
		Slv_v(Idx_AutoRead) 	:= Inp.AutoRead;
		return Slv_v;
	end function;
		
	function SlvToRomEntry(	Inp : in std_logic_vector) return CfgRomEntry_t is
		variable Data_v : CfgRomEntry_t;
	begin
		Data_v.HasMux	:= Inp(Idx_HasMux);
		Data_v.MuxAddr	:= Inp(Rng_MuxAddr); 	
		Data_v.MuxValue	:= Inp(Rng_MuxValue); 
		Data_v.DevAddr	:= Inp(Rng_DevAddr);
		Data_v.CmdBytes	:= to_integer(unsigned(Inp(Rng_CmdBytes))); 
		Data_v.CmdData	:= Inp(Rng_CmdData);
		Data_v.DatBytes	:= to_integer(unsigned(Inp(Rng_DatBytes))); 
		Data_v.AutoRead	:= Inp(Idx_AutoRead);
		return Data_v;
	end function;
	
end i2c_devreg_pkg;






