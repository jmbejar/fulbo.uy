module Standings
  # Builds a standings table from decided matches, applying points
  # adjustments and ordering ties with the given tiebreakers.
  class Table
    include Enumerable

    def self.for_stage(stage, group: nil)
      matches = stage.matches.decided
      matches = matches.where(group: group) if group
      new(
        teams: group ? group.teams : stage.teams,
        matches: matches,
        adjustments: stage.points_adjustments,
        tiebreakers: stage.tiebreakers
      )
    end

    def initialize(teams:, matches:, adjustments: PointsAdjustment.none, tiebreakers: Stage::TIEBREAKERS)
      @teams = teams.to_a
      @matches = matches.to_a
      @adjustments = adjustments.to_a
      @tiebreakers = Array(tiebreakers)
    end

    def each(&) = rows.each(&)

    def rows
      @rows ||= begin
        by_team = build_rows
        by_team.values
          .group_by(&:points)
          .sort_by { |points, _| -points }
          .flat_map { |_, tied| break_ties(tied, @tiebreakers) }
      end
    end

    private

    def build_rows
      by_team = @teams.index_by(&:id).transform_values { |team| Row.new(team) }
      @matches.each do |match|
        home = by_team[match.home_team_id] ||= Row.new(match.home_team)
        away = by_team[match.away_team_id] ||= Row.new(match.away_team)
        if match.walkover?
          home.record_walkover(match.walkover_winner_home?)
          away.record_walkover(match.walkover_winner_away?)
        else
          home.record(match.home_goals, match.away_goals)
          away.record(match.away_goals, match.home_goals)
        end
      end
      @adjustments.each do |adjustment|
        row = by_team[adjustment.team_id]
        row.adjustment += adjustment.points if row
      end
      by_team
    end

    # Splits the tied rows by the first criterion and recurses on the
    # groups that remain tied, so head-to-head only considers teams that
    # are still level at that point.
    def break_ties(tied, criteria)
      return tied if tied.one?
      return tied.sort_by { |row| row.team.name } if criteria.empty?

      criterion, *rest = criteria
      values = criterion_values(criterion, tied)
      return tied.sort_by { |row| row.team.name } if values.nil?

      tied.group_by { |row| values[row.team.id] }
        .sort_by { |value, _| -value }
        .flat_map { |_, subgroup| break_ties(subgroup, rest) }
    end

    def criterion_values(criterion, rows)
      case criterion
      when "goal_difference" then rows.to_h { |row| [ row.team.id, row.goal_difference ] }
      when "goals_for" then rows.to_h { |row| [ row.team.id, row.goals_for ] }
      when "head_to_head" then head_to_head_points(rows)
      when "lots" then nil # TODO: real drawing of lots; alphabetical for now.
      end
    end

    def head_to_head_points(rows)
      ids = rows.map { |row| row.team.id }
      points = ids.index_with(0)
      @matches.each do |match|
        next unless ids.include?(match.home_team_id) && ids.include?(match.away_team_id)

        case match.home_outcome
        when 1 then points[match.home_team_id] += 3
        when -1 then points[match.away_team_id] += 3
        else
          points[match.home_team_id] += 1
          points[match.away_team_id] += 1
        end
      end
      points
    end
  end
end
