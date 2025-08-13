
IVERILOG := iverilog$(ICARUS_SUFFIX)
VVP := vvp$(ICARUS_SUFFIX)

SRC_CORE 	= ../../build/exotiny_preproc.v
SRC_DESIGN 	= ../../src/heichips25_fazyrv_exotiny.sv
SRC_SIM 	= heichips_ecp5.sv heichips_ecp5_tb.sv ../../tb/qspi_psram.sv ../../tb/spiflash.v


CORE 		= ../../FazyRV-ExoTiny/FazyRV/rtl

SRC_PRE_CORE 	= $(wildcard $(CORE)/*.v $(CORE)/*.sv)
SRC_PRE_DESIGN 	= $(wildcard ../../FazyRV-ExoTiny/rtl/*.v ../../FazyRV-ExoTiny/rtl/*.sv ../../FazyRV-ExoTiny/WdgRV/rtl/reg/*.v ../../FazyRV-ExoTiny/WdgRV/submodules/rggen-verilog-rtl/*.v)
SRC_PRE_DESIGN  += ../../src/heichips25_fazyrv_exotiny.sv ../../FazyRV-ExoTiny/WdgRV/rtl/wdg_top.v ../../FazyRV-ExoTiny/WdgRV/rtl/cntr.v ../../FazyRV-ExoTiny/WdgRV/rtl/fsm.v ../../FazyRV-ExoTiny/WdgRV/rtl/reg/wdgrv_regs.v ../../FazyRV-ExoTiny/WdgRV/rtl/clkdiv.v ../../FazyRV-ExoTiny/WdgRV/rtl/reset_ctrl.v


test_vcd: testbench.vvp
	$(VVP) -N $< +vcd +noerror +firmware=/home/meinhard/Documents/repos/heichips25-fazyrv-exotiny/emu/firmware/build/firmware.hex

test_pre_vcd: testbench_pre.vvp
	$(VVP) -N $< +vcd +noerror +firmware=/home/meinhard/Documents/repos/heichips25-fazyrv-exotiny/emu/firmware/build/firmware.hex	

testbench.vvp: $(SRC_CORE) $(SRC_DESIGN) $(SRC_SIM) 
	$(IVERILOG) -g2005-sv -DSIM -DDEBUG -o $@ $^
	chmod -x $@

testbench_pre.vvp: $(SRC_PRE_CORE) $(SRC_PRE_DESIGN) $(SRC_SIM) 
	$(IVERILOG) -g2005-sv -DSIM -DDEBUG -I ../../FazyRV-ExoTiny/WdgRV/submodules/rggen-verilog-rtl/  -o $@ $^
	chmod -x $@


.PHONY: test test_vcd
