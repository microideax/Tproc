`timescale 1ns / 1ns
`include "network_para.vh"

module output_related_tb();

parameter KERNEL_SIZE_5_MODE = `KERNEL_SIZE_5_MODE;
parameter KERNEL_SIZE_3_MODE = `KERNEL_SIZE_3_MODE;
parameter KERNEL_SIZE_1_MODE = `KERNEL_SIZE_1_MODE;
parameter NORMAL_CONV_MODE = 8'h01;
parameter DW_CONV_MODE = 8'h02;
parameter FEATURE_WIDTH = `FEATURE_WIDTH;
parameter BUFFER_NUM = `A_BUFFER_NUM;
parameter RAM_DEPTH = `A_BUFFER_DEPTH;
parameter CONV_5 = 0;
parameter CONV_3 = 1;
parameter DW_5 = 2;
parameter DW_3 = 3;
parameter CONV_PW = 4;
parameter RD_MODE = 5;


reg clk;
reg rst;

reg [15:0] layer_width;
reg [1:0] kn_size_mode;
reg [7:0] com_type;
reg wr_rd_mode, module_cnt_rst, rd_out_en;
reg [4:0] current_channel_NO;
//local signal
reg data_comein, data_comeout, initial_iteration;
reg [3:0] testing_mode;
reg [FEATURE_WIDTH-1:0] data_in_cnt, stop_num, data_out_cnt;
wire [FEATURE_WIDTH-1:0] data_cnt_div_8;
reg [BUFFER_NUM*FEATURE_WIDTH-1:0] data_in;
wire [BUFFER_NUM*FEATURE_WIDTH-1:0] data_out;
wire [3:0] total_row_num, total_channel_num;

output_module inst_output_module (
	.clk                (clk),
	.rst                (rst),
	.initial_iteration  (initial_iteration),
	.cnt_rst         	(module_cnt_rst),
	.layer_width        (layer_width),
	.kn_size_mode       (kn_size_mode),
	.com_type           (com_type),
	.wr_rd_mode         (wr_rd_mode),
	.current_channel_NO (current_channel_NO),
	.rd_out_en          (rd_out_en),
	.data_in            (data_in),
	.data_out           (data_out)
);

/*
explanation for two signals:
module_cnt_rst: rst the input/output counter of A-buffer controller. Do it at the beginning of every wr/rd period
initial_iteration: the first writing period for A-buffer
*/
initial begin
	//basic signals
	$timeformat(-9, 0, " ns", 10);
	data_in_cnt = 0;
	data_out_cnt = 0;
    clk = 0;
    rst = 1;
    module_cnt_rst = 1;
    initial_iteration = 1;//currently just set to be 1.
    #50;
    rst = 0;
    module_cnt_rst = 0;
    //configuration
	#20;
	layer_width = 9'd28;
	#50;
	testing_mode = CONV_PW; // when verification different modes, only change this
	#30;
	data_comein = 1;
	data_comeout = 0;
	#15000
	data_comein = 0;
	testing_mode = RD_MODE;
	module_cnt_rst = 1;
	#50
	module_cnt_rst = 0;
	#100
	data_comeout = 1;
end


//configuration
always @(*) begin
	case (testing_mode)
		CONV_5 : begin
			com_type = NORMAL_CONV_MODE;
			kn_size_mode = KERNEL_SIZE_5_MODE;
			wr_rd_mode = 1;//wr
			stop_num = layer_width*5*8 - 1;
		end
		CONV_3 : begin
			com_type = NORMAL_CONV_MODE;
			kn_size_mode = KERNEL_SIZE_3_MODE;
			wr_rd_mode = 1;//wr		
			stop_num = layer_width*2*8 - 1;	
		end
		DW_5 : begin
			com_type = DW_CONV_MODE;
			kn_size_mode = KERNEL_SIZE_5_MODE;
			wr_rd_mode = 1;//wr
			stop_num = layer_width*5 - 1;			
		end
		DW_3 : begin
			com_type = DW_CONV_MODE;
			kn_size_mode = KERNEL_SIZE_3_MODE;
			wr_rd_mode = 1;//wr		
			stop_num = layer_width*2 - 1;	
		end
		CONV_PW : begin
			com_type = NORMAL_CONV_MODE;
			kn_size_mode = KERNEL_SIZE_1_MODE;
			wr_rd_mode = 1;//wr
			stop_num = (layer_width/5+(layer_width%5 != 0))*8 - 1;			
		end
		RD_MODE : begin
			wr_rd_mode = 0;//rd
			stop_num = total_row_num*(layer_width/25+(layer_width%25 != 0))*total_channel_num-1;
		end

		default : begin
			com_type = 0;
			kn_size_mode = 0;
			wr_rd_mode = 0;
			stop_num = 0;	
		end
	endcase
