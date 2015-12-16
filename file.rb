class RubyFile
  include Neo4j::ActiveNode

  self.mapped_label_name = 'File'

  property :file_path, constraint: :unique
end

