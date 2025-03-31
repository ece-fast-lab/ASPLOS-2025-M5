.PHONY: simv
.PHONY: clean
.PHONY: run

VCS_FLAGS= -full64 -sv=2012 +lint=all,noSVA-UA,noNS,noSVA-AECASR -timescale=1ns/10ps -debug_acc+all -fsdb +v2k -kdb

all: simv

simv:
	./compile.sh SKIP_DUMMY_COPY=1

noip:
	vcs $(VCS_FLAGS) -f vcs_filelists/top_filelist -top pac_top_tb

run:
	./simv -l simualtion.log -timescale=1ns/10ps

convert:
	fsdb2vcd top_tb.fsdb -o top_tb.vcd

clean:
	rm -f simv
	rm -f *.log
	rm -f *.fsdb
	rm -f *.fsdb.*
	rm -f ucli.key
	rm -f vc_hdrs.h
	rm -rf csrc
	rm -rf simv.daidir
	rm -rf simv.vdb
	rm -rf fsdb2vcdLog
	rm -rf verdi_config_file

	
