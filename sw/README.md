# FANE software

The `dist_sim/` package provides pure-PyTorch FP8/FANE arithmetic and
numerical-distribution simulation. The simulation and hardware-vector
generation workflows run on the CPU.

All FP8 values are represented as `torch.uint8` bit patterns, supporting E2M5,
E3M4, E4M3, and E5M2 independently of PyTorch's native FP8 dtype support.

## `dist_sim`: pure-PyTorch arithmetic

Every multiplication uses the existing FANE approximation: add the two
seven-bit exponent/mantissa fields, subtract the aligned exponent bias, XOR the
signs, and emit FP8. A zero operand or an out-of-range unsigned magnitude emits
positive zero.

Products are reduced in blocks of up to nine using the bit-domain FP8 adder,
then each block partial sum is FP8-added to the stored output. Exponent
alignment truncates shifted bits. Every product, block partial sum and stored
accumulator is FP8, matching the nine-MAC hardware chain and result-memory
writeback. The final block may contain fewer than nine terms.

Grouping changes FP8 results: eighteen products of 1 produce two partial
sums of 9 and a stored result of 18. Serial per-product FP8 addition would
stall at 16. `fane_matmul` and `fane_dot` use the hardware's block order.

From the repository root, install the CPU build of PyTorch in a fresh Python
environment, then install the remaining requirements:

```bash
python -m pip install "torch>=2.2" --index-url https://download.pytorch.org/whl/cpu
python -m pip install -r sw/requirements.txt
pytest -q sw/dist_sim/tests/test_dist_sim.py
python -m sw.dist_sim.validate --repeats 5
```

The simulator covers uniform, normal, Laplace, and Student-t distributions by
default. RMSE is measured against FP32 matrix multiplication of the same
quantized FP8 inputs, isolating arithmetic error from input quantization.

```python
import torch

from sw.dist_sim import dequantize_from_fp8, fane_matmul, quantize_to_fp8

a = quantize_to_fp8(torch.randn(4, 9), "e4m3")
b = quantize_to_fp8(torch.randn(9, 8), "e4m3")
c_bits = fane_matmul(
    a,
    b,
    "e4m3",
)
c = dequantize_from_fp8(c_bits, "e4m3")
```
