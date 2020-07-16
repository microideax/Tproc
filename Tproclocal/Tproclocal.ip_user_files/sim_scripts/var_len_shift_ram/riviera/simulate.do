onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+var_len_shift_ram -L xbip_utils_v3_0_10 -L c_reg_fd_v12_0_6 -L c_mux_bit_v12_0_6 -L c_shift_ram_v12_0_13 -L xil_defaultlib -L secureip -O5 xil_defaultlib.var_len_shift_ram

do {wave.do}

view wave
view structure

do {var_len_shift_ram.udo}

run -all

endsim

quit -force
