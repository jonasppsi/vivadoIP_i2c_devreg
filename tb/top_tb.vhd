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
	
library std;
	use std.textio.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_tb_axi_pkg.all;
	use work.i2c_devreg_pkg.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;
	use work.psi_tb_activity_pkg.all;
	use work.psi_tb_i2c_pkg.all;

entity top_tb is
end entity top_tb;

architecture sim of top_tb is

	-------------------------------------------------------------------------
	-- AXI Definition
	-------------------------------------------------------------------------
	constant ID_WIDTH 		: integer 	:= 1;
	constant ADDR_WIDTH 	: integer	:= 16;
	constant USER_WIDTH		: integer	:= 1;
	constant DATA_WIDTH		: integer	:= 32;
	constant BYTE_WIDTH		: integer	:= DATA_WIDTH/8;
	
	subtype ID_RANGE is natural range ID_WIDTH-1 downto 0;
	subtype ADDR_RANGE is natural range ADDR_WIDTH-1 downto 0;
	subtype USER_RANGE is natural range USER_WIDTH-1 downto 0;
	subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
	subtype BYTE_RANGE is natural range BYTE_WIDTH-1 downto 0;
	
	signal axi_ms : axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
								araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
								aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
								wdata(DATA_RANGE),
								wstrb(BYTE_RANGE));
	
	signal axi_sm : axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
								ruser(USER_RANGE), buser(USER_RANGE),
								rdata(DATA_RANGE));

	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant	ClockFrequencyAxi_c	: real		:= 125.0e6;							-- Use slow clocks to speed up simulation
	constant	ClockPeriodAxi_c	: time		:= (1 sec)/ClockFrequencyAxi_c;
	constant 	NumReg_c			: integer	:= 4;
	
	signal 		TbRunning			: boolean 	:= True;

	
	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal aclk				: std_logic						:= '0';
	signal aresetn			: std_logic						:= '0';
	signal I2cScl			: std_logic						:= 'H';
	signal I2cSda			: std_logic						:= 'H';
	signal I2cRom_TValid	: std_logic						:= '0';
	signal I2cRom_TData		: std_logic_vector(31 downto 0)	:= (others => '0');
	signal RomI2c_TValid	: std_logic						:= '0';
	signal RomI2c_TData		: std_logic_vector(63 downto 0)	:= (others => '0');
	signal UpdateTrig		: std_logic						:= '0';
	signal Irq				: std_logic						:= '0';
	
