# CNN Conv2D Layer Reference Model - Quick Start Guide

## Overview

Two reference models have been created for the CNN Conv2D Layer:

1. **SystemVerilog Reference Model** - For integration into UVM testbench
2. **Python Reference Model** - For standalone verification and debugging

Both models implement the exact same computation as the VHDL DUT.

## Files Created

### Core Reference Models
```
ICP2_2/
├── uvc/cnn_conv2d_layer_uvc/
│   ├── conv2d_layer_reference_model.svh        # SystemVerilog reference model
│   └── conv2d_layer_reference_example.svh      # Usage examples
├── reference_model/
│   ├── conv2d_reference.py                     # Python reference model
│   └── README.md                               # Detailed documentation
└── REFERENCE_MODEL_USAGE.md                    # This file
```

### Updated Files
```
ICP2_2/cnn_conv2d_layer/tb/
├── tb_pkg.sv                                   # Added reference model include
├── tb_top.sv                                   # Fixed type mismatches
├── cnn_conv2d_layer_wrapper.sv                 # SV wrapper (renamed to _sv)
└── dut/cnn_conv2d_layer_wrapper.vhd            # VHDL wrapper (renamed to _vhd)
```

## Quick Start

### 1. SystemVerilog Reference Model (UVM Testbench)

The reference model is already included in your `tb_pkg.sv`. To use it in your scoreboard:

```systemverilog
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    
    // Add reference model
    conv2d_layer_reference_model ref_model;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ref_model = new();  // Automatically loads .dat files
    endfunction
    
    // Called when you receive complete input image
    function void process_input(byte unsigned img_data[784]);
        ref_model.load_input_image_flat(img_data);
        ref_model.compute();
        `uvm_info("SCOREBOARD", "Computed expected outputs", UVM_MEDIUM)
    endfunction
    
    // Called for each DUT output
    function void check_output(int row, int col, byte signed dut_out[32]);
        byte signed expected[32];
        ref_model.get_output_vector(row, col, expected);
        
        for (int k = 0; k < 32; k++) begin
            if (dut_out[k] != expected[k]) begin
                `uvm_error("MISMATCH", 
                    $sformatf("K%0d pos(%0d,%0d): DUT=%0d Exp=%0d",
                              k, row, col, dut_out[k], expected[k]))
            end else begin
                `uvm_info("MATCH", 
                    $sformatf("K%0d pos(%0d,%0d): %0d ✓",
                              k, row, col, dut_out[k]), UVM_HIGH)
            end
        end
    endfunction
endclass
```

### 2. Python Reference Model (Standalone)

Test the Python model:

```bash
cd ICP2_2
python reference_model/conv2d_reference.py
```

Use in your own scripts:

```python
from reference_model.conv2d_reference import Conv2DReferenceModel
import numpy as np

# Load reference model
ref_model = Conv2DReferenceModel(".")  # Path to .dat files

# Create or load test image
test_image = np.random.randint(0, 256, (28, 28), dtype=np.uint8)

# Compute outputs
output_features = ref_model.compute(test_image)  # Shape: (32, 26, 26)

# Access specific outputs
print(f"Kernel 0, position (5,5): {output_features[0, 5, 5]}")

# Display for debugging
ref_model.display_params(0)
ref_model.display_output(output_features, 0)
```

## Computation Flow

Both models implement:

```
1. Convolution:     sum(input[i,j] * weight[i,j])  for 3×3 window
2. Add Bias:        result = conv_sum + bias
3. ReLU + Scale:    result = (result > 0) ? result * M0 : 0
4. Right Shift:     result = (result + 2^(N-1)) >> N
5. Saturate:        clamp result to [-128, 127]
```

## Data Files Required

Place these in your simulation directory:

```
cnn_conv2d_layer_weights.dat    # 32 kernels × 9 weights (3×3)
cnn_conv2d_layer_biases.dat     # 32 biases (32-bit signed)
cnn_conv2d_layer_m0_vals.dat    # 32 M0 values (8-bit signed)
cnn_conv2d_layer_n_vals.dat     # 32 N values (8-bit unsigned)
```

These files are already present in `ICP2_2/`.

## Mixed-Language Simulation Fix

The type mismatch issue between SystemVerilog and VHDL arrays has been fixed using a two-layer wrapper approach:

```
Testbench (SV)
    ↓
