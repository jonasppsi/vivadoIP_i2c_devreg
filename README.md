# General Information

## Maintainer
Oliver Bründler [oliver.bruendler@psi.ch]

## License
This library is published under [PSI HDL Library License](License.txt), which is [LGPL](LGPL2_1.txt) plus some additional exceptions to clarify the LGPL terms in the context of firmware development.

## Detailed Documentation
For details, refer to the [Datasheet](doc/i2c_devreg.pdf)

## Changelog
See [Changelog](Changelog.md)

<!-- DO NOT CHANGE FORMAT: this section is parsed to resolve dependencies -->

# Dependencies

The required folder structure looks as given below (folder names must be matched exactly). 

Alternatively the repository [psi\_fpga\_all](https://github.com/paulscherrerinstitute/psi_fpga_all) can be used. This repo contains all FPGA related repositories as submodules in the correct folder structure.

* TCL
  * [PsiSim](https://github.com/paulscherrerinstitute/PsiSim) (2.2.0 or higher, for development only)
  * [PsiIpPackage](https://github.com/paulscherrerinstitute/PsiIpPackage) (2.0.0, for development only )
* VHDL
  * [psi\_common](https://github.com/paulscherrerinstitute/psi_common) (2.6.2 or higher)
  * [psi\_tb](https://github.com/paulscherrerinstitute/psi_tb) (2.4.0 or higher, for development only)
* VivadoIp
  * [**vivadoIP\_i2c\_devreg**](https://github.com/paulscherrerinstitute/vivadoIP_i2c_devreg)
  
<!-- END OF PARSED SECTION -->
  
Dependencies can also be checked out using the python script *scripts/dependencies.py*. For details, refer to the help of the script:

```
python dependencies.py -help
```

Note that the [dependencies package](https://github.com/paulscherrerinstitute/PsiFpgaLibDependencies) must be installed in order to run the script.

# Description
This IP-core implements mirroring of I2C device regsiter into a BRAM. This prevents the CPU from having high IRQ load due to many I2C accesses to execute in board-management systems with many I2C components. For details, refer to the [Datasheet](doc/i2c_devreg.pdf) The functionality is described there in more detail.


# Reference Design
A reference design for the Xilinx ZCU102 board is provided in the folder *refdesign/ZCU102*. To execute the reference design, follow the steps below:

1. In the Vivado TCL console, navigate to the directory *[root]/refdesign/ZCU102*
2. run *source ./project.tcl*
3. Build a bitstream and export it (export HW -> Include bitstream)
4. In SDK, open a new workspace
5. In SDK, import all projects from *[root]/refdesign/ZCU102/SDK*
6. In SDK, update the HW platform specification with the one exported in step 3
7. Run the project


# Simulations and Testbenches

A regression test script for Modelsim is present. To run the regression test, execute the following command in modelsim from within the directory *sim*

```
source ./run.tcl
``` 
 