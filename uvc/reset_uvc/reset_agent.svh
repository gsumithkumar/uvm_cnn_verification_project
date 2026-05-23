//------------------------------------------------------------------------------
// reset_agent class
//
// This is the top-level uVC agent for the reset interface.
//
// It reads the uvc configuration from the uvm config database and sets the
// configuration in the uvc driver. It creates the driver if the configuration
// is active and the creates monitor if the configuration has_monitor enabled.
//
//------------------------------------------------------------------------------
class reset_agent  extends uvm_agent;
    `uvm_component_param_utils(reset_agent)

    // uVC sequencer.
    uvm_sequencer #(reset_seq_item) m_sequencer;
    // uVC monitor.
    reset_monitor m_monitor;
    // uVC driver.
    reset_driver m_driver;
    // uVC configuration object.
    reset_config m_config;

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
        if (!uvm_config_db #(reset_config)::get(this,"*","config",m_config)) begin
            `uvm_fatal(get_name(),"Cannot find <config> agent configuration!")
        end
        // Store uVC configuration into UVM config DB used by the uVC.
        uvm_config_db #(reset_config)::set(this,"*","reset_config",m_config);
        // Create uVC sequencer and driver
        if (m_config.is_active == UVM_ACTIVE) begin
            m_sequencer = uvm_sequencer #(reset_seq_item)::type_id::create("reset_sequencer",this);
            m_driver = reset_driver::type_id::create("reset_driver",this);
        end
        // Create uVC monitor
        if (m_config.has_monitor) begin
            m_monitor = reset_monitor::type_id::create("reset_monitor",this);
        end
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // The connection phase for the uVC.
    //------------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // If driver active connect then sequencer to the driver.
        if (m_config.is_active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end
    endfunction : connect_phase

    //------------------------------------------------------------------------------
    // The end of elaboration phase for the uVC
    //------------------------------------------------------------------------------
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_name(),$sformatf("RESET agent is alive...."), UVM_LOW)
    endfunction : end_of_elaboration_phase
  
endclass: reset_agent
