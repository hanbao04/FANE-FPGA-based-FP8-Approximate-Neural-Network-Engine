import numpy as np
import math
import warnings
from utils.Decoder import FP8_Codec
from utils.Adder import Adder
from utils.Multiplier import Multiplier
from utils.test_data_gen import Data_Gen

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
        exp_bit, mant_bit, _ = FP8_Codec._get_format_params(format)
        self.format = format
        self.exp_bit = exp_bit
        self.mant_bit = mant_bit
        self.adder = Adder(format=format)
        self.multiplier = Multiplier(format=format, bin_output=True)

    def get_flag(self, val_bin: str) -> str:
        _, _, _, _, flag = FP8_Codec.decode(int(val_bin, 2), fp_format=self.format)
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
        exp_bit, mant_bit, _ = FP8_Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8_Codec.encode(A[i][k], self.format)
                    value_b_str = FP8_Codec.encode(B[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.fasa_mac_unit(value_a_str, value_b_str, dot_product)
                
                if dot_product == "pass":
                    C[i][j] = "pass"
                else:
                    val, *_ = FP8_Codec.decode(int(dot_product, 2), fp_format=self.format)
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
        exp_bit, mant_bit, _ = FP8_Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8_Codec.encode(A[i][k], self.format)
                    value_b_str = FP8_Codec.encode(B[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.mac_unit(value_a_str, value_b_str, dot_product)
                if dot_product == "pass":
                    C[i][j] = "pass"
                else:
                    val, *_ = FP8_Codec.decode(int(dot_product, 2), fp_format=self.format)
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
        exp_bit, mant_bit, _ = FP8_Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8_Codec.encode(A[i][k], self.format)
                    value_b_str = FP8_Codec.encode(B[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.lmul_mac_unit(value_a_str, value_b_str, dot_product)
                if dot_product == "pass":
                    C[i][j] = "pass"
                else:
                    val, *_ = FP8_Codec.decode(int(dot_product, 2), fp_format=self.format)
                    C[i][j] = val
        
        return C
    
    def test_fasa(self, size, value_range):
        """
        Test FASA matrix multiplication with generated data.
        
        Args:
            size (int): Size of the square matrix to test
            
        Returns:
            tuple: (reference_result, fasa_result)
                - reference_result (numpy.ndarray): Exact element-wise product
                - fasa_result (list): FASA approximate multiplication result
        """
        data_gen = Data_Gen(size, size, self.format, value_range)

        # Generate test data
        mat_a, mat_b, mat_res = data_gen.fasa_test_data()
        
        # Perform FASA matrix multiplication
        fasa_result = self.fasa_matrix_multiply(mat_a, mat_b)
        
        return mat_res, fasa_result
    
    def test_standard(self, size, value_range):
        """
        Test standard FP8 matrix multiplication with generated data.
        
        Args:
            size (int): Size of the square matrix to test
            
        Returns:
            tuple: (reference_result, standard_result)
                - reference_result (numpy.ndarray): Exact element-wise product
                - standard_result (list): Standard FP8 multiplication result
        """
        data_gen = Data_Gen(size, size, self.format, value_range)

        # Generate test data
        mat_a, mat_b, mat_res = data_gen.fasa_test_data()
        
        # Perform standard FP8 matrix multiplication
        standard_result = self.matrix_multiply(mat_a, mat_b)
        
        return mat_res, standard_result
    
    def test_lmul(self, size, value_range):
        """
        Test standard FP8 matrix multiplication with generated data.
        
        Args:
            size (int): Size of the square matrix to test
            
        Returns:
            tuple: (reference_result, standard_result)
                - reference_result (numpy.ndarray): Exact element-wise product
                - standard_result (list): Standard FP8 multiplication result
        """
        data_gen = Data_Gen(size, size, self.format, value_range)

        # Generate test data
        mat_a, mat_b, mat_res = data_gen.fasa_test_data()
        
        # Perform standard FP8 matrix multiplication
        standard_result = self.l_mul_matrix_multiply(mat_a, mat_b)
        
        return mat_res, standard_result

    def calculate_rmse(self, reference_result, approx_result):
        """
        Calculate only RMSE for quick evaluation.
        
        Args:
            reference_result (numpy.ndarray): Reference floating-point results
            approx_result (list): FASA approximate results in FP8 format
            
        Returns:
            float: Root Mean Square Error
        """
        squared_error_sum = 0
        count = 0
        
        for i in range(len(approx_result)):
            for j in range(len(approx_result[0])):
                # Decode FP8 result to float for comparison
                # fp8_value = int(fasa_result[i][j], 2)
                # decoded_value, _, _, _, _ = FP8Codec.decode(fp8_value, self.format)
                
                reference_value = reference_result[i][j]
                fasa_value = approx_result[i][j]
                squared_error = (reference_value - fasa_value) ** 2
                squared_error_sum += squared_error
                count += 1
        
        mse = squared_error_sum / count if count > 0 else 0
        rmse = math.sqrt(mse)
        return rmse

if __name__ == "__main__":
    # Create matrix multiplier with E4M3 format
    range_val_dict = {
        'e2m5': (-0.3, 0.3),
        'e3m4': (-0.6, 0.6),
        'e4m3': (-1.0, 1.0),
        'e5m2': (-1.3, 1.3),
    }
    
    tot_fasa_error = [0, 0, 0, 0, 0, 0, 0, 0]
    tot_standard_error = []
    tot_lmul_error = []
    max_iter = 4

    sizes = [3, 6, 9, 16, 32, 48, 64, 128]

    # t_{0.975, df} 查表（双侧95%），df = n-1；n>=30 用正态近似 1.96
    _T975 = {
        1:12.706, 2:4.303, 3:3.182, 4:2.776, 5:2.571, 6:2.447, 7:2.365, 8:2.306, 9:2.262,
        10:2.228,11:2.201,12:2.179,13:2.160,14:2.145,15:2.131,16:2.120,17:2.110,18:2.101,
        19:2.093,20:2.086,21:2.080,22:2.074,23:2.069,24:2.064,25:2.060,26:2.056,27:2.052,
        28:2.048,29:2.045
    }
    def t_crit_975(n):
        if n is None or n <= 1:
            return float('nan')
        df = n - 1
        if df in _T975:
            return _T975[df]
        return 1.96  # n>=30 近似

    for fmt in ['e5m2']:
        print(f"Testing format: {fmt}")

        fasa_runs, std_runs, lmul_runs = [], [], []

        for it in range(max_iter):
            mat_mult = FP8MatrixMultiplier(format=fmt)
            fasa_error, standard_error, lmul_error = [], [], []
            range_val = range_val_dict[fmt]
            for size in sizes:
                ref_fasa,  fasa_res  = mat_mult.test_fasa(size=size, value_range=range_val)
                ref_std,   std_res   = mat_mult.test_standard(size=size, value_range=range_val)
                ref_lmul,  lmul_res  = mat_mult.test_lmul(size=size, value_range=range_val)

                fasa_error.append(mat_mult.calculate_rmse(ref_fasa,  fasa_res))
                standard_error.append(mat_mult.calculate_rmse(ref_std,   std_res))
                lmul_error.append(mat_mult.calculate_rmse(ref_lmul,  lmul_res))

            fasa_runs.append(fasa_error)
            std_runs.append(standard_error)
            lmul_runs.append(lmul_error)

        # (n_runs, T)
        fasa_runs = np.asarray(fasa_runs, dtype=float)
        std_runs  = np.asarray(std_runs,  dtype=float)
        lmul_runs = np.asarray(lmul_runs, dtype=float)

        # 均值 & 样本标准差
        fasa_mean, fasa_std = fasa_runs.mean(axis=0), fasa_runs.std(axis=0, ddof=1)
        std_mean,  std_std  = std_runs.mean(axis=0),  std_runs.std(axis=0,  ddof=1)
        lmul_mean, lmul_std = lmul_runs.mean(axis=0), lmul_runs.std(axis=0, ddof=1)

        # 95% 置信区间半宽 = t_{0.975, n-1} * (std / sqrt(n))
        n = fasa_runs.shape[0]
        tcrit = t_crit_975(n)
        fasa_ci95 = tcrit * fasa_std / math.sqrt(n)
        std_ci95  = tcrit * std_std  / math.sqrt(n)
        lmul_ci95 = tcrit * lmul_std / math.sqrt(n)

        # 打印结果
        def fmt_arr(a): return [float(f"{v:.6f}") for v in a]
        print(f"n_runs = {n}, t_crit_0.975 = {tcrit:.3f}")
        print(f"fasa_{fmt}_mean = {fmt_arr(fasa_mean)}")
        print(f"fasa_{fmt}_std  = {fmt_arr(fasa_std)}")
        print(f"fasa_{fmt}_ci_high = {fmt_arr(fasa_mean + fasa_ci95)}")
        print(f"fasa_{fmt}_ci_low = {fmt_arr(fasa_mean - fasa_ci95)}")

        print(f"standard_{fmt}_mean = {fmt_arr(std_mean)}")
        print(f"standard_{fmt}_std  = {fmt_arr(std_std)}")
        print(f"standard_{fmt}_ci_high = {fmt_arr(std_mean + std_ci95)}")
        print(f"standard_{fmt}_ci_low = {fmt_arr(std_mean - std_ci95)}")

        print(f"lmul_{fmt}_mean = {fmt_arr(lmul_mean)}")
        print(f"lmul_{fmt}_std  = {fmt_arr(lmul_std)}")
        print(f"lmul_{fmt}_ci_high = {fmt_arr(lmul_mean + lmul_ci95)}")
        print(f"lmul_{fmt}_ci_low = {fmt_arr(lmul_mean - lmul_ci95)}")

