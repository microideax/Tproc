`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2018 02:27:25 PM
// Design Name: 
// Module Name: featrue_mem_ctr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
// Functionality: read feature data in from the feature buffer
// Output the entire kernel with shifting for the computation array
//////////////////////////////////////////////////////////////////////////////////
`include "network_para.vh"

module line_buffer_array#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_IN_MEM_READ_WIDTH_COF = `FEATURE_IN_MEM_READ_WIDTH_COF
)(
    input wire                                                                    clk,
    input wire                                                                    rst,
    input wire   [2:0]                                                            current_kernel_size,
    input wire   [7:0]                                                            feature_size,
    input wire                                                                    line_buffer_enable,
    input wire   input_buffer_select,
    
    input wire   src_buffer_empty,
    input wire   src_buffer_full,
    input wire   initial_lines_of_feature,

    input  wire    [Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0]      feature_mem_read_data_0,
    input  wire    [Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0]      feature_mem_read_data_1,
    
    output wire  [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0]          feature_wire
    );
    
reg [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_out;
reg [Tn * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_tmp [KERNEL_SIZE-1 : 0];

genvar i,j,k,x,y,z;
  
// always@(posedge clk)
//     if(rst)
//         feature_mem_read_data_tmp <= 0;
//     else 
//         if ((current_kernel_size != 1) && (feature_mem_read_cnt2 == 2))
//             feature_mem_read_data_tmp <= feature_mem_read_data >> (FEATURE_WIDTH*Tn);
//         else if ((current_kernel_size == 1) && (feature_mem_read_cnt2 == 0))
//             feature_mem_read_data_tmp <= feature_mem_read_data >> (FEATURE_WIDTH*Tn); 
//         else
//             feature_mem_read_data_tmp <= feature_mem_read_data_tmp >> (FEATURE_WIDTH*Tn);
 
wire [Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0] feature_transfer_wire;
wire [FEATURE_WIDTH * KERNEL_SIZE - 1 : 0] line_buffer_in [Tn-1 : 0];
wire [Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0] line_buffer_out;

assign feature_transfer_wire[Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0] = 
                    (input_buffer_select) ? feature_mem_read_data_1[Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0] 
                    : feature_mem_read_data_0[Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0];

generate
    for(i = 0 ; i < Tn ; i = i + 1) begin:array_to_lines
        assign line_buffer_in[i] = feature_transfer_wire[(i+1) * KERNEL_SIZE * FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH];
    end
endgenerate
           
generate
for(i = 0 ; i < Tn; i = i+1) begin:lined_buffer
    line_buffer line_buffer0(
                    .clk(clk),
                    .enable(line_buffer_enable),
                    .line_buffer_mod(),   
                    .current_kernel_size(current_kernel_size),
                    .shift_ram_depth(feature_size),//shift_ram_depth(5'd31),
                    .data_in(line_buffer_in[i]),
                    .data_out(line_buffer_out[(i+1) * FEATURE_WIDTH * KERNEL_SIZE - 1 : i * FEATURE_WIDTH * KERNEL_SIZE])
                    );
end
endgenerate


// TODO: 1) if the input lines contains the line #1, then the input should be transferred to line_buffer 
//  and also directly output
//       2) this line buffer module contains the shifting module which outputs the Tn*K*K feature data



assign feature_wire[Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] = feature_out[Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0];

// generate
// for(i = 0 ; i <Tn ; i = i + 1) begin:feature_wire_i
//     for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_wire_j
//         for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_wire_k
//             assign feature_wire[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
//                                 i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
//                     = (current_kernel_size == 1) ? feature_transfer_wire_for_1X1[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
//                                                                                  i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
//                                                   :feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k];
//         end
//     end
// end
// endgenerate
   

endmodule