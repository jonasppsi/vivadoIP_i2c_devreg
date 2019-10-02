/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

//*******************************************************************************
// Includes
//*******************************************************************************
#include <stdio.h>
#include <xparameters.h>
#include <stdbool.h>
#include <xscugic.h>
#include <sleep.h>
#include <xil_cache.h>
#include <i2c_devreg.h>
#include "../../../../../IpRepo/refdes_rom/inc/example_rom_regs.h"

//*******************************************************************************
// Static variables
//*******************************************************************************
static XScuGic gicInst;


//*******************************************************************************
// Interrupt handling
//*******************************************************************************

//Xilinx IRQ handler, just call the psi_ms_daq IRQ handler
void IrqHandler(void* arg)
{
	//Clear vector
	uint32_t vec;
	I2cDevReg_IrqGetVec(XPAR_I2C_DEVREG_0_BASEADDR, &vec);
	I2cDevReg_IrqClear(XPAR_I2C_DEVREG_0_BASEADDR, vec);

	//Handle IRQ
	printf("\nIrq received\n");
	uint32_t value;
	//The part number is constant
	I2cDevReg_RegGet(XPAR_I2C_DEVREG_0_BASEADDR, ZCU102_I2C1_SI5341_PARTNUMBER, &value);
	printf("Part Number: %04x\n", value);
	//This register is modfied with every IRQ
	I2cDevReg_RegGet(XPAR_I2C_DEVREG_0_BASEADDR, ZCU102_I2C1_SI5341_LOSIN_MASK, &value);
	printf("Counter Register: %d\n", value);
	I2cDevReg_RegWrite(XPAR_I2C_DEVREG_0_BASEADDR, ZCU102_I2C1_SI5341_LOSIN_MASK, value+1);
}

//*******************************************************************************
// Initialization
//*******************************************************************************
void Init()
{
	//Interrupt Controller
	printf("Initialize Interrupt Controller\n");
	XScuGic_Config *IntcConfig;
	IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
	XScuGic_CfgInitialize(&gicInst, IntcConfig, IntcConfig->CpuBaseAddress);
	XScuGic_Disable(&gicInst, XPAR_FABRIC_I2C_DEVREG_0_IRQ_INTR);
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(	XIL_EXCEPTION_ID_INT,
									(Xil_ExceptionHandler) XScuGic_InterruptHandler,
									&gicInst);
	XScuGic_SetPriorityTriggerType(&gicInst, XPAR_FABRIC_I2C_DEVREG_0_IRQ_INTR, 0xA0, 0x1);	//0x1 = level sensitive IRQ, 0xA0 is default priority
	XScuGic_Connect(&gicInst, XPAR_FABRIC_I2C_DEVREG_0_IRQ_INTR, IrqHandler, NULL);
	XScuGic_Enable(&gicInst, XPAR_FABRIC_I2C_DEVREG_0_IRQ_INTR);
	Xil_ExceptionEnable();

	//i2c_devreg
	printf("Initialize i2c_devreg\n");
	I2cDevReg_UpdateEnable(XPAR_I2C_DEVREG_0_BASEADDR, true);
	I2cDevReg_IrqEnable(XPAR_I2C_DEVREG_0_BASEADDR, I2C_DEVREG_IRQ_UPD);

	printf("Initialization done\n");
	usleep(100000);

}


//*******************************************************************************
// Main Loop
//*******************************************************************************
int main()
{
	//*** Initialization ***
	printf("*** Hello from i2c_devreg RefDesign! ***\n");
	Init();

	while(true){

	}

	return 0;
}

										


