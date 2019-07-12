# Fancy Fader

Fades random colors through strips of WS2812 LEDs.
Rewrite of WS2812 fancy fader project in Verilog for Lattice HX1K FPGAs.

Purely done for training and out of curiosity.

Original version of fancy fader for ATTiny85:
https://github.com/dpiegdon/digispark-workbench/tree/master/projects/ws2812-fancy-fader

# Implementation notes

Yosys et al are used for compilation. Depending on the version of the compiler suite,
the whole project might fit into a HX1K, or it might not.

Multiplication is used at several places in the code, which results in a very bloated
implementation. No effort has been done to reduce this.

