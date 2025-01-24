library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity toplevel is
    Port (
           reset : in std_logic;
           clk : in std_logic;
           rx : in std_logic;
           tx : out std_logic;
           LED : out std_logic  --led de comprobacion y reset
    );
end toplevel;

architecture behavioral of toplevel is
----------------------------------------------------------------
-- declaracion del picoblaze
----------------------------------------------------------------
  component picoblaze
    Port (      address : out std_logic_vector(7 downto 0);
            instruction : in std_logic_vector(15 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
                  reset : in std_logic; 
						  clk : in std_logic);
    end component;

-----------------------------------------------------------------
-- declaraci�n de la ROM de programa
-----------------------------------------------------------------
  component programa_helloworld_int 
    Port (      address : in std_logic_vector(7 downto 0);
            		   dout : out std_logic_vector(15 downto 0);
                    clk : in std_logic);
    end component;

-----------------------------------------------------------------
-- Signals usadas para conectar el picoblaze y la ROM de programa
-----------------------------------------------------------------
signal     address : std_logic_vector(7 downto 0);
signal instruction : std_logic_vector(15 downto 0);
		
-----------------------------------------------------------------
-- Signals para debugging 
-----------------------------------------------------------------
signal readstrobe: std_logic;
signal writestrobe: std_logic;
signal portid: std_logic_vector(7 downto 0);
signal inport: std_logic_vector(7 downto 0);
signal outport: std_logic_vector(7 downto 0);
signal picoint: std_logic;

type ram_type is array (0 to 63) of std_logic_vector (7 downto 0);
signal RAM : ram_type := (
x"0A", x"0D", x"2A", x"20", x"48", x"45", x"4C", x"4C",
x"4F", x"20", x"49", x"27", x"4D", x"20", x"41", x"4C",
x"49", x"56", x"45", x"21", x"20", x"3A", x"2D", x"44",
x"20", x"2A", x"0A", x"0D", x"2A", x"20", x"50", x"52",
x"45", x"53", x"53", x"20", x"41", x"4E", x"59", x"20",
x"4B", x"45", x"59", x"20", x"54", x"4F", x"20", x"43",
x"4F", x"4E", x"54", x"49", x"4E", x"55", x"45", x"20",
x"2A", x"0A", x"0D", x"00", x"00", x"00", x"00", x"00" );

signal rxbuff_out,RAM_out: std_logic_vector(7 downto 0);

-- Add to component declarations
component hamming_module
    Port ( 
        clk : in STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(3 downto 0);
        encode : in STD_LOGIC;
        data_out : out STD_LOGIC_VECTOR(6 downto 0)
    );
end component;

-- Add to signal declarations
signal hamming_in : STD_LOGIC_VECTOR(3 downto 0);
signal hamming_out : STD_LOGIC_VECTOR(6 downto 0);
signal hamming_encode : STD_LOGIC;

begin
    -- Debug LED shows rx state
    LED <= rx;  -- This will show us the rx line state
    
    -- Or alternatively, toggle LED on transmission
    -- process(clk)
    -- begin
    --     if rising_edge(clk) then
    --         if writestrobe = '1' and portid = x"FF" then
    --             LED <= not LED;  -- Toggle LED on each transmission
    --         end if;
    --     end if;
    -- end process;

    picoint <= NOT rx;

  processor: picoblaze
    port map(      address => address,
               instruction => instruction,
                   port_id => portid,
              write_strobe => writestrobe,
                  out_port => outport,
               read_strobe => readstrobe,
                   in_port => inport,
                 interrupt => picoint,
                     reset => reset,
                       clk => clk);

  program: programa_helloworld_int
    port map(     address => address,
               	     dout => instruction,
                      clk => clk);

	--registra el bit tx del puerto de salida, por si �ste cambia
	txbuff:process(reset, clk)
	begin
		if (reset='1') then
			tx <= '1';
		elsif rising_edge(clk) then
			if (writestrobe = '1' and portid=x"FF") then
				tx <= outport(0);	
			end if;
		end if;
	end process;
	
	--a�ade 7ceros a rx para meterlos al puerto de entrada cuando se lea
	rxbuff:process(reset, clk)
	begin
		if (reset='1') then
			rxbuff_out <= (others=>'1');
		elsif rising_edge(clk) then
			if (readstrobe = '1' and portid =x"FF") then
				rxbuff_out <= rx & "0000000";	
			end if;		 
		end if;
	end process;
	
	-- Memoria RAM (escritura sincrona / lectura asincrona)
	process (clk)
	begin
		if (clk'event and clk = '1') then
			if (writestrobe = '1' and portid<x"40") then
				RAM(to_integer(unsigned(portid))) <= outport;
			end if;
		end if;
	end process;
	RAM_out <= RAM(to_integer(unsigned(portid)));
	
-- Multiplexor inport
inport <= RAM_out when (readstrobe = '1' and portid<x"40") else
			 rxbuff_out when (readstrobe = '1' and portid=x"FF") else
			 "0" & hamming_out when (readstrobe = '1' and portid=x"FE") else
			 x"00";

-- Add component instantiation in architecture
hamming: hamming_module
    port map (
        clk => clk,
        data_in => hamming_in,
        encode => hamming_encode,
        data_out => hamming_out
    );

-- Add process for Hamming control
process(clk)
begin
    if rising_edge(clk) then
        if writestrobe = '1' and portid = x"FE" then
            hamming_in <= outport(3 downto 0);
            hamming_encode <= outport(7);
        end if;
    end if;
end process;

end behavioral;