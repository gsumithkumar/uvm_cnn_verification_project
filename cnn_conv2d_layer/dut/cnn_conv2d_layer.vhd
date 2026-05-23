library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cnn_pkg.all;

-------------------------------------------------------------------------------
-- cnn_conv2d_layer
--  
-- This is a fixed-multiplier based CNN Layer, that uses KERNEL_DEPTH * 
-- KERNEL_ROWS * KERNEL_COLS fixed multipliers (LUT Based) to calculate a 
-- single matrix dot-product in one cycle.
-- The input data is moved in via an INPUT_COLS long shift register for each
-- kernel row, with elements (INPUTS_COLS - KERNEL_ROWS) : INPUT_COLS-1 in each
-- shift-register passed to the fixed multiplier for each kernel column element
-- in the corresponding row.
-- N.B It is important to consider the fanout here, as for a large number of
-- kernels, there will be reasonably high fanout for the input elements (since
-- the same input elements are forwarded to all kernels simulatenously)
-------------------------------------------------------------------------------
entity cnn_conv2d_layer is
    generic (
        -- Data Dimensions
        INPUT_ROWS          : integer := 28;
        INPUT_COLS          : integer := 28;
        
        KERNEL_ROWS         : integer := 3;
        KERNEL_COLS         : integer := 3;
        KERNEL_DEPTH        : integer := 32;
        
        OUTPUT_ROWS         : integer := 26;
        OUTPUT_COLS         : integer := 26;
        
        -- Data Widths
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
        -- Externals
        clk                 : in    std_logic;                      -- Clock
        rst                 : in    std_logic;                      -- Reset
        en                  : in    std_logic;                      -- Enable Convolutional Layer

        -- Input Controller Signals
        input_element       : in    conv2d_input_t;
        output_elements     : out   conv2d_layer_outputs_array_t;
        output_data_valid   : out   std_logic;
        complete            : out   std_logic
    );
end cnn_conv2d_layer;

architecture behavioral of cnn_conv2d_layer is

    component shift_reg is
    generic (
        INPUT_WIDTH : integer := 8;
        ELEMENTS    : integer := 8
    );
    port (
        -- Global
        clk         : in    std_logic;                      -- Clock
        rst         : in    std_logic;                      -- Reset
        en          : in    std_logic;                      -- Enable

        -- Data Control
        data_in     : in    std_logic_vector(INPUT_WIDTH-1 downto 0);   -- Input Element
        data_out    : out   std_logic_vector(INPUT_WIDTH-1 downto 0)    -- Output Element
    );
    end component;
    
    component cnn_conv2d_unit
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
    end component;

    signal en_i                 : std_logic := '0';
    signal input_element_i      : std_logic_vector(INPUT_DATA_BITS-1 downto 0) := (others => '0');
    signal output_element_i     : std_logic_vector(OUTPUT_DATA_BITS-1 downto 0) := (others => '0');
    signal mult_en_i            : std_logic := '0';
    signal mult_en_del_i        : std_logic := '0';
    signal output_data_valid_i  : std_logic := '0';
    signal complete_i           : std_logic := '0';
    
    signal conv2d_unit_input_elements_i     : conv2d_unit_inputs_array_t := (others => (others => '0'));
    signal conv2d_layer_output_elements_i   : conv2d_layer_outputs_array_t := (others => (others => '0'));
    type conv2d_unit_sr_row_t    is array (0 to KERNEL_COLS-1) of conv2d_input_t;
    type conv2d_unit_sr_matrix_t is array (0 to KERNEL_ROWS-1) of conv2d_unit_sr_row_t;
    signal conv2d_unit_sr_matrix : conv2d_unit_sr_matrix_t := (others => (others => (others => '0')));
    
    -- There are KERNEL_ROWS shift-registers in the convolutional layer, with 
    -- the input of each shift-register (besides the first) being provided from
    -- the output of the 'multiplication elements' in each row.
    type sr_io_array_t is array(0 to KERNEL_ROWS-1) of std_logic_vector(INPUT_DATA_BITS-1 downto 0);
    signal shift_reg_inputs_i       : sr_io_array_t := (others => (others => '0')); 
    signal shift_reg_outputs_i      : sr_io_array_t := (others => (others => '0')); 
    signal conv2d_unit_sr_inputs    : sr_io_array_t := (others => (others => '0')); 
    signal conv2d_unit_sr_outputs   : sr_io_array_t := (others => (others => '0')); 
    
    constant    SR_COUNTER_WIDTH         : integer := 8;
    signal      sr_row_counter           : unsigned(SR_COUNTER_WIDTH-1 downto 0) := (others => '0');
    signal      sr_col_counter           : unsigned(SR_COUNTER_WIDTH-1 downto 0) := (others => '0');
    signal      sr_row_counter_en        : std_logic := '0';
    signal      sr_row_counter_rst       : std_logic := '0';
    signal      sr_en                    : std_logic := '0';
    signal      sr_col_counter_rst       : std_logic := '0';
    
    type state_t is (s0_idle, s1_prefetch, s2_load_input, s3_conv, s4_get_next_row);
    signal current_state    : state_t := s0_idle;
    signal next_state       : state_t := s0_idle;
    
