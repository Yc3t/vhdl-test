library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hamming_module is
    Port ( 
        clk : in STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(3 downto 0);  -- 4-bit input data
        encode : in STD_LOGIC;  -- 1 for encode, 0 for decode
        data_out : out STD_LOGIC_VECTOR(6 downto 0)  -- 7-bit Hamming code output
    );
end hamming_module;

architecture Behavioral of hamming_module is
begin
    process(clk)
        variable p1, p2, p3 : STD_LOGIC;
    begin
        if rising_edge(clk) then
            if encode = '1' then
                -- Calculate parity bits
                p1 := data_in(0) xor data_in(1) xor data_in(3);
                p2 := data_in(0) xor data_in(2) xor data_in(3);
                p3 := data_in(1) xor data_in(2) xor data_in(3);
                
                -- Output format: [p1 p2 d1 p3 d2 d3 d4]
                data_out <= data_in(3) & data_in(2) & data_in(1) & p3 & data_in(0) & p2 & p1;
            else
                -- Decode and error correction would go here
                -- For now, just extract the original data
                data_out(3 downto 0) <= data_in(3 downto 0);
                data_out(6 downto 4) <= "000";
            end if;
        end if;
    end process;
end Behavioral; 