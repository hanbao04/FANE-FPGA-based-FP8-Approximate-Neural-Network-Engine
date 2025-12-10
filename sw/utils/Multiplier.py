from .Decoder import FP8_Codec
from .Adder import Adder

class Multiplier:
    def __init__(self, format: str = 'e3m4', bin_output: bool = False):
        e_bits, m_bits, bias = FP8_Codec._get_format_params(format)
        self.fmt = format
        self.exp_bits = e_bits
        self.mant_bits = m_bits
        self.bias = bias
        self.adder = Adder(format=format)
        self.bin_output = bin_output

    def _unpakcing(self, value: str) -> tuple:
        """
        Unpack an FP8 binary string into its sign, exponent, and mantissa components.
        
        Args:
            value (str): FP8 number as an 8-bit binary string
        Returns:
            tuple: (sign (int), exponent (str), mantissa (str))
        """
        sign = value[0]
        exponent = value[1:1 + self.exp_bits]
        mantissa = value[1 + self.exp_bits:]
        return sign, exponent, mantissa

    def _em_cul(self, exp: str, man: str) -> list:
        """
        Calculate exponent and mantissa values from binary representation.
        
        Args:
            exp (str): Exponent bits as binary string
            man (str): Mantissa bits as binary string
            
        Returns:
            list: [exponent_value, mantissa_value]
        """
        # Handle denormalized numbers (exponent all zeros)
        if exp == f"{0:0{self.exp_bits}b}":
            # Denormalized number
            e = 1 - self.bias
            m = -1  # Special flag for denormalized
        else:
            # Normalized number
            e = int(exp, 2) - self.bias
            m = 0
        
        # Calculate mantissa fractional value
        for i in range(0, self.mant_bits):
            m += int(man[i], 2) / (2**(i+1))
        
        return [e, m]
    
    def decimal(self, value_a: str, value_b: str) -> list:
        """
        Convert both FP8 binary values to their decimal representations.
        
        Returns:
            list: [decimal_value1, decimal_value2]
        """
        sign1, exp1, man1 = self._unpakcing(value_a)
        sign2, exp2, man2 = self._unpakcing(value_b)   

        x = self._em_cul(exp1, man1)
        y = self._em_cul(exp2, man2)
        
        d1 = (1 + x[1]) * (2**x[0]) if sign1 == '0' else -1 * (1 + x[1]) * (2**x[0])
        d2 = (1 + y[1]) * (2**y[0]) if sign2 == '0' else -1 * (1 + y[1]) * (2**y[0])

        return [d1, d2]
    
    def multiply(self, value_a: str, value_b: str):
        """
        Perform FP8 multiplication of the two values.
        
        Returns:
            float/str: Result of the multiplication
        """
        sign1, exp1, man1 = self._unpakcing(value_a)
        sign2, exp2, man2 = self._unpakcing(value_b)  
        sign = int(sign1) ^ int(sign2) 
        x = self._em_cul(exp1, man1)
        y = self._em_cul(exp2, man2)

        mul_xy = (1 + x[1] + y[1] + x[1] * y[1]) * (2**(x[0] + y[0]))
        if sign == 1:
            mul_xy = -mul_xy

        return mul_xy if self.bin_output == False else FP8_Codec.encode(mul_xy, self.fmt)
    
    def L_Mul(self, value_a: str, value_b: str):
        """
        Perform FP8 multiplication using logarithmic method.
        
        Returns:
            float/str: Result of the multiplication
        """
        sign1, exp1, man1 = self._unpakcing(value_a)
        sign2, exp2, man2 = self._unpakcing(value_b)   
        sign = int(sign1) ^ int(sign2) 
        x = self._em_cul(exp1, man1)
        y = self._em_cul(exp2, man2)

        # Determine approximation level based on mantissa bits
        if self.mant_bits <= 3:
            lm = self.mant_bits
        elif self.mant_bits == 4:
            lm = 3
        else:
            lm = 4

        # Linear approximation formula
        L_mul_xy = (1 + x[1] + y[1] + 2**(-lm)) * (2**(x[0] + y[0]))
        if sign == 1:
            L_mul_xy = -L_mul_xy
        
        return L_mul_xy if self.bin_output == False else FP8_Codec.encode(L_mul_xy, self.fmt)
    
    def FASA(self, value_a: str, value_b: str) -> str:
        """
        Perform FP8 multiplication using logarithmic method followed by addition using FP8 adder.
        
        Returns:
            str: Result of the multiplication in FP8 binary string format
        """
        sign1, exp1, man1 = self._unpakcing(value_a)
        sign2, exp2, man2 = self._unpakcing(value_b)   
        sign = int(sign1) ^ int(sign2) 
        mul1 = exp1 + man1
        mul2 = exp2 + man2

        # Perform binary addition
        sum_binary = "{0:0>8}".format(self.adder.int_bin_adder(mul1, mul2))
        # Extract new exponent and mantissa from sum
        exp = sum_binary[0: self.exp_bits+1]
        man = sum_binary[self.exp_bits+1: 8]

        # Calculate new value
        xy = self._em_cul(exp, man)
        L_mul_xy = (1 + xy[1]) * (2**(xy[0] - self.bias))
        
        # Apply sign
        if sign == 1:
            L_mul_xy = -L_mul_xy
        
        return L_mul_xy if self.bin_output == False else FP8_Codec.encode(L_mul_xy, self.fmt)