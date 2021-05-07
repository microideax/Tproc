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

module adder_2in_1out #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire clk,
    input wire rst,
    input wire [FEATURE_WIDTH-1 : 0] A1,
    input wire [FEATURE_WIDTH-1 : 0] B1,
    output reg [FEATURE_WIDTH-1 : 0] O
);
always@(posedge clk) begin
    if(rst) begin
        O <= 0;
    end
    else begin
        O <= A1 + B1;
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



module adder_tree_single_kernel_new #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_SIZE_3 = `KERNEL_SIZE_3,
    parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
    parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE,
    parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE,
    parameter ADDER_ROW = KERNEL_SIZE*KERNEL_SIZE
) (
    input wire fast_clk,
    input wire rst,
    input wire [KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 :0] ternery_res,// kn5/kn3: [KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 :0]    kn1: all bits
    input wire [1:0] kn_size_mode,
    output wire [FEATURE_WIDTH - 1 : 0] kernel_sum_even, // kn5/kn3 out
    output wire [FEATURE_WIDTH - 1 : 0] kernel_sum_odd, // kn3 out
    output wire [6*FEATURE_WIDTH - 1 : 0] kernel_size_1_out // kn1 out
);

/////////layer 0
wire [KERNEL_SIZE_3*KERNEL_SIZE_3*FEATURE_WIDTH-1 : 0] input_kernel_0, input_kernel_1; //two 3*3 kernel
wire [(KERNEL_SIZE*KERNEL_SIZE-2*KERNEL_SIZE_3*KERNEL_SIZE_3)*FEATURE_WIDTH-1 : 0] input_discard;//7 values, discarded in kn=3 mode
assign input_kernel_0 = ternery_res[KERNEL_SIZE_3*KERNEL_SIZE_3*FEATURE_WIDTH-1 : 0];
assign input_kernel_1 = ternery_res[2*KERNEL_SIZE_3*KERNEL_SIZE_3*FEATURE_WIDTH-1 : KERNEL_SIZE_3*KERNEL_SIZE_3*FEATURE_WIDTH];
assign input_discard = ternery_res[KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 2*KERNEL_SIZE_3*KERNEL_SIZE_3*FEATURE_WIDTH];
wire [4*FEATURE_WIDTH - 1 : 0] layer0_kernel_0,layer0_kernel_1, layer0_discard;
genvar i;
//kernel 0
generate
    for(i = 0; i < 2; i=i+1) begin
        adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1_kn0_l0 (
            .clk(fast_clk),
            .rst(rst),
            .A1(input_kernel_0[(1+i*4)*FEATURE_WIDTH-1 : i*4*FEATURE_WIDTH]),
            .B1(input_kernel_0[(2+i*4)*FEATURE_WIDTH-1 : (1+i*4)*FEATURE_WIDTH]),
            .A2(input_kernel_0[(3+i*4)*FEATURE_WIDTH-1 : (2+i*4)*FEATURE_WIDTH]),
            .B2(input_kernel_0[(4+i*4)*FEATURE_WIDTH-1 : (3+i*4)*FEATURE_WIDTH]),
            .O(layer0_kernel_0[(1+i)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH])
        );  
    end
endgenerate
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kn0_l0(.clk(fast_clk), .rst(rst), .in_data(input_kernel_0[9*FEATURE_WIDTH-1:8*FEATURE_WIDTH]), .o_data(layer0_kernel_0[3*FEATURE_WIDTH-1 : 2*FEATURE_WIDTH]));
assign layer0_kernel_0[4*FEATURE_WIDTH-1 : 3*FEATURE_WIDTH] = 0;
//kernel 1
generate
    for(i = 0; i < 2; i=i+1) begin
        adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1_kn1_l0 (
            .clk(fast_clk),
            .rst(rst),
            .A1(input_kernel_1[(1+i*4)*FEATURE_WIDTH-1 : i*4*FEATURE_WIDTH]),
            .B1(input_kernel_1[(2+i*4)*FEATURE_WIDTH-1 : (1+i*4)*FEATURE_WIDTH]),
            .A2(input_kernel_1[(3+i*4)*FEATURE_WIDTH-1 : (2+i*4)*FEATURE_WIDTH]),
            .B2(input_kernel_1[(4+i*4)*FEATURE_WIDTH-1 : (3+i*4)*FEATURE_WIDTH]),
            .O(layer0_kernel_1[(1+i)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH])
        );  
    end
