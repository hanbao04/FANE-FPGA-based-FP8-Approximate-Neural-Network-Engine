from utils.Multiplier import Multiplier
from utils.Adder import Adder   
from utils.Decoder import FP8_Codec
from utils.Multiplier import Multiplier
from utils.test_data_gen import Data_Gen
from Matmul import FP8MatrixMultiplier
import numpy as np

def test_data_in(format: str = 'e3m4'):
    # 定义测试数据字典
    # 每项是 [(a_bin, b_bin, c_bin), ...] 共5组
    fp8_tests = {
        'e2m5': [
            ('00100000', '00100000', '00100000'),  # 0.5×0.5+0.5
            ('00101000', '00101000', '00100000'),  # 0.625×0.625+0.5
            ('01000000', '00100000', '00100000'),  # 1.0×0.5+0.5
            ('01001000', '01001000', '00100000'),  # 1.125×1.125+0.5
            ('10100000', '10100000', '00100000'),  # (-0.5)×(-0.5)+0.5
        ],
        'e3m4': [
            ('00011000', '00011000', '00011000'),  # 0.25×0.25+0.25
            ('00100000', '00100000', '00011000'),  # 0.5×0.5+0.25
            ('00101000', '00101000', '00011000'),  # 1.0×1.0+0.25
            ('00110000', '00110000', '00011000'),  # 2.0×2.0+0.25
            ('10101000', '10101000', '00011000'),  # (-1.0)×(-1.0)+0.25
        ],
        'e4m3': [
            ('00111000', '00111000', '00111000'),  # 0.125×0.125+0.125
            ('01000000', '01000000', '00111000'),  # 0.25×0.25+0.125
            ('01001000', '01001000', '00111000'),  # 0.5×0.5+0.125
            ('01011000', '01011000', '00111000'),  # 2.0×2.0+0.125
            ('01100000', '01100000', '00111000'),  # 8.0×8.0+0.125
        ],
        'e5m2': [
            ('01111000', '01111000', '01011000'),  # 1.0×1.0+1.0
            ('10000000', '10000000', '01011000'),  # 2.0×2.0+1.0
            ('10001000', '10001000', '01011000'),  # 4.0×4.0+1.0
            ('10100000', '10100000', '01011000'),  # 32×32+1.0
            ('11000000', '11000000', '01011000'),  # 512×512+1.0
        ],
    }
    return fp8_tests


def mac_test(format: str = 'e3m4'):
    matmul = FP8MatrixMultiplier(format=format)
    fp8_tests = test_data_in(format)
    # 检查输入格式
    if format.lower() not in fp8_tests:
        raise ValueError(f"Unsupported FP8 format '{format}'. Choose from e2m5, e3m4, e4m3, e5m2.")

    print(f"========== MAC op test format {format} ==========")

    # 遍历每组数据
    for i, (a_bin, b_bin, c_bin) in enumerate(fp8_tests[format.lower()], start=1):
        res_bin = matmul.fasa_mac_unit(value_a=a_bin, value_b=b_bin, prod_t_1=c_bin)
        print(f"res_{i}: ")
        print(f"    Binary:  {a_bin} * {b_bin} + {c_bin} -> RESULT={res_bin}")
        if res_bin != 'pass':
            a_val = FP8_Codec.decode(int(a_bin, 2), format)[0]
            b_val = FP8_Codec.decode(int(b_bin, 2), format)[0]
            c_val = FP8_Codec.decode(int(c_bin, 2), format)[0]
            r_val = FP8_Codec.decode(int(res_bin, 2), format)[0]
            print(f"    Decimal: {a_val} x {b_val} + {c_val} = {r_val}\n")

    print("=== Tests completed ===\n")

def adder_test(format: str = 'e2m5'):
    adder_test_data = test_data_in(format)
    adder = Adder(format=format)
    print(f"========== Adder test format {format} ==========")
    for i, (a_bin, b_bin, c_bin) in enumerate(adder_test_data[format.lower()], start=1): 
        res_bin = adder.fp_bin_adder(a_bin=a_bin, b_bin=b_bin)
        
        print(f"res_{i}:")
        print(f"    Binary:  {a_bin} + {b_bin} -> RESULT={res_bin}")
        if res_bin != 'pass':
                a_val = FP8_Codec.decode(int(a_bin, 2), format)[0]
                b_val = FP8_Codec.decode(int(b_bin, 2), format)[0]
                r_val = FP8_Codec.decode(int(res_bin, 2), format)[0]
                print(f"    Decimal: {a_val} + {b_val} = {r_val}\n")

def add_mul_test(format: str = 'e3m4'):
    mul = Multiplier(format=format, bin_output=True)
    add_mul_data = test_data_in(format=format)
    print(f"========== Add-Mul test format {format} ==========")
    for i, (a_bin, b_bin, c_bin) in enumerate(add_mul_data[format.lower()], start=1): 
        res_bin = mul.FASA(value_a=b_bin, value_b=c_bin)
        
        print(f"res_{i}:")
        print(f"    Binary:  {b_bin} x {c_bin} -> RESULT={res_bin}")
        if res_bin != 'pass':
                b_val = FP8_Codec.decode(int(b_bin, 2), format)[0]
                c_val = FP8_Codec.decode(int(c_bin, 2), format)[0]
                r_val = FP8_Codec.decode(int(res_bin, 2), format)[0]
                print(f"    Decimal: {b_val} x {c_val} = {r_val}\n")

if __name__ == "__main__":
    # format = 'e3m4'
    # mac_test(format)
    # adder_test(format)
    # add_mul_test(format)
    for fmt in ['e2m5', 'e3m4', 'e4m3', 'e5m2']:
         mac_test(format=fmt)