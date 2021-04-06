
// This scratch pad memory is constructed by asymmetric_fifo
// The input fills each of the fifo line for every feature load read
// Each of the scratchpad memory is constructed with kernel_size numbers of fifos
// 128 bits input fills each of the fifo line
// 16 bits output from each of the fifo line
// The fifo lines start output 

`include "network_para.vh"

module scratchpad_mem#(
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH
)(
    input wire clk,
    input wire rst,
    input wire [3:0] wr_mem_line, // indexing of the fifo lines
    input wire [3:0] rd_mem_line,
    input wire [DATA_BUS_WIDTH-1: 0] i_data,
    input wire wr_en,
    input wire rd_en,
    input wire kn_size_mode,
    
    output wire [FEATURE_WIDTH*KERNEL_SIZE-1: 0] data_out,
    output wire group_empty,
    output wire group_full
);

// reg [DATA_BUS_WIDTH - 1 : 0] data_reg;
reg [DATA_BUS_WIDTH - 1 : 0] din_to_fifo__fetch [KERNEL_SIZE-1 : 0];
wire [KERNEL_SIZE*DATA_BUS_WIDTH - 1 : 0] din_to_fifo__buffer;
wire [DATA_BUS_WIDTH - 1 : 0] din_to_fifo [KERNEL_SIZE-1 : 0];
reg [KERNEL_SIZE-1 : 0] wr_en_line__fetch;
wire [KERNEL_SIZE-1 : 0] wr_en_line__buffer;
wire [KERNEL_SIZE-1 : 0] wr_en_line;

// always@(posedge clk) begin
    // data_reg <= i_data;
// end

always@(posedge clk) begin
    if(rst) begin
        wr_en_line__fetch[KERNEL_SIZE - 1 : 0] <= 5'b00000;
    end 
    else begin
        if(wr_en) begin
            din_to_fifo__fetch[wr_mem_line] <= i_data;
            wr_en_line__fetch[wr_mem_line] <= wr_en;
        end 
        else begin
            // din_to_fifo[wr_mem_line] <= 0;
            wr_en_line__fetch[KERNEL_SIZE - 1 : 0] <= 5'b00000;
        end
    end
end

//assign din_to_fifo[wr_mem_line] = i_data;

wire [KERNEL_SIZE * FEATURE_WIDTH-1 : 0] fifo_to_dout;
wire [KERNEL_SIZE-1:0] rd_en_wire;

assign rd_en_wire = rd_en ? ~0 : 0;
/*
always@(posedge clk) begin
    if (rst) begin
        rd_en_wire <= 0;
    end
    else begin
        case(rd_mem_line)
            4'h0: begin
                rd_en_wire[0] = rd_en;
            end
            4'h1: begin
                rd_en_wire[1] = rd_en;
            end
            4'h2: begin
                rd_en_wire[2] = rd_en;
            end
            4'h3: begin
                rd_en_wire[3] = rd_en;
            end
            4'h4: begin
                rd_en_wire[4] = rd_en;
            end
            default: begin
                rd_en_wire[KERNEL_SIZE - 1 : 0] = ~0;
            end
        endcase
    end
end
*/
/*
always@(posedge clk) begin
    if(rst) begin
        rd_en_wire <= 0;
    end
    else begin
        if(rd_en) begin
            rd_en_wire <= ~0;
        end
        else begin
            rd_en_wire <= 0;
        end
    end
end
*/
wire [KERNEL_SIZE-1 : 0] full_wire;
wire [KERNEL_SIZE-1 : 0] empty_wire;

genvar i;
generate
    for(i=0; i < KERNEL_SIZE; i=i+1) begin: s_pad_mem
    asymmetric_fifo spad_mem(
        .clk(clk),
        .srst(rst),
        .din(din_to_fifo[i]), // [127:0]
        .wr_en(wr_en_line[i]),
        .rd_en(rd_en_wire[i]),
        .dout(fifo_to_dout[i*FEATURE_WIDTH + FEATURE_WIDTH-1 : i*FEATURE_WIDTH]), // [15:0]
        .full(full_wire[i]),
        .empty(empty_wire[i])
    );
    end
    for(i=1; i < KERNEL_SIZE; i=i+1) begin: s_pad_buffer
    //line_shift_buffer shift_buffer(
    //    .clk       (clk),
    //    .rst       (rst),
    //    .spad_rd_en(rd_en_wire[i]),
    //    .data_in   (fifo_to_dout[i*FEATURE_WIDTH + FEATURE_WIDTH-1 : i*FEATURE_WIDTH]),
    //    .data_out  (din_to_fifo__buffer[i-1]),
    //    .wr_en     (wr_en_line__buffer[i-1])
    //);
    spad_input_switch input_switch(
        .fetch_wr_en   (wr_en_line__fetch[i-1]),
        .buffer_wr_en  (wr_en_line__buffer[i-1]),
        .wr_en         (wr_en_line[i-1]),
        .fetch_data_in (din_to_fifo__fetch[i-1]),
        .buffer_data_in(din_to_fifo__buffer[i*DATA_BUS_WIDTH-1:(i-1)*DATA_BUS_WIDTH]),
        .data_in       (din_to_fifo[i-1])
    );
    end

    line_shift_buffer_array shift_buffer_array(
        .clk         (clk),
        .rst         (rst),
        .kn_size_mode(kn_size_mode),
        .spad_rd_en  (rd_en_wire[KERNEL_SIZE-1:1]),
        .data_in     (fifo_to_dout[(KERNEL_SIZE-1)*FEATURE_WIDTH + FEATURE_WIDTH-1 : FEATURE_WIDTH]),
        .data_out    (din_to_fifo__buffer[(KERNEL_SIZE-1)*DATA_BUS_WIDTH - 1 : 0]),
        .wr_en       (wr_en_line__buffer[KERNEL_SIZE-1 - 1:0])
    );

endgenerate

assign    din_to_fifo[KERNEL_SIZE-1] = din_to_fifo__fetch[KERNEL_SIZE-1];
assign    wr_en_line[KERNEL_SIZE-1] = wr_en_line__fetch[KERNEL_SIZE-1];


assign data_out[KERNEL_SIZE * FEATURE_WIDTH -1 : 0] = fifo_to_dout[KERNEL_SIZE * FEATURE_WIDTH -1 : 0];
assign group_empty = empty_wire[0];
assign group_full = full_wire[KERNEL_SIZE-1];
/*
always@(full_wire or empty_wire)begin
    if(full_wire == 8'hff) begin
        group_full = 1'b1;
    end else begin
        group_full = 1'b0;
    end
    if(empty_wire == 8'hff) begin
        group_empty = 1'b1;
    end else begin
        group_empty = 1'b0;
    end
end
*/
endmodule

module line_shift_buffer_array #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH, // 128 bits
    parameter BUFFER_DEPTH_LOG2 = $clog2(DATA_BUS_WIDTH/FEATURE_WIDTH), // 3 bits
    parameter BUFFER_DEPTH = DATA_BUS_WIDTH/FEATURE_WIDTH, // 8
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE,
    parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE
)(
    input wire clk,  
    input wire rst,
    input wire kn_size_mode,
    input wire [KERNEL_SIZE - 1 : 0] spad_rd_en, // former spad's rd_en  (row 1, 2, 3, 4)
    input wire [(KERNEL_SIZE - 1) * FEATURE_WIDTH - 1 : 0] data_in,//row 1, 2, 3, 4
    output reg [(KERNEL_SIZE - 1) * DATA_BUS_WIDTH - 1 : 0] data_out,//row 0, 1, 2, 3
    output wire [KERNEL_SIZE - 1 : 0] wr_en
);

reg [(KERNEL_SIZE - 1) * FEATURE_WIDTH - 1 : 0] data_in_inter;
wire [(KERNEL_SIZE - 1) * DATA_BUS_WIDTH - 1 : 0] data_out_inter;

always @(*) begin
    case (kn_size_mode)
        KERNEL_SIZE_5_MODE : begin
            data_in_inter = data_in;
            data_out = data_out_inter;
        end
        KERNEL_SIZE_3_MODE : begin
            data_in_inter[FEATURE_WIDTH - 1 : 0] = data_in[2*FEATURE_WIDTH - 1 : FEATURE_WIDTH];
            data_in_inter[2*FEATURE_WIDTH - 1 : FEATURE_WIDTH] = data_in[4*FEATURE_WIDTH - 1 : 3*FEATURE_WIDTH];
            data_in_inter[4*FEATURE_WIDTH - 1 : 2*FEATURE_WIDTH] = 0;
            data_out = data_out_inter;
        end
        default : begin
            data_in_inter = data_in;
            data_out = data_out_inter;
        end
    endcase
end

genvar i;
generate
    for (i=0; i < KERNEL_SIZE-1; i=i+1) begin
        line_shift_buffer shift_buffer(
            .clk       (clk),
            .rst       (rst),
            .spad_rd_en(spad_rd_en[i]),
            .data_in   (data_in_inter[(i+1)*FEATURE_WIDTH - 1 : i*FEATURE_WIDTH]),
            .data_out  (data_out_inter[(i+1)*DATA_BUS_WIDTH - 1 : i*DATA_BUS_WIDTH]),
            .wr_en     (wr_en[i])
        );
    end
endgenerate

endmodule


//feature buffer : used to fill the next line with previous line feature
module line_shift_buffer  #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH, // 128 bits
    parameter BUFFER_DEPTH_LOG2 = $clog2(DATA_BUS_WIDTH/FEATURE_WIDTH), // 3 bits
    parameter BUFFER_DEPTH = DATA_BUS_WIDTH/FEATURE_WIDTH // 8
)(
    input wire clk,  
    input wire rst,
    input wire spad_rd_en, // former spad's rd_en
    input wire [FEATURE_WIDTH - 1 : 0] data_in,
    output wire [DATA_BUS_WIDTH - 1 : 0] data_out,
    output reg wr_en
);

reg [DATA_BUS_WIDTH - 1 : 0] data_buffer;
reg [BUFFER_DEPTH_LOG2 - 1 : 0] buffer_cnt, buffer_cnt_t;
reg spad_rd_en_t;// sync with dout from spad


always @(posedge clk or posedge rst) begin
    if(rst) begin
        spad_rd_en_t <= 0;
        buffer_cnt <= 0;
        buffer_cnt_t <= 0;
        data_buffer <= 0;
        wr_en <= 0;
    end else begin
        spad_rd_en_t <= spad_rd_en; // sync with dout from spad
        buffer_cnt <= spad_rd_en_t ? (buffer_cnt + 1) : buffer_cnt;
        buffer_cnt_t <= buffer_cnt;
        data_buffer <= spad_rd_en_t ? {data_buffer[DATA_BUS_WIDTH - FEATURE_WIDTH - 1 : 0], data_in} : data_buffer;
        wr_en <= (buffer_cnt == 3'b0 && buffer_cnt_t == 3'b111) ? 1 : 0;
    end
end

assign data_out = data_buffer;


endmodule

//2*8 feature buffer : used to fill the next line with previous line feature
/*
module line_shift_buffer  #(
    parameter FEATURE_WIDTH = `FEATURE_WIDTH, // 16 bits
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH, // 128 bits
    parameter BUFFER_DEPTH_LOG2 = $clog2(2*DATA_BUS_WIDTH/FEATURE_WIDTH), // 4 bits
    parameter BUFFER_DEPTH = 2*DATA_BUS_WIDTH/FEATURE_WIDTH // 16
)(
    input wire clk,  
    input wire rst,
    input wire spad_rd_en, // former spad's rd_en
    input wire [FEATURE_WIDTH - 1 : 0] data_in,
    output wire [DATA_BUS_WIDTH - 1 : 0] data_out,
    output wire wr_en
);

