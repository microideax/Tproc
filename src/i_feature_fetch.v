// dummy input feature fetch module

module i_feature_fetch(
input wire clk,
input wire rst,
input wire [127:0] i_data,
input wire [6:0] opcode,
input wire [7:0] feature_size,
input wire feature_in_select,

output reg [14:0] wr_addr,
output reg [15:0] wr_data,
output reg wr_en,
output reg i_mem_select );      

// this module reads data from external memory to the on chip feature_in_memory  

endmodule

module i_weight_fetch(
    input wire clk,
    input wire rst,
    input wire [127:0] i_data,
    input wire [6:0] opcode,
    input wire [15:0] fetch_addr, // this will be defined by the parser, 
                                  // which is the relative address of the weight data

    output reg [14:0] wr_addr,
    output reg [127:0] wr_data,
    output reg wr_en                                  
);

endmodule