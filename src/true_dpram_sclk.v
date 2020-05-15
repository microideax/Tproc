
// This is a functional unit without verifying the resource effectiveness
// TODO: evaluate the resource concumption when compared to the generated dual-port ram from vivado

module true_dpram_sclk #(
  parameter DATA_WIDTH = 64,
  parameter ADDR_WIDTH = 4,
  parameter RAM_DEPTH = (1 << ADDR_WIDTH)
)(
	input [DATA_WIDTH-1:0] data_a, data_b,
	input [ADDR_WIDTH-1:0] addr_a, addr_b,
	input we_a, we_b, clk,
	output reg [DATA_WIDTH-1:0] q_a, q_b
);
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[RAM_DEPTH-1:0];
	
	// Port A
	always @ (posedge clk)
	begin
		if (we_a) 
		begin
			ram[addr_a] <= data_a;
			q_a <= data_a;
		end
		else 
		begin
			q_a <= ram[addr_a];
		end
	end
	
	// Port B
	always @ (posedge clk)
	begin
		if (we_b)
		begin
			ram[addr_b] <= data_b;
			q_b <= data_b;
		end
		else
		begin
			q_b <= ram[addr_b];
		end
	end
	
endmodule