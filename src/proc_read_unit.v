
module proc_read_unit#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_IN_MEM_READ_WIDTH_COF = `FEATURE_IN_MEM_READ_WIDTH_COF
)(
input clk,
input rst,

output wire arm_read_feature_enable_0,
output wire [15:0] arm_read_feature_addr_0,
input [FEATURE_WIDTH*2 - 1 : 0] arm_read_feature_data_0,

output wire arm_read_feature_enable_1,
output wire [15:0] arm_read_feature_addr_1,
input [FEATURE_WIDTH*2 - 1 : 0] arm_read_feature_data_1,
 
input wire                                                                    arm_read_feature_enable,
input wire   [15:0]                                                           arm_read_feature_addr,
output wire  [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data,
input wire                                                                    arm_read_feature_select
    
);

//singals for ARM read feature
/*    
wire                                                                    arm_read_feature_enable_0;
wire   [15:0]                                                           arm_read_feature_addr_0;
wire   [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data_0;

wire                                                                    arm_read_feature_enable_1;
wire   [15:0]                                                           arm_read_feature_addr_1;
wire   [FEATURE_WIDTH*2 - 1 : 0]                                        arm_read_feature_data_1;
*/

assign  arm_read_feature_enable_0   = (arm_read_feature_select == 0) ? arm_read_feature_enable   : 0;
assign  arm_read_feature_enable_1   = (arm_read_feature_select == 0) ? 0                         : arm_read_feature_enable;

assign  arm_read_feature_addr_0     = (arm_read_feature_select == 0) ? arm_read_feature_addr     : 0;
assign  arm_read_feature_addr_1     = (arm_read_feature_select == 0) ? 0                         : arm_read_feature_addr;

assign  arm_read_feature_data       = (arm_read_feature_select == 0) ? arm_read_feature_data_0   : arm_read_feature_data_1;



endmodule