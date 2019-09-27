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
		ClockFrequency_g	: real		:= 125.0e6;		-- in Hz		
		I2cFrequency_g		: real 		:= 100.0e3;		-- in Hz		
		BusBusyTimeout_g	: real		:= 1.0e-3;		-- in sec		
		UpdatePeriod_g		: real		:= 100.0e-3;	-- in sec		
		InternalTriState_g	: boolean	:= true;		-- 				
		NumOfReg_g			: integer	:= 1024;		--				
		
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
		ToRom_TValid	: out	std_logic;
		ToRom_TData		: out	std_logic_vector(31 downto 0);
		
		-- Data From ROM
		FromRom_TValid	: in	std_logic;
		FromRom_TData	: in	std_logic_vector(63 downto 0);
		
		-----------------------------------------------------------------------------
		-- Parallel Ports
		-----------------------------------------------------------------------------
		UpdateTrig		: in	std_logic	:= '0';
		
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

	-- Array of desired number of chip enables for each address range
	constant USER_SLV_NUM_REG   : integer              := 32; 
	
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
	
	-- Implementation signals
	signal FromRom				: FromRom_t;
	signal ToRom				: ToRom_t;
	signal UpdateTrigI			: std_logic;
	signal UpdateEnaI			: std_logic;
	signal BusBusyI				: std_logic;
	signal AccessFailedI		: std_logic;
	signal AccessFailedLatch	: std_logic;
	signal IsWriteI				: std_logic;
	signal IsReadUpdateI		: std_logic;
	signal RegFifoFullI			: std_logic;
	signal RegFifoEmptyI		: std_logic;
	
	
	-- Constants
	constant RomAddrBits_c		: integer	:= log2ceil(NumOfReg_g);
	
	

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
	AxiRst <= not s00_axi_aresetn;
	ToRom_TValid 	<= ToRom.Vld;
	ToRom_TData 	<= ToRom.Addr;
	FromRom 		<= SlvToFromRom(FromRom_TData, FromRom_TValid);
	
	UpdateEnaI		<= reg_wdata(0)(0);
	UpdateTrigI		<= UpdateTrigI or (reg_wdata(1)(0) and reg_wr(1));
	
	reg_rdata(4)(0)	<= BusBusyI;
	reg_rdata(5)(0)	<= AccessFailedLatch;
	reg_rdata(6)(0)	<= RegFifoEmptyI;
	reg_rdata(7)(8)	<= RegFifoFullI;
	
	p_fail_latch : process(s00_axi_aclk)
	begin
		if rising_edge(s00_axi_aclk) then
			if AxiRst = '1' then
				AccessFailedLatch <= '0';
			else	
				if AccessFailedI = '1' then
					AccessFailedLatch <= '1';
				elsif (reg_wdata(5)(0) = '1') and (reg_wr(5) = '1') then
					AccessFailedLatch <= '0';
				end if;
			end if;
		end if;
	end process;
	
	IsWriteI		<= '1' when mem_addr(RomAddrBits_c+1 downto RomAddrBits_c) = "01" else '0';
	IsReadUpdateI	<= '1' when mem_addr(RomAddrBits_c+1 downto RomAddrBits_c) = "10" else '0';
   
	-----------------------------------------------------------------------------
	-- Implementation
	----------------------------------------------------------------------------- 
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
			ToRom			=> ToRom,
			FromRom			=> FromRom,
			
			-- Parallel Signals
			UpdateTrig		=> UpdateTrigI,
			UpdateEna		=> UpdateEnaI,
			UpdateDone		=> open,
			BusBusy			=> BusBusyI,
			AccessFailed	=> AccessFailedI,

			-- Reg Access
			RegAddr			=> mem_addr(RomAddrBits_c-1 downto 0),
			RegI2cWrite		=> IsWriteI,
			RegI2cRead		=> IsReadUpdateI,
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
