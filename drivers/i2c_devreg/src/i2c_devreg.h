/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#pragma once

//*******************************************************************************
// Includes
//*******************************************************************************
#include <stdint.h>
#include <stdbool.h>

//*******************************************************************************
// Definitions
//*******************************************************************************
// Return codes
typedef enum I2cDevReg_ErrCode
{
	I2cDevReg_Success = 0,
	I2cDevReg_FifoFull = -1,
} I2cDevReg_ErrCode;

// Register
#define I2C_DEVREG_REG_UPDATE_ENA			0x00
#define I2C_DEVREG_REG_UPDATE_TRIG			0x04
#define I2C_DEVREG_REG_BUS_BUSY				0x10
#define I2C_DEVREG_REG_ACCESS_FAILED		0x14
#define I2C_DEVREG_REG_FIFO_STATE			0x18
#define I2C_DEVREG_REG_UPDATE_ONGOING		0x1C
#define I2C_DEVREG_REG_FORCE_READ			0x20
#define I2C_DEVREG_MEM_OFFS					0x40

// FIFO state Bitmasks
#define I2C_DEVREG_FIFO_STATE_EMPTY 		(1 << 0)
#define I2C_DEVREG_FIFO_STATE_FULL 			(1 << 8)


//*******************************************************************************
// Access Functions
//*******************************************************************************
/**
 * Enable / disable updating of the shadowed registers. If disabled, neither the 
 * UpdateTrig port nor the I2cDevReg_DoUpdate() function can trigger an update.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param ena			True = enable update, False = disable update
 */
I2cDevReg_ErrCode I2cDevReg_UpdateEnable(const uint32_t baseAddr, const bool ena);

/**
 * Go through all registers and update the value of all registers that have
 * auto update enabled.
 *
 * @param baseAddr		Base address of the IP component to access
 */
I2cDevReg_ErrCode I2cDevReg_DoUpdate(const uint32_t baseAddr);

/**
 * Check if the fail flag was set. Note that the flag must be reset manually using
 * I2cDevReg_ResetFail().
 *
 * @param baseAddr		Base address of the IP component to access
 * @param flag_p		Result: True = an access failure occured, False = no access failure occured
 */
I2cDevReg_ErrCode I2cDevReg_CheckFail(const uint32_t baseAddr, bool* const flag_p);

/**
 * Reset the fail flag.
 *
 * @param baseAddr		Base address of the IP component to access
 */
I2cDevReg_ErrCode I2cDevReg_ResetFail(const uint32_t baseAddr);

/**
 * Write to an I2C device register.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param idx			Index of the register (number of the ROM entry)
 * @param value			Value to write. Depending on the ROM entry, only the lower byte(s) may be used.
 */
I2cDevReg_ErrCode I2cDevReg_RegWrite(const uint32_t baseAddr, const uint32_t idx, const uint32_t value);

/**
 * Get mirrored I2C device register value.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param idx			Index of the register (number of the ROM entry)
 * @param value_p		Read value. Depending on the ROM entry, only the lower byte(s) may be used.
 */
I2cDevReg_ErrCode I2cDevReg_RegGet(const uint32_t baseAddr, const uint32_t idx, uint32_t* const value_p);

/**
 * Force read to an I2C device register outside of the normal update procedure.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param idx			Index of the register (number of the ROM entry)
 */
I2cDevReg_ErrCode I2cDevReg_RegReadback(const uint32_t baseAddr, const uint32_t idx);

/**
 * Check if the user action FIFO is empty (i.e. if all I2cDevReg_RegWrite() and I2cDevReg_RegReadback()
 * are completed and corresponding results are reflected in the mirrored register values).
 *
 * @param baseAddr		Base address of the IP component to access
 * @param isEmpty_p		Result: True = FIFO is empty, False = FIFO is not empty
 */
I2cDevReg_ErrCode I2cDevReg_IsFifoEmpty(const uint32_t baseAddr, bool* const isEmpty_p);

/**
 * Check if the user action FIFO is full (i.e. if no more I2cDevReg_RegWrite() and I2cDevReg_RegReadback()
 * operations can be started at the moment).
 *
 * @param baseAddr		Base address of the IP component to access
 * @param isFull_p		Result: True = FIFO is full, False = FIFO is not full
 */
I2cDevReg_ErrCode I2cDevReg_IsFifoFull(const uint32_t baseAddr, bool* const isFull_p);



