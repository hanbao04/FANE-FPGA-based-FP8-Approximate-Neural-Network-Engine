"""Pure-PyTorch FANE arithmetic for distribution simulation.

FANE multiplication is bit-oriented: the seven exponent/mantissa bits are
added, the aligned exponent bias is subtracted, and the signs are XORed.  The
optimized RTL forces a result outside the unsigned seven-bit magnitude range
to zero instead of allowing the old two's-complement wraparound.

Matrix accumulation follows the hardware's nine-term MAC blocks and FP8
result-memory writeback, including truncating exponent alignment. Every
product, block partial sum, and stored accumulator is represented in FP8.
"""

from __future__ import annotations

import torch

from .fp8 import (
    FP8Format,
    _require_bits,
    dequantize_from_fp8,
    get_format,
    quantize_to_fp8,
)


def fane_mul_bits(
    lhs: torch.Tensor,
    rhs: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
) -> torch.Tensor:
    """Elementwise FANE FP8 x FP8 -> FP8 multiplication on raw bit tensors."""

    _require_bits(lhs, "lhs")
    _require_bits(rhs, "rhs")
    if lhs.device != rhs.device:
        raise ValueError(f"lhs and rhs must be on the same device: {lhs.device} != {rhs.device}")

    spec = get_format(fp8_format)
    lhs, rhs = torch.broadcast_tensors(lhs, rhs)
    lhs_raw = lhs.to(torch.int32)
    rhs_raw = rhs.to(torch.int32)
    lhs_magnitude = lhs_raw.bitwise_and(0x7F)
    rhs_magnitude = rhs_raw.bitwise_and(0x7F)

    sign = lhs_raw.bitwise_xor(rhs_raw).bitwise_and(0x80)
    raw_magnitude = lhs_magnitude + rhs_magnitude - spec.bias_code
    magnitude = raw_magnitude.bitwise_and(0x7F)
    product = sign.bitwise_or(magnitude)

    # The optimized LUT3 output stage suppresses zero inputs and both directions
    # of seven-bit overflow rather than exposing a wrapped magnitude.
    force_zero = (
        lhs_magnitude.eq(0)
        | rhs_magnitude.eq(0)
        | raw_magnitude.lt(0)
        | raw_magnitude.gt(0x7F)
    )
    return torch.where(force_zero, torch.zeros_like(product), product).to(torch.uint8)


