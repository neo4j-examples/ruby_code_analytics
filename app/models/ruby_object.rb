class RubyObject
  include Neo4j::ActiveNode

  self.mapped_label_name = 'Object'

  property :ruby_object_id, type: Integer, constraint: :unique
  property :ruby_inspect, type: String

  has_many :out, :instance_variable_objects, type: :INSTANCE_VARIABLE, model_class: :RubyObject

  has_one :out, :ruby_class, type: :IS_A, model_class: :RubyObject
  has_one :out, :ruby_superclass, type: :HAS_SUPERCLASS, model_class: :RubyObject

  has_many :in, :instances, type: :IS_A, model_class: :RubyObject

  has_many :in, :return_trace_points, type: :RETURNED, model_class: :TracePointEntry
  has_many :in, :object_trace_points, type: :FROM_OBJECT, model_class: :TracePointEntry
  has_many :in, :reference_trace_points, rel_class: :HasVariableValue

  def class_ancestry
    query_as(:obj).match('path=(obj)-[:IS_A*1..]->(class:Object)')
      .order('length(path)').pluck(:class)[0..-2]
  end

  def self.from_object(object)
    object_inspect = object.inspect rescue nil
    attributes = {
      ruby_object_id: object.object_id,
      ruby_inspect: object_inspect
    }
    if object.class != Class
      attributes[:ruby_class] = from_object(object.class)
    end
    if object.is_a?(Class) && object.superclass
      attributes[:ruby_superclass] = from_object(object.superclass)
    end

    attributes.reject! {|_, v| v.nil? }

    obj = find_by(ruby_object_id: object.object_id)

    obj || create(attributes)
  end
end
