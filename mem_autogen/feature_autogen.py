from PIL import Image 
import numpy as np

def reformat_str(array_value):
	new_str = hex(array_value)[2:].rjust(4,'0')
	return new_str

img_line = 28
img_column = 28
str_line = ""
cnt = 0
list_cnt = 0
output_list = []

image = Image.open("mnist_train_1.png") # use Image.open in PIL to open the image
image_arr = np.array(image) # convert to numpy array
#np.set_printoptions(formatter={'int':hex})
#np.savetxt("mnist_train_1.txt", image_arr)

for i in range(img_line):
	for j in range(img_column):
		cnt = j % 8
		str_tmp = reformat_str(image_arr[i][j])
		str_line = str_line + str_tmp
		if cnt == 7:
			output_list.append(str_line)
			str_line = ""
			list_cnt = list_cnt + 1
			pass
	if str_line != "":
		str_line = str_line.rjust(32, '0')
		output_list.append(str_line)
		str_line = ""
		list_cnt = list_cnt + 1
		pass

fileObject = open('i_feature_init.mem', 'w')
for l in output_list:
	#print(output_list[l])
	fileObject.write(l)
	fileObject.write('\n')
fileObject.close()

#.strip("0x")  to remove "0x" in str
#.rjust(4,'0') to complement str using '0'
#print (reformat_str(image_arr[4][15]))