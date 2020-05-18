
// This scratch pad memory is constructed by asymmetric_fifo
// The input fills each of the fifo line for every feature load read
// Each of the scratchpad memory is constructed with kernel_size numbers of fifos
// 128 bits input fills each of the fifo line
// 16 bits output from each of the fifo line
// The fifo lines start output 

`include "network_para.vh"

module scratchpad_mem#(
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH
)(
    input wire clk,
    input wire rst,
    input wire [3:0] wr_mem_line, // indexing of the fifo lines
    input wire [3:0] rd_mem_line,
    input wire [DATA_BUS_WIDTH-1: 0] i_data,
    input wire wr_en,
    input wire rd_en,
    
    output wire [FEATURE_WIDTH*KERNEL_SIZE-1: 0] data_out,
    output wire group_empty,
    output wire group_full
);

// reg [DATA_BUS_WIDTH - 1 : 0] data_reg;
reg [DATA_BUS_WIDTH - 1 : 0] din_to_fifo [KERNEL_SIZE-1 : 0];
reg [KERNEL_SIZE-1 : 0] wr_en_line;

// always@(posedge clk) begin
    // data_reg <= i_data;
// end

always@(posedge clk) begin
    if(rst) begin
        wr_en_line[KERNEL_SIZE - 1 : 0] <= 5'b00000;
    end 
    else begin
        if(wr_en) begin
            din_to_fifo[wr_mem_line] <= i_data;
            wr_en_line[wr_mem_line] <= wr_en;
        end 
        else begin
            // din_to_fifo[wr_mem_line] <= 0;
            wr_en_line[KERNEL_SIZE - 1 : 0] <= 5'b00000;
        end
    end
end

//assign din_to_fifo[wr_mem_line] = i_data;

wire [KERNEL_SIZE * FEATURE_WIDTH-1 : 0] fifo_to_dout;
reg rd_en_wire [KERNEL_SIZE-1:0];

always@(posedge clk) begin
    case(rd_mem_line)
        4'h0: begin
            rd_en_wire[0] = rd_en;
        end
        4'h1: begin
            rd_en_wire[1] = rd_en;
        end
        4'h2: begin
            rd_en_wire[2] = rd_en;
        end
        4'h3: begin
            rd_en_wire[3] = rd_en;
        end
        4'h4: begin
            rd_en_wire[4] = rd_en;
        end
    endcase
end

wire [KERNEL_SIZE-1 : 0] full_wire;
wire [KERNEL_SIZE-1 : 0] empty_wire;

genvar i;
generate
    for(i=0; i < KERNEL_SIZE; i=i+1) begin: s_pad_mem
    asymmetric_fifo spad_mem_0(
        .clk(clk),
        .srst(rst),
        .din(din_to_fifo[i]), // [127:0]
        .wr_en(wr_en_line[i]),
        .rd_en(rd_en_wire[i]),
        .dout(fifo_to_dout[i*FEATURE_WIDTH + FEATURE_WIDTH-1 : i*FEATURE_WIDTH]), // [15:0]
        .full(full_wire[i]),
        .empty(empty_wire[i])
    );
    end
    
endgenerate

assign data_out[KERNEL_SIZE * FEATURE_WIDTH -1 : 0] = fifo_to_dout[KERNEL_SIZE * FEATURE_WIDTH -1 : 0];
assign group_empty = empty_wire[0];
assign group_full = full_wire[KERNEL_SIZE-1];
/*
always@(full_wire or empty_wire)begin
    if(full_wire == 8'hff) begin
        group_full = 1'b1;
    end else begin
        group_full = 1'b0;
    end
    if(empty_wire == 8'hff) begin
        group_empty = 1'b1;
    end else begin
        group_empty = 1'b0;
    end
end
*/
endmodule