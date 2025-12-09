`timescale 1ns / 1ps

module I2C_tb;

reg       CLK;
reg       RST; 
reg [7:0] data_in;
reg [6:0] addr_in;

wire SDA;
wire SCL;

reg slave_ack_drive;

// 1. Model Pull-up Resistor for SDA
// This primitive ensures SDA defaults to '1' (high) when released.
pullup (SDA); 

assign SDA = (slave_ack_drive == 1'b0) ? 1'b0 : 1'bz;

always @ (posedge CLK) begin
    if (RST) begin
        slave_ack_drive <= 1'b1; 
    end
    else begin
        if (dut.state == 3 || dut.state == 5) begin // ACK_WAIT1 or ACK_WAIT2
             if (SCL == 0) begin
                 slave_ack_drive <= 1'b0;
             end else begin
                 slave_ack_drive <= 1'b1;
             end
        end
        else begin
            slave_ack_drive <= 1'b1;
        end
    end
end


// 3. Instantiate the Device Under Test (DUT)
I2C_1 dut (
    .CLK     (CLK),
    .RST     (RST),
    .data_in (data_in),
    .addr_in (addr_in),
    .SDA     (SDA),
    .SCL     (SCL)
);

// 4. Clock Generator (20 ns period for 50 MHz CLK)
always #10 CLK = ~CLK;

initial begin
    CLK = 0;
    RST = 1;

    data_in = 8'hAA;
    addr_in = 7'h50; 
    
    $display("====== Simulation starts at %0t ns ======", $time);
    $display("Target Write: Addr=7'h%2h, Data=8'h%2h", addr_in, data_in);
    
    #100;
    RST = 0;

    #192000;
    
    $display("====== Simulation ends at %0t ns ======", $time);
    $finish;
end
    
initial
$monitor("Time=%0t ns | State=%0d | SCL=%0b | SDA=%0b | Master_SDA_En=%0b | Slave_ACK_Drive=%0b", 
          $time, dut.state, SCL, SDA, dut.i2c_sda_en, slave_ack_drive);

endmodule