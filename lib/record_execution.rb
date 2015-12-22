require 'record_execution_trace'
require 'process_ast_node'
require 'parser/current'

def record_execution(&block)
  record_execution_trace(10) do
    begin
      block.call
    rescue Exception => e
      nil
    end
  end

  file_paths = TracePointEntry.as(:tp).where_not(path: nil).pluck('DISTINCT tp.path')

  file_paths.each do |file_path|
    full_path = Pathname.new(file_path).realpath.to_s

    code = File.read(full_path)
    root = Parser::CurrentRuby.parse(code)

    root_db_entry = process_ast_node(root, full_path, code)

    root_db_entry.from_file = RubyFile.find_or_create({file_path: full_path}, content: code)
  end


  TracePointEntry.all.each do |tp|
    ast_node = ASTNode.find_by(file_path: tp.path, first_line: tp.lineno, name: tp.method_id, type: 'def')
    # raise "Failed to find ASTNode for TracePoint: #{tp.inspect}"
    tp.ast_node = ast_node if ast_node
  end
end
