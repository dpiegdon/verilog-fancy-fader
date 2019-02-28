
DEVICE=hx1k
PACKAGE=tq144
PCF=icestick.pcf

QUIET=-q



.PHONY: all prog clean

.PRECIOUS: %.json %.asc %.bin %.rpt




all: top.rpt

prog: top.bin
	iceprog $<

clean:
	-rm -f *.json
	-rm -f *.asc
	-rm -f *.bin
	-rm -f *.rpt




top.json: \
	top.v




%.json: %.v
	yosys -Q $(QUIET) -p 'synth_ice40 -top $(subst .v,,$<) -json $@' $^

%.asc: %.json
	@# "--force" is required because nextpnr sees the combinatorial
	@# loop of a ringoscillator and raises an error
	nextpnr-ice40 $(QUIET) --force --$(DEVICE) --package $(PACKAGE) --pcf $(PCF) --json $< --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -p $(PCF) -P $(PACKAGE) -d $(DEVICE) -r $@ -m -t $<

