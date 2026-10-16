class TeamsController < ApplicationController
  def show
    @team = Team.find_by!(slug: params[:slug])
    @matches = @team.matches.includes(:home_team, :away_team, stage: { season: :competition }).order(:kicks_off_at)
  end
end
