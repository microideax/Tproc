
// This scratch pad memory is constructed by syn_fifo
// The input fills each of the fifo line for every feature load read
// Each of the scratchpad memory is constructed with kernel_size numbers of fifos

`include "network_para.vh"

module scratchpad_mem(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter SCALER_WIDTH = `SCALER_WIDTH,
    parameter BIAS_WIDTH = `BIAS_WIDTH,
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH
)(
    input wire clk,
    input wire rst,
    input wire [DATA_BUS_WIDTH-1: 0] i_data,
    
    output wire [KERNEL_WIDTH*KERNEL_SIZE-1: 0] spad_mem_o,

    output wire group_empty,
    output wire group_full
)

genvar i;


generate
    for(i=0; i < KERNEL_SIZE; i=i+1) begin: s_pad_mem
        


endmodule