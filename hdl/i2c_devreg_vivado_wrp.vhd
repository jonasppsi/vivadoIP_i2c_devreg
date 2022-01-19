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

library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_array_pkg.all;
	use work.i2c_devreg_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity i2c_devreg_vivado_wrp is
	generic
	(	
		-- SPI Parameters
		ClockFrequencyHz_g	: integer		:= 125_000_000;		-- in Hz		
		I2cFrequencyHz_g	: integer 		:= 100_000;			-- in Hz		
		BusBusyTimeoutUs_g	: integer		:= 1000;			-- in us		
		UpdatePeriodMs_g	: integer		:= 100;				-- in ms		
		InternalTriState_g	: boolean		:= true;		-- 				
		NumOfReg_g			: integer		:= 1024;		--				
		
		-- AXI Parameters
		C_S00_AXI_ID_WIDTH          : integer := 1;		-- Width of ID for for write address, write data, read address and read data
		C_S00_AXI_ADDR_WIDTH        : integer := 14		-- Width of S_AXI address bus	
	);
	port
	(
		-----------------------------------------------------------------------------
		-- I2C Ports
		-----------------------------------------------------------------------------
		-- I2c Interface with internal Tri-State (InternalTriState_g = true)
		I2cScl			: inout	std_logic	:= 'Z';
		I2cSda			: inout	std_logic	:= 'Z';
		
		-- I2c Interface with external Tri-State (InternalTriState_g = false)
		I2cScl_I		: in	std_logic	:= '0';
		I2cScl_O		: out	std_logic;
		I2cScl_T		: out	std_logic;
		I2cSda_I		: in	std_logic	:= '0';
		I2cSda_O		: out	std_logic;
		I2cSda_T		: out	std_logic;
		
		-----------------------------------------------------------------------------
		-- Config ROM Ports
		-----------------------------------------------------------------------------
		-- Data To ROM
		I2cRom_TValid	: out	std_logic;
		I2cRom_TData	: out	std_logic_vector(31 downto 0);
		
		-- Data From ROM
		RomI2c_TValid	: in	std_logic;
		RomI2c_TData	: in	std_logic_vector(71 downto 0);
		
		-----------------------------------------------------------------------------
		-- Parallel Ports
		-----------------------------------------------------------------------------
		UpdateTrig		: in	std_logic	:= '0';
		Irq				: out	std_logic;
		
		-----------------------------------------------------------------------------
		-- Axi Slave Bus Interface
		-----------------------------------------------------------------------------
		-- System
		s00_axi_aclk    : in    std_logic;                                             
		s00_axi_aresetn : in    std_logic;                                             
		-- Read address channel
		s00_axi_arid    : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     
		s00_axi_araddr  : in    std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);     
		s00_axi_arlen   : in    std_logic_vector(7 downto 0);                          
		s00_axi_arsize  : in    std_logic_vector(2 downto 0);                          
		s00_axi_arburst : in    std_logic_vector(1 downto 0);                          
		s00_axi_arlock  : in    std_logic;                                             
		s00_axi_arcache : in    std_logic_vector(3 downto 0);                          
		s00_axi_arprot  : in    std_logic_vector(2 downto 0);                          
		s00_axi_arvalid : in    std_logic;                                             
		s00_axi_arready : out   std_logic;                                             
		-- Read data channel
		s00_axi_rid     : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       
		s00_axi_rdata   : out   std_logic_vector(31 downto 0);                         
		s00_axi_rresp   : out   std_logic_vector(1 downto 0);                          
		s00_axi_rlast   : out   std_logic;                                             
		s00_axi_rvalid  : out   std_logic;                                             
		s00_axi_rready  : in    std_logic;                                             
		-- Write address channel
		s00_axi_awid    : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     
		s00_axi_awaddr  : in    std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);     
		s00_axi_awlen   : in    std_logic_vector(7 downto 0);                          
		s00_axi_awsize  : in    std_logic_vector(2 downto 0);                          
		s00_axi_awburst : in    std_logic_vector(1 downto 0);                          
		s00_axi_awlock  : in    std_logic;                                             
		s00_axi_awcache : in    std_logic_vector(3 downto 0);                          
		s00_axi_awprot  : in    std_logic_vector(2 downto 0);                          
		s00_axi_awvalid : in    std_logic;                                             
		s00_axi_awready : out   std_logic;                                             
		-- Write data channel
		s00_axi_wdata   : in    std_logic_vector(31    downto 0);                      
		s00_axi_wstrb   : in    std_logic_vector(3 downto 0);                          
		s00_axi_wlast   : in    std_logic;                                             
		s00_axi_wvalid  : in    std_logic;                                             
		s00_axi_wready  : out   std_logic;                                             
		-- Write response channel
		s00_axi_bid     : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       
		s00_axi_bresp   : out   std_logic_vector(1 downto 0);                          
		s00_axi_bvalid  : out   std_logic;                                             
		s00_axi_bready  : in    std_logic                                              
	);

