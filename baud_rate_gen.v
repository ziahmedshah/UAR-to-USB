// Baud Rate Generator
module uart_baud_rate (
    input wire clk, // system clock
    input wire rst,
    input wire [7:0] baud_division, // divisor value
    input wire en, //baud enable signal
    output reg baud_tick); // baudclk
/*  Clock Frequency: f  = 20 MHz
    Baud Rate:       Bd = 9600 bit/s
    Baud Division = ____f____
                     16 x Bd
*/
// Intrnal wires declaration
    reg temp_en, delayed_en; // temporary enable signal and  a register to add some delay
    reg [7:0] baud_count; // counter 
// body 
// enable signal 
    always @(posedge clk) begin
        if (rst) begin
            temp_en <= 0; // enable reg initialized
            delayed_en <= 0; // delayed enable reg initialized
        end
        else begin
            if ((en == 0) || (en == 1)) begin // at every possiblity 
                temp_en <= en; // en sx is assigned to temp_en register 
                delayed_en <= temp_en; // and temp-en is assigned to delayed register for delay
            end
            else begin // to hold previous states
                temp_en <= temp_en; 
                delayed_en <= delayed_en;
            end
        end
    end
// body
//baudclk generation 
    always @(posedge clk) begin
        if (rst) begin // initialization
            baud_count <= 0;
            baud_tick <= 0;
        end
        else begin // at rst = 0
            if (baud_division != 0) begin // at some baud division value
                if ((en == 1) && (delayed_en == 0)) begin // if en high and delayed en low 
                    baud_count <= 1; // baud clk high
                    baud_tick <= baud_tick; // retain previous value
                end
                else if (baud_count == baud_division) begin // counter reaches division value
                    baud_count <= 0; // initialize counter 
                    baud_tick <= 1; // baud clk high
                end
                else begin
                    baud_count <= baud_count + 1; // counter increment
                    baud_tick <= 0; // baud tick is zero, it is only high when counter reaches the division value
                end
            end
            else begin // baud division has value zero, then initialize counter and tick
                baud_count <= 0;
                baud_tick <= 0;
            end
        end
    end
endmodule
