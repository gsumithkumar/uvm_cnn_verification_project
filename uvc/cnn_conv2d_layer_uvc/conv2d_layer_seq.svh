//=====================================================================
// File: conv2d_layer_seq.svh
// Description:
//   This file defines all UVM stimulus sequences used to verify the
//   CNN convolution layer. The sequences generate pixel-level input
//   transactions using the conv2d_layer_seq_item, where each sequence item
//   represents ONE input pixel applied to the DUT in a single clock
//   cycle along with a control input to induce stalls.
//
//   The sequences in this file implement multiple image-level stimulus
//   scenarios required by the verification plan, including:
//     - All-zero image 
//     - All-maximum image (255) 
//     - Impulse image 
//     - Random image with probabilistic stall injection
//
//   Each sequence transmits a complete image as a series stream of
//   784 sequential pixel transactions. Input stalls are modeled at
//   the transaction level and translated by the driver into DUT-level
//   control of the 'en' signal.
//=====================================================================

//=====================================================================
//  BASE IMAGE SEQUENCE (COMMON PARAMETERS)
//=====================================================================

class cnn_base_image_seq extends uvm_sequence #(conv2d_layer_seq_item);
  `uvm_object_utils(cnn_base_image_seq)

  // Random seed
  localparam int SEED = 7777;
  
  // Image size from DUT
  localparam int IMG_ROWS   = 28;
  localparam int IMG_COLS   = 28;
  localparam int IMG_PIXELS = IMG_ROWS * IMG_COLS;
  localparam int CNN_INPUT_DATA_BITS     = 8;

  bit [CNN_INPUT_DATA_BITS-1:0] input_matrix [IMG_PIXELS];

  function new(string name = "cnn_base_image_seq");
    super.new(name);
  endfunction
endclass
//=====================================================================
// 1) ALL-ZERO IMAGE SEQUENCE  
//=====================================================================
class cnn_zero_image_seq extends cnn_base_image_seq;
  `uvm_object_utils(cnn_zero_image_seq)

  function new(string name = "cnn_zero_image_seq");
    super.new(name);
  endfunction

  conv2d_layer_seq_item seq_itm;
  task body();

    `uvm_info(get_name(), "Starting ALL-ZERO IMAGE sequence", UVM_MEDIUM)

    seq_itm = conv2d_layer_seq_item::type_id::create("seq_itm");
    for (int i = 0; i < IMG_PIXELS; i++) begin
      input_matrix[i] = 8'h00;
    end
    start_item(seq_itm);
    seq_itm.input_matrix = input_matrix;
    seq_itm.inject_stalls = 0;
    finish_item(seq_itm);
  endtask
endclass


//=====================================================================
// 2) ALL-MAX IMAGE SEQUENCE 
//=====================================================================
class cnn_max_image_seq extends cnn_base_image_seq;
  `uvm_object_utils(cnn_max_image_seq)

  function new(string name = "cnn_max_image_seq");
    super.new(name);
  endfunction
   
  conv2d_layer_seq_item seq_itm;
  task body();

    `uvm_info(get_name(), "Starting ALL-MAX IMAGE sequence", UVM_MEDIUM)

    seq_itm = conv2d_layer_seq_item::type_id::create("seq_itm");
    for (int i = 0; i < IMG_PIXELS; i++) begin
      input_matrix[i] = 8'hFF;
    end 
    start_item(seq_itm);
    seq_itm.input_matrix = input_matrix;
    seq_itm.inject_stalls = 0;
    finish_item(seq_itm);
  endtask
endclass


//=====================================================================
// 3) IMPULSE IMAGE SEQUENCE 
//=====================================================================
class cnn_impulse_image_seq extends cnn_base_image_seq;
  `uvm_object_utils(cnn_impulse_image_seq)

  function new(string name = "cnn_impulse_image_seq");
    super.new(name);
  endfunction

 conv2d_layer_seq_item seq_itm;
 task body();
    
    int impulse_index;

    impulse_index = IMG_ROWS / 2 * IMG_COLS + IMG_COLS / 2;  // Center pixel of Image (28/2 * 28 + 28/2 = 14 * 28 + 14 = 392 + 14 = 406)

    `uvm_info(get_name(), "Starting IMPULSE IMAGE sequence", UVM_MEDIUM)

    seq_itm = conv2d_layer_seq_item::type_id::create("seq_itm");

    for (int i = 0; i < IMG_PIXELS; i++) begin
      if (i == impulse_index)
        input_matrix[i] = 8'hFF;
      else
        input_matrix[i] = 8'h00;
    end
      
    start_item(seq_itm);
    seq_itm.input_matrix = input_matrix;
    seq_itm.inject_stalls = 0;
    finish_item(seq_itm);
  endtask
endclass


//=====================================================================
// 4) RANDOM IMAGE SEQUENCE  WITH STALLS
//=====================================================================
class cnn_random_image_seq extends cnn_base_image_seq;
  `uvm_object_utils(cnn_random_image_seq)

  function new(string name = "cnn_random_image_seq");
    super.new(name);
  endfunction

  conv2d_layer_seq_item seq_itm;
   task body();
    `uvm_info(get_name(),"Starting RANDOM IMAGE sequence", UVM_MEDIUM)

    seq_itm = conv2d_layer_seq_item::type_id::create("seq_itm");
    if (!(seq_itm.randomize() with {
      seq_itm.inject_stalls == 0;
    }))
      `uvm_fatal(get_name(), "Randomization failed")

    start_item(seq_itm);
    finish_item(seq_itm);
  endtask
endclass
