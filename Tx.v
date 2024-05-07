//Uart transmitter
module uart_tx (
    input wire clk,
    input wire rst,
    input wire baud_tick, // signal on which transactions occur
    input wire [7:0] ext_data_in, // external 8-bit data input of Tx 
    input wire en, // transmit enable  signal
    output reg tx); //Tx signal output
// internal wire declarations
    reg [3:0] count_16; //counter for oversampling
    reg count_16_indication; // OS achieved indication
    reg [2:0] count_8; // counter to count data bits.
    reg count_8_indication; // bit count achieved
    reg [7:0] data_save; // temporary reg to store the external data to send
// FSM Parameters
    localparam IDLE = 0;
    localparam START = 1;
    localparam DATA = 2;
    localparam STOP = 3;
// state registers
    reg [1:0] current_state, next_state;
//OS counter tracker 
    always @(posedge clk) begin
        if (rst) begin
            count_16 <= 0; 
            count_16_indication <= 0;
        end
        else begin
            if (baud_tick == 1) begin // on ever baud_tick (baud_clk)
                if (current_state != IDLE) begin // except IDLE state
                    if (count_16 == 15) begin // OS counter start
                        count_16 <= 0;
                        count_16_indication <= 1; // high indication when it reaches value 15, and reseted
                    end
                    else begin
                        count_16 <= count_16 + 1; // OS counter increment 
                        count_16_indication <= 0; // indication is low
                    end
                end
                else begin // default OS counter tracker state
                    count_16 <= 0;
                    count_16_indication <= 0;
                end
            end
            else begin // to maintain its previous value
                count_16 <= count_16;
                count_16_indication <= 0;
            end
        end
    end
// count tracker for data bits
    always @(posedge clk) begin
        if (rst) begin
            count_8 <= 0;
            count_8_indication <= 0;
            data_save <= 0;
        end
        else begin // on dara state
            if (current_state == DATA) begin
                if ((baud_tick == 1) && (count_16 == 15)) begin // baud clk and OS achieved
                    if (count_8 == 7) begin // start the counter 
                        count_8 <= 0; 
                        count_8_indication <= 1; // indication high when condition satisfied, and counter restart
                        data_save <= data_save; // maintain value
                    end
                    else begin
                        count_8 <= count_8 + 1; // data counter increment
                        count_8_indication <= 0; // low indication
                        data_save <= {data_save[6:0],1'b0}; // data serialization
                    end
                end
                else begin  // maintain its previous values
                    count_8 <= count_8;
                    count_8_indication <= 0;
                    data_save <= data_save; 
                end
            end
            else begin // default  states
                count_8 <= 0;
                count_8_indication <= 0;
                data_save <= ext_data_in; // external data register is assigned to tempo reg data save
            end
        end
    end
 // MAIN FSM STATE ASSIGNED TO NEXT STATE
    always @(posedge clk) begin
        if (rst) begin
            current_state <= 0;
        end
        else begin
            current_state <= next_state;
        end
    end
// MAIN FINITE STATE MACHINE
    always @(*) begin
        if (rst) begin
            next_state = 0; // next state varible is initialized
        end
        else begin
            case (current_state) // on the basis of current state 
                IDLE: begin // 00
                    tx = 1; // idealy high signal of UART
                    if (en == 1) begin
                        next_state = START; // state changes as enable signal is high
                    end
                end
                START: begin // 01
                    tx = 0; //  signal becomes low, indicating start condition for UART 
                    if (count_16_indication == 1) begin // OS  achieved
                        next_state = DATA; // move to data state
                    end
                end
                DATA: begin //02
                    tx = data_save[7]; // index 7 bit is at Tx line 
                    if (count_8_indication == 1) begin // and data bits counter fulfil its function 
                        next_state = STOP; // move to stop state
                    end
                end
                STOP: begin // 03
                    tx = 1; // high tx line is the indication of stop state
                    if (count_16_indication == 1) begin // OS of stop bit achieved
                        next_state = IDLE;
                    end
                end
                default: next_state = IDLE; // by default IDLE
            endcase // cases over
        end
    end

endmodule

