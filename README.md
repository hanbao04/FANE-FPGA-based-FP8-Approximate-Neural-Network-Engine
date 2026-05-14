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
|   |-- fp8_mac/       # Standalone FP8 MAC RTL and testbench
|   |-- mm/            # Matrix-multiplication RTL variants
|   |   |-- v_paper/   # Paper version
|   |   `-- v_opt/     # Optimized implementation (Fix the Bug of Addmul and mm)
|   |-- conv/          # Convolution RTL and chip-level wrapper
|   |   |-- v_paper/   # Paper version
|   |   `-- v_opt/     # Optimized implementation (Fix the Bug of Addmul and conv)
|   `-- fg_min_unit/   # Fine-grained/minimum-unit RTL experiments
|-- sw/
|   |-- main.py        # RMSE evaluation across FP8 formats and distributions
|   |-- test.py        # Directed software tests and small demos
|   `-- utils/         # FP8 codec, arithmetic models, data generation, and helpers
|-- ChangLOG.md        # Project changelog
|-- LICENSE
`-- README.md
```

## Software Model

The Python model provides a bit-level and numerical reference for the approximate FP8 arithmetic flow used by the hardware design.

### Features

- FP8 format support: `e2m5`, `e3m4`, `e4m3`, and `e5m2`
- FP8 encoding and decoding utilities
- Approximate multiplier and adder models
- FP8 MAC and matrix-multiplication simulation
- Random matrix generation for multiple input distributions
- RMSE-based comparison against floating-point reference results
- Repeated evaluation over matrix sizes and FP8 formats

### Main Modules

| Path | Description |
| --- | --- |
| `sw/utils/Decoder.py` | FP8 encode/decode utilities |
| `sw/utils/Adder.py` | FP8 adder model |
| `sw/utils/Multiplier.py` | Approximate multiplier model |
| `sw/utils/top_matmul.py` | FP8 MAC and matrix-multiplication flow |
| `sw/utils/data_gen.py` | Random input generation and matrix data path |
| `sw/utils/error.py` | RMSE calculation utilities |
| `sw/main.py` | Batch evaluation script |
| `sw/test.py` | Directed functional tests and demos |

### Supported Input Distributions

The evaluation flow currently includes:

- `uniform`
- `normal`
- `laplace`
- `student_t`

### Running the Software Tests

From the repository root:

```bash
cd sw
python test.py
```

For the full evaluation flow:

```bash
cd sw
python main.py
```

The main evaluation sweeps FP8 formats and input distributions, then reports RMSE statistics and confidence-interval data.

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

`hw/fg_min_unit/` contains minimum RTL blocks with fine-grained design, including matrix-vector and convolution-oriented modules, constraints, adders, and FP8 data-path components.

### Matrix Multiplication

| Path | Description |
| --- | --- |
| `hw/mm/v_paper/` | Reference matrix-multiplication RTL corresponding to the paper version |
| `hw/mm/v_opt/` | Optimized matrix-multiplication RTL |
| `hw/mm/v_opt(v_paper)/mm.v` | Core matrix-multiplication engine |
| `hw/mm/v_opt(v_paper)/mm_top.v` | Top-level matrix-multiplication control and memory integration |
| `hw/mm/v_opt(v_paper)/mm_chip.sv` | Chip-style wrapper for the matrix-multiplication unit |
| `hw/mm/v_opt(v_paper)/fpmac_mm.v` | Pipeline-compatible FP8 MAC wrapper |

### Convolution

| Path | Description |
| --- | --- |
| `hw/conv/v_paper/` | Reference convolution RTL corresponding to the paper version |
| `hw/conv/v_opt/` | Optimized convolution RTL |
| `hw/conv/v_opt(v_paper)/conv.v` | Core convolution engine |
| `hw/conv/v_opt(v_paper)/conv_top.v` | Top-level convolution control and memory integration |
| `hw/conv/v_opt(v_paper)/conv_chip.sv` | Chip-style wrapper for the convolution unit |
| `hw/conv/v_opt(v_paper)/fpmac_conv.v` | Pipeline-compatible FP8 MAC wrapper |


## Power Evaluation

Power results are derived using **PDM tool v2025.2**.

## Notes on Recent Fixes

Recent fixes are documented in [`ChangLOG.md`](ChangLOG.md). In particular, the add-multiply, matrix-multiplication, and convolution paths were updated to handle edge cases correctly:

- Edge-case output is now `0` instead of the previous two's-complement-style representation.
- Related hardware logic was updated from `LUT2` to `LUT3`.
- The addition before BRAM was corrected to use an FP adder instead of an integer adder.

## License

This project is released under the license provided in [`LICENSE`](LICENSE).
