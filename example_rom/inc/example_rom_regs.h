#pragma once

// <<START_GENERATED>>

/* LM73, (0x48, No Mux) */
#define EXAMPLE_I2C_LM73_TEMPERATURE             0x00000000 // DataBytes = 2, CmdBytes = 1, Cmd = 0x00000000, AutoRead = True, AutoWrite = False
#define EXAMPLE_I2C_LM73_CONFIG                  0x00000001 // DataBytes = 1, CmdBytes = 1, Cmd = 0x00000001, AutoRead = False, AutoWrite = False
/* LM73 behind Mux, (0x48, MuxAddr=0xa0, MuxValue=0x20) */
#define EXAMPLE_I2C_LM73_BEHIND_MUX_TEMPERATURE  0x00000010 // DataBytes = 2, CmdBytes = 1, Cmd = 0x00000000, AutoRead = True, AutoWrite = False
#define EXAMPLE_I2C_LM73_BEHIND_MUX_CONFIG       0x00000011 // DataBytes = 1, CmdBytes = 1, Cmd = 0x00000001, AutoRead = False, AutoWrite = False
// <<END_GENERATED>>