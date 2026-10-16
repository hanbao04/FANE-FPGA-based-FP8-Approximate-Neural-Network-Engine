"""Pure-PyTorch FP8 bit encoding for the distribution simulator.

The public representation is a ``torch.uint8`` tensor containing the raw FP8
bit pattern.  Keeping the representation explicit lets FANE support E2M5 and
E3M4 in addition to the FP8 formats exposed as native PyTorch dtypes.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Final

import torch


@dataclass(frozen=True)
class FP8Format:
    """Description of an IEEE-like 8-bit floating-point format."""

    name: str
    exponent_bits: int
    mantissa_bits: int

    @property
    def bias(self) -> int:
        return (1 << (self.exponent_bits - 1)) - 1

    @property
    def exponent_all_ones(self) -> int:
        return (1 << self.exponent_bits) - 1

    @property
    def mantissa_scale(self) -> int:
        return 1 << self.mantissa_bits

    @property
    def bias_code(self) -> int:
        """Bias aligned with the mantissa field in the seven magnitude bits."""

        return self.bias << self.mantissa_bits


_FORMATS: Final[dict[str, FP8Format]] = {
    "e2m5": FP8Format("e2m5", 2, 5),
    "e3m4": FP8Format("e3m4", 3, 4),
    "e4m3": FP8Format("e4m3", 4, 3),
    "e5m2": FP8Format("e5m2", 5, 2),
}


def get_format(fp8_format: str | FP8Format) -> FP8Format:
    if isinstance(fp8_format, FP8Format):
        return fp8_format
    key = fp8_format.lower()
    try:
        return _FORMATS[key]
    except KeyError as exc:
        choices = ", ".join(_FORMATS)
        raise ValueError(f"unsupported FP8 format {fp8_format!r}; choose {choices}") from exc


def _require_tensor(tensor: torch.Tensor, name: str) -> None:
    if not isinstance(tensor, torch.Tensor):
        raise TypeError(f"{name} must be a torch.Tensor")


def _require_bits(tensor: torch.Tensor, name: str = "bits") -> None:
    _require_tensor(tensor, name)
    if tensor.dtype != torch.uint8:
        raise TypeError(f"{name} must have dtype torch.uint8, got {tensor.dtype}")


def quantize_to_fp8(
    values: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
) -> torch.Tensor:
    """Quantize a floating-point tensor to raw FP8 bits using round-to-nearest-even.

    All-ones exponent encodes infinity/NaN.  Finite overflow becomes infinity,
    and subnormal values are rounded using the same RNE rule as normal values.
    Quantizer calculations are performed in FP32.
    """

    _require_tensor(values, "values")
    if not values.is_floating_point():
        raise TypeError(f"values must be floating point, got {values.dtype}")

    spec = get_format(fp8_format)
    work = values.to(torch.float32)
    magnitude = work.abs()
    sign_code = torch.signbit(work).to(torch.int32) << 7
    result = sign_code.clone()

    finite_nonzero = torch.isfinite(work) & magnitude.ne(0)
    safe_magnitude = torch.where(finite_nonzero, magnitude, torch.ones_like(magnitude))
    exponent = torch.floor(torch.log2(safe_magnitude)).to(torch.int32)
    raw_exponent = exponent + spec.bias

    # Normal path. torch.round implements bankers rounding (RNE).
    normal = finite_nonzero & raw_exponent.gt(0) & raw_exponent.lt(spec.exponent_all_ones)
    power_of_two = torch.ldexp(torch.ones_like(safe_magnitude), exponent)
    mantissa_real = (safe_magnitude / power_of_two - 1.0) * spec.mantissa_scale
    mantissa = torch.round(mantissa_real).to(torch.int32)
    carry = mantissa.eq(spec.mantissa_scale)
    rounded_exponent = raw_exponent + carry.to(torch.int32)
    rounded_mantissa = torch.where(carry, torch.zeros_like(mantissa), mantissa)
    normal_overflow = normal & rounded_exponent.ge(spec.exponent_all_ones)
    normal_code = (
        sign_code
        | (rounded_exponent << spec.mantissa_bits)
        | rounded_mantissa
    )
    result = torch.where(normal & ~normal_overflow, normal_code, result)

    # Subnormal path. A rounded mantissa equal to the scale becomes the
    # smallest normal number.
    subnormal = finite_nonzero & raw_exponent.le(0)
    subnormal_step = 2.0 ** (1 - spec.bias - spec.mantissa_bits)
    subnormal_mantissa = torch.round(safe_magnitude / subnormal_step).to(torch.int32)
    subnormal_carry = subnormal_mantissa.ge(spec.mantissa_scale)
    subnormal_code = torch.where(
        subnormal_carry,
        torch.full_like(result, 1 << spec.mantissa_bits),
        subnormal_mantissa.clamp(0, spec.mantissa_scale - 1),
    )
    result = torch.where(subnormal, sign_code | subnormal_code, result)

    infinity_code = sign_code | (spec.exponent_all_ones << spec.mantissa_bits)
    # A mantissa RNE carry can promote the largest finite exponent into the
    # all-ones exponent even when the pre-round exponent was still finite.
    # This boundary encodes infinity.
    overflow = (
        finite_nonzero & raw_exponent.ge(spec.exponent_all_ones)
    ) | normal_overflow
    result = torch.where(overflow | torch.isinf(work), infinity_code, result)

    # Use one stable, positive quiet-NaN payload.
    nan_payload = 1 << max(spec.mantissa_bits - 1, 0)
    nan_code = (spec.exponent_all_ones << spec.mantissa_bits) | nan_payload
    result = torch.where(torch.isnan(work), torch.full_like(result, nan_code), result)

    # Match the original software convention: an exact zero is always +0.
    result = torch.where(magnitude.eq(0), torch.zeros_like(result), result)
    return result.to(torch.uint8)


def dequantize_from_fp8(
    bits: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
    *,
    dtype: torch.dtype = torch.float32,
) -> torch.Tensor:
    """Decode raw FP8 bit patterns into a floating-point PyTorch tensor."""

    _require_bits(bits)
    if dtype not in (torch.float16, torch.float32, torch.float64, torch.bfloat16):
        raise TypeError(f"dtype must be floating point, got {dtype}")

    spec = get_format(fp8_format)
    raw = bits.to(torch.int32)
    sign = raw.bitwise_and(0x80).ne(0)
    exponent = raw.bitwise_right_shift(spec.mantissa_bits).bitwise_and(
        spec.exponent_all_ones
    )
    mantissa = raw.bitwise_and(spec.mantissa_scale - 1)

    mantissa_float = mantissa.to(torch.float32)
    normal_value = torch.ldexp(
        1.0 + mantissa_float / spec.mantissa_scale,
        exponent - spec.bias,
    )
    subnormal_value = mantissa_float * (2.0 ** (1 - spec.bias - spec.mantissa_bits))
    value = torch.where(exponent.eq(0), subnormal_value, normal_value)

    special = exponent.eq(spec.exponent_all_ones)
    infinity = special & mantissa.eq(0)
    nan = special & mantissa.ne(0)
    value = torch.where(infinity, torch.full_like(value, float("inf")), value)
    value = torch.where(nan, torch.full_like(value, float("nan")), value)
    value = torch.where(sign, -value, value)
    return value.to(dtype)
