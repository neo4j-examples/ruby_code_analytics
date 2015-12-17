class TracePointsController < ApplicationController
  def show
    @trace_point = TracePointEntry.find(params[:id])
  end
end
