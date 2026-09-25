`timescale 1ns/1ps

module fifo_sva #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
)(
    input logic                   clk,
    input logic                   rst_n,

    input logic                   wr_en,
    input logic                   rd_en,

    input logic [DATA_WIDTH-1:0]  wr_data,
    input logic [DATA_WIDTH-1:0]  rd_data,

    input logic                   empty,
    input logic                   full,

    input logic [$clog2(DEPTH+1)-1:0] count
);

    // ============================================================
    // SVA 1: EMPTY flag must correspond to count == 0
    // ============================================================

    property p_empty_correct;
        @(posedge clk)
        disable iff (!rst_n)
        empty == (count == 0);
    endproperty

    a_empty_correct:
        assert property (p_empty_correct)
        else $error("SVA FAILURE: EMPTY flag inconsistent with COUNT");


    // ============================================================
    // SVA 2: FULL flag must correspond to count == DEPTH
    // ============================================================

    property p_full_correct;
        @(posedge clk)
        disable iff (!rst_n)
        full == (count == DEPTH);
    endproperty

    a_full_correct:
        assert property (p_full_correct)
        else $error("SVA FAILURE: FULL flag inconsistent with COUNT");


    // ============================================================
    // SVA 3: FIFO count must never exceed DEPTH
    // ============================================================

    property p_count_never_overflow;
        @(posedge clk)
        disable iff (!rst_n)
        count <= DEPTH;
    endproperty

    a_count_never_overflow:
        assert property (p_count_never_overflow)
        else $error("SVA FAILURE: FIFO COUNT exceeded DEPTH");




    // ============================================================
    // SVA 5: Write while FULL must not increase occupancy
    // ============================================================

    property p_write_while_full;
        @(posedge clk)
        disable iff (!rst_n)
        full && wr_en && !rd_en
        |=> count == $past(count);
    endproperty

    a_write_while_full:
        assert property (p_write_while_full)
        else $error("SVA FAILURE: WRITE while FULL changed COUNT");


    // ============================================================
    // SVA 6: Read while EMPTY must not decrease occupancy
    // ============================================================

    property p_read_while_empty;
        @(posedge clk)
        disable iff (!rst_n)
        empty && rd_en && !wr_en
        |=> count == $past(count);
    endproperty

    a_read_while_empty:
        assert property (p_read_while_empty)
        else $error("SVA FAILURE: READ while EMPTY changed COUNT");


    // ============================================================
    // SVA 7: Normal WRITE increments COUNT
    // ============================================================

    property p_normal_write;
        @(posedge clk)
        disable iff (!rst_n)
        wr_en && !rd_en && !full
        |=> count == ($past(count) + 1);
    endproperty

    a_normal_write:
        assert property (p_normal_write)
        else $error("SVA FAILURE: Normal WRITE did not increment COUNT");


    // ============================================================
    // SVA 8: Normal READ decrements COUNT
    // ============================================================

    property p_normal_read;
        @(posedge clk)
        disable iff (!rst_n)
        rd_en && !wr_en && !empty
        |=> count == ($past(count) - 1);
    endproperty

    a_normal_read:
        assert property (p_normal_read)
        else $error("SVA FAILURE: Normal READ did not decrement COUNT");


    // ============================================================
    // SVA 9: Simultaneous READ + WRITE preserves occupancy
    // ============================================================

    property p_simultaneous_rd_wr;
        @(posedge clk)
        disable iff (!rst_n)
        wr_en && rd_en && !empty && !full
        |=> count == $past(count);
    endproperty

    a_simultaneous_rd_wr:
        assert property (p_simultaneous_rd_wr)
        else $error("SVA FAILURE: Simultaneous RD+WR changed COUNT");


    // ============================================================
    // SVA 10: Reset forces EMPTY
    // ============================================================

    property p_reset_empty;
        @(posedge clk)
        !rst_n |-> empty;
    endproperty

    a_reset_empty:
        assert property (p_reset_empty)
        else $error("SVA FAILURE: FIFO not EMPTY during RESET");


    // ============================================================
    // SVA 11: Reset forces count to zero
    // ============================================================

    property p_reset_count;
        @(posedge clk)
        !rst_n |-> (count == 0);
    endproperty

    a_reset_count:
        assert property (p_reset_count)
        else $error("SVA FAILURE: FIFO COUNT not zero during RESET");


    // ============================================================
    // SVA 12: EMPTY and FULL cannot both be asserted
    // ============================================================

    property p_empty_not_full;
        @(posedge clk)
        !(empty && full);
    endproperty

    a_empty_not_full:
        assert property (p_empty_not_full)
        else $error("SVA FAILURE: EMPTY and FULL asserted simultaneously");


endmodule