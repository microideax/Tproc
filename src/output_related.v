`include "network_para.vh"

module output_module #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter BUFFER_NUM = `A_BUFFER_NUM,
    parameter RAM_DEPTH = `A_BUFFER_DEPTH,
    parameter ADDR_WIDTH = $clog2(RAM_DEPTH)
)(
//basic signals
  input wire clk,
  input wire rst,
  input wire cnt_rst,
//information/state
  input wire initial_iteration,
  input wire [15:0] layer_width,
  input wire [1:0] kn_size_mode,
  input wire [7:0] com_type,
  input wire wr_rd_mode,//0:read, 1:write
//enable signal
  input wire [4:0] current_channel_NO, //also used as enable signal
  input wire rd_out_en,
//data
  input wire [BUFFER_NUM*FEATURE_WIDTH-1:0] data_in,
  output wire [BUFFER_NUM*FEATURE_WIDTH-1:0] data_out
);

wire [BUFFER_NUM-1:0] wr_bus, rd_bus;
wire [BUFFER_NUM*ADDR_WIDTH-1:0] addr_bus;
wire [BUFFER_NUM*FEATURE_WIDTH-1:0] data_in_tmp1, data_in_tmp2, data_from_A_buffer;
wire [2*BUFFER_NUM*FEATURE_WIDTH-1:0] data_to_buffer;
wire [7:0] rd_shift, wr_shift, rd_shift_tmp;
wire [BUFFER_NUM*FEATURE_WIDTH-1:0] output_buffer;


accum_buffer_controller A_buffer_controller(
    .clk(clk),
    .rst(rst),
    .buffer_cnt_cln(cnt_rst),
    .layer_width(layer_width),
    .kn_size_mode(kn_size_mode),
    .com_type(com_type),
    .wr_rd_mode(wr_rd_mode),//1:read, 0:write
    .current_channel_NO(current_channel_NO), //used as enable signal
    .rd_en_in(rd_out_en),
    .addr_out(addr_bus),
    .wr_en(wr_bus),
    .rd_en(rd_bus),
    .rd_shift(rd_shift),
    .wr_shift(wr_shift)
);


register_x1 #(.FEATURE_WIDTH(BUFFER_NUM*FEATURE_WIDTH)) data_in_delay_1(.clk(clk), .rst(rst), .in_data(data_in), .o_data(data_in_tmp1));
register_x1 #(.FEATURE_WIDTH(BUFFER_NUM*FEATURE_WIDTH)) data_in_delay_2(.clk(clk), .rst(rst), .in_data(data_in_tmp1), .o_data(data_in_tmp2));

assign data_to_buffer = {data_in_tmp2, data_in_tmp2} << wr_shift*FEATURE_WIDTH;

accumulative_buffer_set A_buffer_set(
    .clk(clk),
    .rst(rst),
    .initial_iteration(initial_iteration),
    .wr_bus(wr_bus),
    .rd_bus(rd_bus),
    .addr_bus(addr_bus),
    .data_in(data_to_buffer[2*BUFFER_NUM*FEATURE_WIDTH-1:BUFFER_NUM*FEATURE_WIDTH]),
    .data_out(data_from_A_buffer)
);

register_x1 #(.FEATURE_WIDTH(8)) data_out_shift_delay(.clk(clk), .rst(rst), .in_data(rd_shift), .o_data(rd_shift_tmp));
//always @(posedge clk or posedge rst) begin
//    if(rst) begin
//        output_buffer <= 0;
//    end else begin
//        output_buffer <= {data_from_A_buffer, data_from_A_buffer} >> rd_shift*FEATURE_WIDTH;
//    end
//end

//tmp design
//assign data_out = output_buffer;
assign data_out = {data_from_A_buffer, data_from_A_buffer} >> rd_shift_tmp*FEATURE_WIDTH;

endmodule


module accumulative_buffer_set #(
  parameter FEATURE_WIDTH = `FEATURE_WIDTH,
  parameter RAM_DEPTH = `A_BUFFER_DEPTH,
  parameter ADDR_WIDTH = $clog2(RAM_DEPTH),
  parameter BUFFER_NUM = `A_BUFFER_NUM
)(
  input wire clk,
  input wire rst,
  input wire initial_iteration,
  input wire [BUFFER_NUM-1:0] wr_bus,
  input wire [BUFFER_NUM-1:0] rd_bus,
  input wire [BUFFER_NUM*ADDR_WIDTH-1:0] addr_bus,
  input wire [BUFFER_NUM*FEATURE_WIDTH-1:0] data_in,
  output wire [BUFFER_NUM*FEATURE_WIDTH-1:0] data_out
);


