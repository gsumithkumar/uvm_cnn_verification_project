//=====================================================================
// File: cnn_conv_seqs.svh
// Description:
//   This file defines all UVM stimulus sequences used to verify the
//   CNN convolution layer. The sequences generate pixel-level input
//   transactions using the cnn_conv_seq_item, where each sequence item
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

package cnn_seq_pkg;


//=====================================================================
//  BASE IMAGE SEQUENCE (COMMON PARAMETERS)
//=====================================================================
class cnn_base_image_seq extends uvm_sequence #(cnn_conv_seq_item);
  `uvm_object_utils(cnn_base_image_seq)

  // Image size from DUT
  localparam int IMG_ROWS   = 28;
  localparam int IMG_COLS   = 28;
  localparam int IMG_PIXELS = IMG_ROWS * IMG_COLS;
  localparam int CNN_INPUT_DATA_BITS     = 8;

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

  cnn_conv_seq_item seq_itm;
  task body();

    `uvm_info(get_name(), "Starting ALL-ZERO IMAGE sequence", UVM_MEDIUM)

    seq_itm = cnn_conv_seq_item::type_id::create("seq_itm");
    for (int i = 0; i < IMG_PIXELS; i++) begin
      start_item(seq_itm);

      // All Pixels Set to Zero
      seq_itm.pixel         = 8'h00;
      seq_itm.inject_stalls = 0;

      finish_item(seq_itm);
    end
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
   
  cnn_conv_seq_item seq_itm;
  task body();

    `uvm_info(get_name(), "Starting ALL-MAX IMAGE sequence", UVM_MEDIUM)

    seq_itm = cnn_conv_seq_item::type_id::create("seq_itm");
    for (int i = 0; i < IMG_PIXELS; i++) begin
      start_item(seq_itm);

      // All Pixels Set to 255
      seq_itm.pixel         = 8'hFF;
      seq_itm.inject_stalls = 0;

      finish_item(seq_itm);
    end
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

 cnn_conv_seq_item seq_itm;
 task body();
    
    int impulse_index;

    impulse_index = IMG_PIXELS / 2;  // Center pixel of Image (784/2)

    `uvm_info(get_name(), "Starting IMPULSE IMAGE sequence", UVM_MEDIUM)

    seq_itm = cnn_conv_seq_item::type_id::create("seq_itm");

    for (int i = 0; i < IMG_PIXELS; i++) begin
      
      start_item(seq_itm);

      if (i == impulse_index)
        seq_itm.pixel = 8'hFF; 
      else
        seq_itm.pixel = 8'h00;

      seq_itm.inject_stalls = 0;

      finish_item(seq_itm);
    end
  endtask
endclass


//=====================================================================
// 4) RANDOM IMAGE SEQUENCE  WITH STALLS
//=====================================================================
class cnn_random_image_seq extends cnn_base_image_seq;
  `uvm_object_utils(cnn_random_image_seq)

  rand bit [CNN_INPUT_DATA_BITS-1:0] pixel;
  rand bit          inject_stalls;
  constraint stalls 	{  inject_stalls dist { 0:=90, 1:=10}; }

  function new(string name = "cnn_random_image_seq");
    super.new(name);
  endfunction

  cnn_conv_seq_item seq_itm;
   task body();
    `uvm_info(get_name(),"Starting RANDOM IMAGE sequence", UVM_MEDIUM)

    seq_itm = cnn_conv_seq_item::type_id::create("seq_itm");
    for (int i = 0; i < IMG_PIXELS; i++) begin
      start_item(seq_itm);

      if (!(seq_itm.randomize() with {
        seq_itm.pixel == local::pixel;
        seq_itm.inject_stalls == local::inject_stalls;
      }))
        `uvm_fatal(get_name(), "Randomization failed")

      finish_item(seq_itm);
    end
  endtask
endclass

endpackage : cnn_seq_pkg
