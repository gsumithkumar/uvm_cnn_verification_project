class cnn_conv_seq_item extends uvm_sequence_item;

  localparam int CNN_INPUT_DATA_BITS     = 8;

  
  // Input Image Data  
  rand bit [CNN_INPUT_DATA_BITS-1:0] pixel;   // Input Picture Matrix Pixel(a single pixel of '8' bit pixels) 
      

  // Stalls Controls (en = 0) 
  rand bit          inject_stalls;          //1 -> TB will insert stalls (en=0).
  

  // -------------------------------------------------
  // 5) UVM registration / print control
  // -------------------------------------------------
  `uvm_object_utils_begin(cnn_conv_seq_item)
    `uvm_field_int       (pixel,                UVM_ALL_ON | UVM_DEC)
    `uvm_field_int       (inject_stalls,        UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  // -------------------------------------------------
  // 6) Constructor
  // -------------------------------------------------
  function new(string name = "cnn_conv_seq_item");
    super.new(name);
  endfunction

endclass
