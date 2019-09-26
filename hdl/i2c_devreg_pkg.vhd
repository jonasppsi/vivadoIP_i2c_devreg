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
	
	type CfgRom_t is array (natural range <>) of FromRom_t;
		

end package;






