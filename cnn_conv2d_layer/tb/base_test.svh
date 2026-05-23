//------------------------------------------------------------------------------
// Class base_test
// 
// Base class for all UVM tests derived from uvm_test
// 
// This class contains the basic structure of UVM test class and provides
// basic sequences and environment to make it easier for users to create
// test cases.
// 
// This class includes:
//  - base_test: Base class for all UVM tests derived from uvm_test
//  - base_test::build_phase: Function to build the class within UVM build phase
//  - base_test::run_phase: Start UVM test in running phase
// 
// This class is a part of the test library.
// 
//------------------------------------------------------------------------------
class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    // Testbench top configuration object with all setup for the TB
    top_config m_top_config;
    
    // Testbench environment
    tb_env m_tb_env;
    
    // Number of images to process (can be overridden in derived tests)
    int unsigned num_images = 1;

    //------------------------------------------------------------------------------
    // FUNCTION: new
    // Creates and constructs the test.
    //------------------------------------------------------------------------------
    function new (string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
        
        // Get TB TOP configuration from UVM DB
        if ((uvm_config_db #(top_config)::get(null, "tb_top", "top_config", m_top_config)) == 0) begin
            `uvm_fatal(get_name(), "Cannot find <top_config> TB configuration!")
        end
    endfunction : new

    //------------------------------------------------------------------------------
    // FUNCTION: build_phase
    // Function to build the class within UVM build phase.
    //------------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create TB verification environment
        m_tb_env = tb_env::type_id::create("m_tb_env", this);
        
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // FUNCTION: run_phase
    // Start UVM test in running phase.
    //------------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        reset_seq reset;
        cnn_zero_image_seq zero_seq;

        super.run_phase(phase);
        
        `uvm_info(get_name(), $sformatf("UVM TB Starts UVM test: '%s'", get_name()), UVM_NONE)
        
        // Raise objection if no UVM test is running
        phase.raise_objection(this);
        
        // Reset DUT before start
        reset = reset_seq::type_id::create("reset");
        if (!(reset.randomize() with {
            delay == 0;
            length == 10;
        })) `uvm_fatal(get_name(), "Failed to randomize reset")
        
        reset.start(m_tb_env.m_reset_agent.m_sequencer);
        
        // Wait a bit after reset
        #50ns;
        
        // Run a default sequence (zero image) - can be overridden in derived tests
        zero_seq = cnn_zero_image_seq::type_id::create("zero_seq");
        zero_seq.start(m_tb_env.m_cnn_conv2d_layer_agent.m_sequencer);
        
        // Wait for processing to complete
        #1000ns;
        
        // Drop objection when test is done
        phase.drop_objection(this);
        
    endtask : run_phase

endclass : base_test

