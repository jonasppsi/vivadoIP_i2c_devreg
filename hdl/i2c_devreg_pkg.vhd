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

	type ToRom_t is record
		Vld		: std_logic;
		Addr	: std_logic_vector(31 downto 0); -- unused bits are discarded on both sides
	end record;
	
	type FromRom_t is record	
		Vld			: std_logic;
		HasMux		: std_logic;
		MuxAddr		: std_logic_vector(6 downto 0);
		MuxValue	: std_logic_vector(7 downto 0);
		DevAddr		: std_logic_vector(6 downto 0);
		CmdBytes	: integer range 0 to 4;
		CmdData		: std_logic_vector(31 downto 0);
		DatBytes	: integer range 0 to 4;
		AutoRead	: std_logic;
	end record;	
	constant FromRomIdx_HasMux		: integer	:= 0;
	subtype FromRomRng_MuxAddr		is natural range FromRomIdx_HasMux+7 downto FromRomIdx_HasMux+1;
	subtype FromRomRng_MuxValue		is natural range FromRomRng_MuxAddr'high+8 downto FromRomRng_MuxAddr'high+1;
	subtype FromRomRng_DevAddr		is natural range FromRomRng_MuxValue'high+7 downto FromRomRng_MuxValue'high+1;
	subtype FromRomRng_CmdBytes		is natural range FromRomRng_DevAddr'high+3 downto FromRomRng_DevAddr'high+1;
	subtype FromRomRng_CmdData		is natural range FromRomRng_CmdBytes'high+32 downto FromRomRng_CmdBytes'high+1;
	subtype FromRomRng_DatBytes		is natural range FromRomRng_CmdData'high+3 downto FromRomRng_CmdData'high+1;
	constant FromRomIdx_AutoRead	: integer	:= FromRomRng_DatBytes'high+1;
	constant FromRomBits_c			: integer	:= FromRomIdx_AutoRead+1;
	
	type CfgRomEntry_t is record	
		HasMux		: std_logic;
		MuxAddr		: std_logic_vector(6 downto 0);
		MuxValue	: std_logic_vector(7 downto 0);
		DevAddr		: std_logic_vector(6 downto 0);
		CmdBytes	: integer range 0 to 4;
		CmdData		: std_logic_vector(31 downto 0);
		DatBytes	: integer range 0 to 4;
		AutoRead	: std_logic;
	end record;		
	type CfgRom_t is array (natural range <>) of CfgRomEntry_t;	
	
	function EntryToFromRom(	Entry 	: in CfgRomEntry_t;
								Vld		: in std_logic) return FromRom_t;
								
	function FromRomToSlv(Inp : in FromRom_t) return std_logic_vector;
	
	function SlvToFromRom(	Inp : in std_logic_vector;
							Vld	: in std_logic) return FromRom_t;

end package;

package body i2c_devreg_pkg is

	function EntryToFromRom(	Entry 	: in CfgRomEntry_t;
								Vld		: in std_logic) return FromRom_t is
		variable Data_v : FromRom_t;
	begin
		Data_v.Vld 			:= Vld;
		Data_v.HasMux 		:= Entry.HasMux;
		Data_v.MuxAddr		:= Entry.MuxAddr;
		Data_v.MuxValue		:= Entry.MuxValue;
		Data_v.DevAddr		:= Entry.DevAddr;
		Data_v.CmdBytes		:= Entry.CmdBytes;
		Data_v.CmdData		:= Entry.CmdData;
		Data_v.DatBytes		:= Entry.DatBytes;
		Data_v.AutoRead		:= Entry.AutoRead;
		return Data_v;
	end function;

	function FromRomToSlv(Inp : in FromRom_t) return std_logic_vector is
		variable Slv_v : std_logic_vector(FromRomBits_c-1 downto 0);
	begin
		Slv_v(FromRomIdx_HasMux) 	:= Inp.HasMux;
		Slv_v(FromRomRng_MuxAddr) 	:= Inp.MuxAddr;
		Slv_v(FromRomRng_MuxValue) 	:= Inp.MuxValue;
		Slv_v(FromRomRng_DevAddr) 	:= Inp.DevAddr;
		Slv_v(FromRomRng_CmdBytes) 	:= std_logic_vector(to_unsigned(Inp.CmdBytes, 3));
		Slv_v(FromRomRng_CmdData) 	:= Inp.CmdData;
		Slv_v(FromRomRng_DatBytes) 	:= std_logic_vector(to_unsigned(Inp.DatBytes, 3));
		Slv_v(FromRomIdx_AutoRead) 	:= Inp.AutoRead;
		return Slv_v;
	end function;
		
	function SlvToFromRom(	Inp : in std_logic_vector;
							Vld	: in std_logic) return FromRom_t is
		variable Data_v : FromRom_t;
	begin
		Data_v.HasMux	:= Inp(FromRomIdx_HasMux);
		Data_v.MuxAddr	:= Inp(FromRomRng_MuxAddr); 	
		Data_v.MuxValue	:= Inp(FromRomRng_MuxValue); 
		Data_v.DevAddr	:= Inp(FromRomRng_DevAddr);
		Data_v.CmdBytes	:= to_integer(unsigned(Inp(FromRomRng_CmdBytes))); 
		Data_v.CmdData	:= Inp(FromRomRng_CmdData);
		Data_v.DatBytes	:= to_integer(unsigned(Inp(FromRomRng_DatBytes))); 
		Data_v.AutoRead	:= Inp(FromRomIdx_AutoRead);
		Data_v.Vld		:= Vld;
		return Data_v;
	end function;
	
end i2c_devreg_pkg;






