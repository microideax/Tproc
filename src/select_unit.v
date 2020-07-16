`include "network_para.vh"

module select_unit#(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, 
    parameter KERNEL_WIDTH = `KERNEL_WIDTH
)(
    input wire                                      clk,
    input wire                                      rst,
    input wire  signed [FEATURE_WIDTH-1:0]          select_in,
    input wire                                      kernel_valid,
    input wire  signed [KERNEL_WIDTH - 1 : 0]       kernel_value,
    output reg  signed [FEATURE_WIDTH-1:0]          select_out
    );

wire [FEATURE_WIDTH-1:0] kernel_wire;
assign kernel_wire = (kernel_valid) ? kernel_value : 0;

always @(posedge clk)
    begin
        if(rst)
            select_out <= 0;
        else
            begin
            if(kernel_wire == 2'b01)
                select_out <= select_in;
            else if(kernel_wire == 2'b10)
                select_out <= -select_in;
            else if(kernel_wire == 2'b11)
                select_out <= (select_in<<1);
            else 
                select_out <= 0;
            end
    end
endmodule