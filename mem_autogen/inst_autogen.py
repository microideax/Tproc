"""
verilog code version: 10/3/2021

inst template: 
0402002000000008 bias_fetch
0400000000000105 feature_fetch line 0
0400000500010105 feature_fetch line 1
0400000a00020105 feature_fetch line 2
0400000f00030105 feature_fetch line 3
0400001400040105 feature_fetch line 4
0401000000000008 weight_fetch  filter_channel(tn) = 0
0401000801000008 weight_fetch  filter_channel(tn) = 1
0401001002000008 weight_fetch  filter_channel(tn) = 2
0401001803000008 weight_fetch  filter_channel(tn) = 3
0404002000000008 scaler_fetch
4001010000000000 shift vertical reg(reg2: vertical_reg_select  reg3: line_buffer_mod(fetch 5 columns -- 0; 1 column -- 1))
8100000501000100 CONV 

weight_mem order: weight -- bias -- scaler

to conv each line, we need 58 instr.
"""
img_line = 28
img_column = 28
kernel_size = 5
line_buffer_mod = 0 # '0' denotes fetch 5 columns while '1' denotes 1
Tn = 4 # Tn = 4
Tm = 8 # Tm = 8
pxl_num_one_mem_addr = (img_column//8)+((img_column%8)!=0)
CONV = "8100000501000100"
output_list = []

def reformat_str(value, rjust_0):
	new_str = hex(value)[2:].rjust(rjust_0,'0')
	return new_str

def fetch_5_lines(beginning_line, inst_list): #currently only fetch feature channel 0
	for x in range(kernel_size):
		inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
		inst_list.append(inst)
		pass

def fetch_line(beginning_line, inst_list): #currently only fetch feature channel 0
	#let x = 4
	inst = "0400" + reformat_str((beginning_line + 4)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(4, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
	inst_list.append(inst)
	pass

def fetch_weight(inst_list):
	for x in range(Tn):
		inst = "0401" + reformat_str(x*Tm, 4) + reformat_str(x, 2) + "00" + reformat_str(8, 4)
		inst_list.append(inst)
		pass

def fetch_bias(inst_list):
	inst = "0402" + reformat_str(Tn*Tm, 4) + "00000008" #tmp
	inst_list.append(inst)

def fetch_scaler(inst_list):
	inst = "0404" + reformat_str(Tn*Tm + Tm, 4) + "00000008"
	inst_list.append(inst)

def CONV_inst(inst_list):
	inst_list.append(CONV)

def vertical_shift(inst_list, mod):
	if mod == 0:
		inst = "4001010000000000"
	else:
		inst = "4001010100000000"
	inst_list.append(inst)



fetch_weight(output_list)	
fetch_bias(output_list)
fetch_scaler(output_list)


#feature fetch: ram_depth is 16 so counter can not be larger than 2

for i in range(img_line - kernel_size + 1):
	line_buffer_mod = 0
	if i == 0:
		fetch_5_lines(i,output_list)
	else:
		fetch_line(i, output_list)
	for j in range(img_column - kernel_size + 1):
		vertical_shift(output_list, line_buffer_mod)
		CONV_inst(output_list)
		line_buffer_mod = 1
		pass
	pass
	vertical_shift(output_list, line_buffer_mod)
	vertical_shift(output_list, line_buffer_mod)
	vertical_shift(output_list, line_buffer_mod)
	vertical_shift(output_list, line_buffer_mod)

fileObject = open('i_instr_init.mem', 'w')
for inst in output_list:
	#print(output_list[l])
	fileObject.write(inst)
	fileObject.write('\n')
fileObject.close()

"""
verilog code version: 28/2/2021

inst template: 
0402002000000008 bias_fetch
0400000000000105 feature_fetch line 0
0400000500010105 feature_fetch line 1
0400000a00020105 feature_fetch line 2
0400000f00030105 feature_fetch line 3
0400001400040105 feature_fetch line 4
0401000000000008 weight_fetch  filter_channel(tn) = 0
0401000801000008 weight_fetch  filter_channel(tn) = 1
0401001002000008 weight_fetch  filter_channel(tn) = 2
0401001803000008 weight_fetch  filter_channel(tn) = 3
0404002000000008 scaler_fetch
4001010000000000 shift vertical reg(reg2: vertical_reg_select  reg3: line_buffer_mod(fetch 5 columns -- 0; 1 column -- 1))
8100000501000100 CONV 

to conv each line, we need 58 instr.
"""
"""
img_line = 28
img_column = 28
kernel_size = 5
line_buffer_mod = 0 # '0' denotes fetch 5 columns while '1' denotes 1
Tn = 4 # Tn = 4
Tm = 8 # Tm = 8
pxl_num_one_mem_addr = (img_column//8)+((img_column%8)!=0)
CONV = "8100000501000100"
output_list = []

def reformat_str(value, rjust_0):
	new_str = hex(value)[2:].rjust(rjust_0,'0')
	return new_str

def fetch_5_lines(beginning_line, inst_list): #currently only fetch feature channel 0
	for x in range(kernel_size):
		inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
		inst_list.append(inst)
		pass

def fetch_weight(inst_list):
	for x in range(Tn):
		inst = "0401" + reformat_str(x*Tm, 4) + reformat_str(x, 2) + "00" + reformat_str(8, 4)
		inst_list.append(inst)
		pass

def fetch_scaler(beginning_line, inst_list): # total scaler num: (img_line - 4)(img_column - 4)*Tm
	inst = "0404"+ reformat_str(32+beginning_line*24*8,4) +"000000"+reformat_str((img_column - 4)*Tm,2)
	inst_list.append(inst)

def CONV_inst(inst_list):
	inst_list.append(CONV)

def vertical_shift(inst_list, mod):
	if mod == 0:
		inst = "4001010000000000"
	else:
		inst = "4001010100000000"
	inst_list.append(inst)

def fetch_bias(inst_list):
	inst = "0402002000000008" #tmp
	inst_list.append(inst)


	
fetch_bias(output_list)
fetch_weight(output_list)

#feature fetch: ram_depth is 16 so counter can not be larger than 2

for i in range(img_line - kernel_size + 1):
	line_buffer_mod = 0
	fetch_5_lines(i,output_list)
	fetch_scaler(i,output_list)
	for j in range(img_column - kernel_size + 1):
		vertical_shift(output_list, line_buffer_mod)
		CONV_inst(output_list)
		line_buffer_mod = 1
		pass
	pass
	vertical_shift(output_list, line_buffer_mod)
	vertical_shift(output_list, line_buffer_mod)
	vertical_shift(output_list, line_buffer_mod)
	vertical_shift(output_list, line_buffer_mod)

fileObject = open('i_instr_init.mem', 'w')
for inst in output_list:
	#print(output_list[l])
	fileObject.write(inst)
	fileObject.write('\n')
fileObject.close()
"""