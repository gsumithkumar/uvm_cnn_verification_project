//------------------------------------------------------------------------------
// class basic_test
//
// This class is an extension of the base_test class.
// It provides a basic test structure for verifying the CNN Conv2D Layer
// in the UVM framework.
//
// The test runs multiple image sequences to verify the DUT:
// - Zero image sequence (all pixels = 0)
// - Max image sequence (all pixels = 255)
// - Impulse image sequence (single pixel = 255, rest = 0)
// - Random image sequence (random pixels with stalls)
//
// The class provides an implementation of the build_phase and run_phase methods.
// It creates and builds the TB environment as defined in base_test.
// It runs comprehensive test scenarios to verify the convolution layer.
//
// The test uses the input UVC agent's sequencer (m_cnn_conv2d_layer_agent) to
// drive stimulus sequences to the DUT. The output UVC agent's monitor
// (m_cnn_conv2d_layer_out_agent) passively observes DUT outputs and sends
// transactions to the scoreboard for verification.
//
// See more detailed information in base_test
//------------------------------------------------------------------------------
class basic_test extends base_test;
    `uvm_component_utils(basic_test)

    //------------------------------------------------------------------------------
    // FUNCTION: new
    // Creates and constructs the test.
    //------------------------------------------------------------------------------
    function new (string name = "basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //------------------------------------------------------------------------------
    // FUNCTION: build_phase
    // Function to build the class within UVM build phase.
    //------------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        // Create and build TB environment as defined in base test
        super.build_phase(phase);
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // FUNCTION: run_phase
    // Start UVM test in running phase.
    // This test runs multiple image sequences to thoroughly verify the DUT.
    //------------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        reset_seq reset;
        cnn_zero_image_seq zero_seq;
        cnn_max_image_seq max_seq;
        cnn_impulse_image_seq impulse_seq;
        cnn_random_image_seq random_seq;

        `uvm_info(get_name(), $sformatf("Starting basic_test for CNN Conv2D Layer"), UVM_NONE)
        
        // Raise objection
        phase.raise_objection(this);
        
        // Reset DUT
        reset = reset_seq::type_id::create("reset");
        if (!(reset.randomize() with {
            delay == 0;
            length == 10;
        })) `uvm_fatal(get_name(), "Failed to randomize reset")
        
        reset.start(m_tb_env.m_reset_agent.m_sequencer);
        
        `uvm_info(get_name(), "Reset sequence completed", UVM_MEDIUM)
        #50ns;
        
        // Test 1: Zero Image
        `uvm_info(get_name(), "=== Running Zero Image Test ===", UVM_MEDIUM)
        zero_seq = cnn_zero_image_seq::type_id::create("zero_seq");
        zero_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
        #500ns;
        
        // Test 2: Max Image
        `uvm_info(get_name(), "=== Running Max Image Test ===", UVM_MEDIUM)
        max_seq = cnn_max_image_seq::type_id::create("max_seq");
        max_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
        #500ns;
        
        // Test 3: Impulse Image
        `uvm_info(get_name(), "=== Running Impulse Image Test ===", UVM_MEDIUM)
        impulse_seq = cnn_impulse_image_seq::type_id::create("impulse_seq");
        impulse_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
        #500ns;
        
        // Test 4: Random Image with Stalls
        repeat(100) begin
        `uvm_info(get_name(), "=== Running Random Image Test with Stalls ===", UVM_MEDIUM)
            random_seq = cnn_random_image_seq::type_id::create("random_seq");
            random_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
            #500ns;
        end
        
        `uvm_info(get_name(), "All test sequences completed", UVM_MEDIUM)
        
        // Drop objection
        phase.drop_objection(this);
        
    endtask : run_phase

endclass : basic_test

