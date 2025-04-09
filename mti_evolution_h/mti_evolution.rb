# hbi_evolution.rb: Six panel plot of the evolution of the HBI.  Each
#   panel shows the temperature (increasing from blue to red), and the
#   magnetic field lines.  The panel also has a label saying what the
#   time is.  Field lines are calculated in this file, and it's really
#   slow.  Designed for athena 4.
#
require 'Tioga/FigureMaker'
require 'plot_styles.rb'
require 'read_vtk.rb'

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
    @my_colormap = t.mellow_colormap

    t.save_dir = 'plots'

    enter_page # yes, need this twice
    t.def_figure('mti_evolution') { mnras_style; charter_style; enter_page; panel_plot }
  end

  # set the page size, etc
  #
  def enter_page
    # do not call "_style" functions here

    # Margins
    t.default_frame_left   = 0.0
    t.default_frame_right  = 1.0
    t.default_frame_top    = 0.9925
    t.default_frame_bottom = 0.0075

    @row_height = 0.4925

    t.default_page_height = t.default_page_width * \
      (t.default_frame_right - t.default_frame_left) / \
      (t.default_frame_top - t.default_frame_bottom) * \
    2.0 / (1-@row_height) / 3.0
  end




  # Master function for the plot
  #
  def panel_plot
    t.xaxis_type = AXIS_WITH_TICKS_ONLY
    t.yaxis_type = AXIS_WITH_TICKS_ONLY
    t.subplot('bottom_margin' => 1-@row_height) do
      temperature_plot([{ 'file' => 'merged/turb.0000.vtk',
                          'time' => '0'},
                        { 'file' => 'merged/turb.0003.vtk',
                          'time' => '3'},
                        { 'file' => 'merged/turb.0004.vtk',
                          'time' => '4'}])
    end
    t.subplot('top_margin' => 1-@row_height) do
      temperature_plot([{ 'file' => 'merged/turb.0005.vtk',
                          'time' => '5'},
                        { 'file' => 'merged/turb.0006.vtk',
                          'time' => '6'},
                        { 'file' => 'merged/turb.0020.vtk',
                          'time' => '20'}])
    end
  end


  # plot a set of simulations
  #
  def temperature_plot(sim_list)
    n = sim_list.count { |x| !x.nil? }
    a = 1.0 / n

    i = 0
    sim_list.each do |sim|
      t.subplot('left_margin' => a * i + 0.01,
                'right_margin' => a * (n-i-1) + 0.01 ) { single_plot(sim) }
      i += 1
    end
  end

  def single_plot(sim)
    vi = VTKfile.new(:t => true, :b => true)
    vi.read(sim['file'])

    xmin = vi.ox;  xmax = vi.ox + vi.nx*vi.dx
    ymin = vi.oy;  ymax = vi.oy + vi.ny*vi.dy

    data = Dtable.new(vi.ny, vi.nx)
    for j in (0...vi.ny)
      for i in (0...vi.nx)
        data[i,j] = vi.t.at(j+vi.ny*i)
      end
    end

    img = t.create_image_data(data,
                              'min_value' => 0.933,
                              'max_value' => 1.000,
                              'masking' => false)

    t.show_plot([xmin, xmax, ymin, ymax]) do
      t.show_image(
                   'll' => [xmin, ymin],
                   'lr' => [xmax, ymin],
                   'ul' => [xmin, ymax],
                   'color_space' => @my_colormap,
                   'data' => img,
                   'w' => vi.d.nx, 'h' => vi.d.ny)

      t.show_text('text' => '$t = ' + sim['time'] + '\, t_{\mathrm{buoy}}$',
                  'side' => TOP,
                  'position' => 0.48,
                  'justification' => LEFT_JUSTIFIED,
                  'shift' => -1.5,
                  'color' => WhiteSmoke)

      t.show_polyline([xmin,xmax],[0.25*ymax,0.25*ymax], LightGrey)
      t.show_polyline([xmin,xmax],[0.75*ymax,0.75*ymax], LightGrey)
    end

    if true then                # field lines are slow; turn off for experimenting

      f = Dtable.new(vi.ny, vi.nx)

      for j in 0...vi.ny
        for i in 0...vi.nx

          for jp in 0..j
            f[i,j] += (vi.bx[0,jp,i] + vi.bx[0,jp,0])
          end
          for ip in 0..i
            f[i,j] -= (vi.by[0,j,ip] + vi.by[0,0,ip])
          end
        end
      end

      nlevels = 15
      max = f.max
      min = f.min
      levels = Dvector.new(nlevels+1)  do |i|
        min + (max - min)*i.to_f/nlevels
      end

      t.stroke_color = Black
      t.line_width = 0.8

      t.show_plot([xmin, xmax, ymax, ymin]) do
        xs = Dvector.new(vi.nx) {|i| vi.ox + vi.dx * (i+0.5)}
        ys = Dvector.new(vi.ny) {|i| vi.oy + vi.dy * (i+0.5)}
        gaps = Array.new

        levels.each do |level|
          pts_array = t.make_contour({ 'data' => f.transpose,
                                       'level' => level,
                                       'xs' => xs,
                                       'ys' => ys,
                                       'gaps' => gaps })
          t.append_points_with_gaps_to_path(pts_array[0], pts_array[1], gaps, false)
          t.stroke
        end
      end
    end
  end

end

MyPlots.new
