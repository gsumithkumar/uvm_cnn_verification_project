library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
--use std.env.all;
use std.textio.all;

package cnn_pkg is

    constant CNN_INSTANCES_GLOBAL       : integer := 1;
    constant CNN_INPUT_DATA_BITS        : integer := 8;
    subtype cnn_input_data_t is unsigned(CNN_INPUT_DATA_BITS-1 downto 0);
    type cnn_fifo_data_array_t is array(0 to CNN_INSTANCES_GLOBAL-1) of cnn_input_data_t;
    type cnn_fifo_dout_array_t is array(0 to CNN_INSTANCES_GLOBAL-1) of std_logic_vector(CNN_INPUT_DATA_BITS-1 downto 0);

    constant CONV2D_INPUT_ROWS          : integer := 28;
    constant CONV2D_INPUT_COLS          : integer := 28;
    constant CONV2D_OUTPUT_ROWS         : integer := 26;
    constant CONV2D_OUTPUT_COLS         : integer := 26;
    
    constant CONV_LAYER_KERNEL_DEPTH    : integer := 32;
    constant CONV2D_KERNEL_ROWS         : integer := 3;
    constant CONV2D_KERNEL_COLS         : integer := 3;
    constant CONV2D_KERNEL_ELEMS        : integer := (CONV2D_KERNEL_ROWS * CONV2D_KERNEL_COLS);
    
    -- Each conv2d_unit represents a single kernel to be convolved with the input data
    constant CONV2D_UNIT_INPUT_BITS     : integer := 8;
    constant CONV2D_UNIT_WEIGHT_BITS    : integer := 8;
    constant CONV2D_UNIT_BIAS_BITS      : integer := 32;
    constant CONV2D_UNIT_M0_BITS        : integer := 8;
    constant CONV2D_UNIT_N_BITS         : integer := 8;
    constant CONV2D_UNIT_OUTPUT_BITS    : integer := 8;
    
    subtype conv2d_input_t  is unsigned(CONV2D_UNIT_INPUT_BITS-1  downto 0);
    subtype conv2d_weight_t is signed(CONV2D_UNIT_WEIGHT_BITS-1 downto 0);
    subtype conv2d_bias_t   is signed(CONV2D_UNIT_BIAS_BITS-1   downto 0);
    subtype conv2d_m0_t     is signed(CONV2D_UNIT_M0_BITS-1     downto 0);
    subtype conv2d_n_t      is unsigned(CONV2D_UNIT_N_BITS-1     downto 0);
    subtype conv2d_output_t is signed(CONV2D_UNIT_OUTPUT_BITS-1 downto 0);
    
    type conv2d_unit_inputs_array_t  is array (0 to CONV2D_KERNEL_ELEMS-1) of conv2d_input_t;
    type conv2d_unit_outputs_array_t  is array (0 to CONV2D_KERNEL_ELEMS-1) of conv2d_output_t;
    type conv2d_unit_weights_array_t is array (0 to CONV2D_KERNEL_ELEMS-1) of conv2d_weight_t;
    
    -- A conv2d_layer represents a full convolutional layer, consisting of CONV_LAYER_KERNEL_DEPTH
    -- conv2d_units that each perform a convolution on the input data in parallel.
    type conv2d_layer_bias_array_t   is array (0 to CONV_LAYER_KERNEL_DEPTH-1) of conv2d_bias_t;
    type conv2d_layer_m0_array_t     is array (0 to CONV_LAYER_KERNEL_DEPTH-1) of conv2d_m0_t;
    type conv2d_layer_n_array_t      is array (0 to CONV_LAYER_KERNEL_DEPTH-1) of conv2d_n_t;
    type conv2d_layer_outputs_array_t  is array (0 to CONV_LAYER_KERNEL_DEPTH-1) of conv2d_output_t;
    type conv2d_layer_weights_array_t is array (0 to CONV_LAYER_KERNEL_DEPTH-1) of conv2d_unit_weights_array_t;
    
    -- Define, but don't initialise the constants for the convolutional layer
    constant CONV2D_LAYER_WEIGHTS_CONSTANT  : conv2d_layer_weights_array_t;
    constant CONV2D_LAYER_BIASES_CONSTANT   : conv2d_layer_bias_array_t;
    constant CONV2D_LAYER_M0_VALS_CONSTANT  : conv2d_layer_m0_array_t;
    constant CONV2D_LAYER_N_VALS_CONSTANT   : conv2d_layer_n_array_t;
    
    constant CNN_INPUT_IMAGE_SAMPLES            : integer := (CONV2D_INPUT_ROWS * CONV2D_INPUT_COLS);
    constant CNN_CONV2D_OUTPUT_MATRIX_SAMPLES   : integer := (CONV2D_OUTPUT_ROWS * CONV2D_OUTPUT_COLS);
    
    -- Maxpool
    constant MAXPOOL_LAYER_KERNEL_DEPTH     : integer := 32;
    constant MAXPOOL_UNIT_OUTPUT_BITS       : integer := 8;
    constant MAXPOOL_OUTPUT_ROWS            : integer := 13;
    constant MAXPOOL_OUTPUT_COLS            : integer := 13;
    constant MAXPOOL_OUTPUT_MATRIX_SAMPLES  : integer := (MAXPOOL_OUTPUT_ROWS * MAXPOOL_OUTPUT_COLS);
    
    subtype maxpool_input_t is signed(MAXPOOL_UNIT_OUTPUT_BITS-1 downto 0);
    
    type maxpool_layer_inputs_array_t is array  (0 to MAXPOOL_LAYER_KERNEL_DEPTH-1) of maxpool_input_t;
    
