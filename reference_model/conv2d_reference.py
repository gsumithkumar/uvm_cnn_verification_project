#!/usr/bin/env python3
"""
CNN Conv2D Layer Reference Model

This Python reference model performs the same convolution operation as the
VHDL DUT for verification purposes. It can be used to:
- Generate golden reference outputs for testing
- Verify simulation results offline
- Debug mismatches between DUT and expected results

The computation matches the VHDL implementation:
1. Convolution: sum(input[i,j] * weight[i,j]) for 3x3 window
2. Add bias
3. Apply ReLU with M0 scaling: if result > 0: result *= M0, else: 0
4. Right shift with rounding: (result + 2^(N-1)) >> N
5. Saturate to 8-bit signed range [-128, 127]
"""

import numpy as np
import sys
from pathlib import Path

class Conv2DReferenceModel:
    """Reference model for CNN Conv2D Layer"""
    
    def __init__(self, data_dir="."):
        """
        Initialize the reference model
        
        Args:
            data_dir: Directory containing the .dat files
        """
        self.data_dir = Path(data_dir)
        
        # Layer parameters
        self.INPUT_ROWS = 28
        self.INPUT_COLS = 28
        self.KERNEL_ROWS = 3
        self.KERNEL_COLS = 3
        self.KERNEL_DEPTH = 32
        self.OUTPUT_ROWS = 26
        self.OUTPUT_COLS = 26
        
        # Load parameters from .dat files
        self.weights = None    # Shape: (32, 3, 3)
        self.biases = None     # Shape: (32,)
        self.m0_vals = None    # Shape: (32,)
        self.n_vals = None     # Shape: (32,)
        
        self.load_parameters()
    
    def load_parameters(self):
        """Load weights, biases, M0, and N values from .dat files"""
        
        # Load weights (32 lines, each with 9 hex bytes for 3x3 kernel)
        weights_file = self.data_dir / "cnn_conv2d_layer_weights.dat"
        self.weights = np.zeros((self.KERNEL_DEPTH, self.KERNEL_ROWS, self.KERNEL_COLS), dtype=np.int8)
        
        with open(weights_file, 'r') as f:
            for k, line in enumerate(f):
                if k >= self.KERNEL_DEPTH:
                    break
                hex_vals = line.strip().split()
                if len(hex_vals) == 9:
                    for i in range(9):
                        row = i // 3
                        col = i % 3
                        # Convert hex to signed 8-bit
                        val = int(hex_vals[i], 16)
                        if val > 127:
                            val = val - 256
                        self.weights[k, row, col] = val
        
        print(f"Loaded {self.KERNEL_DEPTH} kernels from {weights_file}")
        
        # Load biases (32 lines, each with 32-bit hex value)
        biases_file = self.data_dir / "cnn_conv2d_layer_biases.dat"
        self.biases = np.zeros(self.KERNEL_DEPTH, dtype=np.int32)
        
        with open(biases_file, 'r') as f:
            for k, line in enumerate(f):
                if k >= self.KERNEL_DEPTH:
                    break
                # Convert hex to signed 32-bit
                val = int(line.strip(), 16)
                if val >= 2**31:
                    val = val - 2**32
                self.biases[k] = val
        
        print(f"Loaded {self.KERNEL_DEPTH} biases from {biases_file}")
        
        # Load M0 values (32 lines, each with 8-bit hex value)
        m0_file = self.data_dir / "cnn_conv2d_layer_m0_vals.dat"
        self.m0_vals = np.zeros(self.KERNEL_DEPTH, dtype=np.int8)
        
        with open(m0_file, 'r') as f:
            for k, line in enumerate(f):
                if k >= self.KERNEL_DEPTH:
                    break
                val = int(line.strip(), 16)
                if val > 127:
                    val = val - 256
                self.m0_vals[k] = val
        
        print(f"Loaded {self.KERNEL_DEPTH} M0 values from {m0_file}")
        
        # Load N (right shift) values (32 lines, each with 8-bit hex value)
        n_file = self.data_dir / "cnn_conv2d_layer_n_vals.dat"
        self.n_vals = np.zeros(self.KERNEL_DEPTH, dtype=np.uint8)
        
        with open(n_file, 'r') as f:
            for k, line in enumerate(f):
                if k >= self.KERNEL_DEPTH:
                    break
                self.n_vals[k] = int(line.strip(), 16)
        
        print(f"Loaded {self.KERNEL_DEPTH} N values from {n_file}")
    
    def compute_single_output(self, input_image, kernel_idx, out_row, out_col):
        """
        Compute single output element for given kernel and output position
        
        Args:
            input_image: Input image array (28x28), dtype uint8
            kernel_idx: Index of kernel to use (0-31)
            out_row: Output row position (0-25)
            out_col: Output column position (0-25)
            
        Returns:
            8-bit signed output value
        """
        # Step 1: Convolution (sum of element-wise products)
        conv_sum = 0
        for kr in range(self.KERNEL_ROWS):
            for kc in range(self.KERNEL_COLS):
                in_row = out_row + kr
                in_col = out_col + kc
                weight_val = int(self.weights[kernel_idx, kr, kc])
                input_val = int(input_image[in_row, in_col])
                conv_sum += weight_val * input_val
        
        # Step 2: Add bias
        biased_result = conv_sum + int(self.biases[kernel_idx])
        
        # Step 3: Apply ReLU with M0 scaling
        if biased_result > 0:
            scaled_result = biased_result * int(self.m0_vals[kernel_idx])
        else:
            scaled_result = 0
        
        # Step 4: Right shift with rounding offset
        # RSH_OFFSET = 2^(N-1) for rounding
        n = int(self.n_vals[kernel_idx])
        if n > 0:
            rsh_offset = 2 ** (n - 1)
        else:
            rsh_offset = 0
        
        shifted_result = (scaled_result + rsh_offset) >> n
        
        # Step 5: Saturate to 8-bit signed range [-128, 127]
        if shifted_result > 127:
            final_output = 127
        elif shifted_result < -128:
            final_output = -128
        else:
            final_output = shifted_result
        
        return np.int8(final_output)
    
    def compute(self, input_image):
        """
        Perform convolution for entire image
        
        Args:
            input_image: Input image array (28x28), dtype uint8
            
        Returns:
            Output features array (32, 26, 26), dtype int8
        """
        assert input_image.shape == (self.INPUT_ROWS, self.INPUT_COLS), \
            f"Input image must be {self.INPUT_ROWS}x{self.INPUT_COLS}"
        
        output_features = np.zeros(
            (self.KERNEL_DEPTH, self.OUTPUT_ROWS, self.OUTPUT_COLS),
            dtype=np.int8
        )
        
        for k in range(self.KERNEL_DEPTH):
            for out_r in range(self.OUTPUT_ROWS):
                for out_c in range(self.OUTPUT_COLS):
                    output_features[k, out_r, out_c] = \
                        self.compute_single_output(input_image, k, out_r, out_c)
        
        print(f"Convolution computation complete for {self.KERNEL_DEPTH} kernels")
        return output_features
    
    def display_params(self, kernel_idx=0):
        """Display parameters for a specific kernel (for debugging)"""
        print(f"\n=== Kernel {kernel_idx} Parameters ===")
        print("Weights:")
        for r in range(self.KERNEL_ROWS):
            print(f"  {self.weights[kernel_idx, r, :]}")
        print(f"Bias: {self.biases[kernel_idx]} (0x{self.biases[kernel_idx]:08x})")
        print(f"M0: {self.m0_vals[kernel_idx]} (0x{self.m0_vals[kernel_idx]:02x})")
        print(f"N (right shift): {self.n_vals[kernel_idx]}")
    
    def display_output(self, output_features, kernel_idx=0, max_rows=5, max_cols=5):
        """Display output feature map (for debugging)"""
        rows_to_show = min(max_rows, self.OUTPUT_ROWS)
        cols_to_show = min(max_cols, self.OUTPUT_COLS)
        
        print(f"\n=== Output Feature Map for Kernel {kernel_idx} (first {rows_to_show}x{cols_to_show}) ===")
        for r in range(rows_to_show):
            print(f"Row {r:02d}: ", end="")
            for c in range(cols_to_show):
                print(f"{output_features[kernel_idx, r, c]:4d} ", end="")
            print()


