VIVADO ?= vivado
VIVADO_LAB ?= vivado_lab
XSDB ?= xsdb
IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: help check milestone1-sim sim-all catalog-check catalog-build synth-generic build-openxc7 program-openxc7 qt-build install-vivado create build build-streaming sim-streaming probe program program-lab clean

help:
	@echo "make check       - inspect USB, drivers, and installed FPGA tools"
	@echo "make milestone1-sim - run the self-checking streaming simulation"
	@echo "make sim-all       - run all streaming simulations and top elaboration"
	@echo "make catalog-check - run all catalog project and streaming regressions"
	@echo "make catalog-build - build the additional board-only project bitstreams"
	@echo "make build-openxc7 - synthesize, route, and generate a Basys3 bitstream without Vivado"
	@echo "make program-openxc7 - program build/openxc7/basys3_demo.bit through JTAG"
	@echo "make qt-build     - build the Qt UART telemetry dashboard"
	@echo "make install-vivado - install AMD Vivado 2026.2 from Downloads"
	@echo "make build-streaming - synthesize and implement the streaming top"
	@echo "make sim-streaming - run the default streaming test in Vivado XSIM"
	@echo "make synth-generic - run an informational Yosys XC7 resource estimate"
	@echo "make create      - create build/basys3_demo Vivado project"
	@echo "make build       - synthesize, implement, and write build/basys3_demo.bit"
	@echo "make probe       - enumerate a running hw_server via XSDB"
	@echo "make program     - program build/basys3_demo.bit via XSDB"
	@echo "make program-lab - program via Vivado Lab Hardware Manager"

check:
	./scripts/check_environment.sh

milestone1-sim:
	IVERILOG=$(IVERILOG) VVP=$(VVP) ./sim/run_iverilog.sh

sim-all:
	IVERILOG=$(IVERILOG) VVP=$(VVP) ./sim/run_all.sh

catalog-check:
	./scripts/run_catalog_checks.sh

catalog-build:
	./scripts/build_project_catalog.sh

build-openxc7:
	./scripts/build_openxc7_demo.sh

program-openxc7:
	./scripts/program_openxc7_demo.sh

qt-build:
	./scripts/build_qt_monitor.sh

install-vivado:
	./scripts/install_vivado_2026_2.sh

build-streaming:
	$(VIVADO) -mode batch -source scripts/build_streaming_bitstream.tcl

sim-streaming:
	$(VIVADO) -mode batch -source scripts/run_streaming_xsim.tcl

synth-generic:
	./scripts/run_yosys_xc7_estimate.sh

create:
	$(VIVADO) -mode batch -source scripts/create_project.tcl

build:
	$(VIVADO) -mode batch -source scripts/build_bitstream.tcl

probe:
	$(XSDB) -quiet scripts/probe_hardware.tcl

program:
	$(XSDB) -quiet scripts/program_xsdb.tcl build/basys3_demo.bit

program-lab:
	$(VIVADO_LAB) -mode batch -source scripts/program_vivado_lab.tcl -tclargs build/basys3_demo.bit

clean:
	rm -rf build/basys3_demo build/*.bit build/*.rpt build/*.jou build/*.log
