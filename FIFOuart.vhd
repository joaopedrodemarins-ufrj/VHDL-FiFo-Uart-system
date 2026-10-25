library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FIFOuart is
	port(
	clk : in std_logic;
	py_entry : in std_logic_vector(7 downto 0);
	allow : in std_logic);
end entity;


architecture behaviour of FIFOuart is

constant F_num_tx : integer := 8; ------------quantidade de fifos tx
constant F_num_rx : integer := 1; ------------quantidade de fifos rx
subtype byte_t is std_logic_vector(7 downto 0);
type fifo_t is array (0 to F_num_tx - 1) of byte_t;
signal FF_all : fifo_t;      ------FF_all(3) é o byte na posição 3, FF_all(3)(2) significa o byte 3 no bit 2
signal UTXv : std_logic_vector(9 downto 0);
signal URXv : std_logic_vector(9 downto 0);
signal out_utx : std_logic := '1';
signal write : std_logic := '0';
signal read : std_logic :='0';
signal full :std_logic := '0';
signal wr_pos : integer range 0 to 7 := 0;
signal rd_pos_bit : integer range 0 to 9 := 0;
signal rd_pos_byte  : integer range 0 to F_num_tx := 0;


signal st_bit : std_logic := '0';
signal rx_pos_bit : integer range 0 to 7 :=0;
signal rx_pos_byte : integer range 0 to F_num_rx - 1 := 0;


signal cicle : std_logic := '1';
signal timer : integer := 0;

begin
UTXv(0) <= '0';
UTXv(9) <= '1';
process(clk)
begin
if rising_edge(clk) then
	if timer = 4 then -------------nesse caso, a cada 5 clocks inverte o cicle, e a cada dez (dobro de 5) incentiva o rising_edge(cicle), logo, é [X/2] - 1 pra colocar no timer
	cicle <= not cicle;
	timer <= 0;
	else
	    timer <= timer + 1;
	end if;
end if;
end process;

process(cicle , py_entry, allow)
begin

if allow = '1' and full = '0' then
	if rising_edge(cicle) then
wr_pos <= wr_pos + 1;
FF_all(wr_pos) <= py_entry;
	
	
	if wr_pos = F_num_tx - 1 then
	wr_pos <= 0;
	full <='1';
	read <= '1';
	end if;
    end if;
end if;
if read ='1' and full = '1' then

      if rd_pos_bit = 8 or rd_pos_bit = 9 then
	 out_utx <= UTXv(rd_pos_bit);
	 rd_pos_byte <= rd_pos_byte + 1;
	if rd_pos_bit = 9 then
	  out_utx <= UTXv(rd_pos_bit);
	  rd_pos_bit <= 0;
	  rd_pos_byte <= rd_pos_byte + 1;
	end_if;
        else
		if rising_edge(cicle) then
		rd_pos_bit <= rd_pos_bit + 1;
		UTXv(rd_pos_bit + 1) <= FF_all(rd_pos_byte)(rd_pos_bit);
		out_utx <= UTXv(rd_pos_bit);
		end if;
      end if;
	
	if rd_pos_byte = F_num_tx - 1 then
	rd_pos_byte <= 0;
	read <= '0';
	out_utx <= '1';
	end if;
end if;

if out_utx = '0' then
st_bit <= '1';
end if;

if rising_edge(cicle) and st_bit = '1' then
rx_pos_bit <= rx_pos_bit + 1;
URXv(rx_pos_bit) <= out_utx;
if rx_pos_bit = 9 then
rx_pos_bit <= 0;
rx_pos_byte <= rx_pos_byte +1;
    if rx_pos_byte = F_num_rx - 1 then
    rx_pos_byte <= 0;
    st_bit <= '0';
    end if;
end if;
end if;

	
end process;

end behaviour;