endgenerate
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kn1_l0(.clk(fast_clk), .rst(rst), .in_data(input_kernel_1[9*FEATURE_WIDTH-1:8*FEATURE_WIDTH]), .o_data(layer0_kernel_1[3*FEATURE_WIDTH-1 : 2*FEATURE_WIDTH]));
assign layer0_kernel_1[4*FEATURE_WIDTH-1 : 3*FEATURE_WIDTH] = 0;
//discard
wire [FEATURE_WIDTH-1 : 0] zero_wire;
assign zero_wire = 0;
adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(4)) adder_8_in_4_out_disc_l0 (
    .fast_clk(fast_clk),
    .rst(rst),
    .A_INPUT(input_discard[4*FEATURE_WIDTH - 1 : 0]),
    .B_INPUT({zero_wire, input_discard[7*FEATURE_WIDTH - 1 : 4*FEATURE_WIDTH]}),
    .O_OUTPUT(layer0_discard)
);
//////////layer1
wire [FEATURE_WIDTH-1 : 0] layer1_discard, layer1_kernel_0, layer1_kernel_1;
adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1_kn0_l1 (
    .clk(fast_clk),
    .rst(rst),
    .A1(layer0_kernel_0[FEATURE_WIDTH-1:0]),
    .B1(layer0_kernel_0[2*FEATURE_WIDTH-1:FEATURE_WIDTH]),
    .A2(layer0_kernel_0[3*FEATURE_WIDTH-1:2*FEATURE_WIDTH]),
    .B2(layer0_kernel_0[4*FEATURE_WIDTH-1:3*FEATURE_WIDTH]),
    .O(layer1_kernel_0)
);
adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1_kn1_l1 (
    .clk(fast_clk),
    .rst(rst),
    .A1(layer0_kernel_1[FEATURE_WIDTH-1:0]),
    .B1(layer0_kernel_1[2*FEATURE_WIDTH-1:FEATURE_WIDTH]),
    .A2(layer0_kernel_1[3*FEATURE_WIDTH-1:2*FEATURE_WIDTH]),
    .B2(layer0_kernel_1[4*FEATURE_WIDTH-1:3*FEATURE_WIDTH]),
    .O(layer1_kernel_1)
);
adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1_disc_l1 (
    .clk(fast_clk),
    .rst(rst),
    .A1(layer0_discard[FEATURE_WIDTH-1:0]),
    .B1(layer0_discard[2*FEATURE_WIDTH-1:FEATURE_WIDTH]),
    .A2(layer0_discard[3*FEATURE_WIDTH-1:2*FEATURE_WIDTH]),
    .B2(layer0_discard[4*FEATURE_WIDTH-1:3*FEATURE_WIDTH]),
    .O(layer1_discard)
);
/////////layer2
wire [FEATURE_WIDTH-1 : 0] kn_size_5_out_temp, layer2_kernel_0, layer2_kernel_1;
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kn0_l2(.clk(fast_clk), .rst(rst), .in_data(layer1_kernel_0), .o_data(layer2_kernel_0));
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kn1_l2(.clk(fast_clk), .rst(rst), .in_data(layer1_kernel_1), .o_data(layer2_kernel_1));
adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1_kn_size_5 (
    .clk(fast_clk),
    .rst(rst),
    .A1(layer1_kernel_0),
    .B1(layer1_kernel_1),
    .A2(layer1_discard),
    .B2(0),
    .O(kn_size_5_out_temp)
);
/////////layer3
wire [FEATURE_WIDTH-1 : 0] kn_size_5_out, kn_size_3_even, kn_size_3_odd;
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kns3_even(.clk(fast_clk), .rst(rst), .in_data(layer2_kernel_0), .o_data(kn_size_3_even));
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kns3_odd(.clk(fast_clk), .rst(rst), .in_data(layer2_kernel_1), .o_data(kn_size_3_odd));
register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) lat_kns5_out(.clk(fast_clk), .rst(rst), .in_data(kn_size_5_out_temp), .o_data(kn_size_5_out));

