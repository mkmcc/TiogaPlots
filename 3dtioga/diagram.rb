require 'Tioga/FigureMaker'
require 'plot_styles.rb'
require 'Dobjects/Function'

require 'matrix'

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

    t.def_figure('diagram') do
      mnras_style
      charter_style
      enter_page
      diagram
    end


    # viewing angles
    #
    alpha = 0.3 * PI            # rotation about y-axis
    beta  = PI / 6              # rotation about z-axis
    dist  = 3.0                 # camera distance in units of focal length

    @zoom  = 1.25 * dist
    @shift = [-0.25, 0.0, 0.0]  # center of image

    @b_color = FireBrick
    @a_color = BrightBlue


    # build camera matrix and camera vector
    #
    mat1 = Matrix[ [cos(-beta),   0,   -sin(-beta)],
                   [         0,   1,             0],
                   [sin(-beta),   0,    cos(-beta)] ]

    mat2 = Matrix[ [cos(-alpha),   -sin(-alpha),   0],
                   [sin(-alpha),    cos(-alpha),   0],
                   [          0,              0,   1] ]

    @mat = mat1 * mat2

    @proj = Matrix[[0, 1, 0], [0, 0, 1]]

    camera = Matrix.column_vector( [dist * cos(beta) * cos(alpha),
                                    dist * cos(beta) * sin(alpha),
                                    dist * sin(beta)])
    @c = @mat * camera
  end

  def enter_page
    t.default_frame_left   = 0.0
    t.default_frame_right  = 1.0
    t.default_frame_top    = 1.0
    t.default_frame_bottom = 0.0

    t.default_page_width  = 72 * 3.5

    t.default_page_height = t.default_page_width * \
      (t.default_frame_right - t.default_frame_left) / \
      (t.default_frame_top - t.default_frame_bottom) / 0.5

    t.default_enter_page_function
  end

  def project_point(vec)
    # shift coordinate system.  no array addition?
    vec = [vec[0] - @shift[0],
           vec[1] - @shift[1],
           vec[2] - @shift[2]]

    # use the camera matrix and vector to image the vector
    v = @mat * Matrix.column_vector(vec)
    r = (v[0,0]-@c[0,0]).abs

    v = (@proj * v) / r
    v.transpose.to_a.first    # wtf???
  end

  def project_line(xs, ys, zs)
    # convert to a list of 3D points
    threed = Array.new
    xs.each_index do |i|
      threed << [xs[i], ys[i], zs[i]]
    end

    # project each of the points
    threed.map! {|pt| project_point(pt)}

    # convert back to separate lists of x and y
    xp = threed.map{|pt| pt[0]}
    yp = threed.map{|pt| pt[1]}

    [xp, yp]
  end

  def make_ellipse(a, e, ia, ib)
    # first make the ellipse in r-theta coordinates
    #
    num = 101
    theta = Dvector.new(num) {|i| 2*PI*i.to_f / (num-1)}
    r = theta.map do |th|
      a * (1-e*e) / (1 + e * cos(th))
    end

    # convert to cartesian
    # this is kind of a hack... note that it only works for ia OR ib
    # not equal to zero; not both!
    #
    xs = r.map2(theta) {|rr, th| rr * cos(th) * cos(ib)}
    ys = r.map2(theta) {|rr, th| rr * sin(th) * cos(-ia)}
    zs = r.map2(theta) {|rr, th| rr * (sin(th) * sin(-ia) + cos(th) * sin(ib))}

    [xs, ys, zs]
  end

  def background
    # draw an x-y grid
    #
    t.line_width = 0.5
    t.stroke_color = [0.7, 0.7, 0.7]

    ngrid = 21
    ngrid.times do |i|
      x = -1.0 + 2.0 * i / (ngrid-1)
      pt1 = project_point([x,  1.0, 0.0])
      pt2 = project_point([x, -1.0, 0.0])

      t.stroke_line(*pt1, *pt2)
    end

    ngrid.times do |i|
      y = -1.0 + 2.0 * i / (ngrid-1)
      pt1 = project_point([ 1.0, y, 0.0])
      pt2 = project_point([-1.0, y, 0.0])

      t.stroke_line(*pt1, *pt2)
    end

    # draw the 'b' axis
    #
    pt1 = project_point([0.0, -0.7,  0.0])
    pt2 = project_point([0.0,  0.7,  0.0])

    t.show_arrow('tail'       => pt1,
                 'head'       => pt2,
                 'tail_scale' => 0.0,
                 'head_scale' => 0.75,
                 'line_width' => 1.5,
                 'color'      => @b_color)

    pt = project_point([0.0, 0.7, 0.05])

    t.show_text('at'   => pt,
                'text' => '$\hat{b}$')

    # draw the 'a' axis
    #
    pt1 = project_point([-1.0, 0.0, 0.0])
    pt2 = project_point([ 0.5, 0.0, 0.0])

    t.show_arrow('tail'       => pt1,
                 'head'       => pt2,
                 'tail_scale' => 0.0,
                 'head_scale' => 0.75,
                 'line_width' => 1.5,
                 'color'      => @a_color)

    pt = project_point([0.5, 0.0, 0.05])

    t.show_text('at'   => pt,
                'text' => '$\hat{a}$')

    # draw the orbit
    #
    t.line_width = 1.5
    t.stroke_color = Black

    xs, ys, zs = make_ellipse(0.5, 0.7, 0.0, 0.0)
    xp, yp = project_line(xs, ys, zs)

    t.show_polyline(xp, yp)
  end

  def diagram
    t.xaxis_type = t.right_edge_type = AXIS_HIDDEN
    t.yaxis_type = t.top_edge_type   = AXIS_HIDDEN
    t.subplot('bottom_margin' => 0.5) {ia_diagram}
    t.subplot('top_margin'    => 0.5) {ib_diagram}
  end

  def ib_diagram
    t.show_plot([-1.0/@zoom, 1.0/@zoom, 1.0/@zoom, -1.0/@zoom]) do
      background

      # draw the orbit
      #
      t.stroke_color = @b_color

      xs, ys, zs = make_ellipse(0.5, 0.7, 0.0, atan(-0.25 / 0.5))
      xp, yp = project_line(xs, ys, zs)

      t.show_polyline(xp, yp)

      # draw the angular momentum vector
      #
      pt1 = project_point([0.0, 0.0, 0.0])
      pt2 = project_point([0.0, 0.0, 0.5])

      t.show_arrow('tail'       => pt1,
                   'head'       => pt2,
                   'tail_scale' => 0.0,
                   'line_width' => 1.5,
                   'head_scale' => 0.75)

      pt = project_point([0.0, 0.0, 0.55])

      t.show_text('at'   => pt,
                  'text' => '$\vec{J}$')

      # draw the 'ib' torque vector
      #
      pt1 = project_point([ 0.0,  0.0, 0.5])
      pt2 = project_point([ 0.25, 0.0, 0.5])

      t.show_arrow('tail'       => pt1,
                   'head'       => pt2,
                   'tail_scale' => 0.0,
                   'head_scale' => 0.5,
                   'line_width' => 1.5,
                   'color'      => @b_color)

      pt = project_point([0.125, 0.0, 0.55])

      t.show_text('at'   => pt,
                  'text' => '$+i_{\text{b}}$')

      # draw the new 'ib' angular momentum vector
      #
      pt1 = project_point([ 0.0,  0.0, 0.0])
      pt2 = project_point([ 0.25, 0.0, 0.5])

      t.show_arrow('tail'       => pt1,
                   'head'       => pt2,
                   'tail_scale' => 0.0,
                   'head_scale' => 0.5,
                   'line_width' => 1.5,
                   'color'      => @b_color)

    end
  end

  def ia_diagram
    t.show_plot([-1.0/@zoom, 1.0/@zoom, 1.0/@zoom, -1.0/@zoom]) do
      background

      # draw the orbit
      #
      t.stroke_color = @a_color

      xs, ys, zs = make_ellipse(0.5, 0.7, atan(0.25 / 0.5), 0.0)
      xp, yp = project_line(xs, ys, zs)

      t.show_polyline(xp, yp)


      # draw the angular momentum vector
      #
      pt1 = project_point([0.0, 0.0, 0.0])
      pt2 = project_point([0.0, 0.0, 0.5])

      t.show_arrow('tail'       => pt1,
                   'head'       => pt2,
                   'tail_scale' => 0.0,
                   'line_width' => 1.5,
                   'head_scale' => 0.75)

      pt = project_point([0.0, 0.0, 0.55])

      t.show_text('at'   => pt,
                  'text' => '$\vec{J}$')


      # draw the 'ia' torque vector
      #
      pt1 = project_point([0.0,  0.0,  0.5])
      pt2 = project_point([0.0,  0.25, 0.5])

      t.show_arrow('tail'       => pt1,
                   'head'       => pt2,
                   'tail_scale' => 0.0,
                   'head_scale' => 0.5,
                   'line_width' => 1.5,
                   'color'      => @a_color)

      pt = project_point([0.0, 0.125, 0.55])

      t.show_text('at'   => pt,
                  'text' => '$-i_{\text{a}}$')

      # draw the new 'ia' angular momentum vector
      #
      pt1 = project_point([0.0,  0.0,  0.0])
      pt2 = project_point([0.0,  0.25, 0.5])

      t.show_arrow('tail'       => pt1,
                   'head'       => pt2,
                   'tail_scale' => 0.0,
                   'head_scale' => 0.5,
                   'line_width' => 1.5,
                   'color'      => @a_color)


    end
  end

end

MyPlots.new

# Local Variables:
#   compile-command: "tioga diagram.rb -s"
# End:
