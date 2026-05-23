class conv2d_layer_seq_item extends uvm_sequence_item;

  localparam int CNN_INPUT_DATA_BITS     = 8;

  localparam int IMG_ROWS = 28;
  localparam int IMG_COLS = 28;
  localparam int IMG_PIXELS = IMG_ROWS * IMG_COLS;
  // Input Image Data  
  rand bit [CNN_INPUT_DATA_BITS-1:0] input_matrix [IMG_PIXELS];
      

  // Stalls Controls (en = 0) 
  rand bit          inject_stalls;          //1 -> TB will insert stalls (en=0).
  

  // -------------------------------------------------
  // 5) UVM registration / print control
  // -------------------------------------------------
  `uvm_object_utils_begin(conv2d_layer_seq_item)
    `uvm_field_sarray_int(input_matrix,         UVM_ALL_ON | UVM_DEC)
    `uvm_field_int       (inject_stalls,        UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  // -------------------------------------------------
  // 6) Constructor
  // -------------------------------------------------
  function new(string name = "conv2d_layer_seq_item");
    super.new(name);
  endfunction

endclass
