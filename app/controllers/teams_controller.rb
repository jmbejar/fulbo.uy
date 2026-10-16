class TeamsController < ApplicationController
  SEARCH_LIMIT = 6

  def index
    @query = params[:q].to_s.strip
    @teams = @query.present? ? search(@query) : []
  end

  def show
    @team = Team.find_by!(slug: params[:slug])
    matches = @team.matches.includes(:home_team, :away_team, stage: { season: :competition }).order(Match.arel_table[:kicks_off_at].asc.nulls_last, :round)
    # Results run newest first, so the latest one sits next to the upcoming matches.
    upcoming, results = matches.partition { |match| !match.decided? }
    @sections = { upcoming: upcoming, results: results.reverse }.reject { |_, list| list.empty? }
  end

  private

  # SQLite cannot ignore accents, and there are only a few dozen teams.
  def search(query)
    needle = normalize(query)
    Team.includes(:team_aliases, seasons: :competition).order(:name).select do |team|
      [ team.name, team.short_name, *team.team_aliases.map(&:name) ].compact.any? { |name| normalize(name).include?(needle) }
    end.first(SEARCH_LIMIT)
  end

  def normalize(text) = I18n.transliterate(text).downcase
end
