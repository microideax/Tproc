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


"""
kernel_size = 1
img_line = 28
img_column = 28
line_buffer_mod = 0 # '0' denotes fetch 5 columns while '1' denotes 1
Tn = 4 # Tn = 4
Tm = 8 # Tm = 8
pxl_num_one_mem_addr = (img_column//8)+((img_column%8)!=0)
CONV = "8100000501000100"
output_list = []

def reformat_str(value, rjust_0):
	new_str = hex(value)[2:].rjust(rjust_0,'0')
	return new_str

def kernel_size_conf(kn_size, inst_list):
	if kn_size == 5:
		inst = "2000000000000000"
	elif kn_size == 3 :
		inst = "2001000000000000"
	elif kn_size == 1 :
		inst = "2002000000000000"
	else:
		inst = "2000000000000000"
	inst_list.append(inst)

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

#for kernel_size = 5/3
def begin_fetch_lines(beginning_line, inst_list): #currently only fetch feature channel 0
	if kernel_size == 5:
		for_range = 5
	elif kernel_size == 3:
		for_range = 4
	for x in range(for_range):
		inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
		inst_list.append(inst)
		pass

def fetch_5_lines(beginning_line, inst_list): #currently only fetch feature channel 0
	for_range = 5
	for x in range(for_range):
		inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
		inst_list.append(inst)
		pass

#for kernel_size = 5
def fetch_1_line(beginning_line, inst_list): #currently only fetch feature channel 0
	#let x = 4
	x = 4
	inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
	inst_list.append(inst)
	pass

#for kernel_size = 3
def fetch_2_lines(beginning_line, inst_list):
	x = 2
	inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
	inst_list.append(inst)
	x = 3
	inst = "0400" + reformat_str((beginning_line + x)*pxl_num_one_mem_addr, 4) + "00" + reformat_str(x, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
	inst_list.append(inst)
	pass

def fetch_line(beginning_line, inst_list, kn_size):
	if kn_size == 5 :
		fetch_1_line(beginning_line, inst_list)
	elif kn_size == 3 :
		fetch_2_lines(beginning_line, inst_list)

def fetch_1_line_src_dst(source_line, destionation_buffer, inst_list): #currently only fetch feature channel 0
	#let x = 4
	x = 4
	inst = "0400" + reformat_str(source_line*pxl_num_one_mem_addr, 4) + "00" + reformat_str(destionation_buffer, 2) + "01" + reformat_str(pxl_num_one_mem_addr, 2)
	inst_list.append(inst)
	pass



#main function
if (kernel_size == 5 or kernel_size == 3):
	if kernel_size == 5:
		for_i_range = range(img_line - kernel_size + 1)
	elif kernel_size == 3:
		for_i_range = range(img_line - kernel_size + 1)[::2]#0 2 4 6 ...
	kernel_size_conf(kernel_size, output_list)
	fetch_weight(output_list)	
	fetch_bias(output_list)
	fetch_scaler(output_list)
	#feature fetch: ram_depth is 16 so counter can not be larger than 2
	for i in for_i_range:
		line_buffer_mod = 0
		if i == 0:
			begin_fetch_lines(i,output_list)
		else:
			fetch_line(i, output_list, kernel_size)
		for j in range(img_column - kernel_size + 1):
			vertical_shift(output_list, line_buffer_mod)
			CONV_inst(output_list)
			line_buffer_mod = 1
		vertical_shift(output_list, line_buffer_mod)
		vertical_shift(output_list, line_buffer_mod)
		vertical_shift(output_list, line_buffer_mod)
		vertical_shift(output_list, line_buffer_mod)


elif kernel_size == 1 :
	kernel_size_conf(kernel_size, output_list)
	fetch_weight(output_list)	
	fetch_bias(output_list)
	fetch_scaler(output_list)
	lines_have_remainder = ((img_line%5) > 0) #have remainder:1, don't have:0
	column_have_remainder = ((img_column%5) > 0) #have remainder:1, don't have:0

	for i in range(img_line//5): #round up to a integer
		fetch_5_lines(i*5, output_list)
		for j in range(img_column//5 + column_have_remainder):
			line_buffer_mod = 0
			vertical_shift(output_list, line_buffer_mod)
			CONV_inst(output_list)
		for k in range(4*8-5*(img_column//5 + column_have_remainder)):#column remainder part
			line_buffer_mod = 1
			vertical_shift(output_list, line_buffer_mod)

	if lines_have_remainder:#line remainder part
		for l in range(img_line%5):
			fetch_1_line_src_dst(l+img_line//5*5, l, output_list)
		#for m in range(5-img_line%5):
		#	fetch_1_line_src_dst(0, img_line%5+m, output_list)#fetch all-zero line to pad image
		for j in range(img_column//5 + column_have_remainder):
			line_buffer_mod = 0
			vertical_shift(output_list, line_buffer_mod)
			CONV_inst(output_list)
		for k in range(4*8-5*(img_column//5 + column_have_remainder)):
			line_buffer_mod = 1
			vertical_shift(output_list, line_buffer_mod)




fileObject = open('i_instr_init_kn1.mem', 'w')
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

def begin_fetch_lines(beginning_line, inst_list): #currently only fetch feature channel 0
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
	begin_fetch_lines(i,output_list)
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