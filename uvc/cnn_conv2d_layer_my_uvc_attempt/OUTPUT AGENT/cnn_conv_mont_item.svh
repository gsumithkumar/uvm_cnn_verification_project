

// Convolution event type observed by the monitor
typedef enum {
  IMAGE_PROCESSING,     
  IMAGE_COMPLETE    // complete signal =1
} convo_event_e;
class cnn_conv_mont_item extends uvm_sequence_item;

  convo_event_e conv_status;          // PROCESSING or COMPLETE
  int unsigned  img_id;       // Pairs convo_states for an image


  // 32 output feature-map values, each 8-bit signed
  logic signed [7:0] output_elements [0:31];

  // Output Control Fields
  bit output_data_valid;
  bit complete;

  `uvm_object_utils_begin(cnn_conv_mont_item)
  `uvm_field_sarray_int(output_elements, UVM_ALL_ON)
  `uvm_field_int (output_data_valid,UVM_ALL_ON | UVM_DEC)
  `uvm_field_int (complete,UVM_ALL_ON | UVM_DEC)
  `uvm_field_int (img_id,UVM_ALL_ON | UVM_DEC)
  `uvm_field_enum (convo_event_e,conv_status,UVM_ALL_ON)
  `uvm_object_utils_end


  function new(string name = "cnn_conv_mont_item");
    super.new(name);
  endfunction

endclass
