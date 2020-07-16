vlib work
vlib riviera

vlib riviera/xbip_utils_v3_0_10
vlib riviera/c_reg_fd_v12_0_6
vlib riviera/c_mux_bit_v12_0_6
vlib riviera/c_shift_ram_v12_0_13
vlib riviera/xil_defaultlib

vmap xbip_utils_v3_0_10 riviera/xbip_utils_v3_0_10
vmap c_reg_fd_v12_0_6 riviera/c_reg_fd_v12_0_6
vmap c_mux_bit_v12_0_6 riviera/c_mux_bit_v12_0_6
vmap c_shift_ram_v12_0_13 riviera/c_shift_ram_v12_0_13
vmap xil_defaultlib riviera/xil_defaultlib

vcom -work xbip_utils_v3_0_10 -93 \
"../../../ipstatic/hdl/xbip_utils_v3_0_vh_rfs.vhd" \

vcom -work c_reg_fd_v12_0_6 -93 \
"../../../ipstatic/hdl/c_reg_fd_v12_0_vh_rfs.vhd" \

vcom -work c_mux_bit_v12_0_6 -93 \
"../../../ipstatic/hdl/c_mux_bit_v12_0_vh_rfs.vhd" \

vcom -work c_shift_ram_v12_0_13 -93 \
"../../../ipstatic/hdl/c_shift_ram_v12_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../Tproclocal.srcs/sources_1/ip/var_len_shift_ram/sim/var_len_shift_ram.vhd" \


