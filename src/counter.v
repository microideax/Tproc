module counter(
        input clk,
        input rst,
        output reg [12:0] cnt);

always@(posedge clk)
    if(rst)
        cnt <= 0;
    else
        cnt <= cnt + 1;

endmodule 