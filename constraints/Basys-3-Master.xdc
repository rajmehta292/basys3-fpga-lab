## Official Digilent Basys 3 rev B master pin reference.
## This compact map is intentionally non-active; use basys3_demo.xdc for the
## working design and consult Digilent's full master XDC for exact declarations.

## Clock: W5 (100 MHz)
## Switches SW0..SW15: V17 V16 W16 W17 W15 V15 W14 W13 V2 T3 T2 R3 W2 U1 T1 R2
## LEDs LD0..LD15: U16 E19 U19 V19 W18 U15 U14 V14 V13 V3 W3 U3 P3 N3 P1 L1
## Seven-segment {A..G}: W7 W6 U8 V8 U5 V5 U7; DP: V7; AN0..AN3: U2 U4 V4 W4
## Buttons {C U L R D}: U18 T18 W19 T17 U17
## Pmod JA: J1 L2 J2 G2 H1 K2 H2 G3
## Pmod JB: A14 A16 B15 B16 A15 A17 C15 C16
## Pmod JC: K17 M18 N17 P18 L17 M19 P17 R18
## XADC Pmod: J3 L3 M2 N2 K3 M3 M1 N1
## VGA: red G19 H19 J19 N19; blue N18 L18 K18 J18;
##       green J17 H17 G17 D17; sync P19 R19
## USB-UART: RsRx B18, RsTx A18
## USB HID/PS2: PS2Clk C17, PS2Data B17
## Quad-SPI: DQ0..DQ3 D18 D19 G18 F18; CS# K19

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
