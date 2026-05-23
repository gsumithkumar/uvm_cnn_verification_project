library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_multiplier is
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
end fixed_multiplier;

architecture rtl of fixed_multiplier is

    signal en_i     : std_logic := '0';
    signal result_i : signed(MULT_RESULT_WIDTH downto 0);
    
begin

    en_i    <= en;

--    p_mult : process(clk)
--    begin
--        if rst = '1' then
--            result <= (others => '0');
--        elsif rising_edge(clk) then
--            if en = '1' then
--                result <= op0 * MULT_OP1;
--            end if;
--        end if;
--    end process;

    result_i <= (('0' & op0) * MULT_OP1) when en = '1' and rst = '0' else (others => '0');
    result <= result_i(MULT_RESULT_WIDTH-1 downto 0);
     
 end rtl;