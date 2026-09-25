`timescale 1ns/1ps

module fifo_coverage #(
    parameter int DATA_WIDTH  = 8,
    parameter int DEPTH       = 8,
    parameter int COUNT_WIDTH = $clog2(DEPTH + 1)
) (
    input logic                   clk,
    input logic                   rst_n,

    input logic                   wr_en,
    input logic                   rd_en,

    input logic                   empty,
    input logic                   full,

    input logic [COUNT_WIDTH-1:0] count
);

    // ------------------------------------------------------------
    // Coverage counters
    // ------------------------------------------------------------

    integer reset_cycles;
    integer write_hits;
    integer read_hits;

    integer empty_hits;
    integer full_hits;

    integer partial_hits;
    integer simultaneous_rd_wr;

    integer write_when_full;
    integer read_when_empty;

    integer count_zero_hits;
    integer count_one_hits;
    integer count_mid_hits;
    integer count_depth_minus_one_hits;
    integer count_depth_hits;

    integer empty_to_nonempty;
    integer nonempty_to_empty;

    integer nonfull_to_full;
    integer full_to_nonfull;

    integer total_samples;

    // Previous state
    logic prev_empty;
    logic prev_full;

    // ------------------------------------------------------------
    // Initial values
    // ------------------------------------------------------------

    initial begin
        reset_cycles               = 0;
        write_hits                 = 0;
        read_hits                  = 0;

        empty_hits                 = 0;
        full_hits                  = 0;

        partial_hits               = 0;
        simultaneous_rd_wr         = 0;

        write_when_full            = 0;
        read_when_empty            = 0;

        count_zero_hits            = 0;
        count_one_hits             = 0;
        count_mid_hits             = 0;
        count_depth_minus_one_hits = 0;
        count_depth_hits           = 0;

        empty_to_nonempty           = 0;
        nonempty_to_empty           = 0;

        nonfull_to_full             = 0;
        full_to_nonfull             = 0;

        total_samples               = 0;

        prev_empty = 1'b1;
        prev_full  = 1'b0;
    end

    // ------------------------------------------------------------
    // Functional coverage collection
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin
            reset_cycles = reset_cycles + 1;
        end
        else begin

            total_samples = total_samples + 1;

            // ----------------------------------------------------
            // Operation coverage
            // ----------------------------------------------------

            if (wr_en)
                write_hits = write_hits + 1;

            if (rd_en)
                read_hits = read_hits + 1;

            if (wr_en && rd_en)
                simultaneous_rd_wr = simultaneous_rd_wr + 1;

            // ----------------------------------------------------
            // FIFO state coverage
            // ----------------------------------------------------

            if (empty)
                empty_hits = empty_hits + 1;

            if (full)
                full_hits = full_hits + 1;

            if (!empty && !full)
                partial_hits = partial_hits + 1;

            // ----------------------------------------------------
            // Boundary-operation coverage
            //
            // These are intentionally counted rather than treated
            // as failures. The SVA file handles correctness.
            // ----------------------------------------------------

            if (wr_en && full)
                write_when_full = write_when_full + 1;

            if (rd_en && empty)
                read_when_empty = read_when_empty + 1;

            // ----------------------------------------------------
            // Occupancy coverage
            // ----------------------------------------------------

            if (count == COUNT_WIDTH'(0))
                count_zero_hits = count_zero_hits + 1;

            if (count == COUNT_WIDTH'(1))
                count_one_hits = count_one_hits + 1;

            if ((count > COUNT_WIDTH'(1)) &&
                (count < COUNT_WIDTH'(DEPTH-1)))
                count_mid_hits = count_mid_hits + 1;

            if (count == COUNT_WIDTH'(DEPTH-1))
                count_depth_minus_one_hits =
                    count_depth_minus_one_hits + 1;

            if (count == COUNT_WIDTH'(DEPTH))
                count_depth_hits = count_depth_hits + 1;

            // ----------------------------------------------------
            // State-transition coverage
            // ----------------------------------------------------

            if (prev_empty && !empty)
                empty_to_nonempty = empty_to_nonempty + 1;

            if (!prev_empty && empty)
                nonempty_to_empty = nonempty_to_empty + 1;

            if (!prev_full && full)
                nonfull_to_full = nonfull_to_full + 1;

            if (prev_full && !full)
                full_to_nonfull = full_to_nonfull + 1;

            // Save state for next cycle
            prev_empty = empty;
            prev_full  = full;
        end
    end

    // ------------------------------------------------------------
    // Coverage report
    // ------------------------------------------------------------

    final begin

        $display("");
        $display("============================================================");
        $display("                 FIFO FUNCTIONAL COVERAGE");
        $display("============================================================");

        $display("");
        $display("Operation Coverage");
        $display("------------------------------------------------------------");
        $display("Writes                  : %0d", write_hits);
        $display("Reads                   : %0d", read_hits);
        $display("Simultaneous RD + WR    : %0d", simultaneous_rd_wr);

        $display("");
        $display("FIFO State Coverage");
        $display("------------------------------------------------------------");
        $display("EMPTY                   : %0d", empty_hits);
        $display("FULL                    : %0d", full_hits);
        $display("PARTIAL                 : %0d", partial_hits);

        $display("");
        $display("Occupancy Coverage");
        $display("------------------------------------------------------------");
        $display("COUNT = 0               : %0d", count_zero_hits);
        $display("COUNT = 1               : %0d", count_one_hits);
        $display("COUNT = MID             : %0d", count_mid_hits);
        $display("COUNT = DEPTH-1         : %0d",
                 count_depth_minus_one_hits);
        $display("COUNT = DEPTH           : %0d", count_depth_hits);

        $display("");
        $display("Boundary Operation Coverage");
        $display("------------------------------------------------------------");
        $display("WRITE while FULL        : %0d", write_when_full);
        $display("READ while EMPTY        : %0d", read_when_empty);

        $display("");
        $display("State Transition Coverage");
        $display("------------------------------------------------------------");
        $display("EMPTY -> NONEMPTY       : %0d", empty_to_nonempty);
        $display("NONEMPTY -> EMPTY       : %0d", nonempty_to_empty);
        $display("NONFULL -> FULL         : %0d", nonfull_to_full);
        $display("FULL -> NONFULL         : %0d", full_to_nonfull);

        $display("");
        $display("Total sampled cycles    : %0d", total_samples);
        $display("Reset cycles            : %0d", reset_cycles);

        $display("");
        $display("============================================================");
        $display("              END FIFO FUNCTIONAL COVERAGE");
        $display("============================================================");
        $display("");
    end

endmodule