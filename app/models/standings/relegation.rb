module Standings
  # Tabla del descenso: points per match over the current season plus the
  # previous (relegation_years - 1) seasons stored as HistoricalRecord.
  class Relegation
    Row = Data.define(:team, :points, :played, :current_points, :current_played, :previous) do
      def average = played.zero? ? 0.0 : (points.to_f / played).round(3)
    end

    def initialize(season)
      @season = season
    end

    def rows
      current = Annual.new(@season).table.index_by { |row| row.team.id }
      history = HistoricalRecord
        .where(competition: @season.competition, year: previous_years)
        .group_by(&:team_id)

      @season.teams.map { |team| build_row(team, current[team.id], history.fetch(team.id, [])) }
        .sort_by { |row| [ -row.average, -row.current_points, row.team.name ] }
    end

    private

    def previous_years
      ((@season.year - @season.relegation_years + 1)...@season.year).to_a
    end

    def build_row(team, current_row, records)
      current_points = current_row&.points.to_i
      current_played = current_row&.played.to_i
      previous = previous_years.index_with { |year| records.find { |record| record.year == year } }
      Row.new(
        team: team,
        points: current_points + records.sum(&:points),
        played: current_played + records.sum(&:matches_played),
        current_points: current_points,
        current_played: current_played,
        previous: previous
      )
    end
  end
end
