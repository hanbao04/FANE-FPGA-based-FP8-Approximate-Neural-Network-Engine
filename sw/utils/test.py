from typing import Optional, Sequence, Dict, Any
from .data_gen import DataGen
from .top_matmul import FP8MatrixMultiplier
import numpy as np

class TESTER:
    def __init__(self):
        pass

    @staticmethod
    def test_fasa(size, format = format, dist = 'uniform',
                    value_range: Sequence[float] = (1.0, 2.0), 
                    dist_params: Optional[Dict[str, Any]] = None):
            """
            Test FASA matrix multiplication with generated data.
            
            Args:
                size (int): Size of the square matrix to test
                
            Returns:
                tuple: (reference_result, fasa_result)
                    - reference_result (numpy.ndarray): Exact element-wise product
                    - fasa_result (list): FASA approximate multiplication result
            """
            data_gen = DataGen(row=size, col=size, format=format,
                        dist=dist, value_range=value_range)

            # Generate test data
            mat_a, mat_b, mat_res = data_gen.fasa_test_data()
            
            # Perform FASA matrix multiplication
            matmul = FP8MatrixMultiplier(format=format)
            fasa_result = matmul.fasa_matrix_multiply(mat_a, mat_b)
            
            return mat_res, fasa_result
    
    @staticmethod
    def test_standard(size, format = format, dist = 'uniform',
                 value_range: Sequence[float] = (1.0, 2.0), 
                 dist_params: Optional[Dict[str, Any]] = None):
        """
        Test standard FP8 matrix multiplication with generated data.
        
        Args:
            size (int): Size of the square matrix to test
            
        Returns:
            tuple: (reference_result, standard_result)
                - reference_result (numpy.ndarray): Exact element-wise product
                - standard_result (list): Standard FP8 multiplication result
        """
        data_gen = DataGen(row=size, col=size, format=format,
                    dist=dist, value_range=value_range)

        # Generate test data
        mat_a, mat_b, mat_res = data_gen.fasa_test_data()
        
        # Perform standard FP8 matrix multiplication
        matmul = FP8MatrixMultiplier(format=format)
        standard_result = matmul.matrix_multiply(mat_a, mat_b)
        
        return mat_res, standard_result
    
    @staticmethod
    def test_lmul(size, format = format, dist = 'uniform',
                 value_range: Sequence[float] = (1.0, 2.0), 
                 dist_params: Optional[Dict[str, Any]] = None):
        """
        Test standard FP8 matrix multiplication with generated data.
        
        Args:
            size (int): Size of the square matrix to test
            
        Returns:
            tuple: (reference_result, standard_result)
                - reference_result (numpy.ndarray): Exact element-wise product
                - standard_result (list): Standard FP8 multiplication result
        """
        data_gen = DataGen(row=size, col=size, format=format,
                    dist=dist, value_range=value_range)

        # Generate test data
        mat_a, mat_b, mat_res = data_gen.fasa_test_data()
        
        # Perform standard FP8 matrix multiplication
        matmul = FP8MatrixMultiplier(format=format)
        standard_result = matmul.l_mul_matrix_multiply(mat_a, mat_b)
        
        return mat_res, standard_result