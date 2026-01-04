# RISC-V Processor

A hardware implementation of a RISC-V processor core written in Verilog/SystemVerilog. This project implements the RV32I base integer instruction set architecture.

## Features

- **ISA Support**: RV32I base integer instruction set
- **Pipeline**: 5-stage classic RISC pipeline (Fetch, Decode, Execute, Memory, Writeback)
- **Hazard Handling**: Data forwarding and pipeline stalling mechanisms
- **Memory Interface**: Separate instruction and data memory interfaces
- **Configurable**: Parameterized design for easy customization

## Architecture Overview

The processor implements a classic 5-stage pipeline architecture:

1. **Instruction Fetch (IF)**: Fetches instructions from memory
2. **Instruction Decode (ID)**: Decodes instructions and reads register file
3. **Execute (EX)**: Performs ALU operations and branch resolution
4. **Memory Access (MEM)**: Handles load/store operations
5. **Write Back (WB)**: Writes results back to register file

### Supported Instructions

The processor implements the complete RV32I instruction set including:

- **Arithmetic**: ADD, SUB, AND, OR, XOR, SLT, SLTU
- **Immediate**: ADDI, ANDI, ORI, XORI, SLTI, SLTIU
- **Shift**: SLL, SRL, SRA, SLLI, SRLI, SRAI
- **Load/Store**: LB, LH, LW, LBU, LHU, SB, SH, SW
- **Branch**: BEQ, BNE, BLT, BGE, BLTU, BGEU
- **Jump**: JAL, JALR
- **Upper Immediate**: LUI, AUIPC

## Getting Started

### Prerequisites

- Verilog/SystemVerilog simulator (ModelSim, Icarus Verilog, Verilator, or similar)
- RISC-V GNU Toolchain for compiling test programs
- (Optional) FPGA synthesis tools if targeting hardware

### Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/riscv-processor.git
cd riscv-processor
```

### Directory Structure

```
riscv-processor/
├── rtl/                  # RTL source files
│   ├── core/            # Processor core modules
│   ├── memory/          # Memory modules
│   └── peripherals/     # Peripheral interfaces
├── tb/                  # Testbenches
├── tests/               # Test programs
├── tools/               # Build and simulation scripts
├── docs/                # Documentation
└── README.md
```

## Simulation

### Running Testbench

Using Icarus Verilog:

```bash
cd tb
iverilog -o sim -s testbench testbench.v ../rtl/**/*.v
vvp sim
```

Using ModelSim:

```bash
cd tb
vsim -do run.do
```

### Running Test Programs

1. Compile your RISC-V assembly or C program:

```bash
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -o program.elf program.c
riscv32-unknown-elf-objcopy -O binary program.elf program.bin
```

2. Load the program into instruction memory and run simulation

## Synthesis

### FPGA Synthesis

The design has been tested on the following FPGA boards:

- Xilinx Artix-7
- Intel Cyclone V
- Lattice iCE40

Synthesis scripts are provided in the `tools/` directory.

## Performance

- **Maximum Frequency**: ~50 MHz (on Artix-7)
- **CPI**: ~1.2 (with forwarding, without cache misses)
- **Resource Usage**: ~2000 LUTs, ~1000 FFs (varies by configuration)

## Testing

The processor has been verified using:

- Custom directed tests for individual instructions
- RISC-V compliance test suite
- Dhrystone benchmark
- CoreMark benchmark

## Configuration

Key parameters can be configured in `rtl/core/riscv_config.vh`:

```verilog
parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
parameter REG_COUNT = 32;
parameter ENABLE_FORWARDING = 1;
```

## Known Limitations

- No multiply/divide instructions (M extension not implemented)
- No floating-point support (F/D extensions not implemented)
- No interrupts or exceptions (privileged architecture not implemented)
- Single-cycle memory access assumed

## Roadmap

- [ ] Implement M extension (multiply/divide)
- [ ] Add interrupt controller
- [ ] Implement CSR registers
- [ ] Add branch prediction
- [ ] Cache integration
- [ ] Multi-cycle memory interface

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the project coding standards and includes appropriate tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- RISC-V Foundation for the ISA specification
- Berkeley Architecture Research for educational resources
- Contributors and testers who helped improve this project

## References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [RISC-V Instruction Set Manual](https://github.com/riscv/riscv-isa-manual)
- [Computer Organization and Design RISC-V Edition](https://www.elsevier.com/books/computer-organization-and-design-risc-v-edition/patterson/978-0-12-812275-4)

## Contact

Your Name - @Kingkiri0986 User email:- paramtap0809@gmail.com

Project Link: https://github.com/Kingkiri0986/RISC-V_Processor.git

---

**Note**: This is an educational project. For production use, consider mature RISC-V cores like BOOM, Rocket, or commercial offerings.