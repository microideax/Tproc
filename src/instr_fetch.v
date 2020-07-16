// dummy instruction fetch module
// TODO: AXI interface, register variables for instruction fetching


/* test case instructions
04 00 00 00 01 00 00 00 // fetch feature to feature_mem 1
*/

module instr_fetch(
input wire clk,
input wire rst,

input wire [15:0] fetch_addr, // initialized with constant address, runtime with instruction decoder data
input wire fetcher_enable,

input wire [63:0] i_instr,
output reg [7:0]  i_instr_addr,
output reg i_instr_rd_en,

output wire [63:0] o_instr,
output reg [4:0] o_instr_addr,
output wire o_instr_enable,
output reg fetch_flag
);

// reg [127:0] test_instr [15:0];

// testing format for input fetch
// opcode | reg_1 | reg_2 | reg_3 | reg_4 | reg_5 | reg_6| reg_7|
// code   | f_type| saddrh| saddrl| daddrh| daddrl|memsel| null | 

/*
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
*/

reg fetch_status;
reg [4:0] fetch_cnt;

always@(posedge clk)begin
    if(rst) begin
        fetch_status <= 1'b0;
    end 
    else if (fetcher_enable && fetch_cnt < 15)begin
        fetch_status <= 1'b1;
    end
    else begin
        fetch_status <= 1'b0;
    end
end

always@(posedge clk)begin
    if(rst)begin
        fetch_cnt <= 5'b00000;
    end
    else if(fetch_status == 1'b1)begin
        fetch_cnt <= fetch_cnt + 1'b1;
    end else if(fetch_cnt == 15)begin
        fetch_cnt <= 5'b00000;
    end
end

always@(posedge clk) begin
    if(rst) begin
        i_instr_rd_en <= 1'b0;
        i_instr_addr <= 16'h0000;
    end else begin
        if (fetch_status) begin
            i_instr_rd_en <= 1'b1;
            i_instr_addr <= fetch_cnt;
        end
        else begin
            i_instr_rd_en <= 1'b0;
            i_instr_addr <= 16'h0000;
        end
    end
end



reg instr_fetch_flag;
reg instr_fetch_tmp;
always@(posedge clk) begin
    // instr_fetch_tmp <= fetcher_enable;
    instr_fetch_flag <= i_instr_rd_en;
end

assign o_instr = i_instr;
assign o_instr_enable = i_instr_rd_en;


// simulation annotations
always @ (o_instr) begin
    $display("Fetching instr: time= %d, fifo_addr= %d, instr_data= %h", $realtime, fetch_cnt, o_instr);
end


endmodule