//------------------------------------------------------------------------------
// Example: How to use the reference model in scoreboard
//
// This file shows examples of how to integrate the reference model verification
// into your tests. The scoreboard now includes a reference model that compares
// DUT outputs against expected outputs computed from the input image.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Example 1: Modified sequence that sends image to scoreboard
//------------------------------------------------------------------------------
// You can modify your sequences to send the complete image to the scoreboard
// before sending pixels to the DUT. Here's an example:

/*
class cnn_zero_image_seq_with_ref extends cnn_base_image_seq;
    `uvm_object_utils(cnn_zero_image_seq_with_ref)
    
    scoreboard m_scoreboard;
    
    function new(string name = "cnn_zero_image_seq_with_ref");
        super.new(name);
    endfunction
    
    task body();
        byte unsigned img_data[784];
        scoreboard sb;
        
        `uvm_info(get_name(), "Starting ALL-ZERO IMAGE sequence with reference", UVM_MEDIUM)
        
        // Build the image data
        for (int i = 0; i < IMG_PIXELS; i++) begin
            img_data[i] = 8'h00;
        end
        
        // Get scoreboard reference from config_db or parent
        // Option 1: Via config_db (set in test)
        if (!uvm_config_db #(scoreboard)::get(null, "", "scoreboard", sb)) begin
            `uvm_warning(get_name(), "Scoreboard not found in config_db - skipping reference verification")
        end else begin
            // Load image into scoreboard for reference model computation
            sb.load_input_image_for_verification(img_data, 0);  // img_id = 0
        end
        
        // Now send pixels to DUT as normal
        conv2d_layer_seq_item seq_itm;
        seq_itm = conv2d_layer_seq_item::type_id::create("seq_itm");
        for (int i = 0; i < IMG_PIXELS; i++) begin
            start_item(seq_itm);
            seq_itm.pixel = 8'h00;
            seq_itm.inject_stalls = 0;
            finish_item(seq_itm);
        end
    endtask
endclass
*/

//------------------------------------------------------------------------------
// Example 2: Test that loads images into scoreboard
//------------------------------------------------------------------------------
// In your test's run_phase, you can load images into the scoreboard:

/*
class my_test_with_ref extends base_test;
    `uvm_component_utils(my_test_with_ref)
    
    virtual task run_phase(uvm_phase phase);
        reset_seq reset;
        cnn_zero_image_seq zero_seq;
        byte unsigned test_image[784];
        int unsigned img_id = 0;
        
        phase.raise_objection(this);
        
        // Reset
        reset = reset_seq::type_id::create("reset");
        reset.randomize() with { delay == 0; length == 10; };
        reset.start(m_tb_env.m_reset_agent.m_sequencer);
        #50ns;
        
        // Prepare test image (all zeros example)
        for (int i = 0; i < 784; i++) begin
            test_image[i] = 8'h00;
        end
        
        // Load image into scoreboard reference model BEFORE sending to DUT
        m_tb_env.m_scoreboard.load_input_image_for_verification(test_image, img_id);
        
        // Now send image to DUT
        zero_seq = cnn_zero_image_seq::type_id::create("zero_seq");
        zero_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
        
        // Wait for processing
        #1000ns;
        
        // For next image, increment img_id
        img_id++;
        
        phase.drop_objection(this);
    endtask
endclass
*/

//------------------------------------------------------------------------------
// Example 3: Random image with reference
//------------------------------------------------------------------------------
// For random images, you need to generate the image first, then send it:

/*
task send_random_image_with_ref(int unsigned img_id);
    byte unsigned random_image[784];
    cnn_random_image_seq random_seq;
    
    // Generate random image data
    for (int i = 0; i < 784; i++) begin
        random_image[i] = $urandom_range(0, 255);
    end
    
    // Load into scoreboard reference model
    m_tb_env.m_scoreboard.load_input_image_for_verification(random_image, img_id);
    
    // Create a custom sequence that sends the exact image we generated
    // (You'd need to modify cnn_random_image_seq to accept pre-generated data)
    random_seq = cnn_random_image_seq::type_id::create("random_seq");
    random_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
endtask
*/

//------------------------------------------------------------------------------
// Notes:
//------------------------------------------------------------------------------
// 1. Call load_input_image_for_verification() BEFORE sending image to DUT
// 2. The img_id parameter should match the image ID that will be used by the monitor
// 3. The scoreboard will automatically compare DUT outputs with reference model outputs
// 4. Mismatches will be reported as UVM errors
// 5. Statistics are reported in check_phase
//
// The reference model uses the SystemVerilog implementation which:
// - Loads weights, biases, M0, and N values from .dat files automatically
// - Computes expected outputs using the same algorithm as the DUT
// - Provides bit-accurate comparison
//------------------------------------------------------------------------------

