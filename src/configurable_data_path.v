// configurable adder path
// CONV/DWCONV/PWCONV are achieved with different data path configuration
// Tm should always larger than Tn

`include "network_para.vh"

module configurable_data_path #(
    parameter Tn = `Tn,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter SCALER_WIDTH = `SCALER_WIDTH,
    parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
    parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE,
    parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE,
    parameter Tm = `Tm
) (
    input wire clk,
    input wire rst,

    input wire config_enable,
    input wire config_clear,//temporally replaced by conv_done
    input wire [3:0] kernel_size,
    
    input wire [7:0] com_type,
    input wire [1:0] kn_size_mode,
    input wire [15:0] layer_width,
    input wire wr_rd_mode,
    input wire A_buffer_cnt_rst,
    input wire initial_iteration,
    input wire A_buffer_read_en,

    input wire vertical_shift_mod,
    input wire virtical_reg_shift,
    input wire virreg_input_sel, // from instruction decoder
    output wire virreg_to_fmem_0, 
    output wire virreg_to_fmem_1,
    input wire [Tn*FEATURE_WIDTH*KERNEL_SIZE - 1 : 0] feature_mem_read_data_0,
    input wire [Tn*FEATURE_WIDTH*KERNEL_SIZE - 1 : 0] feature_mem_read_data_1,
    output wire shift_done_from_virreg,

    input wire [Tn*KERNEL_SIZE*KERNEL_SIZE*KERNEL_WIDTH-1 : 0] weight_wire,
    output reg [15:0] weight_addr,
    output reg weight_read_en,
    
    input wire [15:0] scaler_data,
    output reg [15:0] scaler_addr,
    output wire scaler_buffer_rd_en,
    //output wire [Tm* FEATURE_WIDTH + SCALER_WIDTH-1 : 0] scaled_feature_output,

    input wire [FEATURE_WIDTH - 1 : 0] bias_data,
    output reg [15:0] bias_addr,
    output wire bias_buffer_rd_en,

    output wire compute_done
);

// wire shift_done_from_virreg;
// assign shift_done_from_virreg = shift_done_from_virreg;

//configure part
reg [7 : 0] com_type_reg;
always@(posedge clk or posedge rst) begin
  if(rst) begin
    com_type_reg <= 8'h00;
  end 
  else begin
    if(config_enable)begin
      com_type_reg <= com_type;
    end else if(compute_done) begin // use compute_done temporally
      com_type_reg <= 8'h00;
    end  else begin
      com_type_reg <= com_type_reg;
    end
  end
end

//wire virreg_to_fmem_0;
//wire virreg_to_fmem_1;
wire [Tn*FEATURE_WIDTH*KERNEL_SIZE*KERNEL_SIZE - 1 : 0] vertical_reg_to_select_array;
//reg [Tn*FEATURE_WIDTH*KERNEL_SIZE*KERNEL_SIZE - 1 : 0] vertical_data_reg;
wire [Tm*FEATURE_WIDTH - 1 : 0] tm_scaled_feature;
wire [Tm*16-1 : 0] scaler_reg;

vertical_reg i_vertical_reg(
    .clk(clk),
    .rst(rst),
    .com_type(),
    .kernel_size(),
    .shift_mod(vertical_shift_mod),
    .enable(virtical_reg_shift),
    .in_select(virreg_input_sel),
    .kn_size_mode(kn_size_mode),
    .feature_en_0(virreg_to_fmem_0),
    .feature_en_1(virreg_to_fmem_1),
    .dia_0(feature_mem_read_data_0),
    .dia_1(feature_mem_read_data_1),
    .doa(vertical_reg_to_select_array),
    .shift_done(shift_done_from_virreg)
);

//always@(posedge clk) begin
//  if(rst) begin
//    vertical_data_reg <= 0;
//  end
//  else begin
//    if(shift_done_from_virreg) begin
//      vertical_data_reg <= vertical_reg_to_select_array;
//    end else begin
//      vertical_data_reg <= vertical_data_reg;
//    end
//  end
//end

// virtical_reg w_virtical_reg();
reg [4:0] out_channel_counter;
wire [4:0] out_channel_counter_flag;
reg feature_ready_flag;

