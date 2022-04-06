# block-minifloat-MAC

A verilog implementation of an exact multiply and add (EMA) for block minifloat artithmetic.

Please include NV_DW02_tree.v for the Vivado synthesis, and kindly note that:

(1) Unsigned/signed multiplier (including different bit-width) could be achieved by modifying Booth encoding and padding scheme;

(2) There is an constant gap between the addition result of partial sums and final result (i.e., multiplication result), which depends on bit-width and signed/unsigned multiplication. You can find this gap by behaviour simulation in Vivado and integrate it into the last row of the partial sum.
