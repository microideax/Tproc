// This feature mem is constructed with scratchpad_mem
// Each feature mem contains Tn scratchpad_mem
// totally Tn x KERNEL_SIZE memory lines are indexed by the dst_addr
// Tn --> dst_addr_h
// Kernel_number --> dst_addr_l

`include "network_para.vh"

module scratchpad_feature_mem#(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH
)(
    input wire clk,
    input wire rst,

    input wire [8:0] wr_mem_group, // select the mem group from the Tn group of memory
    input wire [3:0] wr_mem_line,  // select the mem line from the KERNEL_SIZE line of memory
    input wire [8:0] rd_mem_group,
    input wire [3:0] rd_mem_line,

    input wire [DATA_BUS_WIDTH-1: 0] i_port,

    output wire [Tn*FEATURE_WIDTH*KERNEL_SIZE-1 : 0] data_out
);

reg [DATA_BUS_WIDTH-1 :0] i_data [Tn-1 : 0];

always@(wr_mem_group) begin
    i_data[wr_mem_group] = i_port;
end

genvar i;
generate 
    for(i=0; i < Tn; i=i+1) begin: feature_mem
        // assign i_data[wr_mem_group] = (wr_mem_group == i) ? i_port : {DATA_BUS_WIDTH{1'b0}};
        scratchpad_mem mem_line (
            .clk(clk),
            .rst(rst),
            .wr_mem_line(wr_mem_line),
            .rd_mem_line(),
            .i_data(i_data[i]),
            .wr_en(),
            .rd_en(),
            .data_out(),
            .group_empty(),
            .group_full()
        );
    end
endgenerate

endmodule