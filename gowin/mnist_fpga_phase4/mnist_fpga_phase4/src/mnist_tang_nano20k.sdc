# Tang Nano 20K onboard oscillator
# 27 MHz = 37.037 ns period
create_clock -name clk27 -period 37.037 -waveform {0 18.5185} [get_ports {clk27}]
