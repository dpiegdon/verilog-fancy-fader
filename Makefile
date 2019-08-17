
DEVICE=hx1k
PACKAGE=tq144
PCF=icestick.pcf

#QUIET=-q

TESTBENCHES=$(wildcard *_tb.v)
TESTS=$(TESTBENCHES:%.v=%.test)

.PHONY: all prog run_tests clean

.PRECIOUS: %.json %.asc %.bin %.rpt




all: top.rpt

prog: top.bin
	iceprog $<

run_tests: $(TESTS)
	make -C verilog-buildingblocks run_tests
	@for test in $^; do \
		echo $$test; \
		./$$test; \
	done



clean:
	-rm -f *.json
	-rm -f *.asc
	-rm -f *.bin
	-rm -f *.rpt
	-rm *_tb.test
	-rm *_tb.vcd




top.json: \
	verilog-buildingblocks/lattice_ice40/ringoscillator.v \
	verilog-buildingblocks/lattice_ice40/random.v \
	verilog-buildingblocks/random.v \
	verilog-buildingblocks/lfsr.v \
	verilog-buildingblocks/synchronous_reset_timer.v \
	ws2812_fancy_fader.v \
	ws2812_gammasight.v \
	ws2812_output_shifter.v \
	top.v




%_tb.test: %_tb.v %.v
	iverilog -o $@ $^

%.json: %.v
	yosys -Q $(QUIET) -p 'synth_ice40 -top $(subst .v,,$<) -json $@' $^

%.asc: %.json
	nextpnr-ice40 $(QUIET) --promote-logic --opt-timing --ignore-loops --$(DEVICE) --package $(PACKAGE) --pcf $(PCF) --json $< --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -p $(PCF) -P $(PACKAGE) -d $(DEVICE) -r $@ -m -t $<

