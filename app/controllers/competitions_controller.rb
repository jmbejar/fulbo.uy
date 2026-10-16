class CompetitionsController < ApplicationController
  include CompetitionScoped

  def show
    @stage = @season.current_stage
    @round = selected_round(@stage)
    render "stages/show"
  end

  def annual
    raise ActiveRecord::RecordNotFound unless @season.annual?

    @table = Standings::Annual.new(@season).table
  end

  def relegation
    raise ActiveRecord::RecordNotFound unless @season.relegation?

    @rows = Standings::Relegation.new(@season).rows
  end
end
