require 'parser'
require 'parser/current'
require 'pathname'
require 'neo4j'
require 'neo4j/core/cypher_session'
require 'neo4j/core/cypher_session/adaptors/http'

require './record_execution_trace'
require './process_ast_node'


Neo4j::Session.open(:server_db, 'http://neo4j:neo5j@localhost:7474')

ASTNode.delete_all
TracePointEntry.delete_all
RubyObject.delete_all
RubyFile.delete_all

def record_execution(&block)
  record_execution_trace(10) do
    block.call
  end

  file_paths = TracePointEntry.as(:tp).where_not(path: nil).pluck('DISTINCT tp.path')

  file_paths.each do |file_path|
    full_path = Pathname.new(file_path).realpath.to_s

    code = File.read(full_path)
    root = Parser::CurrentRuby.parse(code)

    root_db_entry = process_ast_node(root, full_path, code)

    root_db_entry.file = RubyFile.merge(file_path: full_path)
  end


  TracePointEntry.all.each do |tp|
    ast_node = ASTNode.find_by(file_path: tp.path, first_line: tp.lineno, name: tp.method_id, type: 'def')
    # raise "Failed to find ASTNode for TracePoint: #{tp.inspect}"
    tp.ast_node = ast_node if ast_node
  end
end

record_execution do
  def add_random(i, max = 50)
    i + rand(max)
  end

  class Foo
    def bar
      'baz'
    end
  end

  puts add_random(rand(10))

  begin
    raise "Test error"
  rescue => e
    puts e.message
  end

  add_random(4).to_param
  Foo.new.bar
end