def main():
    """Example usage of the reference model"""
    
    # Create reference model (assuming .dat files are in current directory)
    ref_model = Conv2DReferenceModel(".")
    
    # Display parameters for first kernel
    ref_model.display_params(0)
    
    # Create a simple test image
    test_image = np.zeros((28, 28), dtype=np.uint8)
    
    # Add a simple pattern in the center
    test_image[13:15, 13:15] = [[255, 128], [128, 255]]
    
    print("\nInput image center pattern:")
    print(test_image[12:16, 12:16])
    
    # Compute convolution
    output_features = ref_model.compute(test_image)
    
    # Display some results
    print("\n=== Sample Outputs ===")
    print("Position (0,0) - First 4 kernel outputs:")
    for k in range(4):
        print(f"  Kernel {k}: {output_features[k, 0, 0]}")
    
    print("\nPosition (12,12) - First 4 kernel outputs:")
    for k in range(4):
        print(f"  Kernel {k}: {output_features[k, 12, 12]}")
    
    # Display first feature map
    ref_model.display_output(output_features, 0, 10, 10)
    
    # Save outputs to file for comparison
    output_file = "reference_outputs.npy"
    np.save(output_file, output_features)
    print(f"\nSaved outputs to {output_file}")


if __name__ == "__main__":
    main()



