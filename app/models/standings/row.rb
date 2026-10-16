module Standings
  class Row
    attr_reader :team
    attr_accessor :played, :won, :drawn, :lost, :goals_for, :goals_against, :adjustment

    def initialize(team)
      @team = team
      @played = @won = @drawn = @lost = @goals_for = @goals_against = @adjustment = 0
    end

    def record(scored, conceded)
      self.played += 1
      self.goals_for += scored
      self.goals_against += conceded
      if scored > conceded then self.won += 1
      elsif scored == conceded then self.drawn += 1
      else self.lost += 1
      end
    end

    # A walkover counts as played and won/lost, without goals.
    def record_walkover(won)
      self.played += 1
      won ? self.won += 1 : self.lost += 1
    end

    def points = won * 3 + drawn + adjustment

    def goal_difference = goals_for - goals_against
  end
end
