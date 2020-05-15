// dummy instruction fetch module


/* test case instructions
04 00 00 00 01 00 00 00 // fetch feature to feature_mem 1
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
reg [127:0] test_instr [15:0];

integer i;
initial begin
  test_instr[0] = 64'h0400000000010100;
  for (i=1;i<16;i=i+1)
    test_instr[i] = i;
end

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
        o_instr <= test_instr[fetch_cnt];
        o_instr_addr <= fetch_cnt;
    end
end

endmodule