//------------------------------------------------------------------------------
// CNN Convolution Layer Driver
//
// This class implements the UVM driver for the CNN convolution layer UVC.
// The driver is responsible for translating high-level sequence items
// (cnn_conv_seq_item) into pin-level signal activity
// on the CNN DUT interface.
//
//
//It contains a build phase and a run phase
//-------------------------------------------------------------------------------
class conv_driver extends uvm_driver #(cnn_conv_seq_item);
`uvm_component_utils(conv_driver)

    // Config File to Access Interface to DUT
    cnn_conv_config  m_config;

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

//------------------------------------------------------------------------------
// FUNCTION: build_phase
//
// The build phase is responsible for retrieving the CNN UVC configuration
// object from the UVM configuration database. This configuration object
// contains the virtual interface handle (m_vif) that allows the driver
// to access and control the DUT signals.
//
// If the configuration object is not found, the simulation is terminated
// using a fatal error, since the driver cannot function without access
// to the DUT interface.
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(cnn_conv_config)::get(this,"","cnn_conv_config", m_config)) begin
            `uvm_fatal(get_name(),"Cannot find the UVC configuration!")
        end
    endfunction : build_phase


//------------------------------------------------------------------------------
// TASK: run_phase
//
// The run phase implements the main operational behavior of the CNN driver.
// It executes continuously throughout simulation and performs the following
// steps for each transaction:
//
// 1. Initializes the DUT input signals to safe values.
// 2. Waits for de-assertion of reset before beginning stimulus injection.
// 3. Retrieves the next sequence item from the sequencer.
// 4. Translates the abstract transaction fields into physical DUT signals:
//    - inject_stalls  -> controls the DUT enable signal (en)
//    - pixel          -> drives the CNN input pixel bus (input_element)
// 5. Drives the signals synchronously with the rising edge of the CNN clock.
// 6. Notifies the sequencer upon completion of each transaction.
//
// Each iteration of the driver loop corresponds to one pixel being driven
// into the CNN convolution layer.
//------------------------------------------------------------------------------
virtual task run_phase(uvm_phase phase);
         cnn_conv_seq_item seq_item;
        // Reset input signals of the interface
        m_config.m_vif.en <= 0;
        m_config.m_vif.input_element <= 8'h00;
        
        // Drive Pixels when Reset is de-asserted
        @(negedge m_config.m_vif.rst);
        
        // Loop forever
        forever begin
            // Wait for sequence item
            seq_item_port.get_next_item(seq_item);
            `uvm_info(get_name(),$sformatf("Driving pixel = %0d to the DUT",seq_item.pixel),UVM_HIGH)

            // Write data and set enable signal
            if (seq_item.inject_stalls) begin
                 m_config.m_vif.en <= 0;   // stall
                  `uvm_info(get_name(),$sformatf("The convolution has been stalled"),UVM_HIGH)
            end
            else begin
                m_config.m_vif.en <= 1;   // normal operation
            end
            m_config.m_vif.input_element <= seq_item.pixel;
            @(posedge m_config.m_vif.clk);
            
            seq_item_port.item_done();
        end
    endtask : run_phase

endclass