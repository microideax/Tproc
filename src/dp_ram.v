// Simple dual-port block ram with read after write


module dp_ram#(
    parameter RAM_DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH),
    parameter DATA_WIDTH = 64
)(
input clk, 
input ena, 
input enb, 
input wea, 
input [ADDR_WIDTH-1 : 0] addra, 
input [ADDR_WIDTH-1 : 0] addrb, 
input [DATA_WIDTH-1 : 0] dia, 
output [DATA_WIDTH-1:0] dob
);

reg [DATA_WIDTH-1 : 0] ram [RAM_DEPTH:0];
reg [DATA_WIDTH-1 : 0] doa, dob;

always@(posedge clk) begin
    if(ena) begin
        if(wea) 
            ram[addra] <= dia;
    end
end

always@(posedge clk) begin
    if(enb)
        dob <= ram[addrb];
end        



endmodule