end entity i2c_devreg_vivado_wrp;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of i2c_devreg_vivado_wrp is 

	-- Generics as real
	constant ClockFrequency_g	: real	:= real(ClockFrequencyHz_g);			-- in Hz		
	constant I2cFrequency_g		: real	:= real(I2cFrequencyHz_g);				-- in Hz		
	constant BusBusyTimeout_g	: real	:= real(BusBusyTimeoutUs_g)*1.0e-6;		-- in sec		
	constant UpdatePeriod_g		: real	:= real(UpdatePeriodMs_g)*1.0e-3;		-- in sec	

  constant SEC_COUNTER_LIMIT : integer := integer(ClockFrequency_g);

	-- Array of desired number of chip enables for each address range
	constant USER_SLV_NUM_REG   : integer              := RegIdx_Mem_c; 
	
	-- IP Interconnect 
	signal reg_rd               : std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_rdata            : t_aslv32(0 to USER_SLV_NUM_REG-1) := (others => (others => '0'));
	signal reg_wr               : std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_wdata            : t_aslv32(0 to USER_SLV_NUM_REG-1);

	signal mem_addr				: std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);							
	signal mem_wr				: std_logic_vector( 3 downto 0);											
	signal mem_wdata			: std_logic_vector(31 downto 0);											
	signal mem_rdata			: std_logic_vector(31 downto 0)	:= (others => '0');				
	
	-- Ohter Signals 
	signal AxiRst				: std_logic;
	
	-- Constants
	constant RomAddrBits_c		: integer	:= log2ceil(NumOfReg_g);
	
	-- Implementation signals
	signal UpdateTrigI			: std_logic;
	signal UpdateEnaI			: std_logic;
	signal UpdateDoneI			: std_logic;
	signal BusBusyI				: std_logic;
	signal AccessFailedI		: std_logic;
	signal AccessFailedLatch	: std_logic;
	signal RegFifoFullI			: std_logic;
	signal RegFifoEmptyI		: std_logic;
	signal FromRomEntry			: CfgRomEntry_t;
	signal RegAddrI				: std_logic_vector(RomAddrBits_c-1 downto 0);
	signal MemWrI				: std_logic;
	signal UpdateOngoingI		: std_logic;
	signal IrqI					: std_logic;
	signal IrqVecI				: std_logic_vector(31 downto 0);
	signal IrqEnaI				: std_logic_vector(31 downto 0);
	signal FifoEmptyLast		: std_logic;

  -- Statistics:
  signal BusBusyCount, BusBusyCountLatch, UpdateTrigCount, UpdateTrigCountLatch, TrigWhileBusyCount : unsigned(31 downto 0);
  signal BusBusyCountMax  : unsigned(31 downto 0);
  signal SecCounter : unsigned(31 downto 0);
  signal SecTick : std_logic;

