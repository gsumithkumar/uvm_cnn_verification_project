interface conv2d_if (
    input logic clk,
    input logic rst
);

    // Control signal
    logic en;

    // 8-bit input pixel
    logic [7:0] input_element;

    // 32 output feature-map values, each 8-bit signed
    logic signed [7:0] output_elements [0:31];

    // Output control
    logic output_data_valid;
    logic complete;

endinterface
