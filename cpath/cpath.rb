# Piotr Ramza
# pramza1
# cs401 Project 2
# Cost and Time Graph
#
# Note: I did not write the priority queue file.

require './priority_queue.rb'

# Edge class holds all information for an edge
class Edge
  def initialize(src, dest, cst, tim)
    @source = src
    @cost = cst
    @time = tim
    @destination = dest
    @checked = false
  end
  #getters and setters
  attr_accessor(:cost, :time, :source, :destination)
end

# Vertex class
# hold name, outgoing edges, and solution arrays
# best and current variables are used to determine which
# solutions get chosen
class Vertex
  def initialize(nam)
    @name = nam
    @outgoing_edges = []
    @valid_options = []
    @final_path = []
    @final_path_counter = 0
    @current_cost = 1.0/0
    @current_time = 1.0/0
    @best_cost = 0
    @best_time = 1.0/0
  end
  # getters and setters
  attr_accessor(:name, :done, :outgoing_edges, :current_cost,
                :final_path, :current_time, :valid_options)

  def add_edge(edge)
    @outgoing_edges.push(edge)
  end

  def add_solution(array, budget, source_vertex)
    if @best_time > array[1] && @best_cost <= array[0]
      @valid_options.push(array)
      @best_cost = array[0]
      @best_time = array[1]
      if @best_cost <= budget
        if source_vertex.final_path.empty?
          new_array = [source_vertex.name]
          @final_path.push(new_array)
        else
          old = Marshal.load(Marshal.dump(source_vertex.final_path))
          old.each do |array|
            array.push(@name)
            @final_path.push(array)
          end
        end
      end
    end
  end

  def print_outgoing
    @outgoing_edges.each do |edge|
      print "#{edge.destination} "
    end
  end
end

# class that holds all vertices and adds edges to vertex/graph
class Graph
  def initialize(budget)
    @vertex_array = []
    @edge_array = []
    @contained_vertices = []
    @budget = budget
    @queue = PQueue.new
  end
  # getters and setters
  attr_accessor(:vertex_array)

  # prints the vertices and the worthwhile cost/time it takes to
  # get there
  def print_solution
    @vertex_array.each do |vertex|
      print "#{vertex.name} has options #{vertex.valid_options}\n"
    end
  end

  # reads the file and populates the graph
  def read_graph_file(file)
    File.foreach(file) do |line|
      this_line = line.split
      temp = Edge.new(this_line[0].to_i, this_line[1].to_i,
                      this_line[2].to_i, this_line[3].to_i)
      @edge_array.push(temp)
      add(temp)
    end
  end

  # add edge to graph by adding it to vertex
  # create vertex if one is not already in graph
  def add(edge)
    source = edge.source
    if @contained_vertices.include? source
      @vertex_array.at(source).add_edge(edge)
    else
      new_vertex = Vertex.new(source)
      new_vertex.add_edge(edge)
      @contained_vertices.push(source)
      if @vertex_array.size < source
        @vertex_array.insert(source, new_vertex)
      else
        @vertex_array[source] = new_vertex
      end
    end
  end

  # prints the vertices and the vertices they point to
  def print_graph
    @vertex_array.each do |vertex|
      print "#{vertex.name} points to: "
      vertex.print_outgoing
      puts ''
    end
  end

  # creates the first element in the queue them starts the recursive
  # solution method
  def solve_start(first)
    starting_edge = Edge.new(first,first,0, 0)
    @queue.push(starting_edge)
    solve(first)
  end

  def solve(first)
    vertex = @vertex_array[first]

    # when a vertex is encountered we add all outgoing edges to
    # the queue if those edges have a lower time than what was
    # already found
    vertex.outgoing_edges.each do |edge|
      new_edge = Edge.new(first, edge.destination,
                          vertex.current_cost + edge.cost,
                          vertex.current_time + edge.time)
      # due to the way my algorithm populates the graph a vertex
      # with no outgoing edges may not be added originally
      # It will be added here
      if @vertex_array[edge.destination].nil?
        new_vertex = Vertex.new(edge.destination)
        @vertex_array.insert(edge.destination, new_vertex)
      end
      # add edges to the priority queue if they have a lower new time
      # compared to the time already stored in the destination vertex
      if @vertex_array[edge.destination].current_time > vertex.current_time + edge.time
        @queue.push(new_edge)
      end
    end

    # loops until the queue is empty, removing the first element in the
    # queue and adding it to the solutions array of the vertex if the
    # cost is higher and the time lower
    until @queue.empty?
      best = @queue.pop
      return if best.nil?

      best_vertex = @vertex_array[best.destination]
      best_vertex.current_cost = best.cost
      best_vertex.current_time = best.time

      ct_array = [best.cost, best.time]
      best_vertex.add_solution(ct_array, @budget, @vertex_array[best.source])
      # recursive call
      solve(best_vertex.name)

    end
  end

  # gets the correct path from the multiple possible paths
  # takes a double array of all paths to that vertex and
  # returns the one that gives path_cost and path_time
  def get_path(double_array, path_cost, path_time)
    double_array.each do |path|
      correct_path = []
      cost = 0
      time = 0
      count = 0
      until count == path.size - 1
        correct_edge = @edge_array.find { |i| 
          i.source == path[count] && i.destination == path[count+1] 
        }
        cost += correct_edge.cost
        time += correct_edge.time
        count += 1
      end
      if cost == path_cost && time == path_time
        return path
      end
    end
  end

  # gets and prints the best solution for the budget
  def final_solution(first, last, budget)
    best_cost = -1
    best_time = 0
    final_vertex = @vertex_array[last]
    final_vertex.valid_options.each do |ct_array|
      if ct_array[0] > best_cost && ct_array[0] <= budget
        best_cost = ct_array[0]
        best_time = ct_array[1]
      end
    end
    print "\nVertex #{@vertex_array[first].name} to vertex #{@vertex_array[last].name} has cost/time options:\n"
    count = 1
    print "      (Cost, Time)\n"
    @vertex_array[last].valid_options.each do |option|
      print "#{count}\t(#{option[0]}, #{option[1]})\n"
      count += 1
    end
    if best_cost == -1
      puts "No solution found with budget #{budget}"
    else
      print "\nBest solution found within budget of #{@budget} was:\n Cost #{best_cost}\n Time #{best_time}\n"
      true_path = get_path(@vertex_array[last].final_path, best_cost, best_time)
      print "Path: "
      count = 0
      while count < true_path.size - 1
        print "#{true_path[count]} -> "
        count += 1
      end
      puts true_path[count]
    end
  end
end

if ARGV.size < 4
  puts ARGV
  puts 'Error:'
  puts 'Use: ruby cpath.rb <file> <s> <d> <budget>'
else
  file = ARGV[0]
  start = ARGV[1].to_i
  finish = ARGV[2].to_i
  budget = ARGV[3].to_i
  graph = Graph.new(budget)
  graph.read_graph_file(file)
  graph.solve_start(start)
  graph.final_solution(start, finish, budget)
end


