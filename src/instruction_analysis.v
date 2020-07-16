// Instruction analysis 
// Decoding the input instructions and send to different components
// ERROR: The instruction need to be operation based, which means 
// different opcode represents different variable distribution

`timescale 1ns / 1ps

module instruction_decode(
       input   wire             clk,
       input   wire             rst,
       input   wire  [63:0]     instruction,
       input   wire             instr_enable,

       output  reg feature_fetch_enable,
       output  reg weight_fetch_enable,
       output  reg bias_fetch_enable,
       output  reg scaler_fetch_enable,
       output  reg instr_fetch_enable,

    // interface group to feature fetcher
       output  reg [7:0]        fetch_type,
       output  reg [15:0]       src_addr,
       output  reg [7:0]        dst_addr,
       output  reg [7:0]        mem_sel,
       output  reg [7:0]        fetch_counter,

    // TODO: interface group to weight fetcher
    //    output  reg   [15:0]     weight_mem_init_addr,
    //    output  reg   [7:0]      scaler_mem_addr,
    //    output  reg   [15:0]     CLP_work_time,
    //    output  reg   [3:0]      CLP_type,

    // interface group to conv/dwconv/deconv
       output  reg   [2:0]      current_kernel_size,
       output  reg   [7:0]      current_feature_size,
       output  reg              line_buffer_enable,
       output  reg              feature_in_select,   //0: CLP read feature from ram0          1:  CLP read feature from ram1
       output  reg              line_buffer_mod,

       output  reg              feature_out_select  //0: CLP write feature to ram0           1:  CLP write feature to ram1
       );
    
reg [10:0] feature_amount; 

reg [7:0] opcode;
reg [7:0] reg_1;
reg [7:0] reg_2;
reg [7:0] reg_3;
reg [7:0] reg_4;
reg [7:0] reg_5;
reg [7:0] reg_6;
reg [7:0] reg_7;

always@(posedge clk) begin
    if(rst) begin
        opcode <= 0;
        reg_1  <= 0;
        reg_2  <= 0;
        reg_3  <= 0;
        reg_4  <= 0;
        reg_5  <= 0;
        reg_6  <= 0;
        reg_7  <= 0;
    end 
    else begin
        if(instr_enable) begin
            opcode <= instruction[63:56];
            reg_1  <= instruction[55:48];
            reg_2  <= instruction[47:40];
            reg_3  <= instruction[39:32];
            reg_4  <= instruction[31:24];
            reg_5  <= instruction[23:16];
            reg_6  <= instruction[15:8];
            reg_7  <= instruction[7:0];
        end else begin
            opcode <= 0;
            reg_1  <= 0;
            reg_2  <= 0;
            reg_3  <= 0;
            reg_4  <= 0;
            reg_5  <= 0;
            reg_6  <= 0;
            reg_7  <= 0;
        end
    end
end
    
always@(posedge clk) begin
    if(rst) begin
        feature_fetch_enable <= 1'b0;
        weight_fetch_enable <= 1'b0;
        bias_fetch_enable <= 1'b0;
        scaler_fetch_enable <= 1'b0;
        instr_fetch_enable <= 1'b0;
        fetch_type <= 0;
        src_addr <= 0;
        dst_addr <= 0;
        mem_sel  <= 0;
        fetch_counter <= 0;
    end else begin
        case (opcode)
            8'h01: begin
                feature_fetch_enable <= ~reg_1[0];
                weight_fetch_enable <= reg_1[0];
                bias_fetch_enable <= reg_1[1];
                scaler_fetch_enable <= reg_1[2];
            end
            8'h02: begin
                feature_fetch_enable <= ~reg_1[0];
                weight_fetch_enable <= reg_1[0];
                fetch_type <= reg_1;
                src_addr <= {reg_2, reg_3};
                dst_addr <= {reg_4[3:0], reg_5[3:0]};
                mem_sel <= reg_6;
                fetch_counter <= reg_7;
            end
            8'h04: begin
                feature_fetch_enable <= ~reg_1[0];
                weight_fetch_enable  <= reg_1[0];
                fetch_type <= reg_1;
                src_addr <= {reg_2, reg_3};
                dst_addr <= {reg_4[3:0], reg_5[3:0]}; // reg_4 is not used in the current stage
                mem_sel <= reg_6;
            end
            8'h81: begin
                current_kernel_size <= reg_3;
                current_feature_size <= reg_2;
                line_buffer_enable <= reg_4[0];
                feature_in_select <= reg_6[0]; // select input buffer
                line_buffer_mod <= reg_1[0];
            end
            default: begin
                feature_fetch_enable <= 1'b0;
                weight_fetch_enable <= 1'b0;
                bias_fetch_enable <= 1'b0;
                scaler_fetch_enable <= 1'b0;
                instr_fetch_enable <= 1'b0;
                fetch_type <= 0;
                src_addr <= 0;
                dst_addr <= 0;
                mem_sel  <= 0;
                fetch_counter <= 0;
            end
        endcase
    end
end


endmodule