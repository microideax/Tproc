`include "network_para.vh"

module feature_load #(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter DATA_BUS_WIDTH = `DATA_BUS_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter FEATURE_IN_MEM_READ_WIDTH_COF = `FEATURE_IN_MEM_READ_WIDTH_COF
)(
    input wire                                                                    clk,
    input wire                                                                    rst,
    /*
    input wire   [2:0]                                                            current_kernel_size,
    input wire                                                                    state,
    input wire   [7:0]                                                            feature_size,
    input wire                                                                    CLP_output_flag,
    input wire   [Tm * FEATURE_WIDTH - 1 : 0]                                     CLP_output,
    */
    input wire                                                                   fetcher_to_mem,
    input wire   [7:0]                                                           wr_feature_addr,
    input wire   [DATA_BUS_WIDTH - 1 : 0]                                        wr_feature_data,
    input wire                                                                   wr_feature_sel,

    output wire                                                                   fetcher_to_mem_0,
    output wire   [7:0]                                                           wr_feature_addr_0,
    output wire   [DATA_BUS_WIDTH - 1 : 0]                                        wr_feature_data_0,
    
    output wire                                                                   fetcher_to_mem_1,
    output wire   [7:0]                                                           wr_feature_addr_1,
    output wire   [DATA_BUS_WIDTH - 1 : 0]                                        wr_feature_data_1
);



//signals for ARM wirte feature

// wire                                                                    fetcher_to_mem_0;
// wire   [14:0]                                                           wr_feature_addr_0;
// wire   [FEATURE_WIDTH*2 - 1 : 0]                                        wr_feature_data_0;
// wire                                                                    fetcher_to_mem_1;
// wire   [14:0]                                                           wr_feature_addr_1;
// wire   [FEATURE_WIDTH*2 - 1 : 0]                                        wr_feature_data_1;

assign fetcher_to_mem_0 = (wr_feature_sel == 0) ? fetcher_to_mem : 0;
assign fetcher_to_mem_1 = (wr_feature_sel == 0) ? 0 : fetcher_to_mem;

assign wr_feature_addr_0   = (wr_feature_sel == 0) ? wr_feature_addr : 0;
assign wr_feature_addr_1   = (wr_feature_sel == 0) ? 0 : wr_feature_addr;

assign wr_feature_data_0   = (wr_feature_sel == 0) ? wr_feature_data : 0;
assign wr_feature_data_1   = (wr_feature_sel == 0) ? 0 : wr_feature_data;
 
/* 
always@(posedge clk) begin
    if(rst) begin
        fetcher_to_mem_0 <= 0;
        fetcher_to_mem_1 <= 0;
        wr_feature_addr_0 <= 0;
        wr_feature_addr_1 <= 0;
        wr_feature_data_0 <= 0;
        wr_feature_data_1 <= 0;
    end else begin
        fetcher_to_mem_0 <= (wr_feature_sel == 0) ? fetcher_to_mem : 0;
        fetcher_to_mem_1 <= (wr_feature_sel == 0) ? 0 : fetcher_to_mem;
        wr_feature_addr_0 <= (wr_feature_sel == 0) ? wr_feature_addr : 0;
        wr_feature_addr_1 <= (wr_feature_sel == 0) ? 0 : wr_feature_addr;
    end
end
*/

/*
always@(posedge clk)
    if(rst)
        feature_mem_read_enable <= 0;
    else 
        if(state == 0)
            feature_mem_read_enable <= 0;
        else
            feature_mem_read_enable <= 1;
            
always@(posedge clk)
    if(rst)
        feature_mem_read_enable_p <= 0;
    else
        feature_mem_read_enable_p <= feature_mem_read_enable;     
 
always@(posedge clk)
    if(rst)
        begin
            feature_mem_read_addr <= 0;
            feature_mem_read_cnt2 <= 0;
        end          
    else
        if(state == 0)
            feature_mem_read_cnt2 <= 0;
        else
            if((feature_mem_read_enable_p == 0)&&(feature_mem_read_enable == 1))
                feature_mem_read_addr <= 0;
            else if(feature_mem_read_enable_p == 1)
                begin
                    if(current_kernel_size != 1)
                        if(feature_mem_read_addr <= (feature_size-2))   //!!!!!!!!   30
                            feature_mem_read_addr <= feature_mem_read_addr + 1;
                        else
                            begin
                                if(feature_mem_read_cnt2 == 0)
                                    begin
                                        feature_mem_read_addr <= feature_mem_read_addr + 1;
                                        feature_mem_read_cnt2 <= 1;
                                    end  
                                else if(feature_mem_read_cnt2 == 7)
                                    begin
                                        feature_mem_read_addr <= feature_mem_read_addr + 1;
                                        feature_mem_read_cnt2 <= 8;
                                    end
                                else if(feature_mem_read_cnt2 == 8)
                                    feature_mem_read_cnt2 <= 1;    
                                else
                                    begin
                                        feature_mem_read_cnt2 <= feature_mem_read_cnt2 + 1;
                                    end
                            end
                    else   //kernel_size = 1 
                        begin
                            if(feature_mem_read_cnt2 == 7)
                                begin
                                    feature_mem_read_cnt2 <= 0;   
                                end
                            else if(feature_mem_read_cnt2 == 6)
                                begin
                                    feature_mem_read_addr <= feature_mem_read_addr + 1;
                                    feature_mem_read_cnt2 <= feature_mem_read_cnt2 + 1;  
                                end    
                            else
                                feature_mem_read_cnt2 <= feature_mem_read_cnt2 + 1; 
                        end                       
                end
 */
 /*
always@(posedge clk)
    if(rst)
        feature_mem_read_data_tmp <= 0;
    else 
        if ((current_kernel_size != 1) && (feature_mem_read_cnt2 == 2))
            feature_mem_read_data_tmp <= feature_mem_read_data >> (FEATURE_WIDTH*Tn);
        else if ((current_kernel_size == 1) && (feature_mem_read_cnt2 == 0))
            feature_mem_read_data_tmp <= feature_mem_read_data >> (FEATURE_WIDTH*Tn); 
        else
            feature_mem_read_data_tmp <= feature_mem_read_data_tmp >> (FEATURE_WIDTH*Tn);
 
always@(posedge clk)
    if(rst)
        line_buffer_enable <= 0;
    else
        if(state == 0)
            line_buffer_enable <= 0;
        else
            if((feature_mem_read_enable_p == 0)&&(feature_mem_read_enable == 1))
                line_buffer_enable <= 1;
            else
                line_buffer_enable <= line_buffer_enable;
*/
 
endmodule    

