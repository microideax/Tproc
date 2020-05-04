// dummy instruction fetch module

/*
Mannually generated instructions for function verification
|63-57| opcode
|56-49| feature_size
|48| feature_out_select
|47| feature_in_select
|
*/


/* test case instructions
opcode = 0000001 // fetch_f
f_size = 00010000 // 16
f_out_s = 0
f_i_s = 0
w_mem_init_addr = 16'h0000
s_mem_addr = 8'h00
CLP_work_time = 16'h0000
current_kernel_size = 3'b101
CLP_type = 4'b0001 // instr_fetch
*/

module instr_fetch(
input wire clk,
input wire rst,
input wire [63:0] i_instr,
input [15:0] fetch_addr,
input fetch_enable,
output reg [63:0] o_instr,
output reg [4:0] o_instr_addr,
output reg o_instr_enable,
output reg fetch_flag
);

reg [4:0] fetch_cnt;


always @ (posedge clk) begin
    if (rst) begin
        fetch_flag <= 0;
    end
    else begin
        if(fetch_enable == 1 && fetch_cnt < 15) begin
            fetch_flag <= 1;
        end
        else 
        if (fetch_cnt == 15) begin
            fetch_flag <= 0;
        end
    end
end

always @ (posedge clk) begin
    if(rst) begin
        fetch_cnt <= 0;
    end
    else begin
        if (fetch_flag == 1) begin
            fetch_cnt <= fetch_cnt + 1;
        end
    end
end

always@(posedge clk) begin
    if(rst) begin
        o_instr_enable <= 0;
        o_instr <= 64'b0; 
    end 
    else begin
        o_instr_enable <= fetch_flag;
        o_instr <= fetch_cnt;
        o_instr_addr <= fetch_cnt;
    end
end

endmodule