class HomeController < ApplicationController
  def index
    @first_trace_point = TracePointEntry.as(:tp).where_not("()-[:NEXT]->(tp)").limit(1).pluck(:tp).first
  end
end
