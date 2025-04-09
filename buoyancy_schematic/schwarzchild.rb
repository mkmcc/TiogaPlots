# plot.rb: Plots a schematic for the growth of the MTI
#
# Time-stamp: <2025-04-09 14:16:05 (mkmcc)>
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

    t.def_figure('schwarzchild') { thesis_style; charter_style; plot }
    enter_page
  end

  def enter_page
    t.default_frame_left   = 0.0
    t.default_frame_right  = 1.0
    t.default_frame_top    = 1.0
    t.default_frame_bottom = 0.0

    t.default_page_height = t.default_page_width * 3.0/4.75
  end


  def plot
    t.fill_color = LightGray
    t.fill_and_stroke_circle(0.5,0.66,0.2)

    t.stroke_color = Gray

    t.show_text('at'   => [0.50, 0.66],
                'text' => '$s (z_0); \; P (z_0 + \delta z)$',
                'alignment' => ALIGNED_AT_MIDHEIGHT)

    t.show_text('at'   => [0.1, 0.66],
                'text' => '$s (z_0 + \delta z)$',
                'alignment' => ALIGNED_AT_MIDHEIGHT,
                'justification' => LEFT_JUSTIFIED)

    t.show_text('at'   => [0.1, 0.34],
                'text' => '$s (z_0)$',
                'alignment' => ALIGNED_AT_BASELINE,
                'justification' => LEFT_JUSTIFIED)

    t.show_text('at'   => [0.875, 0.66],
                'text' => '$P (z_0 + \delta z)$',
                'alignment' => ALIGNED_AT_MIDHEIGHT)

    t.show_arrow('tail' => [0.5, 0.05],
                 'head' => [0.5, 0.34])

    t.show_text('at'   => [0.53, 0.20],
                'text' => '$\delta z$',
                'alignment' => ALIGNED_AT_MIDHEIGHT)
  end

end

MyPlots.new
