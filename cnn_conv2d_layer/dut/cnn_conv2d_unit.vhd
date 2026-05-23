library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cnn_pkg.all;

-------------------------------------------------------------------------------
-- cnn_conv2d_unit
--  
-- This is a fixed-multiplier based Convolution Unit, that uses KERNEL_DEPTH * 
-- KERNEL_ROWS fixed multipliers (LUT Based) to calculate a single matrix 
-- dot-product in one cycle.
-- The input data is moved in via an INPUT_COLS long shift register for each
-- kernel row, with elements (INPUTS_COLS - KERNEL_ROWS) : INPUT_COLS-1 in each
-- shift-register passed to the fixed multiplier for each kernel column element
-- in the corresponding row.
-- N.B It is important to consider the fanout here, as for a large number of
-- kernels, there will be reasonably high fanout for the input elements (since
-- the same input elements are forwarded to all kernels simulatenously)
-------------------------------------------------------------------------------
entity cnn_conv2d_unit is
    generic (
        KERNEL_ROWS         : integer := CONV2D_KERNEL_ROWS;
        KERNEL_COLS         : integer := CONV2D_KERNEL_COLS;
        
        -- Data Widths
        INPUT_DATA_BITS     : integer := CONV2D_UNIT_INPUT_BITS;
        WEIGHT_BITS         : integer := CONV2D_UNIT_WEIGHT_BITS;
        M0_BITS             : integer := CONV2D_UNIT_M0_BITS;
        BIAS_DATA_BITS      : integer := CONV2D_UNIT_BIAS_BITS;
        OUTPUT_DATA_BITS    : integer := CONV2D_UNIT_OUTPUT_BITS;
        
        -- Each convolution unit has a constant array of weights, a constant M0 scaling value,
        -- a constant right shift value, and a constant bias
        WEIGHTS             : conv2d_unit_weights_array_t;
        BIAS                : signed(CONV2D_UNIT_BIAS_BITS-1 downto 0);
        M0                  : signed(CONV2D_UNIT_M0_BITS-1 downto 0);
        RIGHT_SHIFT         : unsigned(CONV2D_UNIT_N_BITS-1 downto 0) := to_unsigned(10, CONV2D_UNIT_N_BITS)
    );
    port (
        -- Externals
        clk                 : in    std_logic;                      -- Clock
        rst                 : in    std_logic;                      -- Reset
        en                  : in    std_logic;                      -- Enable Convolutional Unit

        -- Each unit receives KERNEL_ROWS*KERNEL_COLS inputs from the cnn_conv2d_layer instance
        -- containing it. These units are passed to the corresponding fixed_multiplier unit for
        -- the kernel weight that it will be multiplied by.
        input_elements      : in    conv2d_unit_inputs_array_t;
        output_element      : out   signed(OUTPUT_DATA_BITS-1 downto 0)
    );
end cnn_conv2d_unit;

architecture behavioral of cnn_conv2d_unit is

    component fixed_multiplier
    generic (
        MULT_OP0_WIDTH      : integer := 8;
        MULT_OP1_WIDTH      : integer := 8;
        MULT_RESULT_WIDTH   : integer := 16;
        
        MULT_OP1            : signed(7 downto 0) := x"00"
    );
    port (
        clk             : in    std_logic;
        rst             : in    std_logic;
        en              : in    std_logic;
        op0             : in    signed(MULT_OP0_WIDTH-1 downto 0);
        result          : out   signed(MULT_RESULT_WIDTH-1 downto 0)
    );
    end component;
    
    constant RSH_OFFSET : integer := (2 ** (to_integer(RIGHT_SHIFT)-1));
    
    signal en_i                     : std_logic := '0';
    signal input_element_i          : std_logic_vector(INPUT_DATA_BITS-1 downto 0) := (others => '0');
    signal output_element_i         : signed(OUTPUT_DATA_BITS-1 downto 0) := (others => '0');
    
    type state_t is (s0_init, s1_convolve);
    signal current_state    : state_t := s0_init;
    signal next_state       : state_t := s0_init;
    
    type fixed_mults_out_array_t is  array(0 to KERNEL_ROWS*KERNEL_COLS) of signed((INPUT_DATA_BITS+WEIGHT_BITS)-1 downto 0);
    signal mult_out_data : fixed_mults_out_array_t := (others => (others => '0'));
 
    signal biased_result_i  : signed(CONV2D_UNIT_BIAS_BITS-1 downto 0) := (others => '0');
    signal scaled_result_i  : signed(CONV2D_UNIT_BIAS_BITS+8-1 downto 0) := (others => '0');
    signal shifted_result_i : signed(CONV2D_UNIT_BIAS_BITS+8-1 downto 0) := (others => '0');
    signal adder_out_tmp_i  : signed(31 downto 0) := (others => '0');
    
    -- We have 9-elements that must be summed, we pre-add the first two elements and drive these
    -- into the first element of the first layer, after which we add pairs of inputs together
    -- Layer 1: (9-2 pre-added elements = 7 + 1 input elements = 4 additions)
    -- Layer 2: 4 input elements = 2 additions
    -- Layer 3: 2 input elements = 1 additions
    type adder_array_layer_in_1_t is array(0 to 7) of signed(31 downto 0);
    type adder_array_layer_out_1_t is array(0 to 3) of signed(31 downto 0);
    type adder_array_layer_out_2_t is array(0 to 1) of signed(31 downto 0);
    
    signal adder_layer1_in   : adder_array_layer_in_1_t := (others => (others => '0'));
    signal adder_layer1_out  : adder_array_layer_out_1_t := (others => (others => '0'));
    signal adder_layer2_out  : adder_array_layer_out_2_t := (others => (others => '0'));
    
