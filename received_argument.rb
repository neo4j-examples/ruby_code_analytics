class ReceivedArgument
  include Neo4j::ActiveRel

  from_class :TracePointEntry
  to_class :RubyObject
  
  property :argument_name
end