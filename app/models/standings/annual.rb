module Standings
  # Tabla Anual: every stage flagged with counts_for_annual, added together.
  class Annual
    def initialize(season)
      @season = season
    end

    def table
      stages = @season.annual_stages
      Table.new(
        teams: @season.teams,
        matches: Match.decided.where(stage: stages).includes(:home_team, :away_team),
        adjustments: PointsAdjustment.where(stage: stages),
        tiebreakers: stages.first&.tiebreakers || Stage::TIEBREAKERS
      )
    end
  end
end
