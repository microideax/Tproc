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
    input               i_mem_full,
    input               instr_exe_state, // this signal indicate the instruction is executed, then move to the next one

    input [63:0]        i_mem_din,
    
    output reg [9:0]    i_mem_addr,
    output reg          i_mem_rd_enable,
    
    output reg          fetch_instruction_from_ddr,
    output reg          instruction_enable,
    output wire [63:0]   ctr
    ); 

reg i_mem_full_tmp;
reg [6:0] state;
reg [15:0] instruction_exe_cnt;

assign ctr = i_mem_din;

always@(posedge clk)begin
    i_mem_full_tmp <= i_mem_full;
end

always@(posedge clk)
    if(rst)
        begin
            instruction_enable <= 0;
            // ctr <= 0;
            state <= 6'b000000;
            fetch_instruction_from_ddr <= 1'b0;
            i_mem_rd_enable <= 1'b0;
            instruction_exe_cnt <= 16'b0;
        end
    else
        begin
            case(state)
                6'b000000:begin // Idle state
                    if(acc_enable == 1 && i_mem_empty)
                        state <= 6'b000001;
                    else 
                        state <= state;
                end    
                6'b000001:begin // if i_mem empty, fetch instruction from ddr, else skip
                    // if(i_mem_empty != 1)
                    if(i_mem_full_tmp == 1)
                        begin
                            fetch_instruction_from_ddr <= 1'b0;
                            state <= state << 1;
                        end
                    else begin
                            state <= state;
                            fetch_instruction_from_ddr <= 1'b1;
                    end
                end
                6'b000010:begin // instruction mem not empty, read instruction to instrution bus 'ctr'
                    state <= state << 1;
                    fetch_instruction_from_ddr <= 1'b0;
                    i_mem_rd_enable <= 1'b1;
                end
                6'b000100:begin // fetch instruction from i_mem
                    i_mem_rd_enable <= 1'b0;
                    instruction_enable <= 1'b1;
                    state <= state << 1;
                end
                6'b001000:begin // instruction decoding stage
                    state <= state << 1;
                    instruction_enable<=1'b0;
                    // ctr <= i_mem_din;
                end  
                6'b010000:begin // instruction execution stage
                    if(instr_exe_state == 1 && i_mem_empty) begin
                        state <= 6'b000001;
                        i_mem_addr <= 0;
                    end
                    else if(instr_exe_state == 1 && (!i_mem_empty))begin 
                        state <= 6'b000010;
                        i_mem_addr <= i_mem_addr + 1'b1;
                        instruction_exe_cnt <= instruction_exe_cnt + 1'b1;
                    end
                    else
                        state <= state;
                end
                default: state <= 6'b000000;
            endcase
        end

// simulation annotations
always@ (state) begin
    case (state) 
    6'b000000: begin
        $display($realtime, "%b", state, " Top state: Initial");    
    end
    6'b000001: begin
        $display($realtime, "%b", state, " Top state: CLP fetch instruction.");    
    end
    6'b000010: begin
        $display($realtime, "%b", state, " Top state: Instr Decoder fetch instruction start.");    
    end
    6'b000100: begin
        $display($realtime, "%b", state, " Top state: Fetch instr from i_mem.");    
    end
    6'b001000: begin
        $display($realtime, "%b", state, " Top state: Instruction Decoding.");    
    end
    6'b010000: begin
        $display($realtime, "%b", state, " Top state: Instruction Executed.");    
    end
    default: ;
    endcase
end
/*
always@ (i_mem_empty) begin
    $display($realtime, " Instruction memory empty: %b", i_mem_empty, "  Fetching instructions from ext mem.");
end
always@ (i_mem_full) begin
    $display($realtime, " Instruction memory full: %b", i_mem_full, "  Fetched instructions from ext mem.");
end
// always@ (i_mem_rd_enable) begin
    // $display($realtime, " Instruction ready: %b", i_mem_rd_enable);
// end
always@ (instruction_enable) begin
    $display($realtime, " First instruction into instr decoder.");
end
always@ (instr_exe_state) begin
    $display($realtime, " Instruction executed");
end
*/
always@(instruction_exe_cnt) begin
    $display($realtime, " Instruction counter value: %0d", instruction_exe_cnt);
end

endmodule 