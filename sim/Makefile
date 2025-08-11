
PYTHON := python3
IVERILOG := iverilog$(ICARUS_SUFFIX)
VVP := vvp$(ICARUS_SUFFIX)

CORE = ../FazyRV-ExoTiny/FazyRV/rtl
SOC  = ../FazyRV-ExoTiny
TEST_OBJS = $(addsuffix .o,$(basename $(wildcard tests/*.S)))
SOC_TEST_OBJS = $(addsuffix .o,$(basename $(wildcard soc_tests/*.S)))
FIRMWARE_OBJS = firmware/start.o
GCC_WARNS = -Werror -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic
TOOLCHAIN_PREFIX = riscv32-unknown-elf-

SRC_CORE 	= $(wildcard $(CORE)/*.v $(CORE)/*.sv)
SRC_DESIGN 	= $(wildcard $(SOC)/rtl/*.v $(SOC)/rtl/*.sv $(SOC)/ $(SOC)/WdgRV/rtl/reg/*.v $(SOC)/WdgRV/submodules/rggen-verilog-rtl/*.v)
SRC_DESIGN  += $(SOC)/WdgRV/rtl/wdg_top.v $(SOC)/WdgRV/rtl/cntr.v $(SOC)/WdgRV/rtl/fsm.v $(SOC)/WdgRV/rtl/reg/wdgrv_regs.v $(SOC)/WdgRV/rtl/clkdiv.v $(SOC)/WdgRV/rtl/reset_ctrl.v
SRC_DESIGN  += ../src/heichips25_fazyrv_exotiny.sv
SRC_SIM 	= $(wildcard ../tb/*.v ../tb/*.sv)

test: testbench.vvp firmware/rom.hex
	$(VVP) -N $< +firmware=firmware/rom.hex

test_vcd: testbench.vvp firmware/rom.hex
	$(VVP) -N $< +vcd +noerror +firmware=firmware/rom.hex

testbench.vvp: $(SRC_CORE) $(SRC_DESIGN) $(SRC_SIM) 
	$(IVERILOG) -g2005-sv -DSIM -DDEBUG -I $(SOC)/WdgRV/submodules/rggen-verilog-rtl/ -o $@ $^
	chmod -x $@

firmware/rom.hex: firmware/firmware.elf firmware/makehex.py
	$(TOOLCHAIN_PREFIX)objcopy -O binary firmware/firmware.elf firmware/rom.bin
	$(PYTHON) firmware/makehex.py firmware/rom.bin 32768 > $@

firmware/firmware.bin: firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) $(SOC_TEST_OBJS) firmware/riscv.ld
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,firmware/riscv.ld,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) $(SOC_TEST_OBJS) -lgcc
	chmod -x $@
	$(TOOLCHAIN_PREFIX)objdump --disassemble-all $@ >> firmware/firmware.txt

firmware/start.o: firmware/start.S
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i -o $@ $<

firmware/%.o: firmware/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i_zicsr -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

tests/%.o: tests/%.S tests/riscv_test.h tests/test_macros.h
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i_zicsr -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

soc_tests/%.o: soc_tests/%.S tests/riscv_test.h tests/test_macros.h soc_tests/test_macros_custom.h
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i_zicsr -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) $(SOC_TEST_OBJS) firmware/firmware.map firmware/start.o firmware/firmware.bin firmware/firmware.hex firmware/firmware.elf \
		testbench.vvp firmware/firmware.txt tb.vcd firmware/rom.hex firmware/rom.bin

.PHONY: test test_vcd
