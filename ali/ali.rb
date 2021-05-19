# Piotr Ramza
# pramza2
# 663328597
# Project 2 : Virtual Machine
#
class VirtualMachine


  # set all values on virtual machine to default values
  def initialize
    super
    @file_name = ''
    @memory = Array.new(256, 0)
    @memory_counter = 0
    @register_a = 0
    @register_b = 0
    @pc = 0
    @zero_bit = 0
    @overflow = 0
    @done = false
    @line = Execute.new
    @file = ExecuteAll.new
  end

  attr_accessor(:memory, :register_a, :register_b, :pc, :zero_bit, :overflow, :done, :memory_counter)

  # places the code into memory, starting at memory slot 0
  def populate_memory
    File.foreach(@file_name) do |line|
      @memory[@memory_counter] = line.chomp
      @memory_counter += 1

      @done = true if @memory_counter > 255
    end
  end

  def loop
    # asks the user for a file and populates memory using that file
    # and shows current values of virtual machine
    print "Please enter file name:\n"
    @file_name = gets.chomp
    populate_memory

    # not enough memory for code
    if @done
      puts 'Not enough memory for file'
      return
    end

    print_values

    # ask user for command, either 'l' 'a' or 'q'
    print "\nPlease enter a command:\n"
    input = gets.chomp

    while input != 'q' && !@done
      # execute the next instruction
      if input == 'l'
        command = @memory[@pc].split
        print "Instruction: #{command[0]}\n"
        @line.run_instruction(self, command)
        print_values
      # execute all instructions until HLT
      elsif input == 'a'
        @file.run_file(self)
        print_values
      elsif input == 'q'
        @done = true
      end

      unless done
        print "\nPlease enter a command:\n"
        input = gets.chomp
      end

    end
  end

  # prints the important information stored in the virtual machine
  def print_values
    print "\nRegister A: #{@register_a}\tRegister B: #{@register_b}\n"
    print "Zero Bit: #{@zero_bit}\tOverflow Bit: #{@overflow}\n"
    print "Program Counter: #{@pc}\n"
    print "Memory: #{@memory}\n"
  end

end # end of class Virtual

# class that executes single instructions
class Execute
  def initialize
    super
    @converter = Binary.new
  end

  # executes a single instruction,
  # command is an array holding the instruction in 0
  # and any value it needs in 1
  def run_instruction(vm, command)

    # declare a symbol and save it in the next available memory
    # position. The value will be stored in the position after that
    if command[0] == 'DEC'
      vm.memory[vm.memory_counter] = command[1]
      vm.memory_counter += 2

    elsif command[0] == 'LDA'
      index = vm.memory.index(command[1])
      vm.register_a = @converter.to_decimal(vm.memory[index + 1])

    elsif command[0] == 'LDB'
      index = vm.memory.index(command[1])
      vm.register_b = @converter.to_decimal(vm.memory[index + 1])

    # Loads the integer value into the accumulator register. The value could be negative.
    elsif command[0] == 'LDI'
      vm.register_a = command[1].to_i

      # store register a value at symbol (command[1])
      # if no such symbol exists, make one
    elsif command[0] == 'STR'
      index = vm.memory.index(command[1])
      vm.memory[index + 1] = @converter.to_binary(vm.register_a)

    # Exchanges the content registers A and B.
    elsif command[0] == 'XCH'
      temp = vm.register_a
      vm.register_a = vm.register_b
      vm.register_b = temp

    # Transfers control to instruction at address number in program memory
    elsif command[0] == 'JMP'
      vm.pc = command[1].to_i - 1

    # Transfers control to instruction at address number if the zero-result bit is set.
    elsif command[0] == 'JZS'
      vm.pc = command[1].to_i - 1 if vm.zero_bit == 1

    # Transfers control to instruction at address number if the overflow bit is set.
    elsif command[0] == 'JVS'
      vm.pc = command[1].to_i - 1 if vm.overflow == 1

    # Adds the content of registers A and B. The sum is stored
    # in A. The overflow and zero-result bits are set or cleared as needed.
    elsif command[0] == 'ADD'
      result = vm.register_a.to_i + vm.register_b.to_i
      if result > 2_147_483_647 || result < -2_147_483_648
        vm.overflow = 1
        dif = result - 2_147_483_647
        vm.register_a = dif - 2_147_483_648
      else
        vm.register_a = result
        vm.overflow = 0
      end
      vm.zero_bit = if vm.register_a.zero?
                      1
                    else
                      0
                    end
    elsif command[0] == 'HLT'
      vm.done = true
    end
    vm.pc += 1
  end
end

# class that handles execution of the entire file
# inherits single line instruction running from Execute class
class ExecuteAll < Execute

  # execute all instructions in memory until HLT is reached
  def run_file(vm)
    until vm.done
      command = vm.memory[vm.pc]
      instruction = command.split
      run_instruction(vm, instruction)
    end
  end
end

# class that turns binary into decimal and decimal to binary
class Binary
  def to_binary(decimal)
    if decimal >= 0
      '0' << decimal.to_s(2)
    else
      (-2**32 - decimal).to_s(2)[1...33]
    end
  end

  def to_decimal(binary)
    decimal = binary.to_i(2)
    if decimal >= 2**31
      decimal - 2**32
    else
      decimal
    end
  end
end

vm = VirtualMachine.new
vm.loop