begin

	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.i2c_devreg_vivado_wrp
		generic map (
			-- SPI Parameters
			ClockFrequencyHz_g		=> integer(ClockFrequencyAxi_c),
			I2cFrequencyHz_g		=> integer(1.0e6),		
			InternalTriState_g		=> true,			
			NumOfReg_g				=> NumReg_c,			
			-- AXI Parameters
			C_S00_AXI_ID_WIDTH		=> ID_WIDTH,
			C_S00_AXI_ADDR_WIDTH    => ADDR_WIDTH	
		)
		port map
		(
			-- I2C Ports
			I2cScl				=> I2cScl,
			I2cSda				=> I2cSda,
			-- Config ROM Ports
			I2cRom_TValid		=> I2cRom_TValid,
			I2cRom_TData		=> I2cRom_TData,			
			RomI2c_TValid		=> RomI2c_TValid,
			RomI2c_TData		=> RomI2c_TData,
			-- Parallel Ports
			UpdateTrig			=> UpdateTrig,
			Irq					=> Irq,
			-- Axi Slave Bus Interface
			s00_axi_aclk    	=> aclk,
			s00_axi_aresetn  	=> aresetn,
			s00_axi_arid        => axi_ms.arid,
			s00_axi_araddr      => axi_ms.araddr,
			s00_axi_arlen       => axi_ms.arlen,
			s00_axi_arsize      => axi_ms.arsize,
			s00_axi_arburst     => axi_ms.arburst,
			s00_axi_arlock      => axi_ms.arlock,
			s00_axi_arcache     => axi_ms.arcache,
			s00_axi_arprot      => axi_ms.arprot,
			s00_axi_arvalid     => axi_ms.arvalid,
			s00_axi_arready     => axi_sm.arready,
			s00_axi_rid         => axi_sm.rid,
			s00_axi_rdata       => axi_sm.rdata,
			s00_axi_rresp       => axi_sm.rresp,
			s00_axi_rlast       => axi_sm.rlast,
			s00_axi_rvalid      => axi_sm.rvalid,
			s00_axi_rready      => axi_ms.rready,
			s00_axi_awid    	=> axi_ms.awid,    
			s00_axi_awaddr      => axi_ms.awaddr,
			s00_axi_awlen       => axi_ms.awlen,
			s00_axi_awsize      => axi_ms.awsize,
			s00_axi_awburst     => axi_ms.awburst,
			s00_axi_awlock      => axi_ms.awlock,
			s00_axi_awcache     => axi_ms.awcache,
			s00_axi_awprot      => axi_ms.awprot,
			s00_axi_awvalid     => axi_ms.awvalid,
			s00_axi_awready     => axi_sm.awready,
			s00_axi_wdata       => axi_ms.wdata,
			s00_axi_wstrb       => axi_ms.wstrb,
			s00_axi_wlast       => axi_ms.wlast,
			s00_axi_wvalid      => axi_ms.wvalid,
			s00_axi_wready      => axi_sm.wready,
			s00_axi_bid         => axi_sm.bid,
			s00_axi_bresp       => axi_sm.bresp,
			s00_axi_bvalid      => axi_sm.bvalid,
			s00_axi_bready      => axi_ms.bready			
		);
		
	I2cPullUp(I2cScl, I2cSda);

	-------------------------------------------------------------------------
	-- ROM Emulation
	-------------------------------------------------------------------------		
	p_rom : process(aclk)
		constant RomContent : CfgRom_t(0 to 2**log2ceil(NumReg_c)-1) := (
			-- << ROM_CONTENT >>
			0       => (AutoRead => '1', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"12",	CmdBytes => 1,	CmdData => X"000000AB",	DatBytes => 1),
			1       => (AutoRead => '0', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"12",	CmdBytes => 1,	CmdData => X"000000A0",	DatBytes => 1),
			2       => (AutoRead => '1', HasMux => '1',	MuxAddr => X"0A", 	MuxValue => X"CD", 	DevAddr => X"13",	CmdBytes => 1,	CmdData => X"000000E0",	DatBytes => 2),
			-- << END_ROM_CONTENT >>
			others 	=> (AutoRead => '0', HasMux => '0',	MuxAddr => X"00", 	MuxValue => X"00", 	DevAddr => X"00",	CmdBytes => 0,	CmdData => X"00000000",	DatBytes => 0)
		);
		constant RomAddrBits_c		: integer	:= log2ceil(NumReg_c);
	begin
		if rising_edge(aclk) then
			RomI2c_TValid <= I2cRom_TValid;
			if I2cRom_TValid = '1' then
				RomI2c_TData	<= RomEntryRomToSlv(RomContent(to_integer(unsigned(I2cRom_TData(RomAddrBits_c-1 downto 0)))));
			end if;
		end if;
	end process;

	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_aclk : process
	begin
		aclk <= '0';
		while TbRunning loop
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '1';
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '0';
		end loop;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
		variable Readback_v	: integer;
		variable ReadbackSlv_v : std_logic_vector(31 downto 0);
		variable StartTime_v : time;
	begin
		-- Reset
		aresetn <= '0';
		wait for 1 us;
		wait until rising_edge(aclk);
		aresetn <= '1';
		wait for 1 us;
		wait until rising_edge(aclk);
		
		-- *** Check reset values ***
		print(">> Check reset values");
		axi_single_expect(RegIdx_UpdateEna_c*4, 0, axi_ms, axi_sm, aclk, "Reset Wrong 0"); 
		axi_single_expect(RegIdx_BusBusy_c*4, 0, axi_ms, axi_sm, aclk, "Reset Wrong 1"); 
		axi_single_expect(RegIdx_AccessFailed_c*4, 0, axi_ms, axi_sm, aclk, "Reset Wrong 2"); 
		axi_single_expect(RegIdx_FifoState_c*4, 2**BitIdx_FifoState_Empty_c, axi_ms, axi_sm, aclk, "Reset Wrong 3"); 
		axi_single_expect(RegIdx_UpdateOngoing_c*4, 0, axi_ms, axi_sm, aclk, "Reset Wrong 4"); 
		
		
		-- *** Check Update Disabled by Default ***
		print(">> Check Update Disabled by Default");
		axi_single_write(RegIdx_UpdateTrig_c*4, 1, axi_ms, axi_sm, aclk);	
		PulseSig(UpdateTrig, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_BusBusy_c*4, 0, axi_ms, axi_sm, aclk, "Bus went busy unexpectedly"); 
		
		-- *** Check Single Read (index 1) ***
		print(">> Check Single Read");
		StartTime_v := now;
		axi_single_write(RegIdx_ForceRead_c*4, 1, axi_ms, axi_sm, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_BusBusy_c*4, 1, axi_ms, axi_sm, aclk, "Bus did not go busy"); 
		axi_single_expect(RegIdx_FifoState_c*4, 0, axi_ms, axi_sm, aclk, "FIFO is still empty");		
		-- Wait until done
		loop
			axi_single_read(RegIdx_BusBusy_c*4, Readback_v, axi_ms, axi_sm, aclk);
			exit when Readback_v = 0;
		end loop;
		-- Check values
		axi_single_expect((RegIdx_Mem_c+1)*4, 16#F1#, axi_ms, axi_sm, aclk, "Wrong data");
		axi_single_expect(RegIdx_AccessFailed_c*4, 0, axi_ms, axi_sm, aclk, "Wrong data");	
		CheckLastActivity(Irq, now-StartTime_v, 0, "Irq sent unexpectedly");
		ClockedWaitTime(10 us, aclk);
		
		-- *** Check single write (index 1)  ***
		print(">> Check single write");
		axi_single_write((RegIdx_Mem_c+1)*4, 16#F2#, axi_ms, axi_sm, aclk);
		axi_single_write(RegIdx_IrqEna_c*4, 2**BitIdx_Irq_FifoEmpty_c, axi_ms, axi_sm, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_BusBusy_c*4, 1, axi_ms, axi_sm, aclk, "Bus did not go busy"); 
		axi_single_expect(RegIdx_FifoState_c*4, 0, axi_ms, axi_sm, aclk, "FIFO is still empty"); 		
		-- Wait until done
		loop
			axi_single_read(RegIdx_BusBusy_c*4, Readback_v, axi_ms, axi_sm, aclk);
			exit when Readback_v = 0;
		end loop;
		-- Check values
		axi_single_expect((RegIdx_Mem_c+1)*4, 16#F2#, axi_ms, axi_sm, aclk, "Wrong data");
		axi_single_expect(RegIdx_AccessFailed_c*4, 0, axi_ms, axi_sm, aclk, "Wrong data");	
		axi_single_expect(RegIdx_FifoState_c*4, 2**BitIdx_FifoState_Empty_c, axi_ms, axi_sm, aclk, "FIFO is not empty");
		StdlCompare(1, Irq, "IRQ was not fired");
		axi_single_write(RegIdx_IrqVec_c*4, 2**BitIdx_Irq_FifoEmpty_c, axi_ms, axi_sm, aclk);
		ClockedWaitTime(100 ns, aclk);
		StdlCompare(0, Irq, "IRQ was not cleared");
		axi_single_write(RegIdx_IrqEna_c*4, 0, axi_ms, axi_sm, aclk);
		ClockedWaitTime(10 us, aclk);
		
		-- *** Check Fail & Clear ***
		print(">> Check Fail & Clear");
		axi_single_write((RegIdx_Mem_c+1)*4, 16#F3#, axi_ms, axi_sm, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_BusBusy_c*4, 1, axi_ms, axi_sm, aclk, "Bus did not go busy"); 
		axi_single_expect(RegIdx_FifoState_c*4, 0, axi_ms, axi_sm, aclk, "FIFO is still empty"); 		
		-- Wait until done
		loop
			axi_single_read(RegIdx_BusBusy_c*4, Readback_v, axi_ms, axi_sm, aclk);
			exit when Readback_v = 0;
		end loop;
		-- Check values
		axi_single_expect(RegIdx_AccessFailed_c*4, 1, axi_ms, axi_sm, aclk, "Fail-bit not set");	
		axi_single_expect((RegIdx_Mem_c+1)*4, 16#FFFFFFFF#, axi_ms, axi_sm, aclk, "Wrong value on fail");
		axi_single_write(RegIdx_AccessFailed_c*4, 1, axi_ms, axi_sm, aclk);
		axi_single_expect(RegIdx_AccessFailed_c*4, 0, axi_ms, axi_sm, aclk, "Fail-bit not cleared");
		ClockedWaitTime(10 us, aclk);
		

		-- *** Check Update External Port ***
		print(">> Check Update External Port");
		axi_single_write(RegIdx_UpdateEna_c*4, 1, axi_ms, axi_sm, aclk);
		axi_single_write(RegIdx_IrqEna_c*4, 2**BitIdx_Irq_UpdateDone_c, axi_ms, axi_sm, aclk);
		PulseSig(UpdateTrig, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_UpdateOngoing_c*4, 1, axi_ms, axi_sm, aclk, "Bus did not go busy"); 
		-- Wait until done
		loop
			axi_single_read(RegIdx_UpdateOngoing_c*4, Readback_v, axi_ms, axi_sm, aclk);
			exit when Readback_v = 0;
		end loop;
		-- Check values
		axi_single_expect((RegIdx_Mem_c+0)*4, 16#F4#, axi_ms, axi_sm, aclk, "Wrong data 0");
		axi_single_expect((RegIdx_Mem_c+2)*4, 16#F5F6#, axi_ms, axi_sm, aclk, "Wrong data 2");
		axi_single_expect(RegIdx_AccessFailed_c*4, 0, axi_ms, axi_sm, aclk, "Wrong fail-bit");	
		StdlCompare(1, Irq, "IRQ was not fired");
		axi_single_write(RegIdx_IrqVec_c*4, 2**BitIdx_Irq_UpdateDone_c, axi_ms, axi_sm, aclk);
		ClockedWaitTime(100 ns, aclk);
		StdlCompare(0, Irq, "IRQ was not cleared");
		axi_single_write(RegIdx_IrqEna_c*4, 0, axi_ms, axi_sm, aclk);
		ClockedWaitTime(10 us, aclk);
		
		-- *** Check Update via Register Bank ***
		print(">> Check Update via Register Bank");
		StartTime_v := now;
		axi_single_write(RegIdx_UpdateTrig_c*4, 1, axi_ms, axi_sm, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_UpdateOngoing_c*4, 1, axi_ms, axi_sm, aclk, "Bus did not go busy"); 
		-- Wait until done
		loop
			axi_single_read(RegIdx_UpdateOngoing_c*4, Readback_v, axi_ms, axi_sm, aclk);
			exit when Readback_v = 0;
		end loop;
		-- Check values
		axi_single_expect((RegIdx_Mem_c+0)*4, 16#F7#, axi_ms, axi_sm, aclk, "Wrong data 0");
		axi_single_expect((RegIdx_Mem_c+2)*4, 16#F8F9#, axi_ms, axi_sm, aclk, "Wrong data 2");
		axi_single_expect(RegIdx_AccessFailed_c*4, 0, axi_ms, axi_sm, aclk, "Wrong fail-bit");	
		ClockedWaitTime(10 us, aclk);
		-- We would not expect an IRQ
		CheckLastActivity(Irq, now-StartTime_v, 0, "Irq sent unexpectedly");
		
		-- TB done
		TbRunning <= false;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- SPI Emulation
	-------------------------------------------------------------------------
	p_i2c_slave : process
	begin	
		I2cSetFrequency(1.0e6);
		I2cBusFree(I2cScl, I2cSda);
	
		wait until aresetn = '1';
		wait until rising_edge(aclk);
		
		-- *** Check reset values ***
		-- Nothing to do
		
		-- *** Check Update Disabled by Default  ***
		-- Nothing to do
		
		-- *** Check Single Read (index 1) ***
		I2cSlaveWaitStart(I2cScl, I2cSda, "A1");
		I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_WRITE), I2cScl, I2cSda, "A2", I2c_ACK);	
		I2cSlaveExpectByte(16#A0#, I2cScl, I2cSda, "A3", I2c_ACK);	
		I2cSlaveWaitRepeatedStart(I2cScl, I2cSda, "A4");
		I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_READ), I2cScl, I2cSda, "A5", I2c_ACK);	
		I2cSlaveSendByte(16#F1#, I2cScl, I2cSda, "A6", I2c_NACK);
		I2cSlaveWaitStop(I2cScl, I2cSda, "A7");
		
		-- *** Check single write (index 1)  ***
		I2cSlaveWaitStart(I2cScl, I2cSda, "B1");
		I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_WRITE), I2cScl, I2cSda, "B2", I2c_ACK);	
		I2cSlaveExpectByte(16#A0#, I2cScl, I2cSda, "B3", I2c_ACK);	
		I2cSlaveExpectByte(16#F2#, I2cScl, I2cSda, "B6", I2c_ACK);
		I2cSlaveWaitStop(I2cScl, I2cSda, "B7");
		
		-- *** Check Fail & Clear ***
		-- First try
		I2cSlaveWaitStart(I2cScl, I2cSda, "C1");
		I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_WRITE), I2cScl, I2cSda, "C2", I2c_NACK);
		I2cSlaveWaitStop(I2cScl, I2cSda, "C3");
		-- Retry
		I2cSlaveWaitStart(I2cScl, I2cSda, "C4");
		I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_WRITE), I2cScl, I2cSda, "C5", I2c_NACK);
		I2cSlaveWaitStop(I2cScl, I2cSda, "C6");
		
		-- *** Check Update External Port ***
		-- *** Check Update via Register Bank ***
		-- ... Both work the same way, so they are handled in one loop
		for i in 0 to 1 loop
			-- Index 0
			I2cSlaveWaitStart(I2cScl, I2cSda, "D1-" & to_string(i));
			I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_WRITE), I2cScl, I2cSda, "D2-" & to_string(i), I2c_ACK);
			I2cSlaveExpectByte(16#AB#, I2cScl, I2cSda, "D3-" & to_string(i), I2c_ACK);	
			I2cSlaveWaitRepeatedStart(I2cScl, I2cSda, "D4-" & to_string(i));
			I2cSlaveExpectByte(I2cGetAddr(16#12#, I2c_READ), I2cScl, I2cSda, "D5-" & to_string(i), I2c_ACK);
			I2cSlaveSendByte(16#F4#+3*i, I2cScl, I2cSda, "D6-" & to_string(i), I2c_NACK);	
			I2cSlaveWaitStop(I2cScl, I2cSda, "D7-" & to_string(i));	

			-- Index 1 is skipped (no auto update)
		
			-- Index 2
			I2cSlaveWaitStart(I2cScl, I2cSda, "D8-" & to_string(i));
			I2cSlaveExpectByte(I2cGetAddr(16#0A#, I2c_WRITE), I2cScl, I2cSda, "D9-" & to_string(i), I2c_ACK);
			I2cSlaveExpectByte(16#CD#, I2cScl, I2cSda, "D10-" & to_string(i), I2c_ACK);	
			I2cSlaveWaitRepeatedStart(I2cScl, I2cSda, "D11-" & to_string(i));
			I2cSlaveExpectByte(I2cGetAddr(16#13#, I2c_WRITE), I2cScl, I2cSda, "D12-" & to_string(i), I2c_ACK);
			I2cSlaveExpectByte(16#E0#, I2cScl, I2cSda, "D13-" & to_string(i), I2c_ACK);
			I2cSlaveWaitRepeatedStart(I2cScl, I2cSda, "D14-" & to_string(i));
			I2cSlaveExpectByte(I2cGetAddr(16#13#, I2c_READ), I2cScl, I2cSda, "D15-" & to_string(i), I2c_ACK);
			I2cSlaveSendByte(16#F5#+3*i, I2cScl, I2cSda, "D16-" & to_string(i), I2c_ACK);	
			I2cSlaveSendByte(16#F6#+3*i, I2cScl, I2cSda, "D17-" & to_string(i), I2c_NACK);
			I2cSlaveWaitStop(I2cScl, I2cSda, "D18-" & to_string(i));	
		end loop;
	
		
		wait;
	end process;
	
	

end sim;
