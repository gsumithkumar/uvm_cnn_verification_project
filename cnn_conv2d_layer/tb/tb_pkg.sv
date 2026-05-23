//------------------------------------------------------------------------------
// Testbench package for CNN Conv2D Layer verification
//
// The tb_pkg package provides a collection of files and
// UVCs that are used for testbench development
//
// It includes:
// - Clock UVC
// - Reset UVC
// - CNN Conv2D Layer UVC
// - Test Environment
// - Scoreboard
// - Tests
//
// The package also imports the UVM package and includes
// the necessary UVM macros to support UVM-based testbenches
//
//------------------------------------------------------------------------------
`timescale 1ns/1ns 
package tb_pkg;
    // Import from UVM package
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Include files from the clock UVC
    `include "clock_config.svh"
    `include "clock_driver.svh"
    `include "clock_agent.svh"
    
    // Include files from the reset UVC
    `include "reset_seq_item.svh"
    `include "reset_seq.svh"
    `include "reset_config.svh"
    `include "reset_driver.svh"
    `include "reset_monitor.svh"
    `include "reset_agent.svh"
    
    // Include files from the CNN Conv2D Layer UVC
    `include "conv2d_layer_seq_item.svh"
    `include "conv2d_layer_seq.svh"
    `include "conv2d_layer_output_seq_item.svh"
    `include "conv2d_layer_config.svh"
    `include "conv2d_layer_driver.svh"
    `include "conv2d_layer_monitor.svh"
    `include "conv2d_layer_agent.svh"
    `include "conv2d_layer_reference_model.svh"
    
    // Include files from the TB
    `include "top_config.svh"
    `include "scoreboard.svh"
    `include "tb_env.svh"
    `include "base_test.svh"
    `include "basic_test.svh"
    
endpackage: tb_pkg

