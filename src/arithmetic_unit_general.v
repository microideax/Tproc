// general adder unit for test

`include "network_para.vh"

module adderx4 #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [FEATURE_WIDTH-1 : 0] A1,
    input wire [FEATURE_WIDTH-1 : 0] B1,
    output reg [FEATURE_WIDTH-1 : 0] O1,
    input wire [FEATURE_WIDTH-1 : 0] A2,
    input wire [FEATURE_WIDTH-1 : 0] B2,
    output reg [FEATURE_WIDTH-1 : 0] O2,
    input wire [FEATURE_WIDTH-1 : 0] A3,
    input wire [FEATURE_WIDTH-1 : 0] B3,
    output reg [FEATURE_WIDTH-1 : 0] O3,
    input wire [FEATURE_WIDTH-1 : 0] A4,
    input wire [FEATURE_WIDTH-1 : 0] B4, 
    output reg [FEATURE_WIDTH-1 : 0] O4
);

always@(posedge clk) begin
    if(rst) begin
        O1 <= 0;
        O2 <= 0;
        O3 <= 0;
        O4 <= 0;
    end
    else begin
        O1 <= A1 + B1;
        O2 <= A2 + B2;
        O3 <= A3 + B3;
        O4 <= A4 + B4;
    end
end

endmodule

module adder_4in_1out #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [FEATURE_WIDTH-1 : 0] A1,
    input wire [FEATURE_WIDTH-1 : 0] B1,
    input wire [FEATURE_WIDTH-1 : 0] A2,
    input wire [FEATURE_WIDTH-1 : 0] B2,
    output reg [FEATURE_WIDTH-1 : 0] O
);
always@(posedge clk) begin
    if(rst) begin
        O <= 0;
    end
    else begin
        O <= A1 + B1 + A2 + B2;
    end
end
endmodule



module adder_2Nin_Nout #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter CHANNEL_NUM = 12 // channel number must be divided by 4
) (
    input wire fast_clk,
    input wire rst,
    input wire [FEATURE_WIDTH * CHANNEL_NUM - 1 : 0] A_INPUT,
    input wire [FEATURE_WIDTH * CHANNEL_NUM - 1 : 0] B_INPUT,
    output wire [FEATURE_WIDTH * CHANNEL_NUM - 1 : 0] O_OUTPUT
);

wire [FEATURE_WIDTH - 1 : 0] A_DATA [CHANNEL_NUM - 1 : 0];
wire [FEATURE_WIDTH - 1 : 0] B_DATA [CHANNEL_NUM - 1 : 0];
wire [FEATURE_WIDTH - 1 : 0] O_DATA [CHANNEL_NUM - 1 : 0];

genvar i, j;

generate
    for(i = 0; i < CHANNEL_NUM; i = i+1) begin
        assign A_DATA[i] = A_INPUT[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH];
        assign B_DATA[i] = B_INPUT[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH];
        assign O_OUTPUT[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH] = O_DATA[i];
    end
endgenerate


generate                 //   adder No.1
    for(j = 0 ; j < CHANNEL_NUM; j=j+4) begin:adder_6
        adderx4  adder_line_0(
            .clk(fast_clk), 
            .rst(rst),
            .A1(A_DATA[j]), 
            .B1(B_DATA[j]),
            .O1(O_DATA[j]), 
            .A2(A_DATA[j+1]),  
            .B2(B_DATA[j+1]),   
            .O2(O_DATA[j+1]),    
            .A3(A_DATA[j+2]),
            .B3(B_DATA[j+2]),
            .O3(O_DATA[j+2]),
            .A4(A_DATA[j+3]),
            .B4(B_DATA[j+3]),
            .O4(O_DATA[j+3])
            );
    end
endgenerate

endmodule



module register_x1 #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire clk,
    input wire rst,
    input [FEATURE_WIDTH - 1 : 0] in_data,
    output reg [FEATURE_WIDTH - 1 : 0] o_data
);

always@(posedge clk) begin
    if(rst) begin
        o_data <= 0;
    end else begin
        o_data <= in_data;
    end
end

endmodule



module adder_tree_single_kernel #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    // parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter ADDER_ROW = KERNEL_SIZE*KERNEL_SIZE
) (
    input wire fast_clk,
    input wire rst,
    input wire [KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 :0] ternery_res,
    output wire [FEATURE_WIDTH - 1 : 0] kernel_sum
);

genvar i, j, k;

wire [13*FEATURE_WIDTH - 1 : 0] adder_row_0_output;
adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(12)) adder_24_in_12_out (
    .fast_clk(fast_clk),
    .rst(rst),
    .A_INPUT(ternery_res[12*FEATURE_WIDTH-1 : 0]),
    .B_INPUT(ternery_res[24*FEATURE_WIDTH-1 : 12*FEATURE_WIDTH]),
    .O_OUTPUT(adder_row_0_output[12*FEATURE_WIDTH-1 : 0])
);
register_x1 #(FEATURE_WIDTH) adder_row_0_reg_out(
    .clk(fast_clk),
    .rst(rst),
    .in_data(ternery_res[KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : (KERNEL_SIZE*KERNEL_SIZE-1)*FEATURE_WIDTH]),
    .o_data(adder_row_0_output[13*FEATURE_WIDTH - 1 : 12*FEATURE_WIDTH])
);

wire [16*FEATURE_WIDTH - 1 : 0] adder_row_1_input;
wire [8*FEATURE_WIDTH - 1 : 0] adder_row_1_output;
// wire [8*FEATURE_WIDTH - 1 : 0] adder_row_2_input;
generate
    for(i = 0; i < 16; i=i+1) begin
        if(i < 13) begin
            assign adder_row_1_input[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH] = adder_row_0_output[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH];
        end else begin
            assign adder_row_1_input[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH] = 0;
        end
    end
endgenerate


adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(8)) adder_16_in_8_out (
    .fast_clk(fast_clk),
    .rst(rst),
    .A_INPUT(adder_row_1_input[8*FEATURE_WIDTH - 1 : 0]),
    .B_INPUT(adder_row_1_input[16*FEATURE_WIDTH - 1 : 8*FEATURE_WIDTH]),
    .O_OUTPUT(adder_row_1_output)
);

wire [8*FEATURE_WIDTH - 1 : 0] adder_row_2_output;
adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(4)) adder_8_in_4_out (
    .fast_clk(fast_clk),
    .rst(rst),
    .A_INPUT(adder_row_1_output[4*FEATURE_WIDTH - 1 : 0]),
    .B_INPUT(adder_row_1_output[8*FEATURE_WIDTH - 1 : 0]),
    .O_OUTPUT(adder_row_2_output)
);

adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1 (
    .clk(fast_clk),
    .rst(rst),
    .A1(adder_row_2_output[FEATURE_WIDTH-1:0]),
    .B1(adder_row_2_output[2*FEATURE_WIDTH-1:FEATURE_WIDTH]),
    .A2(adder_row_2_output[3*FEATURE_WIDTH-1:2*FEATURE_WIDTH]),
    .B2(adder_row_2_output[4*FEATURE_WIDTH-1:3*FEATURE_WIDTH]),
    .O(kernel_sum)
);

endmodule


module adder_tree_Tn_kernel #(
    parameter Tn = `Tn,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter ADDER_ROW = KERNEL_SIZE*KERNEL_SIZE
) (
    input wire fast_clk,
    input wire rst,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 :0] ternery_res_tn,
    output wire [Tn * FEATURE_WIDTH - 1 : 0] kernel_sum_tn
);


