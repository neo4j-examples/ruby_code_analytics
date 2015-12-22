class MethodsController < ApplicationController
  def index
    @classes_and_methods = TracePointEntry.as(:tp).pluck('DISTINCT tp.defined_class, tp.method_id')
    @classes_and_methods.reject! { |pair| pair.any?(&:nil?) }

    @class_ast_nodes = ASTNode.where(type: 'class').index_by(&:name)
  end

  def show
    @defined_class = params[:defined_class]
    @method_id = params[:method_id]
    @trace_points = TracePointEntry.where(defined_class: @defined_class, method_id: @method_id)

    call_trace_points = @trace_points.where(event: ['call', 'c_call'])

    @class_and_method_parent_trace_points = call_trace_points.parent(:parent, nil, rel_length: 1..10)
      .where_not(method_id: nil)
      .where(event: ['call', 'c_call'])
      .pluck(:defined_class, :method_id, 'collect(parent)')

    @class_and_method_child_trace_points = call_trace_points.children(:child, nil, rel_length: 1..10)
      .where_not(method_id: nil)
      .where(event: ['call', 'c_call'])
      .pluck(:defined_class, :method_id, 'collect(child)')
  end
end
