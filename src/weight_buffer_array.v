// Organize dual-port BRAMs into a ram array for weight storage

`include "network_para.vh"



module weight_buffer_array #(
    parameter RAM_DEPTH = `Tm,
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH),
    parameter DATA_WIDTH = 64, // effective weight = Kernel_size*Kernel_size*2-bit < 5*5*2
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

// assign ram_select = {7'b000_0000,1} << (addra[ADDR_WIDTH+1:ADDR_WIDTH] + 1);
// assign ram_select[addra[ADDR_WIDTH+1:ADDR_WIDTH]] = 1'b1 & wea;

sel_decoder ram_sel(
    .sel(addra[ADDR_WIDTH+1: ADDR_WIDTH]),
    .res(ram_select)
);

genvar i;
generate
    for (i = 0; i < `Tn; i = i+1) begin
        dp_ram #(16, 4, 64) w_buffer(
            .clk(clk),
            .ena(ram_select[i]),
            .enb(enb),
            .wea(ram_select[i] & wea),
            .addra(addra[ADDR_WIDTH -1 : 0]),
            .addrb(addrb),
            .dia(dia),
            .dob(weight_out[(i+1)*DATA_WIDTH -1: i*DATA_WIDTH])
            );
    end
endgenerate

assign weight_buffer_out = weight_out;

endmodule 

module sel_decoder(
    input wire [1:0] sel,
    output reg [3:0] res
);

always @(sel)  
    begin  
        case (sel)  
        2'b00 : res = 4'b0001;  
        2'b01 : res = 4'b0010;  
        2'b10 : res = 4'b0100;  
        2'b11 : res = 4'b1000;  
        default : res = 4'b0000;  
    endcase  
  end 
endmodule