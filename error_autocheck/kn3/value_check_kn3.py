import numpy as np
from PIL import Image 
from scipy import signal,misc,ndimage

#parameters
Tm_even_file = "Tm_0_ram_even.txt"
Tm_odd_file = "Tm_0_ram_odd.txt"
image_file = "mnist_train_1.png"
img_row = 28
img_column = 28
kernel_size = 3
out_row = img_row - kernel_size + 1
out_column = img_column - kernel_size + 1
out_number = out_row * out_column
str_line = ""


#verilog sim output (convolved)
Tm_out_even = np.loadtxt(Tm_even_file) 
Tm_out_odd = np.loadtxt(Tm_odd_file) 

Tm_out_even_del = Tm_out_even[0 : 338]
tm_out_even_arr = np.reshape(Tm_out_even_del, (13, 26)).astype(int)
Tm_out_odd_del = Tm_out_odd[0 : 338]
tm_out_odd_arr = np.reshape(Tm_out_odd_del, (13, 26)).astype(int)

for i in range(13):
	if i == 0:
		tm_out_arr_tmp = np.append(tm_out_even_arr[i], tm_out_odd_arr[i], axis=0)
	else :
		tm_out_arr_tmp = np.append(tm_out_arr_tmp, tm_out_even_arr[i], axis=0)
		tm_out_arr_tmp = np.append(tm_out_arr_tmp, tm_out_odd_arr[i], axis=0)
tm_out_arr = np.reshape(tm_out_arr_tmp, (out_row, out_column)).astype(int)

#image input
image = Image.open(image_file) # use Image.open in PIL to open the image
image_arr = np.array(image) # convert to numpy array

#image conv
w = np.ones((kernel_size,kernel_size))
image_conv=signal.convolve2d(image_arr,w,'valid')#no padding


#bias
image_bias = image_conv + np.ones((out_row, out_column))
image_bias = image_bias.astype(int)

#compare
error = image_bias - tm_out_arr  #astype:convert to int

#print(error)
#print(tm_out_arr)
#print(image_bias)


fileObject = open('py_conv_out.txt', 'w')
for i in range(out_row):
	for j in range(out_column):
		str_tmp = str(image_bias[i][j]).rjust(4,'0')
		str_line = str_line + " " + str_tmp
	fileObject.write(str_line)
	fileObject.write('\n')
	str_line = ""
fileObject.close()

fileObject = open('vrlg_conv_out.txt', 'w')
for i in range(out_row):
	for j in range(out_column):
		str_tmp = str(tm_out_arr[i][j]).rjust(4,'0')
		str_line = str_line + " " + str_tmp
	fileObject.write(str_line)
	fileObject.write('\n')
	str_line = ""
fileObject.close()

fileObject = open('check_error.txt', 'w')
for i in range(out_row):
	for j in range(out_column):
		str_tmp = str(error[i][j]).rjust(4,'0')
		str_line = str_line + " " + str_tmp
	fileObject.write(str_line)
	fileObject.write('\n')
	str_line = ""
fileObject.close()