class MethodsController < ApplicationController
  def index
    @classes_and_methods = TracePointEntry.as(:tp).pluck('DISTINCT tp.defined_class, tp.method_id')
    @classes_and_methods.reject! { |pair| pair.any?(&:nil?) }
  end

  def show
    @defined_class = params[:defined_class]
    @method_id = params[:method_id]
    @trace_points = TracePointEntry.where(defined_class: @defined_class, method_id: @method_id)
  end
end