always@(posedge clk) begin
  if(rst) begin
    feature_ready_flag <= 1'b0;
  end else begin
    if(shift_done_from_virreg) begin
        feature_ready_flag <= 1'b1;
    end 
    else begin
      case (com_type_reg)
        8'h01: feature_ready_flag <= (out_channel_counter == (Tm-1)) ? 1'b0 : feature_ready_flag;
        8'h02: feature_ready_flag <= 1'b0;
        default : feature_ready_flag <= feature_ready_flag;
      endcase
    end      
      //else if(out_channel_counter == (Tm-1)) begin
      //  feature_ready_flag <= 1'b0;
      //end    
  end
end

reg sel_array_enable;
reg [4:0] tern_com_channel_NO_in;
always@(posedge clk)begin
    if(rst)begin
        out_channel_counter <= 5'h00;
        weight_read_en <= 1'b0;
    end
    else begin
      case(com_type_reg)
        8'h01: begin //CONV = select_array -> kernel adder tree -> channel adder tree -> scaler_mult => single output
            if(feature_ready_flag)begin
              weight_addr <= out_channel_counter;
              weight_read_en <= 1'b1;
              out_channel_counter <= out_channel_counter + 1'b1;
            end else begin
              weight_addr <= 0;
              weight_read_en <= 0;
              out_channel_counter <=0;
            end
        end
        8'h02: begin // DWCONV => select array -> kernel adder tree -> scaler_mult => Tn output
            if(feature_ready_flag)begin
              weight_addr <= out_channel_counter;
              weight_read_en <= 1'b1;
              out_channel_counter <= 1'b1;//output channel only count once
            end else begin
              weight_addr <= 0;
              weight_read_en <= 0;
              out_channel_counter <=0;
            end
        end
        8'h04: begin // PWCONV => select array -> channel adder tree -> scaler_mult => single output
            weight_read_en <= 1'b0;
        end
        default: begin
          weight_read_en <= 1'b0;
        end
        endcase
      end
end

//time sequence: +0 clk -- weight_read_en/out_channel_counter    +1 clk -- weight_in/tern_com_channel_NO_in/sel_array_enable

////////termary_select_array////////
always@(posedge clk)begin
  if(rst) begin
    sel_array_enable <= 1'b0;
    tern_com_channel_NO_in <= 0;
  end
  else begin
    sel_array_enable <= weight_read_en;
    tern_com_channel_NO_in <= out_channel_counter;
  end
end
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] ternary_com_out;
wire [4:0] tern_com_channel_NO_out;
wire ternary_com_done;
TnKK_select_array ternary_com_array(
    .clk(clk),
    .rst(rst),
    .feature_in(vertical_reg_to_select_array),
    .weight_in(weight_wire),
    .kn_size_mode(kn_size_mode),
    .enable(sel_array_enable),
    .channel_NO_in(tern_com_channel_NO_in),
    .channel_NO_out(tern_com_channel_NO_out),
    .feature_out(ternary_com_out),
    .ternary_com_done(ternary_com_done)
);

////////just for simulation////////
//wire [FEATURE_WIDTH - 1 : 0] ternary_in_test_even [3*3 -1 : 0];
//wire [FEATURE_WIDTH - 1 : 0] ternary_in_test_odd [3*3 -1 : 0];
//wire [FEATURE_WIDTH - 1 : 0] ternary_out_test_even [3*3 -1 : 0];
//wire [FEATURE_WIDTH - 1 : 0] ternary_out_test_odd [3*3 -1 : 0];
//genvar m;
//generate
//  for(m = 0; m < 3*3; m = m + 1) begin
//    assign ternary_in_test_even[m] = vertical_reg_to_select_array[(m + 1)*FEATURE_WIDTH - 1 : m*FEATURE_WIDTH];
//    assign ternary_in_test_odd[m] = vertical_reg_to_select_array[9*FEATURE_WIDTH + (m + 1)*FEATURE_WIDTH - 1 : 9*FEATURE_WIDTH + m*FEATURE_WIDTH];
//    assign ternary_out_test_even[m] = ternary_com_out[(m + 1)*FEATURE_WIDTH - 1 : m*FEATURE_WIDTH];
//    assign ternary_out_test_odd[m] = ternary_com_out[9*FEATURE_WIDTH + (m + 1)*FEATURE_WIDTH - 1 : 9*FEATURE_WIDTH + m*FEATURE_WIDTH];
//  end
//endgenerate
////////////////////////////////


