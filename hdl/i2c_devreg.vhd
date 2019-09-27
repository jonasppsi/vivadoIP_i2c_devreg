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
		Clk				: in	std_logic;		-- $$ type=clk; freq=125e6 $$
		Rst				: in	std_logic;	    -- $$ type=rst; clk=Clk $$
		
		-- Config Rom Interface
		ToRom			: out	ToRom_t;
		FromRom			: in	FromRom_t;
		
		-- Parallel Interface
		UpdateTrig		: in	std_logic;
		UpdateEna		: in	std_logic	:= '1';	
		UpdateDone		: out	std_logic;			-- Pulse when update cycle completed
		BusBusy			: out 	std_logic;	
		AccessFailed	: out	std_logic;			-- Pulse if an access failed

		-- Reg Access
		RegAddr			: in	std_logic_vector(log2ceil(NumOfReg_g)-1 downto 0);
		RegI2cWrite		: in	std_logic;
		RegI2cRead		: in	std_logic;
		RegDout			: out	std_logic_vector(31 downto 0);
		RegDin			: in	std_logic_vector(31 downto 0);
		RegFifoFull		: out	std_logic;
		RegFifoEmpty	: out	std_logic;
		
		-- I2c Interface with internal Tri-State (InternalTriState_g = true)
		I2cScl			: inout	std_logic	:= 'Z';
		I2cSda			: inout	std_logic	:= 'Z';
		
		-- I2c Interface with external Tri-State (InternalTriState_g = false)
		I2cScl_I		: in	std_logic	:= '0';
		I2cScl_O		: out	std_logic;
		I2cScl_T		: out	std_logic;
		I2cSda_I		: in	std_logic	:= '0';
		I2cSda_O		: out	std_logic;
		I2cSda_T		: out	std_logic
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
					DataAddr_s, DataValue_s, DataEnd_s);

	-- *** Constants ***
	constant UpdateToLimit_c	: integer	:= integer(ceil(UpdatePeriod_g*ClockFrequency_g))-1;
	constant RomAddrBits_c		: integer	:= log2ceil(NumOfReg_g);
	constant I2cRetrys_c		: integer	:= 1;
	constant OpFifoDepth_c		: integer	:= 256;
	
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
		ByteCnt			: integer range 0 to 3;
		RecData			: std_logic_vector(31 downto 0);
		RamWr			: std_logic;
		RamAddr			: std_logic_vector(RomAddrBits_c-1 downto 0);
		RamData			: std_logic_vector(31 downto 0);
		UpdateDone		: std_logic;
		RetryCnt		: integer range 0 to I2cRetrys_c;
		RetryAfterStop	: std_logic;
		FifoPop			: std_logic;
		IsFifoOperation	: std_logic;
		WriteData		: std_logic_vector(31 downto 0);
		IsWriteAccess	: std_logic;
		AccessFailed	: std_logic;
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
	signal FifoEmptyI		: std_logic;	
	signal FifoAddr			: std_logic_vector(RomAddrBits_c-1 downto 0);
	signal FifoIsRead		: std_logic;
	signal FifoData			: std_logic_vector(31 downto 0);
