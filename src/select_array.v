// Select array is constructed with select unit to process the 2-bit*4-bit multiplication
// Select array takes in Tn feature input, conv with Tm set of weight (each set has Tn learning kernels)


module TnKK_select_array#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter SCALER_WIDTH = `SCALER_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, 
    parameter BIAS_WIDTH = `BIAS_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_in,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]    weight_in,
    input wire enable,
    output reg [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_out
);

wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] temp_feature_out;

wire [FEATURE_WIDTH - 1 : 0] feature_in_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
//wire [FEATURE_WIDTH - 1 : 0] feature_reorder [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [KERNEL_WIDTH - 1 : 0] weight_in_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

wire [FEATURE_WIDTH - 1 : 0] temp_feature [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

genvar i;
generate
    for(i = 0; i < Tn * KERNEL_SIZE * KERNEL_SIZE; i = i+1) begin: feature_select_arrya
        assign feature_in_wire[i] = feature_in[(i+1)*FEATURE_WIDTH-1:i*FEATURE_WIDTH];
        //assign feature_reorder[i] = feature_in[((i%25/5) + 5 * (i/25) + 20 * (i%5)+1)*FEATURE_WIDTH-1:((i%25/5) + 5 * (i/25) + 20 * (i%5))*FEATURE_WIDTH];
        //assign feature_reorder[i] = feature_in[(i+1)*FEATURE_WIDTH-1:i*FEATURE_WIDTH];
        assign weight_in_wire[i] = weight_in[(i+1)*KERNEL_WIDTH-1:i*KERNEL_WIDTH];
        assign temp_feature[i] = feature_in_wire[i] * weight_in_wire[i];
        assign temp_feature_out[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH] = temp_feature[i];
    end
endgenerate

always @(posedge clk or posedge rst) begin
    if(rst) begin
        feature_out <= 0;
    end else begin
        feature_out <= (enable) ? temp_feature_out : 0;
    end
end

endmodule