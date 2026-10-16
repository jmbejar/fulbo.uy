module CompetitionScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_competition
  end

  private

  # The home page shows the top competition.
  def set_competition
    slug = params[:competition_slug] || params[:slug]
    @competition = slug ? Competition.find_by!(slug: slug) : Competition.by_tier.first!
    @season = @competition.current_season
    # Cached tables show crests, which the AUF sync learns after the fact and
    # deploys can bundle.
    @crests_version = [ Team.maximum(:updated_at), Team::BUNDLED_CRESTS.size ]
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
