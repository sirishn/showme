#!/usr/bin/ruby

require 'rubygems'
require './fpga'
require 'csv'

$stdout.sync = true

on = 1024*9
off = 1024*4

ltp = 1
ltd = 3
p_delta = 0

base_strength = 1024*5

time_scale = 0.05

phase1 = (3314*time_scale).to_i
phase2 = (6628*time_scale).to_i



@log = CSV.open("log.csv", "w")
@data = []
@log << ["time", "gain"]


### initialize the FPGA neural network
  @fpga = FPGA.new("ih_competition_xem6010.bit")
#  @fpga = FPGA.new "synapse_xem6010.bit"
#  @fpga.plot_channels = [ [0x32, "fixed"], [0x34, "fixed"], [0x3c, "fixed"], [0x3e, "fixed"]]
  @fpga.plot_channels = [[ 0x3c, "fixed"]]

  @fpga.send_base_strength 0
  @fpga.send_ltp 0
  @fpga.send_ltd 0
  @fpga.send_clk_divider 10 
  @fpga.send_reset

  @fpga.send_base_strength base_strength
  @fpga.send_ltp ltp
  @fpga.send_ltd ltd
#  @fpga.send_p_delta p_delta
  


### set initial gains
#  @fpga.send_left_m1_in on
#  @fpga.send_right_m1_in on


### inactivate m1 unilaterally between weeks 5-7
  puts "Inactivate m1 unilaterally between weeks 5-7"
  puts "Synaptic gain at week 5: #{@fpga.get_plot_data}"
  @fpga.send_left_m1_in off
  @fpga.send_right_m1_in on
  # 14 days = 1,209,600 seconds
  # at 365x real time = 3314 seconds
  #sleep 3314  
  (1..phase1).each do |t|
    @data = @fpga.get_plot_data
    #p @data
    @log << [t, @data]
    sleep 1
  print "\rTime: #{t}/#{phase1+phase2} Gain:#{@data}"
  end

### alternate inactivation for weeks 7-11
  puts "\rAlternate inactivation for weeks 7-11" 
  puts "Synaptic gain at week 7: #{@fpga.get_plot_data}"
  @fpga.send_left_m1_in on
  @fpga.send_right_m1_in off
  # 28 days = 2,419,200 seconds
  # at 365x real time = 6628 seconds
  #sleep 6628
  (phase1+1..phase1+phase2).each do |t|
    print "\rTime: #{t}/#{phase1+phase2} Gain:#{@data}"
    @data = @fpga.get_plot_data
    @log << [t, @data]
    #p @data
    sleep 1
  end
  puts "Synaptic gain at week 11: #{@fpga.get_plot_data}"

@log.close
