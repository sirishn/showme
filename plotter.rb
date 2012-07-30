#!/usr/bin/env arch -i386 ruby

# wxRuby based plotter for reading opalkelly channel
# hi @ siri.sh


require 'rubygems'
require 'wx'
include Wx

#require 'fpga_dummy_neuron_int'
require 'fpga'

class OpalKellyPlotter < Window

  attr_accessor :fps, :plots
  
  def initialize(parent, fpga, plot_channels, plot_type, plot_titles, *args)
    super(parent, *args)

    initialize_fpga fpga, plot_channels
    initialize_plotter plot_type, plot_titles
    initialize_timers
    initialize_gui

  end

  def initialize_fpga(fpga, plot_channels)
    @fpga = fpga
    @fpga.plot_channels = plot_channels
    p @fpga.plot_channels
    
  end
  
  def initialize_plotter(plot_type, plot_titles)
    @plot_titles = plot_titles
    
    @plot_start_coordinate = 200
    @plot_spacing = 130
    @plot_type = plot_type
    @plots = @fpga.get_plot_data
    @prev_plots = Array.new(@plots.length, 0)
    @scale = Array.new(@plots.length, 50.0)

    @pens = Array[BLACK_PEN, RED_PEN, GREEN_PEN, CYAN_PEN, GREY_PEN]
    @brushes = Array[BLACK_BRUSH, RED_BRUSH, GREEN_BRUSH, CYAN_BRUSH, GREY_BRUSH]
    
    @xcord = @plot_start_coordinate
    
    @plot_data = Array.new(@plots.length)
    @plots.each_index do |i|
      @plot_data[i] = []
    end
    
    set_background_colour WHITE
    evt_paint do
      draw_plot_titles
      draw_grid
    end
    
    @fps = 0
    
  end
  
  def initialize_timers
    # Create our Animation Timer
    @timer = Timer.new(self,1000)
    @fpga_timer = Timer.new(self,2000)
    
       
    # Set it to run every 25 milliseconds, you can set this value higher, to get
    # higher frame rates, however, it may cause non-responsiveness of normal
    # gui controls.
    @timer.start(25)
    @fpga_timer.start(25)
    # Setup the event Handler to do the drawing on this window.
    #evt_paint :on_paint
    #evt_timer 1000, :animate
    evt_timer 1000, :on_paint
    evt_timer 2000, :update_plots
  end
  
  def update_plots
    @plots = @fpga.get_plot_data
    @plots.each_index do |i|
      @plot_data[i] += [[@xcord, @plots[i]]]
      
    end
    #p @plot_data
    #p @plots
  end
  
  def on_paint
    # We do our drawing now
    return unless @pause_plot == 0

    draw_line_plots
    draw_raster_plots
    @fps += 1
    @xcord+=4
    right_limit = @plot_start_coordinate + ((get_virtual_size.get_width-@plot_start_coordinate)/40).to_i * 40
    if (@xcord >= right_limit )
      @xcord = @plot_start_coordinate+4
      @plot_data = Array.new(@plots.length)
      @plots.each_index do |i|
        @plot_data[i] = []
      end
      
      clear_background
      #ObjectSpace.garbage_collect
    end
  end

  def draw_plot_titles
    paint do |dc|
      
      dc.set_pen BLACK_PEN
      @plots.each_index do |i|
        dc.draw_text @plot_titles[i], @plot_start_coordinate+5, i*@plot_spacing+5 unless @plot_titles[i]==nil
        dc.draw_text "Plot #{i}", @plot_start_coordinate+5, i*@plot_spacing+5 if @plot_titles[i]==nil
      end
    end
  end
  
  def draw_grid
    
    draw_horizontal_gridlines
    draw_vertical_gridlines
    draw_axes_labels
    
  end
  
  def draw_horizontal_gridlines
    right_limit = @plot_start_coordinate + ((get_virtual_size.get_width-@plot_start_coordinate)/40).to_i * 40
    paint do |dc|
      @plots.each_index do |i|
        next if @plot_type[i] == "raster"
        pen = Pen.new(LIGHT_GREY, 1, SOLID)
        dc.set_pen pen
        y = i*@plot_spacing
        major_lines = [20,70,120]
        major_lines.each do |line|
          dc.draw_line @plot_start_coordinate, line+y, right_limit, line+y 
        end
        pen.set_style DOT
        dc.set_pen pen
        minor_lines = [30, 40, 50, 60, 80, 90, 100, 110]
        minor_lines.each do |line|
          dc.draw_line @plot_start_coordinate, line+y, right_limit, line+y
        end
      end
    end
  end
  
  def draw_vertical_gridlines
    paint do |dc|
      @plots.each_index do |i|
        next if @plot_type[i] == "raster"
        pen = Pen.new(LIGHT_GREY, 1, SOLID)
        dc.set_pen pen
        x = @plot_start_coordinate
        y = i*@plot_spacing
        while (x < get_virtual_size.get_width)
          
          dc.draw_line x, 20+y, x, 120+y
          x += 40
          
        end
      end
    end
  end
  
  def draw_axes_labels
    paint do |dc|
      dc.set_pen BLACK_PEN
      @plots.each_index do |i|
        next if @plot_type[i] == "raster"
        current_scale = (50/@scale[i]).to_s
        current_scale = ((50/@scale[i])/1024).to_s if @plot_type[i] == "fixed"
        dc.draw_text "0", @plot_start_coordinate-10, 61+@plot_spacing*i 
        dc.draw_text current_scale, @plot_start_coordinate-(3+current_scale.size*8), 11+@plot_spacing*i
        dc.draw_text "-#{current_scale}", @plot_start_coordinate-(10+(current_scale.size)*8), 111+@plot_spacing*i
      end
    end
  end
 
  def draw_line_plots
    plotnumber = 0
    paint do |dc|
      @plots.each do |plot|
      begin
        if @plot_type[plotnumber] == "raster"
          plotnumber+=1
          next
        end
        dc.set_pen @pens[plotnumber%5]
        scale = @scale[plotnumber]
        yposition = plotnumber*@plot_spacing+70
        prev_point = (yposition-@prev_plots[plotnumber]*scale).to_i
        new_point = (yposition-plot*scale).to_i
        
        autoscale(plot, plotnumber) if out_of_scale? new_point, yposition
        
        new_point = yposition+50 if plot*scale <= -50
        new_point = yposition-50 if plot*scale >= 50
        dc.draw_line @xcord-4, prev_point, @xcord, new_point #
        @prev_plots[plotnumber] = -(new_point-yposition)/scale
        plotnumber += 1

       rescue NoMethodError
         next
       end
      end
    end
  end
  
  def draw_raster_plots
    plotnumber = 0
    paint do |dc|
      @plots.each do |plot|
        unless @plot_type[plotnumber] == "raster"
          plotnumber+=1
          next
        end
        dc.set_pen @pens[plotnumber%5]
        dc.set_brush @brushes[plotnumber%5]
        scale = @scale[plotnumber]
        yposition = plotnumber*@plot_spacing+20
        new_point = plot.to_i
        mask = 0x00000001
        for i in (0..31)
          #dc.draw_rectangle @xcord, yposition+5*i, 5, 5 if (mask << i) == (new_point&(mask<<i))
          dc.draw_rectangle @xcord, yposition+4*i, 4, 4 if (mask << i) == (new_point&(mask<<i))

        end
        plotnumber+=1
      end
    end
  end
 
  def draw_line_history
    
    paint do |dc|
      @plots.each_index do |i|
      begin
        next if @plot_data[i].length < 3
        next if @plot_type[i] == "raster"
        dc.set_pen @pens[i%5]
        scale = @scale[i]
        scaled_plots = []
        current_plot = @plot_data[i]
        current_plot.each do |x, y|
          yposition = i*@plot_spacing+70
          scaled_y = (yposition-y*scale).to_i                    
          scaled_y = yposition+50 if y*scale <= -50
          scaled_y = yposition-50 if y*scale >= 50
          scaled_plots += [[x,scaled_y]]
        end
        dc.draw_lines scaled_plots
       rescue NoMethodError
         next
       end
      end
    end
  end
  
  def pause_button_click(event)
      # Your code here
      if @pause_plot == 0
        @pause_plot = 1
        @pause_button.set_label "Start Plotting"
      else
        @pause_plot = 0
        @pause_button.set_label "Pause Plotting"
      end
  end
   
  def out_of_scale?(new_point, yposition)
    if (new_point-yposition >= -50 && new_point-yposition <= 50 )
      return FALSE
    else
      return TRUE
    end
    
  end
    
  def initialize_gui

    build_buttons
    build_sliders
    build_checkboxes
    
  end
  
  def build_checkboxes
    @noisy_i = CheckBox.new(self,  -1,  "Noisy Currents",
                 Point.new(10,160),
                 Size.new(100,40),
                 0,
                 DEFAULT_VALIDATOR, 
                 "noisy_i")
                 
    evt_checkbox(@noisy_i.get_id) { | event | noisy_i_update(event) }
    
    eval %{
      def noisy_i_update(event)
        @fpga.send_enable_noisy_i(@noisy_i.get_value)
      end
    }
                 
  end
  
  def build_buttons
    
    build_pause
    build_reset
    
  end
  
  def build_pause
    @pause_plot = 0
    @pause_button = Button.new(self, -1, 'Pause Plotting', 
        Point.new(10,10), DEFAULT_SIZE, ALIGN_CENTER)
    evt_button(@pause_button.get_id()) { |event| pause_button_click(event)}
  end
  
  def build_sliders
    
    build_scale_sliders
    build_input_sliders
    
  end
  
  def build_scale_sliders
    #Plot scale sliders
    @plots.each_index do |i|
      next if @plot_type[i] == "raster"
      slider_xcord = @plot_start_coordinate-70
      slider_ycord = @plot_spacing*i + 20

      eval %{
        @scale_slider_#{i} = Slider.new(self, -1, 3, 1, 15, \
        Point.new(#{slider_xcord},#{slider_ycord}), Size.new(10,100), \
        SL_VERTICAL, DEFAULT_VALIDATOR, \"scale_slider_#{i}\")
        
        evt_slider(@scale_slider_#{i}.get_id) { | event | scale_slider_update_#{i}(event) }     
      
        def scale_slider_update_#{i}(event)
          eval("@scale[#{i}] = 400.0/(2**@scale_slider_#{i}.get_value)")
          redraw
        end
      }
   
    end
  end
  
  def build_input_sliders
    build_clk_divider_slider
    build_i_in_slider
  end
  
  def build_clk_divider_slider
    StaticText.new(self,  -1,  "clk divider", 
                   Point.new(10,80), 
                   Size.new(100,40), 
                   ALIGN_CENTRE, 
                   "clk_divider_slider_label")
    
    #clk divider slider
    eval %{
      @clk_divider_slider = Slider.new(self, -1, 0, 0, 10000, \
      Point.new(10, 100), Size.new(100,10), \
      SL_HORIZONTAL, DEFAULT_VALIDATOR, \"clk_divider_slider\")
      
      evt_slider(@clk_divider_slider.get_id) { | event | clk_divider_slider_update(event) }
      
      def clk_divider_slider_update(event)
        @fpga.send_clk_divider @clk_divider_slider.get_value
        print "clk divider: "
        p @clk_divider_slider.get_value
      end
    }
    
    
  end
  
  def build_i_in_slider
    @slider_label = StaticText.new(self,  -1,  "I in", 
                   Point.new(10,120), 
                   Size.new(100,40), 
                   ALIGN_CENTRE, 
                   "clk_divider_slider_label")
    #i in slider
    eval %{
      @i_in_slider = Slider.new(self, -1, 10240, 0, 50*1024, \
      Point.new(10, 140), Size.new(100,10), \
      SL_HORIZONTAL, DEFAULT_VALIDATOR, \"i_in_slider\")
      
      evt_slider(@i_in_slider.get_id) { | event | i_in_slider_update(event) }
    }
    
    eval %{ 
      def i_in_slider_update(event)
        @fpga.send_i_in @i_in_slider.get_value
        slide_value = @i_in_slider.get_value.to_f./(1024)
        @slider_label.set_label "I_in: " + slide_value.to_s[0..4]
        print "I in: "
        p @i_in_slider.get_value
      end
    }
  end
  
  def build_reset
  
    @reset_button = Button.new(self, -1, 'Reset Sim', 
        Point.new(10,50), DEFAULT_SIZE, ALIGN_CENTER)
    evt_button(@reset_button.get_id()) { |event| send_reset_sim(event)}
    
    eval %{
      def send_reset_sim(event)
        @fpga.send_reset_sim
      end
    }
  end
    
  def redraw
    clear_background
    draw_line_history
  end
  
  def autoscale(plot, plotnumber)
    
    y = plotnumber*@plot_spacing+70
    x = (y-plot*@scale[plotnumber]).to_i
    eval("current_slider = @scale_slider_#{plotnumber}.get_value")
    while (out_of_scale? x, y)
      current_slider+=1
      @scale[plotnumber] = 400.0/(2**current_slider)
      x = (y-plot*@scale[plotnumber]).to_i
    end
    eval("@scale_slider_#{plotnumber}.set_value current_slider")
    redraw
  end
  
end

class PlotFrame < Frame
 
  #def initialize(title, bitfile, plot_channels, plot_type)
  def initialize(title, fpga, plot_channels, plot_type, plot_titles)
    super(nil, -1, title, Point.new(0,22), Size.new(450,650) )
    @plot_channels = plot_channels
    @plot_type = plot_type
    #@fpga = FPGA.new(bitfile)
    @fpga = fpga
    #@win = OpalKellyPlotter.new(self, @fpga, @plot_channels, @plot_type )
    @win = OpalKellyPlotter.new(self, fpga, plot_channels, plot_type, plot_titles )
    
    @fps_bar = StatusBar.new(self)
    self.status_bar = @fps_bar
    Timer.every(1000) { fps_display }
 
  end
  
  def fps_display
      @fps_bar.push_status_text "FPS: #{@win.fps}"
      @win.fps = 0
  end
  

  
end


