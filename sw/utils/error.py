import math

class ErrorCalc:
    def __init__(self):
        pass

    @staticmethod
    def calculate_rmse(reference_result, approx_result):
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