begin

	--------------------------------------------------------------------------
	-- Combinatorial Proccess
	--------------------------------------------------------------------------
	p_comb : process(	r, FromRom, UpdateTrig, UpdateEna, 
						I2cCmdRdy, I2cRspVld, I2cRspType, I2cRspData, I2cRspAck, I2cRspArbLost, I2cRspSeq, 
						FifoEmptyI, FifoAddr, FifoIsRead, FifoData)
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
		
		-- *** Default Values ***
		v.ToRom.Vld		:= '0';
		v.RamWr			:= '0';
		v.UpdateDone	:= '0';
		v.FifoPop		:= '0';
		v.AccessFailed := '0';
		
		-- *** FSM ***
		case r.Fsm is
		
			---------------------------------------------------------------------
			-- Idles
			---------------------------------------------------------------------
			when Idle_s =>
				v.RomAddr	:= 0;
				if (r.UpdatePending = '1') or (FifoEmptyI = '0') then
					v.Fsm	:= UpdCheck_s;
				end if;

			---------------------------------------------------------------------
			-- Initiate Access
			---------------------------------------------------------------------				
			when UpdCheck_s =>
				v.IsFifoOperation := '0';
				v.IsWriteAccess := '0';
				-- User triggered operations have priority
				if FifoEmptyI = '0' then
					v.ToRom.Vld								:= '1';
					v.ToRom.Addr							:= (others => '0');
					v.ToRom.Addr(RomAddrBits_c-1 downto 0)	:= FifoAddr;
					v.Fsm 									:= RomData_s;
					v.WriteData								:= FifoData;
					v.IsFifoOperation						:= '1';
					v.IsWriteAccess							:= not FifoIsRead;
				-- Start Update Access
				elsif r.UpdatePending = '1' then
					-- Next update
					if r.RomAddr /= NumOfReg_g then
						v.ToRom.Vld								:= '1';
						v.ToRom.Addr							:= (others => '0');
						v.ToRom.Addr(RomAddrBits_c-1 downto 0)	:= std_logic_vector(to_unsigned(r.RomAddr, RomAddrBits_c));
						v.Fsm 									:= RomData_s;
						v.RomAddr 								:= r.RomAddr + 1;
					else
						-- update is done, go back to idle
						v.UpdatePending := '0';
						v.Fsm 			:= Idle_s;
						v.UpdateDone 	:= '1';
					end if;
				-- Nothing pending, go back to idle
				else	
					v.Fsm := Idle_s;
				end if;
				
			when RomData_s =>
				v.RetryCnt 			:= 0;
				v.RetryAfterStop 	:= '0';
				if FromRom.Vld = '1' then
					v.FromRom := FromRom;
					-- Skip if it is not an auto-read and not a user operation
					if (FromRom.AutoRead = '0') and (r.IsFifoOperation = '0') then
						v.Fsm := UpdCheck_s;
					-- Execute access otherwise
					else
						v.Fsm := Start_s;
					end if;
				end if;

			---------------------------------------------------------------------
			-- Repeatedly used command application
			---------------------------------------------------------------------				
			when ApplyCmd_s =>
				v.I2cCmdVld		:= '1';
				if (I2cCmdRdy = '1') and (r.I2cCmdVld = '1') then
					v.Fsm 		:= WaitResp_s;
					v.I2cCmdVld		:= '0';
				end if;
				
			when WaitResp_s =>
				if I2cRspVld = '1' then
					-- On error, try complete access again
					if (I2cRspArbLost = '1') or (I2cRspSeq = '1') then
						v.Fsm	:= Start_s;
					-- Handle receive NACK
					elsif (I2cRspType = CMD_SEND) and (I2cRspAck = '0') then
						-- Fail if retry did not work otherwise
						if r.RetryCnt = I2cRetrys_c then
							v.RetryAfterStop 	:= '0';
							v.Fsm 				:= DataEnd_s;
							v.AccessFailed		:= '1';
						-- Retry otherwise
						else
							v.RetryAfterStop 	:= '1';
							v.RetryCnt 			:= r.RetryCnt + 1;
							v.Fsm	:= Stop_s; 
						end if;								
					-- Otherwise, continue
					else
						v.Fsm	:= r.FsmNext;
					end if;
					-- For reads, receive the data
					if I2cRspType = CMD_REC then
						v.RecData	:= r.RecData(23 downto 0) & I2cRspData;
					end if;
				end if;
				
			---------------------------------------------------------------------
			-- Start / Stop
			---------------------------------------------------------------------
			when Start_s =>				
				v.I2cCmdType	:= CMD_START;
				v.FsmNext		:= MuxAddr_s;
				v.Fsm 			:= ApplyCmd_s;
				
			when Stop_s =>
				v.I2cCmdType	:= CMD_STOP;
				-- Retry Handling
				if r.RetryAfterStop = '1' then
					v.FsmNext		:= Start_s;
				-- Else go check for next operation
				else
					v.FsmNext		:= UpdCheck_s;
				end if;	
				v.RetryAfterStop 	:= '0'; -- clear flag to be in correct state for next cycle
				v.Fsm 			:= ApplyCmd_s;				

			---------------------------------------------------------------------
			-- MUX Handling
			---------------------------------------------------------------------				
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
				
			---------------------------------------------------------------------
			-- Command Handling
			---------------------------------------------------------------------				
			when CmdAddr_s =>				
				-- Skip if no command bytes
				if r.FromRom.CmdBytes = 0 then
					v.Fsm	:= DataAddr_s;
				-- Apply Address otherwise
				else
					v.ByteCnt := r.FromRom.CmdBytes-1;
					v.I2cCmdType	:= CMD_SEND;					
					v.I2cCmdData	:= r.FromRom.DevAddr & '0';	-- Command is always written R/W=0
					v.FsmNext		:= CmdValue_s;
					v.Fsm 			:= ApplyCmd_s;
				end if;
			
			when CmdValue_s =>
				v.I2cCmdType		:= CMD_SEND;
				v.I2cCmdData		:= r.FromRom.CmdData(r.ByteCnt*8+7 downto r.ByteCnt*8);
				v.Fsm 				:= ApplyCmd_s;				
				if r.ByteCnt = 0 then
					v.FsmNext	:= CmdRepStart_s;
				else
					v.ByteCnt	:= r.ByteCnt - 1;
					v.FsmNext	:= CmdValue_s;
				end if;
				
			when CmdRepStart_s =>
				v.I2cCmdType	:= CMD_REPSTART;	
				v.FsmNext		:= DataAddr_s;
				v.Fsm			:= ApplyCmd_s;

			---------------------------------------------------------------------
			-- Data Handling
			---------------------------------------------------------------------
			when DataAddr_s =>
				v.RecData	:= (others => '0');
				-- Skip if no data bytes
				if r.FromRom.DatBytes = 0 then
					v.Fsm	:= Stop_s;
				-- Apply Address otherwise
				else
					v.ByteCnt := r.FromRom.DatBytes-1;
					v.I2cCmdType	:= CMD_SEND;	
					v.I2cCmdData	:= r.FromRom.DevAddr & not r.IsWriteAccess;	
					v.FsmNext		:= DataValue_s;
					v.Fsm 			:= ApplyCmd_s;
				end if;				
				
			when DataValue_s =>
				-- Write 
				if r.IsWriteAccess = '1' then
					v.I2cCmdType		:= CMD_SEND;
					v.I2cCmdData		:= r.WriteData(r.ByteCnt*8+7 downto r.ByteCnt*8);
				-- Read
				else
					v.I2cCmdType		:= CMD_REC;
				end if;
				
				-- Otherwise it is a read (either periodic or from FIFO)			
				v.Fsm 				:= ApplyCmd_s;				
				if r.ByteCnt = 0 then
					v.FsmNext	:= DataEnd_s;
					v.I2cCmdAck	:= '0'; -- for writes, ACK has no effect. So we can always set it
				else
					v.ByteCnt	:= r.ByteCnt - 1;
					v.FsmNext	:= DataValue_s;
					v.I2cCmdAck	:= '1';
				end if;		

			---------------------------------------------------------------------
			-- End of Transfer handling
			---------------------------------------------------------------------
			when DataEnd_s =>
				v.Fsm 		:= Stop_s;
				-- Write FFFF... for failing accesses
				if r.AccessFailed = '1' then
					v.RamData := (others => '1');
				-- Writes
				elsif r.IsWriteAccess = '1' then
					v.RamData	:= r.WriteData;
				-- Otherwise it is a read, so write received data
				else
					v.RamData	:= r.RecData;
				end if;
				v.RamWr		:= '1';
				v.RamAddr	:= r.ToRom.Addr(RomAddrBits_c-1 downto 0);
				-- Remove data from FIFO after operation if it was a FIFO operation 
				-- ... this is only possible after the operation since data may be used for retrys 
				if r.IsFifoOperation = '1' then
					v.FifoPop := '1';
				end if;
				
			when others => null;
			
		end case;	
		
		-- *** assign signal ***
		r_next <= v;
	end process;
	
	--------------------------------------------------------------------------
	-- Outputs
	--------------------------------------------------------------------------
	ToRom <= r.ToRom;
	UpdateDone <= r.UpdateDone;
	RegFifoEmpty <= FifoEmptyI;
	AccessFailed <= r.AccessFailed;
	
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
				r.UpdateDone		<= '0';
				r.FifoPop			<= '0';
			end if;			
		end if;
	end process;
	
	--------------------------------------------------------------------------
	-- Component Instantiations
	--------------------------------------------------------------------------
	
	-- I2c Master
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
		
	-- RAM for register content
	i_ram : entity work.psi_common_tdp_ram 
		generic map (
			Depth_g		=> NumOfReg_g,
			Width_g		=> 32,
			Behavior_g	=> "RBW"
		)
		port map (
			ClkA		=> Clk,
			AddrA		=> r.ToRom.Addr(RomAddrBits_c-1 downto 0),
			WrA			=> r.RamWr,
			DinA		=> r.RamData,
			DoutA		=> open,
			ClkB		=> Clk,
			AddrB		=> RegAddr,
			WrB			=> '0',
			DinB		=> (others => '0'),
			DoutB		=> RegDout
		);
		
	-- User Command FIFO
	b_fifo : block 
		constant Idx_Read_c		: integer	:= 0;
		subtype Rng_Addr_c is natural range RomAddrBits_c+Idx_Read_c downto Idx_Read_c+1;
		subtype Rng_Data_c is natural range 32+Rng_Addr_c'high downto Rng_Addr_c'high+1;
		signal FifoWrite		: std_logic;
		signal FifoInData		: std_logic_vector(Rng_Data_c'high downto 0);
		signal FifoOutData		: std_logic_vector(FifoInData'range);
	begin
		-- Input assembly
		FifoWrite 				<= RegI2cWrite or RegI2cRead;
		FifoInData(Idx_Read_c) 	<= RegI2cRead;
		FifoInData(Rng_Addr_c)	<= RegAddr;
		FifoInData(Rng_Data_c)	<= RegDin;
		
		-- Instantiation
		i_fifo : entity work.psi_common_sync_fifo
			generic map (
				Width_g			=> Rng_Data_c'high+1,
				Depth_g			=> OpFifoDepth_c,
				AlmFullOn_g		=> false,
				AlmEmptyOn_g	=> false,
				RamBehavior_g	=> "RBW"
			)
			port map (
				Clk			=> Clk,
				Rst			=> Rst,
				InData		=> FifoInData,
				InVld		=> FifoWrite,
				OutData		=> FifoOutData,
				OutRdy		=> r.FifoPop,
				Full		=> RegFifoFull,
				Empty		=> FifoEmptyI
			);
			
		-- Output decoding
		FifoIsRead	<= FifoOutData(Idx_Read_c);
		FifoAddr 	<= FifoOutData(Rng_Addr_c);
		FifoData	<= FifoOutData(Rng_Data_c);
	end block;
	
	
end;





