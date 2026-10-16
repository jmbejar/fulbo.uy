module CompetitionScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_competition
  end

  private

  def set_competition
    @competition = Competition.find_by!(slug: params[:competition_slug] || params[:slug])
    @season = @competition.current_season
  end

  # The round shown in the fixtures: the requested one, or the next round
  # with pending matches, or the last one.
  def selected_round(stage)
    rounds = stage.rounds
    requested = params[:round].to_i
    return requested if rounds.include?(requested)

    stage.matches.scheduled.minimum(:round) || rounds.last
  end
end
