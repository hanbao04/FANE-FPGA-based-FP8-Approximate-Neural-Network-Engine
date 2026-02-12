import numpy as np
import math
import warnings
from utils.error import ErrorCalc
from utils.test import TESTER
from typing import Optional, Dict, Any

def run_test(format = format, dist = 'uniform', dist_params: Optional[Dict[str, Any]] = None):
    print(f'============= Data Dist = {dist} =============')
    fasa_runs, std_runs, lmul_runs = [], [], []
    fasa_error, standard_error, lmul_error = [], [], []
    range_val_dict = {
        'e2m5': (-0.3, 0.3),
        'e3m4': (-0.6, 0.6),
        'e4m3': (-1.0, 1.0),
        'e5m2': (-1.3, 1.3),
    }
    range_val = range_val_dict[format]
    for size in sizes:
        ref_fasa,  fasa_res  = TESTER.test_fasa(size=size, format=format, value_range=range_val, dist = dist)
        ref_std ,  std_res   = TESTER.test_standard(size=size, format=format, value_range=range_val, dist = dist)
        ref_lmul,  lmul_res  = TESTER.test_lmul(size=size, format=format, value_range=range_val, dist = dist)

        fasa_error.append(ErrorCalc.calculate_rmse       (ref_fasa,  fasa_res))
        standard_error.append(ErrorCalc.calculate_rmse   (ref_std,   std_res))
        lmul_error.append(ErrorCalc.calculate_rmse       (ref_lmul,  lmul_res))

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

if __name__ == "__main__":
    # Create matrix multiplier with E4M3 format
    
    
    tot_fasa_error = [0, 0, 0, 0, 0, 0, 0, 0]
    tot_standard_error = []
    tot_lmul_error = []
    max_iter = 40

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

    for fmt in ['e5m2', 'e4m3', 'e3m4', 'e2m5']:
        print(f"========================== Testing format: {fmt} ==========================")

        for it in range(max_iter):
            run_test(format=fmt, dist = 'uniform')
            run_test(format=fmt, dist = 'normal')
            run_test(format=fmt, dist = 'laplace')
            run_test(format=fmt, dist = 'student_t')
            
