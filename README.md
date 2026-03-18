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

The hardware directory contains RTL sources for the main accelerator building blocks:

- `hw/fp8_mac/`: FP8 add-mul and MAC-related modules, including a simulation testbench.
- `hw/mm/`: FP8 matrix multiplication design files and top-level wrappers.
- `hw/conv/`: FP8 convolution engine files, address generation logic, and wrapper/top modules.

These files are intended to represent the hardware implementation side of the FANE architecture and can be used as a starting point for FPGA synthesis, integration, or further accelerator exploration.

## Quick Start

### Requirements

- Python 3.x
- `numpy`

Install the Python dependency with:

```bash
pip install numpy
```

### Run Functional Tests

From the repository root:

```bash
python sw/test.py
```

This script includes examples for:

- MAC operation tests
- adder tests
- add-mul tests
- random data generation demos

You can enable additional test calls by editing the `if __name__ == "__main__":` section in `sw/test.py`.

### Run Error Evaluation

From the repository root:

```bash
python sw/main.py
```

This script evaluates multiple FP8 formats over several matrix sizes and input distributions, and prints RMSE statistics with confidence interval summaries.