import math

def sine_function(x):
    return math.sin(x)

def generate_sine_lut(num_samples, amplitude, num_bits):
    max_value = 2 ** (num_bits - 1) - 1
    phase_step = 2 * math.pi / num_samples
    
    with open("sin_LUT.coe", "w") as file:
        file.write("memory_initialization_radix=10;\n")
        file.write("memory_initialization_vector=\n")
        
        for i in range(num_samples):
            phase = i * phase_step
            sine_value = sine_function(phase)
            quantized_value = int(round(sine_value * max_value))
            
            if i == num_samples - 1:
                file.write(f"{quantized_value};\n")
            else:
                file.write(f"{quantized_value},\n")

# Configuration parameters
num_samples = 1024
amplitude = 1.0
num_bits = 16

generate_sine_lut(num_samples, amplitude, num_bits)