////////kernel adder tree////////
wire [Tn*FEATURE_WIDTH - 1 : 0] tn_kernel_out_even;
wire [Tn*FEATURE_WIDTH - 1 : 0] tn_kernel_out_odd;
wire [25*FEATURE_WIDTH - 1 : 0] addertree_out_kn_sz_1;
wire [4:0] kn_addertree_channel_NO_in,  kn_addertree_channel_NO_out;
wire tn_kernel_done;
assign kn_addertree_channel_NO_in = tern_com_channel_NO_out;
adder_tree_Tn_kernel kernel_adder_tree(
    .fast_clk(clk),
    .rst(rst),
    .enable(ternary_com_done),
    .channel_NO_in(kn_addertree_channel_NO_in),
    .kn_size_mode(kn_size_mode),
    .ternery_res_tn(ternary_com_out),
    .kernel_sum_tn_even(tn_kernel_out_even),
    .kernel_sum_tn_odd(tn_kernel_out_odd),
    .kernel_size_1_out (addertree_out_kn_sz_1),
    .adder_done(tn_kernel_done),
    .channel_NO_out(kn_addertree_channel_NO_out)
);


////////channel adder tree////////
//kn1 mode: skip this
//dw conv mode: skip this
wire [4:0] channel_addertree_channel_NO_in, channel_addertree_even_channel_NO_out, channel_addertree_odd_channel_NO_out;
assign channel_addertree_channel_NO_in = kn_addertree_channel_NO_out;
wire [FEATURE_WIDTH-1 : 0] tm_feature_temp_even, tm_feature_temp_odd;
wire tn_channel_done_even, tn_channel_done_odd;
adder_tree_tn channel_adder_tree_even(
    .fast_clk(clk),
    .rst(rst),
    .enable(tn_kernel_done),
    .channel_NO_in (channel_addertree_channel_NO_in),
    .tn_input(tn_kernel_out_even),
    .out(tm_feature_temp_even),
    .adder_done(tn_channel_done_even),
    .channel_NO_out(channel_addertree_even_channel_NO_out)
);
adder_tree_tn channel_adder_tree_odd(
    .fast_clk(clk),
    .rst(rst),
    .enable(tn_kernel_done),
    .channel_NO_in (channel_addertree_channel_NO_in),
    .tn_input(tn_kernel_out_odd),
    .out(tm_feature_temp_odd),
    .adder_done(tn_channel_done_odd),
    .channel_NO_out(channel_addertree_odd_channel_NO_out)
);


////////scaler module////////
always @(posedge clk or posedge rst) begin
  if(rst) begin
    scaler_addr <= 0;
  end else begin
    scaler_addr <= (scaler_buffer_rd_en) ? (scaler_addr + 1) : 0;
  end
