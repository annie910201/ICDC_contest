library verilog;
use verilog.vl_types.all;
entity testfixture is
    generic(
        N_PAT           : integer := 16383
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of N_PAT : constant is 1;
end testfixture;
