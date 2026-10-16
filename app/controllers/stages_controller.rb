class StagesController < ApplicationController
  include CompetitionScoped

  def show
    @stage = @season.stages.find_by!(slug: params[:slug])
    @round = selected_round(@stage)
  end
end