begin

	AxiRst <= not s00_axi_aresetn;

   -----------------------------------------------------------------------------
   -- AXI decode instance
   -----------------------------------------------------------------------------
   axi_slave_reg_inst : entity work.psi_common_axi_slave_ipif
   generic map
   (
      -- Users parameters
      NumReg_g                             => USER_SLV_NUM_REG,
      UseMem_g                             => true,
      -- Parameters of Axi Slave Bus Interface
      AxiIdWidth_g                         => C_S00_AXI_ID_WIDTH,
      AxiAddrWidth_g                       => C_S00_AXI_ADDR_WIDTH
   )
   port map
   (
      --------------------------------------------------------------------------
      -- Axi Slave Bus Interface
      --------------------------------------------------------------------------
      -- System
      s_axi_aclk                  => s00_axi_aclk,
      s_axi_aresetn               => s00_axi_aresetn,
      -- Read address channel
      s_axi_arid                  => s00_axi_arid,
      s_axi_araddr                => s00_axi_araddr,
      s_axi_arlen                 => s00_axi_arlen,
      s_axi_arsize                => s00_axi_arsize,
      s_axi_arburst               => s00_axi_arburst,
      s_axi_arlock                => s00_axi_arlock,
      s_axi_arcache               => s00_axi_arcache,
      s_axi_arprot                => s00_axi_arprot,
      s_axi_arvalid               => s00_axi_arvalid,
      s_axi_arready               => s00_axi_arready,
      -- Read data channel
      s_axi_rid                   => s00_axi_rid,
      s_axi_rdata                 => s00_axi_rdata,
      s_axi_rresp                 => s00_axi_rresp,
      s_axi_rlast                 => s00_axi_rlast,
      s_axi_rvalid                => s00_axi_rvalid,
      s_axi_rready                => s00_axi_rready,
      -- Write address channel
      s_axi_awid                  => s00_axi_awid,
      s_axi_awaddr                => s00_axi_awaddr,
      s_axi_awlen                 => s00_axi_awlen,
      s_axi_awsize                => s00_axi_awsize,
      s_axi_awburst               => s00_axi_awburst,
      s_axi_awlock                => s00_axi_awlock,
      s_axi_awcache               => s00_axi_awcache,
      s_axi_awprot                => s00_axi_awprot,
      s_axi_awvalid               => s00_axi_awvalid,
      s_axi_awready               => s00_axi_awready,
      -- Write data channel
      s_axi_wdata                 => s00_axi_wdata,
      s_axi_wstrb                 => s00_axi_wstrb,
      s_axi_wlast                 => s00_axi_wlast,
      s_axi_wvalid                => s00_axi_wvalid,
      s_axi_wready                => s00_axi_wready,
      -- Write response channel
      s_axi_bid                   => s00_axi_bid,
      s_axi_bresp                 => s00_axi_bresp,
      s_axi_bvalid                => s00_axi_bvalid,
      s_axi_bready                => s00_axi_bready,
      --------------------------------------------------------------------------
      -- Register Interface
      --------------------------------------------------------------------------
      o_reg_rd                    => reg_rd,
      i_reg_rdata                 => reg_rdata,
      o_reg_wr                    => reg_wr,
      o_reg_wdata                 => reg_wdata,
	  --------------------------------------------------------------------------
	  -- Memory Interface
	  --------------------------------------------------------------------------
	  o_mem_addr				  => mem_addr,
	  o_mem_wr					  => mem_wr,
	  o_mem_wdata				  => mem_wdata,
	  i_mem_rdata  				  => mem_rdata
   );
   
	-----------------------------------------------------------------------------
	-- Wrapper Logic
	-----------------------------------------------------------------------------
	AxiRst 				<= not s00_axi_aresetn;
	FromRomEntry 		<= SlvToRomEntry(RomI2c_TData);
	
	UpdateEnaI							<= reg_wdata(RegIdx_UpdateEna_c)(0);	
	UpdateTrigI							<= UpdateTrig or (reg_wdata(RegIdx_UpdateTrig_c)(0) and reg_wr(RegIdx_UpdateTrig_c));
	IrqEnaI(BitIdx_Irq_UpdateDone_c)	<= reg_wdata(RegIdx_IrqEna_c)(BitIdx_Irq_UpdateDone_c);
	IrqEnaI(BitIdx_Irq_FifoEmpty_c)		<= reg_wdata(RegIdx_IrqEna_c)(BitIdx_Irq_FifoEmpty_c);
	
	reg_rdata(RegIdx_UpdateEna_c)(0)						<= UpdateEnaI;
	reg_rdata(RegIdx_BusBusy_c)(0)							<= BusBusyI;
  reg_rdata(RegIdx_BusBusyCount_c)					<= std_logic_vector(BusBusyCountLatch);
	reg_rdata(RegIdx_BusBusyCountMax_c)				<= std_logic_vector(BusBusyCountMax);
	reg_rdata(RegIdx_TrigWhileBusyCount_c)				<= std_logic_vector(TrigWhileBusyCount);
  reg_rdata(RegIdx_UpdateTrigCount_c)					<= std_logic_vector(UpdateTrigCountLatch);
	reg_rdata(RegIdx_AccessFailed_c)(0)						<= AccessFailedLatch;
	reg_rdata(RegIdx_FifoState_c)(BitIdx_FifoState_Empty_c)	<= RegFifoEmptyI;
	reg_rdata(RegIdx_FifoState_c)(BitIdx_FifoState_Full_c)	<= RegFifoFullI;
	reg_rdata(RegIdx_UpdateOngoing_c)(0)					<= UpdateOngoingI;
	reg_rdata(RegIdx_IrqEna_c)(BitIdx_Irq_UpdateDone_c)		<= IrqEnaI(BitIdx_Irq_UpdateDone_c);
	reg_rdata(RegIdx_IrqEna_c)(BitIdx_Irq_FifoEmpty_c)		<= IrqEnaI(BitIdx_Irq_FifoEmpty_c);
	reg_rdata(RegIdx_IrqVec_c)								<= IrqVecI;
	
	p_fail_latch : process(s00_axi_aclk)
	begin
		if rising_edge(s00_axi_aclk) then
			if AxiRst = '1' then
				AccessFailedLatch <= '0';
			else	
				if AccessFailedI = '1' then
					AccessFailedLatch <= '1';
				elsif (reg_wdata(RegIdx_AccessFailed_c)(0) = '1') and (reg_wr(RegIdx_AccessFailed_c) = '1') then
					AccessFailedLatch <= '0';
				end if;
			end if;
		end if;
	end process;
	
	p_irq : process(s00_axi_aclk)
	begin
		if rising_edge(s00_axi_aclk) then
			if AxiRst = '1' then
				IrqVecI <= (others => '0');
				IrqI <= '0';
				FifoEmptyLast <= '0';
			else
				if UpdateDoneI = '1' then
					IrqVecI(BitIdx_Irq_UpdateDone_c) <= '1';
				elsif reg_wdata(RegIdx_IrqVec_c)(BitIdx_Irq_UpdateDone_c) = '1' and reg_wr(RegIdx_IrqVec_c) = '1' then
					IrqVecI(BitIdx_Irq_UpdateDone_c) <= '0';
				end if;
				
				FifoEmptyLast <= RegFifoEmptyI;
				if (RegFifoEmptyI = '1') and (FifoEmptyLast = '0') then
					IrqVecI(BitIdx_Irq_FifoEmpty_c) <= '1';
				elsif reg_wdata(RegIdx_IrqVec_c)(BitIdx_Irq_FifoEmpty_c) = '1' and reg_wr(RegIdx_IrqVec_c) = '1' then 
					IrqVecI(BitIdx_Irq_FifoEmpty_c) <= '0';
				end if;
				
				if unsigned(IrqVecI and IrqEnaI) /= 0 then
					IrqI <= '1';
				else
					IrqI <= '0';
				end if;
			end if;
		end if;
	end process;
	
	RegAddrI <= mem_addr(RomAddrBits_c+1 downto 2) when reg_wr(RegIdx_ForceRead_c) = '0' else reg_wdata(RegIdx_ForceRead_c)(RomAddrBits_c-1 downto 0);
	
	MemWrI <= '1' when mem_wr /= "0000" else '0';
	
	Irq <= IrqI;

  --------------------------------------------------------------------------
  -- Statistics Counters
  --------------------------------------------------------------------------
  blk_stat : block
  begin

    p_stat : process(s00_axi_aclk)
    begin

      if rising_edge(s00_axi_aclk) then
        -- 1 Sec Counter:
        SecTick <= '0';
        if (SecCounter = SEC_COUNTER_LIMIT-1) then
          SecCounter <= (others=>'0');
          SecTick <= '1';
        else 
          SecCounter <= SecCounter + 1;
        end if;

        if (BusBusyI = '1' and std_logic_vector(BusBusyCount) /= x"FFFFFFFF") then
          BusBusyCount <= BusBusyCount + 1;
        end if;
   
        -- Max Busy Time:
        if (BusBusyCount > BusBusyCountMax) then
          BusBusyCountMax <= BusBusyCount;
        end if;

        if (SecTick = '1') then
        --if (UpdateTrigI = '1') then
          BusBusyCountLatch <= BusBusyCount;
          UpdateTrigCountLatch <= UpdateTrigCount;
          BusBusyCount <= (others=>'0');
          UpdateTrigCount <= (others=>'0');
        end if;

        if (UpdateTrigI = '1')  then
          UpdateTrigCount <= UpdateTrigCount + 1;
        end if;

        if (UpdateTrigI = '1' and BusBusyI = '1')  then
          TrigWhileBusyCount <= TrigWhileBusyCount + 1;
        end if;

        if (reg_wdata(RegIdx_BusBusyCountMax_c)(0) = '1' and reg_wr(RegIdx_BusBusyCountMax_c) = '1') then
          BusBusyCountMax <= (others=>'0');
        end if;

        if (reg_wdata(RegIdx_TrigWhileBusyCount_c)(0) = '1' and reg_wr(RegIdx_TrigWhileBusyCount_c) = '1') then
          TrigWhileBusyCount <= (others=>'0');
        end if;
      end if;
    end process;

  end block;

	-----------------------------------------------------------------------------
	-- Implementation
	-----------------------------------------------------------------------------
	I2cRom_TData(I2cRom_TData'high downto RomAddrBits_c) <= (others => '0');
 	i_regdev : entity work.i2c_devreg
		generic map (
			ClockFrequency_g	=> ClockFrequency_g,
			I2cFrequency_g		=> I2cFrequency_g,
			BusBusyTimeout_g	=> BusBusyTimeout_g,
			UpdatePeriod_g		=> UpdatePeriod_g,
			InternalTriState_g	=> InternalTriState_g,
			NumOfReg_g			=> NumOfReg_g
		)
		port map (
			-- Control Signals
			Clk				=> s00_axi_aclk,
			Rst				=> AxiRst,
			
			-- ROM Connection
			ToRomVld		=> I2cRom_TValid,
			ToRomAddr		=> I2cRom_TData(RomAddrBits_c-1 downto 0),
			FromRomVld		=> RomI2c_TValid,
			FromRomEntry	=> FromRomEntry,
			
			-- Parallel Signals
			UpdateTrig		=> UpdateTrigI,
			UpdateEna		=> UpdateEnaI,
			UpdateDone		=> UpdateDoneI,
			UpdateOngoing 	=> UpdateOngoingI,
			BusBusy			=> BusBusyI,
			AccessFailed	=> AccessFailedI,

			-- Reg Access
			RegAddr			=> RegAddrI,
			RegI2cWrite		=> MemWrI,
			RegI2cRead		=> reg_wr(8),
			RegDout			=> mem_rdata,
			RegDin			=> mem_wdata,
			RegFifoFull		=> RegFifoFullI,
			RegFifoEmpty	=> RegFifoEmptyI,
			
			-- I2c Interface with internal Tri-State (InternalTriState_g = true)
			I2cScl			=> I2cScl,
			I2cSda			=> I2cSda,
			
			-- I2c Interface with external Tri-State (InternalTriState_g = false)
			I2cScl_I		=> I2cScl_I,
			I2cScl_O		=> I2cScl_O,
			I2cScl_T		=> I2cScl_T,
			I2cSda_I		=> I2cSda_I,
			I2cSda_O		=> I2cSda_O,
			I2cSda_T		=> I2cSda_T
		);
  
end rtl;
