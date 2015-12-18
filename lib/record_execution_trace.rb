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

def record_execution_trace(levels = 4)

  execution_index = 1
  indent = 0
  output = ''
  last_tracepoint_db_entry = nil
  ancestor_stack = []
  trace = TracePoint.new do |tp|
    output << tracepoint_string(tp, indent)


    if [:return, :c_return].include?(tp.event) && indent.nonzero?
      indent -= 1
      ancestor_stack.pop
    else
      if [:call, :c_call].include?(tp.event)
        indent += 1
      end
    end

    if tp.event# != :line
      attributes = %i(event defined_class method_id).each_with_object({}) do |method, attributes|
        attributes[method] = tp.send(method)
      end
      #unless [:c_call, :c_return].include?(tp.event)
        attributes[:lineno] = tp.lineno
        attributes[:path] = Pathname.new(tp.path).realpath.to_s
      #end

      attributes[:return_value] = RubyObject.from_object(tp.return_value) if [:return, :c_return].include?(tp.event)
      attributes[:ruby_object] = RubyObject.from_object(tp.self) unless tp == tp.self

      attributes[:execution_index] = execution_index
      execution_index += 1

      last_tracepoint_db_entry = TracePointEntry.create(attributes.merge(previous: last_tracepoint_db_entry, parent: ancestor_stack.last))

      if tp.event == :line
        begin
          line = get_file_line(tp.path, tp.lineno)
          root = Parser::CurrentRuby.parse(line)
          extract_variables(root).each do |variable|
            begin
              value = tp.binding.local_variable_get(variable)
            rescue NameError
              nil
            end
            object_entry = RubyObject.from_object(value)
            HasVariableValue.create(last_tracepoint_db_entry, object_entry, variable_name: variable)
          end
        rescue Parser::SyntaxError
          nil
        end
      end

      if tp.event == :call
        method = tp.self.method(tp.method_id)
        parameter_names = method.parameters.map {|_, name| name }
        arguments = parameter_names.each_with_object({}) do |name, arguments|
          arguments[name] = tp.binding.local_variable_get(name)
        end
        arguments.each do |name, object|
          argument_value = RubyObject.from_object(object)
          ReceivedArgument.create(last_tracepoint_db_entry, argument_value, argument_name: name)
        end
      end
    end

    if [:call, :c_call].include?(tp.event)
      ancestor_stack.push(last_tracepoint_db_entry)
    end    
  end

  trace.enable
  yield
ensure
  trace.disable
  puts output
end


