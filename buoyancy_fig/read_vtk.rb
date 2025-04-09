# todo: make a read function, which makes sure we're not at eof

# globals:
# @contents
# @time
# @nx, @ny, @nz
# @ox, @oy, @oz
# @dx, @dy, @dz
# @rho
# @E
# @Bx, @By, @Bz
# @vx, @vy, @vz
#

require 'Tioga/FigureMaker'

module VTKimport

  include Tioga

  def read_vtk(file)
#    @contents = open(file, 'rb')
    @contents = File.open(file, 'rb')

    # read the header
    line = String.new
    line = @contents.gets.chomp
    if not (line == '# vtk DataFile Version 3.0' or
            line == '# vtk DataFile Version 2.0') then
      puts 'Error (read_vtk): Unrecognized header in file '+file
      puts line
      return
    end

    # read the time
    line = @contents.gets.chomp
    @time = line.split.last.to_f

    # read the format
    line = @contents.gets.chomp
    if line != 'BINARY' then
      puts 'Error (read_vtk): Unrecognized format in file '+file
      puts line
      return
    end

    line = @contents.gets.chomp
    if line != 'DATASET STRUCTURED_POINTS' then
      puts 'Error (read_vtk): Unrecognized format in file '+file
      puts line
      return
    end

    # get the dimensions
    line = @contents.gets.chomp
    temp = line.split
    temp.shift
    @nx = temp.shift.to_i
    @nx -= 1 if @nx > 1

    @ny = temp.shift.to_i
    @ny -= 1 if @ny > 1

    @nz = temp.shift.to_i
    @nz -= 1 if @nz > 1

    # get the origin
    line = @contents.gets.chomp
    temp = line.split
    temp.shift
    @ox = temp.shift.to_f
    @oy = temp.shift.to_f
    @oz = temp.shift.to_f

    # get the spacing
    line = @contents.gets.chomp
    temp = line.split
    temp.shift
    @dx = temp.shift.to_f
    @dy = temp.shift.to_f
    @dz = temp.shift.to_f

    # cell data?
    line = @contents.gets.chomp
    cell_data = line.split.last.to_i
    if cell_data != @nx * @ny * @nz then
      puts 'Error (read_vtk): Wrong number of cells in file '+file
      puts 'cell_data = '+cell_data.to_s
      puts 'nx*ny*nz  = '+(@nx*@ny*@nz).to_s
      return
    end

    # Loop over variables
    while (1) do
      line = @contents.gets
      if line == nil then
        # we're at the end of the file
        break
      end
      line = line.chomp

      temp = line.split
      type = temp.shift # SCALARS or VECTORS
      var  = temp.shift # density, etc.
      precision = temp.shift # float

      if precision != 'float' then
        puts 'Error'
        puts precision
        return
      end

      if type == 'SCALARS' then
        line = @contents.gets.chomp # this line isn't needed
        read_scalar(var)
      elsif type == 'VECTORS' then
        read_vector(var)
      else
        puts 'Error: unknown data type'
        puts type
        return
      end

    end
    @contents.close
  end

  def read_scalar(var)
    # assume that it's a 2D array
    data = Dtable.new(@ny, @nx) # ny, nx is right

    for j in 0..@ny-1
      for i in 0..@nx-1
        # read 4 bytes (sizeof(float))
        # 'g' means big-endian, single-precision float
        # should check to see if we're at eof
        data[i,j] = @contents.read(4).unpack('g').first
      end
    end

    if var == 'density'
      @rho = data
    elsif var == 'total-energy' or var == 'total_energy'
      @E = data
    else
      puts 'Error: unknown scalar label'
      puts var
      return
    end
  end


  def read_vector(var)
    # assume that it's a 2D array of 3D vectors
    data1 = Dtable.new(@ny, @nx) # ny, nx is right
    data2 = Dtable.new(@ny, @nx) # ny, nx is right
    data3 = Dtable.new(@ny, @nx) # ny, nx is right

    for j in 0..@ny-1
      for i in 0..@nx-1
        # should check to see if we're at eof!
        data1[i,j] = @contents.read(4).unpack('g').first
        data2[i,j] = @contents.read(4).unpack('g').first
        data3[i,j] = @contents.read(4).unpack('g').first
      end
    end

    if var == 'velocity'
      @vx = data1
      @vy = data2
      @vz = data3
    elsif var == 'cell-centered-B' or var == 'cell_centered_B'
      @Bx = data1
      @By = data2
      @Bz = data3
    else
      puts 'Error: unknown scalar label'
      puts var
      return
    end
  end

end # module