end package;

package body cnn_pkg is
    -- Entries in output without value in file are assigned to 0
--    impure function conv2d_unit_weights_init return conv2d_unit_weights_array_t is
--        file vec_file   : text open read_mode is "tb_cnn_conv2d_layer_weights.txt";
--        variable iline  : line;
--        variable weight : signed(CONV2D_UNIT_WEIGHT_BITS-1 downto 0);
--        variable i      : integer := 0;
--        variable res_t  : conv2d_unit_weights_array_t := (others => (others => '0'));
--    begin
--        readline (vec_file, iline);
--        -- Each line contains CONV2D_KERNEL_ROWS * CONV2D_KERNEL_COLS hex items, 
--        -- for the unit weights, we just read the first one
--        for i in 0 to CONV2D_KERNEL_ELEMS-1 loop
--            hread(iline, weight);
--            res_t(i) := weight;
--        end loop;
--        return res_t;
--    end function;
    
    -- Each kernel has CONV2D_KERNEL_ELEMS weights which are given on a single comma separate line
    -- There are CONV2D_LAYER_KERNEL_DEPTH lines
    impure function conv2d_layer_weights_init return conv2d_layer_weights_array_t is
        --file     vec_file       : text open read_mode is "tb_cnn_conv2d_layer_weights.txt";
        file     vec_file       : text; -- open read_mode is "tb_cnn_conv2d_layer_weights.txt";
        variable iline          : line;
        variable weight         : std_logic_vector(7 downto 0);
        variable unit_weights   : conv2d_unit_weights_array_t;
        variable kernel_idx     : integer := 0;
        variable res_t          : conv2d_layer_weights_array_t := (others => (others => (others => '0')));
    begin
        file_open(vec_file, "cnn_conv2d_layer_weights.dat", read_mode);
        while not endfile (vec_file) loop
            readline (vec_file, iline);
            for i in 0 to CONV2D_KERNEL_ELEMS-1 loop
                hread(iline, weight);
                res_t(kernel_idx)(i) := signed(weight);
            end loop;
            kernel_idx := kernel_idx + 1;
        end loop;
        return res_t;
    end function;
    
    -- Each kernel has CONV2D_KERNEL_ELEMS weights which are given on a single comma separate line
    -- There are CONV2D_LAYER_KERNEL_DEPTH lines
    impure function conv2d_layer_biases_init return conv2d_layer_bias_array_t is
        file     vec_file       : text open read_mode is "cnn_conv2d_layer_biases.dat";
        variable iline          : line;
        variable bias           : std_logic_vector(CONV2D_UNIT_BIAS_BITS-1 downto 0);
        variable unit_weights   : conv2d_layer_bias_array_t;
        variable res_t          : conv2d_layer_bias_array_t := (others => (others => '0'));
    begin
        for i in 0 to CONV_LAYER_KERNEL_DEPTH-1 loop
            readline (vec_file, iline);
            hread(iline, bias);
            res_t(i) := signed(bias);
        end loop;
        return res_t;
    end function;
    
    impure function conv2d_layer_m0_vals_init return conv2d_layer_m0_array_t is
        file     vec_file       : text open read_mode is "cnn_conv2d_layer_m0_vals.dat";
        variable iline          : line;
        variable m0             : std_logic_vector(CONV2D_UNIT_N_BITS-1 downto 0);
        variable unit_weights   : conv2d_layer_m0_array_t;
        variable res_t          : conv2d_layer_m0_array_t := (others => (others => '0'));
    begin
        for i in 0 to CONV_LAYER_KERNEL_DEPTH-1 loop
            readline (vec_file, iline);
            hread(iline, m0);
            res_t(i) := signed(m0);
        end loop;
        return res_t;
    end function;
    
    impure function conv2d_layer_n_vals_init return conv2d_layer_n_array_t is
        file     vec_file       : text open read_mode is "cnn_conv2d_layer_n_vals.dat";
        variable iline          : line;
        variable n              : std_logic_vector(CONV2D_UNIT_N_BITS-1 downto 0);
        variable unit_weights   : conv2d_layer_n_array_t;
        variable res_t          : conv2d_layer_n_array_t := (others => (others => '0'));
    begin
        for i in 0 to CONV_LAYER_KERNEL_DEPTH-1 loop
            readline (vec_file, iline);
            hread(iline, n);
            res_t(i) := unsigned(n);
        end loop;
        return res_t;
    end function;
    
    constant CONV2D_LAYER_WEIGHTS_CONSTANT  : conv2d_layer_weights_array_t  := conv2d_layer_weights_init;
    constant CONV2D_LAYER_BIASES_CONSTANT   : conv2d_layer_bias_array_t     := conv2d_layer_biases_init;
    constant CONV2D_LAYER_M0_VALS_CONSTANT  : conv2d_layer_m0_array_t       := conv2d_layer_m0_vals_init;
    constant CONV2D_LAYER_N_VALS_CONSTANT   : conv2d_layer_n_array_t        := conv2d_layer_n_vals_init;
end package body;