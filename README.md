# FANE: FPGA-based FP8 Approximate Neural Network Engine

This repository contains the reference software and hardware artifacts for the paper **FANE: FPGA-based FP8 Approximate Neural Network Engine**.

The project is organized around two complementary parts:

- `sw/`: Python models for FP8 encoding/decoding, approximate add-mul simulation, matrix multiplication, and error evaluation.
- `hw/`: RTL implementations of the FP8 MAC, matrix multiplication, and convolution building blocks used by the accelerator design.

## Repository Layout

```text
.
|-- hw/
|   |-- fp8_mac/    # FP8 MAC and simulation testbench
|   |-- mm/         # Matrix multiplication related RTL
|   `-- conv/       # Convolution related RTL and wrapper files
|-- sw/
|   |-- main.py     # Error evaluation across FP8 formats and input distributions
|   |-- test.py     # Functional tests for MAC, adder, add-mul, and data generation
|   `-- utils/      # Core FP8 codec, arithmetic units, matrix multiply, and helpers
|-- LICENSE
`-- README.md
```

## Software Part

The software stack provides a Python-level model of the proposed FP8 approximate arithmetic pipeline. It includes:

- FP8 format support for `e2m5`, `e3m4`, `e4m3`, and `e5m2`
- FP8 encoding and decoding utilities
- Approximate multiplication and accumulation flow
- FP8 matrix multiplication simulation
- Random data generation under multiple distributions
- RMSE-based error analysis against floating-point reference results

### Main Python Modules

- `sw/utils/Decoder.py`: FP8 codec implementation.
- `sw/utils/Adder.py`: FP8 adder model.
- `sw/utils/Multiplier.py`: approximate multiplier implementation.
- `sw/utils/top_matmul.py`: FP8 MAC and matrix multiplication flow.
- `sw/utils/data_gen.py`: random matrix generation and matrix multiplication data path.
- `sw/utils/error.py`: RMSE calculation utilities.
- `sw/main.py`: repeated evaluation script for different FP8 formats and distributions.
- `sw/test.py`: directed tests and small-scale demos.

### Supported Input Distributions

The software evaluation flow currently covers:

- uniform
- normal
- laplace
- student_t

## Hardware Part

The hardware directory contains the RTL implementation of the main FANE building blocks.

### Directory Structure

- `hw/fp8_mac/`: source and simulation files for the FP8 arithmetic core.
- `hw/mm/`: matrix multiplication datapath, chip-level wrapper, and a directed smoke testbench.
- `hw/conv/`: convolution datapath, address-generation logic, chip-level wrapper, and a directed smoke testbench.

### Main Hardware Modules

- `hw/fp8_mac/src/fp8_addmul.v`: approximate FP8 multiply pipeline.
- `hw/fp8_mac/src/fp8_adder.v`: FP8 adder used for accumulation.
- `hw/fp8_mac/src/fane_mac.v`: MAC wrapper around the FP8 multiply and add stages. 

- `hw/mm/fp8_mac.v`: MAC wrapper around the FP8 multiply and add stages.(Re-pack in order to satisfy the pipeline)
- `hw/mm/fp8_mm.v`: core matrix-multiplication engine.
- `hw/mm/fp8_mm_top.v`: matrix-multiplication top-level control and memory integration.
- `hw/mm/fp8_mm_chip.sv`: chip-style wrapper that instantiates multiple MM tiles.
- `hw/conv/fp8_conv_mm_tb.sv`: testbench for MVM unit.

- `hw/conv/fp8_mac.v`: MAC wrapper around the FP8 multiply and add stages.(Re-pack in order to satisfy the pipeline)
- `hw/conv/fp8_addr_gen.v`: address generator used by the convolution pipeline.
- `hw/conv/fp8_conv.v`: core convolution compute engine.
- `hw/conv/fp8_conv_top.v`: convolution control, buffering, and URAM/BRAM integration.
- `hw/conv/fp8_conv_chip.sv`: chip-style wrapper that instantiates multiple convolution tiles.
- `hw/conv/fp8_conv_chip_tb.sv`: testbench for conv unit. PLEASE run at least 3000ns and console gives the result.