genvar i;
generate
    for (i = 0; i < 25; i=i+1) begin
        accumulative_buffer_unit A_buffer (
            .clk(clk),
            .rst(rst),
            .wr(wr_bus[i]),
            .rd(rd_bus[i]),
            .initial_iteration(initial_iteration),
            .addr(addr_bus[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH]),
            .data_in(data_in[(i+1)*FEATURE_WIDTH-1:i*FEATURE_WIDTH]),
            .data_out(data_out[(i+1)*FEATURE_WIDTH-1:i*FEATURE_WIDTH])
        );
    end
endgenerate

endmodule




module accum_buffer_controller #(
  //buffer configuration
  parameter RAM_DEPTH = `A_BUFFER_DEPTH,
  parameter ADDR_WIDTH = $clog2(RAM_DEPTH),
  parameter BUFFER_NUM = `A_BUFFER_NUM,
  //global
  parameter Tm = `Tm,
  parameter Tn = `Tn,
  parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
  parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE,
  parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE,
  //local
  parameter CONV_5 = 0,
  parameter CONV_3 = 1,
  parameter DW_5 = 2,
  parameter DW_3 = 3,
  parameter CONV_PW = 4,
  parameter RD_MODE = 5
)(
  input wire clk,
  input wire rst,
  input wire buffer_cnt_cln,

  input wire [15:0] layer_width,
  input wire [1:0] kn_size_mode,
  input wire [7:0] com_type,
  input wire wr_rd_mode,//0:read, 1:write

  input wire [4:0] current_channel_NO, //also used as enable signal
  input wire rd_en_in,

  output reg [BUFFER_NUM*ADDR_WIDTH-1:0] addr_out,
  output reg [BUFFER_NUM-1:0] wr_en,
  output reg [BUFFER_NUM-1:0] rd_en,
  output reg [7:0] rd_shift,
  output reg [7:0] wr_shift
);

reg [15:0] input_counter;
reg wr_en_flag, rd_en_flag;
always @(posedge clk or posedge rst) begin : proc_
    if(rst) begin
        input_counter <= 0 - 1;
        wr_en_flag <= 0;
        rd_en_flag <= 0;
    end else begin
        input_counter <= (buffer_cnt_cln) ? 0 - 1
                       : (wr_rd_mode == 1 && current_channel_NO != 0) ? (input_counter + 1)
                       : (wr_rd_mode == 0 && rd_en_in == 1) ? (input_counter + 1)
                       : input_counter;
        wr_en_flag <= (current_channel_NO != 0) ? 1 : 0;
        rd_en_flag <= rd_en_in;
    end
end

