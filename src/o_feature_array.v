// This module is used to store the features for output

`include "network_para.vh"

module o_feature_array #(
    parameter Tm = `Tm,
    parameter Tn = `Tn,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [Tm*FEATURE_WIDTH-1 : 0] wr_feature_in,
    input wire [Tm-1 : 0] wr_feature_enable,
    output wire feature_out,
    input wire [Tm-1 : 0] rd_feature_enable
);


endmodule


module o_feature_reg #(
    parameter Tm = `Tm,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [FEATURE_WIDTH-1 : 0] wr_feature_in,
    input wire [Tm-1 : 0] wr_feature_enable,
    output wire [FEATURE_WIDTH-1 : 0] rd_feature_out,
    input wire [Tm-1 : 0] rd_feature_enable
);

genvar i;
generate
    for(i=0; i<Tm; i=i+1)begin
        syn_fifo #(16, 4, 16) o_fifo (
            .clk(clk),
            .rst(rst),
            .wr_cs(wr_feature_enable[i]),
            .rd_cs(rd_feature_enable[i]),
            .data_in(wr_feature_in),
            .rd_en(rd_feature_enable[i]),
            .wr_en(wr_feature_enable[i]),
            .data_out(rd_feature_out),
            .empty(),
            .full()
        );
    end 
endgenerate

endmodule