//------------------------------------------------------------------------------
// conv2d_layer_if interface
//
// Interface for CNN Conv2D Layer DUT
// This interface connects the UVM testbench to the CNN convolution layer DUT
// It provides:
// - Control signals (en)
// - Input data (input_element)
// - Output data (output_elements array)
// - Output control signals (output_data_valid, complete)
//------------------------------------------------------------------------------
interface conv2d_layer_if (
    input logic clk,
    input logic rst
);

    // Control signal - Enable signal for the convolution layer
    logic en;

    // 8-bit input pixel (unsigned to match VHDL conv2d_input_t)
    logic [7:0] input_element;

    // 32 output feature-map values, each 8-bit signed (to match VHDL conv2d_output_t)
    logic signed [7:0] output_elements [0:31];

    // Output control signals
    logic output_data_valid;
    logic complete;

endinterface : conv2d_layer_if

