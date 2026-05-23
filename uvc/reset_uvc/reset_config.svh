//------------------------------------------------------------------------------
// reset_config class
//
// The configuration of clock.
// This class contains the configuration of reset, and the virtual interface.
//
// The configuration of reset includes:
//  is_active   - indicate whether the sequencer and driver are activated.
//  has_monitor - indicate whether the monitor is activated.
//
// The virtual interface includes:
//  m_vif - the reset uVC virtual reset_if interface.
//
//------------------------------------------------------------------------------
class reset_config extends uvm_object;

    // The Sequencer and driver are activated
    bit is_active=1;
    // The monitor is active. 
    bit has_monitor=1;
    // reset uVC virtual RESET_IF interface.
    virtual reset_if m_vif;

    `uvm_object_utils_begin(reset_config)
    `uvm_field_int(is_active,UVM_ALL_ON|UVM_DEC)
    `uvm_field_int(has_monitor,UVM_ALL_ON|UVM_DEC)
    `uvm_object_utils_end

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new (string name = "reset_config");
        super.new(name);
    endfunction : new

endclass : reset_config
