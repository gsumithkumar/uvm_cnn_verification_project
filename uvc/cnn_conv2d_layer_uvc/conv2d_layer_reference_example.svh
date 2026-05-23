//------------------------------------------------------------------------------
// conv2d_layer_reference_example
//
// Example showing how to use the conv2d_layer_reference_model
// This can be used as a template for integration into your scoreboard
//------------------------------------------------------------------------------

// Example usage in a test or scoreboard:
//
// class my_scoreboard extends uvm_scoreboard;
//     conv2d_layer_reference_model ref_model;
//     
//     function void build_phase(uvm_phase phase);
//         super.build_phase(phase);
//         ref_model = new();
//     endfunction
//     
//     // When you receive an input image transaction
//     task process_input_image(byte unsigned img_data[28*28]);
//         byte unsigned img_2d[28][28];
//         byte signed expected_outputs[32];
//         
//         // Load the input image
//         ref_model.load_input_image_flat(img_data);
//         
//         // Compute expected outputs
//         ref_model.compute();
//         
//         // Get expected outputs for position (row, col)
//         // This should be called when DUT produces output at that position
//         ref_model.get_output_vector(row, col, expected_outputs);
//         
//         // Compare with DUT outputs
//         for (int k = 0; k < 32; k++) begin
//             if (dut_outputs[k] != expected_outputs[k]) begin
//                 `uvm_error("SCOREBOARD", 
//                     $sformatf("Mismatch at kernel %0d, pos(%0d,%0d): DUT=%0d, Expected=%0d",
//                               k, row, col, dut_outputs[k], expected_outputs[k]))
//             end
//         end
//     endtask

// Standalone example (can be run in a simple module for verification)
module reference_model_test;
    
    initial begin
        conv2d_layer_reference_model ref_model;
        byte unsigned test_image[28][28];
        byte signed output_vec[32];
        
        // Create reference model
        ref_model = new();
        
        // Display parameters for first kernel
        ref_model.display_params(0);
        
        // Create a simple test image (all zeros except a small pattern)
        for (int r = 0; r < 28; r++) begin
            for (int c = 0; c < 28; c++) begin
                test_image[r][c] = 0;
            end
        end
        
        // Add a simple pattern in the center
        test_image[13][13] = 255;
        test_image[13][14] = 128;
        test_image[14][13] = 128;
        test_image[14][14] = 255;
        
        // Load and compute
        ref_model.load_input_image(test_image);
        ref_model.compute();
        
        // Display some results
        $display("\n=== Sample Outputs ===");
        ref_model.get_output_vector(0, 0, output_vec);
        $display("Position (0,0) - Kernel outputs:");
        for (int k = 0; k < 4; k++) begin
            $display("  Kernel %0d: %0d", k, output_vec[k]);
        end
        
        ref_model.get_output_vector(12, 12, output_vec);
        $display("Position (12,12) - Kernel outputs:");
        for (int k = 0; k < 4; k++) begin
            $display("  Kernel %0d: %0d", k, output_vec[k]);
        end
        
        // Display first feature map
        ref_model.display_output(0, 10, 10);
        
        $display("\nReference model test complete");
        $finish;
    end
    
endmodule



