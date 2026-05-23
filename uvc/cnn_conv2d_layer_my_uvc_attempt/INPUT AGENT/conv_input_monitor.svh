//--------------------------------------------------------------------------------
//Description:
//
//   conv_input_monitor
//   -----------
//   This UVM monitor passively observes the CNN convolution-layer DUT interface
//   through the virtual interface handle stored in cnn_conv_config for the input
//   to the DUT.
//
// 
//   This monitor samples all the input signals like pixel, inject stalls
//   on the rising edge of clock, packages them into
//   a cnn_inp_mont_item transaction, and publishes that transaction to other
//   verification components (scoreboard / coverage) via an analysis port.

//--------------------------------------------------------------------------------

class conv_input_monitor extends uvm_monitor;
    `uvm_component_utils(conv_input_monitor)

    // Convolution Layer UVC configuration
    cnn_conv_config m_config;

    // Analysis port to scoreboard / coverage
    uvm_analysis_port #(cnn_inp_mont_item) m_analysis_port;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // build_phase:
    //
    // Purpose:
    //   - Retrieve the UVC configuration object from uvm_config_db.
    //   - Create (construct) the analysis port.
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(cnn_conv_config)::get(this,"","cnn_conv_config", m_config))
            `uvm_fatal(get_name(), "Cannot find cnn_conv_config")

       m_analysis_port = new("m_convolution_input_analysis_port", this);
       
    endfunction

//--------------------------------------------------------------------------
// run_phase:
//
// High-level operation:
//   1) Wait for each rising edge of the interface clock.
//   4) Sample the DUT input signals observed on the interface.
//   5) Package the sampled values into a transaction.
//   6) Publish the transaction to subscribers via the analysis port.
//--------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        cnn_inp_mont_item img_transac;    

        forever begin
        @(posedge m_config.m_vif.clk);
        
        img_transac = cnn_inp_mont_item::type_id::create("img_transac", this);

        img_transac.pixel         = m_config.m_vif.input_element;
        img_transac.enable_input  = m_config.m_vif.en;
        img_transac.reset_input   = m_config.m_vif.rst;

        // Publish to scoreboard
        m_analysis_port.write(img_transac);
    
    end
            
    endtask

endclass : conv_input_monitor