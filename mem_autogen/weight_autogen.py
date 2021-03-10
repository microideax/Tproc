"""
verilog code version: 28/2/2021
"""


Tn = 4
Tm = 8
img_line = 28
img_column = 28
weight_1 = "0001555555555555"
#order         1st column -> 5th column
weight_0 = "0000000000000000"
scaler_1 = "0000000000000001"
output_list = []


#weight part
for i in range(Tn):
	for j in range(Tm):
		if i == 0:
			mem = weight_1
		else:
			mem = weight_0
		output_list.append(mem)

#scaler part
for line in range(img_line - 4):
	for column in range(img_column - 4):
		for channel in range(Tm):
			mem = scaler_1
			output_list.append(mem)

#output
fileObject = open('i_weight_init.mem', 'w')
for output in output_list:
	#print(output_list[l])
	fileObject.write(output)
	fileObject.write('\n')
fileObject.close()