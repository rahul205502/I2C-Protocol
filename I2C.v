module I2C_1 (
    input  wire        CLK,
    input  wire        RST,
    input  wire [7:0]  data_in,
    input  wire [6:0]  addr_in, 
    inout  wire        SDA,
    output reg         SCL
);

reg i2c_sda;
reg i2c_sda_en;      // 0 = drive SDA, 1 = release (Z)
assign SDA = i2c_sda_en ? 1'bz : i2c_sda;

// State + counters
reg [7:0] state;
reg [3:0] count;
reg [7:0] tx_data;

localparam IDLE      = 0;
localparam START     = 1;
localparam ADDR      = 2;
localparam ACK_WAIT1 = 3;
localparam DATA      = 4;
localparam ACK_WAIT2 = 5;
localparam STOP      = 6;

// Clock division for SCL
localparam SCL_DIV_COUNT = 250;
reg [8:0] scl_count;

always @(posedge CLK) begin
    if (RST) begin
        scl_count <= 0;
        SCL <= 1;
    end else begin
        if (state != IDLE) begin
            if (scl_count < SCL_DIV_COUNT - 1)
                scl_count <= scl_count + 1;
            else begin
                SCL <= ~SCL;
                scl_count <= 0;
            end
        end else begin
            SCL <= 1;
            scl_count <= 0;
        end
    end
end

always @(posedge CLK) begin
    if (RST) begin
        state       <= IDLE;
        i2c_sda     <= 1;
        i2c_sda_en  <= 1;
        count       <= 0;
        tx_data     <= 0;
    end else begin
        
        if (scl_count == 0) begin
            case(state)

            IDLE: begin
                i2c_sda_en <= 0;
                i2c_sda    <= 1;
                if (SCL == 1) state <= START;
            end

            START: begin
                if (SCL == 1) begin
                    i2c_sda    <= 0;
                    i2c_sda_en <= 0;
                    tx_data    <= {addr_in, 1'b0};
                    count      <= 7;
                    state      <= ADDR;
                end
            end

            ADDR: begin
                i2c_sda_en <= 0; // Drive
                if (SCL == 0) begin
                    i2c_sda    <= tx_data[count];
                end else begin
                    if (count == 0) begin
                        state <= ACK_WAIT1;
                        count <= 7;
                    end
                    else count <= count - 1;
                end
            end

            ACK_WAIT1: begin
                if (SCL == 0) begin
                    i2c_sda_en <= 1;        
                end 
                else begin
                    tx_data <= data_in;
                    count   <= 7;
                    state   <= DATA;
                end
            end

            DATA: begin
                i2c_sda_en <= 0; // Drive
                if (SCL == 0) begin
                    i2c_sda   <= tx_data[count];
                end else begin
                    if (count == 0) begin
                        state <= ACK_WAIT2;
                        count <= 7;
                    end
                    else count <= count - 1;
                end
            end

            ACK_WAIT2: begin
                if (SCL == 0) begin
                    i2c_sda_en <= 1;              
                end else begin
                    state <= STOP;
                end
            end

            STOP: begin
                if (SCL == 0) begin
                    i2c_sda_en <= 0;
                    i2c_sda    <= 0;
                end else begin
                    i2c_sda    <= 1;
                    i2c_sda_en <= 0;
                    state      <= IDLE;
                end
            end

            default: state <= IDLE;

            endcase
        end
    end
end

endmodule