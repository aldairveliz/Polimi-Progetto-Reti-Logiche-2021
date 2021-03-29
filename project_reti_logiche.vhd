library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type STATE is (RST, REQ_LETT, ELAB_LETT, LETT, CALCOLO, CALCOLO_PIXEL, REQ_SCR, ELAB_SCR, DONE, FINE);
    signal STATE_CURR: STATE;
    signal MEM_ADDRESS, count, dim, temp_pixel: std_logic_vector(15 downto 0);
    signal min, max, current, dim_x, dim_y, delta_value: std_logic_vector(7 downto 0);
    signal shift: std_logic_vector(3 downto 0);
    signal selezione: std_logic_vector(1 downto 0);
    signal modifica: std_logic;
begin
    process(i_clk, i_rst)
    begin
    if(i_clk'event and i_clk='1') then 
        if (i_rst = '1') then
            STATE_CURR <= RST;
        elsif(i_rst = '0') then
        case STATE_CURR is
            when RST =>
                MEM_ADDRESS <= (others => '0');
                count <= (others => '0');
                dim <= (others => '0');
                temp_pixel <= (others => '0');
                min <= (others => '1');
                max <= (others => '0');
                current <= (others => '0');
                dim_x <= (others => '0');
                dim_y <= (others => '0');
                delta_value <= (others => '0');
                shift <= (others => '0');
                selezione <= (others => '0');
                modifica <= '0';
                o_done <= '0';                
                if (i_start = '1') then     
                    o_en <= '1';             
                    o_we <= '0';       
                    STATE_CURR <= REQ_LETT;                                        
                end if;
            when REQ_LETT =>
                o_address <= MEM_ADDRESS;
                STATE_CURR <= ELAB_LETT;
            when ELAB_LETT => 
                STATE_CURR <= LETT;
            when LETT =>
                if(selezione = "00") then
                    dim_x <= i_data;
                    MEM_ADDRESS <= MEM_ADDRESS + 1;
                    selezione <= "01";
                    STATE_CURR <= REQ_LETT;
                elsif(selezione = "01") then
                    dim_y <= i_data;
                    MEM_ADDRESS <= MEM_ADDRESS + 1;
                    selezione <= "10";
                    STATE_CURR <= REQ_LETT;
                elsif(selezione = "10") then
                    dim <= dim_x * dim_y;
                    current <= i_data;
                    MEM_ADDRESS <= MEM_ADDRESS + 1;
                    selezione <= "11";
                    STATE_CURR <= CALCOLO;
                elsif(selezione = "11") then
                    current <= i_data;
                    MEM_ADDRESS <= MEM_ADDRESS + 1;
                    if(modifica = '1') then
                        STATE_CURR <= CALCOLO_PIXEL;
                    else
                        STATE_CURR <= CALCOLO;
                    end if;
                end if;
            when CALCOLO =>
                if(conv_integer(dim) = 0)then
                    STATE_CURR <= DONE;
                end if;
                if(conv_integer(count) < conv_integer(dim)) then 
                    if( current < min) then
                        min <= current;
                    end if;
                    if( current > max) then
                        max <= current;
                    end if;
                    count <= count + 1;
                    STATE_CURR <= REQ_LETT;
                else
                    modifica <= '1';
                    MEM_ADDRESS <= "0000000000000010";
                    delta_value <= max - min;
                    if(modifica = '1') then
                        count <= (others => '0');
                        case conv_integer(delta_value) is
                            when 0 =>
                                shift <= "1000";
                            when 1 to 2 =>
                                shift <= "0111";
                            when 3 to 6 =>
                                shift <= "0110";
                            when 7 to 14 =>
                                shift <= "0101";
                            when 15 to 30 =>
                                shift <= "0100";
                            when 31 to 62 =>
                                shift <= "0011";
                            when 63 to 126 =>
                                shift <= "0010";
                            when 127 to 254 =>
                                shift <= "0001";
                            when 255 =>
                                shift <= "0000";
                            when others =>
                                shift <= "0000";
                        end case;                                     
                        STATE_CURR <= REQ_LETT;
                    else
                        STATE_CURR <= CALCOLO;
                    end if;
                end if;
            when CALCOLO_PIXEL =>
                if(count < dim) then
                    temp_pixel <= std_logic_vector(unsigned("00000000"&(current - min)) sll conv_integer(shift));
                    count <= count + 1;
                    STATE_CURR <= REQ_SCR;
                else
                    STATE_CURR <= DONE;
                end if;
            when REQ_SCR =>
                if(conv_integer(temp_pixel) > 255) then
                    o_data <= "11111111";
                else
                    o_data <= temp_pixel(7 downto 0);
                end if;
                o_address <= MEM_ADDRESS - 1 + conv_integer(dim);
                o_we <= '1';
                STATE_CURR <= ELAB_SCR;
            when ELAB_SCR =>
                o_we <= '0';
                STATE_CURR <= REQ_LETT;
            when DONE =>
                o_done <= '1';
                o_en <= '0';
                STATE_CURR <= FINE;
            when FINE =>
                if(i_start = '0') then
                    o_done <= '0';
                    STATE_CURR <= RST;
                end if;     
            end case;
         end if;
      end if;
    end process;
end Behavioral;