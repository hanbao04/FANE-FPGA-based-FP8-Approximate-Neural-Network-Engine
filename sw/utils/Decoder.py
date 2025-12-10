import numpy as np
import math

class FP8_Codec:
    """
    FP8 format converter for encoding and decoding between floating-point numbers and FP8 representations.
    Supports formats: 'e2m5', 'e3m4', 'e4m3', 'e5m2'
    """
    
    # Format mapping: format_name -> (exponent_bits, mantissa_bits)
    FORMATS = {
        "e2m5": (2, 5),
        "e3m4": (3, 4),
        "e4m3": (4, 3),
        "e5m2": (5, 2),
    }
    
    @staticmethod
    def _get_format_params(fp_format: str):
        """
        Get format parameters for the specified FP8 format.
        
        Args:
            fp_format (str): FP8 format name
            
        Returns:
            tuple: (exponent_bits, mantissa_bits, bias)
        """
        if fp_format not in FP8_Codec.FORMATS:
            raise ValueError(f'Unsupported format "{fp_format}". Choose from {list(FP8_Codec.FORMATS.keys())}')
        
        e_bits, m_bits = FP8_Codec.FORMATS[fp_format]
        bias = (2 ** (e_bits - 1) - 1)
        return e_bits, m_bits, bias
    
    @staticmethod
    def decode(input_data: int, fp_format: str = "e4m3", custom_bias: int | None = None) -> tuple:
        """
        Decode a single FP8 value to floating-point representation.
        
        Args:
            input_data (int): 8-bit integer in range 0..255
            fp_format (str): FP8 format name
            custom_bias (int | None): Custom bias value to override default
            
        Returns:
            tuple: (value, unbiased_exponent, fraction, significand, flag)
                - value (float): Decoded floating-point value
                - unbiased_exponent (int): Unbiased exponent
                - fraction (float): Fraction part (mantissa / 2^mantissa_bits)
                - significand (float): Significand (1 + fraction for normals)
                - flag (str): Classification flag
        """
        if not (0 <= input_data <= 0xFF):
            raise ValueError("input_data must be an 8-bit integer in range 0..255")

        e_bits, m_bits, default_bias = FP8_Codec._get_format_params(fp_format)
        bias = default_bias if custom_bias is None else int(custom_bias)
        mant_scale = 1 << m_bits
        exp_all_ones = (1 << e_bits) - 1

        b = int(input_data) & 0xFF

        # Extract fields: [sign][exponent][mantissa]
        sign = (b >> (e_bits + m_bits)) & 0x1
        exp_raw = (b >> m_bits) & ((1 << e_bits) - 1)
        mant = b & ((1 << m_bits) - 1)

        # Classify and decode
        if exp_raw == 0:
            if mant == 0:
                # Zero (+0 or -0)
                E = 1 - bias
                M = 0.0
                value = -0.0 if sign == 1 else 0.0
                flag = "zero"
            else:
                # Denormalized number
                E = 1 - bias
                M = mant / mant_scale
                val = M * (2.0 ** E)
                value = -val if sign == 1 else val
                flag = "denormalized"
        elif exp_raw == exp_all_ones:
            if mant == 0:
                # Infinity
                E = 0
                M = 0.0
                value = -np.inf if sign == 1 else np.inf
                flag = "infinity"
            else:
                # NaN
                E = 0
                M = np.nan
                value = np.nan
                flag = "NaN"
        else:
            # Normalized number
            E = exp_raw - bias
            M = 1.0 + mant / mant_scale
            val = M * (2.0 ** E)
            value = -val if sign == 1 else val
            flag = "normalized"

        return float(value), int(E), float(mant / mant_scale), float(M), flag

    @staticmethod
    def encode(decimal_number: float, fp_format: str = "e4m3") -> str:
        """
        Encode a floating-point number to FP8 binary representation.
        
        Args:
            decimal_number: Floating-point number to encode
            fp_format (str): FP8 format name
            
        Returns:
            str: 8-bit binary string representation
        """
        e_bits, m_bits, bias = FP8_Codec._get_format_params(fp_format)
        total_bits = 1 + e_bits + m_bits
        max_exp = (1 << e_bits) - 1

        # Handle special cases
        if math.isnan(decimal_number):
            # NaN: exponent all ones, mantissa non-zero
            return '0' + '1' * e_bits + '1' + '0' * (m_bits - 1)
        
        if math.isinf(decimal_number):
            # Infinity: exponent all ones, mantissa all zeros
            sign_bit = '1' if decimal_number < 0 else '0'
            return sign_bit + '1' * e_bits + '0' * m_bits
        
        # Handle zero
        if decimal_number == 0:
            return '0' * total_bits
        
        # Extract sign
        sign_bit = '1' if decimal_number < 0 else '0'
        x = abs(decimal_number)
        
        # Calculate exponent and mantissa
        if x == 0:
            exp_raw = 0
            mant = 0
        else:
            # Calculate binary exponent
            exp_unbiased = math.floor(math.log2(x))
            exp_raw = exp_unbiased + bias
            
            # Handle overflow
            if exp_raw >= max_exp:
                # Overflow to infinity
                return sign_bit + '1' * e_bits + '0' * m_bits
            
            # Handle denormal numbers
            if exp_raw <= 0:
                if exp_raw < -(m_bits - 1):  # Underflow to zero
                    return sign_bit + '0' * e_bits + '0' * m_bits
                
                # Denormal number
                exp_raw = 0
                fraction = x / (2.0 ** (1 - bias))
                mant = round(fraction * (1 << m_bits))
                if mant >= (1 << m_bits):  # Rounding to smallest normal
                    exp_raw = 1
                    mant = 0
                elif mant == 0:  # Underflow to zero
                    return sign_bit + '0' * e_bits + '0' * m_bits
            else:
                # Normal number
                fraction = (x / (2.0 ** exp_unbiased)) - 1.0
                mant = round(fraction * (1 << m_bits))
                
                # Handle mantissa carry
                if mant == (1 << m_bits):
                    mant = 0
                    exp_raw += 1
                    if exp_raw >= max_exp:  # Carry causes overflow
                        return sign_bit + '1' * e_bits + '0' * m_bits
        
        # Convert to binary
        exp_binary = format(exp_raw, f'0{e_bits}b')
        mant_binary = format(mant, f'0{m_bits}b')
        
        return sign_bit + exp_binary + mant_binary

    @staticmethod
    def encode_to_int(decimal_number, fp_format: str = "e4m3") -> int:
        """
        Encode a floating-point number to FP8 integer representation.
        
        Args:
            decimal_number: Floating-point number to encode
            fp_format (str): FP8 format name
            
        Returns:
            int: 8-bit integer representation (0-255)
        """
        binary_str = FP8_Codec.encode(decimal_number, fp_format)
        return int(binary_str, 2)
    
    @staticmethod
    def range_info(fp_format: str | None = None):
        """
        打印或返回 FP8 格式的数值范围（normalized 与 denormalized）。

        Args:
            fp_format (str | None): 
                - 指定格式 ('e2m5', 'e3m4', 'e4m3', 'e5m2')
                - 为 None 时输出所有格式信息

        Returns:
            dict 或 None:
                - 若指定格式，则返回包含范围的 dict；
                - 若为 None，则仅打印所有格式的范围信息。
        """
        def compute_range(fmt: str):
            e_bits, m_bits, bias = FP8_Codec._get_format_params(fmt)
            mant_scale = 1 << m_bits
            exp_all_ones = (1 << e_bits) - 1

            # Normalized range
            exp_min_norm = 1 - bias
            exp_max_norm = exp_all_ones - 2 - bias  # exclude Inf/NaN
            norm_min = (1.0) * (2.0 ** exp_min_norm)
            norm_max = (2.0 - 2.0 ** (-m_bits)) * (2.0 ** exp_max_norm)

            # Denormalized range (exp=0)
            denorm_min = (2.0 ** (1 - bias)) * (1.0 / mant_scale)
            denorm_max = (2.0 ** (1 - bias)) * ((mant_scale - 1) / mant_scale)

            return {
                "normalized_min": norm_min,
                "normalized_max": norm_max,
                "denorm_min": denorm_min,
                "denorm_max": denorm_max,
            }

        # === 单独格式 ===
        if fp_format is not None:
            if fp_format not in FP8_Codec.FORMATS:
                raise ValueError(f"Unsupported format '{fp_format}'. Must be one of {list(FP8_Codec.FORMATS.keys())}")
            result = compute_range(fp_format)
            print(f"{fp_format.upper():>5} | normalized=[{result['normalized_min']:.3e}, {result['normalized_max']:.3e}]"
                  f"  denorm=[{result['denorm_min']:.3e}, {result['denorm_max']:.3e}]")
            return result

        # === 打印所有格式 ===
        print("\n=== FP8 Range Info ===")
        for fmt in ["e2m5", "e3m4", "e4m3", "e5m2"]:
            r = compute_range(fmt)
            print(f"{fmt.upper():>5} | normalized=[{r['normalized_min']:.3e}, {r['normalized_max']:.3e}]"
                  f"  denorm=[{r['denorm_min']:.3e}, {r['denorm_max']:.3e}]")
        return None

