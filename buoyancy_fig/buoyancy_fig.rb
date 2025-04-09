require 'Tioga/FigureMaker'
require 'plot_styles.rb'
require './read_vtk.rb'

class MyPlots

  include Math
  include Tioga
  include FigureConstants
  include MyPlotStyles
  include VTKimport

  def t
    @figure_maker
  end

  def initialize
    @figure_maker = FigureMaker.default
    t.save_dir = 'plots'

    # t.def_figure('hbi_schematic') { thesis_style; charter_style; exec_plot_hbi }
    # t.def_figure('mti_schematic') { thesis_style; charter_style; exec_plot_mti }
    # enter_page_single

    t.def_figure('buoy_schematic') { thesis_style; charter_style; exec_plot_both }
    enter_page_double
  end

  def enter_page_double
    t.default_page_width  = 72*4.75

    t.default_frame_left   = 0.075
    t.default_frame_right  = 0.99
    t.default_frame_top    = 0.925
    t.default_frame_bottom = 0.02

    t.default_page_height = t.default_page_width * \
                            (t.default_frame_right - t.default_frame_left) / \
                            (t.default_frame_top - t.default_frame_bottom) * 0.45 * 2
  end

  def enter_page_single
    t.default_page_width  = 72*4.75

    t.default_frame_left   = 0.01
    t.default_frame_right  = 0.99
    t.default_frame_top    = 0.875
    t.default_frame_bottom = 0.02

    t.default_page_height = t.default_page_width * \
      (t.default_frame_right - t.default_frame_left) / \
      (t.default_frame_top - t.default_frame_bottom) * 0.45
  end

  def exec_plot_both
    t.subplot('bottom_margin' => 0.55, 'top_margin' => 0.00){
      exec_plot_mti

      t.show_text('text' => 'MTI',
                  'side' => LEFT,
                  'position' => 0.5,
                  'justification' => CENTERED,
                  'shift' => 0.5,
                  'scale' => 1.5,
                  'color' => Black)
    }

    t.subplot('bottom_margin' => 0.00, 'top_margin' => 0.55){
      exec_plot_hbi


      t.show_text('text' => 'HBI',
                  'side' => LEFT,
                  'position' => 0.5,
                  'justification' => CENTERED,
                  'shift' => 0.5,
                  'scale' => 1.5,
                  'color' => Black)
    }
  end

  def exec_plot_hbi
    t.xaxis_type = AXIS_WITH_TICKS_ONLY
    t.yaxis_type = AXIS_WITH_TICKS_ONLY

    t.xaxis_locations_for_major_ticks = [ 0.0, 0.5, 1.0]
    t.xaxis_locations_for_minor_ticks = [ 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9 ]

    t.yaxis_locations_for_major_ticks = [ 0.0, 0.5, 1.0]
    t.yaxis_locations_for_minor_ticks = [ 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9 ]

    t.subplot('right_margin' => 0.55, 'left_margin' => 0.0){
      sampled_image({'title' => 'Temperature ($t = 5 \, t_{\mathrm{buoy}}$)',
                      'dir'  => 'hbi_data',
                      'file' => 'temp.5.2D'})
      field_lines({'dir' => 'hbi_data',
                   'file' => 'vecpot.5.2D'})
    }
    t.subplot('left_margin' => 0.55, 'right_margin' => 0.0){
      sampled_image_2({'title' => '$\Delta T$',
                       'dir' => 'hbi_data'})
      field_lines({'dir' => 'hbi_data',
                   'file' => 'vecpot.5.2D'})
    }
  end

  def exec_plot_mti
    t.xaxis_type = AXIS_WITH_TICKS_ONLY
    t.yaxis_type = AXIS_WITH_TICKS_ONLY

    t.xaxis_locations_for_major_ticks = [ 0.0, 0.5, 1.0]
    t.xaxis_locations_for_minor_ticks = [ 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9 ]

    t.yaxis_locations_for_major_ticks = [ 0.0, 0.5, 1.0]
    t.yaxis_locations_for_minor_ticks = [ 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9 ]

    t.subplot('right_margin' => 0.55, 'left_margin' => 0.0){
      sampled_image({'title' => 'Temperature ($t = 0$)',
                      'dir'  => 'mti_data',
                      'file' => 'temp.init.2D'})
      field_lines({'dir' => 'mti_data',
                   'file' => 'vecpot.init.2D'})
    }
    t.subplot('left_margin' => 0.55, 'right_margin' => 0.0){
      sampled_image({'title' => 'Temperature ($t = 5 \, t_{\mathrm{buoy}}$)',
                      'dir' => 'mti_data',
                      'file' => 'merged.0019.vtk'})
      field_lines_vtk
    }
  end

  def sampled_image(h, colormap = nil)
    t.do_box_labels(h['title'], nil, nil)

    if h['file'].match(/.2D/) then
      data = get_temp_image(h['dir']+'/'+h['file'])
    elsif h['file'].match(/.vtk/) then
      data = get_temp_image_vtk(h['dir']+'/'+h['file'])
    end

    t.show_plot([0, 1.0, 1.0, 0]) do
      t.fill_color = Wheat
      t.fill_frame
      t.show_image(
                   'll' => [0, 0],
                   'lr' => [1.00, 0],
                   'ul' => [0, 1.00],
                   'color_space' => t.mellow_colormap,
                   'data' => data, 'value_mask' => 255,
                   'w' => 64, 'h' => 64)
    end
  end

  def sampled_image_2(h, colormap = nil)
    t.do_box_labels(h['title'], nil, nil)
    data = get_temp_diff_image(h['dir'])

    t.show_plot([0, 1.0, 1.0, 0]) do
      t.fill_color = Wheat
      t.fill_frame
      t.show_image(
                   'll' => [0, 0],
                   'lr' => [1.00, 0],
                   'ul' => [0, 1.00],
                   'color_space' => t.mellow_colormap,
                   'data' => data, 'value_mask' => 255,
                   'w' => 64, 'h' => 64)
    end
  end

  def get_temp_image(file)
    # file = dir+'/temp.5.2D'
    @xs = Dvector.new(64){ |i| i }
    @ys = Dvector.new(64){ |i| i }
    image_data = Dtable.new(@xs.nitems, @ys.nitems)
    image_data.read(file)

    image_zmin = image_data.min * 0.99
    image_zmax = image_data.max * 1.01

    return t.create_image_data(image_data.rotate_ccw90,
                               'min_value' => image_zmin,
                               'max_value' => image_zmax)
  end

  def get_temp_image_vtk(file)
    read_vtk(file)

    @xmin = @ox
    @xmax = @ox + @nx*@dx

    @ymin = @oy
    @ymax = @oy + @ny*@dy

    gamma = 5.0 / 3
    @T = @E.mul(gamma - 1.0).div(@rho)

    image_zmin = @T.min * 0.99
    image_zmax = @T.max * 1.01

    data = @T.rotate_ccw90

    @xs = Dvector.new(64){ |i| i }
    @ys = Dvector.new(64){ |i| i }

    image_data = Dtable.new(@xs.nitems, @ys.nitems)

    (192/3..2*192/3-1).each do |i|
      image_data.set_row((i-192/3), data.row(i))
    end

    return t.create_image_data(image_data,
                               'min_value' => image_zmin,
                               'max_value' => image_zmax,
                               'masking' => true)
  end

  def get_temp_diff_image(dir)
    file = dir+'/temp.5.2D'
    @xs = Dvector.new(64){ |i| i }
    @ys = Dvector.new(64){ |i| i }
    image_data = Dtable.new(@xs.nitems, @ys.nitems)
    image_data.read(file)

    file = dir+'/temp.init.2D'
    init_data = Dtable.new(@xs.nitems, @ys.nitems)
    init_data.read(file)

    image_data.sub!(init_data)

    image_zmin = image_data.min * 0.99
    image_zmax = image_data.max * 1.01


    return t.create_image_data(image_data.rotate_ccw90,
                               'min_value' => image_zmin,
                               'max_value' => image_zmax)
  end

  def field_lines(h)
    file = h['dir']+'/'+h['file']
    @xs = Dvector.new(64){ |i| i }
    @ys = Dvector.new(64){ |i| i }
    vecpot_data = Dtable.new(@xs.nitems, @ys.nitems)
    vecpot_data.read(file)

    if file == 'mti_data/vecpot.init.2D' then
      vecpot_data.num_cols.times do |i|
        temp = Dvector.new(vecpot_data.num_rows, i.to_f)
        vecpot_data.set_column(i,temp)
      end
    end

    t.stroke_color = Black # SlateGray
    t.line_width = 1

    t.show_plot([0.0, 1.0, 1.0, 0.0]) {

      nlevels = 15
      max = vecpot_data.max
      min = vecpot_data.min
      levels = Dvector.new(nlevels+1)  do |i|
        min + (max - min)*i.to_f/nlevels
      end

      xs = Dvector.new(64) {|i| 0.0 + 1.0/63 * i.to_f}
      ys = Dvector.new(64) {|i| 0.0 + 1.0/63 * i.to_f}
      gaps = Array.new

      vecpot_data = vecpot_data.transpose

      levels.each do |level|
        pts_array = t.make_contour({ 'data' => vecpot_data,
                                     'level' => level,
                                     'xs' => xs,
                                     'ys' => ys,
                                     'gaps' => gaps })
        t.append_points_with_gaps_to_path(pts_array[0], pts_array[1], gaps, false)
        t.stroke
        t.discard_path
      end
    }

  end

  def field_lines_vtk
    # Build the vector potential
    f = Dtable.new(@ny / 3, @nx)

    for j in 0..(@ny/3)-1
      for i in 0..@nx-1

        # 'primed coordinates'
        for jp in 0..j
          f[i,j] += 0.5 * (@Bx[i,jp+@ny/3] + @Bx[0,jp+@ny/3]) * @dy
        end
        for ip in 0..i
          f[i,j] -= 0.5 * (@By[ip,j+@ny/3] + @By[ip,0+@ny/3]) * @dx
        end
      end
    end

    f = f.transpose

    nlevels = 15
    max = f.max
    min = f.min
    levels = Dvector.new(nlevels+1)  do |i|
      min + (max - min)*i.to_f/nlevels
    end

    xs = Dvector.new(@nx) {|i| @ox + @dx * (i+0.5)}
    ys = Dvector.new(@ny/3) {|i| @oy + @dy * ((i+@ny/3)+0.5)}
    gaps = Array.new

    t.stroke_color = Black # SlateGray
    t.line_width = 1

    t.show_plot([@xmin, @xmax, @ymax*2.0/3, @ymax/3]) {
      levels.each do |level|
        pts_array = t.make_contour({ 'data' => f,
                                     'level' => level,
                                     'xs' => xs,
                                     'ys' => ys,
                                     'gaps' => gaps })
        t.append_points_with_gaps_to_path(pts_array[0], pts_array[1], gaps, false)
        t.stroke
        t.discard_path
      end
    }
    puts 'success'
  end

end

MyPlots.new
