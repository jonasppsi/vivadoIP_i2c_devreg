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
		RomI2c_TData	: out	std_logic_vector(71 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of i2c_devreg_rom is	

	constant RomContent : CfgRom_t(0 to 2**log2ceil(NumOfReg_g)-1) := (
		-- << ROM_CONTENT >>

		-----------------------------------------------------------------------------
		-- SI5341
		-----------------------------------------------------------------------------
		0	=> (AutoRead => '0', AutoWrite => '1', HasMux => '1', MuxAddr => X"74", MuxValue => X"02", DevAddr => X"36", CmdBytes => 2, CmdData => X"00000100", DatBytes => 0), -- SetPage0
		1	=> (AutoRead => '1', AutoWrite => '0', HasMux => '1', MuxAddr => X"74", MuxValue => X"02", DevAddr => X"36", CmdBytes => 1, CmdData => X"00000002", DatBytes => 2), -- PartNumber
		2	=> (AutoRead => '1', AutoWrite => '0', HasMux => '1', MuxAddr => X"74", MuxValue => X"02", DevAddr => X"36", CmdBytes => 1, CmdData => X"00000018", DatBytes => 1), -- LosIn_Mask
		3	=> (AutoRead => '0', AutoWrite => '1', HasMux => '1', MuxAddr => X"74", MuxValue => X"02", DevAddr => X"36", CmdBytes => 1, CmdData => X"00000001", DatBytes => 1), -- UserPage

		-- << END_ROM_CONTENT >>
		others 	=> (AutoRead => '0', AutoWrite => '0', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"00",	CmdBytes => 0,	CmdData => X"00000000",	DatBytes => 0)
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





