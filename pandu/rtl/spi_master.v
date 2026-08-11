`timescale 1ns/1ps

module spi_master #(
    parameter CLK_DIV = 4
)(
    input        clk,
    input        rst,

    input        start,
    input  [7:0] tx_data,

    output reg [7:0] rx_data,
    output reg       busy,
    output reg       done,

    // SPI interface
    output reg       sclk,
    output reg       mosi,
    input            miso,
    output reg       cs
);

    reg [7:0] tx_shift;
    reg [7:0] rx_shift;

    reg [3:0] bit_count;
    reg [15:0] clk_count;

    always @(posedge clk) begin

        if (rst) begin
            tx_shift <= 8'd0;
            rx_shift <= 8'd0;

            rx_data <= 8'd0;

            bit_count <= 4'd0;
            clk_count <= 16'd0;

            busy <= 1'b0;
            done <= 1'b0;

            sclk <= 1'b0;
            mosi <= 1'b0;
            cs   <= 1'b1;
        end

        else begin

            done <= 1'b0;

            // Start SPI transfer
            if (start && !busy) begin

                busy <= 1'b1;
                cs   <= 1'b0;

                tx_shift <= tx_data;
                rx_shift <= 8'd0;

                bit_count <= 4'd0;
                clk_count <= 16'd0;

                sclk <= 1'b0;

                // MSB first
                mosi <= tx_data[7];
            end

            else if (busy) begin

                if (clk_count == CLK_DIV - 1) begin

                    clk_count <= 16'd0;

                    // SPI Mode 0
                    if (sclk == 1'b0) begin

                        // Rising edge:
                        // Slave data is sampled here
                        sclk <= 1'b1;

                        rx_shift <= {rx_shift[6:0], miso};

                    end

                    else begin

                        // Falling edge:
                        // Change MOSI here
                        sclk <= 1'b0;

                        if (bit_count == 4'd7) begin

                            // Transfer complete
                            busy <= 1'b0;
                            done <= 1'b1;
                            cs   <= 1'b1;

                            rx_data <= rx_shift;

                        end

                        else begin

                            bit_count <= bit_count + 1'b1;

                            tx_shift <= {tx_shift[6:0], 1'b0};

                            mosi <= tx_shift[6];
                        end
                    end
                end

                else begin
                    clk_count <= clk_count + 1'b1;
                end
            end
        end
    end

endmodule