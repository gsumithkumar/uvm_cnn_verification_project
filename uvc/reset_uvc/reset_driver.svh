//------------------------------------------------------------------------------
// reset_driver class
//
// This class models the reset driver for the reset sequencer.
// 
// The reset driver is responsible for sending the reset signal to the DUT
// according to the reset sequences received from the sequencer.
// 
// The reset driver uses a reset_seq_item, which is a sequence item that
// contains the reset delay and length.
//
//------------------------------------------------------------------------------
class reset_driver extends uvm_driver #(reset_seq_item);
    `uvm_component_param_utils(reset_driver)

    // RESET uVC configuration object.
    reset_config  m_config;

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        if (!uvm_config_db #(reset_config)::get(this,"","reset_config", m_config)) begin
            `uvm_fatal(get_name(),"Cannot find the VC configuration!")
        end
    endfunction

    //------------------------------------------------------------------------------
    // The build phase for the component.
    //------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // The run phase for the component.
    //------------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        reset_seq_item seq_item;
        // Reset signal
        m_config.m_vif.reset <= 1;
        // Main loop
        forever begin
            // Wait for sequence item
            seq_item_port.get(seq_item);
            // Perform the requested action and send response back.
            `uvm_info(get_name(),$sformatf("RESET transaction delay=%0d length=%0d", seq_item.reset_delay, seq_item.reset_length), UVM_FULL)
            for (int nn=0; nn < seq_item.reset_delay; nn++) begin
                @(posedge m_config.m_vif.clk);
            end
            if (seq_item.reset_delay > 0) begin
                @(posedge m_config.m_vif.clk);
            end
            m_config.m_vif.reset <= 1;
            `uvm_info(get_name(),$sformatf("RESET activated"), UVM_FULL)
            for (int nn=0; nn < seq_item.reset_length; nn++) begin
                @(posedge m_config.m_vif.clk);
            end
            m_config.m_vif.reset <= 0;
            `uvm_info(get_name(),$sformatf("RESET deactivated"), UVM_FULL)
            seq_item_port.put(seq_item);
        end
    endtask : run_phase

endclass : reset_driver
