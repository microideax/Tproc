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
    parameter Tm = `Tm
) (
    input wire clk,
    input wire rst,

    input wire config_enable,
    input wire config_clear,//temporally replaced by conv_done
    input wire [7:0] com_type,
    input wire [3:0] kernel_size,

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

reg [7 : 0] com_type_reg;
always@(posedge clk) begin
  if(rst) begin
    com_type_reg <= 8'h00;
  end 
  else begin
    if(config_enable)begin
      com_type_reg <= com_type;
    end else if(conv_done) begin // use conv_done temporally
      com_type_reg <= 8'h00;
    end  else begin
      com_type_reg <= com_type_reg;
    end
  end
end

wire virreg_to_fmem_0;
wire virreg_to_fmem_1;
wire [Tn*FEATURE_WIDTH*KERNEL_SIZE*KERNEL_SIZE - 1 : 0] virtical_reg_to_select_array;
reg [Tn*FEATURE_WIDTH*KERNEL_SIZE*KERNEL_SIZE - 1 : 0] virtical_data_reg;
wire [Tm*FEATURE_WIDTH - 1 : 0] tm_scaled_feature;
wire [Tm*16-1 : 0] scaler_reg;

vertical_reg i_vertical_reg(
    .clk(clk),
    .rst(rst),
    .com_type(),
    .kernel_size(),
    .shift_mod   (vertical_shift_mod),
    .enable(virtical_reg_shift),
    .in_select(virreg_input_sel),
    .feature_en_0(virreg_to_fmem_0),
    .feature_en_1(virreg_to_fmem_1),
    .dia_0(feature_mem_read_data_0),
    .dia_1(feature_mem_read_data_1),
    .doa(virtical_reg_to_select_array),
    .shift_done(shift_done_from_virreg)
);

always@(posedge clk) begin
  if(rst) begin
    virtical_data_reg <= 0;
  end
  else begin
    if(shift_done_from_virreg) begin
      virtical_data_reg <= virtical_reg_to_select_array;
    end else begin
      virtical_data_reg <= virtical_data_reg;
    end
  end
end

// virtical_reg w_virtical_reg();
reg [4:0] out_channel_counter;
reg feature_ready_flag;

always@(posedge clk) begin
  if(rst) begin
    feature_ready_flag <= 1'b0;
  end else begin
    if(shift_done_from_virreg) begin
        feature_ready_flag <= 1'b1;
      end 
      else if(out_channel_counter == (Tm-1)) begin
        feature_ready_flag <= 1'b0;
      end    
  end
end
/*
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*KERNEL_WIDTH-1 : 0] weight_vertical_wire;

vertical_reg_weight vertical_reg_weight(
  .clk       (clk),
  .rst       (rst),
  .weight_in (weight_wire),
  .weight_out(weight_vertical_wire)
);
*/

/*
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] reorder_feature;
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] reorder_feature_in;

assign reorder_feature_in = virtical_data_reg;

reorder_feature reorder_feature_1(
  .clk        (clk),
  .rst        (rst),
  .feature_in (reorder_feature_in),
  .feature_out(reorder_feature)
);*/


reg sel_array_enable;
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
            weight_read_en <= 1'b0;
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

always@(posedge clk)begin
  if(rst) begin
    sel_array_enable <= 1'b0;
  end
  else begin
    sel_array_enable <= weight_read_en;
  end
end

wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH - 1 : 0] ternary_com_out;
wire ternary_com_done;
TnKK_select_array ternary_com_array(
    .clk(clk),
    .rst(rst),
    .feature_in(virtical_reg_to_select_array),
    .weight_in(weight_wire),
    .enable(sel_array_enable),
    .feature_out(ternary_com_out),
    .ternary_com_done(ternary_com_done)
);

wire [Tn*FEATURE_WIDTH - 1 : 0] tn_kernel_out;
wire tn_kernel_done;
adder_tree_Tn_kernel kernel_adder_tree(
    .fast_clk(clk),
    .rst(rst),
    .enable(ternary_com_done),
    .ternery_res_tn(ternary_com_out),
    .kernel_sum_tn(tn_kernel_out),
    .adder_done(tn_kernel_done)
);

wire [FEATURE_WIDTH-1 : 0] tm_feature_temp;
wire tn_channel_done;
adder_tree_tn channel_adder_tree(
    .fast_clk(clk),
    .rst(rst),
    .enable(tn_kernel_done),
    .tn_input(tn_kernel_out),
    .out(tm_feature_temp),
    .adder_done(tn_channel_done)
);

assign scaler_buffer_rd_en = tn_kernel_done;
always @(posedge clk or posedge rst) begin
  if(rst) begin
    scaler_addr <= 0;
  end else begin
    scaler_addr <= (scaler_buffer_rd_en) ? (scaler_addr + 1) : 0;
  end
end
wire [FEATURE_WIDTH-1 : 0] scaled_feature;
scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) single_feature_scaling_unit (
    .clk(clk),
    .rst(rst),
    .enable(tn_channel_done),
    .data_in(tm_feature_temp),
    .scaler_in(scaler_data[15 : 0]),
    .data_o(scaled_feature)
);

wire [FEATURE_WIDTH-1 : 0] biased_feature;
assign bias_buffer_rd_en = tn_channel_done;
always @(posedge clk or posedge rst) begin
  if(rst) begin
    bias_addr <= 0;
  end else begin
    bias_addr <= (bias_buffer_rd_en) ? (bias_addr + 1) : 0;
  end
end
adder_2in_1out #(
  .FEATURE_WIDTH(FEATURE_WIDTH)
  )bias_adder_tree(
    .clk(clk),
    .rst(rst),
    .A1 (scaled_feature),
    .B1 (bias_data),
    .O  (biased_feature)  
);


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
reg [4:0] tm_buffer_sel_reg, reg_0, reg_1, reg_2, reg_3, reg_4, reg_5, reg_6, reg_7;
always@(posedge clk or posedge rst)begin
  if(rst) begin
    tm_buffer_sel_reg <= 0;
    reg_0 <= 0;
    reg_1 <= 0;
    reg_2 <= 0;
    reg_3 <= 0;
    reg_4 <= 0;
    reg_5 <= 0;
    reg_6 <= 0;
    reg_7 <= 0;
  end
  else begin
    tm_buffer_sel_reg <= reg_7;
    reg_7 <= reg_6;
    reg_6 <= reg_5;
    reg_5 <= reg_4;
    reg_4 <= reg_3;
    reg_3 <= reg_2;
    reg_2 <= reg_1;
    reg_1 <= reg_0;
    reg_0 <= out_channel_counter;
  end
end

wire [Tm : 0]tm_wr_enable;
assign tm_wr_enable = 1 << tm_buffer_sel_reg;
// always@(posedge clk)begin
//   if(rst)begin
//     tm_wr_enable <= 0;
//   end
//   else begin
//     tm_wr
//   end
// end

reg conv_done;
reg [15:0] enable_cnt;
wire [15:0] tm_wr_addr;

always @(posedge clk or posedge rst) begin : proc_
  if(rst) begin
    enable_cnt <= 0;
    conv_done <= 0;
  end else begin
    enable_cnt <= config_enable ? (enable_cnt + 1) : enable_cnt;
    conv_done <= tm_wr_enable[8] ? 1 : 0;
  end
end
assign tm_wr_addr = enable_cnt - 1;
assign compute_done = conv_done;


genvar i;
generate
  for(i=0; i<Tm; i=i+1)begin
    dp_ram #(.RAM_DEPTH(1024), .ADDR_WIDTH(10), .DATA_WIDTH(FEATURE_WIDTH)) tm_data_buffer(
      .clk(clk),
      .ena(tm_wr_enable[i+1]),
      .enb(),
      .wea(tm_wr_enable[i+1]),
      .addra(tm_wr_addr),
      .addrb(),
      .dia(biased_feature),
      .dob()
    ); 
  end
endgenerate

/////////////////////////only for simulation/////////////////////////
/*
integer fp_w;
reg [3:0] mem_count;
initial begin

  fp_w = $fopen("Tm_1_ram.txt","w");
  #1800;
  for (mem_count = 0; mem_count < 8; mem_count = mem_count + 1) begin
    $fdisplay(fp_w, "%d", scaled_feature);          //%h denotes hex
    #10;
  end

  $fclose(fp_w);
end*/


integer fp_w;
reg [15:0] cnt_sim;
initial begin
  fp_w = $fopen("Tm_0_ram.txt","w");
  #300000;
  $fclose(fp_w);
  //$stop;
end

always @(posedge tm_wr_enable[1]) begin
  #5;
  $fdisplay(fp_w, "%d", biased_feature); 
  cnt_sim <= cnt_sim + 1;
end

//always begin
//  #1000
//  $fdisplay(fp_w, "%d", biased_feature);
//end

//always @(cnt_sim) begin
//  if(cnt_sim == 24*24 - 1) begin
//    $fclose(fp_w);
//  end
//end

endmodule

