module ApplicationHelper
  def link_to_trace_point(trace_point, options = {})
    if trace_point
      link_to trace_point.description, trace_point_path(trace_point), options
    else
      'None'
    end
  end

  def link_to_object(object, options = {})
    link_to object.ruby_inspect, object_path(object.ruby_object_id), options
  end
end
