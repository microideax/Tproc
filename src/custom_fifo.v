//-----------------------------------------------------
// Design Name : syn_fifo
// File Name   : syn_fifo.v
// Function    : Synchronous (single clock) FIFO
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module syn_fifo #(
    // FIFO constants
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 4,
    parameter RAM_DEPTH = (1 << ADDR_WIDTH)
)(
    // Port Declarations
    input clk      , // Clock input
    input rst      , // Active high reset
    input wr_cs    , // Write chip select
    input rd_cs    , // Read chipe select
    input [DATA_WIDTH-1:0] data_in  , // Data input
    input rd_en    , // Read enable
    input wr_en    , // Write Enable
output [DATA_WIDTH-1:0]data_out , // Data Output
output empty    , // FIFO empty
output full       // FIFO full
);    
 
//-----------Internal variables-------------------
reg [ADDR_WIDTH-1:0] wr_pointer;
reg [ADDR_WIDTH-1:0] rd_pointer;
reg [ADDR_WIDTH :0] status_cnt;
reg [DATA_WIDTH-1:0] data_out ;
wire [DATA_WIDTH-1:0] data_ram ;

//-----------Variable assignments---------------
assign full = (status_cnt == (RAM_DEPTH-1));
assign empty = (status_cnt == 0);

//-----------Code Start---------------------------
always @ (posedge clk or posedge rst)
begin : WRITE_POINTER
  if (rst) begin
    wr_pointer <= 0;
  end else if (wr_cs && wr_en ) begin
    wr_pointer <= wr_pointer + 1;
  end
end

always @ (posedge clk or posedge rst)
begin : READ_POINTER
  if (rst) begin
    rd_pointer <= 0;
  end else if (rd_cs && rd_en ) begin
    rd_pointer <= rd_pointer + 1;
  end
end

always  @ (posedge clk or posedge rst)
begin : READ_DATA
  if (rst) begin
    data_out <= 0;
  end else if (rd_cs && rd_en ) begin
    data_out <= data_ram;
  end
end

always @ (posedge clk or posedge rst)
begin : STATUS_COUNTER
  if (rst) begin
    status_cnt <= 0;
  // Read but no write.
  end else if ((rd_cs && rd_en) && !(wr_cs && wr_en) 
                && (status_cnt != 0)) begin
    status_cnt <= status_cnt - 1;
  // Write but no read.
  end else if ((wr_cs && wr_en) && !(rd_cs && rd_en) 
               && (status_cnt != RAM_DEPTH)) begin
    status_cnt <= status_cnt + 1;
  end
end 

/*   
ram_dp_ar_aw #(DATA_WIDTH,ADDR_WIDTH) DP_RAM (
.address_0 (wr_pointer) , // address_0 input 
.data_0    (data_in)    , // data_0 bi-directional
.cs_0      (wr_cs)      , // chip select
.we_0      (wr_en)      , // write enable
.oe_0      (1'b0)       , // output enable
.address_1 (rd_pointer) , // address_q input
.data_1    (data_ram)   , // data_1 bi-directional
.cs_1      (rd_cs)      , // chip select
.we_1      (1'b0)       , // Read enable
.oe_1      (rd_en)        // output enable
);     
*/
/*
dp_ram #(RAM_DEPTH, ADDR_WIDTH, DATA_WIDTH) ram_for_fifo (
    .clk(clk),
    .ena(wr_en),
    .enb(rd_en),
    .wea(wr_cs),
    .addra(wr_pointer),
    .addrb(rd_pointer),
    .dia(data_in),
    .dob(data_ram)
);
*/
true_dpram_sclk #(DATA_WIDTH, ADDR_WIDTH, RAM_DEPTH) ram_for_fifo (
  .data_a(data_in),
  .data_b(),
  .addr_a(wr_pointer),
  .addr_b(rd_pointer),
  .we_a(wr_en),
  .we_b(rd_en),
  .clk(clk),
  .q_a(),
  .q_b(data_ram)
);

endmodule


