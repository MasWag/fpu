library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity i2f is 
  port (
    A   : in  std_logic_vector (31 downto 0);
    CLK : in  std_logic;
    Q   : out std_logic_vector (31 downto 0));
end entity i2f;

architecture behav of i2f is
  component ZLC31 is    
    port (
      A : in  std_logic_vector (30 downto 0);
      Q : out integer range 0 to 31);
  end component ZLC31;

  signal isZero : boolean := false;
  signal sign : std_logic := '0';
  signal expr : std_logic_vector (7 downto 0) := (others => '0');
  signal mantissa : std_logic_vector (22 downto 0) := (others => '0');
  signal i : std_logic_vector (30 downto 0) := (others => '0');
  signal raw_mantissa : std_logic_vector (30 downto 0) := (others => '0');
  signal s : integer range 0 to 31 := 0;
  signal R : std_logic := '0';
  signal G : std_logic := '0';
  signal ulp : std_logic := '0';
  signal round : integer range 0 to 1 := 0;
begin  -- architecture behav
  with sign select
    raw_mantissa <=
    std_logic_vector(to_unsigned(to_integer(unsigned(not i)) + 1,31)) when '1',
    i when others;

  ZLC:ZLC31 port map(raw_mantissa,s);

  with s < 31 select
    expr <=
    std_logic_vector(to_unsigned(157 - s,8)) when true,
    (others => '0')                          when others;

  with s < 7 select
    R <=
    raw_mantissa (6- s) when true,
    '0'                              when others;

  with s < 6 and to_integer(unsigned(raw_mantissa (5-s downto 0))) /= 0 select
    G <=
    '1'                when true,
    '0'                when others;

  with s < 8 select
    ulp <=
    raw_mantissa (7-s) when true,
    '0'                              when others;

  with (R and (G or ulp)) select
    round <=
    1 when '1',
    0 when others;

  with s < 7 select
    mantissa <=
    std_logic_vector(
      shift_left (arg => unsigned(raw_mantissa),
                  count => s-7)(22 downto 0)) when false,
    std_logic_vector(
      shift_right (arg => unsigned(raw_mantissa),
                   count => 7-s)(22 downto 0)) when others;

  with isZero select
    Q <=
    sign & std_logic_vector(to_unsigned(to_integer(unsigned(expr & mantissa)) + round,31)) when false,
    (others => '0')                  when others;

  -- purpose: set input
  -- type   : combinational
  -- inputs : clk
  main_loop: process (clk) is
  begin  -- process main_loop
    if rising_edge (clk) then
      isZero <= A = x"00000000";
      sign <= A (31);
      i <= A (30 downto 0);
    end if;
  end process main_loop;

end architecture behav;
