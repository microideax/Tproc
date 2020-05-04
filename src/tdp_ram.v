// Dual-port block ram with two write ports

module tdp_ram#(
parameter RAM_DEPTH = 32,
parameter ADDR_WIDTH = $clog2(RAM_DEPTH),
parameter DATA_WIDTH = 64
)(
input clka, 
input clkb,
input ena, 
input enb, 
input wea, 
input web,
input [ADDR_WIDTH-1 : 0] addra,
input [ADDR_WIDTH-1 : 0] addrb,
input [DATA_WIDTH-1 : 0] dia,
input [DATA_WIDTH-1 : 0] dib,
output [DATA_WIDTH-1: 0] doa,
output [DATA_WIDTH-1: 0] dob);

always @ (posedge clka) begin
	if(ena) begin
		if(wea) 
			ram[addra] <= dia;
			doa <= ram[addra];
	end
end

always @ (posedge clkb) begin
	if(enb) begin
		if(web) 
			ram[addrb] <= dib;
			dob <= ram[addrb];
	end
end

endmodule

