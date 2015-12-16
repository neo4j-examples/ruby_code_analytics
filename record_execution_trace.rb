require './trace_point_entry'
require './ruby_object'
require './received_argument'
require 'pathname'

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
      indent += 1 if [:call, :c_call].include?(tp.event)
    end

    if tp.event != :line
      attributes = %i(event lineno defined_class method_id).each_with_object({}) do |method, attributes|
        attributes[method] = tp.send(method)
      end
      unless [:c_call, :c_return].include?(tp.event)
        attributes[:path] = Pathname.new(tp.path).realpath.to_s
      end

      attributes[:return_value] = RubyObject.from_object(tp.return_value) if [:return, :c_return].include?(tp.event)
      attributes[:ruby_object] = RubyObject.from_object(tp.self) unless tp == tp.self

      attributes[:execution_index] = execution_index
      execution_index += 1

      last_tracepoint_db_entry = TracePointEntry.create(attributes.merge(previous: last_tracepoint_db_entry, parent: ancestor_stack.last))

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

      ancestor_stack.push(last_tracepoint_db_entry)
    end

  end

  trace.enable
  yield
ensure
  trace.disable
  puts output
end


