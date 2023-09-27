library verilog;
use verilog.vl_types.all;
entity STI_DAC is
    generic(
        INIT            : integer := 0;
        INPUT_DATA      : integer := 1;
        DEAL_WITH_DATA  : integer := 2;
        OUTPUT          : integer := 3;
        ADD_ZERO        : integer := 4;
        DOWN_ZERO       : integer := 5;
        FINISH          : integer := 6
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        load            : in     vl_logic;
        pi_data         : in     vl_logic_vector(15 downto 0);
        pi_length       : in     vl_logic_vector(1 downto 0);
        pi_fill         : in     vl_logic;
        pi_msb          : in     vl_logic;
        pi_low          : in     vl_logic;
        pi_end          : in     vl_logic;
        so_data         : out    vl_logic;
        so_valid        : out    vl_logic;
        pixel_finish    : out    vl_logic;
        pixel_dataout   : out    vl_logic_vector(7 downto 0);
        pixel_addr      : out    vl_logic_vector(7 downto 0);
        pixel_wr        : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of INIT : constant is 1;
    attribute mti_svvh_generic_type of INPUT_DATA : constant is 1;
    attribute mti_svvh_generic_type of DEAL_WITH_DATA : constant is 1;
    attribute mti_svvh_generic_type of OUTPUT : constant is 1;
    attribute mti_svvh_generic_type of ADD_ZERO : constant is 1;
    attribute mti_svvh_generic_type of DOWN_ZERO : constant is 1;
    attribute mti_svvh_generic_type of FINISH : constant is 1;
end STI_DAC;
