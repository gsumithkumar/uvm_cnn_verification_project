library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_reg is
    generic (
        INPUT_WIDTH : integer := 8;
        ELEMENTS    : integer := 8
    );
    port (
        -- Global
        clk                 : in    std_logic;                      -- Clock
        rst                 : in    std_logic;                      -- Reset
        en                  : in    std_logic;                      -- Enable

        -- Data Control
        data_in         : in    std_logic_vector(INPUT_WIDTH-1 downto 0);   -- Input Element
        data_out        : out   std_logic_vector(INPUT_WIDTH-1 downto 0)    -- Output Element
    );
end shift_reg;

architecture behavioral of shift_reg is

    signal shift_reg_internal   : std_logic_vector(((INPUT_WIDTH * ELEMENTS) - 1) downto 0);

begin 

    -- New data is shifted into the bottom INPUT_WIDTH bits of the shift_reg_internal, meaning
    -- the output of the shift-register is always found in the top INPUT_WIDTH bits.
    p_capture_input_data_reg : process(clk, rst)
    begin
        if rst = '1' then
            shift_reg_internal <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                shift_reg_internal <= shift_reg_internal((INPUT_WIDTH*(ELEMENTS-1) - 1) downto 0) & data_in;
            end if;
        end if;
    end process;

    -- Drive data_out directly with the top INPUT_WIDTH bits
    data_out <= shift_reg_internal((INPUT_WIDTH*ELEMENTS - 1) downto (INPUT_WIDTH*(ELEMENTS-1)));

end architecture;