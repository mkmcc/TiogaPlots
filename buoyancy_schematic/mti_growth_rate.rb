# plot.rb: Plots a schematic for the growth of the MTI
#
# Time-stamp: <2011-03-08 22:33:02 (mkmccjr)>
#

require 'Tioga/FigureMaker'
require 'plot_styles.rb'

class MyPlots

  include Math
  include Tioga
  include FigureConstants
  include MyPlotStyles

  def t
    @figure_maker
  end

  def initialize
    @figure_maker = FigureMaker.default

    t.save_dir = 'plots'

    t.def_figure('mti_growth_rate') { thesis_style; charter_style; plot }
    enter_page
  end

  def enter_page
    t.default_frame_left   = 0.0
    t.default_frame_right  = 1.0
    t.default_frame_top    = 1.0
    t.default_frame_bottom = 0.0

    t.default_page_height = t.default_page_width
  end


  def plot
    t.fill_color = LightGray
    t.fill_and_stroke_circle(0.5,0.66,0.2)

    t.stroke_color = Gray

    xs = Dvector.new(101){|i| i.to_f/100}
    ys = 0.56 + 0.1 * ((50 * (xs-0.28)).tanh)
    temp = ys[0..49]
    ys = temp.insert(-1, *(ys[0..50].reverse))
    t.append_points_to_path(xs, ys)
    t.stroke


    xs = Dvector.new(101){|i| i.to_f/100}
    ys = 0.7 + 0.075 * ((20 * (xs-0.29)).tanh)
    temp = ys[0..49]
    ys = temp.insert(-1, *(ys[0..50].reverse))
    t.append_points_to_path(xs, ys)
    t.stroke

    t.show_text('at'   => [0.50, 0.68],
                'text' => '$T (z_0); \; P (z_0 + \delta z)$')

    t.show_text('at'   => [0.125, 0.67],
                'text' => '$T (z_0 + \delta z)$')

    t.show_text('at'   => [0.125, 0.5],
                'text' => '$T (z_0)$')

    t.show_text('at'   => [0.875, 0.67],
                'text' => '$P (z_0 + \delta z)$')

    t.show_arrow('tail' => [0.5, 0.26],
                 'head' => [0.5, 0.46])

    t.show_text('at'   => [0.53, 0.35],
                'text' => '$\delta z$')
  end

end

MyPlots.new