def fane_add_bits(
    lhs: torch.Tensor,
    rhs: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
) -> torch.Tensor:
    """Add raw FP8 tensors with the original truncating bit-domain adder.

    Exponents are aligned by right-shifting (without guard, round, or sticky
    bits), signed mantissas are added, and the result is normalized and packed
    directly back to FP8.  This models the pure-FP8 accumulation path rather
    than an FP32 addition followed by FP8 quantization.
    """

    _require_bits(lhs, "lhs")
    _require_bits(rhs, "rhs")
    if lhs.device != rhs.device:
        raise ValueError(f"lhs and rhs must be on the same device: {lhs.device} != {rhs.device}")

    spec = get_format(fp8_format)
    lhs, rhs = torch.broadcast_tensors(lhs, rhs)
    lhs_raw = lhs.to(torch.int32)
    rhs_raw = rhs.to(torch.int32)
    mantissa_mask = spec.mantissa_scale - 1

    lhs_sign = lhs_raw.bitwise_and(0x80).ne(0)
    rhs_sign = rhs_raw.bitwise_and(0x80).ne(0)
    lhs_exponent = lhs_raw.bitwise_right_shift(spec.mantissa_bits).bitwise_and(
        spec.exponent_all_ones
    )
    rhs_exponent = rhs_raw.bitwise_right_shift(spec.mantissa_bits).bitwise_and(
        spec.exponent_all_ones
    )
    lhs_mantissa = lhs_raw.bitwise_and(mantissa_mask)
    rhs_mantissa = rhs_raw.bitwise_and(mantissa_mask)

    lhs_nan = lhs_exponent.eq(spec.exponent_all_ones) & lhs_mantissa.ne(0)
    rhs_nan = rhs_exponent.eq(spec.exponent_all_ones) & rhs_mantissa.ne(0)
    lhs_inf = lhs_exponent.eq(spec.exponent_all_ones) & lhs_mantissa.eq(0)
    rhs_inf = rhs_exponent.eq(spec.exponent_all_ones) & rhs_mantissa.eq(0)
    opposite_infinities = lhs_inf & rhs_inf & lhs_sign.ne(rhs_sign)
    canonical_nan = torch.full_like(
        lhs_raw,
        (spec.exponent_all_ones << spec.mantissa_bits) | 1,
    )
    lhs_infinity = (
        lhs_sign.to(torch.int32).bitwise_left_shift(7)
        | (spec.exponent_all_ones << spec.mantissa_bits)
    )
    rhs_infinity = (
        rhs_sign.to(torch.int32).bitwise_left_shift(7)
        | (spec.exponent_all_ones << spec.mantissa_bits)
    )

    lhs_zero = lhs_exponent.eq(0) & lhs_mantissa.eq(0)
    rhs_zero = rhs_exponent.eq(0) & rhs_mantissa.eq(0)
    lhs_significand = lhs_mantissa | (
        lhs_exponent.ne(0).to(torch.int32) << spec.mantissa_bits
    )
    rhs_significand = rhs_mantissa | (
        rhs_exponent.ne(0).to(torch.int32) << spec.mantissa_bits
    )

    lhs_has_larger_exponent = lhs_exponent.gt(rhs_exponent)
    exponent_difference = (lhs_exponent - rhs_exponent).abs()
    aligned_lhs = torch.where(
        lhs_has_larger_exponent,
        lhs_significand,
        torch.bitwise_right_shift(lhs_significand, exponent_difference),
    )
    aligned_rhs = torch.where(
        lhs_has_larger_exponent,
        torch.bitwise_right_shift(rhs_significand, exponent_difference),
        rhs_significand,
    )
    common_exponent = torch.maximum(lhs_exponent, rhs_exponent)
    signed_lhs = torch.where(lhs_sign, -aligned_lhs, aligned_lhs)
    signed_rhs = torch.where(rhs_sign, -aligned_rhs, aligned_rhs)
    signed_sum = signed_lhs + signed_rhs
    result_zero = signed_sum.eq(0)
    result_sign = signed_sum.lt(0)
    magnitude = signed_sum.abs()

    most_significant_bit = torch.zeros_like(magnitude)
    for bit in range(spec.mantissa_bits + 2):
        most_significant_bit = torch.where(
            magnitude.ge(1 << bit),
            torch.full_like(most_significant_bit, bit),
            most_significant_bit,
        )

    shift_right = (most_significant_bit - spec.mantissa_bits).clamp_min(0)
    normalized_magnitude = torch.bitwise_right_shift(magnitude, shift_right)
    normalized_exponent = common_exponent + shift_right
    shift_left = (spec.mantissa_bits - most_significant_bit).clamp_min(0)
    can_shift_left = most_significant_bit.lt(spec.mantissa_bits) & normalized_exponent.gt(0)
    normalized_magnitude = torch.where(
        can_shift_left,
        torch.bitwise_left_shift(normalized_magnitude, shift_left),
        normalized_magnitude,
    )
    normalized_exponent = torch.where(
        can_shift_left,
        normalized_exponent - shift_left,
        normalized_exponent,
    )

    overflow = normalized_exponent.ge(spec.exponent_all_ones)
    normal = normalized_exponent.gt(0) & ~overflow
    normal_code = (
        result_sign.to(torch.int32).bitwise_left_shift(7)
        | normalized_exponent.bitwise_left_shift(spec.mantissa_bits)
        | normalized_magnitude.bitwise_and(mantissa_mask)
    )
    normalized_most_significant_bit = torch.zeros_like(normalized_magnitude)
    for bit in range(spec.mantissa_bits + 2):
        normalized_most_significant_bit = torch.where(
            normalized_magnitude.ge(1 << bit),
            torch.full_like(normalized_most_significant_bit, bit),
            normalized_most_significant_bit,
        )
    subnormal_shift = (
        normalized_most_significant_bit - (spec.mantissa_bits - 1)
    ).clamp_min(0)
    subnormal_mantissa = torch.bitwise_right_shift(normalized_magnitude, subnormal_shift)
    subnormal_code = (
        result_sign.to(torch.int32).bitwise_left_shift(7)
        | subnormal_mantissa.bitwise_and(mantissa_mask)
    )
    infinity_code = (
        result_sign.to(torch.int32).bitwise_left_shift(7)
        | (spec.exponent_all_ones << spec.mantissa_bits)
    )
    result = torch.where(normal, normal_code, subnormal_code)
    result = torch.where(overflow, infinity_code, result)
    result = torch.where(result_zero, torch.zeros_like(result), result)

    # Preserve the legacy adder's special-value and zero-shortcut priority.
    result = torch.where(rhs_zero, lhs_raw, result)
    result = torch.where(lhs_zero, rhs_raw, result)
    result = torch.where(rhs_inf, rhs_infinity, result)
    result = torch.where(lhs_inf, lhs_infinity, result)
    result = torch.where(lhs_nan | rhs_nan | opposite_infinities, canonical_nan, result)
    return result.to(torch.uint8)