cnn_conv2d_layer_wrapper_sv (SystemVerilog)
    ↓ [256-bit flat vector]
cnn_conv2d_layer_wrapper_vhd (VHDL)
    ↓ [VHDL array type]
cnn_conv2d_layer (VHDL DUT)
```

The VHDL wrapper flattens the array into a `std_logic_vector(255 downto 0)` which Vivado XSim can map to SystemVerilog.

## Testing Strategy

### Basic Verification Flow

1. **Load Parameters**: Both models read `.dat` files on construction
2. **Load Input**: Feed same input image to DUT and reference model
3. **Compute**: Reference model computes expected outputs
4. **Compare**: Check each DUT output against reference
5. **Report**: Log matches/mismatches

### Example Test Sequence

```systemverilog
// In your test
task body();
    byte unsigned test_img[784];
    
    // Generate or load test image
    for (int i = 0; i < 784; i++) test_img[i] = $urandom();
    
    // Send to DUT via driver
    send_image_to_dut(test_img);
    
    // Scoreboard will:
    // - Compute expected outputs using reference model
    // - Compare against DUT outputs as they arrive
endtask
```

## Debugging Mismatches

If DUT ≠ Reference:

1. **Verify Parameters Match**:
   ```systemverilog
   ref_model.display_params(kernel_idx);  // Show weights, bias, M0, N
   ```

2. **Test Simple Inputs**:
   - All zeros
   - Single pixel = 255
   - Known patterns

3. **Check Intermediate Values**:
   - Add debug prints in reference model
   - Check: conv_sum, biased_result, scaled_result, shifted_result

4. **Verify Signedness**:
   - Inputs: unsigned [0, 255]
   - Weights: signed [-128, 127]
   - Outputs: signed [-128, 127]

## Additional Resources

- **Detailed Documentation**: `reference_model/README.md`
- **Usage Examples**: `uvc/cnn_conv2d_layer_uvc/conv2d_layer_reference_example.svh`
- **DUT Source**: `cnn_conv2d_layer/dut/cnn_conv2d_layer.vhd`
- **Package Info**: `cnn_conv2d_layer/dut/cnn_pkg.vhd`

## Common Issues

### "File not found" errors
- Ensure `.dat` files are in simulation run directory
- For Python: run from `ICP2_2/` or pass correct `data_dir`

### Type mismatch errors  
- Use `cnn_conv2d_layer_wrapper_sv` (not `cnn_conv2d_layer` directly)
- Wrapper handles VHDL ↔ SystemVerilog type conversion

### Reference model not found in simulation
- Check that `tb_pkg.sv` includes `conv2d_layer_reference_model.svh`
- Already added - just recompile

## Next Steps

1. **Integrate into Scoreboard**: Add reference model to your `scoreboard.svh`
2. **Add Comparison Logic**: Compare DUT outputs with reference
3. **Create Test Cases**: Test with various input images
4. **Coverage**: Track which scenarios have been tested
5. **Python Verification**: Use Python model for offline analysis

## Questions?

The reference models are well-commented. Key functions:

**SystemVerilog**:
- `load_input_image_flat()` - Load 784-element flat array
- `compute()` - Compute all outputs
- `get_output_vector()` - Get outputs for one position
- `display_params()` - Debug kernel parameters

**Python**:
- `compute()` - Compute all outputs, returns (32,26,26) array
- `compute_single_output()` - Compute one output element
- `display_params()` / `display_output()` - Debug helpers



