//usb to uart test bench
`timescale 1ns/1ns
module USBtoUART_TB();
//ports...
reg clk, rst;
reg [2:0] sram_address;
reg [7:0] data_in_sram;
wire [7:0] data_out_sram;
reg we; reg re; // UART  w,r enabling signals
//SRAM instantiation...
SRAM     sram_uut( .clk(clk), .data_in(data_in_sram), .we(we), .re(re), .sram_addr(sram_address), .data_out(data_out_sram));
//ports...
reg rx;
wire Tx;
reg [1:0] address; // it is basically selectline
//UART instantiation...
uart_top_design     uart_uut( .clk(clk), .rst(rst), .address(address), .write_data(data_out_sram), .read_data(), 
			      .we(we), .re(re), .tx(Tx), .rx(Tx));
//clk generation...
initial clk = 0;
    always #25 clk = ~clk;
initial begin
        #10 rst = 1;
        #100 rst = 0;   
//--------------------------|
        #100 address = 0; // select line
	#100 sram_address = 8'b0000_0000;
        #100 data_in_sram = 130;
        #100 we = 1;
       // #100 we = 0;
//--------------------------|
        #100 address = 1; // select line
	#100 sram_address = 8'b0000_0001;
        #100 data_in_sram = 8'b1000_0000; //write data zeroth index
        #100 we = 1;
//--------------------------|
        #100 address = 2; // select line
	#100 sram_address = 8'b0000_0010; 
        #100 data_in_sram = 8'b0110_1001; // actual data to be transmitted
//--------------------------| 
// enable signal for data transmission
        #100 address = 1; // select line
	#100 sram_address = 8'b0000_0110;
        #100 data_in_sram = 8'b1000_0000; //write data enable zeroth index
        #100 we = 1;
//--------------------------|
        #100 address = 3; // select line
	#100 sram_address = 8'b0000_0001;
        #100 data_in_sram = 8'b1011_0100; 
        #100 we = 1;
//--------------------------|
        #104750 rx = 0;
        #104750 rx = 0;
        #104750 rx = 1;
        #104750 rx = 0;
        #104750 rx = 0;
        #104750 rx = 0;
        #104750 rx = 0;
        #104750 rx = 1;
//--------------------------|
        #200000 re = 1;
//stop simulation...
        #500000 $finish;
    end
endmodule
