// virtical_reg used to buffer the input data for the select_array 

/*
vertical_reg_output format:
addr:   0   1   2   3   4   5   6   ...  kernel_size^2+0 ... Tn*kernel_size^2-1 
data:  a00 a10 a20 a30 a40 a01 a02  ...        b00       ...         d44
a10: pixel value of group a, line 1, column 0
*/

`include "network_para.vh"

module vertical_reg #(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_SIZE_3 = `KERNEL_SIZE_3,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
    parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE,
    parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE
)(
    input wire clk,
    input wire rst,
    input wire [3:0] com_type,
    input wire [7:0] kernel_size,
    input wire [1:0] kn_size_mode,
    input wire enable,
    input wire in_select,
    input wire shift_mod,
    output reg feature_en_0,
    output reg feature_en_1,

    input wire [Tn*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] dia_0,
    input wire [Tn*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] dia_1,
    output wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] doa,
    output wire shift_done
);

wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] d_temp;

reg [KERNEL_SIZE-2 : 0] counter;
reg shift_done_flag, vir_reg_done, d_temp_select_0_tmp, d_temp_select_1_tmp, d_temp_select_0, d_temp_select_1;
wire enable_flag, counter_empty_n;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter <= 0;
    end else begin
        counter <= (kn_size_mode == KERNEL_SIZE_5_MODE) ? {counter[KERNEL_SIZE-3 : 0], (enable & (!shift_mod))}
                 : (kn_size_mode == KERNEL_SIZE_3_MODE) ? {2'b0, counter[KERNEL_SIZE_3-3 : 0], (enable & (!shift_mod))}
                 : {counter[KERNEL_SIZE-3 : 0], (enable & (!shift_mod))};
    end
end

assign counter_empty_n = |counter;
assign enable_flag = counter_empty_n | enable;


always@(posedge clk) begin
    if(rst) begin
        feature_en_0 <= 0;
        feature_en_1 <= 0;
        //d_temp_select_0_tmp <= 0;
        //d_temp_select_1_tmp <= 0;
        d_temp_select_0 <= 0;
        d_temp_select_1 <= 0;
        shift_done_flag <= 0;
        vir_reg_done <= 0;
    end
    else begin
        feature_en_0 <= (enable & ~in_select) | (feature_en_0 & counter_empty_n);
        feature_en_1 <= (enable & in_select) | ((feature_en_1 & counter_empty_n));
        //d_temp_select_0_tmp <= enable & ~in_select;
        //d_temp_select_1_tmp <= enable & in_select;
        d_temp_select_0 <= feature_en_0;
        d_temp_select_1 <= feature_en_1;
        shift_done_flag <= (feature_en_0 | feature_en_1) & (~enable_flag);
        vir_reg_done <= shift_done_flag;
    end
end

assign shift_done = vir_reg_done;

//always@(posedge clk) begin
//    if (feature_en_0|feature_en_1) begin
//        d_temp_0[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] <= {d_temp_0[Tn*KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], dia_0};
//        d_temp_1[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] <= {d_temp_1[Tn*KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], dia_1};
//    end
//    else begin
//        d_temp_0 <= d_temp_0;
//        d_temp_1 <= d_temp_1;
//    end
//end
//
//assign doa[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] = vir_reg_done ? d_temp_1[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] : d_temp_0[Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0];


genvar i;
generate
    for (i = 0; i < Tn; i = i + 1) begin
        shift_reg i_shift_reg(
            .clk            (clk),
            .rst            (rst),
            .d_temp_select_0(d_temp_select_0),
            .d_temp_select_1(d_temp_select_1),
            .kn_size_mode   (kn_size_mode),
            .sub_dia_0      (dia_0[(i+1)*KERNEL_SIZE*FEATURE_WIDTH - 1 : i*KERNEL_SIZE*FEATURE_WIDTH]),
            .sub_dia_1      (dia_1[(i+1)*KERNEL_SIZE*FEATURE_WIDTH - 1 : i*KERNEL_SIZE*FEATURE_WIDTH]),
            .sub_d_temp     (d_temp[(i+1)*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : i*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH])
            );
    end
endgenerate


assign doa = d_temp;

endmodule


module shift_reg #(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
    parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE,
    parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE,
    parameter KERNEL_SIZE_3 = `KERNEL_SIZE_3,
    parameter KERNEL_3_BITS = KERNEL_SIZE_3*KERNEL_SIZE_3*FEATURE_WIDTH
)(
    input wire clk,
    input wire rst,
    input wire d_temp_select_0,
    input wire d_temp_select_1,
    input wire [1:0] kn_size_mode,
    input wire [KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] sub_dia_0,
    input wire [KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] sub_dia_1,
    output reg [KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] sub_d_temp
);

wire [KERNEL_SIZE_3*FEATURE_WIDTH - 1 : 0] sub_dia_0_kn3_a, sub_dia_0_kn3_b, sub_dia_1_kn3_a, sub_dia_1_kn3_b;
wire [KERNEL_3_BITS - 1 : 0] sub_d_temp_a, sub_d_temp_b;

assign sub_dia_0_kn3_a = sub_dia_0[KERNEL_SIZE_3*FEATURE_WIDTH - 1 : 0];
assign sub_dia_0_kn3_b = sub_dia_0[(KERNEL_SIZE_3+1)*FEATURE_WIDTH - 1 : FEATURE_WIDTH];
assign sub_dia_1_kn3_a = sub_dia_1[KERNEL_SIZE_3*FEATURE_WIDTH - 1 : 0];
assign sub_dia_1_kn3_b = sub_dia_1[(KERNEL_SIZE_3+1)*FEATURE_WIDTH - 1 : FEATURE_WIDTH];

assign sub_d_temp_a = sub_d_temp[KERNEL_3_BITS - 1 : 0];
assign sub_d_temp_b = sub_d_temp[2*KERNEL_3_BITS - 1 : KERNEL_3_BITS];

always@(posedge clk or posedge rst) begin
    if (rst) begin
        sub_d_temp <= 0;
    end
    else begin
        case (kn_size_mode)
            KERNEL_SIZE_5_MODE : begin
                sub_d_temp <= (d_temp_select_0 == 1) ? {sub_d_temp[KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], sub_dia_0}
                            : (d_temp_select_1 == 1) ? {sub_d_temp[KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], sub_dia_1}
                            : sub_d_temp;
            end
            KERNEL_SIZE_3_MODE : begin
                sub_d_temp[KERNEL_3_BITS - 1 : 0] <= (d_temp_select_0 == 1) ? {sub_d_temp_a[KERNEL_SIZE_3*(KERNEL_SIZE_3-1)*FEATURE_WIDTH-1 : 0], sub_dia_0_kn3_a}
                                                   : (d_temp_select_1 == 1) ? {sub_d_temp_a[KERNEL_SIZE_3*(KERNEL_SIZE_3-1)*FEATURE_WIDTH-1 : 0], sub_dia_1_kn3_a}
                                                   : sub_d_temp[KERNEL_3_BITS - 1 : 0];
                sub_d_temp[2*KERNEL_3_BITS - 1 : KERNEL_3_BITS] <= (d_temp_select_0 == 1) ? {sub_d_temp_b[KERNEL_SIZE_3*(KERNEL_SIZE_3-1)*FEATURE_WIDTH-1 : 0], sub_dia_0_kn3_b}
                                                                 : (d_temp_select_1 == 1) ? {sub_d_temp_b[KERNEL_SIZE_3*(KERNEL_SIZE_3-1)*FEATURE_WIDTH-1 : 0], sub_dia_1_kn3_b}
                                                                 : sub_d_temp[2*KERNEL_3_BITS - 1 : KERNEL_3_BITS];
                sub_d_temp[KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 2*KERNEL_3_BITS] <= 0;
                                                
            end
            KERNEL_SIZE_1_MODE : begin
                sub_d_temp <= (d_temp_select_0 == 1) ? {sub_d_temp[KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], sub_dia_0}
                            : (d_temp_select_1 == 1) ? {sub_d_temp[KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], sub_dia_1}
                            : sub_d_temp;
            end
            default : sub_d_temp <= (d_temp_select_0 == 1) ? {sub_d_temp[KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], sub_dia_0}
                                  : (d_temp_select_1 == 1) ? {sub_d_temp[KERNEL_SIZE*(KERNEL_SIZE-1)*FEATURE_WIDTH-1 : 0], sub_dia_1}
                                  : sub_d_temp;
        endcase
    end
end  

endmodule





module reorder_weight #(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH
)(
    input clk,
    input rst,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ] weight_in,
    output wire [Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ] weight_out
);

wire [KERNEL_WIDTH - 1 : 0] weight_in_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [KERNEL_WIDTH - 1 : 0] weight_out_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

genvar i;
generate
    for(i = 0; i < Tn * KERNEL_SIZE * KERNEL_SIZE; i = i+1) begin: weight_vertical_reg
        assign weight_in_wire[i] = weight_in[(i+1)*KERNEL_WIDTH-1:i*KERNEL_WIDTH];
        assign weight_out_wire[i] = weight_in_wire[25*(i/5%4) + 5*(i%5) + i/20];
        assign weight_out[(i+1)*KERNEL_WIDTH-1 : i*KERNEL_WIDTH] = weight_out_wire[i];
    end
endgenerate

endmodule

module reorder_feature #(
    parameter Tn = `Tn,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_width = `KERNEL_SIZE
)(
    input clk,
    input rst,
    input wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ] feature_in,
    output wire [Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ] feature_out
);

wire [FEATURE_WIDTH - 1 : 0] feature_in_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [FEATURE_WIDTH - 1 : 0] feature_out_wire [Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];

genvar i;
generate
    for(i = 0; i < Tn * KERNEL_SIZE * KERNEL_SIZE; i = i+1) begin: feature_vertical_reg
        assign feature_in_wire[i] = feature_in[(i+1)*FEATURE_WIDTH-1:i*FEATURE_WIDTH];
        assign feature_out_wire[i] = feature_in_wire[(i%25/5) + 5 * (i/25) + 20 * (i%5)];
        assign feature_out[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH] = feature_out_wire[i];
    end
endgenerate

endmodule


