#!/usr/bin/env arch -i386 ruby

require 'plotter'

class SynapseTest < App
  def on_init
    #@plot_channels = [[0x20, "fixed"], [0x30, "int32"], [0x22, "fixed"], [0x24, "fixed"], [0x38, "int32"]]
    #@plot_type = ["line", "raster", "line", "line", "raster"]
    @plot_channels = [[0x20, "fixed"], [0x26, "int32"], [0x30, "int32"], [0x22, "fixed"], [0x24, "fixed"], [0x28, "int32"], [0x38, "int32"]]
    @plot_type = ["line", "line", "raster", "line", "line", "line", "raster"]
    @plot_titles = ["Presynaptic membrane potential", "# of presynaptic spikes", "Presynaptic spikes", "Synaptic current", "Postsynaptic membrane potential","# of postsynaptic spikes", "Postsynaptic spikes" ]
    #@bitfile = "synapse_xem6010.bit"
    @fpga = FPGA.new("synapse_xem6010.bit")
    @fpga.send_clk_divider 47*128
    PlotFrame.new("hello world", @fpga, @plot_channels, @plot_type, @plot_titles).show
  end
end

#GC.disable            # disable garbage collection to prevent wxRuby crash
SynapseTest.new.main_loop   # start the show!