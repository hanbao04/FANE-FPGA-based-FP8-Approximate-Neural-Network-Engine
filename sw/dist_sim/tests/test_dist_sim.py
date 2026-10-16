import pytest


torch = pytest.importorskip("torch")

from sw.dist_sim import (  # noqa: E402
    dequantize_from_fp8,
    fane_add_bits,
    fane_matmul,
    fane_mul_bits,
    quantize_to_fp8,
)


@pytest.mark.parametrize("fp8_format", ["e2m5", "e3m4", "e4m3", "e5m2"])
def test_codec_round_trip_for_exact_values(fp8_format):
    values = torch.tensor([0.0, 0.5, 1.0, 1.5, -0.5, -1.0, -2.0])
    bits = quantize_to_fp8(values, fp8_format)
    decoded = dequantize_from_fp8(bits, fp8_format)
    torch.testing.assert_close(decoded, values, rtol=0, atol=0)


@pytest.mark.parametrize("fp8_format", ["e2m5", "e3m4", "e4m3", "e5m2"])
def test_fane_one_times_one_and_zero(fp8_format):
    inputs = quantize_to_fp8(torch.tensor([1.0, 0.0, -1.0]), fp8_format)
    rhs = quantize_to_fp8(torch.tensor([1.0, -2.0, -1.0]), fp8_format)
    product = fane_mul_bits(inputs, rhs, fp8_format)
    decoded = dequantize_from_fp8(product, fp8_format)
    torch.testing.assert_close(decoded, torch.tensor([1.0, 0.0, 1.0]), rtol=0, atol=0)


def test_rne_ties_choose_even_mantissa():
    values = torch.tensor([1.0625, 1.1875])
    decoded = dequantize_from_fp8(quantize_to_fp8(values, "e4m3"), "e4m3")
    torch.testing.assert_close(decoded, torch.tensor([1.0, 1.25]), rtol=0, atol=0)


def test_rne_mantissa_carry_into_special_exponent_becomes_infinity():
    values = torch.tensor([250.375, -250.375], dtype=torch.float16)
    bits = quantize_to_fp8(values, "e4m3")
    assert bits.tolist() == [0x78, 0xF8]


def test_optimized_fane_out_of_range_product_becomes_zero():
    tiny = quantize_to_fp8(torch.tensor([2.0**-9]), "e4m3")
    largest = torch.tensor([0x77], dtype=torch.uint8)
    assert fane_mul_bits(tiny, tiny, "e4m3").item() == 0
    assert fane_mul_bits(largest, largest, "e4m3").item() == 0


def test_pure_fp8_adder_uses_original_truncating_alignment():
    lhs = quantize_to_fp8(torch.tensor([1.0]), "e4m3")
    rhs = quantize_to_fp8(torch.tensor([0.1875]), "e4m3")
    output = fane_add_bits(lhs, rhs, "e4m3")
    decoded = dequantize_from_fp8(output, "e4m3")
    torch.testing.assert_close(decoded, torch.tensor([1.125]), rtol=0, atol=0)


def test_matmul_uses_truncating_fp8_accumulation():
    lhs = quantize_to_fp8(torch.tensor([[1.0, 1.0]]), "e4m3")
    rhs = quantize_to_fp8(torch.tensor([[1.0], [0.1875]]), "e4m3")

    output = fane_matmul(lhs, rhs, "e4m3")

    torch.testing.assert_close(
        dequantize_from_fp8(output, "e4m3"),
        torch.tensor([[1.125]]),
        rtol=0,
        atol=0,
    )


def test_matmul_nine_term_dot_product():
    lhs = quantize_to_fp8(torch.ones((1, 9)), "e4m3")
    rhs = quantize_to_fp8(torch.ones((9, 1)), "e4m3")
    output = fane_matmul(lhs, rhs, "e4m3")
    decoded = dequantize_from_fp8(output, "e4m3")
    torch.testing.assert_close(decoded, torch.tensor([[9.0]]), rtol=0, atol=0)


def test_matmul_ten_term_dot_product():
    lhs = quantize_to_fp8(torch.ones((1, 10)), "e4m3")
    rhs = quantize_to_fp8(torch.ones((10, 1)), "e4m3")
    output = fane_matmul(lhs, rhs, "e4m3")
    expected = quantize_to_fp8(torch.tensor([[10.0]]), "e4m3")
    assert torch.equal(output, expected)


def test_matmul_uses_nine_term_blocks_before_fp8_writeback():
    # Every value is normal and finite. Serial FP8 addition stalls at 16;
    # the hardware produces two partial sums of 9 and writes back 18.
    lhs = torch.full((1, 18), 0x38, dtype=torch.uint8)
    rhs = torch.full((18, 1), 0x38, dtype=torch.uint8)
    assert fane_matmul(lhs, rhs).item() == 0x59


def test_blocked_matmul_matches_two_result_memory_passes():
    lhs = quantize_to_fp8(torch.tensor([[0.5] * 9 + [0.75] * 9]))
    rhs = quantize_to_fp8(torch.tensor([[1.0]] * 9 + [[0.5]] * 9))
    first = fane_matmul(lhs[:, :9], rhs[:9])
    second = fane_matmul(lhs[:, 9:], rhs[9:])
    assert torch.equal(fane_matmul(lhs, rhs), fane_add_bits(first, second))
