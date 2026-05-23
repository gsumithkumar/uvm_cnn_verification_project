//------------------------------------------------------------------------------
// conv2d_layer_output_seq_item class
//
// This class represents the output transaction item from the CNN Conv2D Layer
// It is used by the monitor to capture and report the DUT output data
//
// The class contains:
// - Output feature map data (32 8-bit signed values)
// - Output control signals (output_data_valid, complete)
// - Convolution status (IMAGE_PROCESSING or IMAGE_COMPLETE)
// - Image ID for tracking multiple images
//------------------------------------------------------------------------------

// Convolution event type observed by the monitor
typedef enum {
  IMAGE_PROCESSING,     // Image processing in progress
  IMAGE_COMPLETE        // Image processing complete (complete signal = 1)
} conv_event_e;

class conv2d_layer_output_seq_item extends uvm_sequence_item;

  conv_event_e conv_status;          // PROCESSING or COMPLETE
  int unsigned img_id;               // Pairs convolution states for an image

  // 32 output feature-map values, each 8-bit signed
  logic signed [7:0] output_elements [0:31];

  // Output Control Fields
  bit output_data_valid;
  bit complete;

  `uvm_object_utils_begin(conv2d_layer_output_seq_item)
    `uvm_field_sarray_int(output_elements, UVM_ALL_ON)
    `uvm_field_int(output_data_valid, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(complete, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(img_id, UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(conv_event_e, conv_status, UVM_ALL_ON)
  `uvm_object_utils_end

  //------------------------------------------------------------------------------
  // The constructor for the sequence item.
  //------------------------------------------------------------------------------
  function new(string name = "conv2d_layer_output_seq_item");
    super.new(name);
  endfunction : new

endclass : conv2d_layer_output_seq_item

