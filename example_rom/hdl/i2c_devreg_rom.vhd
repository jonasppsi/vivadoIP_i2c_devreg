------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.i2c_devreg_pkg.all;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity i2c_devreg_rom is
	generic (
		NumOfReg_g			: integer	:= 1024
	);
	port (
		-- Control Signals
		aclk				: in	std_logic;	    
		
		-- Config Rom Interface
		I2cRom_TValid	: in	std_logic;
		I2cRom_TData	: in	std_logic_vector(31 downto 0);
		RomI2c_TValid	: out	std_logic;
		RomI2c_TData	: out	std_logic_vector(63 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of i2c_devreg_rom is	

	constant RomContent : CfgRom_t(0 to 2**log2ceil(NumOfReg_g)-1) := (
		-- << ROM_CONTENT >>
		0       => (AutoRead => '1', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"12",	CmdBytes => 1,	CmdData => X"000000AB",	DatBytes => 1),
		1       => (AutoRead => '0', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"12",	CmdBytes => 1,	CmdData => X"000000A0",	DatBytes => 1),
		2       => (AutoRead => '1', HasMux => '1',	MuxAddr => X"0A", 	MuxValue => X"CD", 	DevAddr => X"13",	CmdBytes => 1,	CmdData => X"000000E0",	DatBytes => 2),
		-- << END_ROM_CONTENT >>
		others 	=> (AutoRead => '0', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"00",	CmdBytes => 0,	CmdData => X"00000000",	DatBytes => 0)
	); 	
	
	-- Constants
	constant RomAddrBits_c		: integer	:= log2ceil(NumOfReg_g);


begin

	p_rom : process(aclk)
	begin
		if rising_edge(aclk) then
			RomI2c_TValid <= I2cRom_TValid;
			if I2cRom_TValid = '1' then
				RomI2c_TData	<= RomEntryRomToSlv(RomContent(to_integer(unsigned(I2cRom_TData(RomAddrBits_c-1 downto 0)))));
			end if;
		end if;
	end process;
	
end;





