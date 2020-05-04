// Instruction analysis 
// Decoding the input instructions and send to different components
// TODO: The future operational pipeline of the Instructions need to be considered. 

`timescale 1ns / 1ps

module instruction_decode(
       input   wire                                         clk,
       input   wire                                         rst,
       input   wire  [63:0]                                 instruction,
       input   wire                                         CLP_enable,
       output  reg   [63:57]                                opcode,
       output  reg   [7:0]                                  feature_size,
       output  reg                                          feature_out_select,     //    0:   CLP write feature to ram0           1:  CLP write feature to ram1
       output  reg                                          feature_in_select,       //   0 :  CLP read feature from ram0          1:  CLP read feature from ram1
       output  reg   [15:0]                                 weight_mem_init_addr,
       output  reg   [7:0]                                  scaler_mem_addr,
       output  reg   [15:0]                                 CLP_work_time,
       output  reg   [2:0]                                  current_kernel_size,
//       output  reg   [10:0]                                 feature_amount,
       output  reg   [3:0]                                  CLP_type );
    
reg [10:0] feature_amount;    
    
always@(posedge clk)
   if(rst)
       begin
           CLP_type                     <= 0;
           current_kernel_size          <= 0;
           CLP_work_time                <= 0;
           scaler_mem_addr              <= 0;
           weight_mem_init_addr         <= 0;
           feature_amount               <= 0;
           feature_in_select            <= 0;
           feature_out_select           <= 0;
           feature_size                 <= 0;
       end   
   else
       begin
           if(CLP_enable == 1)
               begin
                   opcode                  <= instruction[63:57];
                   feature_size            <= instruction[56:49]; 
                   feature_out_select      <= instruction[48];
                   feature_in_select       <= instruction[47];     
                   weight_mem_init_addr    <= instruction[46:31];   
                   scaler_mem_addr         <= instruction[30:23];
                   CLP_work_time           <= instruction[22:7];
                   current_kernel_size     <= instruction[6:4];
                   CLP_type                <= instruction[3:0];   
               end
           else
               begin
                   opcode                  <= opcode;
                   feature_size            <= feature_size;
                   feature_out_select      <= feature_out_select;
                   feature_in_select       <= feature_in_select;
                   weight_mem_init_addr    <= weight_mem_init_addr;
                   scaler_mem_addr         <= scaler_mem_addr;
                   CLP_work_time           <= CLP_work_time;
                   current_kernel_size     <= current_kernel_size; 
                   CLP_type                <= CLP_type;
//                   feature_amount          <= feature_amount;
               end
       end  
endmodule
//

/*

                   CLP_type                <= instruction[3:0];
                   current_kernel_size     <= instruction[6:4];
                   CLP_work_time           <= instruction[17:7];    //
                   scaler_mem_addr         <= instruction[23:18];   //
                   weight_mem_init_addr    <= instruction[39:24];
                   feature_amount          <= instruction[50:40];
                   feature_in_select       <= instruction[51];
                   feature_out_select      <= instruction[52];
                   feature_size            <= instruction[58:53];*/