module syn_fifo_dpram #(
    // FIFO constants
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 4,
    parameter RAM_DEPTH = (1 << ADDR_WIDTH)
)(
    // Port Declarations
    input clk      , // Clock input
    input rst      , // Active high reset
    input wr_cs    , // Write chip select
    input rd_cs    , // Read chipe select
    input [DATA_WIDTH-1:0] data_in  , // Data input
    input rd_en    , // Read enable
    input wr_en    , // Write Enable
    output wire [DATA_WIDTH-1:0] data_out , // Data Output
    output empty    , // FIFO empty
    output full       // FIFO full
);    
 
//-----------Internal variables-------------------
reg [ADDR_WIDTH-1:0] wr_pointer;
reg [ADDR_WIDTH-1:0] rd_pointer;
reg [ADDR_WIDTH :0] status_cnt;
//reg [DATA_WIDTH-1:0] data_out ;
wire [DATA_WIDTH-1:0] data_ram;
reg rd_en_reg;

//-----------Variable assignments---------------
assign full = (status_cnt == (RAM_DEPTH-1));
assign empty = (status_cnt == 0);

//-----------Code Start---------------------------
always @ (posedge clk or posedge rst)
begin : WRITE_POINTER
  if (rst) begin
    wr_pointer <= 0;
  end else if (wr_cs && wr_en ) begin
    wr_pointer <= wr_pointer + 1;
  end
end

always @ (posedge clk or posedge rst)
begin : READ_POINTER
  if (rst) begin
    rd_pointer <= 0;
  end else if (rd_cs && rd_en ) begin
    rd_pointer <= rd_pointer + 1;
  end
end

/*
always  @ (posedge clk or posedge rst)
begin : READ_DATA
  if (rst) begin
    data_out <= 0;
  end else if (rd_cs && rd_en ) begin
    data_out <= data_ram;
  end
end
*/
always@(posedge clk)begin
    if(rst) begin
        rd_en_reg <= 1'b0;
    end else begin
        rd_en_reg <= rd_en;
    end
end
assign data_out = (rd_en | rd_en_reg) ? data_ram : 0;

always @ (posedge clk or posedge rst)
begin : STATUS_COUNTER
  if (rst) begin
    status_cnt <= 0;
  // Read but no write.
  end else if ((rd_cs && rd_en) && !(wr_cs && wr_en) 
                && (status_cnt != 0)) begin
    status_cnt <= status_cnt - 1;
  // Write but no read.
  end else if ((wr_cs && wr_en) && !(rd_cs && rd_en) 
               && (status_cnt != RAM_DEPTH)) begin
    status_cnt <= status_cnt + 1;
  end
end 

/*   
ram_dp_ar_aw #(DATA_WIDTH,ADDR_WIDTH) DP_RAM (
.address_0 (wr_pointer) , // address_0 input 
.data_0    (data_in)    , // data_0 bi-directional
.cs_0      (wr_cs)      , // chip select
.we_0      (wr_en)      , // write enable
.oe_0      (1'b0)       , // output enable
.address_1 (rd_pointer) , // address_q input
.data_1    (data_ram)   , // data_1 bi-directional
.cs_1      (rd_cs)      , // chip select
.we_1      (1'b0)       , // Read enable
.oe_1      (rd_en)        // output enable
);     
*/

dp_ram #(RAM_DEPTH, ADDR_WIDTH, DATA_WIDTH) ram_for_fifo (
    .clk(clk),
    .ena(wr_en),
    .enb(rd_en),
    .wea(wr_cs),
    .addra(wr_pointer),
    .addrb(rd_pointer),
    .dia(data_in),
    .dob(data_ram)
);

/*
true_dpram_sclk #(DATA_WIDTH, ADDR_WIDTH, RAM_DEPTH) ram_for_fifo (
  .data_a(data_in),
  .data_b(),
  .addr_a(wr_pointer),
  .addr_b(rd_pointer),
  .we_a(wr_en),
  .we_b(rd_en),
  .clk(clk),
  .q_a(),
  .q_b(data_ram)
);
*/
endmodule