begin
    -- Since the shift-reg data is internal, and we need to be able to route the last KERNEL_COLS
    -- elements, we make the datapath up to the columns that will be passed to the conv2d_unit
    -- a generic shift_reg, then break out the last part locally.
    gen_shift_reg_rows : for i in 0 to (KERNEL_ROWS-1) generate
    begin
        sr_row_i : shift_reg
        generic map (
            INPUT_WIDTH => CONV2D_UNIT_INPUT_BITS,
            ELEMENTS    => INPUT_COLS-KERNEL_COLS
        )
        port map (
            clk         => clk,
            rst         => rst,
            en          => sr_en,
    
            -- Data Control
            data_in     => shift_reg_inputs_i(i),
            data_out    => shift_reg_outputs_i(i)
        );
    end generate;
    
    -- Route the input to the layer to the input to the first row's shift-register,
    -- route the output of each subsequent shift-register to the input of the next
    -- row's shift-register. The output of the last shift-register doesn't need to
    -- go anywhere, since that input data is no longer being used.
    shift_reg_inputs_i(0) <= std_logic_vector(input_element);
    gen_shift_reg_routing : for i in 0 to (KERNEL_ROWS-2) generate
        shift_reg_inputs_i(i+1)     <= conv2d_unit_sr_outputs(i);
    end generate;
    
    -- Need to hook up the correct parts of the shift-register, ah bollocks, we
    -- need to have 3x inputs and 3x outputs for the internal 'shift-register'
    -- belonging to each conv2d unit... Let's create KERNEL_ROWS SRs of KERNEL_COLS 
    -- elements each, but make each element within those SRs accessible to the 
    -- conv2d_unit
    gen_conv2d_unit_sr_rows : for i in 0 to (KERNEL_ROWS-1) generate
    
        conv2d_unit_sr_inputs(i)  <= shift_reg_outputs_i(i);
        conv2d_unit_sr_outputs(i) <= std_logic_vector(conv2d_unit_sr_matrix(i)(KERNEL_COLS-1));
        
        p_clk_conv2d_unit_sr_input : process(clk, rst)
        begin
            if rst = '1' then
                conv2d_unit_sr_matrix(i)(0) <= (others => '0');
            elsif rising_edge(clk) then
                conv2d_unit_sr_matrix(i)(0) <= unsigned(conv2d_unit_sr_inputs(i));
            end if;
        end process;
        
        -- Now make sure the 1st -> (KERNEL_COLS-1)th elements get clocked with the 
        -- value of the previous element
        gen_conv2d_unit_sr_cols : for j in 0 to KERNEL_COLS-2 generate
            p_clk_conv2d_unit_sr : process(clk, rst)
            begin
                if rst = '1' then
                    conv2d_unit_sr_matrix(i)(j+1) <= (others => '0');
                elsif rising_edge(clk) then
                    if (sr_en = '1') then
                        conv2d_unit_sr_matrix(i)(j+1) <= conv2d_unit_sr_matrix(i)(j);
                    end if;
                end if;
            end process;
        end generate;
        
        -- Now make sure the 1st -> (KERNEL_COLS-1)th elements get clocked with the 
        -- value of the previous element
        gen_conv2d_unit_mult_inputs : for j in 0 to KERNEL_COLS-1 generate
            conv2d_unit_input_elements_i((i*KERNEL_COLS)+j) <= conv2d_unit_sr_matrix(i)(j);
        end generate;
        
    end generate;

    generate_conv2d_units : for i in 0 to KERNEL_DEPTH-1 generate
    begin
         conv2d_unit_i : cnn_conv2d_unit
            generic map (
                WEIGHTS     => WEIGHTS_MATRIX(i),
                BIAS        => BIAS_ARRAY(i),
                M0          => M0_ARRAY(i),
                RIGHT_SHIFT => N_RSH_ARRAY(i),
                
                KERNEL_ROWS => KERNEL_ROWS,
                KERNEL_COLS => KERNEL_COLS
            )
            port map(
                clk                 => clk,
                rst                 => rst,
                en                  => en,
                input_elements      => conv2d_unit_input_elements_i,
                output_element      => conv2d_layer_output_elements_i(i)
            );
    end generate;
   
    p_sr_row_counter : process(clk, rst, sr_row_counter_rst)
    begin
        if rst = '1' then
            sr_row_counter <= (others => '0');
        elsif rising_edge(clk) then
            if sr_row_counter_en = '1' then
                sr_row_counter <= sr_row_counter + 1;
            end if;
            if sr_row_counter_rst = '1' then
                sr_row_counter <= (others => '0');
            end if;
        end if;
    end process;
    
    p_sr_col_counter : process(clk, rst, sr_col_counter_rst)
    begin
        if rst = '1' then
            sr_col_counter <= (others => '0');
        elsif rising_edge(clk) then
            if sr_en = '1' then
                if sr_col_counter_rst = '1' then
                    sr_col_counter <= (others => '0');
                else
                    sr_col_counter <= sr_col_counter + 1;
                end if;
            end if;
        end if;
    end process;

    p_fsm_reg : process(clk, rst)
    begin
        if rst = '1' then
            current_state <= s0_idle;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    p_fsm : process(current_state,
                       en, 
                       sr_col_counter)
    begin
        next_state              <= current_state;
        sr_row_counter_en    <= '0';
        sr_en    <= '0';
        sr_row_counter_rst   <= '0';
        sr_col_counter_rst   <= '0';
        mult_en_i            <= '0';
        complete_i          <= '0';
    
        case (current_state) is
            
            -- Nothing happens until we get the enable signal, then we enable the shift-registers
            -- and start moving data through.
            when s0_idle =>
                if (en = '1') then
                    sr_en <= '1';
                    next_state <= s1_prefetch;
                end if;
            
            -- This state exists for when we begin loading data from nothing. In the standard
            -- case where we're receiving one image after another, each subsequent image will
            -- be at a position just outside the (INPUT_COLS - KERNEL_COLS) index of the first
            -- processing row (since this is where the 'last' convolution window of the previous 
            -- data will occur), this means we must shift it towards the (KERNEL_ROWS-1)*INPUT_ROWS
            -- + KERNEL_COLS index to begin processing, therefore we retain that repeated operation
            -- as its own designated state 's2_load_input' and keep the initial 'pump priming' 
            -- operation (which moves the first input data elements to index (INPUT_COLS-KERNEL_COLS)-1)
            -- as a special state 's1_prefetch'
            --
            -- Imagine a 7x7 input matrix, A, being convolved with a 3x3 kernel, B, as shown below (the 
            -- * elements are the ones currently in the convolution window). If we imagine that we're 
            -- shifting the lowest index in first (input element A_{0,0}) and we're convolving with kernel 
            -- B which has its 0,0 element in the bottom right, and its 2,2 element in the top left.
            -- 
            --     0   1   2   3   4   5   6
            -- 0  [ ] [ ] [ ] [ ] [*] [*] [*]
            -- 1  [ ] [ ] [ ] [ ] [*] [*] [*]
            -- 2  [ ] [ ] [ ] [ ] [*] [*] [*]
            --
            -- We first shift the input element A_{0,0} 4 positions towards index 0,3 (with A being
            -- fed row-wise, so we have A_{0,1} at 0,2, A_{0,2} at 0,1, and A_{0,3} at 0,0, this
            -- constitutes the prefetch stage.
            --
            -- To slide the input matrix across the convolution window, we must shift another 17 times
            -- so that we now have: 
            --      A_{0,0} at 2,6, A_{0,1} at 2,5, A_{0,2} at 2,4,
            --      A_{1,0} at 1,6, A_{1,1} at 1,5, A_{1,2} at 1,4,
            --      A_{2,0} at 0,6, A_{2,1} at 0,5, A_{2,2} at 0,4,
            -- 
            -- The input matrix A is now aligned correctly with the convolution window and we can begin
            -- to convolve on each subsequent cycle as we shift the data through, until we reach the end
            -- of the row (s3_convolve), at which point we must shift without multiplying to realign the
            -- next row  with the convolution window (s4_get_next_row).
            when s1_prefetch =>
                sr_en <= '1';
                if (sr_col_counter = INPUT_COLS - KERNEL_COLS) then
                    next_state <= s2_load_input;
                    sr_col_counter_rst <= '1';
                end if;
                
            when s2_load_input =>
                mult_en_i <= '0';
                sr_en <= '1';
                if (sr_col_counter = ((KERNEL_ROWS-1)*INPUT_COLS + KERNEL_COLS) - 2) then
                    next_state <= s3_conv;
                    sr_col_counter_rst <= '1';
                end if;
       
            when s3_conv =>
                sr_en <= '1';
                mult_en_i <= '1';
                
                -- If all columns that will be processed in this row are done, then
                -- we need to fetch another row or end the test.
                if (sr_col_counter = (INPUT_COLS - KERNEL_COLS)) then
                    next_state  <= s4_get_next_row;
                    
                    -- If the row counter has reached the maximum length, we've completed the
                    -- current input matrix, and we must load the next one.
                    if (sr_row_counter = (INPUT_ROWS - KERNEL_ROWS)) then
                        complete_i          <= '1';
                        sr_row_counter_rst  <= '1';
                        sr_col_counter_rst  <= '1';
                        next_state          <= s2_load_input;
                    end if;
                end if;
       
            when s4_get_next_row =>
                mult_en_i   <= '0';
                sr_en       <= '1';
                
                if (sr_col_counter = INPUT_COLS-1) then
                    if (sr_row_counter = INPUT_ROWS - KERNEL_ROWS) then
                        sr_row_counter_rst <= '1';
                        next_state  <= s2_load_input;
                    else
                        next_state  <= s3_conv;
                    end if;
                    sr_row_counter_en    <= '1';
                    sr_col_counter_rst   <= '1';
                end if;
                
            when others         => null;
        end case;
        
        if (en = '0') then
            sr_row_counter_rst      <= '1';
            sr_col_counter_rst      <= '1';
            next_state              <= s0_idle;
        end if;
        
    end process;
    
    -- Drive the outputs from internal routing signals
    output_elements     <= conv2d_layer_output_elements_i;
    
    -- Okay, it takes two cycles from mult_en until the data is valid, so we effectively delay
    -- mult_en to get our valid signal...
    p_output_valid : process(clk, rst)
    begin
        if rst = '1' then
            mult_en_del_i       <= '0';
            output_data_valid_i <= '0';
        elsif rising_edge(clk) then
            mult_en_del_i       <= mult_en_i;
            output_data_valid_i <= mult_en_del_i;
        end if;
    end process;
    
    output_data_valid   <= output_data_valid_i;
    complete            <= complete_i;
    
end behavioral;
