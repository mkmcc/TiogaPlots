# plot.rb: plots the hbi/mti growth rate as a function of
#   w_cond/w_buoy, for different viscosities.  The actualy growth
#   rates are calculated in the accompanying mathematica notebook;
#   this just makes the plot.
#
# Begun by Mike McCourt, March 2011
#
# Time-stamp: <2025-04-09 16:29:13 (mkmcc)>
#
require 'Tioga/FigureMaker'
require 'plot_styles.rb'
require 'Dobjects/Function'

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

    $my_Line_Type_Dot = [[2, 4], 10]

    t.def_figure('growth-rates-visc') { thesis_style; minion_style; dispersion_plot }
    enter_page
  end

  def enter_page
    t.default_frame_left   = 0.08
    t.default_frame_right  = 0.98
    t.default_frame_top    = 0.89
    t.default_frame_bottom = 0.12

    t.default_page_height = t.default_page_width * \
      (t.default_frame_right - t.default_frame_left) / \
      (t.default_frame_top - t.default_frame_bottom) / 2.0

    t.default_enter_page_function
  end

 def plot_regions
    t.fill_color = LightGray
    t.fill_rect((4).log10, -2,
                (10).log10 - (4).log10, 2)

    t.fill_rect((30).log10, -2,
                (300).log10 - (30).log10, 2)

    t.show_text('text' => '{\footnotesize largest scales in {\scshape cc} clusters}',
                'x'    => ((4).log10 + (10).log10)/2,
                'y'    => -1.2,
                'angle' => 90,
                'alignment' => ALIGNED_AT_MIDHEIGHT)

    t.show_text('text' => '\parbox[c]{2cm}{\footnotesize \begin{center} largest scales in {\scshape ncc} clusters \end{center}}',
                'x'    => ((300).log10 + (30).log10)/2,
                'y'    => -0.525,
                'angle' => 90,
                'alignment' => ALIGNED_AT_MIDHEIGHT)

  end

  def plot_text
    t.show_text('text' => '\leftarrow \parbox[c]{1cm}{\begin{center} Large Scales \end{center}}',
                'at' => [-0.8, -1.75],
                'justification' => LEFT_JUSTIFIED,
                'alignment' => ALIGNED_AT_BASELINE)

    t.show_text('text' => '\parbox[c]{1cm}{\begin{center} Small Scales \end{center}} \rightarrow',
                'at' => [1.4, -1.75],
                'justification' => LEFT_JUSTIFIED,
                'alignment' => ALIGNED_AT_BASELINE)
  end

  def plot_lines(file)
    t.xaxis_log_values = t.yaxis_log_values = true
    t.show_plot([-1, (300).log10, 0, -2]) do
      # x = w_cond / w_buoy; ys are growth rate / w_buoy
      # y1 has no viscosity; y2 has a realistic viscosity; y3 is even more viscous
      x, y1, y2, y3 = Dvector.fancy_read("data/#{file}")
      x.safe_log10! ;  y1.safe_log10! ;  y2.safe_log10! ;  y3.safe_log10!


      # get the region where the growth rate is suppressed by less
      # than a factor of 2
      fun       = Function.new(x, y2)
      fun_dense = fun.interpolate(300)  # densely sampled

      istart = fun_dense.y.where_first_ge(-1.5 * (2).log10)
      iend   = fun_dense.y.where_last_ge(-1.5 * (2).log10)

      fun = Function.new((fun_dense.x)[istart...iend],
                         (fun_dense.y)[istart...iend])

      fun_sparse = fun.interpolate(20) # don't need many points

      t.append_points_to_path(fun_sparse.x, fun_sparse.y)
      t.append_point_to_path(fun_sparse.x.last, -2)
      t.append_point_to_path(fun_sparse.x.first, -2)
      t.close_path
      t.fill_color = MistyRose
      t.fill


      #
      plot_regions
      plot_text


      # finally, plot the theory curves
      t.show_polyline(x, y1, MidnightBlue,  nil, Line_Type_Solid)
      t.show_polyline(x, y2, DarkGoldenrod, nil, $my_Line_Type_Dot)
    end
  end

  def plot_points(file)
    t.xaxis_log_values = t.yaxis_log_values = true
    t.show_plot([-1, (300).log10, 0, -2]) do
      x, pf_nv, pl_nv, ph_nv,
         pf_v,  pl_v,  ph_v,
         pf_sv, pl_sv, ph_sv = Dvector.fancy_read("data/#{file}")

      ph_nv = (ph_nv).safe_log10 - (pf_nv).safe_log10
      pl_nv = (pf_nv).safe_log10 - (pl_nv).safe_log10

      ph_v = (ph_v).safe_log10 - (pf_v).safe_log10
      pl_v = (pf_v).safe_log10 - (pl_v).safe_log10

      ph_sv = (ph_sv).safe_log10 - (pf_sv).safe_log10
      pl_sv = (pf_sv).safe_log10 - (pl_sv).safe_log10

      x.safe_log10!
      pf_nv.safe_log10!
      pf_v.safe_log10!
      pf_sv.safe_log10!

      x.each_index do |i|
        t.show_marker({ 'x' => x[i],
                        'y' => pf_nv[i],
                        'marker' => Asterisk,
                        'color'  => MidnightBlue})

        t.show_marker({ 'x' => x[i],
                        'y' => pf_v[i],
                        'marker' => Asterisk,
                        'color'  => DarkGoldenrod})
      end
    end
  end

  def dispersion_plot
    xlabel = '$\omega_{\mathrm{cond}} / \omega_{\mathrm{buoy}}$'
    ylabel = '$p / \omega_{\mathrm{buoy}}$'

    t.xlabel_shift = 1.7

    t.subplot('right' => 0.5, 'bottom' => 0.0) do
      t.do_box_labels('HBI, $\hat{b}_z = 1$', xlabel, ylabel)
      plot_lines('hbi_bz-1_kz-0.707.dat')
      plot_points('hbi_bz-1_kz-0.707-simresults.dat')
    end

    ylabel = '$\sigma / \omega_{\mathrm{buoy}}$'
    t.subplot('left' => 0.5, 'bottom' => 0.0) do
      t.yaxis_type = AXIS_WITH_TICKS_ONLY

      t.xaxis_locations_for_major_ticks = [-1, 0, 1, 2]
      t.xaxis_tick_labels = ['', '1', '10', '$10^2$']

      t.do_box_labels('MTI, $\hat{b}_z = 0$', xlabel, nil)
      plot_lines('mti_bz-0_kz-0.707.dat')
      plot_points('mti_bz-0_kz-0.707-simresults.dat')
    end

    t.subplot('left' => 0.5) do
      t.show_plot_with_legend('plot_right_margin'  => 0.0,
                              'legend_left_margin' => 0.05,
                              'legend_top_margin'  => 0.25) do

        t.save_legend_info({ 'line_color' => MidnightBlue,
                             'line_type' => Line_Type_Solid,
                             'text' => '\Large{Pr = 0.00}'})

        t.save_legend_info({ 'line_color' => DarkGoldenrod,
                             'line_type' => $my_Line_Type_Dot,
                             'text' => '\Large{Pr = 0.01}'})
      end
    end

  end

end

MyPlots.new

# Local Variables:
#   compile-command: "tioga growth-rate-plot.rb -s"
# End:
