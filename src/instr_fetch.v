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

// testing format for input fetch
// opcode | reg_1 | reg_2 | reg_3 | reg_4 | reg_5 | reg_6| reg_7|
// code   | f_type| saddrh| saddrl| daddrh| daddrl|memsel| null | 

integer i;
initial begin
  test_instr[0] = 64'h0400000000000100;
  test_instr[1] = 64'h0400000100010100;
  test_instr[2] = 64'h0400000200020100;
  test_instr[3] = 64'h0400000300030100;
  test_instr[4] = 64'h0400000400040100;
  test_instr[5] = 64'h8100000400040100; // instruction for conv
  // instruction for DWconv
  // instruction for conv1x1
  for (i=5;i<16;i=i+1)
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