/////////seperately, only for kernel_size=1
//wire [25*FEATURE_WIDTH - 1 : 0] kn_size_1_out;
//adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(28)) adder_56_in_28_out (
//    .fast_clk(fast_clk),
//    .rst(rst),
//    .A_INPUT(ternery_res[25*FEATURE_WIDTH - 1 : 0]),
//    .B_INPUT(ternery_res[50*FEATURE_WIDTH - 1 : 25*FEATURE_WIDTH]),
//    .O_OUTPUT(kn_size_1_out)
//);
wire [6*FEATURE_WIDTH - 1 : 0] kn_size_1_out;
genvar k;
generate
    for (k = 0; k < 6; k = k + 1) begin
        adder_4in_1out #(FEATURE_WIDTH) addertree_kn1 (
            .clk(fast_clk),
            .rst(rst),
            .A1(ternery_res[(4*k+1)*FEATURE_WIDTH-1 : 4*k*FEATURE_WIDTH]),
            .B1(ternery_res[(4*k+2)*FEATURE_WIDTH-1 : (4*k+1)*FEATURE_WIDTH]),
            .A2(ternery_res[(4*k+3)*FEATURE_WIDTH-1 : (4*k+2)*FEATURE_WIDTH]),
            .B2(ternery_res[(4*k+4)*FEATURE_WIDTH-1 : (4*k+3)*FEATURE_WIDTH]),
            .O(kn_size_1_out[(k+1)*FEATURE_WIDTH-1 : k*FEATURE_WIDTH])
        );
    end
endgenerate

/////////switch
assign kernel_sum_even = (kn_size_mode == KERNEL_SIZE_5_MODE) ? kn_size_5_out
                       : (kn_size_mode == KERNEL_SIZE_3_MODE) ? kn_size_3_even
                       : 0; //default is 0
assign kernel_sum_odd = (kn_size_mode == KERNEL_SIZE_3_MODE) ? kn_size_3_odd : 0;
assign kernel_size_1_out = (kn_size_mode == KERNEL_SIZE_1_MODE) ? kn_size_1_out : 0;

endmodule



//module adder_tree_single_kernel #(
//    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
//    parameter KERNEL_SIZE = `KERNEL_SIZE,
//    // parameter KERNEL_WIDTH = `KERNEL_WIDTH,
//    parameter ADDER_ROW = KERNEL_SIZE*KERNEL_SIZE
//) (
//    input wire fast_clk,
//    input wire rst,
//    input wire [KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 :0] ternery_res,
//    output wire [FEATURE_WIDTH - 1 : 0] kernel_sum
//);
//
//genvar i, j, k;
//
//wire [13*FEATURE_WIDTH - 1 : 0] adder_row_0_output;
//adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(12)) adder_24_in_12_out (
//    .fast_clk(fast_clk),
//    .rst(rst),
//    .A_INPUT(ternery_res[12*FEATURE_WIDTH-1 : 0]),
//    .B_INPUT(ternery_res[24*FEATURE_WIDTH-1 : 12*FEATURE_WIDTH]),
//    .O_OUTPUT(adder_row_0_output[12*FEATURE_WIDTH-1 : 0])
//);
//register_x1 #(FEATURE_WIDTH) adder_row_0_reg_out(
//    .clk(fast_clk),
//    .rst(rst),
//    .in_data(ternery_res[KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : (KERNEL_SIZE*KERNEL_SIZE-1)*FEATURE_WIDTH]),
//    .o_data(adder_row_0_output[13*FEATURE_WIDTH - 1 : 12*FEATURE_WIDTH])
//);
//
//wire [16*FEATURE_WIDTH - 1 : 0] adder_row_1_input;
//wire [8*FEATURE_WIDTH - 1 : 0] adder_row_1_output;
//// wire [8*FEATURE_WIDTH - 1 : 0] adder_row_2_input;
//generate
//    for(i = 0; i < 16; i=i+1) begin
//        if(i < 13) begin
//            assign adder_row_1_input[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH] = adder_row_0_output[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH];
//        end else begin
//            assign adder_row_1_input[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH] = 0;
//        end
//    end
//endgenerate
//
//
//adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(8)) adder_16_in_8_out (
//    .fast_clk(fast_clk),
//    .rst(rst),
//    .A_INPUT(adder_row_1_input[8*FEATURE_WIDTH - 1 : 0]),
//    .B_INPUT(adder_row_1_input[16*FEATURE_WIDTH - 1 : 8*FEATURE_WIDTH]),
//    .O_OUTPUT(adder_row_1_output)
//);
//
//wire [8*FEATURE_WIDTH - 1 : 0] adder_row_2_output;
//adder_2Nin_Nout #(.FEATURE_WIDTH(`FEATURE_WIDTH), .CHANNEL_NUM(4)) adder_8_in_4_out (
//    .fast_clk(fast_clk),
//    .rst(rst),
//    .A_INPUT(adder_row_1_output[4*FEATURE_WIDTH - 1 : 0]),
//    .B_INPUT(adder_row_1_output[8*FEATURE_WIDTH - 1 : 4*FEATURE_WIDTH]),
//    .O_OUTPUT(adder_row_2_output)
//);
//
//adder_4in_1out #(FEATURE_WIDTH) adder_4_to_1 (
//    .clk(fast_clk),
//    .rst(rst),
//    .A1(adder_row_2_output[FEATURE_WIDTH-1:0]),
//    .B1(adder_row_2_output[2*FEATURE_WIDTH-1:FEATURE_WIDTH]),
//    .A2(adder_row_2_output[3*FEATURE_WIDTH-1:2*FEATURE_WIDTH]),
//    .B2(adder_row_2_output[4*FEATURE_WIDTH-1:3*FEATURE_WIDTH]),
//    .O(kernel_sum)
//);
//
//endmodule





