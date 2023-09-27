library verilog;
use verilog.vl_types.all;
entity SET is
    generic(
        INIT            : integer := 0;
        READ            : integer := 1;
        RADIUS_SQUARE   : integer := 2;
        MODE_0          : integer := 3;
        MODE_1          : integer := 4;
        MODE_2          : integer := 5;
        OUTPUT          : integer := 6;
        PAUSE           : integer := 7
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        en              : in     vl_logic;
        central         : in     vl_logic_vector(23 downto 0);
        radius          : in     vl_logic_vector(11 downto 0);
        mode            : in     vl_logic_vector(1 downto 0);
        busy            : out    vl_logic;
        valid           : out    vl_logic;
        candidate       : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of INIT : constant is 1;
    attribute mti_svvh_generic_type of READ : constant is 1;
    attribute mti_svvh_generic_type of RADIUS_SQUARE : constant is 1;
    attribute mti_svvh_generic_type of MODE_0 : constant is 1;
    attribute mti_svvh_generic_type of MODE_1 : constant is 1;
    attribute mti_svvh_generic_type of MODE_2 : constant is 1;
    attribute mti_svvh_generic_type of OUTPUT : constant is 1;
    attribute mti_svvh_generic_type of PAUSE : constant is 1;
end SET;
