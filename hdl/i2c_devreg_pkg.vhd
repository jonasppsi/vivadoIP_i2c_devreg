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
		HasMux			: std_logic;
		MuxAddr			: std_logic_vector(7 downto 0);	-- Bit 7 unused and only present to allow hex entry
		MuxValue		: std_logic_vector(7 downto 0);
		DevAddr			: std_logic_vector(7 downto 0);	-- Bit 7 unused and only present to allow hex entry
		CmdBytes		: integer range 0 to 4;
		CmdData			: std_logic_vector(31 downto 0);
		DatBytes		: integer range 0 to 4;
		AutoRead		: std_logic;
		AutoWrite		: std_logic;
		DataLSByteFirst	: std_logic;
	end record;		
	type CfgRom_t is array (natural range <>) of CfgRomEntry_t;

	-- Indexes to sue when MAP
	constant Idx_HasMux				: integer	:= 0;
	subtype Rng_MuxAddr				is natural range Idx_HasMux+8 downto Idx_HasMux+1;
	subtype Rng_MuxValue			is natural range Rng_MuxAddr'high+8 downto Rng_MuxAddr'high+1;
	subtype Rng_DevAddr				is natural range Rng_MuxValue'high+8 downto Rng_MuxValue'high+1;
	subtype Rng_CmdBytes			is natural range Rng_DevAddr'high+3 downto Rng_DevAddr'high+1;
	subtype Rng_CmdData				is natural range Rng_CmdBytes'high+32 downto Rng_CmdBytes'high+1;
	subtype Rng_DatBytes			is natural range Rng_CmdData'high+3 downto Rng_CmdData'high+1;
	constant Idx_AutoRead			: integer	:= Rng_DatBytes'high+1;	
	constant Idx_AutoWrite 			: integer	:= Idx_AutoRead+1;
	constant Idx_DataLSByteFirst	: integer	:= Idx_AutoWrite+1;
	
	-- Convert record to std_logic_vector									
	function RomEntryRomToSlv(Inp : in CfgRomEntry_t) return std_logic_vector;
	
	-- Convert std_logic_vector to record
	function SlvToRomEntry(	Inp : in std_logic_vector) return CfgRomEntry_t;
	
	-- *** Registers ***
	constant RegIdx_UpdateEna_c			: integer	:= 0;
	constant RegIdx_UpdateTrig_c		: integer	:= 1;
	constant RegIdx_IrqEna_c			: integer	:= 2;
	constant RegIdx_IrqVec_c			: integer	:= 3;
	constant RegIdx_BusBusy_c			: integer	:= 4;
	constant RegIdx_AccessFailed_c		: integer	:= 5;
	constant RegIdx_FifoState_c			: integer	:= 6;
	constant RegIdx_UpdateOngoing_c		: integer	:= 7;
	constant RegIdx_ForceRead_c			: integer	:= 8;
	constant RegIdx_BusBusyCount_c			: integer	:= 9;     -- Bus Busy Time per second
	constant RegIdx_BusBusyCountMax_c			: integer	:= 10; -- Bus Busy Time Max
	constant RegIdx_TrigWhileBusyCount_c			: integer	:= 11;     -- Count Triggers while bus busy
	constant RegIdx_UpdateTrigCount_c			: integer	:= 12;     -- Count update trigger per second
	constant RegIdx_Mem_c				: integer	:= 16;
	
	constant BitIdx_FifoState_Empty_c	: integer	:= 0;
	constant BitIdx_FifoState_Full_c	: integer	:= 8;
	
	constant BitIdx_Irq_UpdateDone_c	: integer	:= 0;
	constant BitIdx_Irq_FifoEmpty_c		: integer	:= 8;
	
	

end package;

package body i2c_devreg_pkg is


	function RomEntryRomToSlv(Inp : in CfgRomEntry_t) return std_logic_vector is
		variable Slv_v : std_logic_vector(71 downto 0) := (others => '0');
	begin
		Slv_v(Idx_HasMux) 			:= Inp.HasMux;
		Slv_v(Rng_MuxAddr) 			:= Inp.MuxAddr;
		Slv_v(Rng_MuxValue) 		:= Inp.MuxValue;
		Slv_v(Rng_DevAddr) 			:= Inp.DevAddr;
		Slv_v(Rng_CmdBytes) 		:= std_logic_vector(to_unsigned(Inp.CmdBytes, 3));
		Slv_v(Rng_CmdData) 			:= Inp.CmdData;
		Slv_v(Rng_DatBytes) 		:= std_logic_vector(to_unsigned(Inp.DatBytes, 3));
		Slv_v(Idx_AutoRead) 		:= Inp.AutoRead;
		Slv_v(Idx_AutoWrite)		:= Inp.AutoWrite;
		Slv_v(Idx_DataLSByteFirst)	:= Inp.DataLSByteFirst;
		return Slv_v;
	end function;
		
	function SlvToRomEntry(	Inp : in std_logic_vector) return CfgRomEntry_t is
		variable Data_v : CfgRomEntry_t;
	begin
		Data_v.HasMux			:= Inp(Idx_HasMux);
		Data_v.MuxAddr			:= Inp(Rng_MuxAddr); 	
		Data_v.MuxValue			:= Inp(Rng_MuxValue); 
		Data_v.DevAddr			:= Inp(Rng_DevAddr);
		Data_v.CmdBytes			:= to_integer(unsigned(Inp(Rng_CmdBytes))); 
		Data_v.CmdData			:= Inp(Rng_CmdData);
		Data_v.DatBytes			:= to_integer(unsigned(Inp(Rng_DatBytes))); 
		Data_v.AutoRead			:= Inp(Idx_AutoRead);
		Data_v.AutoWrite		:= Inp(Idx_AutoWrite);
		Data_v.DataLSByteFirst	:= Inp(Idx_DataLSByteFirst);
		return Data_v;
	end function;
	
end i2c_devreg_pkg;






