`timescale 1ns / 1ns
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
reg ena, wea;
reg [127:0] ram_value;
reg [4:0] ram_addr;

wire [127:0] i_data_port;
wire [15:0] i_data_addr;
wire i_data_rd_en;

wire [63:0] i_weight_port;
wire [15:0] i_weight_addr;
wire i_weight_rd_en;


wire [63:0] i_instr_port;
wire [7:0] i_instr_addr;
wire i_instr_rd_en;


// instanciate test memory sapce for feature data and instruction data
reg [127:0] test_feature_storage [31:0];
reg [63:0]  test_weight_storage [31:0];
reg [63:0] test_instruction_storage [31:0];

assign i_data_port = test_feature_storage[i_data_addr];
assign i_weight_port = test_weight_storage[i_weight_addr];
assign i_instr_port = test_instruction_storage[i_instr_addr];


top mytest(
        .clk(clk),
        .fast_clk(),
        .rst(rst),
        
        .i_data_bus_port(i_data_port),
        .i_feature_addr(i_data_addr),
        .i_feature_rd_en(i_data_rd_en),

        .i_w_bus_port(i_weight_port),
        .i_w_addr(i_weight_addr),
        .i_w_enable(i_w_enable),
        
        .arm_read_feature_enable(),
        .arm_read_feature_addr(),
        .arm_read_feature_data(),
        .arm_read_feature_select(),
        
        // .instr_mem_addr(),
        .instr_port(i_instr_port),
        .instr_fetch_addr(i_instr_addr),
        .instr_rd_en(i_instr_rd_en),
        
        .acc_enable(acc_enable)
        // .CLP_state()      //0 CLP idle    1 CLP busy
        );

integer i,j;
initial
    begin
        
        $timeformat(-9, 0, " ns", 10);
        
        $display("Loading test input feature to DDR....");
        $readmemh("i_feature_init.mem", test_feature_storage);
        $display("Loaded test input 8x8 matrix.");

        $display("Loading test weight data to DDR....");
        $readmemh("i_weight_init.mem", test_weight_storage);

        $display("Loading test instructions to DDR....");
        $readmemh("i_instr_init.mem", test_instruction_storage);
        $display("Loaded test instructions.");

        clk = 0;
        rst = 1;
        acc_enable = 0;
        // load_instr_enable = 1'b0;
        ena = 1;
        wea = 1;
        // ram_value = 1;
        // ram_addr  = 0;
        // for(i=0; i<16; i=i+1) begin
        //         #10
        //         ram_value = ram_value + 1;
        //         ram_addr  = ram_addr + 1;
        // end
        ena = 0;
        wea = 0;
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
