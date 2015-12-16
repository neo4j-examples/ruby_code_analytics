// Match a ruby object with it's class` AST node
MATCH (o:Object)<-[:FROM_OBJECT]-(tp:TracePoint)--(n:ASTNode)-[:HAS_PARENT*]->(class:ASTNode {type: 'class'})
RETURN o.ruby_object_id, o.ruby_inspect, class.name, class.expression

// See everything that has been returned and from where
MATCH (tp:TracePoint)-[:RETURNED]->(o:Object)-[:IS_A]-(class:Object)
WHERE tp.event IN ['return', 'c_return']
RETURN tp.path, tp.lineno, tp.defined_class, tp.method_id, o.ruby_inspect, class.ruby_inspect
ORDER BY tp.execution_index


// Show all returns of a particular superclass
MATCH (tp:TracePoint)-[:RETURNED]->(o:Object)-[:IS_A]-(class:Object)-[:HAS_SUPERCLASS*]->(superclass:Object {ruby_inspect: 'Numeric'})
WHERE tp.event IN ['return', 'c_return']
RETURN tp.path, tp.lineno, tp.defined_class, tp.method_id, o.ruby_inspect, class.ruby_inspect
ORDER BY tp.execution_index