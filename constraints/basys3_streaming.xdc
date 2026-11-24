## Basys 3 streaming validation design
## Device: xc7a35tcpg236-1

set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -name sys_clk -period 10.000 -waveform {0.000 5.000} [get_ports CLK100MHZ]

set_property PACKAGE_PIN U18 [get_ports BTN_RST]
set_property PACKAGE_PIN T18 [get_ports BTN_START]
set_property PACKAGE_PIN U17 [get_ports BTN_STOP]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_RST BTN_START BTN_STOP}]

set_property PACKAGE_PIN V17 [get_ports SW_FAULT]
set_property IOSTANDARD LVCMOS33 [get_ports SW_FAULT]

set_property PACKAGE_PIN A18 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]

## Keep board inputs from floating when not actively driven.
set_property PULLDOWN true [get_ports {BTN_RST BTN_START BTN_STOP SW_FAULT}]
