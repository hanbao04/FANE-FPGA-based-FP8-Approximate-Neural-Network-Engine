import numpy as np
import math
import warnings
from .decoder import FP8Codec
from .adder import Adder
from .multiplier import Multiplier

class FP8MatrixMultiplier:
    """
    FP8 Matrix Multiplier using Element-wise Operations
    
    Performs matrix multiplication using FP8 element-wise multiplication
    and binary addition operations. Supports FASA approximate algorithm.
    """
    
    def __init__(self, format: str = 'e3m4'):
        """
        Initialize FP8 matrix multiplier.
        
        Args:
            exp_bit (int): Number of exponent bits in FP8 format
            mant_bit (int): Number of mantissa bits in FP8 format
        """
        exp_bit, mant_bit, _ = FP8Codec._get_format_params(format)
        self.format = format
        self.exp_bit = exp_bit
        self.mant_bit = mant_bit
        self.adder = Adder(format=format)
        self.multiplier = Multiplier(format=format, bin_output=True)

    def get_flag(self, val_bin: str) -> str:
        _, _, _, _, flag = FP8Codec.decode(int(val_bin, 2), fp_format=self.format)
        return flag

    def fasa_mac_unit(self, value_a: str, value_b: str, prod_t_1: str) -> str:
        if any(v == 'pass' for v in [value_a, value_b, prod_t_1]):
            return 'pass'
        
        flag_a = self.get_flag(value_a)
        flag_b = self.get_flag(value_b)
        if flag_a in ("infinity", "NaN") or flag_b in ("infinity", "NaN"):
            warnings.warn(f'Input inf or nan detected!')
            return 'pass'
        
        prod_t = self.multiplier.FASA(value_a, value_b)
        flag_prod = self.get_flag(prod_t)
        if flag_prod in ("infinity", "NaN"):
            warnings.warn(f'Multiplication inf or nan detected!')
            return 'pass'
        
        result = self.adder.fp_bin_adder(prod_t_1, prod_t)
        flag_result = self.get_flag(result)
        if flag_result in ("infinity", "NaN"):
            warnings.warn(f'Accumulation inf or nan detected!')
            return 'pass'
        
        return result
    
    def mac_unit(self, value_a: str, value_b: str, prod_t_1: str) -> str:
        if any(v == 'pass' for v in [value_a, value_b, prod_t_1]):
            return 'pass'
        
        flag_a = self.get_flag(value_a)
        flag_b = self.get_flag(value_b)
        if flag_a in ("infinity", "NaN") or flag_b in ("infinity", "NaN"):
            warnings.warn(f'Input inf or nan detected!')
            return 'pass'
        
        prod_t = self.multiplier.multiply(value_a, value_b)
        flag_prod = self.get_flag(prod_t)
        if flag_prod in ("infinity", "NaN"):
            warnings.warn(f'Multiplication inf or nan detected!')
            return 'pass'
        
        result = self.adder.fp_bin_adder(prod_t_1, prod_t)
        flag_result = self.get_flag(result)
        if flag_result in ("infinity", "NaN"):
            warnings.warn(f'Accumulation inf or nan detected!')
            return 'pass'
        
        return result
    
    def lmul_mac_unit(self, value_a: str, value_b: str, prod_t_1: str) -> str:
        if any(v == 'pass' for v in [value_a, value_b, prod_t_1]):
            return 'pass'
        
        flag_a = self.get_flag(value_a)
        flag_b = self.get_flag(value_b)
        if flag_a in ("infinity", "NaN") or flag_b in ("infinity", "NaN"):
            warnings.warn(f'Input inf or nan detected!')
            return 'input pass'
        
        prod_t = self.multiplier.L_Mul(value_a, value_b)
        flag_prod = self.get_flag(prod_t)
        if flag_prod in ("infinity", "NaN"):
            warnings.warn(f'Multiplication inf or nan detected!')
            return 'product pass'
        
        result = self.adder.fp_bin_adder(prod_t_1, prod_t)
        flag_result = self.get_flag(result)
        if flag_result in ("infinity", "NaN"):
            warnings.warn(f'Accumulation inf or nan detected!')
            return 'accumulation pass'
        
        return result

    def fasa_matrix_multiply(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        """
        Perform matrix multiplication: A (m*n) * B (n*p) = C (m*p)
        
        Args:
            A (numpy.ndarray): First matrix (m*n) with FP8 encoded elements
            B (numpy.ndarray): Second matrix (n*p) with FP8 encoded elements
            
        Returns:
            list: Result matrix C (m*p) with FP8 encoded elements
        """
        rows_a = A.shape[0]
        cols_a = A.shape[1]
        cols_b = B.shape[1]
        
        # Initialize result matrix with FP8 zero representation
        C = [[0 for _ in range(cols_b)] for _ in range(rows_a)]
        exp_bit, mant_bit, _ = FP8Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8Codec.encode(A[i][k], self.format)
                    value_b_str = FP8Codec.encode(B[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.fasa_mac_unit(value_a_str, value_b_str, dot_product)
                
                if dot_product == "pass":
                    C[i][j] = "pass"
                else:
                    val, *_ = FP8Codec.decode(int(dot_product, 2), fp_format=self.format)
                    C[i][j] = val
        
        return C
    
    def matrix_multiply(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        """
        Perform matrix multiplication: A (m*n) * B (n*p) = C (m*p)
        
        Args:
            A (numpy.ndarray): First matrix (m*n) with FP8 encoded elements
            B (numpy.ndarray): Second matrix (n*p) with FP8 encoded elements
            
        Returns:
            list: Result matrix C (m*p) with FP8 encoded elements
        """
        rows_a = A.shape[0]
        cols_a = A.shape[1]
        cols_b = B.shape[1]
        
        # Initialize result matrix with FP8 zero representation
        C = [[0 for _ in range(cols_b)] for _ in range(rows_a)]
        exp_bit, mant_bit, _ = FP8Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8Codec.encode(A[i][k], self.format)
                    value_b_str = FP8Codec.encode(B[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.mac_unit(value_a_str, value_b_str, dot_product)
                if dot_product == "pass":
                    C[i][j] = "pass"
                else:
                    val, *_ = FP8Codec.decode(int(dot_product, 2), fp_format=self.format)
                    C[i][j] = val
        
        return C

    def l_mul_matrix_multiply(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        """
        Perform matrix multiplication: A (m*n) * B (n*p) = C (m*p)
        
        Args:
            A (numpy.ndarray): First matrix (m*n) with FP8 encoded elements
            B (numpy.ndarray): Second matrix (n*p) with FP8 encoded elements
            
        Returns:
            list: Result matrix C (m*p) with FP8 encoded elements
        """
        rows_a = A.shape[0]
        cols_a = A.shape[1]
        cols_b = B.shape[1]
        
        # Initialize result matrix with FP8 zero representation
        C = [[0 for _ in range(cols_b)] for _ in range(rows_a)]
        exp_bit, mant_bit, _ = FP8Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8Codec.encode(A[i][k], self.format)
                    value_b_str = FP8Codec.encode(B[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.lmul_mac_unit(value_a_str, value_b_str, dot_product)
                if dot_product == "pass":
                    C[i][j] = "pass"
                else:
                    val, *_ = FP8Codec.decode(int(dot_product, 2), fp_format=self.format)
                    C[i][j] = val
        
        return C