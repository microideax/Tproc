import numpy as np
from PIL import Image 
from scipy import signal,misc,ndimage

#parameters
Tm_file = "Tm_0_ram_kn1.txt"
image_file = "mnist_train_1.png"
img_row = 28
img_column = 28
kernel_size = 5
out_row = 30
out_column = 30
str_line = ""

#verilog sim output (convolved)
Tm_out = np.loadtxt(Tm_file) 
Tm_out_direct = Tm_out[0 : 900]
Tm_out_reshape = np.zeros((out_row, out_column))
for i in range(900):
	kernel_NO = i//25
	sub_NO_in_kernel = i%25
	row_NO = (kernel_NO//6)*5 + sub_NO_in_kernel%5
	column_NO = (kernel_NO%6)*5 + (4-sub_NO_in_kernel//5)
	Tm_out_reshape[row_NO, column_NO] = Tm_out[i]
Tm_out_crop = Tm_out_reshape[:28,:28].astype(int)

#image input
image = Image.open(image_file) # use Image.open in PIL to open the image
image_arr = np.array(image) # convert to numpy array

##image conv
#w = np.ones((kernel_size,kernel_size))
#image_conv=signal.convolve2d(image_arr,w,'valid')#no padding


#bias
image_bias = image_arr + np.ones((img_row, img_column))
image_bias = image_bias.astype(int)

#compare
error = image_bias - Tm_out_crop  #astype:convert to int

#print(error)
#print(tm_out_arr)
#print(image_bias)


fileObject = open('py_conv_out.txt', 'w')
for i in range(img_row):
	for j in range(img_column):
		str_tmp = str(image_bias[i][j]).rjust(4,'0')
		str_line = str_line + " " + str_tmp
	fileObject.write(str_line)
	fileObject.write('\n')
	str_line = ""
fileObject.close()

fileObject = open('vrlg_conv_out.txt', 'w')
for i in range(img_row):
	for j in range(img_column):
		str_tmp = str(Tm_out_crop[i][j]).rjust(4,'0')
		str_line = str_line + " " + str_tmp
	fileObject.write(str_line)
	fileObject.write('\n')
	str_line = ""
fileObject.close()

fileObject = open('check_error.txt', 'w')
for i in range(img_row):
	for j in range(img_column):
		str_tmp = str(error[i][j]).rjust(4,'0')
		str_line = str_line + " " + str_tmp
	fileObject.write(str_line)
	fileObject.write('\n')
	str_line = ""
fileObject.close()

print(image_bias.sum()-Tm_out_crop.sum())
print(Tm_out_crop.sum())