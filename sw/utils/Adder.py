from .Decoder import FP8_Codec

class Adder:
    def __init__(self, format: str = 'e3m4'):
        self.format = format
        self.e_bits, self.m_bits, _ = FP8_Codec._get_format_params(format)

    def int_bin_adder(self, a: str, b: str) -> str:
        """
        Add two binary strings and return the result as a binary string.

        :param a: Binary string
        :param b: Binary string
        :return: Sum of a and b as a binary string
        """
        # Ensure `a` is the longer string
        if len(a) < len(b):
            a, b = b, a

        # Reverse both strings to make addition easier (LSB first)
        a = a[::-1]
        b = b[::-1]

        carry = 0
        result = ""

        # Traverse each bit of the longer string
        for index, bit in enumerate(a):
            if index > len(b) - 1:   # If the shorter string is out of range
                b_bit = 0
            else:
                b_bit = int(b[index])

            total = int(bit) + b_bit + carry
            result += str(total % 2)   # Binary sum (0 or 1)

            # Update carry
            carry = 1 if total > 1 else 0

        # If there's a carry at the most significant bit
        if carry == 1:
            result += "1"

        # Reverse again to get the correct order
        return result[::-1]
        
    def fp_bin_adder(self, a_bin: str, b_bin: str) -> str:
        """
        FP8 addition fully in the binary domain (IEEE-like). Uses simple right-shift truncation
        when aligning exponents. Returns an 8-bit FP8 binary string.
        """

        EXP_BITS = self.e_bits
        MANT_BITS = self.m_bits
        EXP_ALL_ONES = (1 << EXP_BITS) - 1

        def decode_fields(bin_str: str):
            sign = 1 if bin_str[0] == '1' else 0
            exp = int(bin_str[1:1 + EXP_BITS], 2)
            mant = int(bin_str[1 + EXP_BITS:], 2)
            return sign, exp, mant

        sa, ea, ma = decode_fields(a_bin)
        sb, eb, mb = decode_fields(b_bin)

        # Special values (Inf/NaN)
        def is_nan(e, m): return e == EXP_ALL_ONES and m != 0
        def is_inf(e, m): return e == EXP_ALL_ONES and m == 0

        if is_nan(ea, ma) or is_nan(eb, mb):
            return '0' + '1' * EXP_BITS + ('0' * (MANT_BITS - 1) + '1' if MANT_BITS > 0 else '')
        if is_inf(ea, ma) and is_inf(eb, mb):
            if sa != sb:
                return '0' + '1' * EXP_BITS + ('0' * (MANT_BITS - 1) + '1' if MANT_BITS > 0 else '')
            return f"{sa:b}" + '1' * EXP_BITS + '0' * MANT_BITS
        if is_inf(ea, ma):
            return f"{sa:b}" + '1' * EXP_BITS + '0' * MANT_BITS
        if is_inf(eb, mb):
            return f"{sb:b}" + '1' * EXP_BITS + '0' * MANT_BITS

        # Zero shortcuts
        if ea == 0 and ma == 0:
            return b_bin
        if eb == 0 and mb == 0:
            return a_bin

        # Add hidden bit for normals
        if ea != 0:
            ma |= (1 << MANT_BITS)
        if eb != 0:
            mb |= (1 << MANT_BITS)

        # Exponent alignment (truncate on right shift)
        exp_res = ea
        if ea > eb:
            mb >>= (ea - eb)
        elif eb > ea:
            ma >>= (eb - ea)
            exp_res = eb

        # Signed mantissa add
        if sa:
            ma = -ma
        if sb:
            mb = -mb
        mant_res = ma + mb

        if mant_res == 0:
            return '0' + '0' * EXP_BITS + '0' * MANT_BITS

        # Sign & abs
        sign_res = 1 if mant_res < 0 else 0
        if mant_res < 0:
            mant_res = -mant_res

        # Normalize to align MSB to hidden-bit position
        msb_pos = mant_res.bit_length() - 1
        if msb_pos > MANT_BITS:
            shift = msb_pos - MANT_BITS
            mant_res >>= shift
            exp_res += shift
        elif msb_pos < MANT_BITS and exp_res > 0:
            shift = MANT_BITS - msb_pos
            mant_res <<= shift
            exp_res -= shift

        # Overflow -> Inf
        if exp_res >= EXP_ALL_ONES:
            return f"{sign_res:b}" + '1' * EXP_BITS + '0' * MANT_BITS

        # Pack (normal vs subnormal)
        if exp_res > 0:
            mant_out = mant_res & ((1 << MANT_BITS) - 1)
            return f"{sign_res:b}" + format(exp_res, f'0{EXP_BITS}b') + format(mant_out, f'0{MANT_BITS}b')
        else:
            # subnormal/underflow: clamp mantissa down to fit
            while mant_res >= (1 << MANT_BITS):
                mant_res >>= 1
            return f"{sign_res:b}" + '0' * EXP_BITS + format(mant_res, f'0{MANT_BITS}b')
        
if __name__ == "__main__":
    # Basic quick tests for Adder
    formats = ["e2m5", "e3m4", "e4m3", "e5m2"]

    print("=== int_bin_adder quick check ===")
    adder_tmp = Adder()  # format is irrelevant for integer adder
    print("  1011 + 0011 ->", adder_tmp.int_bin_adder("1011", "0011"))  # expect 10010
    print("  1111 + 0001 ->", adder_tmp.int_bin_adder("1111", "0001"))  # expect 10000
    print()

    for fmt in formats:
        print(f"=== fp_bin_adder quick check | format={fmt} ===")
        adder = Adder(format=fmt)

        def enc(x: float) -> str:
            return FP8_Codec.encode(x, fp_format=fmt)

        def dec(bits: str) -> float:
            v, *_ = FP8_Codec.decode(int(bits, 2), fp_format=fmt)
            return v

        # 1) small values (should not overflow)
        pairs = [
            (0.25, 0.125),
            (0.5, -0.25),
            (0.0, 0.0),
            (-0.125, -0.125),
        ]

        for a, b in pairs:
            a_bits = enc(a)
            b_bits = enc(b)
            s_bits = adder.fp_bin_adder(a_bits, b_bits)
            s_val = dec(s_bits)
            print(f"  {a: .6f} ({a_bits}) + {b: .6f} ({b_bits}) -> {s_bits} -> {s_val}")

        # 2) edge / specials
        pos_inf = enc(float("inf"))
        neg_inf = enc(-float("inf"))
        nan_bits = enc(float("nan"))

        def show(label, x_bits, y_bits):
            s_bits = adder.fp_bin_adder(x_bits, y_bits)
            s_val = dec(s_bits)  # will be inf or nan as per codec
            print(f"  {label}: {x_bits} ⊕ {y_bits} -> {s_bits} -> {s_val}")

        show("Inf + Inf", pos_inf, pos_inf)
        show("-Inf + -Inf", neg_inf, neg_inf)
        show("Inf + -Inf (NaN expected)", pos_inf, neg_inf)
        show("NaN + 1.0 (NaN expected)", nan_bits, enc(1.0))

        print()
