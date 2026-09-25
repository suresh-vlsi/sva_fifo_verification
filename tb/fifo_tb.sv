`timescale 1ns/1ps

module fifo_tb;

    // ============================================================
    // PARAMETERS
    // ============================================================
    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 8;
    localparam int COUNT_WIDTH = $clog2(DEPTH + 1);

    // ============================================================
    // SIGNALS
    // ============================================================
    logic                   clk;
    logic                   rst_n;

    logic                   wr_en;
    logic                   rd_en;

    logic [DATA_WIDTH-1:0]  wr_data;
    logic [DATA_WIDTH-1:0]  rd_data;

    logic                   empty;
    logic                   full;

    logic [COUNT_WIDTH-1:0] count_dbg;

    // ============================================================
    // DUT
    // ============================================================
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .empty (empty),
        .full  (full),
        .count_dbg(count_dbg)
    );

    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================
    fifo_coverage #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) cov (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .empty    (empty),
        .full     (full),
        .count    (count_dbg)
    );

    // ============================================================
    // CLOCK
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // WAVEFORM
    // ============================================================
    initial begin
        $dumpfile("waves/fifo.vcd");
        $dumpvars(0, fifo_tb);
    end

    // ============================================================
    // WRITE TASK
    // ============================================================
    task automatic fifo_write(
        input logic [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk);

            wr_data = data;
            wr_en   = 1'b1;
            rd_en   = 1'b0;

            @(posedge clk);
            #1;

            $display(
                "[WRITE] data=0x%02h count=%0d empty=%0b full=%0b",
                data,
                count_dbg,
                empty,
                full
            );

            @(negedge clk);

            wr_en   = 1'b0;
            wr_data = '0;
        end
    endtask

    // ============================================================
    // READ TASK
    // ============================================================
    task automatic fifo_read(
        output logic [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge clk);

            rd_en = 1'b1;
            wr_en = 1'b0;

            @(posedge clk);
            #1;

            data = rd_data;

            $display(
                "[READ ] data=0x%02h count=%0d empty=%0b full=%0b",
                rd_data,
                count_dbg,
                empty,
                full
            );

            @(negedge clk);

            rd_en = 1'b0;
        end
    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin : MAIN_TEST

        logic [DATA_WIDTH-1:0] read_value;
        integer i;

        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = '0;

        $display("");
        $display("======================================================");
        $display("              SYNCHRONOUS FIFO TEST");
        $display("======================================================");
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("DEPTH      = %0d", DEPTH);
        $display("======================================================");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------
        $display("");
        $display("[TEST 1] RESET");

        repeat (2) @(posedge clk);

        rst_n = 1'b1;

        @(posedge clk);
        #1;

        $display(
            "After reset: empty=%0b full=%0b count=%0d",
            empty,
            full,
            count_dbg
        );

        if (!empty) begin
            $error("TEST FAILURE: FIFO should be EMPTY after reset");
            $finish;
        end

        if (full) begin
            $error("TEST FAILURE: FIFO should NOT be FULL after reset");
            $finish;
        end

        if (count_dbg != 0) begin
            $error("TEST FAILURE: FIFO count should be 0 after reset");
            $finish;
        end

        // --------------------------------------------------------
        // TEST 2: WRITE ONE VALUE
        // --------------------------------------------------------
        $display("");
        $display("[TEST 2] WRITE ONE VALUE");

        fifo_write(8'hA5);

        if (count_dbg != 1) begin
            $error("TEST FAILURE: Expected count=1, got %0d",
                   count_dbg);
            $finish;
        end

        if (empty) begin
            $error("TEST FAILURE: FIFO should NOT be empty");
            $finish;
        end

        // --------------------------------------------------------
        // TEST 3: FILL FIFO
        // --------------------------------------------------------
        $display("");
        $display("[TEST 3] FILL FIFO");

        // One value is already present.
        // Add remaining DEPTH-1 values.
        for (i = 1; i < DEPTH; i = i + 1) begin
            fifo_write(i[DATA_WIDTH-1:0]);
        end

        @(posedge clk);
        #1;

        $display(
            "FULL state: empty=%0b full=%0b count=%0d",
            empty,
            full,
            count_dbg
        );

        if (!full) begin
            $error("TEST FAILURE: FIFO should be FULL");
            $finish;
        end

        if (count_dbg != DEPTH) begin
            $error("TEST FAILURE: FIFO count should equal DEPTH");
            $finish;
        end

        // --------------------------------------------------------
        // TEST 4: READ ALL VALUES
        // --------------------------------------------------------
        $display("");
        $display("[TEST 4] READ ALL VALUES");

        // First value should be A5
        fifo_read(read_value);

        if (read_value !== 8'hA5) begin
            $error(
                "TEST FAILURE: Expected 0xA5, got 0x%02h",
                read_value
            );
            $finish;
        end

        // Remaining values should be 1..DEPTH-1
        for (i = 1; i < DEPTH; i = i + 1) begin

            fifo_read(read_value);

            if (read_value !== i[DATA_WIDTH-1:0]) begin
                $error(
                    "TEST FAILURE: Expected 0x%02h, got 0x%02h",
                    i[DATA_WIDTH-1:0],
                    read_value
                );
                $finish;
            end

        end

        @(posedge clk);
        #1;

        $display(
            "After reads: empty=%0b full=%0b count=%0d",
            empty,
            full,
            count_dbg
        );

        if (!empty) begin
            $error("TEST FAILURE: FIFO should be EMPTY");
            $finish;
        end

        if (full) begin
            $error("TEST FAILURE: FIFO should NOT be FULL");
            $finish;
        end

        if (count_dbg != 0) begin
            $error("TEST FAILURE: FIFO count should be 0");
            $finish;
        end

        // --------------------------------------------------------
        // TEST 5: WRITE AFTER EMPTY
        // --------------------------------------------------------
        $display("");
        $display("[TEST 5] WRITE AFTER EMPTY");

        fifo_write(8'h55);

        if (count_dbg != 1) begin
            $error("TEST FAILURE: FIFO count should be 1");
            $finish;
        end

        // --------------------------------------------------------
        // TEST 6: READ AFTER WRITE
        // --------------------------------------------------------
        $display("");
        $display("[TEST 6] READ AFTER WRITE");

        fifo_read(read_value);

        if (read_value !== 8'h55) begin
            $error(
                "TEST FAILURE: Expected 0x55, got 0x%02h",
                read_value
            );
            $finish;
        end

        // --------------------------------------------------------
        // TEST 7: WRITE WHILE FULL
        // --------------------------------------------------------
        $display("");
        $display("[TEST 7] WRITE WHILE FULL");

        // Fill FIFO
        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_write(8'h10 + i);
        end

        @(posedge clk);
        #1;

        if (!full) begin
            $error("TEST FAILURE: FIFO should be FULL");
            $finish;
        end

        if (count_dbg != DEPTH) begin
            $error("TEST FAILURE: FIFO count should equal DEPTH");
            $finish;
        end

        // Attempt illegal write while full.
        @(negedge clk);

        wr_data = 8'hEE;
        wr_en   = 1'b1;
        rd_en   = 1'b0;

        @(posedge clk);
        #1;

        wr_en   = 1'b0;
        wr_data = '0;

        $display(
            "After WRITE while FULL: count=%0d",
            count_dbg
        );

        if (count_dbg != DEPTH) begin
            $error(
                "TEST FAILURE: Illegal WRITE changed FULL FIFO count"
            );
            $finish;
        end

        // --------------------------------------------------------
        // TEST 8: READ WHILE FULL
        // --------------------------------------------------------
        $display("");
        $display("[TEST 8] READ WHILE FULL");

        fifo_read(read_value);

        if (count_dbg != DEPTH-1) begin
            $error(
                "TEST FAILURE: Expected count=%0d after READ",
                DEPTH-1
            );
            $finish;
        end

        // --------------------------------------------------------
        // TEST 9: SIMULTANEOUS READ + WRITE
        // --------------------------------------------------------
        $display("");
        $display("[TEST 9] SIMULTANEOUS READ + WRITE");

        @(negedge clk);

        wr_data = 8'hCC;
        wr_en   = 1'b1;
        rd_en   = 1'b1;

        @(posedge clk);
        #1;

        $display(
            "SIMULTANEOUS RD+WR: rd_data=0x%02h count=%0d",
            rd_data,
            count_dbg
        );

        @(negedge clk);

        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = '0;

        // Read and write together should keep occupancy unchanged.
        if (count_dbg != DEPTH-1) begin
            $error(
                "TEST FAILURE: Simultaneous RD+WR changed FIFO occupancy"
            );
            $finish;
        end

        // --------------------------------------------------------
        // TEST 10: DRAIN FIFO
        // --------------------------------------------------------
        $display("");
        $display("[TEST 10] DRAIN FIFO");

        while (!empty) begin
            fifo_read(read_value);
        end

        @(posedge clk);
        #1;

        if (!empty) begin
            $error("TEST FAILURE: FIFO did not reach EMPTY");
            $finish;
        end

        if (full) begin
            $error("TEST FAILURE: FIFO should NOT be FULL");
            $finish;
        end

        if (count_dbg != 0) begin
            $error("TEST FAILURE: FIFO count should be 0");
            $finish;
        end

        // --------------------------------------------------------
        // TEST 11: READ WHILE EMPTY
        // --------------------------------------------------------
        $display("");
        $display("[TEST 11] READ WHILE EMPTY");

        @(negedge clk);

        rd_en = 1'b1;
        wr_en = 1'b0;

        @(posedge clk);
        #1;

        rd_en = 1'b0;

        @(posedge clk);
        #1;

        $display(
            "After READ while EMPTY: empty=%0b full=%0b count=%0d",
            empty,
            full,
            count_dbg
        );

        if (!empty) begin
            $error("TEST FAILURE: Illegal READ changed EMPTY state");
            $finish;
        end

        if (full) begin
            $error("TEST FAILURE: FIFO should NOT be FULL");
            $finish;
        end

        if (count_dbg != 0) begin
            $error("TEST FAILURE: Illegal READ changed FIFO count");
            $finish;
        end

        // --------------------------------------------------------
        // COMPLETE
        // --------------------------------------------------------
        $display("");
        $display("======================================================");
        $display("           ALL FIFO TESTS COMPLETED");
        $display("======================================================");
        $display("");

        $finish;

    end

endmodule