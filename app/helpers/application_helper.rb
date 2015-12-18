module ApplicationHelper
  def link_to_trace_point(trace_point)
    if trace_point
      link_to trace_point.description, trace_point_path(trace_point)
    else
      'None'
    end
  end

  def link_to_object(object)
    link_to object.ruby_inspect, object_path(object.ruby_object_id)
  end
end
