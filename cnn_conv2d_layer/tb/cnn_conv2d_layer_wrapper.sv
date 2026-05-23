//------------------------------------------------------------------------------
// cnn_conv2d_layer_wrapper
//
// SystemVerilog wrapper for the VHDL cnn_conv2d_layer module
// This wrapper handles type conversion between VHDL flattened std_logic_vector
// and SystemVerilog unpacked arrays for mixed-language simulation compatibility
// in Vivado XSim
//------------------------------------------------------------------------------

module cnn_conv2d_layer_wrapper_sv (
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [7:0] input_element,
    output logic signed [7:0] output_elements [0:31],
    output logic output_data_valid,
    output logic complete
);

    // Flattened output from VHDL wrapper: 32 elements * 8 bits = 256 bits
    wire [255:0] output_elements_flat;

    // Unpack flattened vector into array
    // Element i comes from bits [i*8+7 : i*8]
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : unpack_output
            assign output_elements[i] = $signed(output_elements_flat[i*8 +: 8]);
        end
    endgenerate

    // Instantiate the VHDL wrapper (not the DUT directly)
    cnn_conv2d_layer_wrapper_vhd dut_wrapper (
        .clk(clk),
        .rst(rst),
        .en(en),
        .input_element(input_element),
        .output_elements_flat(output_elements_flat),
        .output_data_valid(output_data_valid),
        .complete(complete)
    );

endmodule : cnn_conv2d_layer_wrapper_sv

