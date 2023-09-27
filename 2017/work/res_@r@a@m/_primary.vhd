library verilog;
use verilog.vl_types.all;
entity res_RAM is
    port(
        res_rd          : in     vl_logic;
        res_wr          : in     vl_logic;
        res_addr        : in     vl_logic_vector(13 downto 0);
        res_datain      : in     vl_logic_vector(7 downto 0);
        res_dataout     : out    vl_logic_vector(7 downto 0);
        clk             : in     vl_logic
    );
end res_RAM;
