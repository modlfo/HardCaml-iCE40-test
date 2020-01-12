PROJ = top
PIN_DEF = pins.pcf
DEVICE = hx1k

OCAML_SRC = $(wildcard *.ml)


all: $(PROJ).rpt $(PROJ).bin

top.v: $(OCAML_SRC)
	dune build top.exe
	./_build/default/top.exe

hardcaml: top.v

%.json: %.v
	yosys -p 'synth_ice40 -top top -json $@' $<

%.asc: %.json $(PIN_DEF)
	nextpnr-ice40 --package vq100 --$(DEVICE) --json $< --pcf $(PIN_DEF) --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	sudo iceprogduino $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprogduino $<

clean:
	rm -f $(PROJ).asc $(PROJ).bin $(PROJ).rpt test.vcd top top.v
	dune clean

test: hardcaml
	iverilog -o top top.v test.v
	vvp top
	gtkwave test.vcd &

.PHONY: all prog clean