library verilog;
use verilog.vl_types.all;
entity sti_ROM is
    port(
        sti_rd          : in     vl_logic;
        sti_data        : out    vl_logic_vector(15 downto 0);
        sti_addr        : in     vl_logic_vector(9 downto 0);
        clk             : in     vl_logic;
        reset           : in     vl_logic
    );
end sti_ROM;
