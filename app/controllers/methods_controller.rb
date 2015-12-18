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

    @class_and_method_parent_trace_points = call_trace_points.parent(rel_length: 1..10)
      .where('result_parent.method_id IS NOT NULL')
      .where("result_parent.event IN ['call', 'c_call']")
      .pluck('result_parent.defined_class, result_parent.method_id, collect(result_parent)')

    @class_and_method_child_trace_points = call_trace_points.children(rel_length: 1..10)
      .where('result_children.method_id IS NOT NULL')
      .where("result_children.event IN ['call', 'c_call']")
      .pluck('result_children.defined_class, result_children.method_id, collect(result_children)')
  end
end