end
assign scaler_buffer_rd_en = (com_type_reg == 8'h02) ? ternary_com_done
                           : (kn_size_mode == KERNEL_SIZE_1_MODE) ? ternary_com_done
                           : tn_kernel_done;

wire [4*FEATURE_WIDTH-1 : 0] scaled_feature_even, scaler_mul_feature_in_even;
wire [4*FEATURE_WIDTH-1 : 0] scaled_feature_odd, scaler_mul_feature_in_odd;
wire [25*FEATURE_WIDTH-1 : 0] scaled_feature_kn1;
assign scaler_mul_feature_in_even = (com_type_reg == 8'h01) ? {48'b0, tm_feature_temp_even}
                                  : (com_type_reg == 8'h02) ? {48'b0, tn_kernel_out_even}
                                  : 0;
assign scaler_mul_feature_in_odd = (com_type_reg == 8'h01) ? tm_feature_temp_odd
                                 : (com_type_reg == 8'h02) ? tn_kernel_out_odd
                                 : 0;

wire [4:0] scaler_even_channel_NO_in, scaler_even_channel_NO_out, scaler_odd_channel_NO_in, scaler_odd_channel_NO_out, scaler_kn1_channel_NO_in, scaler_kn1_channel_NO_out;
assign scaler_even_channel_NO_in = (com_type_reg == 8'h01) ? channel_addertree_even_channel_NO_out
                                 : (com_type_reg == 8'h02) ? kn_addertree_channel_NO_out
                                 : 0;
assign scaler_odd_channel_NO_in = (com_type_reg == 8'h01) ? channel_addertree_odd_channel_NO_out
                                : (com_type_reg == 8'h02) ? kn_addertree_channel_NO_out
                                : 0;
assign scaler_kn1_channel_NO_in = kn_addertree_channel_NO_out;

wire scal_mul_en_even, scal_mul_en_odd;
assign scal_mul_en_even = (com_type_reg == 8'h01) ? tn_channel_done_even 
                        : (com_type_reg == 8'h02) ? tn_kernel_done 
                        : 0;
assign scal_mul_en_odd = (com_type_reg == 8'h01) ? tn_channel_done_odd 
                       : (com_type_reg == 8'h02) ? tn_kernel_done 
                       : 0;
scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) single_feature_scaling_unit_even (
    .clk(clk),
    .rst(rst),
    .enable(scal_mul_en_even),
    .data_in(scaler_mul_feature_in_even),
    .scaler_in(scaler_data[15 : 0]),
    .channel_NO_in(scaler_even_channel_NO_in),
    .channel_NO_out(scaler_even_channel_NO_out),
    .data_o(scaled_feature_even)
);
scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) single_feature_scaling_unit_odd (
    .clk(clk),
    .rst(rst),
    .enable(scal_mul_en_odd),
    .data_in(scaler_mul_feature_in_odd),
    .scaler_in(scaler_data[15 : 0]),
    .channel_NO_in(scaler_odd_channel_NO_in),
    .channel_NO_out(scaler_odd_channel_NO_out),
    .data_o(scaled_feature_odd)
);
//N_mul_unit: only for kn1
N_scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) single_feature_scaling_unit_kn1 (
    .clk(clk),
    .rst(rst),
    .enable(tn_kernel_done),
    .data_in(addertree_out_kn_sz_1),
    .scaler_in(scaler_data[15 : 0]),
    .channel_NO_in(scaler_kn1_channel_NO_in),
    .channel_NO_out(scaler_kn1_channel_NO_out),
    .data_o(scaled_feature_kn1)
);


////////bias adder////////
wire [4*FEATURE_WIDTH-1 : 0] biased_feature_even;
wire [4*FEATURE_WIDTH-1 : 0] biased_feature_odd;
wire [25*FEATURE_WIDTH-1 : 0] biased_feature_kn1, biased_feature_kn1_reorder;
wire [25*FEATURE_WIDTH-1 : 0] bias_data_bus_25;
wire [4:0] bias_even_channel_NO_in, bias_even_channel_NO_out, bias_odd_channel_NO_in, bias_odd_channel_NO_out, bias_kn1_channel_NO_in, bias_kn1_channel_NO_out;

assign bias_even_channel_NO_in = scaler_even_channel_NO_out;
assign bias_odd_channel_NO_in = scaler_odd_channel_NO_out;
assign bias_kn1_channel_NO_in = scaler_kn1_channel_NO_out;

assign bias_buffer_rd_en = (kn_size_mode == KERNEL_SIZE_1_MODE) ? tn_kernel_done : scal_mul_en_even|scal_mul_en_odd;

always @(posedge clk or posedge rst) begin
  if(rst) begin
    bias_addr <= 0;
  end else begin
    bias_addr <= (bias_buffer_rd_en) ? (bias_addr + 1) : 0;
  end
end
bias_adder #(
  .FEATURE_WIDTH(FEATURE_WIDTH)
  )bias_adder_tree_even(
    .clk(clk),
    .rst(rst),
    .feature(scaled_feature_even),
    .bias(bias_data),
    .channel_NO_in(bias_even_channel_NO_in),
    .channel_NO_out(bias_even_channel_NO_out),
    .biased_feature(biased_feature_even)  
);
bias_adder #(
  .FEATURE_WIDTH(FEATURE_WIDTH)
  )bias_adder_tree_odd(
    .clk(clk),
    .rst(rst),
    .feature(scaled_feature_odd),
    .bias(bias_data),
    .channel_NO_in(bias_odd_channel_NO_in),
    .channel_NO_out(bias_odd_channel_NO_out),
    .biased_feature(biased_feature_odd)  
);
//specially for pw conv (kn_sz = 1)
genvar j;
generate
  for (j = 0; j < 25; j=j+1) begin
    assign bias_data_bus_25[(j+1)*FEATURE_WIDTH-1 : j*FEATURE_WIDTH] = bias_data;
  end
endgenerate
bias_adder_tree_25 #(.FEATURE_WIDTH(`FEATURE_WIDTH)) bias_adder_tree_kn1 (
    .clk(clk),
    .rst(rst),
    .feature(scaled_feature_kn1),
    .bias(bias_data_bus_25),
    .channel_NO_in(bias_kn1_channel_NO_in),
    .channel_NO_out(bias_kn1_channel_NO_out),
    .biased_feature(biased_feature_kn1)
);

//kn1_biased_feature_reorder
// col num = i%5     row num = i/5      j=row num + (4-col_num)*5 = i/5+(4-i%5)*5
genvar k;
generate
  for (k = 0; k < 25; k = k + 1) begin
    assign biased_feature_kn1_reorder[(k+1)*FEATURE_WIDTH-1:k*FEATURE_WIDTH] =  biased_feature_kn1[(k/5+(4-k%5)*5+1)*FEATURE_WIDTH-1:(k/5+(4-k%5)*5)*FEATURE_WIDTH];
  end
endgenerate



// assign tm_scaled_feature = scaled_feature;

/*
genvar i;
generate
    for(i=0; i<Tm; i=i+1)begin
        scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) tn_feature_scaling_unit(
            .clk(clk),
            .rst(rst),
            .enable(1'b1),
            .data_in(tn_kernel_out[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH]),
            .scaler_in(scaler_reg[(i+1)*SCALER_WIDTH-1 : i*SCALER_WIDTH]),
            .data_o(scaled_feature[(i+1)*FEATURE_WIDTH-1 : i*FEATURE_WIDTH])
        );
    end
endgenerate
*/

// assign scaled_feature_output[Tm*FEATURE_WIDTH-1 : 0] = tm_scaled_feature[Tm*FEATURE_WIDTH-1 : 0];
// need to be optimized later

//reg [4:0] tm_buffer_sel_reg, reg_0, reg_1, reg_2, reg_3, reg_4, reg_5, reg_6, reg_7;
//always@(posedge clk or posedge rst)begin
//  if(rst) begin
//    tm_buffer_sel_reg <= 0;
//    reg_0 <= 0;
//    reg_1 <= 0;
//    reg_2 <= 0;
//    reg_3 <= 0;
//    reg_4 <= 0;
//    reg_5 <= 0;
//    reg_6 <= 0;
//    reg_7 <= 0;
//  end
//  else begin
//    tm_buffer_sel_reg <= reg_7;//scaler
//    reg_7 <= reg_6;// adder tree
//    reg_6 <= reg_5;// kn adder tree 30
//    reg_5 <= reg_4;// kn adder tree 2
//    reg_4 <= reg_3;// kn adder tree 1
//    reg_3 <= reg_2;// kn adder tree 0
//    reg_2 <= reg_1;// ternary out
//    reg_1 <= reg_0;// weight feature in
//    reg_0 <= out_channel_counter;//weight adress
//  end
//end

wire [Tm : 0]tm_wr_enable_even, tm_wr_enable_odd, tm_wr_enable_kn1;
assign tm_wr_enable_even = 1 << bias_even_channel_NO_out;
assign tm_wr_enable_odd = 1 << bias_odd_channel_NO_out;
assign tm_wr_enable_kn1 = 1 << bias_kn1_channel_NO_out;
//assign tm_wr_enable = 1 << tm_buffer_sel_reg;
// always@(posedge clk)begin
//   if(rst)begin
//     tm_wr_enable <= 0;
//   end
//   else begin
//     tm_wr
//   end
// end

reg conv_done_even, conv_done_odd, conv_done_kn1, rd_done;
reg [15:0] enable_cnt;
wire [15:0] tm_wr_addr;

always @(posedge clk or posedge rst) begin : proc_
  if(rst) begin
    enable_cnt <= 0;
    conv_done_even <= 0;
    conv_done_odd <= 0;
    conv_done_kn1 <= 0;
  end else begin
    case (com_type_reg)
      8'h01: begin
        enable_cnt <= config_enable ? (enable_cnt + 1) : enable_cnt;
        conv_done_even <= tm_wr_enable_even[8] ? 1 : 0;
        conv_done_odd <= tm_wr_enable_odd[8] ? 1 : 0;
        conv_done_kn1 <= tm_wr_enable_kn1[8] ? 1 : 0;
      end
      8'h02: begin
        enable_cnt <= config_enable ? (enable_cnt + 1) : enable_cnt;
        conv_done_even <= tm_wr_enable_even[1] ? 1 : 0;
        conv_done_odd <= tm_wr_enable_odd[1] ? 1 : 0;
        conv_done_kn1 <= tm_wr_enable_kn1[1] ? 1 : 0;
      end
      default : begin
        enable_cnt <= enable_cnt;
        conv_done_even <= 0;
        conv_done_odd <= 0;
        conv_done_kn1 <= 0;
      end
    endcase

  end
end
assign tm_wr_addr = enable_cnt - 1;// to count the writing address
assign compute_done = conv_done_even|conv_done_odd|conv_done_kn1|rd_done;



wire [4:0] channel_NO_out;
wire [25*FEATURE_WIDTH-1:0] A_buffer_data_in, A_buffer_data_out;
wire [15:0] total_rd_num;
reg [15:0] rd_cnt;
wire rd_out_en_single;
assign channel_NO_out = (kn_size_mode == KERNEL_SIZE_5_MODE) ? bias_even_channel_NO_out
                      : (kn_size_mode == KERNEL_SIZE_3_MODE) ? bias_even_channel_NO_out
                      : (kn_size_mode == KERNEL_SIZE_1_MODE) ? bias_kn1_channel_NO_out
                      : bias_even_channel_NO_out;//default
assign A_buffer_data_in = (kn_size_mode == KERNEL_SIZE_5_MODE && com_type == 8'h01) ? {384'b0, biased_feature_even[FEATURE_WIDTH-1:0]}
                        : (kn_size_mode == KERNEL_SIZE_3_MODE && com_type == 8'h01) ? {368'b0, biased_feature_odd[FEATURE_WIDTH-1:0], biased_feature_even[FEATURE_WIDTH-1:0]}
                        : (kn_size_mode == KERNEL_SIZE_5_MODE && com_type == 8'h02) ? {336'b0, biased_feature_even}
                        : (kn_size_mode == KERNEL_SIZE_3_MODE && com_type == 8'h02) ? {272'b0, biased_feature_odd, biased_feature_even}
                        : (kn_size_mode == KERNEL_SIZE_1_MODE && com_type == 8'h01) ? biased_feature_kn1_reorder
                        : 0;

///////this part will be integrated into output module in the future:                        
wire [3:0] total_row_num, total_channel_num;
assign total_row_num = (kn_size_mode == KERNEL_SIZE_3_MODE) ? 4 : 5;
assign total_channel_num = (com_type == 8'h01) ? 8 //conv
                         : (com_type == 8'h02) ? 4 //dw conv
                         : 8;//default
assign total_rd_num = total_row_num*(layer_width/25+(layer_width%25 != 0))*total_channel_num;
always @(posedge clk or posedge rst) begin
  if(rst) begin
    rd_cnt <= 0;
    rd_done <= 0;
  end else begin
    rd_cnt <= (wr_rd_mode == 0 && A_buffer_read_en) ? total_rd_num 
            : (wr_rd_mode == 0 && rd_cnt != 0) ? rd_cnt - 1
            : 0;
    rd_done <= (rd_cnt == 1) ? 1 : 0;
  end
end
assign rd_out_en_single = (rd_cnt != 0) ? 1 : 0;
/////////////////////////////////////////////////////////////////////
output_module inst_output_module (
  .clk                (clk),
  .rst                (rst),
  .initial_iteration  (initial_iteration),
  .cnt_rst            (A_buffer_cnt_rst),
  .layer_width        (layer_width),
  .kn_size_mode       (kn_size_mode),
  .com_type           (com_type),
  .wr_rd_mode         (wr_rd_mode),
  .current_channel_NO (channel_NO_out),
  .rd_out_en          (rd_out_en_single),
  .data_in            (A_buffer_data_in),
  .data_out           (A_buffer_data_out)
);








genvar i;
generate
  for(i=0; i<Tm; i=i+1)begin
    dp_ram #(.RAM_DEPTH(1024), .ADDR_WIDTH(10), .DATA_WIDTH(FEATURE_WIDTH)) tm_data_buffer_even(
      .clk(clk),
      .ena(tm_wr_enable_even[i+1]),
      .enb(),
      .wea(tm_wr_enable_even[i+1]),
      .addra(tm_wr_addr),
      .addrb(),
      .dia(biased_feature_even[FEATURE_WIDTH-1:0]),
      .dob()
    ); 
    dp_ram #(.RAM_DEPTH(1024), .ADDR_WIDTH(10), .DATA_WIDTH(FEATURE_WIDTH)) tm_data_buffer_odd(
      .clk(clk),
      .ena(tm_wr_enable_odd[i+1]),
      .enb(),
      .wea(tm_wr_enable_odd[i+1]),
      .addra(tm_wr_addr),
      .addrb(),
      .dia(biased_feature_odd[FEATURE_WIDTH-1:0]),
      .dob()
    ); 
  end
endgenerate


/////////////////////////only for simulation/////////////////////////
integer fp_w_even, fp_w_odd, fp_w_kn1;
genvar n;
reg [15:0] cnt_sim_even, cnt_sim_odd, cnt_sim_kn1;
initial begin
  fp_w_even = $fopen("Tm_0_ram_even.txt","w");
  fp_w_odd = $fopen("Tm_0_ram_odd.txt","w");
  fp_w_kn1 = $fopen("Tm_0_ram_kn1.txt","w");
  #300000;
  $fclose(fp_w_even);
  $fclose(fp_w_odd);
  $fclose(fp_w_kn1);
  //$stop;
end

always @(posedge tm_wr_enable_even[1]) begin
  #5;
  $fdisplay(fp_w_even, "%d", biased_feature_even[FEATURE_WIDTH-1:0]); 
  cnt_sim_even <= cnt_sim_even + 1;
end

always @(posedge tm_wr_enable_odd[1]) begin
  #5;
  $fdisplay(fp_w_odd, "%d", biased_feature_odd[FEATURE_WIDTH-1:0]); 
  cnt_sim_odd <= cnt_sim_odd + 1;
end


wire tn_kernel_done_t;
register_x1 #(.FEATURE_WIDTH(1)) lat(.clk(clk), .rst(rst), .in_data(tn_kernel_done), .o_data(tn_kernel_done_t));

generate
  for (n = 0; n < 25; n=n+1) begin
    always @(posedge tm_wr_enable_kn1[1]) begin
      #n;    
      $fdisplay(fp_w_kn1, "%d", biased_feature_kn1[(n+1)*FEATURE_WIDTH-1:n*FEATURE_WIDTH]); 
      //$fdisplay(fp_w_kn1, "%d", n); 
    end
  end 
endgenerate

endmodule




module data_path_config (
  input wire          clk,
  input wire          rst,

  input wire          data_path_config_enable,
  output reg          data_path_config_done,
  
  input wire  [1:0]   kn_size_mode_config,
  output reg  [1:0]   kn_size_mode,
  
  input wire  [15:0]  layer_width_config,
  output reg  [15:0]  layer_width,
  
  input wire          wr_rd_mode_config,
  output reg          wr_rd_mode,

  input wire  [7:0]   com_type_config,
  output reg  [7:0]   com_type,

  input wire          initial_iteration_config,
  output reg          initial_iteration,

  output reg          A_buffer_cnt_rst
);

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      data_path_config_done <= 0;
      kn_size_mode <= 0;
      wr_rd_mode <= 0;
      layer_width <= 0;
      com_type <= 0;
      A_buffer_cnt_rst <= 0;
      initial_iteration <= 0;
    end else begin
      if (data_path_config_enable) begin
        data_path_config_done <= 1;
        kn_size_mode <= kn_size_mode_config;
        wr_rd_mode <= wr_rd_mode_config;
        layer_width <= layer_width_config;
        com_type <= com_type_config;
        A_buffer_cnt_rst <= 1;
        initial_iteration <= initial_iteration_config;
      end
      else begin
        data_path_config_done <= 0;
        kn_size_mode <= kn_size_mode;
        wr_rd_mode <= wr_rd_mode;
        layer_width <= layer_width;
        com_type <= com_type;
        A_buffer_cnt_rst <= 0;
        initial_iteration <= initial_iteration;
      end
    end
  end
endmodule