if __name__ == "__main__": 
    FP8_Codec.range_info()
    print("=== FP8 Codec Consistency Test ===")

    # 定义每个格式要测试的 5 组二进制输入
    test_vectors = {
        "e2m5": [
            "00000000", "00100000", "01000000", "01111100", "10100000"
        ],
        "e3m4": [
            "00000000", "00011000", "01000000", "01111100", "10101000"
        ],
        "e4m3": [
            "00000000", "00111000", "01000000", "01111000", "10101000"
        ],
        "e5m2": [
            "00000000", "01111000", "10000000", "10100000", "11000000"
        ],
    }

    for fmt, bin_list in test_vectors.items():
        print(f"\n=== Testing {fmt.upper()} ===")

        for i, test_data_str in enumerate(bin_list, start=1):
            test_data = int(test_data_str, 2)

            # Decode
            v, _, _, _, flag = FP8_Codec.decode(test_data, fmt)
            print(f"[{fmt}] Case {i}: bin -> dec: {test_data_str} -> {v:.8g} || flag: {flag}")

            # Encode back
            try:
                fp8_bin = FP8_Codec.encode(v, fmt)
                match = (test_data_str == fp8_bin)
                print(f"          dec -> bin: {v:.8g} -> {fp8_bin} | match={match}")
            except Exception as e:
                print(f"          编码错误: {e}")
