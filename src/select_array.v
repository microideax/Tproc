// Select array is constructed with select unit to process the 2-bit*4-bit multiplication
// Select array takes in Tn feature input, conv with Tm set of weight (each set has Tn learning kernels)


module TnKK_select_array#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_SIZE_3 = `KERNEL_SIZE_3,
    parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
    parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE,
    parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter SCALER_WIDTH = `SCALER_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, 
    parameter BIAS_WIDTH = `BIAS_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_in,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ] weight_in,
    input wire enable,
    input wire [4:0] channel_NO_in,
    input wire [1:0] kn_size_mode,
    output reg [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] feature_out,
    output reg ternary_com_done,
    output wire [4:0] channel_NO_out
);

wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] temp_feature_out;

wire [FEATURE_WIDTH - 1 : 0] feature_in_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
//wire [FEATURE_WIDTH - 1 : 0] feature_reorder [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [KERNEL_WIDTH - 1 : 0] weight_in_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

wire [FEATURE_WIDTH - 1 : 0] temp_feature_kn5 [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [FEATURE_WIDTH - 1 : 0] temp_feature_kn3 [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [FEATURE_WIDTH - 1 : 0] temp_feature_kn1 [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

register_x1 #(.FEATURE_WIDTH(5)) lat_1_channel(.clk(clk), .rst(rst), .in_data(channel_NO_in), .o_data(channel_NO_out));

genvar i;

generate
    for(i = 0; i < Tn * KERNEL_SIZE * KERNEL_SIZE; i = i+1) begin: feature_select_array
        assign feature_in_wire[i] = feature_in[(i+1)*FEATURE_WIDTH-1:i*FEATURE_WIDTH];
        assign weight_in_wire[i] = weight_in[(i+1)*KERNEL_WIDTH-1:i*KERNEL_WIDTH];
        
        //kn5
        assign temp_feature_kn5[i] = (weight_in_wire[i] == 2'b01) ? feature_in_wire[i]
                               : (weight_in_wire[i] == 2'b11) ? ((~feature_in_wire[i]) + 1)
                               : 0;
        
        //kn3
        if (i%(KERNEL_SIZE*KERNEL_SIZE) < KERNEL_SIZE_3 * KERNEL_SIZE_3) begin
            assign temp_feature_kn3[i] = (weight_in_wire[i] == 2'b01) ? feature_in_wire[i]
                                       : (weight_in_wire[i] == 2'b11) ? ((~feature_in_wire[i]) + 1)
                                       : 0;
        end else
        if (i%(KERNEL_SIZE*KERNEL_SIZE) < 2 * KERNEL_SIZE_3 * KERNEL_SIZE_3) begin
            assign temp_feature_kn3[i] = (weight_in_wire[i-KERNEL_SIZE_3*KERNEL_SIZE_3] == 2'b01) ? feature_in_wire[i]
                                       : (weight_in_wire[i-KERNEL_SIZE_3*KERNEL_SIZE_3] == 2'b11) ? ((~feature_in_wire[i]) + 1)
                                       : 0;
        end 
        else begin
            assign temp_feature_kn3[i] = 0;
        end

        //kn1
        assign temp_feature_kn1[i] = (weight_in_wire[(i/(KERNEL_SIZE*KERNEL_SIZE))*(KERNEL_SIZE*KERNEL_SIZE)] == 2'b01) ? feature_in_wire[i]
                                   : (weight_in_wire[(i/(KERNEL_SIZE*KERNEL_SIZE))*(KERNEL_SIZE*KERNEL_SIZE)] == 2'b11) ? ((~feature_in_wire[i]) + 1)
                                   : 0;

        //MUX
        assign temp_feature_out[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH] = (kn_size_mode == KERNEL_SIZE_1_MODE) ? temp_feature_kn1[i] 
                                                                         : (kn_size_mode == KERNEL_SIZE_3_MODE) ? temp_feature_kn3[i]
                                                                         : temp_feature_kn5[i];
    end
endgenerate

always @(posedge clk or posedge rst) begin
    if(rst) begin
        feature_out <= 0;
        ternary_com_done <= 0;
    end else begin
        feature_out <= (enable) ? temp_feature_out : 0;
        ternary_com_done <= enable;
    end
end

endmodule