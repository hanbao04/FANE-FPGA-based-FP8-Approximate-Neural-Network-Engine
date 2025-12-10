import numpy as np
from typing import Optional, Sequence, Tuple, Union
from .Decoder import FP8_Codec
from .Multiplier import Multiplier
from .Adder import Adder


SeedType = Optional[Union[int, Tuple[int, int]]]


class Data_Gen:
    """
    Data generator for FASA testing.

    Generates two random matrices (uniform distribution) and the element-wise
    reference product. Matrices are plain float arrays (not FP8-encoded).
    """

    def __init__(self, row: int, col: int, format: str = 'e4m3', value_range: Sequence[float] = (1.0, 2.0)) -> None:
        """
        Initialize the data generator.

        Args:
            row: Number of rows.
            col: Number of columns.
            value_range: (min, max) for the uniform distribution.
        """
        if not isinstance(row, int) or not isinstance(col, int) or row <= 0 or col <= 0:
            raise ValueError("row and col must be positive integers.")

        if (not isinstance(value_range, (list, tuple)) or len(value_range) != 2 or
                not all(isinstance(x, (int, float)) for x in value_range)):
            raise ValueError("value_range must be a 2-element sequence of numbers: (min, max).")

        vmin, vmax = float(value_range[0]), float(value_range[1])
        if not (vmin < vmax):
            raise ValueError("value_range must satisfy min < max.")

        self.row: int = row
        self.col: int = col
        self.vmin: float = vmin
        self.vmax: float = vmax
        self.format = format
        self.adder = Adder(format=format)
        self.multiplier = Multiplier(format=format, bin_output=True)

    @staticmethod
    def _make_rng(seed: Optional[int]) -> np.random.Generator:
        """Create a numpy Generator with an optional integer seed."""
        if seed is None:
            return np.random.default_rng()
        if not isinstance(seed, int):
            raise ValueError("Seed must be an int or None.")
        return np.random.default_rng(seed)

    def _generate_matrix(self, rng: np.random.Generator) -> np.ndarray:
        """
        Generate a (row, col) matrix with uniform distribution in [vmin, vmax).

        Args:
            rng: A numpy random Generator.

        Returns:
            A NumPy array of shape (row, col), dtype=float64 by default.
        """
        return rng.uniform(self.vmin, self.vmax, size=(self.row, self.col))
    
    def mac_unit(self, value_a: str, value_b: str, prod_t_1: str) -> str:
        prod_t = self.multiplier.multiply(value_a, value_b)
        result = self.adder.fp_bin_adder(prod_t_1, prod_t)
        return result

    def fasa_test_data(self, seed: SeedType = None
                       ) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """
        Generate two random matrices and their element-wise product (reference).

        Args:
            format: FP8 format string (kept for API compatibility; not used here).
            seed: Random seed control.
                  - None: independent RNGs (non-deterministic)
                  - int: same seed for both matrices (deterministic but correlated)
                  - (int, int): separate seeds for A and B

        Returns:
            (mat_a, mat_b, mat_res):
                mat_a: first float matrix, shape (row, col)
                mat_b: second float matrix, shape (row, col)
                mat_res: element-wise product, shape (row, col)
        """
        # Interpret seed
        if seed is None:
            rng_a = self._make_rng(None)
            rng_b = self._make_rng(None)
        elif isinstance(seed, int):
            rng_a = self._make_rng(seed)
            rng_b = self._make_rng(seed + 1)  # different stream, still deterministic
        elif (isinstance(seed, tuple) and len(seed) == 2
              and all(isinstance(s, int) for s in seed)):
            rng_a = self._make_rng(seed[0])
            rng_b = self._make_rng(seed[1])
        else:
            raise ValueError("seed must be None, int, or a tuple of two ints (seed_a, seed_b).")

        # Generate matrices
        mat_a = self._generate_matrix(rng_a)
        mat_b = self._generate_matrix(rng_b)
        rows_a = mat_a.shape[0]
        cols_a = mat_a.shape[1]
        rows_b = mat_b.shape[0]
        cols_b = mat_b.shape[1]
        
        # Initialize result matrix with FP8 zero representation
        mat_c = [[0 for _ in range(cols_b)] for _ in range(rows_a)]
        exp_bit, mant_bit, _ = FP8_Codec._get_format_params(self.format)
        for i in range(rows_a):
            for j in range(cols_b):
                # Initialize accumulator with FP8 zero
                dot_product = '0' * (1 + exp_bit + mant_bit)  # FP8 representation of 0.0
                for k in range(cols_a):
                    value_a_str = FP8_Codec.encode(mat_a[i][k], self.format)
                    value_b_str = FP8_Codec.encode(mat_b[k][j], self.format)
                    # Element-wise multiplication
                    dot_product = self.mac_unit(value_a_str, value_b_str, dot_product)
                val, *_ = FP8_Codec.decode(int(dot_product, 2), fp_format=self.format)
                mat_c[i][j] = val

        return mat_a, mat_b, mat_c


if __name__ == "__main__":
    # Demo usage
    gen = Data_Gen(row=3, col=4, value_range=(1.0, 2.0))

    # Deterministic example with separate seeds for A and B
    A, B, C = gen.fasa_test_data(format="e4m3", seed=(8, 10))

    np.set_printoptions(precision=6, suppress=True)
    print("Matrix A:")
    print(A)
    print("\nMatrix B:")
    print(B)
    print("\nReference result (A * B):")
    print(C)
