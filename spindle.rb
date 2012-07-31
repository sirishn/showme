#!/usr/bin/env arch -i386 ruby

require 'plotter'

class SpindleTest < App
  def on_init
    @plot_channels = [[0x30, "float"], [0x32, "float"], [0x34, "float"]]
    #@plot_type = ["line", "raster", "line", "line", "raster"]
    #@plot_channels = [[0x20, "fixed"], [0x26, "int32"], [0x30, "int32"], [0x22, "fixed"], [0x24, "fixed"], [0x28, "int32"], [0x38, "int32"]]
    @plot_type = ["line", "line", "line"]
    @plot_titles = ["lce", "Ia afferent", "II afferent" ]
    #@bitfile = "synapse_xem6010.bit"
    @fpga = FPGA.new("spindle_xem6010.bit")
    @fpga.send_clk_divider 47*128
    PlotFrame.new("hello world", @fpga, @plot_channels, @plot_type, @plot_titles).show
  end
end

#GC.disable            # disable garbage collection to prevent wxRuby crash
SpindleTest.new.main_loop   # start the show!
