"""Distribution accuracy simulation for the pure-PyTorch FANE operators."""

from __future__ import annotations

import argparse
from dataclasses import dataclass

import torch

from .fane import fane_matmul
from .fp8 import dequantize_from_fp8, quantize_to_fp8


@dataclass(frozen=True)
class ValidationResult:
    fp8_format: str
    distribution: str
    size: int
    rmse_mean: float
    rmse_std: float


_DEFAULT_RANGES = {
    "e2m5": (-0.3, 0.3),
    "e3m4": (-0.6, 0.6),
    "e4m3": (-1.0, 1.0),
    "e5m2": (-1.3, 1.3),
}


def _sample_matrix(
    size: int,
    distribution: str,
    value_range: tuple[float, float],
    generator: torch.Generator,
) -> torch.Tensor:
    low, high = value_range
    center = (low + high) / 2.0
    scale = (high - low) / 6.0
    shape = (size, size)

    if distribution == "uniform":
        return torch.empty(shape).uniform_(low, high, generator=generator)
    if distribution == "normal":
        return torch.empty(shape).normal_(center, scale, generator=generator)
    if distribution == "laplace":
        uniform = torch.empty(shape).uniform_(-0.5, 0.5, generator=generator)
        return center - scale * torch.sign(uniform) * torch.log1p(-2.0 * uniform.abs())
    if distribution == "student_t":
        normal = torch.randn(shape, generator=generator)
        chi_square = torch.randn((*shape, 3), generator=generator).square().sum(dim=-1)
        return center + scale * normal / torch.sqrt(chi_square / 3.0)
    raise ValueError(f"unsupported distribution {distribution!r}")


def validate_case(
    *,
    fp8_format: str,
    distribution: str,
    size: int,
    repeats: int,
    seed: int,
) -> ValidationResult:
    """Compare FANE against FP32 matmul of the same quantized FP8 inputs."""

    if size <= 0 or repeats <= 0:
        raise ValueError("size and repeats must be greater than zero")

    generator = torch.Generator().manual_seed(seed)
    errors = []
    for _ in range(repeats):
        lhs_float = _sample_matrix(size, distribution, _DEFAULT_RANGES[fp8_format], generator)
        rhs_float = _sample_matrix(size, distribution, _DEFAULT_RANGES[fp8_format], generator)
        lhs_bits = quantize_to_fp8(lhs_float, fp8_format)
        rhs_bits = quantize_to_fp8(rhs_float, fp8_format)

        lhs_quantized = dequantize_from_fp8(lhs_bits, fp8_format)
        rhs_quantized = dequantize_from_fp8(rhs_bits, fp8_format)
        reference = torch.matmul(lhs_quantized, rhs_quantized)

        output_bits = fane_matmul(
            lhs_bits,
            rhs_bits,
            fp8_format,
        )
        output = dequantize_from_fp8(output_bits, fp8_format)
        errors.append(torch.sqrt(torch.mean((reference - output).square())))

    stacked = torch.stack(errors).to(torch.float64)
    std = stacked.std(unbiased=True).item() if repeats > 1 else 0.0
    return ValidationResult(
        fp8_format=fp8_format,
        distribution=distribution,
        size=size,
        rmse_mean=stacked.mean().item(),
        rmse_std=std,
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--formats", nargs="+", default=list(_DEFAULT_RANGES))
    parser.add_argument(
        "--distributions",
        nargs="+",
        default=["uniform", "normal", "laplace", "student_t"],
    )
    parser.add_argument("--sizes", nargs="+", type=int, default=[3, 9, 16, 32])
    parser.add_argument("--repeats", type=int, default=5)
    parser.add_argument("--seed", type=int, default=2026)
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    for fp8_format in args.formats:
        if fp8_format not in _DEFAULT_RANGES:
            raise ValueError(f"unsupported FP8 format {fp8_format!r}")
        for distribution in args.distributions:
            for size in args.sizes:
                result = validate_case(
                    fp8_format=fp8_format,
                    distribution=distribution,
                    size=size,
                    repeats=args.repeats,
                    seed=args.seed,
                )
                print(
                    f"format={result.fp8_format} dist={result.distribution} "
                    f"size={result.size} "
                    f"rmse={result.rmse_mean:.8f} std={result.rmse_std:.8f}"
                )


if __name__ == "__main__":
    main()
