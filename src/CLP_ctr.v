`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2018 07:46:24 PM
// Design Name: 
// Module Name: CLP_ctr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      change feature_width from 12 to 8
// Dependencies: 
//      
// Revision:
// Revision 0.01 - File Created
// Additional Comments:

//////////////////////////////////////////////////////////////////////////////////
`include "network_para.vh"

module CLP_ctr#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter SCALER_WIDTH = `SCALER_WIDTH,
    parameter BIAS_WIDTH = `BIAS_WIDTH
)(
    input   wire                                        clk,
    input   wire                                        fast_clk,
    input   wire                                        rst,
    input   wire                                        enable,
    input   wire  [63:0]                                instruction,
/*    
    input   wire                                        arm_write_feature_enable,
    input   wire  [14:0]                                arm_write_feature_addr,
    input   wire  [FEATURE_WIDTH*2 - 1 : 0]             arm_write_feature_data,
*/
    input   wire                                        arm_write_feature_select,

     
//    input   wire                                        arm_read_feature_enable,
//    input   wire  [15:0]                                arm_read_feature_addr,
//    output  wire  [FEATURE_WIDTH*2 - 1 : 0]             arm_read_feature_data,
//    input   wire                                        arm_read_feature_select,
    
    output  wire  feature_mem_read_enable_0,
    output  wire  [8:0] feature_mem_read_addr_0,
    input  wire  [383:0] feature_mem_read_data_0,

    output  wire  feature_mem_read_enable_1,
    output  wire  [8:0] feature_mem_read_addr_1,
    input   wire  [383:0] feature_mem_read_data_1,
    
    output  wire                                        feature_out_select,
    output  wire                                        CLP_output_flag,
    output  wire  [ Tm * FEATURE_WIDTH - 1 : 0 ]        CLP_output,
    
    output  wire                                        state
    );
    
genvar i,j,k,x,y,z;


// wire for instructions
wire     [3:0]           CLP_type;
wire     [2:0]           current_kernel_size;
wire     [15:0]          CLP_work_time;
wire     [7:0]           scaler_mem_addr;
wire     [15:0]          weight_mem_init_addr;
wire                     feature_in_select;       //   0 :  CLP read feature from ram0          1:  CLP read feature from ram1
wire                     feature_out_select;     //    0:   CLP write feature to ram0           1:  CLP write feature to ram1
wire     [7:0]           feature_size;


wire     [11:0]          CLP_ctr_cnt;

wire                    CLP_state;




/*
runtime_cnt runtime_cnt_0(
.clk(clk),
.rst(rst),
.CLP_work_time(CLP_work_time),
.enable(enable),
.CLP_ctr_cnt(CLP_ctr_cnt),
.state(state)
);
*/      
      
instruction_decode instruction_decode_0(
                      .clk(clk),
                      .rst(rst),
                      .instruction(instruction),
                      .state(state),
                      .CLP_type(CLP_type),
                      .current_kernel_size(current_kernel_size),
                      .CLP_work_time(CLP_work_time),
                      .scaler_mem_addr(scaler_mem_addr),
                      .weight_mem_init_addr(weight_mem_init_addr),
                      .feature_amount(),
                      .feature_in_select(feature_in_select),       //   0 :  CLP read feature from ram0          1:  CLP read feature from ram1
                      .feature_out_select(feature_out_select),     //    0:   CLP write feature to ram0           1:  CLP write feature to ram1
                      .feature_size(feature_size)
                    );     
 
 
wire CLP_enable;
wire CLP_data_delay; 

clp_state_control clp_state_unit(
.clk(clk),
.rst(rst),
.enable(enable),
.current_kernel_size(current_kernel_size),
//.CLP_ctr_cnt(CLP_ctr_cnt),
.CLP_work_time(CLP_work_time),
.feature_size(feature_size),
.CLP_enable(CLP_enable),
.CLP_data_ready(CLP_data_ready),
.state(state)
);


    
wire  [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]                   feature_wire;    
wire  [ SCALER_WIDTH - 1:0  ]                                                      scaler_wire;
wire  [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]               weight_wire;


wire f_mem_enable_0;
wire [14:0]  f_mem_addr_0;
wire [FEATURE_WIDTH*2 - 1 : 0]      f_mem_data_0;
wire f_mem_enable_1;
wire [14:0]  f_mem_addr_1;
wire [FEATURE_WIDTH*2 - 1 : 0]      f_mem_data_1;
    

/*    
feature_load i_feature_load(
  .clk(clk),
  .rst(rst),
  .arm_write_feature_enable(arm_write_feature_enable),
  .arm_write_feature_addr(arm_write_feature_addr),
  .arm_write_feature_select(arm_write_feature_select),
  .arm_write_feature_enable_0(f_mem_enable_0),
  .arm_write_feature_addr_0(f_mem_addr_0),
  .arm_write_feature_data_0(f_mem_data_0),
  .arm_write_feature_enable_1(f_mem_enable_1),
  .arm_write_feature_addr_1(f_mem_addr_1),
  .arm_write_feature_data_1(f_mem_data_1)
);


wire feature_mem_read_enable_0;
wire [8:0] feature_mem_read_addr_0;
wire [383:0] feature_mem_read_data_0;

wire feature_mem_read_enable_1;
wire [8:0] feature_mem_read_addr_1;
wire [383:0] feature_mem_read_data_1;

feature_in_mem_gen feature_in_memory_0 (
              .clka(clk),                           // input wire clka
              .ena(f_mem_enable_0),       // input wire ena
              .wea(1'b1),                              // input wire [0 : 0] wea
              .addra(f_mem_addr_0),       // input wire [12 : 0] addra
              .dina(f_mem_data_0),        // input wire [23 : 0] dina
              .clkb(clk),                           // input wire clkb
              .enb(feature_mem_read_enable_0),        // input wire enb
              .addrb(feature_mem_read_addr_0),        // input wire [8 : 0] addrb
              .doutb(feature_mem_read_data_0)         // output wire [383 : 0] doutb
            );



feature_in_mem_gen feature_in_memory_1 (
              .clka(clk),                             // input wire clka
              .ena(f_mem_enable_1),       // input wire ena
              .wea(1'b1),                             // input wire [0 : 0] wea
              .addra(f_mem_addr_1),       // input wire [12 : 0] addra
              .dina(f_mem_data_1),        // input wire [23 : 0] dina
              .clkb(clk),                             // input wire clkb
              .enb(feature_mem_read_enable_1),        // input wire enb
              .addrb(feature_mem_read_addr_1),        // input wire [8 : 0] addrb
              .doutb(feature_mem_read_data_1)         // output wire [383 : 0] doutb
            );

*/

featrue_mem_ctr_1 line_buf_array(
           .clk(clk),
           .rst(rst),
           .current_kernel_size(current_kernel_size),
           .state(state),
           .feature_size(feature_size),
//           .CLP_output_flag(CLP_output_flag),
//           .CLP_output(CLP_output),
           
           /*
           .arm_write_feature_enable(arm_write_feature_enable),
           .arm_write_feature_addr(arm_write_feature_addr),
           .arm_write_feature_data(arm_write_feature_data),
           .arm_write_feature_select(arm_write_feature_select),
            
            .f_mem_enable_0(f_mem_enable_0),
            .f_mem_addr_0(f_mem_addr_0),
            .f_mem_data_0(f_mem_data_0),
            .f_mem_enable_1(f_mem_enable_1),
            .f_mem_addr_1(f_mem_addr_1),
            .f_mem_data_1(f_mem_data_1),
            */
            
            .feature_mem_read_enable_0(feature_mem_read_enable_0),
            .feature_mem_read_enable_1(feature_mem_read_enable_1),
            .feature_mem_read_addr_0(feature_mem_read_addr_0),
            .feature_mem_read_data_0(feature_mem_read_data_0),
            .feature_mem_read_addr_1(feature_mem_read_addr_1),
            .feature_mem_read_data_1(feature_mem_read_data_1),
/*            
           .arm_read_feature_enable(arm_read_feature_enable),
           .arm_read_feature_addr(arm_read_feature_addr),
           .arm_read_feature_data(arm_read_feature_data),
           .arm_read_feature_select(arm_read_feature_select),
*/           
           .feature_in_select(feature_in_select),
           .feature_out_select(feature_out_select),
           .feature_wire(feature_wire)
           /*
           .feature_mem_write_enable_0(feature_mem_write_enable_0),
           .feature_mem_write_addr_0(feature_mem_write_addr_0),
           .feature_mem_write_data_0(feature_mem_write_data_0),                          
           
           .feature_mem_write_enable_1(feature_mem_write_enable_1),
           .feature_mem_write_addr_1(feature_mem_write_addr_1),
           .feature_mem_write_data_1(feature_mem_write_data_1)
           */
    );


/*    
wire                                                                    arm_read_feature_enable_0;
wire   [15:0]                                                           arm_read_feature_addr_0;
wire   [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data_0;
   
wire                                                                    arm_read_feature_enable_1;
wire   [15:0]                                                           arm_read_feature_addr_1;
wire   [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data_1;    
    
proc_read_unit o_feature_offload(
.clk(clk),
.rst(rst),

.arm_read_feature_enable_0(arm_read_feature_enable_0),
.arm_read_feature_addr_0(arm_read_feature_addr_0),
.arm_read_feature_data_0(arm_read_feature_data_0),

.arm_read_feature_enable_1(arm_read_feature_enable_1),
.arm_read_feature_addr_1(arm_read_feature_addr_1),
.arm_read_feature_data_1(arm_read_feature_data_1),

.arm_read_feature_enable(arm_read_feature_enable),
.arm_read_feature_addr(arm_read_feature_addr),
.arm_read_feature_data(arm_read_feature_data),
.arm_read_feature_select(arm_read_feature_select)
);
*/    
    
    
weight_mem_ctr weight_mem_ctr0(
        .clk(clk),
        .rst(rst),
        .state(state),
        .weight_mem_init_addr(weight_mem_init_addr),
        .weight_wire(weight_wire)
    );


scaler_ctr scaler_ctr0(
        .clk(clk),
        .rst(rst),
        .state(state),
        .scaler_mem_addr(scaler_mem_addr),
        .scaler_wire(scaler_wire)
        );


CLP CLP0( 
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .feature_in(feature_wire),
        .weight_in(weight_wire),
        .weight_scaler(scaler_wire),
        .bias_in({Tm * BIAS_WIDTH{1'b0}}),
        .ctr(CLP_type),
        .addr_clear(CLP_data_ready),
        .enable(CLP_enable),
        .out_valid(CLP_output_flag),
        .feature_out(CLP_output)
    );
    
    

/*

wire                                            feature_mem_write_enable_0;
wire    [12:0]                                  feature_mem_write_addr_0;
wire    [Tm * FEATURE_WIDTH - 1:0]              feature_mem_write_data_0;                          

wire                                            feature_mem_write_enable_1;
wire    [12:0]                                  feature_mem_write_addr_1;
wire    [Tm * FEATURE_WIDTH - 1:0]              feature_mem_write_data_1;


feature_mem_write_unit clp_to_fmem(
.clk(clk),
.rst(rst),
.state(state),

.feature_out_select(feature_out_select),
.CLP_output_flag(CLP_output_flag),
.CLP_output(CLP_output),

.feature_mem_write_enable_0(feature_mem_write_enable_0),
.feature_mem_write_addr_0(feature_mem_write_addr_0),
.feature_mem_write_data_0(feature_mem_write_data_0),                          

.feature_mem_write_enable_1(feature_mem_write_enable_1),
.feature_mem_write_addr_1(feature_mem_write_addr_1),
.feature_mem_write_data_1(feature_mem_write_data_1)

);


feature_out_mem_gen feature_out_memory_0 (
             .clka(clk),                            // input wire clka
             .ena(feature_mem_write_enable_0),        // input wire ena
             .wea(1'b1),                               // input wire [0 : 0] wea
             .addra(feature_mem_write_addr_0),        // input wire [9 : 0] addra
             .dina(feature_mem_write_data_0),         // input wire [95 : 0] dina
             .clkb(clk),                            // input wire clkb
             .enb(arm_read_feature_enable_0),         // input wire enb
             .addrb(arm_read_feature_addr_0),         // input wire [11 : 0] addrb
             .doutb(arm_read_feature_data_0)          // output wire [23 : 0] doutb
           );
 
 
feature_out_mem_gen feature_out_memory_1 (
             .clka(clk),                            // input wire clka
             .ena(feature_mem_write_enable_1),        // input wire ena
             .wea(1'b1),                               // input wire [0 : 0] wea
             .addra(feature_mem_write_addr_1),        // input wire [9 : 0] addra
             .dina(feature_mem_write_data_1),         // input wire [95 : 0] dina
             .clkb(clk),                            // input wire clkb
             .enb(arm_read_feature_enable_1),         // input wire enb
             .addrb(arm_read_feature_addr_1),         // input wire [11 : 0] addrb
             .doutb(arm_read_feature_data_1)          // output wire [23 : 0] doutb
           );
*/
endmodule
