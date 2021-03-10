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
input [7:0]  fetch_counter,

input wire [7:0] feature_size,
// input wire feature_in_select,

output reg [14:0] wr_addr,
output wire [127:0] wr_data,
output reg wr_en,
output reg i_mem_select,
output reg fetch_done // this signal is used to inform the top_fsm for the accomplishment of data fetch
);      

// this module reads data from external memory to the on chip feature_in_memory  
// testing format for input fetch
// opcode | reg_1 | reg_2 | reg_3 | reg_4 | reg_5 | reg_6| reg_7 |
// code   | f_type| saddrh| saddrl| daddrh| daddrl|memsel|counter| 

reg [7:0] counter;

always@(posedge clk) begin
    if(rst) begin
        read_data <= 1'b0;
        fetch_addr <= 16'h0000;
        wr_addr <= 15'b0;
        i_mem_select <= 1'b0;
        wr_en <= 1'b0;
        counter <= 8'h00;
    end else begin
        if (feature_fetch_enable) begin
            read_data <= 1'b1;
            fetch_addr <= src_addr;
            wr_addr <= dst_addr;
            i_mem_select <= mem_sel[0];
            wr_en <= 1'b1;
            counter <= (fetch_counter == 8'b0) ? 8'b0 : (fetch_counter - 1);
            // to be compatible with former instruction, final edition -->counter <= fetch_counter;
        end
        else begin
            if (counter != 8'h00) begin // continue fetching
                read_data <= 1'b1;
                fetch_addr <= fetch_addr + 16'h0001;
                wr_addr <= wr_addr;
                i_mem_select <= i_mem_select;
                //wr_addr[3:0] <= (wr_addr[3:0] == 4'd4) ? 4'b0 : (wr_addr[3:0] + 4'b1);
                //wr_addr[7:4] <= (wr_addr[3:0] < 4'd4) ? wr_addr[7:4]
                //                  : (wr_addr[3:0] == 4'd4 && wr_addr[7:4] < 4'd3) ? wr_addr[7:4] + 1
                //                  : 4'b0;
                //wr_addr[14:8] <= 0;
                //i_mem_select <= (wr_addr[3:0] == 4'd4 && wr_addr[7:4] == 4'd3) ? i_mem_select + 1'b1 : i_mem_select;
                wr_en <= 1'b1;
                counter <= counter - 1; 

            end
            else begin
                read_data <= 1'b0;
                fetch_addr <= 16'h0000;
                wr_addr <= 15'b0;
                i_mem_select <= 1'b0;
                wr_en <= 1'b0;
                counter <= 8'h00; 
            end
        end
    end
end

reg feature_fetch_tmp;

always @(posedge clk) begin
    if(rst) begin
        feature_fetch_tmp <= 0;
        fetch_done <= 0;
    end else begin
        feature_fetch_tmp <= (feature_fetch_enable || counter == 1);
        fetch_done <= (feature_fetch_tmp && counter == 0);
    end
end

assign wr_data = i_data;

endmodule


module i_weight_fetch #(
    parameter WEIGHT_BUFFER_DEPTH = 16,
    parameter WEIGHT_ADDR_OFFSET = 0
)(
    input wire clk,
    input wire rst,

    // instruction interface group
    input weight_fetch_enable,
    input scaler_fetch_enable,
    input bias_fetch_enable,
    input [7:0] fetch_type,
    input [15:0] src_addr, // this will be defined by the parser, 
                                // which is the relative address of the weight data
    input [7:0]  dst_addr, // select destination buffer, optional for now
    // weight data input from DDR interface group
    input wire [63:0] w_data,
    input wire [7:0] fetch_counter,
    output reg [31:0] rd_addr,
    output reg rd_en,

    // weight data output to on-chip buffer group
    output reg [7:0] wr_addr,
    output reg [63:0] wr_data,
    output reg wr_en,
    output reg wr_cs_weight,
    output reg wr_cs_scaler,
    output reg wr_cs_bias,

    output reg fetch_done  // execution ACK
);

reg [7:0] wr_addr_tmp;
reg [7:0] counter;

always@(posedge clk) begin
    if(rst) begin
        wr_addr <= 8'h00;
    end
    else begin
        //wr_addr_tmp <= dst_addr;
        wr_addr <= wr_addr_tmp;
    end
end

always@(posedge clk) begin
    if(rst) begin
        rd_en <= 1'b0;
        rd_addr <= 32'h0;
        wr_addr_tmp <= 8'h00;
        counter <= 8'h00; 
        wr_cs_weight_tmp <= 1'b0;
        wr_cs_scaler_tmp <= 1'b0;
        wr_cs_bias_tmp <= 1'b0; 
    end else begin
        if (weight_fetch_enable | scaler_fetch_enable | bias_fetch_enable) begin            
            rd_en <= 1'b1;
            rd_addr <= src_addr + WEIGHT_ADDR_OFFSET;
            wr_addr_tmp <= dst_addr;
            counter <= (fetch_counter == 8'b0) ? 8'b0 : (fetch_counter - 1);
            wr_cs_weight_tmp <= (weight_fetch_enable) ? 1'b1 : 1'b0;
            wr_cs_scaler_tmp <= (scaler_fetch_enable) ? 1'b1 : 1'b0;
            wr_cs_bias_tmp <= (bias_fetch_enable) ? 1'b1 : 1'b0;
        end
        else begin
            if (counter != 8'h00) begin
                rd_en <= 1'b1;
                rd_addr <= rd_addr + 1;
                wr_addr_tmp <= wr_addr_tmp + 1;
                counter <= counter - 1; 
                wr_cs_weight_tmp <= wr_cs_weight_tmp;
                wr_cs_scaler_tmp <= wr_cs_scaler_tmp;
                wr_cs_bias_tmp <= wr_cs_bias_tmp;
            end
            else begin
                rd_en <= 1'b0;
                rd_addr <= 16'h0000;
                wr_addr_tmp <= 8'h00;
                counter <= 8'h00; 
                wr_cs_weight_tmp <= 1'b0;
                wr_cs_scaler_tmp <= 1'b0;
                wr_cs_bias_tmp <= 1'b0;
            end
        end
    end
end

reg fetch_tmp;
reg fetch_tmp_2;
reg wr_cs_scaler_tmp;
reg wr_cs_weight_tmp;
reg wr_cs_bias_tmp;


always @(posedge clk) begin
    if(rst) begin
        fetch_tmp <= 0;
        fetch_tmp_2 <= 0;
        fetch_done <= 0;
        wr_en <= 0;
    end else begin
        fetch_tmp <= (fetch_en || counter == 1);
        fetch_tmp_2 <= (fetch_tmp && counter == 0);
        fetch_done <= fetch_tmp_2;
        wr_en <= rd_en;
    end
end

always@(posedge clk) begin
    if(rst)begin
        wr_data <= 64'h0;
        wr_cs_scaler <= 0;
        wr_cs_weight <= 0;
        wr_cs_bias <= 0;
    end
    else begin
        wr_data <= w_data;
        wr_cs_scaler <= wr_cs_scaler_tmp;
        wr_cs_weight <= wr_cs_weight_tmp;
        wr_cs_bias <= wr_cs_bias_tmp;
    end
end

wire fetch_en;
//assign wr_data = w_data;
assign fetch_en = weight_fetch_enable | scaler_fetch_enable;



endmodule