def _validate_matmul_inputs(
    lhs: torch.Tensor,
    rhs: torch.Tensor,
) -> None:
    _require_bits(lhs, "lhs")
    _require_bits(rhs, "rhs")
    if lhs.ndim != 2 or rhs.ndim != 2:
        raise ValueError(f"fane_matmul expects two rank-2 tensors, got {lhs.ndim} and {rhs.ndim}")
    if lhs.shape[1] != rhs.shape[0]:
        raise ValueError(f"inner dimensions do not match: {lhs.shape} x {rhs.shape}")
    if lhs.device != rhs.device:
        raise ValueError(f"lhs and rhs must be on the same device: {lhs.device} != {rhs.device}")


def fane_matmul(
    lhs: torch.Tensor,
    rhs: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
) -> torch.Tensor:
    """Compute a FANE matrix product and return raw FP8 output bits.

    ``lhs`` has shape ``[M, K]`` and ``rhs`` has shape ``[K, N]``.  Every
    multiply produces FP8 immediately. Each group of up to nine products is
    reduced from zero by the bit-domain FP8 adder, then added to the stored
    output with the same FP8 adder. This matches the nine-MAC hardware chain
    and its result-memory writeback order, including a final shorter group.
    """

    _validate_matmul_inputs(lhs, rhs)
    spec = get_format(fp8_format)
    rows, reduction = lhs.shape
    columns = rhs.shape[1]
    output = torch.zeros((rows, columns), dtype=torch.uint8, device=lhs.device)
    for block_start in range(0, reduction, 9):
        partial = torch.zeros_like(output)
        for index in range(block_start, min(block_start + 9, reduction)):
            product_bits = fane_mul_bits(
                lhs[:, index].unsqueeze(1),
                rhs[index, :].unsqueeze(0),
                spec,
            )
            partial = fane_add_bits(partial, product_bits, spec)
        output = fane_add_bits(output, partial, spec)
    return output


def fane_dot(
    lhs: torch.Tensor,
    rhs: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
) -> torch.Tensor:
    """FANE dot product of two one-dimensional raw FP8 tensors."""

    _require_bits(lhs, "lhs")
    _require_bits(rhs, "rhs")
    if lhs.ndim != 1 or rhs.ndim != 1 or lhs.shape != rhs.shape:
        raise ValueError(f"fane_dot expects equal rank-1 tensors, got {lhs.shape} and {rhs.shape}")
    return fane_matmul(
        lhs.unsqueeze(0),
        rhs.unsqueeze(1),
        fp8_format,
    ).reshape(())


def fane_matmul_float(
    lhs: torch.Tensor,
    rhs: torch.Tensor,
    fp8_format: str | FP8Format = "e4m3",
    *,
    output_dtype: torch.dtype = torch.float32,
) -> torch.Tensor:
    """Convenience wrapper accepting floats and returning decoded values."""

    lhs_bits = quantize_to_fp8(lhs, fp8_format)
    rhs_bits = quantize_to_fp8(rhs, fp8_format)
    output_bits = fane_matmul(
        lhs_bits,
        rhs_bits,
        fp8_format,
    )
    return dequantize_from_fp8(output_bits, fp8_format, dtype=output_dtype)
