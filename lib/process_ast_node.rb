
def extract_code_range(code, rangy_obj)
  code[rangy_obj.begin_pos..rangy_obj.end_pos - 1] if rangy_obj
end


def process_ast_node(node, file_path, code, parent_db_entry = nil)
  #puts
  #puts

  attributes = {parent: parent_db_entry, file_path: file_path}

  attributes[:type] = node.type if node.respond_to?(:type)

  if node.respond_to?(:loc)
    loc = node.loc
    %i(line column).each do |method|
      attributes[method] = node.send(method) if node.respond_to?(method)
    end

    attributes[:loc_class] = loc.class.to_s

    # %i(name line column expression class keyword to_hash).each do |method|
    #   puts "loc.#{method}: #{loc.send(method)}" if loc.respond_to?(method)
    # end

    if loc.respond_to?(:expression)
      e = loc.expression
      # %i(begin_loc end_loc first_line last_line).each do |method|
      #   puts "expression.#{method}: #{e.send(method)}" if e.respond_to?(method)
      # end
      %i(first_line last_line begin_loc end_loc).each do |method|
        attributes[method] = e.send(method) if e.respond_to?(method)
      end

      methods = %i(
        keyword operator expression name argument
        double_colon in else assoc dot selector
        begin end
      )
      methods.each do |method|
        attributes[method] = extract_code_range(code, loc.send(method)) if loc.respond_to?(method)
      end
    end

    # skip_classes = %w(
    #   Parser::Source::Map::Definition
    # )
    # if !skip_classes.include?(loc.class.name)
    # end
  end

  attributes.reject! {|_, val| val.nil? }

  node_db_entry = ASTNode.create(attributes) if (attributes.keys - [:parent, :file_path]).present?

  if node.respond_to?(:children)
    node.children.compact.each do |child|
      process_ast_node(child, file_path, code, node_db_entry)
    end
  end

  node_db_entry
end

