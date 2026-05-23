//------------------------------------------------------------------------------
// tb_env class
//
// This class represents the environment of the TB (Test Bench) for the
// CNN Conv2D Layer which is composed of the different agents and the scoreboard.
// 
// The environment is initialized by getting the TB configuration from the UVM
// database and then creating all the components:
// - Clock agent
// - Reset agent  
// - CNN Conv2D Layer agent
// - Scoreboard
//
// The environment connects the monitor analysis ports of the agents to the
// scoreboard for verification and functional coverage collection.
//
//------------------------------------------------------------------------------
class tb_env extends uvm_env;
    `uvm_component_utils(tb_env)

    // TB configuration object with all setup for the TB environment
    top_config m_top_config;
    
    // Clock instance with clock UVC
    clock_agent m_clock_agent;
    
    // Reset instance with reset UVC
    reset_agent m_reset_agent;
    
    // CNN Conv2D Layer instance with convolution layer UVC
    conv2d_layer_agent m_cnn_conv2d_layer_agent;
    
    // Scoreboard instance
    scoreboard m_scoreboard;

    //------------------------------------------------------------------------------
    // Creates and initializes an instance of this class using the normal
    // constructor arguments for uvm_component.
    //------------------------------------------------------------------------------
    function new (string name = "tb_env", uvm_component parent = null);
        super.new(name, parent);
        
        // Get TOP TB configuration from UVM DB
        if ((uvm_config_db #(top_config)::get(null, "tb_top", "top_config", m_top_config)) == 0) begin
            `uvm_fatal(get_name(), "Cannot find <top_config> TB configuration!")
        end
    endfunction : new

    //------------------------------------------------------------------------------
    // Build all the components in the TB environment
    //------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Build clock UVC
        uvm_config_db #(clock_config)::set(this, "m_clock_agent*", "config", m_top_config.m_clock_config);
        m_clock_agent = clock_agent::type_id::create("m_clock_agent", this);
        
        // Build reset UVC
        uvm_config_db #(reset_config)::set(this, "m_reset_agent*", "config", m_top_config.m_reset_config);
        m_reset_agent = reset_agent::type_id::create("m_reset_agent", this);
        
        // Build CNN Conv2D Layer UVC
        uvm_config_db #(conv2d_layer_config)::set(this, "m_cnn_conv2d_layer_agent*", "config", m_top_config.m_conv2d_layer_config);
        m_cnn_conv2d_layer_agent = conv2d_layer_agent::type_id::create("m_cnn_conv2d_layer_agent", this);
        
        // Build scoreboard component
        m_scoreboard = scoreboard::type_id::create("m_scoreboard", this);
        
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // This function is used to connect the UVC monitor analysis ports to the scoreboard
    //------------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Making all connections from analysis ports to scoreboard
        m_reset_agent.m_monitor.m_analysis_port.connect(m_scoreboard.m_reset_ap);
        m_cnn_conv2d_layer_agent.m_monitor.m_analysis_port.connect(m_scoreboard.m_cnn_output_ap);
        
    endfunction : connect_phase

endclass : tb_env