module adder_tree_Tn_kernel #(
    parameter Tn = `Tn,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE,
    parameter ADDER_ROW = KERNEL_SIZE*KERNEL_SIZE
) (
    input wire fast_clk,
    input wire rst,
    input wire enable,
    input wire [1:0] kn_size_mode,
    input wire [4:0] channel_NO_in,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 :0] ternery_res_tn,
    output wire [Tn * FEATURE_WIDTH - 1 : 0] kernel_sum_tn_even,
    output wire [Tn * FEATURE_WIDTH - 1 : 0] kernel_sum_tn_odd,
    output wire [KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0] kernel_size_1_out,
    output wire adder_done,
    output wire [4:0] channel_NO_out
);


wire lat_1_enable, lat_2_enable, lat_3_enable, lat_4_enable, lat_5_enable;
register_x1 #(.FEATURE_WIDTH(1)) lat_1(.clk(fast_clk), .rst(rst), .in_data(enable), .o_data(lat_1_enable));
register_x1 #(.FEATURE_WIDTH(1)) lat_2(.clk(fast_clk), .rst(rst), .in_data(lat_1_enable), .o_data(lat_2_enable));
register_x1 #(.FEATURE_WIDTH(1)) lat_3(.clk(fast_clk), .rst(rst), .in_data(lat_2_enable), .o_data(lat_3_enable));
register_x1 #(.FEATURE_WIDTH(1)) lat_4(.clk(fast_clk), .rst(rst), .in_data(lat_3_enable), .o_data(lat_4_enable));
register_x1 #(.FEATURE_WIDTH(1)) lat_5(.clk(fast_clk), .rst(rst), .in_data(lat_4_enable), .o_data(lat_5_enable));
assign adder_done = (kn_size_mode == KERNEL_SIZE_1_MODE) ? lat_1_enable : lat_4_enable;

wire [4:0] lat_1_channel_NO, lat_2_channel_NO, lat_3_channel_NO, lat_4_channel_NO, lat_5_channel_NO;
register_x1 #(.FEATURE_WIDTH(5)) lat_a(.clk(fast_clk), .rst(rst), .in_data(channel_NO_in), .o_data(lat_1_channel_NO));
register_x1 #(.FEATURE_WIDTH(5)) lat_b(.clk(fast_clk), .rst(rst), .in_data(lat_1_channel_NO), .o_data(lat_2_channel_NO));
register_x1 #(.FEATURE_WIDTH(5)) lat_c(.clk(fast_clk), .rst(rst), .in_data(lat_2_channel_NO), .o_data(lat_3_channel_NO));
register_x1 #(.FEATURE_WIDTH(5)) lat_d(.clk(fast_clk), .rst(rst), .in_data(lat_3_channel_NO), .o_data(lat_4_channel_NO));
register_x1 #(.FEATURE_WIDTH(5)) lat_e(.clk(fast_clk), .rst(rst), .in_data(lat_4_channel_NO), .o_data(lat_5_channel_NO));
assign channel_NO_out = (kn_size_mode == KERNEL_SIZE_1_MODE) ? lat_1_channel_NO : lat_4_channel_NO;

/////////////////module connection
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] single_kernel_data_in, single_kernel_data_in_kn1_a, single_kernel_data_in_kn1_b;
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] kernel_size_1_subout;
wire [Tn*FEATURE_WIDTH-1 : 0] kernel_sum_even;
wire [Tn*FEATURE_WIDTH-1 : 0] kernel_sum_odd;
genvar i,j,m;
generate
    for(i=0; i<Tn; i=i+1)begin
        adder_tree_single_kernel_new kernel_adder(
            .fast_clk(fast_clk),
            .rst(rst),
            .kn_size_mode(kn_size_mode),
            .ternery_res(single_kernel_data_in[25*(i+1)*FEATURE_WIDTH-1 : 25*i*FEATURE_WIDTH]),
            .kernel_sum_even(kernel_sum_even[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH]),
            .kernel_sum_odd(kernel_sum_odd[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH]),
            .kernel_size_1_out(kernel_size_1_out[6*(i+1)*FEATURE_WIDTH-1 : 6*i*FEATURE_WIDTH])
        );
    end
    for(j=0; j<25; j=j+1)begin
        assign single_kernel_data_in_kn1_a[4*(j+1)*FEATURE_WIDTH-1 : 4*j*FEATURE_WIDTH]
               = {ternery_res_tn[75*FEATURE_WIDTH+(j+1)*FEATURE_WIDTH-1 : 75*FEATURE_WIDTH+j*FEATURE_WIDTH],
                  ternery_res_tn[50*FEATURE_WIDTH+(j+1)*FEATURE_WIDTH-1 : 50*FEATURE_WIDTH+j*FEATURE_WIDTH],
                  ternery_res_tn[25*FEATURE_WIDTH+(j+1)*FEATURE_WIDTH-1 : 25*FEATURE_WIDTH+j*FEATURE_WIDTH],
                  ternery_res_tn[0*FEATURE_WIDTH+(j+1)*FEATURE_WIDTH-1 : 0*FEATURE_WIDTH+j*FEATURE_WIDTH]};
    end
    for(m=0; m<Tn; m=m+1)begin
        assign single_kernel_data_in_kn1_b[25*(m+1)*FEATURE_WIDTH-1 : 25*m*FEATURE_WIDTH]
               = single_kernel_data_in_kn1_a[24*(m+1)*FEATURE_WIDTH-1 : 24*m*FEATURE_WIDTH];
    end
endgenerate
adder_4in_1out #(FEATURE_WIDTH) kn1_number25 (
    .clk(fast_clk),
    .rst(rst),
    .A1(single_kernel_data_in_kn1_a[97*FEATURE_WIDTH-1 : 96*FEATURE_WIDTH]),
    .B1(single_kernel_data_in_kn1_a[98*FEATURE_WIDTH-1 : 97*FEATURE_WIDTH]),
    .A2(single_kernel_data_in_kn1_a[99*FEATURE_WIDTH-1 : 98*FEATURE_WIDTH]),
    .B2(single_kernel_data_in_kn1_a[100*FEATURE_WIDTH-1 : 99*FEATURE_WIDTH]),
    .O(kernel_size_1_out[25*FEATURE_WIDTH-1 : 24*FEATURE_WIDTH])
);

assign single_kernel_data_in = (kn_size_mode == KERNEL_SIZE_1_MODE) ? single_kernel_data_in_kn1_b : ternery_res_tn;
assign kernel_sum_tn_odd = kernel_sum_odd;
assign kernel_sum_tn_even = kernel_sum_even;

//genvar i;
//generate
//    for(i=0; i<Tn; i=i+1)begin
//        adder_tree_single_kernel_new kernel_adder(
//            .fast_clk(fast_clk),
//            .rst(rst),
//            .kn_size_mode(kn_size_mode),
//            .ternery_res(ternery_res_tn[(i+1)*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : i*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH]),
//            .kernel_sum_even(kernel_sum_tn_even[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH]),
//            .kernel_sum_odd(kernel_sum_tn_odd[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH])
//        );
//    end
//endgenerate

endmodule





module adder_tree_tn #(
    parameter Tn = `Tn,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
) (
    input wire fast_clk,
    input wire rst,
    input wire enable,
    input wire [4:0] channel_NO_in,
    input wire [Tn * FEATURE_WIDTH - 1 :0] tn_input,
    output wire [FEATURE_WIDTH - 1 : 0] out,
    output wire [4:0] channel_NO_out,
    output wire adder_done
);

