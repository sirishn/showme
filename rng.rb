#!/usr/bin/env arch -i386 ruby

require 'plotter'

class RNGTest < App
  def on_init
    @title = "LFSR^CASR Combined Random Number Generator"
    #@bitfile = "rng_xem6010.bit"
    @fpga = FPGA.new("rng_xem6010.bit")
    #@fpga.clk_divider = 47*20 & 0xffff
    @fpga.send_clk_divider 740
    @plot_channels = [[0x20, "int32"], [0x20, "int32"], [0x30, "int32"], [0x32,"int32"]]
    @plot_type = ["line", "raster", "raster", "raster"]
    PlotFrame.new(@title, @fpga, @plot_channels, @plot_type, []).show
  end
end

#GC.disable            # disable garbage collection to prevent wxRuby crash
RNGTest.new.main_loop   # start the show!