begin


    gen_fixed_mult_units : for i in 0 to ((KERNEL_ROWS*KERNEL_COLS)-1) generate
      begin
         fixed_mult_i : fixed_multiplier
            generic map (
                MULT_OP0_WIDTH  => INPUT_DATA_BITS,
                MULT_OP1_WIDTH  => WEIGHT_BITS,
                MULT_OP1        => WEIGHTS((KERNEL_ROWS*KERNEL_COLS)-1-i)
            )
            port map(         
                clk             => clk,
                rst             => rst,
                en              => en,
                op0             => signed(input_elements(i)),
                result          => mult_out_data(i)
            );
    end generate;
    
    -- Pre-add the first two elements to give us a balanced tree
    p_capture_fm_out : process(clk, rst)
    begin
        if rst = '1' then
            adder_layer1_in(0)  <= (others => '0');
            adder_layer1_in(1)  <= (others => '0');
        elsif rising_edge(clk) then
            if (en = '1') then
                adder_layer1_in(0) <= (resize(mult_out_data(0), adder_layer1_in(0)'length) + resize(mult_out_data(1), adder_layer1_in(0)'length));
                adder_layer1_in(1) <= (resize(mult_out_data(2), adder_layer1_in(0)'length));
            else
                adder_layer1_in(0)  <= (others => '0');
                adder_layer1_in(1)  <= (others => '0');
            end if;
        end if;
    end process;
    
    gen_adder_tree_a : for i in 1 to 3 generate
    begin
        p_capture_fm_out : process(clk, rst)
        begin
            if rst = '1' then
                adder_layer1_in((i*2))  <= (others => '0');
                adder_layer1_in((i*2)+1)  <= (others => '0');
            elsif rising_edge(clk) then
                -- The A input of each adder comes from the output of the previous adder
                adder_layer1_in((i*2))      <= (resize(signed(mult_out_data((i*2)+1)), adder_layer1_in(0)'length));
                adder_layer1_in((i*2)+1)    <= (resize(signed(mult_out_data((i*2)+2)), adder_layer1_in(0)'length));
            end if;
        end process;
    end generate;
    
    gen_adder_tree_layer1_out : for i in 0 to 3 generate
    begin
        adder_layer1_out(i) <= adder_layer1_in((i*2)) + adder_layer1_in((i*2)+1);
    end generate;
    
    gen_adder_tree_b : for i in 0 to 1 generate
    begin
        adder_layer2_out(i) <= adder_layer1_out(i*2) + adder_layer1_out((i*2) + 1);
    end generate;
    
    adder_out_tmp_i     <= adder_layer2_out(0) + adder_layer2_out(1);
    biased_result_i     <= adder_out_tmp_i + BIAS;
    
    p_scale_result : process(biased_result_i)
    begin
        if biased_result_i > 0 then
            scaled_result_i  <= biased_result_i * M0;
        else
            scaled_result_i <= (others => '0');
        end if;
    end process;
    
    p_shift_scaled_result : process(scaled_result_i)
    begin
        shifted_result_i <= shift_right((scaled_result_i + RSH_OFFSET), to_integer(RIGHT_SHIFT));
    end process;
        
    p_calculate_output : process(shifted_result_i)
    begin
        output_element_i <= shifted_result_i(7 downto 0);
    end process;
    
    p_fsm_reg   : process(clk, rst)
    begin
        if rst = '1' then
            current_state <= s0_init;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    p_fsm : process(current_state, 
                    next_state,
                    en_i)
    begin
        next_state  <= current_state;
        
        case (current_state) is
            when (s0_init) =>
                if (en_i = '1') then
                    next_state <= s1_convolve;
                end if;
                
            when (s1_convolve) =>
                if (en_i = '0') then
                    next_state <= s0_init;
                end if;
        end case;
        
        -- Return to the idle state if the enable line has been lowered at any point
        -- The reset asynchronously puts the system back into s_idle
        if (en_i = '0') then
            next_state <= s0_init;
        end if;
    end process;
    
    -- Drive the outputs from internal routing signals
    -- Register this to improve timing
    p_output_reg : process(clk, rst)
    begin
        if rst = '1' then
            output_element <= (others => '0');
        elsif rising_edge(clk) then
            output_element <= output_element_i;
        end if;
    end process;
    
end behavioral;