wire lat_1_enable;
register_x1 #(.FEATURE_WIDTH(1)) lat_1(.clk(fast_clk), .rst(rst), .in_data(enable), .o_data(lat_1_enable));
// register_x1 #(.FEATURE_WIDTH(1)) lat_2(.clk(fast_clk), .rst(rst), .in_data(lat_1_enable), .o_data(lat_2_enable));
// register_x1 #(.FEATURE_WIDTH(1)) lat_3(.clk(fast_clk), .rst(rst), .in_data(lat_2_enable), .o_data(lat_3_enable));
// register_x1 #(.FEATURE_WIDTH(1)) lat_4(.clk(fast_clk), .rst(rst), .in_data(lat_3_enable), .o_data(lat_4_enable));
assign adder_done = lat_1_enable;

register_x1 #(.FEATURE_WIDTH(5)) lat_1_channel(.clk(fast_clk), .rst(rst), .in_data(channel_NO_in), .o_data(channel_NO_out));


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
    input wire [4:0] channel_NO_in,
    output wire [4:0] channel_NO_out,
    output reg [FEATURE_WIDTH+SCALER_WIDTH-1 : 0] data_o
);

register_x1 #(.FEATURE_WIDTH(5)) lat_1_channel(.clk(clk), .rst(rst), .in_data(channel_NO_in), .o_data(channel_NO_out));


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

