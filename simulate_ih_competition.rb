#!/usr/bin/ruby

require 'rubygems'
require './fpga'
require 'csv'

on = 10240
off = 0

ltp = 10
ltd = -10
p_delta = 10

@log = CSV.open("log.csv", "w")
@data = []


### initialize the FPGA neural network
  @fpga = FPGA.new("ih_competition_xem6010.bit")
  @fpga.plot_channels = [ [0x32, "fixed"], [0x34, "fixed"], [0x3c, "fixed"], [0x3e, "fixed"]]
  # @fpga.send_clk_divider 10
  @fpga.send_ltp ltp
  @fpga.send_ltd ltd
  @fpga.send_p_delta p_delta


### set initial gains
  @fpga.send_left_m1_in on
  @fpga.send_right_m1_in on


### inactivate m1 unilaterally between weeks 5-7
  @fpga.send_left_m1_in off
  @fpga.send_right_m1_in on
  # 14 days = 1,209,600 seconds
  # at 365x real time = 3314 seconds
  #sleep 3314  
  (1..3314).each do 
    @data = @fpga.get_plot_data
    p @data
    @log << @data
    #sleep 1
  end

### alternate inactivation for weeks 7-11
  @fpga.send_left_m1_in on
  @fpga.send_right_m1_in off
  # 28 days = 2,419,200 seconds
  # at 365x real time = 6628 seconds
  #sleep 6628
  (1..6628).each do
    @data = @fpga.get_plot_data
    @log << @data
  end

@log.close
