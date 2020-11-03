// virtical_reg used to buffer the input data for the select_array 

`include "network_para.vh"

module virtical_reg #(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_width = `KERNEL_SIZE
)(
    input clk,
    input rst,
    input wire [3:0] com_type,
    input wire [7:0] kernel_size,
    input wire enable,
    input wire in_select,
    output reg feature_en_0,
    output reg feature_en_1,
    input wire [Tn*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] dia_0,
    input wire [Tn*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] dia_1,
    output wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] doa,
    output wire shift_done
);

reg [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] d_temp_0;
reg [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] d_temp_1;

reg shift_enable_reg, shift_enable, vir_reg_done;

always@(posedge clk) begin
    if(rst) begin
        feature_en_0 <= 0;
        feature_en_1 <= 0;
        shift_enable_reg <= 0;
        shift_enable <= 0;
        vir_reg_done <= 0;
    end
    else begin
        feature_en_0 <= enable & ~in_select;
        feature_en_1 <= enable & in_select;
        shift_enable_reg <= enable;
        shift_enable <= shift_enable_reg;
        vir_reg_done <= shift_enable;
    end
end

assign shift_done = vir_reg_done;

always@(posedge clk) begin
    if (shift_enable) begin
        d_temp_0[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] <= {d_temp_0[Tn*KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], dia_0};
        d_temp_1[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] <= {d_temp_1[Tn*KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], dia_1};
    end
    else begin
        d_temp_0 <= d_temp_0;
        d_temp_1 <= d_temp_1;
    end
end

assign doa[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] = vir_reg_done ? d_temp_1[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] : d_temp_0[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0];

endmodule