module N_scaler_multiply_unit #(
    parameter N = 25,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter SCALER_WIDTH = 16
) (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [N*FEATURE_WIDTH-1 : 0] data_in,
    input wire [SCALER_WIDTH-1 : 0] scaler_in,
    input wire [4:0] channel_NO_in,
    output wire [4:0] channel_NO_out,
    output wire [N*FEATURE_WIDTH-1 : 0] data_o
);

register_x1 #(.FEATURE_WIDTH(5)) lat_1_channel(.clk(clk), .rst(rst), .in_data(channel_NO_in), .o_data(channel_NO_out));

genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin
        scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) single_feature_scaling_unit_even (
            .clk(clk),
            .rst(rst),
            .enable(enable),
            .data_in(data_in[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH]),
            .scaler_in(scaler_in[SCALER_WIDTH-1 : 0]),
            .data_o(data_o[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH])
        );
    end
endgenerate
endmodule

module bias_adder #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH 
)(
    input wire clk,
    input wire rst,
    input wire [FEATURE_WIDTH-1:0] feature,
    input wire [FEATURE_WIDTH-1:0] bias,
    input wire [4:0] channel_NO_in,
    output wire [4:0] channel_NO_out,
    output wire [FEATURE_WIDTH-1:0] biased_feature
);

register_x1 #(.FEATURE_WIDTH(5)) lat_1_channel(.clk(clk), .rst(rst), .in_data(channel_NO_in), .o_data(channel_NO_out));

adder_2in_1out #(
  .FEATURE_WIDTH(FEATURE_WIDTH)
  )bias_adder_i(
    .clk(clk),
    .rst(rst),
    .A1 (feature),
    .B1 (bias),
    .O  (biased_feature)  
);

endmodule 

module bias_adder_tree_25 #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH 
)(
    input wire clk,
    input wire rst,
    input wire [25*FEATURE_WIDTH-1 : 0] feature,
    input wire [25*FEATURE_WIDTH-1 : 0] bias,
    input wire [4:0] channel_NO_in,
    output wire [4:0] channel_NO_out,
    output wire [25*FEATURE_WIDTH-1 : 0] biased_feature
);

register_x1 #(.FEATURE_WIDTH(5)) lat_1_channel(.clk(clk), .rst(rst), .in_data(channel_NO_in), .o_data(channel_NO_out));

adder_2Nin_Nout #(.FEATURE_WIDTH(FEATURE_WIDTH), .CHANNEL_NUM(28)) adder_56_in_28_out (
    .fast_clk(clk),
    .rst(rst),
    .A_INPUT(feature),
    .B_INPUT(bias),
    .O_OUTPUT(biased_feature)
);

endmodule
