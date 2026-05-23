class cnn_inp_mont_item extends uvm_sequence_item;

  localparam int CNN_INPUT_DATA_BITS     = 8;

  
  // Input Image Data  
  bit [CNN_INPUT_DATA_BITS-1:0] pixel;   // Input Picture Matrix Pixel(a single pixel of '8' bit pixels) 
      

  // Enable Signal
  bit  enable_input;          //Enable Input of DUT.

  //Reset Signal
  bit reset_input;          //Reset Signal
  

  // -------------------------------------------------
  // 5) UVM registration / print control
  // -------------------------------------------------
  `uvm_object_utils_begin(cnn_inp_mont_item)
    `uvm_field_int       (pixel,                UVM_ALL_ON | UVM_DEC)
    `uvm_field_int       (enable_input,        UVM_ALL_ON | UVM_DEC)
    `uvm_field_int       (reset_input,        UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  // -------------------------------------------------
  // 6) Constructor
  // -------------------------------------------------
  function new(string name = "cnn_inp_mont_item");
    super.new(name);
  endfunction

endclass
