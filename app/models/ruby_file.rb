class RubyFile
  include Neo4j::ActiveNode

  self.mapped_label_name = 'File'

  property :path, type: String, constraint: :unique
  property :content, type: String

  def line_count
    content.split(/[\r?\n?]/).size
  end
end

