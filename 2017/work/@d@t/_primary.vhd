library verilog;
use verilog.vl_types.all;
entity DT is
    generic(
        INITIAL         : integer := 1;
        READ_INIT       : integer := 2;
        WRITE_INIT      : integer := 3;
        WRITE_INIT_FINISH: integer := 4;
        READ_FORWARD    : integer := 5;
        FORWARD         : integer := 6;
        WRITE_FORWARD   : integer := 7;
        FORWARD_FINISH  : integer := 8;
        READ_BACKWARD   : integer := 9;
        BACKWARD        : integer := 10;
        WRITE_BACKWARD  : integer := 11;
        BACKWARD_FINISH : integer := 12
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        done            : out    vl_logic;
        sti_rd          : out    vl_logic;
        sti_addr        : out    vl_logic_vector(9 downto 0);
        sti_di          : in     vl_logic_vector(15 downto 0);
        res_wr          : out    vl_logic;
        res_rd          : out    vl_logic;
        res_addr        : out    vl_logic_vector(13 downto 0);
        res_do          : out    vl_logic_vector(7 downto 0);
        res_di          : in     vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of INITIAL : constant is 1;
    attribute mti_svvh_generic_type of READ_INIT : constant is 1;
    attribute mti_svvh_generic_type of WRITE_INIT : constant is 1;
    attribute mti_svvh_generic_type of WRITE_INIT_FINISH : constant is 1;
    attribute mti_svvh_generic_type of READ_FORWARD : constant is 1;
    attribute mti_svvh_generic_type of FORWARD : constant is 1;
    attribute mti_svvh_generic_type of WRITE_FORWARD : constant is 1;
    attribute mti_svvh_generic_type of FORWARD_FINISH : constant is 1;
    attribute mti_svvh_generic_type of READ_BACKWARD : constant is 1;
    attribute mti_svvh_generic_type of BACKWARD : constant is 1;
    attribute mti_svvh_generic_type of WRITE_BACKWARD : constant is 1;
    attribute mti_svvh_generic_type of BACKWARD_FINISH : constant is 1;
end DT;
