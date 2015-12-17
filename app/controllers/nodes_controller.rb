class NodesController < ApplicationController
  def index
    @root_nodes = ASTNode.as(:root).where_not('()<-[:HAS_PARENT]-(root)').pluck(:root)
  end

  def show
    @node = ASTNode.find(params[:id])
  end
end
