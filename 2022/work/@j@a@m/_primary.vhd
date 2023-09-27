library verilog;
use verilog.vl_types.all;
entity JAM is
    generic(
        INIT            : integer := 0;
        GET_DATA        : integer := 1;
        CHECK_MIN       : integer := 2;
        FIND_PIVOT      : integer := 3;
        FIND_BIGGER_THAN_MIN: integer := 4;
        EXCHANGE        : integer := 5;
        FLIP_NUMBER     : integer := 6;
        OUTPUT          : integer := 7;
        FINISH          : integer := 8
    );
    port(
        CLK             : in     vl_logic;
        RST             : in     vl_logic;
        W               : out    vl_logic_vector(2 downto 0);
        J               : out    vl_logic_vector(2 downto 0);
        Cost            : in     vl_logic_vector(6 downto 0);
        MatchCount      : out    vl_logic_vector(3 downto 0);
        MinCost         : out    vl_logic_vector(9 downto 0);
        Valid           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of INIT : constant is 1;
    attribute mti_svvh_generic_type of GET_DATA : constant is 1;
    attribute mti_svvh_generic_type of CHECK_MIN : constant is 1;
    attribute mti_svvh_generic_type of FIND_PIVOT : constant is 1;
    attribute mti_svvh_generic_type of FIND_BIGGER_THAN_MIN : constant is 1;
    attribute mti_svvh_generic_type of EXCHANGE : constant is 1;
    attribute mti_svvh_generic_type of FLIP_NUMBER : constant is 1;
    attribute mti_svvh_generic_type of OUTPUT : constant is 1;
    attribute mti_svvh_generic_type of FINISH : constant is 1;
end JAM;
