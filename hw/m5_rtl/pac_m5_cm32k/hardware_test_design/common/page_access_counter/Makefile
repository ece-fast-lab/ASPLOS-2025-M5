
# This Makefile is not used.
#Collect All Source Files
PKG_SRCS := $(PWD)/include/ctrl_signal_types.sv
HDL_SRCS := $(shell find $(PWD)/hdl -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/hvl -name '*.sv' -o -name '*.v')
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)

VCS_FLAGS= -full64 -sv=2012 +lint=all,noSVA-UA,noNS,noSVA-AECASR -timescale=1ns/10ps -debug_acc+all -kdb -fsdb +v2k

.PHONY: clean
.PHONY: run

sim/simv: $(SRCS) 
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -l compile.log

run: sim/simv
	cd sim && ./simv -l simualtion.log

clean: 
	rm -rf sim
