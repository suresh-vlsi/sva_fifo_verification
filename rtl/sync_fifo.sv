`timescale 1ns/1ps

module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  full,
    output logic                  empty,

    // Verification/debug visibility
    output logic [$clog2(DEPTH+1)-1:0] count_dbg
);

    // ------------------------------------------------------------
    // Local parameters
    // ------------------------------------------------------------

    localparam int PTR_WIDTH   = $clog2(DEPTH);
    localparam int COUNT_WIDTH = $clog2(DEPTH + 1);

    // Properly sized constant for DEPTH comparison
    localparam [COUNT_WIDTH-1:0] DEPTH_COUNT = COUNT_WIDTH'(DEPTH);

    // ------------------------------------------------------------
    // FIFO storage
    // ------------------------------------------------------------

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer
    logic [PTR_WIDTH-1:0] wr_ptr;

    // Read pointer
    logic [PTR_WIDTH-1:0] rd_ptr;

    // Number of occupied locations
    logic [COUNT_WIDTH-1:0] count;
    assign count_dbg = count;

    // ------------------------------------------------------------
    // Status flags
    // ------------------------------------------------------------

   assign full  = (count == COUNT_WIDTH'(DEPTH));
   assign empty = (count == '0);

    // ------------------------------------------------------------
    // FIFO sequential logic
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;

        end
        else begin

            // ----------------------------------------------------
            // Write operation
            // ----------------------------------------------------

            if (wr_en && !full) begin

                mem[wr_ptr] <= wr_data;
                wr_ptr      <= wr_ptr + 1'b1;

            end

            // ----------------------------------------------------
            // Read operation
            // ----------------------------------------------------

            if (rd_en && !empty) begin

                rd_data <= mem[rd_ptr];
                rd_ptr  <= rd_ptr + 1'b1;

            end

            // ----------------------------------------------------
            // FIFO occupancy update
            // ----------------------------------------------------

            case ({wr_en && !full, rd_en && !empty})

                2'b10: begin
                    // Write only
                    count <= count + 1'b1;
                end

                2'b01: begin
                    // Read only
                    count <= count - 1'b1;
                end

                2'b11: begin
                    // Simultaneous valid read and write
                    count <= count;
                end

                2'b00: begin
                    // No valid operation
                    count <= count;
                end

            endcase

        end

    end

endmodule