//------------------------------------------------------------------------------
// top_config class
//
// Top level configuration object for the CNN Conv2D Layer testbench.
// This class is intended to be used by the UVM configuration database.
//
// It contains the configuration objects for each agent in the system and
// configures them appropriately for the test.
//
// The configuration includes:
// - Clock configuration (clock period, active status)
// - Reset configuration (active status, monitor enable)
// - CNN Conv2D Layer configuration (active status, monitor enable)
//
//------------------------------------------------------------------------------
class top_config extends uvm_object;
    `uvm_object_param_utils(top_config)

    // Clock configuration instance for clock agent UVC.
    clock_config m_clock_config;
    
    // Reset configuration instance for reset agent UVC.
    reset_config m_reset_config;
    
    // CNN Conv2D Layer configuration instance for convolution layer agent UVC.
    conv2d_layer_config m_conv2d_layer_config;

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new (string name = "top_config");
        super.new(name);
        
        // Create and configure clock UVC with 10ns clock generation
        m_clock_config = new("m_clock_config");
        m_clock_config.is_active = 1;
        m_clock_config.clock_period = 10;
        
        // Create and configure reset UVC configuration with driver and monitor
        m_reset_config = new("m_reset_config");
        m_reset_config.is_active = 1;
        m_reset_config.has_monitor = 1;
        
        // Create and configure CNN Conv2D Layer UVC configuration with driver and monitor
        m_conv2d_layer_config = new("m_conv2d_layer_config");
        m_conv2d_layer_config.is_active = 1;
        m_conv2d_layer_config.has_monitor = 1;
        
    endfunction : new

endclass : top_config