genvar i;
generate
    for(i=0; i<Tn; i=i+1)begin
        adder_tree_single_kernel kernel_adder(
            .fast_clk(fast_clk),
            .rst(rst),
            .ternery_res(ternery_res_tn[(i+1)*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : i*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH]),
            .kernel_sum(kernel_sum_tn[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH])
        );
    end
endgenerate

endmodule


module adder_tree_tn #(
    parameter Tn = `Tn,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire fast_clk,
    input wire rst,
    input wire [Tn * FEATURE_WIDTH - 1 :0] tn_input,
    output wire [FEATURE_WIDTH - 1 : 0] out
);

genvar i;
generate
    for(i=0; i<Tn/4; i=i+1) begin
        adder_4in_1out channel_adder(
            .clk(fast_clk),
            .rst(rst),
            .A1(tn_input[FEATURE_WIDTH-1:0]),
            .B1(tn_input[2*FEATURE_WIDTH-1:FEATURE_WIDTH]),
            .A2(tn_input[3*FEATURE_WIDTH-1:2*FEATURE_WIDTH]),
            .B2(tn_input[4*FEATURE_WIDTH-1:3*FEATURE_WIDTH]),
            .O(out)
        );
    end
endgenerate

endmodule


module scaler_multiply_unit #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter SCALER_WIDTH = 16
) (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [FEATURE_WIDTH-1 : 0] data_in,
    input wire [SCALER_WIDTH-1 : 0] scaler_in,
    output reg [FEATURE_WIDTH+SCALER_WIDTH-1 : 0] data_o
);

always@(posedge clk) begin
    if(rst) begin
        data_o <= 0;
    end
    else if(enable) begin
        data_o <= data_in * scaler_in;
    end
    else begin
        data_o <= 0;
    end
end

endmodule