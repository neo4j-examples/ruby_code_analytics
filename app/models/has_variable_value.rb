class HasVariableValue
  include Neo4j::ActiveRel

  from_class :TracePointEntry
  to_class :RubyObject

  property :variable_name, type: String
end