// This module process the multiplication of the ternary weights and the input feature

`include "network_para.vh"

module t_proc_array# (
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH
)(
    input wire clk,
    input wire rst,
    input wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] feature_in,
    input wire kernel_valid,
    input wire [Tm*Tn*KERNEL_SIZE*KERNEL_SIZE*KERNEL_WIDTH - 1 : 0] weight_in,
    output wire [Tm*Tn*KERNEL_SIZE*KERNEL_SIZE-1 : 0] select_out
);


generate 
    for(x = 0; x < Tm;x = x + 1) begin:select_m
        for(k = 0; k < Tn; k = k + 1) begin:select_n
            for(i = 0; i < KERNEL_SIZE; i = i + 1) begin:select_r
               for(j = 0; j < KERNEL_SIZE; j = j + 1) begin:select_c
                   select_unit #(
                    .FEATURE_WIDTH(FEATURE_WIDTH) 
                   )my_select_unit(
                    .clk(clk),
                    .rst(rst),
                    .select_in(feature_in_wire[k * KERNEL_SIZE * KERNEL_SIZE + i * KERNEL_SIZE + j]),
                    .kernel_valid(kernel_valid),
                    .kernel_value(weight_in_wire[x * Tn *KERNEL_SIZE *KERNEL_SIZE + k * KERNEL_SIZE * KERNEL_SIZE + i * KERNEL_SIZE + j]),                                
                    .select_out(select_out_wire[x * Tn * KERNEL_SIZE * KERNEL_SIZE + k * KERNEL_SIZE * KERNEL_SIZE + i * KERNEL_SIZE + j])
                    );
                end
            end
        end
    end
endgenerate 

endmodule