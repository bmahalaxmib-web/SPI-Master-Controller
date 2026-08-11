`timescale 1ns/1ps

module spi_master_tb;

    reg clk;
    reg rst;

    reg       start;
    reg [7:0] tx_data;

    wire [7:0] rx_data;
    wire       busy;
    wire       done;

    wire sclk;
    wire mosi;
    reg  miso;
    wire cs;

    reg [7:0] slave_data;
    reg [7:0] slave_shift;
    reg [3:0] slave_bit_count;

    // DUT
    spi_master #(
        .CLK_DIV(4)
    ) dut (
        .clk(clk),
        .rst(rst),

        .start(start),
        .tx_data(tx_data),

        .rx_data(rx_data),
        .busy(busy),
        .done(done),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    // 50 MHz clock
    always #10 clk = ~clk;


    // ------------------------------------------------
    // SPI Slave Model
    // SPI Mode 0
    // ------------------------------------------------

    // Slave changes MISO on falling edge
    always @(negedge sclk) begin

        if (!cs) begin

            if (slave_bit_count < 8) begin
                miso <= slave_shift[7];

                slave_shift <= {
                    slave_shift[6:0],
                    1'b0
                };

                slave_bit_count <= slave_bit_count + 1'b1;
            end

        end
    end


    initial begin

        $dumpfile("spi_master.vcd");
        $dumpvars(0, spi_master_tb);

        clk = 1'b0;
        rst = 1'b1;

        start   = 1'b0;
        tx_data = 8'h00;

        miso = 1'b0;

        slave_data = 8'h3C;
        slave_shift = 8'h00;
        slave_bit_count = 4'd0;

        #100;

        rst = 1'b0;

        #100;

        $display("----------------------------------------");
        $display("       SPI MASTER CONTROLLER TEST");
        $display("----------------------------------------");
        $display("SPI Mode : 0");
        $display("Data     : 8-bit");
        $display("Order    : MSB First");
        $display("----------------------------------------");


        // Load slave response
        slave_shift = slave_data;
        slave_bit_count = 4'd0;

        // Master transmission data
        tx_data = 8'hA5;

        @(posedge clk);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;


        // Wait for completion
        wait(done);

        #20;

        $display("TX DATA  = 0x%02h", tx_data);
        $display("RX DATA  = 0x%02h", rx_data);


        if (rx_data == slave_data) begin
            $display("RESULT   = PASS");
        end
        else begin
            $display("RESULT   = FAIL");
        end


        $display("----------------------------------------");
        $display("       SIMULATION COMPLETE");
        $display("----------------------------------------");

        #100;

        $finish;

    end

endmodule