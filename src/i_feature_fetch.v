// dummy input feature fetch module

module i_feature_fetch(
input wire clk,
input wire rst,

input wire [127:0] i_data,
output reg [15:0] fetch_addr,
output reg read_data,

input wire feature_fetch_enable,
input wire [7:0] fetch_type,
input [15:0] src_addr,
input [7:0]  dst_addr,
input [7:0]  mem_sel,

input wire [7:0] feature_size,
// input wire feature_in_select,

output wire [14:0] wr_addr,
output wire [127:0] wr_data,
output wire wr_en,
output reg i_mem_select );      

// this module reads data from external memory to the on chip feature_in_memory  
// testing format for input fetch
// opcode | reg_1 | reg_2 | reg_3 | reg_4 | reg_5 | reg_6| reg_7|
// code   | f_type| saddrh| saddrl| daddrh| daddrl|memsel| null | 

always@(posedge clk) begin
    if(rst) begin
        i_mem_select <= 1'b0; 
    end
    else begin
        i_mem_select <= mem_sel[0];
    end
end

always@(posedge clk) begin
    if(rst) begin
        read_data <= 1'b0;
        fetch_addr <= 16'h0000;
    end else begin
        if (feature_fetch_enable) begin
            read_data <= 1'b1;
            fetch_addr <= src_addr;
        end
        else begin
            read_data <= 1'b0;
            fetch_addr <= 16'h0000;
        end
    end
end

reg feature_fetch_flag;
reg feature_fetch_tmp;
always@(posedge clk) begin
    feature_fetch_tmp <= feature_fetch_enable;
    feature_fetch_flag<= feature_fetch_tmp;
end

assign wr_data = i_data;
assign wr_addr = dst_addr;
assign wr_en = feature_fetch_flag;

endmodule


module i_weight_fetch(
    input wire clk,
    input wire rst,
    input wire [127:0] i_w_data,

    input wire weight_fetch_enable,
    input wire [7:0] fetch_type,
    input wire [15:0] src_addr, // this will be defined by the parser, 
                                  // which is the relative address of the weight data

    output reg [14:0] wr_addr,
    output reg [127:0] wr_data,
    output reg wr_en                                  
);

reg start_reg;
always@(posedge clk) begin
    if(rst) begin
        start_reg <= 1'b0; 
    end
    else begin
        if (weight_fetch_enable) 
        begin
            start_reg <= 1'b1;
        end
        else begin
            start_reg <= 1'b0;
        end
    end
end

endmodule