
# OpalKelly ruby interface
# based on DES Tester sample

# hi @ siri.sh


require 'OpalKelly'

class FPGA

  attr_accessor :xem, :plot_channels, :clk_divider

  def initialize(bitfile)
    @plot_channels = []
    @control_signals = 0x0000
    initialize_device(bitfile)
    send_reset
    send_clk_rate
    #send_wave
    #send_i_gain_MN
    
  end

  def initialize_device(bitfile)
    @xem = OpalKelly::FrontPanel.new
    if (OpalKelly::FrontPanel::NoError != @xem.OpenBySerial(""))
      puts "A device could not be opened.  Is one connected?"
      return(false)
    end
    
    @xem.LoadDefaultPLLConfiguration

    # Get some general information about the device.
    puts "Device firmware version: #{@xem.GetDeviceMajorVersion}.#{@xem.GetDeviceMinorVersion}"
    puts "Device serial number: #{@xem.GetSerialNumber}"
    puts "Device ID: #{@xem.GetDeviceID}"

    # Download the configuration file.
    if (OpalKelly::FrontPanel::NoError != @xem.ConfigureFPGA(bitfile))
      puts "FPGA configuration failed."
      return(false)
    end

    # Check for FrontPanel support in the FPGA configuration.
    if (false == @xem.IsFrontPanelEnabled)
      puts "FrontPanel support is not available."
      return(false)
    end
    
    puts "FrontPanel support is available."
    return(true)
  end

  def get_plot_data
    @xem.UpdateWireOuts
    out = []
    @plot_channels.each do |addr, type|
      #if type == "int18"
      #  low_word = @xem.GetWireOutValue(addr) & 0xffff
      #  high_word = @xem.GetWireOutValue(addr + 0x01 ) & 0x0003
      #  full_word = (high_word<<16) + low_word
      #  p full_word
      #  if full_word > 0x1FFFF
      #    full_word = -(0x3FFF - full_word + 0x01)
      #  end
      #  out += [full_word]
      #elsif type == "float32"
      if type == "float32"
        low_word = @xem.GetWireOutValue(addr) & 0xffff
        high_word = @xem.GetWireOutValue(addr + 0x01 ) & 0xffff
        full_word = (high_word<<16) + low_word
        out += [full_word].pack('i').unpack('f')
      elsif type == "int32"
        low_word = @xem.GetWireOutValue(addr) & 0xffff
        high_word = @xem.GetWireOutValue(addr + 0x01 ) & 0xffff
        full_word = (high_word<<16) + low_word
        out += [full_word].pack('i').unpack('i')
      elsif type == "fixed"
        low_word = @xem.GetWireOutValue(addr) & 0xffff
        high_word = @xem.GetWireOutValue(addr + 0x01 ) & 0xffff
        full_word = (high_word<<16) + low_word
        fixed_point = [full_word].pack('i').unpack('i')
        out += [fixed_point[0].to_f/1024]
      end
    end
    
    return out
  end
  
  def send_wave
    write_array = []
    #for i in (1..1024) do
    #  write_array+= [0.3*Math.sin(2*Math::PI*i/1024)+1]
    #end
    for j in (1..16) do
      for i in (1..1024) do
        
        #write_array += [0.8] 
        #write_array += [0.3+0.3*i/30] if i <=30
        #write_array += [0.6] if i <= 255 unless i <= 30
        #write_array += [0.15*Math.sin(2*Math::PI*i/1024)+0.45] if i <= 767 unless i <= 255 
        #write_array += [0.3] unless i <= 767
        
        write_array += [0.3*Math.sin(j*2*Math::PI*i/1024)+1.0]
      end
    end
    #write_array.each { |i| print i.to_s + " " }
    #puts ""
    buf = write_array.pack("f*")
    @xem.WriteToPipeIn(0x80, buf)
  end
  
  def send_reset
    @control_signals ||= 0x0001
    @xem.SetWireInValue(0x00,@control_signals)
    @xem.UpdateWireIns
    @control_signals &&= 0xFFFE
    @xem.SetWireInValue(0x00,@control_signals)
    @xem.UpdateWireIns
  end
  
  def send_reset_sim
    @control_signals = 0x0001|@control_signals
    p @control_signals
    @xem.SetWireInValue(0x00,@control_signals)
    @xem.UpdateWireIns
    @control_signals = 0xFFFE&@control_signals
    @xem.SetWireInValue(0x00,@control_signals)
    @xem.UpdateWireIns
  end
  
  def send_clk_rate
    #@clk_divider ||= 47*128 & 0xffff    #izneuron_xem6010.bit
    #clk_divider = 47*20 & 0xffff      #rng_xem6010.bit
    @clk_divider ||= 0
    @xem.SetWireInValue(0x01, @clk_divider)
    @xem.UpdateWireIns
    @xem.ActivateTriggerIn(0x50,7)
  end
  
  def send_clk_divider(clk_divider)
    #@clk_divider ||= 47*128 & 0xffff    #izneuron_xem6010.bit
    #clk_divider = 47*20 & 0xffff      #rng_xem6010.bit
    #@clk_divider ||= 0
    #@xem.SetWireInValue(0x01, clk_divider)
    low_word = clk_divider & 0xffff
    high_word = (clk_divider << 16) & 0xffff
    @xem.SetWireInValue(0x01, low_word)
    @xem.SetWireInValue(0x02, high_word)
    @xem.UpdateWireIns
    @xem.ActivateTriggerIn(0x50,7)
  end
  
  def send_i_gain_MN
    i_gain_MN = 10*1024
    low_word = i_gain_MN & 0xffff
    high_word = (i_gain_MN << 16) & 0xffff
    @xem.SetWireInValue(0x01, low_word)
    @xem.SetWireInValue(0x02, high_word)
    @xem.UpdateWireIns
    @xem.ActivateTriggerIn(0x50, 6)
  end
  
  def send_i_in(i_in)
    low_word = i_in & 0xffff
    high_word = (i_in << 16) & 0xffff
    @xem.SetWireInValue(0x01, low_word)
    @xem.SetWireInValue(0x02, high_word)
    @xem.UpdateWireIns
    @xem.ActivateTriggerIn(0x50, 6)
  end
  
  def send_enable_noisy_i(enable)
    p enable
    @control_signals = @control_signals|0x8000 if enable
    @control_signals = @control_signals&0x7fff unless enable
    #@control_signals = 0x8000
    @xem.SetWireInValue(0x00,@control_signals)
    p @control_signals
    @xem.UpdateWireIns
  end
  
end
