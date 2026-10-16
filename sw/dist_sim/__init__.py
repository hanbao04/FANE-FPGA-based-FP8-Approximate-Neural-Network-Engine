"""Pure-PyTorch FANE arithmetic and distribution simulation."""

from .fane import fane_add_bits, fane_dot, fane_matmul, fane_matmul_float, fane_mul_bits
from .fp8 import (
    FP8Format,
    dequantize_from_fp8,
    get_format,
    quantize_to_fp8,
)

__all__ = [
    "FP8Format",
    "dequantize_from_fp8",
    "fane_add_bits",
    "fane_dot",
    "fane_matmul",
    "fane_matmul_float",
    "fane_mul_bits",
    "get_format",
    "quantize_to_fp8",
]
