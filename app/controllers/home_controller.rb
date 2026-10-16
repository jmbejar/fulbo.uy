class HomeController < ApplicationController
  def index
    @competitions = Competition.by_tier.includes(:seasons)
    @latest_matches = Match.finished.recent_first.includes(:home_team, :away_team, stage: { season: :competition }).limit(12)
    @upcoming_matches = Match.scheduled.order(:kicks_off_at).includes(:home_team, :away_team, stage: { season: :competition }).limit(12)
  end
end
