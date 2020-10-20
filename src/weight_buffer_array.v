// Organize dual-port BRAMs into a ram array for weight storage

`include "network_para.vh"



module weight_buffer_array #(
    parameter RAM_DEPTH = `Tm,
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH),
    parameter DATA_WIDTH = 64,
    parameter ADDR_EXT = $clog2(`Tn)+1
) (
input clk, 
input ena, 
input enb, 
input wea, 
input wire [(ADDR_EXT+ADDR_WIDTH)-1 : 0] addra, 
input wire [ADDR_WIDTH-1 : 0] addrb, 
input wire [DATA_WIDTH-1 : 0] dia, 
output wire [`Tn*DATA_WIDTH-1:0] weight_buffer_out
);

// Buffer number = Tn
// Each buffer has Tm number of kernels
// Each kernel has KERNEL_SIZE*KERNEL_SIZE data
// Each data is 2 bits

wire [`Tn*DATA_WIDTH-1:0] weight_out;
wire [`Tn-1:0] ram_select;

assign ram_select = `Tn'b0000_0001 << addra[ADDR_WIDTH+1:ADDR_WIDTH];

genvar i;
generate
    for (i = 0; i < `Tn; i = i+1) begin
        dp_ram #(16, 4, 64) w_buffer(
            .clk(clk),
            .ena(ram_select[i]),
            .enb(enb),
            .wea(ram_select[i]),
            .addra(addra[ADDR_WIDTH -1 : 0]),
            .addrb(addrb),
            .dia(dia),
            .dob(weight_out[(i+1)*DATA_WIDTH -1: i*DATA_WIDTH])
            );
    end
endgenerate

assign weight_buffer_out = weight_out;

endmodule 