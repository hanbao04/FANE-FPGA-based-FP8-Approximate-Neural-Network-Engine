# FANE: FPGA-based FP8 Approximate Neural Network Engine

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19098450.svg)](https://doi.org/10.5281/zenodo.19098450)

This repository contains the reference software models and hardware RTL artifacts for **FANE: FPGA-based FP8 Approximate Neural Network Engine**.

FANE explores approximate FP8 arithmetic for neural-network acceleration on FPGA. The repository is split into:

- `sw/`: Python models for FP8 encoding/decoding, approximate arithmetic, matrix multiplication, data generation, and error evaluation.
- `hw/`: Verilog/SystemVerilog implementations of the FP8 MAC, matrix-multiplication, convolution, and supporting accelerator blocks.

## Repository Layout

```text
.
|-- hw/
|   |-- fane_opt/      # Optimized MVM/Conv RTL and Y=1 regression
|   |-- fane_paper/    # Preserved paper-version RTL
|   |-- fp8_mac/       # Standalone FP8 MAC RTL and legacy testbench
|   `-- minimal_unit/ # Minimum-unit RTL experiments
|-- sw/dist_sim/      # FP8 encoding, arithmetic and distribution simulation
|-- Makefile          # Y=1 XSim entry points
|-- LICENSE
`-- README.md
```

## Software Model

The software package provides pure-PyTorch FP8/FANE arithmetic and numerical
distribution simulation. FP8 values use raw bit patterns in `torch.uint8`
tensors.

### Features

- FP8 format support: `e2m5`, `e3m4`, `e4m3`, and `e5m2`
- FP8 encoding and decoding utilities
- FANE FP8 x FP8 -> FP8 approximate multiplication
- Nine-term FP8 partial sums and FP8 result-memory accumulation with truncating alignment
- Uniform, normal, Laplace, and Student-t distribution simulation
- RMSE evaluation against FP32 matrix multiplication of quantized FP8 inputs

### Main Modules

| Path | Description |
| --- | --- |
| `sw/dist_sim/fp8.py` | Pure-PyTorch RNE FP8 encoding and decoding |
| `sw/dist_sim/fane.py` | Pure-PyTorch FANE multiply/add/dot/matmul |
| `sw/dist_sim/validate.py` | Numerical-distribution accuracy evaluation |
| `sw/dist_sim/tests/test_dist_sim.py` | FP8 codec and arithmetic tests |

### Running the Software Tests

From the repository root, install the CPU build of PyTorch in a fresh Python
environment, then install the remaining requirements and run the tests:

```bash
python -m pip install "torch>=2.2" --index-url https://download.pytorch.org/whl/cpu
python -m pip install -r sw/requirements.txt
pytest -q sw/dist_sim/tests/test_dist_sim.py
```

See [`sw/README.md`](sw/README.md) for the operator semantics and examples.

## Hardware RTL

The hardware directory contains the RTL building blocks used to implement the FANE accelerator datapath.

### FP8 MAC

| Path | Description |
| --- | --- |
| `hw/fp8_mac/src/fp8_addmul.v` | Approximate FP8 multiply/add-multiply pipeline |
| `hw/fp8_mac/src/fp8_adder.v` | FP8 adder for accumulation |
| `hw/fp8_mac/src/fane_mac.v` | MAC wrapper around the multiply and add stages |
| `hw/fp8_mac/sim/fane_mac_tb.v` | Standalone MAC simulation testbench |

### Fine-Grained Minimum Unit

`hw/minimal_unit/` contains minimum RTL blocks with fine-grained design, including matrix-vector and convolution-oriented modules, constraints, adders, and FP8 data-path components.

### Matrix Multiplication

| Path | Description |
| --- | --- |
| `hw/fane_paper/mm/v_paper/` | Reference matrix-multiplication RTL corresponding to the paper version |
| `hw/fane_opt/mm/v_opt/` | Optimized matrix-multiplication RTL |
| `hw/fane_opt/mm/v_opt/mm.v` | Core matrix-multiplication engine |
| `hw/fane_opt/mm/v_opt/mm_top.v` | Top-level matrix-multiplication control and memory integration |
| `hw/fane_opt/mm/v_opt/mm_chip.sv` | Chip-style wrapper for the matrix-multiplication unit |
| `hw/fane_opt/mm/v_opt/fpmac_mm.v` | Pipeline-compatible FP8 MAC wrapper |

### Convolution

| Path | Description |
| --- | --- |
| `hw/fane_paper/conv/v_paper/` | Reference convolution RTL corresponding to the paper version |
| `hw/fane_opt/conv/v_opt/` | Optimized convolution RTL |
| `hw/fane_opt/conv/v_opt/conv.v` | Core convolution engine |
| `hw/fane_opt/conv/v_opt/conv_top.v` | Top-level convolution control and memory integration |
| `hw/fane_opt/conv/v_opt/conv_chip.sv` | Chip-style wrapper for the convolution unit |
| `hw/fane_opt/conv/v_opt/fpmac_conv.v` | Pipeline-compatible FP8 MAC wrapper |


## Power Evaluation

Power results are derived using **PDM tool v2025.2**.

## Min.hardware simulation (New)

The `hw/fane_opt/sim` regression validates the complete Y=1 chip wrappers,
including URAM/BRAM paths, address generation, controller timing, every valid
output row, and changed second-pass FP8 accumulation onto nonzero result RAM. Source Vivado first, then use the root Makefile:

```bash
source /opt/xilinx/2025.2/Vivado/settings64.sh
export PYTHON_BIN=/path/to/python-with-torch
make mvm  SEEDS="2026 2027" MVM_VECTORS=5
make conv SEEDS="2026 2027" CONV_WIDTH=4 CONV_HEIGHT=6
make clean
```

Use `make help` for more information.

## License

This project is released under the license provided in [`LICENSE`](LICENSE).
