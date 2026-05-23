//------------------------------------------------------------------------------
// conv2d_layer_reference_model
//
// Reference model for the CNN Conv2D Layer
// This model reads weights, biases, M0 values, and N (right shift) values 
// from .dat files and performs the same convolution operation as the DUT
// to generate expected outputs for verification.
//
// Computation flow:
// 1. Convolve 3x3 kernel with input window (element-wise multiply and sum)
// 2. Add bias
// 3. Apply ReLU with M0 scaling: if (result > 0) result *= M0, else result = 0
// 4. Right shift with rounding: (result + 2^(N-1)) >> N
// 5. Saturate/truncate to 8-bit signed output
//------------------------------------------------------------------------------

class conv2d_layer_reference_model;

    // CNN Layer Parameters
    localparam int INPUT_ROWS = 28;
    localparam int INPUT_COLS = 28;
    localparam int KERNEL_ROWS = 3;
    localparam int KERNEL_COLS = 3;
    localparam int KERNEL_DEPTH = 32;
    localparam int OUTPUT_ROWS = 26;
    localparam int OUTPUT_COLS = 26;

    // Data storage
    byte signed weights[KERNEL_DEPTH][KERNEL_ROWS][KERNEL_COLS];  // 32 kernels, each 3x3
    int signed biases[KERNEL_DEPTH];      // 32-bit biases
    byte signed m0_vals[KERNEL_DEPTH];    // M0 scaling factors
    byte unsigned n_vals[KERNEL_DEPTH];   // Right shift amounts
    
    // Input image buffer
    byte unsigned input_image[INPUT_ROWS][INPUT_COLS];
    
    // Output buffer
    byte signed output_features[KERNEL_DEPTH][OUTPUT_ROWS][OUTPUT_COLS];
    
    // File paths (relative to simulation directory)
    string weights_file = "cnn_conv2d_layer_weights.dat";
    string biases_file = "cnn_conv2d_layer_biases.dat";
    string m0_vals_file = "cnn_conv2d_layer_m0_vals.dat";
    string n_vals_file = "cnn_conv2d_layer_n_vals.dat";

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new();
        load_parameters();
    endfunction

    //--------------------------------------------------------------------------
    // Load parameters from .dat files
    //--------------------------------------------------------------------------
    function void load_parameters();
        int fd;
        string line;
        int scan_result;
        
        // Load weights (32 lines, each with 9 hex bytes)
        fd = $fopen(weights_file, "r");
        if (fd == 0) begin
            $error("Failed to open weights file: %s", weights_file);
            return;
        end
        for (int k = 0; k < KERNEL_DEPTH; k++) begin
            int w0, w1, w2, w3, w4, w5, w6, w7, w8;
            scan_result = $fscanf(fd, "%h %h %h %h %h %h %h %h %h\n", 
                                 w0, w1, w2, w3, w4, w5, w6, w7, w8);
            if (scan_result != 9) begin
                $error("Failed to read weights for kernel %0d", k);
            end
            // Map to 3x3 array (row-major order)
            weights[k][0][0] = w0[7:0];
            weights[k][0][1] = w1[7:0];
            weights[k][0][2] = w2[7:0];
            weights[k][1][0] = w3[7:0];
            weights[k][1][1] = w4[7:0];
            weights[k][1][2] = w5[7:0];
            weights[k][2][0] = w6[7:0];
            weights[k][2][1] = w7[7:0];
            weights[k][2][2] = w8[7:0];
        end
        $fclose(fd);
        $display("Loaded %0d kernels from %s", KERNEL_DEPTH, weights_file);
        
        // Load biases (32 lines, each with 32-bit hex value)
        fd = $fopen(biases_file, "r");
        if (fd == 0) begin
            $error("Failed to open biases file: %s", biases_file);
            return;
        end
        for (int k = 0; k < KERNEL_DEPTH; k++) begin
            scan_result = $fscanf(fd, "%h\n", biases[k]);
            if (scan_result != 1) begin
                $error("Failed to read bias for kernel %0d", k);
            end
        end
        $fclose(fd);
        $display("Loaded %0d biases from %s", KERNEL_DEPTH, biases_file);
        
        // Load M0 values (32 lines, each with 8-bit hex value)
        fd = $fopen(m0_vals_file, "r");
        if (fd == 0) begin
            $error("Failed to open M0 values file: %s", m0_vals_file);
            return;
        end
        for (int k = 0; k < KERNEL_DEPTH; k++) begin
            int m0_temp;
            scan_result = $fscanf(fd, "%h\n", m0_temp);
            if (scan_result != 1) begin
                $error("Failed to read M0 value for kernel %0d", k);
            end
            m0_vals[k] = m0_temp[7:0];
        end
        $fclose(fd);
        $display("Loaded %0d M0 values from %s", KERNEL_DEPTH, m0_vals_file);
        
        // Load N (right shift) values (32 lines, each with 8-bit hex value)
        fd = $fopen(n_vals_file, "r");
        if (fd == 0) begin
            $error("Failed to open N values file: %s", n_vals_file);
            return;
        end
        for (int k = 0; k < KERNEL_DEPTH; k++) begin
            int n_temp;
            scan_result = $fscanf(fd, "%h\n", n_temp);
            if (scan_result != 1) begin
                $error("Failed to read N value for kernel %0d", k);
            end
            n_vals[k] = n_temp[7:0];
        end
        $fclose(fd);
        $display("Loaded %0d N values from %s", KERNEL_DEPTH, n_vals_file);
    endfunction

    //--------------------------------------------------------------------------
    // Load input image from array
    //--------------------------------------------------------------------------
    function void load_input_image(byte unsigned img[INPUT_ROWS][INPUT_COLS]);
        input_image = img;
    endfunction
    
    //--------------------------------------------------------------------------
    // Load input image from flat array (row-major)
    //--------------------------------------------------------------------------
    function void load_input_image_flat(byte unsigned img[INPUT_ROWS * INPUT_COLS]);
        for (int r = 0; r < INPUT_ROWS; r++) begin
            for (int c = 0; c < INPUT_COLS; c++) begin
                input_image[r][c] = img[r * INPUT_COLS + c];
            end
        end
    endfunction

    //--------------------------------------------------------------------------
    // Perform convolution for entire image
    //--------------------------------------------------------------------------
    function void compute();
        for (int k = 0; k < KERNEL_DEPTH; k++) begin
            for (int out_r = 0; out_r < OUTPUT_ROWS; out_r++) begin
                for (int out_c = 0; out_c < OUTPUT_COLS; out_c++) begin
                    output_features[k][out_r][out_c] = compute_single_output(k, out_r, out_c);
                end
            end
        end
        $display("Convolution computation complete for %0d kernels", KERNEL_DEPTH);
    endfunction

    //--------------------------------------------------------------------------
    // Compute single output element for given kernel and output position
    //--------------------------------------------------------------------------
    function byte signed compute_single_output(int kernel_idx, int out_row, int out_col);
        longint signed conv_sum;
        longint signed biased_result;
        longint signed scaled_result;
        longint signed shifted_result;
        longint signed rsh_offset;
        byte signed final_output;
        
        // Step 1: Convolution (sum of element-wise products)
        conv_sum = 0;
        for (int kr = 0; kr < KERNEL_ROWS; kr++) begin
            for (int kc = 0; kc < KERNEL_COLS; kc++) begin
                int in_row = out_row + kr;
                int in_col = out_col + kc;
                longint signed weight_val = $signed(weights[kernel_idx][kr][kc]);
                longint signed input_val = $signed({1'b0, input_image[in_row][in_col]}); // unsigned to signed
                conv_sum += weight_val * input_val;
            end
        end
        
        // Step 2: Add bias
        biased_result = conv_sum + biases[kernel_idx];
        
        // Step 3: Apply ReLU with M0 scaling
        if (biased_result > 0) begin
            scaled_result = biased_result * $signed(m0_vals[kernel_idx]);
        end else begin
            scaled_result = 0;
        end
        
        // Step 4: Right shift with rounding offset
        // RSH_OFFSET = 2^(N-1) for rounding
        rsh_offset = (n_vals[kernel_idx] > 0) ? (1 << (n_vals[kernel_idx] - 1)) : 0;
        shifted_result = (scaled_result + rsh_offset) >>> n_vals[kernel_idx];
        
        // Step 5: Saturate to 8-bit signed range [-128, 127]
        if (shifted_result > 127)
            final_output = 127;
        else if (shifted_result < -128)
            final_output = -128;
        else
            final_output = shifted_result[7:0];
            
        return final_output;
    endfunction

    //--------------------------------------------------------------------------
    // Get single output element
    //--------------------------------------------------------------------------
    function byte signed get_output(int kernel_idx, int row, int col);
        if (kernel_idx >= 0 && kernel_idx < KERNEL_DEPTH &&
            row >= 0 && row < OUTPUT_ROWS &&
            col >= 0 && col < OUTPUT_COLS) begin
            return output_features[kernel_idx][row][col];
        end else begin
            $error("Invalid output indices: kernel=%0d, row=%0d, col=%0d", kernel_idx, row, col);
            return 0;
        end
    endfunction

    //--------------------------------------------------------------------------
    // Get all outputs for a single position (all 32 kernels)
    //--------------------------------------------------------------------------
    function void get_output_vector(int row, int col, output byte signed out_vec[KERNEL_DEPTH]);
        for (int k = 0; k < KERNEL_DEPTH; k++) begin
            out_vec[k] = output_features[k][row][col];
        end
    endfunction

    //--------------------------------------------------------------------------
    // Display parameters (for debug)
    //--------------------------------------------------------------------------
    function void display_params(int kernel_idx = 0);
        $display("=== Kernel %0d Parameters ===", kernel_idx);
        $display("Weights:");
        for (int r = 0; r < KERNEL_ROWS; r++) begin
            $display("  [%0d,%0d,%0d]", 
                    weights[kernel_idx][r][0],
                    weights[kernel_idx][r][1],
                    weights[kernel_idx][r][2]);
        end
        $display("Bias: %0d (0x%08h)", biases[kernel_idx], biases[kernel_idx]);
        $display("M0: %0d (0x%02h)", m0_vals[kernel_idx], m0_vals[kernel_idx]);
        $display("N (right shift): %0d", n_vals[kernel_idx]);
    endfunction

    //--------------------------------------------------------------------------
    // Display output feature map (for debug)
    //--------------------------------------------------------------------------
    function void display_output(int kernel_idx = 0, int max_rows = 5, int max_cols = 5);
        int rows_to_show = (max_rows < OUTPUT_ROWS) ? max_rows : OUTPUT_ROWS;
        int cols_to_show = (max_cols < OUTPUT_COLS) ? max_cols : OUTPUT_COLS;
        
        $display("=== Output Feature Map for Kernel %0d (first %0dx%0d) ===", 
                kernel_idx, rows_to_show, cols_to_show);
        for (int r = 0; r < rows_to_show; r++) begin
            $write("Row %02d: ", r);
            for (int c = 0; c < cols_to_show; c++) begin
                $write("%4d ", output_features[kernel_idx][r][c]);
            end
            $display("");
        end
    endfunction

endclass : conv2d_layer_reference_model



