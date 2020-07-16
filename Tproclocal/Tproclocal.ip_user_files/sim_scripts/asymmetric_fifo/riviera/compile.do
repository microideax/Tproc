vlib work
vlib riviera

vlib riviera/fifo_generator_v13_2_4
vlib riviera/xil_defaultlib

vmap fifo_generator_v13_2_4 riviera/fifo_generator_v13_2_4
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work fifo_generator_v13_2_4  -v2k5 \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_4 -93 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_4  -v2k5 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../Tproclocal.srcs/sources_1/ip/asymmetric_fifo/sim/asymmetric_fifo.v" \


vlog -work xil_defaultlib \
"glbl.v"

