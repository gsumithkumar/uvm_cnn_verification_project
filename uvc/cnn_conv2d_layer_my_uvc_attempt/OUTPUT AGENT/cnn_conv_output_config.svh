//-------------------------------------------------------------------------------------------------------------
// File Description : 
// This class is a UVM configuration object used to control how the CNN Convolution Layer UVC is built and
// how it connects to the DUT during simulation.
//
// It determines which UVM components should be active in a given simulation.
//
// Controls to Enable/Disable UVM components:
//  has_monitor - Indicates whether the monitor is created to observe DUT activity.
//
// This class also provides the connection point between the UVM environment and the DUT.
//
// Virtual Interface handle to the CNN Convolution Layer DUT:
//  m_vif - Virtual interface that allows the driver and monitor to access DUT signals.
//
//-------------------------------------------------------------------------------------------------------------
class cnn_conv_output_config extends uvm_object;

    // The monitor is active. 
    bit has_monitor = 1;
    // Interface for CNN Convolution Layer DUT
    virtual conv2d_if m_vif;

    `uvm_object_utils_begin(cnn_conv_output_config)
    `uvm_field_int(has_monitor,UVM_ALL_ON|UVM_DEC)
    `uvm_object_utils_end

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new (string name = "cnn_conv_output_config");
        super.new(name);
    endfunction : new

endclass : cnn_conv_output_config
