// This is the overall state machine of the accelerator
// States: 
// 000000 -- Idle
// 000001 -- Fetch instruction from external mem
// 000010 -- Instruction mem NOT EMPTY
// 000100 -- Fetch instruction from instruction mem
// 001000 -- Decode instruction and send parameters to corresponding component
// 010000 -- execution of the instruction
// 100000 -- Instruction executed

module top_fsm(
    input clk,
    input rst,

    input               acc_enable,
    input               i_mem_empty,
    input               CLP_state,

    input [63:0]        i_mem_din,
    
    output reg [9:0]    i_mem_addr,
    output reg          i_mem_rd_enable,
    
    output reg          fetch_instruction_from_ddr,
    output reg          instruction_enable,
    output reg [63:0]   ctr
    ); 

reg [6:0] state;

always@(posedge clk)
    if(rst)
        begin
            instruction_enable <= 0;
            ctr <= 0;
            state <= 6'b000000;
            fetch_instruction_from_ddr <= 1'b0;
            i_mem_rd_enable <= 1'b0;
        end
    else
        begin
            case(state)
                6'b000000:begin // Idle state
                    if(acc_enable == 1)
                        state <= 6'b000001;
                    else 
                        state <= state;
                end    
                6'b000001:begin // if i_mem empty, fetch instruction from ddr, else skip
                    if(i_mem_empty != 1)
                        begin
                            state <= state << 1;
                        end
                    else
                        begin
                            state <= state;
                            fetch_instruction_from_ddr <= 1'b1;
                        end
                end
                6'b000010:begin // instruction mem not empty
                    state <= state << 1;
                    fetch_instruction_from_ddr <= 1'b0;
                    i_mem_rd_enable <= 1'b1;
                    ctr <= i_mem_din;
                    instruction_enable <= 1'b1;
                end
                6'b000100:begin // fetch instruction from i_mem
                    instruction_enable<=1'b0;
                    i_mem_rd_enable <= 1'b0;
                    state <= state << 1;
                end
                6'b001000:begin // instruction decoding stage
                    state <= state << 1;
                end  
                6'b010000:begin // instruction execution stage
                    if(CLP_state == 1) 
                    begin
                        state <= 6'b000000;
                        i_mem_addr <= i_mem_addr + 1'b1;
                    end
                    else
                        state <= state;
                end
                default: state <= 6'b000000;
            endcase
        end

endmodule 