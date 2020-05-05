`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2018 18:29:52
// Design Name: 
// Module Name: tb_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_top();

reg clk;
reg rst;
reg acc_enable;

// reg load_instr_enable;
// reg [9:0] load_instr_addr;
// reg [63:0] instr_data; 

//reg instr_loaded_flag;

top mytest(
        .clk(clk),
        .fast_clk(),
        .rst(rst),
        
        .i_data_bus_port(),
        
        .arm_read_feature_enable(),
        .arm_read_feature_addr(),
        .arm_read_feature_data(),
        .arm_read_feature_select(),
        
        // .instr_mem_addr(),
        .instr_port(),
        
        .acc_enable(acc_enable),
        .CLP_state()      //0 CLP idle    1 CLP busy
        );


initial
    begin
        clk = 0;
        rst = 1;
        acc_enable = 0;
        // load_instr_enable = 1'b0;
        #50;
        rst = 0;
        acc_enable = 1;
//        instr_loaded_flag = 0;
        
        # 100;
        rst = 0;
        acc_enable = 0;
        // load_instr_addr = 10'b0000000000;
        // instr_data = 64'b0000000000000011000100000000000000000000000000010101011101011000;
//        instr_loaded_flag = 1'b1;  
        // # 10 
        // load_instr_addr = 10'b0000000001;
        // instr_data = 64'b0000000000000011000100000000000000000000000000010101011101011001;
        // acc_enable = 1;                       
    end

always #5 clk = ~clk;

endmodule
