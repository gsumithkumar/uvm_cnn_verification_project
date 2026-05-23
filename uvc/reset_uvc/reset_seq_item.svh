//------------------------------------------------------------------------------
// reset_seq_item class
// 
// This class is used to represent the reset sequence item
// 
// This class is used to represent the reset sequence item for
// the test bench. It is used to create a reset sequence with 
// the following fields:
// - reset_delay: the delay before the reset is activated
// - reset_length: the length of the reset
// - reset_value: the value of the reset
// - clocks: the number of clocks after which the reset is deactivated
//
//------------------------------------------------------------------------------
class reset_seq_item extends uvm_sequence_item;

    // Delay before activate reset
    rand int unsigned reset_delay;
    // Reset length
    rand int unsigned reset_length;
    // Monitored reset value
    bit reset_value;
    // Monitored clocks
    int unsigned clocks;

    // Specify how variables shall be printed out
    `uvm_object_utils_begin(reset_seq_item)
    `uvm_field_int(reset_delay,UVM_ALL_ON|UVM_DEC)
    `uvm_field_int(reset_length,UVM_ALL_ON|UVM_DEC)
    `uvm_field_int(reset_value,UVM_ALL_ON|UVM_DEC)
    `uvm_field_int(clocks,UVM_ALL_ON|UVM_DEC)
    `uvm_object_utils_end

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new (string name = "reset_seq_item");
        super.new(name);
    endfunction : new

endclass : reset_seq_item
