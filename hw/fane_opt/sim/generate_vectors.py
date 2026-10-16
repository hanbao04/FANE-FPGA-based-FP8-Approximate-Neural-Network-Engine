#!/usr/bin/env python3
"""Generate deterministic E4M3 vectors for one Y=1 fane_opt unit.

  generate_vectors.py --target mvm  --seed S --mvm-vectors N --output-dir DIR
  generate_vectors.py --target conv --seed S --conv-width W --conv-height H --output-dir DIR
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import torch


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
MVM_LANES = 4
MVM_REDUCTION = 9
CONV_KERNEL_SIZE = 3
CONV_LANES = 2
if str(REPOSITORY_ROOT) not in sys.path:
    sys.path.insert(0, str(REPOSITORY_ROOT))

from sw.dist_sim import (
    dequantize_from_fp8,
    fane_add_bits,
    fane_matmul,
    fane_mul_bits,
    quantize_to_fp8,
)


def _write_mem(path: Path, values: list[int], digits: int) -> None:
    path.write_text("".join(f"{value:0{digits}x}\n" for value in values))


def _pack_bytes(values: list[int], width_bytes: int = 9) -> int:
    if len(values) > width_bytes:
        raise ValueError(f"cannot pack {len(values)} bytes into {width_bytes} bytes")
    packed = 0
    for index, value in enumerate(values):
        packed |= int(value) << (8 * index)
    return packed


def _pack_conv_results(values: torch.Tensor) -> list[int]:
    """Pack two lanes and two columns per row into 72-bit result words."""

    words = []
    for row in range(values.shape[1]):
        # The later column occupies the low half of the result word.
        for first_column in range(0, values.shape[2], 2):
            slots = []
            for column in (first_column + 1, first_column):
                for lane in range(CONV_LANES):
                    value = int(values[lane, row, column]) if column < values.shape[2] else 0
                    slots.extend([value, 0])
            words.append(_pack_bytes(slots))
    return words


def _random_normal(
    shape: tuple[int, ...],
    generator: torch.Generator,
    *,
    signed: bool,
) -> torch.Tensor:
    # Keep validation away from unsupported subnormal/Inf corner cases. This
    # magnitude range also keeps every nine-term dot product finite.
    values = torch.empty(shape).uniform_(0.25, 0.75, generator=generator)
    bits = quantize_to_fp8(values, "e4m3")
    if signed:
        negative = torch.randint(0, 2, shape, generator=generator, dtype=torch.uint8)
        bits = bits.bitwise_or(negative.bitwise_left_shift(7))
    _require_normal_finite(bits, "random input")
    return bits


def _require_normal_finite(bits: torch.Tensor, label: str) -> None:
    exponent = bits.to(torch.int32).bitwise_right_shift(3).bitwise_and(0xF)
    valid = exponent.gt(0) & exponent.lt(0xF)
    if not bool(valid.all()):
        raise RuntimeError(f"{label} contains zero, subnormal, Inf, or NaN")


def _trace_dot(lhs: torch.Tensor, rhs: torch.Tensor, label: str) -> torch.Tensor:
    accumulator = torch.zeros((), dtype=torch.uint8)
    for index in range(lhs.numel()):
        product = fane_mul_bits(lhs[index], rhs[index], "e4m3")
        _require_normal_finite(product.reshape(1), f"{label} product {index}")
        accumulator = fane_add_bits(accumulator, product, "e4m3")
        _require_normal_finite(accumulator.reshape(1), f"{label} sum {index}")
    return accumulator


def _unique_conv_inputs(generator: torch.Generator, height: int, width: int) -> torch.Tensor:
    """Return address-unique normal E4M3 planes for the regression."""

    pixel_count = height * width
    if pixel_count > 88:
        raise ValueError("address-unique regression images support at most 88 pixels per lane")
    pool_bits = torch.arange(0x20, 0x20 + pixel_count, dtype=torch.uint8)
    pool_values = dequantize_from_fp8(pool_bits, "e4m3")
    lanes = []
    for _ in range(CONV_LANES):
        permutation = torch.randperm(pool_bits.numel(), generator=generator)
        lanes.append(quantize_to_fp8(pool_values[permutation], "e4m3"))
    bits = torch.stack(lanes).reshape(CONV_LANES, height, width)
    _require_normal_finite(bits, "Conv input")
    return bits


def _conv_outputs(pixels: torch.Tensor, kernels: torch.Tensor) -> torch.Tensor:
    rows = pixels.shape[1] - CONV_KERNEL_SIZE + 1
    columns = pixels.shape[2] - CONV_KERNEL_SIZE + 1
    output = torch.empty((CONV_LANES, rows, columns), dtype=torch.uint8)
    physical_kernels = kernels.reshape(CONV_LANES, 3, 3).flip(1).reshape(CONV_LANES, 9)
    for lane in range(CONV_LANES):
        for row in range(rows):
            for column in range(columns):
                window = pixels[lane, row:row+3, column:column+3].flip(0).reshape(-1)
                traced = _trace_dot(window, physical_kernels[lane], f"Conv {lane}/{row}/{column}")
                result = fane_matmul(window.reshape(1, 9), physical_kernels[lane].reshape(9, 1))
                if int(traced) != int(result.item()):
                    raise RuntimeError("Conv MAC trace disagrees with the Python model")
                output[lane, row, column] = traced
    return output


def _pack_conv_image(pixels: torch.Tensor) -> list[int]:
    return [_pack_bytes([int(pixels[0, row, column]), 0,
                         int(pixels[1, row, column]), 0])
            for row in range(pixels.shape[1]) for column in range(pixels.shape[2])]


def _generate_mvm(seed: int, mvm_vectors: int, output_dir: Path) -> None:
    generator = torch.Generator().manual_seed(seed)
    # MVM Y=1 contains four parallel 9-term dot-product lanes. Exercise five
    # consecutive result addresses. Matrix and vector data are aligned by
    # transaction: output[n] uses A[n] and B[n], including the last row.
    mm_a = _random_normal(
        (MVM_LANES, mvm_vectors, MVM_REDUCTION),
        generator,
        signed=False,
    )
    # Keep every product in a dot product at the same sign. This exercises
    # positive and negative lanes without introducing cancellation corner cases.
    mm_row_negative = torch.randint(
        0,
        2,
        (MVM_LANES, mvm_vectors, 1),
        generator=generator,
        dtype=torch.uint8,
    )
    mm_a = mm_a.bitwise_or(mm_row_negative.bitwise_left_shift(7))
    mm_b = _random_normal(
        (mvm_vectors, MVM_REDUCTION),
        generator,
        signed=False,
    )
    mm_golden = torch.empty((MVM_LANES, mvm_vectors), dtype=torch.uint8)
    for vector_index in range(mvm_vectors):
        input_index = vector_index
        mm_golden[:, vector_index] = fane_matmul(
            mm_a[:, input_index, :],
            mm_b[vector_index, :].reshape(MVM_REDUCTION, 1),
            "e4m3",
        ).reshape(-1)
    for lane_index in range(MVM_LANES):
        for vector_index in range(mvm_vectors):
            input_index = vector_index
            traced = _trace_dot(
                mm_a[lane_index, input_index],
                mm_b[vector_index],
                f"MVM lane {lane_index} vector {vector_index}",
            )
            if int(traced.item()) != int(mm_golden[lane_index, vector_index].item()):
                raise RuntimeError(
                    "MVM trace disagrees with fane_matmul at "
                    f"lane {lane_index}, vector {vector_index}"
                )
    _write_mem(
        output_dir / "mm_a.mem",
        [
            _pack_bytes(mm_a[lane_index, vector_index].tolist())
            for lane_index in range(MVM_LANES)
            for vector_index in range(mvm_vectors)
        ],
        18,
    )
    _write_mem(output_dir / "mm_b.mem", mm_b.reshape(-1).tolist(), 2)
    _write_mem(output_dir / "mm_golden.mem", mm_golden.reshape(-1).tolist(), 2)

    # Changed second-pass data keeps each lane/row sign coherent and all
    # products/partial sums normal, while exposing stale data/address bugs.
    mm_a_second = (mm_a.to(torch.int16) + 1).to(torch.uint8)
    mm_b_second = (mm_b.to(torch.int16) + 1).to(torch.uint8)
    mm_second_outputs = torch.empty_like(mm_golden)
    for lane in range(MVM_LANES):
        for vector in range(mvm_vectors):
            mm_second_outputs[lane, vector] = _trace_dot(
                mm_a_second[lane, vector], mm_b_second[vector], f"MVM second {lane}/{vector}")
            blocked = fane_matmul(
                torch.cat((mm_a[lane, vector], mm_a_second[lane, vector])).reshape(1, 18),
                torch.cat((mm_b[vector], mm_b_second[vector])).reshape(18, 1))
            stored = fane_add_bits(mm_golden[lane, vector], mm_second_outputs[lane, vector])
            if int(blocked.item()) != int(stored):
                raise RuntimeError("MVM blocked model disagrees with two FP8 writebacks")
    mm_accumulated = fane_add_bits(mm_golden, mm_second_outputs)
    _require_normal_finite(mm_accumulated, "MVM second-pass result")
    _write_mem(output_dir / "mm_a_second.mem",
               [_pack_bytes(mm_a_second[lane, vector].tolist())
                for lane in range(MVM_LANES) for vector in range(mvm_vectors)], 18)
    _write_mem(output_dir / "mm_b_second.mem", mm_b_second.reshape(-1).tolist(), 2)
    _write_mem(output_dir / "mm_accum_golden.mem", mm_accumulated.reshape(-1).tolist(), 2)


def _generate_conv(seed: int, width: int, height: int, output_dir: Path) -> None:
    generator = torch.Generator().manual_seed(seed)
    # Use an address-sensitive image for each active low-byte lane. A
    # coherent sign per lane avoids cancellation/subnormal corner cases.
    conv_pixels = _unique_conv_inputs(generator, height, width)
    conv_lane_negative = torch.randint(
        0,
        2,
        (CONV_LANES, 1, 1),
        generator=generator,
        dtype=torch.uint8,
    )
    conv_pixels = conv_pixels.bitwise_or(conv_lane_negative.bitwise_left_shift(7))
    conv_kernels = _random_normal((CONV_LANES, 9), generator, signed=False)
    # The line buffers present each 3x3 window bottom row first. Flip the
    # logical kernel vertically so every pixel still pairs with the same
    # cross-correlation weight. The pure-FP8 reduction is then evaluated in
    # this exact hardware order because FP8 addition is non-associative.
    conv_hardware_kernels = (
        conv_kernels.reshape(CONV_LANES, CONV_KERNEL_SIZE, CONV_KERNEL_SIZE)
        .flip(1)
        .reshape(CONV_LANES, 9)
    )
    conv_all_outputs = _conv_outputs(conv_pixels, conv_kernels)
    conv_image_words = _pack_conv_image(conv_pixels)
    _write_mem(output_dir / "conv_image.mem", conv_image_words, 18)
    # The kernel loader shifts the first BRAM word toward fp_b[8]. Write the
    # vertically flipped hardware kernel in reverse so fp_b[0:8] sees the
    # bottom-to-top accumulation order used by the line buffers and dist_sim.
    _write_mem(
        output_dir / "conv_kernel1.mem",
        list(reversed(conv_hardware_kernels[0].tolist())),
        2,
    )
    _write_mem(
        output_dir / "conv_kernel2.mem",
        list(reversed(conv_hardware_kernels[1].tolist())),
        2,
    )
    # Every valid output row is checked. Each word packs two adjacent
    # columns, with the earlier column in the upper half.
    conv_selected_outputs = conv_all_outputs
    conv_golden_words = _pack_conv_results(conv_selected_outputs)
    conv_pixels_second = (conv_pixels.to(torch.int16) + 1).to(torch.uint8)
    conv_kernels_second = (conv_kernels.to(torch.int16) + 1).to(torch.uint8)
    conv_second_outputs = _conv_outputs(conv_pixels_second, conv_kernels_second)
    conv_accumulated_outputs = fane_add_bits(conv_all_outputs, conv_second_outputs)
    _require_normal_finite(conv_accumulated_outputs, "Conv second-pass result")
    conv_accumulated_words = _pack_conv_results(conv_accumulated_outputs)
    _write_mem(output_dir / "conv_image_second.mem", _pack_conv_image(conv_pixels_second), 18)
    physical_second = conv_kernels_second.reshape(CONV_LANES, 3, 3).flip(1).reshape(CONV_LANES, 9)
    for lane in range(CONV_LANES):
        _write_mem(output_dir / f"conv_kernel{lane+1}_second.mem", physical_second[lane].flip(0).tolist(), 2)
    _write_mem(output_dir / "conv_golden_word.mem", conv_golden_words, 18)
    _write_mem(
        output_dir / "conv_accum_golden_word.mem", conv_accumulated_words, 18
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--target", choices=("mvm", "conv"), required=True)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--mvm-vectors", type=int)
    parser.add_argument("--conv-width", type=int)
    parser.add_argument("--conv-height", type=int)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    needed = ["mvm_vectors"] if args.target == "mvm" else ["conv_width", "conv_height"]
    for name in needed:
        if getattr(args, name) is None:
            parser.error(f"--{name.replace('_', '-')} is required for --target {args.target}")
    return args


def main() -> None:
    args = _parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    if args.target == "mvm":
        _generate_mvm(args.seed, args.mvm_vectors, args.output_dir)
    else:
        _generate_conv(args.seed, args.conv_width, args.conv_height, args.output_dir)


if __name__ == "__main__":
    main()
