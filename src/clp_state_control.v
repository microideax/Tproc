// organizing the control logic into a single block, for further organization of the architecture
module clp_state_control(
input clk,
input rst,
input enable,
input [2:0] current_kernel_size,
//input [11:0] CLP_ctr_cnt,
input [15:0] CLP_work_time,
input [7:0] feature_size,
output reg  CLP_enable,
output reg  CLP_data_ready,
output reg state
);

reg CLP_enable_p;
reg [7:0] CLP_row_cnt;
reg [11:0] CLP_ctr_cnt;


always@(posedge clk) begin
    if(rst) begin
        CLP_ctr_cnt <= 0;
    end 
    else begin
        if(state == 0)
            CLP_ctr_cnt <= 0;
        else
            CLP_ctr_cnt <= CLP_ctr_cnt + 1;  
     end 
end 
  
always@(posedge clk) begin
    if(rst)
        state <= 0;
    else
        if(enable == 1)
            state <= 1;
        else
            if(CLP_ctr_cnt == CLP_work_time)
                state <= 0;
            else
                state <= state;
end    
                
always@(posedge clk)
    if(rst)
        CLP_enable_p <= 0;
    else 
        CLP_enable_p <= CLP_enable;
   
 
always@(posedge clk) begin
    if(rst) begin
            CLP_row_cnt <= 0;
    end 
    else begin
        if((CLP_enable_p == 0) && (CLP_enable == 1))
            CLP_row_cnt <= 0;    
        else 
            if(CLP_data_ready == 1)
                CLP_row_cnt <= CLP_row_cnt + 1; 
            else
                CLP_row_cnt <= CLP_row_cnt;
    end
end 
                    
always@(posedge clk)
    if(rst)
        CLP_data_ready <= 0;
    else 
        if(current_kernel_size == 5)
            begin
                if(CLP_ctr_cnt == 7)
                    CLP_data_ready <= 1;
                else if(CLP_ctr_cnt == CLP_work_time)
                    CLP_data_ready <= 0;
            end
        else if(current_kernel_size == 3)
            begin
                if(CLP_ctr_cnt == 5)
                    CLP_data_ready <= 1;
                else if(CLP_ctr_cnt == CLP_work_time)
                    CLP_data_ready <= 0;
            end
        else  //current_kernel_size == 1
            begin
                if(CLP_ctr_cnt == 1)
                    CLP_data_ready <= 1;
                else if(CLP_data_ready == CLP_work_time)
                    CLP_data_ready <= 0;
            end

    
always@(posedge clk)
    if(rst)
        CLP_enable <= 0;
    else 
        begin
            if(current_kernel_size == 5)
                begin
                    if(CLP_ctr_cnt == 7)
                        CLP_enable <= 1;
                    else if(CLP_ctr_cnt >= CLP_work_time)
                        CLP_enable <= 0;
                    else        
                        if(CLP_row_cnt == feature_size - current_kernel_size - 1)     // if(CLP_row_cnt== 22) 
                            CLP_enable <= 0;
                        else if(CLP_row_cnt == feature_size-2)    //else if(CLP_row_cnt == 26)
                            CLP_enable <= 1;
                        else
                            CLP_enable <= CLP_enable; 
                end
            else if(current_kernel_size == 3)
                begin
                    if(CLP_ctr_cnt == 5)
                        CLP_enable <= 1;
                    else if(CLP_ctr_cnt >= CLP_work_time)
                        CLP_enable <= 0;
                    else        
                        if(CLP_row_cnt== 24) 
                            CLP_enable <= 0;
                        else if(CLP_row_cnt == 26)
                            CLP_enable <= 1; 
                end
            else //current_kernel_size == 1
                begin
                    if(CLP_ctr_cnt == 1)
                        CLP_enable <= 1;
                    else if(CLP_ctr_cnt >= CLP_work_time)
                        CLP_enable <= 0;
                    else 
                        CLP_enable <= CLP_enable;
                
                end
        end

endmodule