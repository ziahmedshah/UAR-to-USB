// uart reciever 
module uart_rx(
    input clk, 
    input rst,
    input baud_tick, // baudclk
    input rx,  // Rx line
    output reg [7:0] ext_data_out); // 8 bit data thrown out parallaly after recieving it serially
// internal signal decalaration
    reg [3:0] count_16; // OS counter  tracker
    reg count_16_indication; // OS indication
    reg [2:0] count_8; // counter to count data bits
    reg count_8_indication;  // data bits counted
    reg [7:0] data_save; // temporary register to store the parallel data
    reg [1:0] current_state, next_state; // state registers
// FSM Parameters
    localparam IDLE  = 0;
    localparam START = 1;
    localparam DATA  = 2;
    localparam STOP  = 3;
//body
// oversampling tracker of states
    always @(posedge clk) begin
        if (rst) begin
            count_16 <= 0;
            count_16_indication <= 0;
        end
        else begin
            if (baud_tick == 1) begin  // at baud  clk
                if (current_state == START) begin // at start state 
                    if (count_16 == 7) begin // pick data at the middle of the OS
                        count_16 <= 0;
                        count_16_indication <= 1; // high signal 
                    end
                    else begin 
                        count_16 <= count_16 + 1;
                        count_16_indication <= 0;
                    end
                end
                else if ((current_state == DATA) || (current_state == STOP)) begin // data orn stop state
                    if (count_16 == 15) begin // OS 
                        count_16 <= 0;
                        count_16_indication <= 1;
                    end
                    else begin
                        count_16 <= count_16 + 1;
                        count_16_indication <= 0;
                    end
                end
                else begin // initilization
                    count_16 <= 0;
                    count_16_indication <= 0;
                end
            end
            else begin // previousn value retention
                count_16 <= count_16;
                count_16_indication <= 0;
            end
        end
    end // end oversampling tracker of states
// count tracker of data
    always @(posedge clk) begin
        if (rst) begin
            count_8 <= 0;
            count_8_indication <= 0;
            data_save <= 0;
        end
        else begin
            if (current_state == DATA) begin // in data state only 
                if ((baud_tick == 1) && (count_16 == 15)) begin  // OS and clk both high
                    if (count_8 == 7) begin // count data bits
                        count_8 <= 0;
                        count_8_indication <= 1;
                        data_save <= {data_save[6:0],rx}; // deserialization of data
                    end
                    else begin
                        count_8 <= count_8 + 1;
                        count_8_indication <= 0;
                        data_save <= {data_save[6:0],rx}; // deserialization of data
                    end
                end
                else begin // value retention
                    count_8 <= count_8;
                    count_8_indication <= 0;
                    data_save <= data_save; 
                end
            end
            else begin // initialization
                count_8 <= 0;
                count_8_indication <= 0;
                data_save <= data_save;
            end
        end
    end // end count tracker data
//temp reg value to original reg
    always @(posedge clk) begin
        if (rst) begin
            ext_data_out <= 0;
        end
        else begin
            ext_data_out <= data_save;
        end
    end // end temp value reg assignment
// state changing
    always @(posedge clk) begin
        if (rst) begin
            current_state <= 0;
        end
        else begin
            current_state <= next_state;
        end
    end // end state changing
// MAIN FSM OF RECIEVER
    always @(*) begin
        if (rst) begin
            next_state = 0;
        end
        else begin
            case (current_state)
                IDLE: begin
                    if (rx == 0) begin // detect start state at RX line low
                        next_state = START;
                    end
                end
                START: begin  // at RX low & OS_tick high 
                    if ((count_16_indication == 1) && (rx == 0)) begin
                        next_state = DATA; // move to data state
                    end
                end
                DATA: begin // at data counter tracker indication
                    if (count_8_indication == 1) begin
                        next_state = STOP;
                    end
                end
                STOP: begin
                    if ((count_16_indication == 1) && (rx == 1)) begin
                        next_state = IDLE;
                    end
                end
                default: next_state = IDLE;
            endcase
        end
    end // end main fsm rcvr
endmodule
