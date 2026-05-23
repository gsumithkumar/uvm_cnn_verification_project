//------------------------------------------------------------------------------
// reset_monitor class
//
//  Monitor that detects the reset condition.
// 
//  This monitor detects reset condition by checking the value of reset_n signal
//  and the number of clock cycles after the reset condition.
// 
//  This monitor should be connected to the reset_seq_item analysis port of
//  the reset_seq_item class.
//  
//------------------------------------------------------------------------------
class reset_monitor  extends uvm_monitor;
    `uvm_component_param_utils(reset_monitor)

    // RESET uVC configuration object.
    reset_config m_config;
    // Monitor analysis port.
    uvm_analysis_port #(reset_seq_item)  m_analysis_port;

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        if (!uvm_config_db #(reset_config)::get(this,"","reset_config", m_config)) begin
            `uvm_fatal(get_name(),"Cannot find the VC configuration!")
        end
        m_analysis_port = new("m_reset_analysis_port", this);
    endfunction

    //------------------------------------------------------------------------------
    // FUNCTION: build
    // The build phase for the component.
    //------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // FUNCTION: run_phase
    // The run phase for the monitor.
    //------------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        reset_seq_item  seq_item;
        int unsigned clocks;
        logic reset;

        // Run forever
        forever begin
            reset = m_config.m_vif.reset;
            @(negedge m_config.m_vif.clk);
            // Wait for reset is changed
            while (reset == m_config.m_vif.reset) begin
                @(negedge m_config.m_vif.clk);
                clocks++;
            end
            // Create a new reset sequence item
            seq_item = reset_seq_item::type_id::create("seq_item");
            seq_item.reset_value = m_config.m_vif.reset;
            seq_item.clocks = clocks;
            // Write to analysis port
            m_analysis_port.write(seq_item);
            clocks= 1;
        end
    endtask : run_phase
endclass : reset_monitor
