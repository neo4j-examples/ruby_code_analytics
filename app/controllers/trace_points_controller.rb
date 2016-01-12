class TracePointsController < ApplicationController
  def show
    @trace_point = TracePointEntry.find(params[:id])

    @file = @trace_point.file

    # Hack to make things faster for now...
    # with_associations seems to be a bit broken...

    instance_variables = {
      ['HAS_PARENT', true] => :parent,
      ['HAS_PARENT', false] => :children,
      ['NEXT', true] => :next,
      ['NEXT', false] => :previous,
      ['HAS_AST_NODE', true] => :ast_node,
      ['RECEIVED_ARGUMENT', true] => :arguments,
      ['RETURNED', true] => :return_value,
      ['HAS_VARIABLE_VALUE', true] => :variable_values
    }

    instance_variables.values.each do |instance_variable|
      association = TracePointEntry.associations[instance_variable]
      instance_variable_set("@#{instance_variable}", association.type == :has_one ? nil : [])
    end

    associations_by_rel_type = @trace_point.query_as(:tp)
      .optional_match('(tp)-[rel]-(other_node)')
      .pluck('type(rel), startNode(rel) = tp AS outbound, collect(other_node)').each do |rel_type, outbound, other_nodes|

        instance_variable = instance_variables[[rel_type, outbound]]
        if instance_variable
          association = TracePointEntry.associations[instance_variable]
          instance_variable_set("@#{instance_variable}", association.type == :has_one ? other_nodes.first : (other_nodes || []))
        end
    end
  end
end
