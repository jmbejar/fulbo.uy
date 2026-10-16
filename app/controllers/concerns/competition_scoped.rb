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

  # The round shown in the fixtures: the requested one, or the round of the
  # next match on the calendar, or else the latest results, since a round
  # without dates yet has nothing to show but team names. Matches still
  # scheduled on a past day (usually postponed without notice) don't count,
  # or one of them would pin the page to an old round.
  def selected_round(stage)
    rounds = stage.rounds
    requested = params[:round].to_i
    return requested if rounds.include?(requested)

    stage.matches.where(status: %i[scheduled live], kicks_off_at: Date.current.beginning_of_day..).order(:kicks_off_at).pick(:round) ||
      stage.matches.decided.order(kicks_off_at: :desc).pick(:round) ||
      rounds.first
  end
end
