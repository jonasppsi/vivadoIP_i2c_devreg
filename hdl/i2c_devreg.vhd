------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity a component that simmplifies I2C access. It allows
-- describing the procedure to access an I2C register in a ROM (i.e. device address,
-- Command bytes, register size in bytes, etc) and then accessing the register
-- by just writing the data. Even more important is the auto-read functionality:
-- Registers can be configured to be read-back periodically without any SW interaction.

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
	use work.psi_common_i2c_master_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity i2c_devreg is
	generic (
		ClockFrequency_g	: real		:= 125.0e6;		-- in Hz		$$ constant=125.0e6 $$
		I2cFrequency_g		: real 		:= 100.0e3;		-- in Hz		$$ constant=1.0e6 $$
		BusBusyTimeout_g	: real		:= 1.0e-3;		-- in sec		
		UpdatePeriod_g		: real		:= 100.0e-3;	-- in sec		$$ constant=1.0e-3 $$
		InternalTriState_g	: boolean	:= true;		-- 				$$ constant=true $$
		NumOfReg_g			: integer	:= 1024			--				$$ constant=3 $$
	);
	port (
		-- Control Signals
		Clk			: in	std_logic;		-- $$ type=clk; freq=125e6 $$
		Rst			: in	std_logic;	    -- $$ type=rst; clk=Clk $$
		
		-- Config Rom Interface
		ToRom		: out	ToRom_t;
		FromRom		: in	FromRom_t;
		
		-- Parallel Interface
		UpdateTrig	: in	std_logic;
		UpdateEna	: in	std_logic	:= '1';	
		BusBusy		: out 	std_logic;

		-- Reg Access
		RegAddr		: in	std_logic_vector(log2ceil(NumOfReg_g)-1 downto 0);
		RegI2cWrite	: in	std_logic;
		RegI2cRead	: in	std_logic;
		RegDout		: out	std_logic_vector(31 downto 0);
		RegDin		: in	std_logic_vector(31 downto 0);
		
		-- I2c Interface with internal Tri-State (InternalTriState_g = true)
		I2cScl		: inout	std_logic	:= 'Z';
		I2cSda		: inout	std_logic	:= 'Z';
		
		-- I2c Interface with external Tri-State (InternalTriState_g = false)
		I2cScl_I	: in	std_logic	:= '0';
		I2cScl_O	: out	std_logic;
		I2cScl_T	: out	std_logic;
		I2cSda_I	: in	std_logic	:= '0';
		I2cSda_O	: out	std_logic;
		I2cSda_T	: out	std_logic
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of i2c_devreg is	

	-- *** Types ***
	type Fsm_t is (	Idle_s, UpdCheck_s, RomData_s, 
					ApplyCmd_s, WaitResp_s, 
					Start_s, Stop_s, MuxAddr_s, 
					MuxValue_s, MuxRepStart_s, 
					CmdAddr_s, CmdValue_s, CmdRepStart_s, 
					DataAddr_s, DataValue_s, DataWrRam_s);

	-- *** Constants ***
	constant UpdateToLimit_c	: integer	:= integer(ceil(UpdatePeriod_g*ClockFrequency_g))-1;
	constant RomAddrBits_c		: integer	:= log2ceil(NumOfReg_g);
	
	-- *** Two Process Method ***
	type two_process_r is record
		UpdateCnt		: integer range 0 to UpdateToLimit_c;
		RomAddr			: integer range 0 to NumOfReg_g;
		UpdatePending	: std_logic;
		Fsm				: Fsm_t;
		FsmNext			: Fsm_t;
		ToRom			: ToRom_t;
		FromRom			: FromRom_t;
		I2cCmdVld		: std_logic;
		I2cCmdType		: std_logic_vector(2 downto 0);
		I2cCmdData		: std_logic_vector(7 downto 0);
		I2cCmdAck		: std_logic;
		ByteCnt			: integer range 0 to 4;
		RecData			: std_logic_vector(31 downto 0);
		RamWr			: std_logic;
		RamAddr			: std_logic_vector(RomAddrBits_c-1 downto 0);
	end record;
	signal r, r_next : two_process_r;	
	
	-- *** Component Connection Signals ***
	signal I2cCmdRdy		: std_logic;
	signal I2cRspVld		: std_logic;
	signal I2cRspType		: std_logic_vector(2 downto 0);
	signal I2cRspData		: std_logic_vector(7 downto 0);
	signal I2cRspAck		: std_logic;
	signal I2cRspArbLost	: std_logic;
	signal I2cRspSeq		: std_logic;
	
begin

	--------------------------------------------------------------------------
	-- Combinatorial Proccess
	--------------------------------------------------------------------------
	p_comb : process(r, FromRom, UpdateTrig, UpdateEna, I2cCmdRdy, I2cRspVld, I2cRspType, I2cRspData, I2cRspAck, I2cRspArbLost, I2cRspSeq)
		variable v : two_process_r;
	begin
		-- *** hold variables stable ***
		v := r;
		
		-- *** detect update triggers ***
		-- Trigger update periodically or upon user request. 
		-- UpdatePending is reset in the FSM when the update is started.
		if UpdateEna = '0' then
			v.UpdateCnt 		:= 0;
			v.UpdatePending		:= '0';					
		else
			if (UpdateTrig = '1') or (r.UpdateCnt = UpdateToLimit_c) then
				v.UpdatePending	:= '1';	
				v.UpdateCnt 	:= 0;
			else
				v.UpdateCnt		:= r.UpdateCnt + 1;
			end if;	
		end if;
		-- TODO: Reset UpdatePending in FSM after update
		
		
		-- *** Default Values ***
		v.ToRom.Vld	:= '0';
		v.RamWr		:= '0';
		
		-- *** FSM ***
		case r.Fsm is
		
			when Idle_s =>
				v.RomAddr	:= 0;
				if r.UpdatePending = '1' then
					v.Fsm	:= UpdCheck_s;
				end if;
				
			when UpdCheck_s =>
				-- TODO: Do user triggered operations
				-- Start Update Access
				if r.UpdatePending = '1' then
					-- Next update
					if r.RomAddr /= NumOfReg_g then
						v.ToRom.Vld	:= '1';
						v.ToRom.Addr							:= (others => '0');
						v.ToRom.Addr(RomAddrBits_c-1 downto 0)	:= std_logic_vector(to_unsigned(r.RomAddr, RomAddrBits_c));
						v.Fsm := RomData_s;
						v.RomAddr := r.RomAddr + 1;
					else
						-- update is done, go back to idle
						v.UpdatePending := '0';
						v.Fsm := Idle_s;
					end if;
				-- Nothing pending, go back to idle
				else	
					v.Fsm := Idle_s;
				end if;
				
			when RomData_s =>
				if FromRom.Vld = '1' then
					v.FromRom := FromRom;
					-- TODO: Do user triggered operations
					-- Skip if it is not an auto-read
					if FromRom.AutoRead = '0' then
						v.Fsm := UpdCheck_s;
					-- Execute access otherwise
					else
						v.Fsm := Start_s;
					end if;
				end if;
				
			when ApplyCmd_s =>
				v.I2cCmdVld		:= '1';
				if (I2cCmdRdy = '1') and (r.I2cCmdVld = '1') then
					v.Fsm 		:= WaitResp_s;
					v.I2cCmdVld		:= '0';
				end if;
				
			when WaitResp_s =>
				-- TODO: Data Handling
				-- TODO: NACK Handling (different for MUX/Device!)
				if I2cRspVld = '1' then
					-- On error, try complete access again
					if (I2cRspArbLost = '1') or (I2cRspSeq = '1') then
						v.Fsm	:= Start_s;
					-- Otherwise, continue
					else
						v.Fsm	:= r.FsmNext;
					end if;
					-- For reads, receive the data
					if I2cRspType = CMD_REC then
						v.RecData	:= r.RecData(23 downto 0) & I2cRspData;
					end if;
				end if;
				
			when Start_s =>				
				v.I2cCmdType	:= CMD_START;
				v.FsmNext		:= MuxAddr_s;
				v.Fsm 			:= ApplyCmd_s;
				
			when Stop_s =>
				v.I2cCmdType	:= CMD_STOP;
				v.FsmNext		:= UpdCheck_s;
				v.Fsm 			:= ApplyCmd_s;				
				
			when MuxAddr_s =>
				-- Skip if mux is unused
				if r.FromRom.HasMux = '0' then
					v.Fsm := CmdAddr_s;
				-- Apply mux address otherwise
				else
					v.I2cCmdType	:= CMD_SEND;
					v.I2cCmdData	:= r.FromRom.MuxAddr & '0';	-- Mux is always written R/W=0
					v.FsmNext		:= MuxValue_s;
					v.Fsm 			:= ApplyCmd_s;
				end if;
				
			when MuxValue_s =>
				v.I2cCmdType	:= CMD_SEND;
				v.I2cCmdData	:= r.FromRom.MuxValue;
				v.FsmNext		:= MuxRepStart_s;
				v.Fsm 			:= ApplyCmd_s;	

			when MuxRepStart_s =>
				v.I2cCmdType	:= CMD_REPSTART;	
				v.FsmNext		:= CmdAddr_s;
				v.Fsm			:= ApplyCmd_s;
				
			when CmdAddr_s =>
				v.ByteCnt := 1;
				-- Skip if no command bytes
				if r.FromRom.CmdBytes = 0 then
					v.Fsm	:= DataAddr_s;
				-- Apply Address otherwise
				else
					v.I2cCmdType	:= CMD_SEND;					
					v.I2cCmdData	:= r.FromRom.DevAddr & '0';	-- Command is always written R/W=0
					v.FsmNext		:= CmdValue_s;
					v.Fsm 			:= ApplyCmd_s;
				end if;
			
			when CmdValue_s =>
				v.I2cCmdType		:= CMD_SEND;
				v.I2cCmdData		:= r.FromRom.CmdData(7 downto 0);
				v.FromRom.CmdData	:= X"00" & r.FromRom.CmdData(31 downto 8);
				v.Fsm 				:= ApplyCmd_s;				
				if r.ByteCnt = r.FromRom.CmdBytes then
					v.FsmNext	:= CmdRepStart_s;
				else
					v.ByteCnt	:= r.ByteCnt + 1;
					v.FsmNext	:= CmdValue_s;
				end if;
				
			when CmdRepStart_s =>
				v.I2cCmdType	:= CMD_REPSTART;	
				v.FsmNext		:= DataAddr_s;
				v.Fsm			:= ApplyCmd_s;

			when DataAddr_s =>
				v.ByteCnt 	:= 1;
				v.RecData	:= (others => '0');
				-- Skip if no data bytes
				if r.FromRom.DatBytes = 0 then
					v.Fsm	:= Stop_s;
				-- Apply Address otherwise
				else
					v.I2cCmdType	:= CMD_SEND;	
					-- TODO: Handle Write (currently always read)
					v.I2cCmdData	:= r.FromRom.DevAddr & '1';	
					v.FsmNext		:= DataValue_s;
					v.Fsm 			:= ApplyCmd_s;
				end if;				
				
			when DataValue_s =>
				-- TODO: Handle Write (currently always read)
				v.I2cCmdType		:= CMD_REC;
				v.Fsm 				:= ApplyCmd_s;				
				if r.ByteCnt = r.FromRom.DatBytes then
					v.FsmNext	:= DataWrRam_s;
					v.I2cCmdAck	:= '0';
				else
					v.ByteCnt	:= r.ByteCnt + 1;
					v.FsmNext	:= DataValue_s;
					v.I2cCmdAck	:= '1';
				end if;		

			when DataWrRam_s =>
				-- TODO: Handle Write (currently always read)
				v.Fsm 		:= Stop_s;
				v.RamWr		:= '1';
				v.RamAddr	:= r.ToRom.Addr(RomAddrBits_c-1 downto 0);
				
			when others => null;
			
		end case;	
		
		-- *** assign signal ***
		r_next <= v;
	end process;
	
	--------------------------------------------------------------------------
	-- Outputs
	--------------------------------------------------------------------------
	ToRom <= r.ToRom;

	
	--------------------------------------------------------------------------
	-- Sequential Proccess
	--------------------------------------------------------------------------
	p_seq : process(Clk)
	begin
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.UpdateCnt 		<= 0;
				r.UpdatePending		<= '0';
				r.Fsm				<= Idle_s;
				r.ToRom.Vld			<= '0';
				r.I2cCmdVld			<= '0';
				r.RamWr				<= '0';
			end if;			
		end if;
	end process;
	
	--------------------------------------------------------------------------
	-- Component Instantiations
	--------------------------------------------------------------------------	
	i_i2c : entity work.psi_common_i2c_master
		generic map ( 
			ClockFrequency_g	=> ClockFrequency_g,
			I2cFrequency_g		=> I2cFrequency_g,
			BusBusyTimeout_g	=> BusBusyTimeout_g,
			CmdTimeout_g		=> 10.0e-6,
			InternalTriState_g	=> InternalTriState_g,
			DisableAsserts_g	=> false
		)
		port map (
			Clk			=> Clk,
			Rst			=> Rst,
			CmdRdy		=> I2cCmdRdy,	
			CmdVld		=> r.I2cCmdVld,	
			CmdType		=> r.I2cCmdType,	
			CmdData		=> r.I2cCmdData,	
			CmdAck		=> r.I2cCmdAck,	
			RspVld		=> I2cRspVld,		
			RspType		=> I2cRspType,		
			RspData		=> I2cRspData,		
			RspAck		=> I2cRspAck,		
			RspArbLost	=> I2cRspArbLost,	
			RspSeq		=> I2cRspSeq,		
			BusBusy		=> BusBusy,
			TimeoutCmd	=> open,
			I2cScl		=> I2cScl,	
			I2cSda		=> I2cSda,	
			I2cScl_I	=> I2cScl_I,
			I2cScl_O	=> I2cScl_O,
			I2cScl_T	=> I2cScl_T,
			I2cSda_I	=> I2cSda_I,
			I2cSda_O	=> I2cSda_O,
			I2cSda_T	=> I2cSda_T
		);
		
	i_ram : entity work.psi_common_tdp_ram 
		generic map (
			Depth_g		=> NumOfReg_g,
			Width_g		=> 32,
			Behavior_g	=> "RBW"
		)
		port map (
			ClkA		=> Clk,
			AddrA		=> r.ToRom.Addr(log2ceil(NumOfReg_g)-1 downto 0),
			WrA			=> r.RamWr,
			DinA		=> r.RecData,
			DoutA		=> open,
			ClkB		=> Clk,
			AddrB		=> RegAddr,
			WrB			=> '0',
			DinB		=> RegDin,
			DoutB		=> RegDout
		);
		
	-- TODO: FIFO for user commands (only remove when command done)
	
	
end;





