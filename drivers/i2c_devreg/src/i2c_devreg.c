/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#include "i2c_devreg.h"
#include <xil_io.h>

//*******************************************************************************
// Helper Functions
//*******************************************************************************
// None


//*******************************************************************************
// Access Functions
//*******************************************************************************

I2cDevReg_ErrCode I2cDevReg_UpdateEnable(const uint32_t baseAddr, const bool ena)
{
	Xil_Out32(baseAddr + I2C_DEVREG_REG_UPDATE_ENA, (ena ? 1 : 0));
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_DoUpdate(const uint32_t baseAddr)
{
	Xil_Out32(baseAddr + I2C_DEVREG_REG_UPDATE_TRIG, 1);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_CheckFail(const uint32_t baseAddr, bool* const flag_p)
{
	uint32_t rdVal = Xil_In32(baseAddr + I2C_DEVREG_REG_ACCESS_FAILED);
	*flag_p = (rdVal != 0);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_ResetFail(const uint32_t baseAddr)
{
	Xil_Out32(baseAddr + I2C_DEVREG_REG_ACCESS_FAILED, 1);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_RegWrite(const uint32_t baseAddr, const uint32_t idx, const uint32_t value)
{
	//Check if FIFO is full
	bool isFull;
	I2cDevReg_IsFifoFull(baseAddr, &isFull);
	if (isFull) {
		return I2cDevReg_FifoFull;
	}
	//Implementation
	Xil_Out32(baseAddr + I2C_DEVREG_MEM_OFFS + idx*4, value);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_RegGet(const uint32_t baseAddr, const uint32_t idx, uint32_t* const value_p)
{
	*value_p = Xil_In32(baseAddr + I2C_DEVREG_MEM_OFFS + idx*4);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_RegReadback(const uint32_t baseAddr, const uint32_t idx)
{
	//Check if FIFO is full
	bool isFull;
	I2cDevReg_IsFifoFull(baseAddr, &isFull);
	if (isFull) {
		return I2cDevReg_FifoFull;
	}
	//Implementation
	Xil_Out32(baseAddr + I2C_DEVREG_REG_FORCE_READ, idx);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_IsFifoEmpty(const uint32_t baseAddr, bool* const isEmpty_p)
{
	uint32_t rdVal = Xil_In32(baseAddr + I2C_DEVREG_REG_FIFO_STATE);
	*isEmpty_p = ((rdVal & I2C_DEVREG_FIFO_STATE_EMPTY) != 0);
	return I2cDevReg_Success;
}

I2cDevReg_ErrCode I2cDevReg_IsFifoFull(const uint32_t baseAddr, bool* const isFull_p)
{
	uint32_t rdVal = Xil_In32(baseAddr + I2C_DEVREG_REG_FIFO_STATE);
	*isFull_p = ((rdVal & I2C_DEVREG_FIFO_STATE_FULL) != 0);
	return I2cDevReg_Success;
}
