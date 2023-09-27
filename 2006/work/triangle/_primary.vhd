library verilog;
use verilog.vl_types.all;
entity triangle is
    generic(
        INPUT_MODE      : integer := 0;
        TRANSLATE_MODE  : integer := 1
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        nt              : in     vl_logic;
        xi              : in     vl_logic_vector(2 downto 0);
        yi              : in     vl_logic_vector(2 downto 0);
        busy            : out    vl_logic;
        po              : out    vl_logic;
        xo              : out    vl_logic_vector(2 downto 0);
        yo              : out    vl_logic_vector(2 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of INPUT_MODE : constant is 1;
    attribute mti_svvh_generic_type of TRANSLATE_MODE : constant is 1;
end triangle;
