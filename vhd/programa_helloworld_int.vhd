library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity programa_helloworld_int is
	port( address : in std_logic_vector(7 downto 0);
		clk : in std_logic;
		dout : out std_logic_vector(15 downto 0));
	end;

architecture v1 of programa_helloworld_int is

	constant ROM_WIDTH: INTEGER:= 16;
	constant ROM_LENGTH: INTEGER:= 256;

	subtype rom_word is std_logic_vector(ROM_WIDTH-1 downto 0);
	type rom_table is array (0 to ROM_LENGTH-1) of rom_word;

constant rom: rom_table := rom_table'(
	"1111000000000000",
	"1101100000001111",
	"0000011100000000",
	"1100000111100000",
	"0010000100000000",
	"1101010000001001",
	"1101100000011100",
		"1101000000110111");

begin

process (clk)
begin
	if clk'event and clk = '1' then
		dout <= rom(conv_integer(address));
	end if;
end process;
end v1;
