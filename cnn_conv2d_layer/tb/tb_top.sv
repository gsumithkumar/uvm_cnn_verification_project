//------------------------------------------------------------------------------
// tb_top module
//
// This module is the top-level testbench for the CNN Conv2D Layer DUT
//
// It instantiates all of the UVC interface instances and connects them to the
// VHDL DUT. It also initializes the UVM test environment and runs the test.
// It creates the default top-level test configuration.
//
// The testbench uses the following UVC interfaces:
// - CLOCK_IF: Generates the system clock
// - RESET_IF: Generates the reset signal
// - conv2d_layer_if: Connects to the CNN Conv2D Layer DUT interface (input/output)
//
//------------------------------------------------------------------------------
module tb_top;

    // Include basic packages
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Include optional packages
    import tb_pkg::*;

    // UVC TB signal variables
    logic tb_clk;
    logic tb_rst;
    logic tb_en;
    logic [7:0] tb_input_element;  // unsigned to match VHDL conv2d_input_t (unsigned)
    logic signed [7:0] tb_output_elements [0:31];  // signed to match VHDL conv2d_output_t (signed)
    logic tb_output_data_valid;
    logic tb_complete;

    // Instantiation of CLOCK UVC interface
    clock_if i_clock_if();
    assign tb_clk = i_clock_if.clock;

    // Instantiation of RESET UVC interface
    reset_if i_reset_if(.clk(tb_clk));
    assign tb_rst = i_reset_if.reset;

    // Instantiation of CNN Conv2D Layer UVC interface
    conv2d_layer_if i_conv2d_layer_if(.clk(tb_clk), .rst(tb_rst));
    assign tb_en = i_conv2d_layer_if.en;
    assign tb_input_element = i_conv2d_layer_if.input_element;
    assign i_conv2d_layer_if.output_elements = tb_output_elements;
    assign i_conv2d_layer_if.output_data_valid = tb_output_data_valid;
    assign i_conv2d_layer_if.complete = tb_complete;

    // Instantiation of the CNN Conv2D Layer DUT (VHDL) via SystemVerilog wrapper
    cnn_conv2d_layer_wrapper_sv dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .en(tb_en),
        .input_element(tb_input_element),
        .output_elements(tb_output_elements),
        .output_data_valid(tb_output_data_valid),
        .complete(tb_complete)
    );

    // Initialize TB configuration
    initial begin
        top_config m_top_config;
        
        // Create TB top configuration and store it into UVM config DB
        m_top_config = new("m_top_config");
        uvm_config_db #(top_config)::set(null, "tb_top", "top_config", m_top_config);
        
        // Save all virtual interface instances into configuration
        m_top_config.m_clock_config.m_vif = i_clock_if;
        m_top_config.m_reset_config.m_vif = i_reset_if;
        m_top_config.m_conv2d_layer_config.m_vif = i_conv2d_layer_if;
    end

    // Start UVM test environment
    initial begin
        run_test("basic_test");
    end

endmodule : tb_top

