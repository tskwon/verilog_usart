`timescale 1ns / 1ps

module usart_rx(
        input wire clk,
        input wire reset,
        input wire rx,
        output reg [7:0] rx_data,
        output reg rx_done
    );
    
    // Baud rate and clock parameters
    parameter BAUD_RATE = 9600;
    parameter CLOCK_FREQ = 100_000_000; 
    parameter BIT_PERIOD = CLOCK_FREQ / BAUD_RATE;
    parameter HALF_BIT_PERIOD = BIT_PERIOD / 2; 
    
    // State Machine
    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;
    
    reg [1:0] current_state, next_state; 
    
    reg [3:0] bit_index;
    reg [15:0] bit_timer;
    reg [7:0] shift_reg;
    
    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (rx == 1'b0) // Start bit detected
                    next_state = START;
                else
                    next_state = IDLE;
            end
            START: begin
                if (bit_timer >= HALF_BIT_PERIOD - 1) // **move to DATA state from HALF_BIT_PERIOD **
                    next_state = DATA;
                else
                    next_state = START;
            end
            DATA: begin
                if (bit_index == 8)
                    next_state = STOP;
                else
                    next_state = DATA;
            end
            STOP: begin
                if (bit_timer >= BIT_PERIOD - 1)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Output and shift register logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_index <= 0;
            bit_timer <= 0;
            shift_reg <= 0;
            rx_done <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    bit_index <= 0;
                    bit_timer <= 0;
                    rx_done <= 0;
                end
                START: begin
                    if (bit_timer < HALF_BIT_PERIOD - 1) // **wait an sampling from HALF_BIT_PERIOD**
                        bit_timer <= bit_timer + 1;
                    else
                        bit_timer <= 0; // Reset timer for DATA state
                end
                DATA: begin
                    if (bit_timer >= BIT_PERIOD - 1) begin
                        shift_reg[bit_index] <= rx; // **1bit receive**
                        bit_index <= bit_index + 1;
                        bit_timer <= 0;
                    end else begin
                        bit_timer <= bit_timer + 1;
                    end
                end
                STOP: begin
                    if (bit_timer >= BIT_PERIOD - 1) begin
                        rx_data <= shift_reg;
                        rx_done <= 1;
                        bit_timer <= 0;
                    end else begin
                        bit_timer <= bit_timer + 1;
                    end
                end
            endcase
        end
    end

endmodule
