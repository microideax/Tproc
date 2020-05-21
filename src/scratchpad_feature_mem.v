// This feature mem is constructed with scratchpad_mem
// Each feature mem contains Tn scratchpad_mem
// totally Tn x KERNEL_SIZE memory lines are indexed by the dst_addr
// Tn --> dst_addr_h
// Kernel_number --> dst_addr_l

// The read status for the feature lines are either reading all the lines out (line_buffer_mod == 0)
// or just reading a single line out (line_buffer_mod == 1)

`include "network_para.vh"

module scratchpad_feature_mem#(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH
)(
    input wire clk,
    input wire rst,

    input wire wr_en,
    input wire rd_en,
    input wire [3:0] wr_mem_group, // select the mem group from the Tn group of memory
    input wire [3:0] wr_mem_line,  // select the mem line from the KERNEL_SIZE line of memory
    input wire [3:0] rd_mem_group,
    input wire [3:0] rd_mem_line,

    input wire [DATA_BUS_WIDTH-1: 0] i_port,

    output wire [Tn*FEATURE_WIDTH*KERNEL_SIZE-1 : 0] data_out
);

reg [DATA_BUS_WIDTH-1 :0] i_port_reg;
reg [DATA_BUS_WIDTH-1 :0] i_data [Tn-1 : 0];
reg [Tn-1 : 0] wr_en_group;
reg [KERNEL_SIZE -1: 0] wr_mem_line_reg;
reg rd_en_wire [Tn-1 : 0]; 
wire group_empty_wire [Tn-1 :0];
wire group_full_wire [Tn-1 : 0];

// reg [8:0] wr_mem_group_reg;
reg wr_en_reg;
always@(posedge clk) begin
    if(rst)begin
        // i_data[wr_mem_group[3:0]]
        wr_en_group[Tn-1:0] <= 0;
    end
    else begin
        if(wr_en) begin
            // i_port_reg <= i_port;
            i_data[wr_mem_group[3:0]] <= i_port;
            wr_en_group[wr_mem_group[3:0]] <= 1'b1;
            wr_mem_line_reg <= wr_mem_line;
        end   
        else begin
            // i_port_reg <= 0;
            // wr_en_reg <= 0;
            i_data[wr_mem_group[3:0]] <= 0;
            wr_en_group[wr_mem_group[3:0]] <= 0;
            wr_mem_line_reg <= 0;
        end 
    end
end

/*
always@(posedge clk) begin
    if(wr_en) begin
        case (wr_mem_group[3:0])
            8'h0: begin
                i_data[0] <= i_port_reg;
                // wr_en_wire[0] <= wr_en;
            end
            8'h1: begin
                i_data[1] <= i_port_reg;
                // wr_en_wire[1] <= wr_en;
            end
            8'h2: begin
                i_data[2] <= i_port_reg;
                // wr_en_wire[2] <= wr_en;
            end
            8'h3: begin
                i_data[3] <= i_port_reg;
                // wr_en_wire[3] <= wr_en;
            end
            default: begin
                // wr_en_wire[3:0] <= 4'b0000;
            end
        endcase
        i_data[wr_mem_group] <= i_port;
        wr_en_wire[wr_mem_group] <= 1'b1;
    end
    else begin
        wr_en_wire[3:0] <= 4'b0000;
    end
end */

always@(rd_mem_group) begin
    rd_en_wire[rd_mem_group] = rd_en;
end

genvar i;
generate 
    for(i=0; i < Tn; i=i+1) begin: feature_mem
        // assign i_data[wr_mem_group] = (wr_mem_group == i) ? i_port : {DATA_BUS_WIDTH{1'b0}};
        scratchpad_mem mem_line (
            .clk(clk),
            .rst(rst),
            .wr_mem_line(wr_mem_line_reg),
            .rd_mem_line(rd_mem_line),
            .i_data(i_data[i]),
            .wr_en(wr_en_group[i]),
            .rd_en(rd_en_wire[i]),
            .data_out(data_out[i*FEATURE_WIDTH*KERNEL_SIZE + FEATURE_WIDTH*KERNEL_SIZE -1: i*FEATURE_WIDTH*KERNEL_SIZE]),
            .group_empty(group_empty_wire[i]),
            .group_full(group_full_wire[i])
        );
    end
endgenerate

endmodule