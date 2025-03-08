`timescale 1ns / 1ps

module uart_tx (
    input wire clk,        // System clock
    input wire reset,      // Reset signal
    input wire tx_start,   // Start signal (스위치로 사용)
    input wire [7:0] tx_data, // Data to transmit
    output wire [7:0] LED,   // Data indicator LED
    output wire reset_LED,  // Reset indicator LED
    output wire tx_start_LED,   // Start check LED
    output reg tx,         // USART TX line
    output reg tx_ready    // Transmission complete signal
);

    parameter TX_COUNT = 1; // 전송할 데이터 개수 설정
    
    // Baud rate settings
    parameter BAUD_RATE = 9600;
    parameter CLOCK_FREQ = 100_000_000;
    localparam BIT_PERIOD = CLOCK_FREQ / BAUD_RATE;
    
    // FSM States
    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;
    
    reg [1:0] current_state, next_state;
    reg tx_active; // 전송 중인지 확인하는 플래그
    
    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg [7:0] shift_reg; // Stop Bit 제거, 8비트 데이터만 저장
    reg [3:0] tx_sent_count; // 전송된 데이터 개수 카운트
    
    // Assign input indicators
    assign LED = tx_data;
    assign reset_LED = reset;
    assign tx_start_LED = tx_start;
    
    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            shift_reg <= 8'b0;
            tx <= 1'b1;       
            tx_ready <= 1'b1;
            tx_active <= 1'b0;
            tx_sent_count <= 0;
            
        end else begin
            current_state <= next_state;
            case (current_state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    tx <= 1'b1;
                    tx_ready <= 1'b1;
                    if (tx_start && !tx_active && tx_sent_count < TX_COUNT) begin
                        shift_reg <= tx_data;   // Load data directly
                        tx_active <= 1'b1;
                        tx_sent_count <= 0;
                    end
                end
                START: begin
                    tx <= 1'b0;                // Start bit
                    tx_ready <= 1'b0;
                    if (clk_count == BIT_PERIOD - 1) begin
                        clk_count <= 0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                DATA: begin
                    tx <= shift_reg[0];        // Send LSB first
                    if (clk_count == BIT_PERIOD - 1) begin
                        clk_count <= 0;
                        bit_index <= bit_index + 1;
                        shift_reg <= shift_reg >> 1; // Shift right after sending
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                STOP: begin
                    tx <= 1'b1;                // Stop bit
//                    tx_active <= 1'b0;
//                    tx_sent_count <= tx_sent_count + 1;
                    if (clk_count == BIT_PERIOD - 1) begin
                        clk_count <= 0;
                        tx_sent_count <= tx_sent_count + 1;
                        tx_active <= 1'b0;
//                        if (tx_sent_count == TX_COUNT) begin
//                            tx_active <= 1'b0;
//                        end
                        end else begin
                            clk_count <= clk_count + 1;
                        end
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (tx_start && !tx_active && tx_sent_count < TX_COUNT)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            START: begin
                if (clk_count == BIT_PERIOD - 1)
                    next_state = DATA;
                else
                    next_state = START;
            end
            DATA: begin
                if (bit_index == 7 && clk_count == BIT_PERIOD - 1)
                    next_state = STOP;
                else
                    next_state = DATA;
            end
            
            STOP: begin
                if (clk_count == BIT_PERIOD - 1)
//                    next_state = (tx_sent_count + 1 < TX_COUNT) ? START : IDLE;
                      next_state = IDLE;
                else
                    next_state = STOP;
            end
            default: next_state = IDLE;
        endcase
    end
    
    endmodule