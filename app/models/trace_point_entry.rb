class TracePointEntry
  include Neo4j::ActiveNode

  self.mapped_label_name = 'TracePoint'

  property :event, type: String
  property :path, type: String, index: :exact
  property :lineno, type: Integer
  property :defined_class, type: String
  property :method_id, type: String
  property :execution_index, type: Integer

  has_one :in, :previous, type: :NEXT, model_class: :TracePoint
  has_one :out, :next, type: :NEXT, model_class: :TracePoint

  has_one :out, :parent, type: :HAS_PARENT, model_class: :TracePoint
  has_many :in, :children, type: :HAS_PARENT, model_class: :TracePoint

  has_one :out, :ast_node, type: :HAS_AST_NODE, model_class: :ASTNode

  has_one :out, :return_value, type: :RETURNED, model_class: :RubyObject
  has_one :out, :ruby_object, type: :FROM_OBJECT

  def description
    line_description = if path.present?
      "#{File.basename(path)}:#{lineno}"
    else
      "(line #{lineno})"
    end
    "#{event} #{defined_class}##{method_id} #{line_description}"
  end

  def file
    RubyFile.find_by(file_path: path) if path
  end

  def line_range
    lineno
  end
end


