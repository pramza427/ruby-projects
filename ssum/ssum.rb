# Piotr Ramza
# cs401
# Project 1
#

class SsumElem
  @value = 0
  @name = ''
  attr_accessor :value, :name

  def print_elem
    puts "#{@value} as #{@name}"
  end
end

class SsumInstance

  def initialize
    super
    @target = 0
    @elems = Array.new
    @feasible = Array.new { Array.new }
    @done = false
    # a mock 2D array to hold information about the total ways to create the target
    @lastcount = nil
    @count = nil
    # a mock 2D array to hold information about the number of shortest ways to create
    # the target
    @lastmincount = nil
    @mincount = nil
  end

  # get elements from the input file
  def read_elems(file_name)
    File.foreach(file_name) do |line|
      elem = SsumElem.new
      line_content = line.split
      elem.value=(line_content[0].to_i)
      elem.name=(line_content[1])
      @elems.push(elem)
    end
    @done = false
  end

  def solve(tgt)
    n = @elems.length

    # solution has already been run on this target
    if @target == tgt && @done
      @feasible.at(n-1).at(tgt)
    end

    # fill variables based on input
    @target = tgt
    @feasible = Array.new(n) { |i| Array.new(@target + 1) { |i| nil } }
    @lastcount = nil
    @count = Array.new(@target, 0)
    @lastmincount = nil
    @mincount = Array.new(@target, 0)

    # leftmost column (column zero) is all TRUE because
    #    a target sum of zero is always acheivable (via the
    #    empty set).
    i = 0
    while i < n
      @feasible[i][0] = Array.new(0)
      i += 1
    end

    # populate first row
    x = 1
    while x <= @target
      if @elems[0].value == x
        @feasible[0][x] = Array.new(1, 0)
        @count[x] = 1
        @mincount[x] = 1
      end

      x += 1
    end

    # save the current count arrays in the last count arrays
    # This allows for the idea of a 2d array but only saves
    # 2 rows at a time, saving space
    @lastcount = @count.clone
    @lastmincount = @mincount.clone

    i = 1
    while i < n
      x = 1
      while x <= tgt

        # determines if we should stick with the array that is already in the column,
        # or if there is a better option to create that number by using a previous array
        # Also counts the number of possibilities for each number (ei. column)
        if x >= @elems[i].value && !@feasible[i-1][x-@elems[i].value].nil?
          newarray = Array.new(1, i)
          oldarray = @feasible[i-1][x-@elems[i].value].clone
          combinedarray = oldarray.concat(newarray)
          placearray(combinedarray, i, x)


        elsif !@feasible[i-1][x].nil?
          @feasible[i][x] = @feasible[i-1][x]

        end
        x += 1
      end
      @lastcount = @count.clone
      @lastmincount = @mincount.clone
      i += 1
    end

    # return the last element in the 2d array
    # This value will be the shortest lexicographically first solution
    @done = true
    @feasible.at(n-1).at(@target)

  end # end solve

  def placearray(combinedarray, i, x)

    # if the value is = x then we need to check if the previous array was also
    # a single length array which held x
    if @elems[i].value == x
      if !@feasible[i-1][x].nil?
        # if it was then we keep the lexographicaly first instance
        # which is already in feasible
        if combinedarray.length == @feasible[i-1][x].length
          @feasible[i][x] = @feasible[i-1][x]
          @mincount[x] +=1
          # otherwise we change the contents of feasible to be
          # the smaller array (the new array)
        elsif combinedarray.length < @feasible[i-1][x].length
          @feasible[i][x] = combinedarray
          @mincount[x] = 1
        else
          @feasible[i][x] = @feasible[i-1][x]
        end
      else
        @feasible[i][x] = Array.new(1,i)
        @mincount[x] = 1
      end
      @count[x] += 1

    elsif !@feasible[i-1][x].nil?
      # length of combination is greater than the current length
      # so we keep the current array
      if combinedarray.length > @feasible[i-1][x].length
        @feasible[i][x] = @feasible[i-1][x]
        @count[x] = @lastcount[x-@elems[i].value] + @lastcount[x]

        # the new  combination is same length and lexicographically first
        # so we use the new array
      elsif combinedarray.length == @feasible[i-1][x].length &&
          combinedarray[0] < @feasible[i-1][x][0]
        @feasible[i][x] = combinedarray
        @count[x] = @lastcount[x-@elems[i].value] + @lastcount[x]
        @mincount[x] = @lastmincount[x-@elems[i].value] + @lastmincount[x]

        # the new  combination is same length and not lexicographically first
        # so we use the old array
      elsif combinedarray.length == @feasible[i-1][x].length
        @feasible[i][x] = @feasible[i-1][x]
        @count[x] = @lastcount[x-@elems[i].value] + @lastcount[x]
        @mincount[x] = @lastmincount[x-@elems[i].value] + @lastmincount[x]

        # the length of combined array is less than current array
        # so we need to replace it with the combined array
      elsif combinedarray.length < @feasible[i-1][x].length
        @feasible[i][x] = combinedarray
        @count[x] = @lastcount[x-@elems[i].value] + @lastcount[x]
        @mincount[x] = 1
      end
      # the previous array was nil so we use the new possible array and set
      # count to the count of the combined array since there is a new possibility for that number
    else
      @feasible[i][x] = combinedarray
      @count[x] = @lastcount[x-@elems[i].value]
      @mincount[x] = @lastmincount[x-@elems[i].value]

    end
  end

  # prints the array since unix prints arrays weird
  def printarray(array)
    print'{'
    array.each_index do |i|
      print "#{array[i]}"
      if i < array.length - 1
        print ', '
      end
    end
    print"}\n\n"
  end

  # prints the results
  def print_result
    solution_array = @feasible.at(@elems.length-1).at(@target)
    if solution_array.nil?
      puts "\nTarget sum of #{@target} is INFEASIBLE"
    else
      print "\nTarget sum of #{@target} is FEASIBLE!\n\n"
      print "Total solutions found: #{@count[@target]}\n"
      print "Shortest solution found: length = #{@feasible[@elems.length-1][@target].length}\n"
      print "Total solutions of size #{@feasible[@elems.length-1][@target].length}: #{@mincount[@target]}\n"
      best_array = @feasible[@elems.length-1][@target].clone
      print "Lexicographically first: "
      best_array.each_index { |i| best_array[i] = @elems[best_array[i]].name }
      printarray(best_array)
    end
  end
end

puts 'Please enter target distance: '
temp_target = gets.chomp
puts "Please enter file name: "
file_name = gets.chomp
ssi = SsumInstance.new
ssi.read_elems(file_name)
ssi.solve(temp_target.to_i)
ssi.print_result