onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+asymmetric_fifo -L fifo_generator_v13_2_4 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.asymmetric_fifo xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {asymmetric_fifo.udo}

run -all

endsim

quit -force
