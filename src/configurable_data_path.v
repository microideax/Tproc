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
    input wire config_clear,
    input wire [7:0] com_type,
    input wire [3:0] kernel_size,

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
    
    input wire [15 : 0] scaler_data,
    output wire scaler_buffer_rd_en,
    output wire [Tm* FEATURE_WIDTH + SCALER_WIDTH-1 : 0] scaled_feature_output
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
    end else if(config_clear) begin
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


wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] reorder_feature;
wire [Tn*KERNEL_SIZE*KERNEL_SIZE*FEATURE_WIDTH-1 : 0] reorder_feature_in;

assign reorder_feature_in = virtical_data_reg;

reorder_feature reorder_feature_1(
  .clk        (clk),
  .rst        (rst),
  .feature_in (reorder_feature_in),
  .feature_out(reorder_feature)
);


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
TnKK_select_array ternary_com_array(
    .clk(clk),
    .rst(rst),
    .feature_in(reorder_feature),
    .weight_in(weight_wire),
    .enable(sel_array_enable),
    .feature_out(ternary_com_out)
);

wire [Tn*FEATURE_WIDTH - 1 : 0] tn_kernel_out;
wire tn_kernel_done;
adder_tree_Tn_kernel kernel_adder_tree(
    .fast_clk(clk),
    .rst(rst),
    .enable(sel_array_enable),
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
wire [FEATURE_WIDTH-1 : 0] scaled_feature;
scaler_multiply_unit #(.FEATURE_WIDTH(FEATURE_WIDTH), .SCALER_WIDTH(16)) single_feature_scaling_unit (
    .clk(clk),
    .rst(rst),
    .enable(tn_channel_done),
    .data_in(tm_feature_temp),
    .scaler_in(scaler_data[15 : 0]),
    .data_o(scaled_feature)
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
reg [4:0] tm_buffer_sel_reg, reg_0, reg_1, reg_2, reg_3, reg_4, reg_5, reg_6;
always@(posedge clk)begin
  if(rst) begin
    tm_buffer_sel_reg <= 0;
    reg_0 <= 0;
    reg_1 <= 0;
    reg_2 <= 0;
    reg_3 <= 0;
    reg_4 <= 0;
    reg_5 <= 0;
    reg_6 <= 0;
  end
  else begin
    tm_buffer_sel_reg <= reg_6;
    reg_6 <= reg_5;
    reg_5 <= reg_4;
    reg_4 <= reg_3;
    reg_3 <= reg_2;
    reg_2 <= reg_1;
    reg_1 <= out_channel_counter;
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

genvar i;
generate
  for(i=0; i<Tm; i=i+1)begin
    dp_ram #(.RAM_DEPTH(), .ADDR_WIDTH(), .DATA_WIDTH()) tm_data_buffer(
      .clk(clk),
      .ena(tm_wr_enable[i+1]),
      .enb(),
      .wea(tm_wr_enable[i+1]),
      .addra(),
      .addrb(),
      .dia(scaled_feature),
      .dob()
    ); 
  end
endgenerate

endmodule
