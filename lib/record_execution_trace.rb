require 'pathname'
require 'parser/current'

CYAN = "\e[36m"
CLEAR = "\e[0m"
GREEN = "\e[32m"

def tracepoint_string(tp, indent)
  parts = []
  parts << "#{'|  ' * indent}"
  parts << "#{CYAN if tp.event == :call}%-8s#{CLEAR}"
  parts << "%s:%-4d %-18s\n"
  parts.join(' ') % [tp.event, tp.path, tp.lineno, tp.defined_class.to_s + '#' + GREEN + tp.method_id.to_s + CLEAR]
end

FILE_LINES = {}

def get_file_line(path, lineno)
  FILE_LINES[path] ||= File.read(path).lines

  FILE_LINES[path][lineno - 1]
end

def extract_variables(ast_node)
  if ast_node.is_a?(Parser::AST::Node)
    if ast_node.type == :send &&
         ast_node.children.size == 2 &&
         ast_node.children[0].nil?
      [ast_node.children[1]]
    else
      ast_node.children.flat_map do |child|
        extract_variables(child)
      end
    end
  else
    []
  end
end

def get_trace_point_var(tp, var_name)
  begin
    tp.binding.local_variable_get(variable)
  rescue NameError
    throw :not_found
  end
end

def record_received_arguments(tp, tracepoint_db_entry)
  require 'pry'
  # Can't just use #method method because some objects implement a #method method
  method = if tp.self.class.instance_method(:method).owner == Kernel
    tp.self.method(tp.method_id) rescue binding.pry
  else
    tp.self.class.instance_method(tp.method_id)
  end
  parameter_names = method.parameters.map {|_, name| name }
  arguments = parameter_names.each_with_object({}) do |name, arguments|
    catch :not_found do
      arguments[name] = get_trace_point_var(tp, name)
    end
  end
  arguments.each do |name, object|
    argument_value = RubyObject.from_object(object)
    ReceivedArgument.create(tracepoint_db_entry, argument_value, argument_name: name)
  end
end

def record_referenced_variables(tp, tracepoint_db_entry)
  line = get_file_line(tp.path, tp.lineno)
  root = Parser::CurrentRuby.parse(line)
  extract_variables(root).each do |variable|
    catch :not_found do
      value = get_trace_point_var(tp, variable)
      object_entry = RubyObject.from_object(value)
      HasVariableValue.create(tracepoint_db_entry, object_entry, variable_name: variable)
    end
  end
rescue Parser::SyntaxError
  nil
end

def record_execution_trace(levels = 4)
  execution_index = 0
  indent = 0
  output = ''
  last_tracepoint_db_entry = nil
  last_start_time = nil
  ancestor_stack = []
  run_time_stack = []

  last_tracepoint_end_time = nil
  last_run_time = nil

  trace = TracePoint.new do |tp|
    last_run_time = 1_000_000.0 * (Time.now - last_tracepoint_end_time) if last_tracepoint_end_time
    puts 'last_run_time', last_run_time.inspect

    output << tracepoint_string(tp, indent)

    last_method_time = nil
    if [:call, :c_call].include?(tp.event)
      run_time_stack.push(0)
    elsif [:return, :c_return].include?(tp.event)
      last_method_time = run_time_stack.pop
    else
      run_time_stack[-1] += last_run_time if run_time_stack[-1] && last_run_time
    end

    associated_call_trace_point = nil
    if [:return, :c_return].include?(tp.event) && indent.nonzero?
      indent -= 1
      associated_call_trace_point = ancestor_stack.pop
    elsif [:call, :c_call].include?(tp.event)
      indent += 1
    end

    attributes = %i(event lineno defined_class method_id).each_with_object({}) do |method, attributes|
      attributes[method] = tp.send(method)
    end
    
    attributes[:execution_time] = last_method_time.round if last_method_time
    attributes[:execution_index] = (execution_index += 1)

    attributes[:path] = Pathname.new(tp.path).realpath.to_s
    attributes[:return_value] = RubyObject.from_object(tp.return_value) if [:return, :c_return].include?(tp.event)
    attributes[:ruby_object] = RubyObject.from_object(tp.self) unless tp == tp.self
    
    last_tracepoint_db_entry = TracePointEntry.create(attributes.merge(previous: last_tracepoint_db_entry, parent: ancestor_stack.last))

    last_tracepoint_db_entry.call_point = associated_call_trace_point if associated_call_trace_point

    record_referenced_variables(tp, last_tracepoint_db_entry) if tp.event == :line
    record_received_arguments(tp, last_tracepoint_db_entry) if tp.event == :call

    if [:call, :c_call].include?(tp.event)
      ancestor_stack.push(last_tracepoint_db_entry)
    end

    last_tracepoint_end_time = Time.now
  end

  trace.enable
  yield
ensure
  trace.disable
  puts output
end