end 

//data transmission
always @(posedge clk or posedge rst) begin
	if (rst) begin
		data_in_cnt <= 0;
		current_channel_NO <= 0;
		rd_out_en <= 0;
		data_in <= 0;
	end
	else begin
		case (testing_mode)
			CONV_5 : begin
				if(data_comein&&(data_in_cnt!=stop_num)) begin
					data_in_cnt <= data_in_cnt + 1;//this signal can be extracted out;
					current_channel_NO <= data_in_cnt%8+1;
					rd_out_en <= 0;
					data_in <= {384'd0, data_cnt_div_8};
				end
				else begin 
					data_in_cnt <= data_in_cnt;
					current_channel_NO <= 0;
					rd_out_en <= 0;
					data_in <= 0;
				end
			end
			CONV_3 : begin
				if(data_comein&&(data_in_cnt!=stop_num)) begin
					data_in_cnt <= data_in_cnt + 1;
					current_channel_NO <= data_in_cnt%8+1;
					rd_out_en <= 0;
					data_in <= {368'd0, data_cnt_div_8, data_cnt_div_8};
				end
				else begin 
					data_in_cnt <= data_in_cnt;
					current_channel_NO <= 0;
					rd_out_en <= 0;
					data_in <= 0;
				end
			end
			DW_5 : begin
				if(data_comein&&(data_in_cnt!=stop_num)) begin
					data_in_cnt <= data_in_cnt + 1;
					current_channel_NO <= 1;
					rd_out_en <= 0;
					data_in <= {336'b0, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt};
				end
				else begin 
					data_in_cnt <= data_in_cnt;
					current_channel_NO <= 0;
					rd_out_en <= 0;
					data_in <= 0;
				end
			end
			DW_3 : begin
				if(data_comein&&(data_in_cnt!=stop_num)) begin
					current_channel_NO <= 1;
					rd_out_en <= 0;
					data_in_cnt <= data_in_cnt + 1;
					data_in <= {272'b0, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt};
				end
				else begin 
					data_in_cnt <= data_in_cnt;
					current_channel_NO <= 0;
					rd_out_en <= 0;
					data_in <= 0;
				end
			end
			CONV_PW : begin
				if(data_comein&&(data_in_cnt!=stop_num)) begin
					data_in_cnt <= data_in_cnt + 1;
					current_channel_NO <= data_in_cnt%8+1;
					rd_out_en <= 0;
					data_in <= {data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, 
									data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt,
									data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt,
									data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt,
									data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt, data_in_cnt
									};
				end
				else begin 
					data_in_cnt <= data_in_cnt;
					current_channel_NO <= 0;
					rd_out_en <= 0;
					data_in <= 0;
				end
			end
			RD_MODE : begin
				data_out_cnt <= (data_comeout&&(data_out_cnt!=stop_num)) ? data_out_cnt + 1 : data_out_cnt;
				current_channel_NO <= 0;
				rd_out_en <= (data_comeout&&(data_out_cnt!=stop_num)) ? 1 : 0;
				data_in <= 0;
			end
			default : begin
				data_in_cnt <= 0;
				current_channel_NO <= 0;
				rd_out_en <= 0;
				data_in <= 0;
			end
		endcase
	end

end

always #5 clk = ~clk;

assign total_row_num = (kn_size_mode == KERNEL_SIZE_3_MODE) ? 4 : 5;
assign total_channel_num = (com_type == 8'h01) ? 8 //conv
                         : (com_type == 8'h02) ? 4 //dw conv
                         : 8;//default
assign data_cnt_div_8 = data_in_cnt/8;

endmodule