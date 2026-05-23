//------------------------------------------------------------------------------
// conv_agent class
//
// This is the top-level uVC agent for the convo2dlayer DUT interface for the output.
//
//
//------------------------------------------------------------------------------
class conv_output_agent  extends uvm_agent;
    `uvm_component_param_utils(conv_output_agent)

    // uVC monitor.
    conv_monitor m_monitor;
    // uVC configuration object.
    cnn_conv_output_config m_config;

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    //------------------------------------------------------------------------------
    // The build phase for the uVC.
    //------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Read the uVC configuration object from UVM config DB.
        if (!uvm_config_db #(cnn_conv_output_config)::get(this,"*","config",m_config)) begin
            `uvm_fatal(get_name(),"Cannot find <config> agent configuration!")
        end
        // Store uVC configuration into UVM config DB used by the uVC.
        uvm_config_db #(cnn_conv_output_config)::set(this,"*","cnn_conv_output_config",m_config);
        // Store uVC agent into UVM config DB
        if (m_config.has_monitor) begin
            // Create uVC monitor
            m_monitor = conv_output_monitor::type_id::create("conv_output_monitor",this);
        end
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // The connection phase for the uVC.
    //------------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    //------------------------------------------------------------------------------
    // The end of elaboration phase for the uVC
    //------------------------------------------------------------------------------
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_name(),$sformatf("Convolution Layer Output agent is alive...."), UVM_LOW)
    endfunction : end_of_elaboration_phase
  
endclass: conv_agent

