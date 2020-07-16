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
    input wire   line_buffer_mod, // controls if the line_buffer is processing the very first lines of the input feature

    input  wire    [Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0]      feature_mem_read_data_0,
    input  wire    [Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 :0]      feature_mem_read_data_1,
    
    output wire  output_valid,
    output wire  [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0]          feature_wire
    );
    
reg [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_out;
reg [Tn * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_tmp [KERNEL_SIZE-1 : 0];

genvar i,j,k,x,y,z;
  
wire [Tn * KERNEL_SIZE * FEATURE_WIDTH - 1 :0] feature_transfer_wire;
wire [KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] line_buffer_in [Tn-1 : 0];
wire [Tn * KERNEL_SIZE * FEATURE_WIDTH - 1 :0] line_buffer_out;

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
                    .line_buffer_mod(line_buffer_mod),   
                    .current_kernel_size(current_kernel_size),
                    .shift_ram_depth(feature_size),//shift_ram_depth(5'd31),
                    .data_in(line_buffer_in[i]),
                    .data_out(line_buffer_out[(i+1) * FEATURE_WIDTH * KERNEL_SIZE - 1 : i * FEATURE_WIDTH * KERNEL_SIZE])
                    );
end
endgenerate


// TODO: this line buffer module contains the shifting module which outputs the Tn*K*K feature data
// when line_buffer_mod == 1 the line buffer is the general line_buffer
// when line_buffer_mod == 0 the line buffer is in data filing mod, without output, need to direct line_buffer_in to feature_out

reg[3:0] shifting_counter;

generate
for(x = 0; x < Tn; x = x+1) begin: input_direct_output
    always@(posedge clk) begin: in_to_out
        if(rst) begin
            feature_out <= 0;
        end else begin
            if(line_buffer_mod == 0) begin: line_in_to_final_out
                feature_out[(x+1)* KERNEL_SIZE * KERNEL_SIZE  * FEATURE_WIDTH - 1 : x* KERNEL_SIZE* KERNEL_SIZE * FEATURE_WIDTH] <= line_buffer_in[i]; 
//                line_buffer_in[(x+1)* KERNEL_SIZE * FEATURE_WIDTH - 1 : x* KERNEL_SIZE * FEATURE_WIDTH];
            end: line_in_to_final_out
            else begin
                feature_out[(x+1)* KERNEL_SIZE * KERNEL_SIZE  * FEATURE_WIDTH - 1 : x* KERNEL_SIZE* KERNEL_SIZE * FEATURE_WIDTH] 
                        <= line_buffer_out[x* KERNEL_SIZE + KERNEL_SIZE - 1 : x* KERNEL_SIZE];
            end                                                
        end
        end
    end
//end: input_direct_output
endgenerate

reg [KERNEL_SIZE-1: 0] shifting_counter; 
always@(posedge clk)begin
    if(rst) begin
        feature_out[Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] <= 0;
        shifting_counter <= 1'b1;
    end
    else begin
        if(line_buffer_mod == 0) begin: shifting_counter_logic
            shifting_counter <= shifting_counter << 1;
            // shifting_counter[KERNEL_SIZE - 1 : 1] <= shifting_counter[KERNEL_SIZE -2: 0];
        end else begin
            shifting_counter <= shifting_counter;
        end
    end
end

assign output_valid = shifting_counter[KERNEL_SIZE-1];
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