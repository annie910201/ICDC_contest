library verilog;
use verilog.vl_types.all;
entity geofence is
    generic(
        INIT            : integer := 0;
        READ            : integer := 1;
        SORT_POINT_12   : integer := 2;
        SORT_POINT_23   : integer := 3;
        SORT_POINT_34   : integer := 4;
        SORT_POINT_45   : integer := 5;
        CHECK_IN_FENCE_0: integer := 6;
        CHECK_IN_FENCE_1: integer := 7;
        CHECK_IN_FENCE_2: integer := 8;
        CHECK_IN_FENCE_3: integer := 9;
        CHECK_IN_FENCE_4: integer := 10;
        CHECK_IN_FENCE_5: integer := 11;
        OUTPUT          : integer := 12;
        PAUSE           : integer := 13
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        X               : in     vl_logic_vector(9 downto 0);
        Y               : in     vl_logic_vector(9 downto 0);
        valid           : out    vl_logic;
        is_inside       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of INIT : constant is 1;
    attribute mti_svvh_generic_type of READ : constant is 1;
    attribute mti_svvh_generic_type of SORT_POINT_12 : constant is 1;
    attribute mti_svvh_generic_type of SORT_POINT_23 : constant is 1;
    attribute mti_svvh_generic_type of SORT_POINT_34 : constant is 1;
    attribute mti_svvh_generic_type of SORT_POINT_45 : constant is 1;
    attribute mti_svvh_generic_type of CHECK_IN_FENCE_0 : constant is 1;
    attribute mti_svvh_generic_type of CHECK_IN_FENCE_1 : constant is 1;
    attribute mti_svvh_generic_type of CHECK_IN_FENCE_2 : constant is 1;
    attribute mti_svvh_generic_type of CHECK_IN_FENCE_3 : constant is 1;
    attribute mti_svvh_generic_type of CHECK_IN_FENCE_4 : constant is 1;
    attribute mti_svvh_generic_type of CHECK_IN_FENCE_5 : constant is 1;
    attribute mti_svvh_generic_type of OUTPUT : constant is 1;
    attribute mti_svvh_generic_type of PAUSE : constant is 1;
end geofence;
