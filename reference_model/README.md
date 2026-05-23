# CNN Conv2D Layer Reference Model

This directory contains reference models for the CNN Conv2D Layer that can be used for verification and debugging.

## Overview

The reference models implement the exact same convolution operation as the VHDL DUT:

1. **Convolution**: Sum of element-wise products over 3x3 kernel window
2. **Bias Addition**: Add 32-bit bias value
3. **ReLU with M0 Scaling**: `if (result > 0) result *= M0; else result = 0`
4. **Right Shift with Rounding**: `(result + 2^(N-1)) >> N`
5. **Saturation**: Clamp to 8-bit signed range [-128, 127]

## Files

### SystemVerilog Reference Model
- **File**: `../uvc/cnn_conv2d_layer_uvc/conv2d_layer_reference_model.svh`
- **Usage**: Integrated into UVM testbench for cycle-accurate comparison
- **Location**: Already included in `tb_pkg.sv`

### Python Reference Model  
- **File**: `conv2d_reference.py`
- **Usage**: Standalone testing and golden reference generation
- **Advantages**: Easy to debug, visualize, and modify

### Example/Documentation
- `../uvc/cnn_conv2d_layer_uvc/conv2d_layer_reference_example.svh` - Shows how to use SystemVerilog model in scoreboard

## Required Data Files

The reference models require the following `.dat` files (should be in simulation directory):

```
cnn_conv2d_layer_weights.dat   - 32 kernels, each line has 9 hex bytes for 3x3 weights
cnn_conv2d_layer_biases.dat    - 32 lines, each with 32-bit hex bias value  
cnn_conv2d_layer_m0_vals.dat   - 32 lines, each with 8-bit hex M0 value
cnn_conv2d_layer_n_vals.dat    - 32 lines, each with 8-bit hex N (right shift) value
```

### Data File Formats

**Weights** (`cnn_conv2d_layer_weights.dat`):
```
18 33 ba 5c 30 d4 a6 f5 7f    # Kernel 0: weights in row-major order
bd 00 52 7f 12 e0 0c 94 cf    # Kernel 1
...
```

**Biases** (`cnn_conv2d_layer_biases.dat`):
```
ffff9647    # Kernel 0 bias (32-bit hex, signed)
ffffb78a    # Kernel 1 bias
...
```

**M0 Values** (`cnn_conv2d_layer_m0_vals.dat`):
```
01    # Kernel 0 M0 (8-bit hex, signed)
01    # Kernel 1 M0
...
```

**N Values** (`cnn_conv2d_layer_n_vals.dat`):
```
0A    # Kernel 0 N / right shift amount (8-bit hex, unsigned)
0A    # Kernel 1 N
...
```

## Usage

### SystemVerilog (In UVM Testbench)

Add to your scoreboard:

```systemverilog
class my_scoreboard extends uvm_scoreboard;
    conv2d_layer_reference_model ref_model;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ref_model = new();  // Automatically loads .dat files
    endfunction
    
    task compare_outputs(byte unsigned img_data[784], int row, int col, byte signed dut_outputs[32]);
        byte signed expected_outputs[32];
        
        // Load input image and compute expected outputs
        ref_model.load_input_image_flat(img_data);
        ref_model.compute();
        
        // Get expected outputs for this position
        ref_model.get_output_vector(row, col, expected_outputs);
        
        // Compare with DUT outputs
        for (int k = 0; k < 32; k++) begin
            if (dut_outputs[k] != expected_outputs[k]) begin
                `uvm_error("MISMATCH", 
                    $sformatf("Kernel %0d, pos(%0d,%0d): DUT=%0d, Expected=%0d",
                              k, row, col, dut_outputs[k], expected_outputs[k]))
            end
        end
    endtask
endclass
```

### Python (Standalone)

```python
from conv2d_reference import Conv2DReferenceModel
import numpy as np

# Create model (assuming .dat files are in current directory)
ref_model = Conv2DReferenceModel(".")

# Create or load input image (28x28, uint8)
input_image = np.random.randint(0, 256, (28, 28), dtype=np.uint8)

# Compute convolution
output_features = ref_model.compute(input_image)  # Shape: (32, 26, 26)

# Access outputs
kernel_0_output = output_features[0, :, :]        # First kernel's output
position_5_5 = output_features[:, 5, 5]           # All kernels at position (5,5)

# Debug specific kernel
ref_model.display_params(kernel_idx=0)
ref_model.display_output(output_features, kernel_idx=0)

# Save for later comparison
np.save("golden_outputs.npy", output_features)
```

Run standalone:
```bash
cd ICP2_2
python reference_model/conv2d_reference.py
```

## Testing the Reference Model

### Quick Test

```bash
cd ICP2_2
python reference_model/conv2d_reference.py
```

This will:
- Load all parameters from .dat files
- Create a test image with a simple pattern
- Compute convolution outputs
- Display results and save to `reference_outputs.npy`

### Compare with Simulation

1. Run your simulation and save DUT outputs
2. Run Python reference model with same input
3. Compare the outputs:

```python
import numpy as np

# Load DUT outputs from simulation
dut_outputs = np.load("dut_outputs.npy")

# Load reference outputs
ref_outputs = np.load("reference_outputs.npy")

# Compare
match = np.array_equal(dut_outputs, ref_outputs)
if match:
    print("✓ DUT outputs match reference!")
else:
    print("✗ Mismatch found:")
    diff = np.where(dut_outputs != ref_outputs)
    for k, r, c in zip(*diff):
        print(f"  Kernel {k}, pos({r},{c}): DUT={dut_outputs[k,r,c]}, Ref={ref_outputs[k,r,c]}")
```

## Input/Output Specifications

### Input
- **Size**: 28×28 pixels
- **Type**: Unsigned 8-bit (0-255)
- **Format**: Row-major order (row 0, then row 1, etc.)

### Output
- **Size**: 32 kernels × 26×26 pixels
- **Type**: Signed 8-bit (-128 to 127)
- **Format**: `[kernel_idx][row][col]`

### Valid Output Positions
- Rows: 0 to 25 (26 rows)
- Cols: 0 to 25 (26 cols)
- The convolution "loses" 2 rows and 2 cols due to the 3×3 kernel with valid padding

## Troubleshooting

### File Not Found Errors
Make sure the `.dat` files are in the directory you're running from:
- For simulation: Files should be in the simulation run directory
- For Python: Pass correct `data_dir` to constructor or run from `ICP2_2` directory

### Mismatches Between Models
If DUT and reference disagree:
1. Verify `.dat` files are identical for both
2. Check input image is the same
3. Use `display_params()` to verify kernel parameters loaded correctly
4. Test with simple known patterns (e.g., all zeros, single bright pixel)
5. Compare intermediate values (conv_sum, biased_result, etc.)

### Signed/Unsigned Issues
- Input pixels are **unsigned** (0-255)
- Weights are **signed** (-128 to 127)
- Outputs are **signed** (-128 to 127)
- Make sure type conversions match the HDL

## Notes

- The reference models match the VHDL DUT bit-accurately when given the same inputs
- Computation is done in high precision (longint/int64) to avoid overflow, then saturated to 8-bit at the end
- The right-shift rounding offset (`2^(N-1)`) ensures proper rounding behavior
- ReLU is applied BEFORE scaling by M0 (as per the VHDL implementation)



