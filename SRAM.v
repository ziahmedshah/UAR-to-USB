`timescale 1ns/1ns
module SRAM( 
	input wire clk,   
	input wire [7:0] data_in, // data of rcvr, by deserilizer
	input wire we, // write enable signal
	input wire re,
	input wire [2:0] sram_addr, // 3 bit address
	output reg [7:0] data_out // data to be transmitted
	);
// Memory...
	reg [7:0] ram [0:7]; 
// Main Body...
	always@(posedge clk)
	begin
		if (we) //@wr data is strored in ram at specific loc
		ram[sram_addr] <= data_in;
		else if (re)
		data_out  <= ram[sram_addr];
	end
endmodule
