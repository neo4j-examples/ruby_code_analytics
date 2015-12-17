class ObjectsController < ApplicationController
  def index
    @object_data = RubyObject.as(:obj)
                    .optional(:ruby_class, :class)
                    .order('class.ruby_inspect, obj.ruby_inspect')
                    .pluck('obj.ruby_object_id, obj.ruby_inspect, class.ruby_inspect')
  end

  def show
    @object = RubyObject.find_by(ruby_object_id: params[:object_id])
  end
end