//mode select
wire [2:0] mode_sel;
assign mode_sel = (kn_size_mode == KERNEL_SIZE_5_MODE && com_type == 8'h01 && wr_rd_mode == 1) ? CONV_5 //kns=5, normal conv
                : (kn_size_mode == KERNEL_SIZE_3_MODE && com_type == 8'h01 && wr_rd_mode == 1) ? CONV_3 //kns=3, normal conv
                : (kn_size_mode == KERNEL_SIZE_5_MODE && com_type == 8'h02 && wr_rd_mode == 1) ? DW_5 //kns=5, dw conv
                : (kn_size_mode == KERNEL_SIZE_3_MODE && com_type == 8'h02 && wr_rd_mode == 1) ? DW_3 //kns=3, dw conv
                : (kn_size_mode == KERNEL_SIZE_1_MODE && com_type == 8'h01 && wr_rd_mode == 1) ? CONV_PW //pw conv
                : (wr_rd_mode == 0) ? RD_MODE
                : 0; //default
//some parameter used
wire [3:0] total_channel_num, channel_NO_conv;
wire [7:0] buffer_area_num_per_line;
wire [7:0] row_NO_conv, row_NO_DWconv, col_NO_conv, col_NO_DWconv, col_NO_PW;
wire [3:0] total_row_num;
assign total_row_num = (kn_size_mode == KERNEL_SIZE_3_MODE) ? 4 : 5;
assign total_channel_num = (com_type == 8'h01) ? Tm //conv
                         : (com_type == 8'h02) ? Tn //dw conv
                         : 8;//default
assign buffer_area_num_per_line = (layer_width%25 == 0) ? layer_width/25 : layer_width/25 + 1;
assign channel_NO_conv = input_counter%8;
assign row_NO_conv = (input_counter/8)/layer_width;
assign col_NO_conv = (input_counter/8)%layer_width;
assign row_NO_DWconv = input_counter/layer_width;
assign col_NO_DWconv = input_counter%layer_width;
assign col_NO_PW = (input_counter/8)*5;

wire [7:0] buffer_index_Conv5, buffer_index_even_Conv3, buffer_index_odd_Conv3;
wire [ADDR_WIDTH-1:0] addr_single_Conv5, addr_single_even_Conv3, addr_single_odd_Conv3;
wire [7:0] wr_shift_Conv5, wr_shift_Conv3, wr_shift_DW5, wr_shift_DW3, wr_shift_PW;

//C5
assign buffer_index_Conv5 = col_NO_conv%25;
assign addr_single_Conv5 = channel_NO_conv + col_NO_conv/25*Tm + row_NO_conv*buffer_area_num_per_line*Tm;
assign wr_shift_Conv5 = buffer_index_Conv5;

//C3
assign buffer_index_even_Conv3 = col_NO_conv%25;
assign buffer_index_odd_Conv3 = (col_NO_conv+1)%25;
assign addr_single_even_Conv3 = channel_NO_conv + col_NO_conv/25*Tm + row_NO_conv*buffer_area_num_per_line*Tm*2;
assign addr_single_odd_Conv3 = addr_single_even_Conv3 + buffer_area_num_per_line*Tm;
assign wr_shift_Conv3 = buffer_index_even_Conv3;

//DW5
//wire [2*BUFFER_NUM-1:0] wr_en_DW5;
//wire [2*BUFFER_NUM*ADDR_WIDTH-1:0] addr_DW5;
//wire [ADDR_WIDTH-1:0] addr_shift_DW5;
//assign buffer_index_shift = input_counter%25;
//assign addr_shift_DW5 = input_counter/25*4;
//assign wr_en_DW5 = {25'b1111, 25'b1111} << buffer_index_shift;
//assign addr_DW5 = {168'b, addr_shift_DW5+3, addr_shift_DW5+2, addr_shift_DW5+1, addr_shift_DW5,
//                   168'b, addr_shift_DW5+3, addr_shift_DW5+2, addr_shift_DW5+1, addr_shift_DW5} << buffer_index_shift*8;

//new DW5
wire [2*BUFFER_NUM-1:0] wr_en_DW5;
wire [ADDR_WIDTH-1:0] addr_bias_macro_DW5, addr_bias_micro_DW5, addr_bias_DW5;
wire [2*BUFFER_NUM*ADDR_WIDTH-1:0] addr_DW5;
assign wr_en_DW5 = {21'h0, 4'hf, 21'h0, 4'hf} << wr_shift_DW5;
assign addr_bias_macro_DW5 = row_NO_DWconv*(buffer_area_num_per_line*Tn);
assign addr_bias_micro_DW5 = (col_NO_DWconv/25)*Tn;
assign addr_bias_DW5 = addr_bias_macro_DW5+addr_bias_micro_DW5;
assign addr_DW5 = {168'b0, 8'd3+addr_bias_DW5, 8'd2+addr_bias_DW5, 8'd1+addr_bias_DW5, 8'd0+addr_bias_DW5,
                  168'b0, 8'd3+addr_bias_DW5, 8'd2+addr_bias_DW5, 8'd1+addr_bias_DW5, 8'd0+addr_bias_DW5
                  } << wr_shift_DW5*ADDR_WIDTH;
assign wr_shift_DW5 = col_NO_DWconv%25;

//DW3
wire [2*BUFFER_NUM-1:0] wr_en_DW3;
wire [ADDR_WIDTH-1:0] addr_bias_macro_DW3, addr_bias_micro_DW3, addr_bias_DW3_e, addr_bias_DW3_o;
wire [2*BUFFER_NUM*ADDR_WIDTH-1:0] addr_DW3;
assign wr_en_DW3 = {17'h0, 8'hff, 17'h0, 8'hff} << wr_shift_DW3;
assign addr_bias_macro_DW3 = row_NO_DWconv*(buffer_area_num_per_line*2*Tn);
assign addr_bias_micro_DW3 = (col_NO_DWconv/25)*Tn;
assign addr_bias_DW3_e = addr_bias_macro_DW3+addr_bias_micro_DW3;
assign addr_bias_DW3_o = addr_bias_macro_DW3+addr_bias_micro_DW3+buffer_area_num_per_line*Tn;
assign addr_DW3 = {136'b0, 8'd3+addr_bias_DW3_o, 8'd2+addr_bias_DW3_o, 8'd1+addr_bias_DW3_o, 8'd0+addr_bias_DW3_o, 8'd3+addr_bias_DW3_e, 8'd2+addr_bias_DW3_e, 8'd1+addr_bias_DW3_e, 8'd0+addr_bias_DW3_e,
                  136'b0, 8'd3+addr_bias_DW3_o, 8'd2+addr_bias_DW3_o, 8'd1+addr_bias_DW3_o, 8'd0+addr_bias_DW3_o, 8'd3+addr_bias_DW3_e, 8'd2+addr_bias_DW3_e, 8'd1+addr_bias_DW3_e, 8'd0+addr_bias_DW3_e
                  } << wr_shift_DW3*ADDR_WIDTH;
assign wr_shift_DW3 = col_NO_DWconv%25;

//PW
//only for Tc=5, if Tc>5, the design should change
//shift hasn't been set
wire [BUFFER_NUM*ADDR_WIDTH-1:0] addr_PW;
wire [5*ADDR_WIDTH-1:0] basic_addr_toshift_PW;
wire [10*ADDR_WIDTH-1:0] basic_addr_PW;
wire [ADDR_WIDTH-1:0] addr_bias_macro_PW, addr_bias_micro_PW, addr_bias_PW;
//assign addr_bias_micro_PW = channel_NO_conv;
//assign addr_bias_macro_PW = (input_counter/40)*8;
//assign addr_bias_PW = addr_bias_macro_PW + addr_bias_micro_PW;
assign addr_bias_PW = channel_NO_conv + col_NO_PW/25*Tm;
genvar i;
generate
    for (i = 0; i < 5; i = i + 1) begin
        assign basic_addr_toshift_PW[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH] = i*buffer_area_num_per_line*Tm + addr_bias_PW;
    end
endgenerate
//assign basic_addr_toshift_PW = {8'd32+addr_bias_PW, 8'd24+addr_bias_PW, 8'd16+addr_bias_PW, 8'd8+addr_bias_PW, 8'd0+addr_bias_PW};
assign basic_addr_PW = {basic_addr_toshift_PW, basic_addr_toshift_PW} << (wr_shift_PW/5)*ADDR_WIDTH;
assign addr_PW = {basic_addr_PW[10*ADDR_WIDTH-1:9*ADDR_WIDTH], basic_addr_PW[10*ADDR_WIDTH-1:9*ADDR_WIDTH], basic_addr_PW[10*ADDR_WIDTH-1:9*ADDR_WIDTH], basic_addr_PW[10*ADDR_WIDTH-1:9*ADDR_WIDTH], basic_addr_PW[10*ADDR_WIDTH-1:9*ADDR_WIDTH],
                  basic_addr_PW[9*ADDR_WIDTH-1:8*ADDR_WIDTH], basic_addr_PW[9*ADDR_WIDTH-1:8*ADDR_WIDTH], basic_addr_PW[9*ADDR_WIDTH-1:8*ADDR_WIDTH], basic_addr_PW[9*ADDR_WIDTH-1:8*ADDR_WIDTH], basic_addr_PW[9*ADDR_WIDTH-1:8*ADDR_WIDTH],
                  basic_addr_PW[8*ADDR_WIDTH-1:7*ADDR_WIDTH], basic_addr_PW[8*ADDR_WIDTH-1:7*ADDR_WIDTH], basic_addr_PW[8*ADDR_WIDTH-1:7*ADDR_WIDTH], basic_addr_PW[8*ADDR_WIDTH-1:7*ADDR_WIDTH], basic_addr_PW[8*ADDR_WIDTH-1:7*ADDR_WIDTH],
                  basic_addr_PW[7*ADDR_WIDTH-1:6*ADDR_WIDTH], basic_addr_PW[7*ADDR_WIDTH-1:6*ADDR_WIDTH], basic_addr_PW[7*ADDR_WIDTH-1:6*ADDR_WIDTH], basic_addr_PW[7*ADDR_WIDTH-1:6*ADDR_WIDTH], basic_addr_PW[7*ADDR_WIDTH-1:6*ADDR_WIDTH],
                  basic_addr_PW[6*ADDR_WIDTH-1:5*ADDR_WIDTH], basic_addr_PW[6*ADDR_WIDTH-1:5*ADDR_WIDTH], basic_addr_PW[6*ADDR_WIDTH-1:5*ADDR_WIDTH], basic_addr_PW[6*ADDR_WIDTH-1:5*ADDR_WIDTH], basic_addr_PW[6*ADDR_WIDTH-1:5*ADDR_WIDTH]};
assign wr_shift_PW = col_NO_PW%25;

//RD
wire [ADDR_WIDTH-1:0] basic_addr_RD;
wire [BUFFER_NUM*ADDR_WIDTH-1:0] addr_RD;
wire [7:0] channel_select, buffer_area_select, row_select, index_shift_RD;
assign channel_select = input_counter/(buffer_area_num_per_line*total_row_num);
assign row_select = input_counter/buffer_area_num_per_line%total_row_num;
assign buffer_area_select = input_counter%buffer_area_num_per_line;
assign basic_addr_RD = channel_select + buffer_area_select*total_channel_num + row_select*buffer_area_num_per_line*total_channel_num;
assign addr_RD = {basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD,
                        basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD,
                        basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD,
                        basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD,
                        basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD, basic_addr_RD};
assign index_shift_RD = (kn_size_mode == KERNEL_SIZE_5_MODE && com_type == 8'h01 && wr_rd_mode == 0) ? 0 //index_shift_RD_Conv5
                      : (kn_size_mode == KERNEL_SIZE_3_MODE && com_type == 8'h01 && wr_rd_mode == 0) ? (row_select%2) //index_shift_RD_Conv3
                      : (kn_size_mode == KERNEL_SIZE_5_MODE && com_type == 8'h02 && wr_rd_mode == 0) ? (channel_select%4) //index_shift_RD_DW5
                      : (kn_size_mode == KERNEL_SIZE_3_MODE && com_type == 8'h02 && wr_rd_mode == 0) ? (channel_select%4 + (row_select%2)*4) //index_shift_RD_DW3
                      : (kn_size_mode == KERNEL_SIZE_1_MODE && com_type == 8'h01 && wr_rd_mode == 0) ? ((row_select%5)*5) //index_shift_RD_PW
                      : 0;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        addr_out <= 0;
        wr_en <= 0;
        rd_en <= 0;
        wr_shift <= 0;
        rd_shift <= 0;
    end else begin
        case (mode_sel)
            CONV_5 : begin
                wr_en <= (wr_en_flag) ? 25'b1 << buffer_index_Conv5 : 0;
                rd_en <= 0;
                addr_out <= addr_single_Conv5 << (buffer_index_Conv5*ADDR_WIDTH);
                wr_shift <= wr_shift_Conv5;
                rd_shift <= 0;
            end // CONV_5
            CONV_3 : begin
                wr_en <= (wr_en_flag) ? ((25'b1 << buffer_index_even_Conv3) + (25'b1 << buffer_index_odd_Conv3)) : 0;
                rd_en <= 0;
                addr_out <= (addr_single_even_Conv3 << (buffer_index_even_Conv3*ADDR_WIDTH)) + (addr_single_odd_Conv3 << (buffer_index_odd_Conv3*ADDR_WIDTH));
                wr_shift <= wr_shift_Conv3;
                rd_shift <= 0;
            end // CONV_3
            DW_5 : begin
                wr_en <= (wr_en_flag) ? wr_en_DW5[2*BUFFER_NUM-1:BUFFER_NUM] : 0;
                rd_en <= 0;
                addr_out <= addr_DW5[2*BUFFER_NUM*ADDR_WIDTH-1:BUFFER_NUM*ADDR_WIDTH];
                wr_shift <= wr_shift_DW5;
                rd_shift <= 0;
            end // DW_5
            DW_3 : begin
                wr_en <= (wr_en_flag) ? wr_en_DW3[2*BUFFER_NUM-1:BUFFER_NUM] : 0;
                rd_en <= 0;
                addr_out <= addr_DW3[2*BUFFER_NUM*ADDR_WIDTH-1:BUFFER_NUM*ADDR_WIDTH];
                wr_shift <= wr_shift_DW3;
                rd_shift <= 0;
            end // DW_3
            CONV_PW : begin
                wr_en <= (wr_en_flag) ? 25'h1ffffff : 0;
                rd_en <= 0;
                addr_out <= addr_PW;
                wr_shift <= wr_shift_PW;//TODO!!!!!!!!!!!
                rd_shift <= 0;
            end // CONV_PW
            RD_MODE : begin
                wr_en <= 0;
                rd_en <= (rd_en_flag) ? 25'h1ffffff : 0;
                addr_out <= addr_RD;
                wr_shift <= 0;
                rd_shift <= index_shift_RD;
            end // RD_MODE
            default : begin
                wr_en <= 0;
                addr_out <= 0;
                rd_en <= 0;
                wr_shift <= 0;
                rd_shift <= 0;
            end
        endcase
    end
end

endmodule



module accumulative_buffer_unit #(
  parameter FEATURE_WIDTH = `FEATURE_WIDTH, 
  parameter RAM_DEPTH = `A_BUFFER_DEPTH,
  parameter ADDR_WIDTH = $clog2(RAM_DEPTH)
)(
  input wire clk,
  input wire rst,
  input wire wr,
  input wire rd,
  input wire initial_iteration,
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [FEATURE_WIDTH-1:0] data_in,
  output wire [FEATURE_WIDTH-1:0] data_out
);

wire wr_tmp, wr_tmp_2, rd_tmp;
wire ena, enb, wea;
wire [ADDR_WIDTH-1:0] addra, addrb, addr_tmp, addr_tmp2;
wire [FEATURE_WIDTH-1:0] data_in_tmp, dia, dob;
reg [FEATURE_WIDTH-1:0] add_result;

register_x1 #(.FEATURE_WIDTH(FEATURE_WIDTH)) data_in_delay(.clk(clk), .rst(rst), .in_data(data_in), .o_data(data_in_tmp));
register_x1 #(.FEATURE_WIDTH(1)) wr_delay(.clk(clk), .rst(rst), .in_data(wr), .o_data(wr_tmp));
register_x1 #(.FEATURE_WIDTH(1)) wr_delay_2(.clk(clk), .rst(rst), .in_data(wr_tmp), .o_data(wr_tmp_2));
register_x1 #(.FEATURE_WIDTH(1)) rd_delay(.clk(clk), .rst(rst), .in_data(rd), .o_data(rd_tmp));
register_x1 #(.FEATURE_WIDTH(ADDR_WIDTH)) addr_delay(.clk(clk), .rst(rst), .in_data(addr), .o_data(addr_tmp));
register_x1 #(.FEATURE_WIDTH(ADDR_WIDTH)) addr_delay_2(.clk(clk), .rst(rst), .in_data(addr_tmp), .o_data(addr_tmp2));


//wr:a  rd:b
assign enb = rd | wr;
assign addrb = addr;

assign ena = wr_tmp_2;
assign wea = wr_tmp_2;
assign dia = add_result;
assign addra = addr_tmp2;

always @(posedge clk or posedge rst) begin
  if(rst) begin
    add_result <= 0;
  end else begin
    add_result <= (initial_iteration) ? data_in_tmp : data_in_tmp + dob;
  end
end

//a -- input port; b -- output port;
dp_ram #(RAM_DEPTH, ADDR_WIDTH, FEATURE_WIDTH) single_buffer(
    .clk(clk),
    .ena(ena),
    .enb(enb),
    .wea(wea),
    .rst(rst),
    .addra(addra),
    .addrb(addrb),
    .dia(dia),
    .dob(dob)
    );

assign data_out = rd_tmp ? dob : 0;

endmodule