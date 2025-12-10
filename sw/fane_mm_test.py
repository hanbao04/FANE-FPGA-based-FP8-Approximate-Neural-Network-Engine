from utils.Multiplier import Multiplier
from utils.Adder import Adder   
from utils.Decoder import FP8_Codec
from utils.Multiplier import Multiplier
from utils.test_data_gen import Data_Gen
from Matmul import FP8MatrixMultiplier
import numpy as np

def fane_mm_test(format: str = 'e3m4'):
    brams = {}
    for i in range(1, 10):
        brams[f"bram_{i}_data"] = [
            '00110000', '00111000', '01000000', '01001000',
            '01010000', '01011000', '01100000', '01101000', '01010000'
        ]


    uram_1_data = [
        '00110000', '00110100', '00111000', '00111100',
        '01000000', '01000100', '01001000', '01001100', '01010000'
    ]


    matmul = FP8MatrixMultiplier(format=format)

    p = {}
    p["p_0"] = matmul.fasa_mac_unit(
        value_a=brams["bram_1_data"][0],
        value_b=uram_1_data[0],
        prod_t_1='00000000'
    )

    for i in range(1, 9):
        p[f"p_{i}"] = matmul.fasa_mac_unit(
            value_a=brams[f"bram_{i+1}_data"][i],   # bram_2_data[1] ... bram_9_data[8]
            value_b=uram_1_data[i],
            prod_t_1=p[f"p_{i-1}"]
        )

    for i in range(0, 9):
        print(f"p_{i} = {p[f'p_{i}']}")

if __name__ == "__main__":
    fane_mm_test(format='e5m2')