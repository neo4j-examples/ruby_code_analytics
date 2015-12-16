require './file'

class ASTNode
  include Neo4j::ActiveNode

  property :type, type: String, index: :exact
  property :file_path, type: String, index: :exact
  property :line, type: Integer
  property :column, type: Integer
  property :first_line, type: Integer
  property :last_line, type: Integer

  property :loc_class, type: String

  property :name, type: String
  property :argument, type: String
  property :assoc, type: String
  property :keyword, type: String
  property :operator, type: String
  property :expression, type: String
  property :double_colon, type: String
  property :dot, type: String
  property :selector, type: String
  property :else, type: String
  property :in, type: String
  property :begin, type: String
  property :end, type: String

  has_one :out, :parent, type: :HAS_PARENT, model_class: :ASTNode

  has_one :out, :file, type: :FROM_FILE, model_class: :RubyFile
end


