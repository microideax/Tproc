

module o_f_unit#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_IN_MEM_READ_WIDTH_COF = `FEATURE_IN_MEM_READ_WIDTH_COF
)(
    input wire                                                                    clk,
    input wire                                                                    rst,

    input wire feature_out_select,
    input wire CLP_output_flag,
    input wire [127:0] feature_i,
    
    input wire arm_read_feature_enable,
    input wire [12:0] arm_read_feature_addr,
    output wire [127:0] arm_read_feature_data,
    input wire arm_read_feature_select,
    input wire state
);


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
.CLP_output(feature_i),

.feature_mem_write_enable_0(feature_mem_write_enable_0),
.feature_mem_write_addr_0(feature_mem_write_addr_0),
.feature_mem_write_data_0(feature_mem_write_data_0),                          

.feature_mem_write_enable_1(feature_mem_write_enable_1),
.feature_mem_write_addr_1(feature_mem_write_addr_1),
.feature_mem_write_data_1(feature_mem_write_data_1)

);


    
wire                                                                    arm_read_feature_enable_0;
wire   [15:0]                                                           arm_read_feature_addr_0;
wire   [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data_0;
   
wire                                                                    arm_read_feature_enable_1;
wire   [15:0]                                                           arm_read_feature_addr_1;
wire   [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data_1;    
 

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
    
              
endmodule