reg buffer_mod; //0: use [127:0]  ;  1: use [255:128]
reg wr_en_0, wr_en_1;
reg [2*DATA_BUS_WIDTH - 1 : 0] data_buffer;
reg [BUFFER_DEPTH_LOG2 - 1 : 0] buffer_cnt, buffer_cnt_t;
reg spad_rd_en_t;// sync with dout from spad


always @(posedge clk or posedge rst) begin
    if(rst) begin
        spad_rd_en_t <= 0;
        buffer_cnt <= 0;
        buffer_cnt_t <= 0;
        data_buffer <= 0;
        wr_en_0 <= 0;
        wr_en_1 <= 0;
    end else begin
        spad_rd_en_t <= spad_rd_en; // sync with dout from spad
        buffer_cnt <= spad_rd_en_t ? (buffer_cnt + 1) : buffer_cnt;
        buffer_cnt_t <= buffer_cnt;
        data_buffer <= (wr_en_0) ? data_buffer[] | (data_in << buffer_cnt*FEATURE_WIDTH)
                     : data_buffer | (data_in << buffer_cnt*FEATURE_WIDTH); // other bits remain the same
        wr_en_0 <= (buffer_cnt == 4'd8 && buffer_cnt_t == 4'd7) ? 1 : 0;
        wr_en_1 <= (buffer_cnt == 4'd0 && buffer_cnt_t == 4'd15) ? 1 : 0;
    end
end

assign data_out = (wr_en_0) ? data_buffer[BUFFER_DEPTH/2 - 1 : 0]
                : (wr_en_1) ? data_buffer[BUFFER_DEPTH - 1 : BUFFER_DEPTH/2]
                : 0;
assign wr_en = wr_en_0 | wr_en_1;

endmodule
*/



module spad_input_switch #(
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH // 128 bits
)(
    input fetch_wr_en, 
    input buffer_wr_en,
    output wr_en,
    
    input [DATA_BUS_WIDTH - 1 : 0] fetch_data_in,
    input [DATA_BUS_WIDTH - 1 : 0] buffer_data_in,
    output [DATA_BUS_WIDTH - 1 : 0] data_in
);
// we define that fetch operation has a higher priority
    assign data_in = (fetch_wr_en) ? fetch_data_in
                   : (buffer_wr_en) ? buffer_data_in
                   : 0;
    assign wr_en = fetch_wr_en | buffer_wr_en;

endmodule


