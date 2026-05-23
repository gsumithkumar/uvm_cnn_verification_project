library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cnn_pkg.all;

-------------------------------------------------------------------------------
-- cnn_conv2d_layer_wrapper
--
-- VHDL wrapper for cnn_conv2d_layer that converts the output array to a 
-- flattened std_logic_vector for Vivado XSim mixed-language simulation
-- compatibility with SystemVerilog testbenches.
-------------------------------------------------------------------------------
entity cnn_conv2d_layer_wrapper_vhd is
    port (
        -- Externals
        clk                 : in    std_logic;
        rst                 : in    std_logic;
        en                  : in    std_logic;

        -- Input Controller Signals
        input_element       : in    unsigned(CONV2D_UNIT_INPUT_BITS-1 downto 0);
        
        -- Flattened output: 32 elements * 8 bits = 256 bits
        -- Element 0 at bits [7:0], Element 1 at bits [15:8], etc.
        output_elements_flat : out  std_logic_vector(255 downto 0);
        
        output_data_valid   : out   std_logic;
        complete            : out   std_logic
    );
end cnn_conv2d_layer_wrapper_vhd;

architecture structural of cnn_conv2d_layer_wrapper_vhd is

    component cnn_conv2d_layer is
        generic (
            INPUT_ROWS          : integer := 28;
            INPUT_COLS          : integer := 28;
            KERNEL_ROWS         : integer := 3;
            KERNEL_COLS         : integer := 3;
            KERNEL_DEPTH        : integer := 32;
            OUTPUT_ROWS         : integer := 26;
            OUTPUT_COLS         : integer := 26;
            INPUT_DATA_BITS     : integer := 8;
            WEIGHTS_DATA_BITS   : integer := 8;
            M0_DATA_BITS        : integer := 8;
            BIAS_DATA_BITS      : integer := 32;
            OUTPUT_DATA_BITS    : integer := 8;
            WEIGHTS_MATRIX      : conv2d_layer_weights_array_t := CONV2D_LAYER_WEIGHTS_CONSTANT;
            BIAS_ARRAY          : conv2d_layer_bias_array_t := CONV2D_LAYER_BIASES_CONSTANT;
            M0_ARRAY            : conv2d_layer_m0_array_t:= CONV2D_LAYER_M0_VALS_CONSTANT;
            N_RSH_ARRAY         : conv2d_layer_n_array_t:= CONV2D_LAYER_N_VALS_CONSTANT
        );
        port (
            clk                 : in    std_logic;
            rst                 : in    std_logic;
            en                  : in    std_logic;
            input_element       : in    conv2d_input_t;
            output_elements     : out   conv2d_layer_outputs_array_t;
            output_data_valid   : out   std_logic;
            complete            : out   std_logic
        );
    end component;

    signal output_elements_i : conv2d_layer_outputs_array_t;

begin

    -- Instantiate the actual DUT
    dut : cnn_conv2d_layer
        port map (
            clk               => clk,
            rst               => rst,
            en                => en,
            input_element     => input_element,
            output_elements   => output_elements_i,
            output_data_valid => output_data_valid,
            complete          => complete
        );

    -- Convert array to flattened std_logic_vector
    -- Each element is 8 bits, element i goes to bits [i*8+7 : i*8]
    gen_flatten : for i in 0 to CONV_LAYER_KERNEL_DEPTH-1 generate
        output_elements_flat((i*8)+7 downto (i*8)) <= std_logic_vector(output_elements_i(i));
    end generate;

end structural;

