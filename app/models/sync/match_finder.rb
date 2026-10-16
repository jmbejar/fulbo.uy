module Sync
  # Finds the fixture match a source is talking about. The same pairing can
  # repeat within a scope (double round robins, Inicial vs Final), so ties are
  # broken by round and then by the closest kickoff date.
  class MatchFinder
    MAX_DATE_DISTANCE = 21 # days

    def initialize(matches)
      @by_pair = matches.to_a.group_by { |match| [ match.home_team_id, match.away_team_id ] }
    end

    def find(home, away, round: nil, on: nil)
      candidates = @by_pair.fetch([ home.id, away.id ], [])
      return candidates.first if candidates.one?

      if round
        same_round = candidates.select { |match| match.round == round }
        return same_round.first if same_round.one?
      end
      closest(candidates, on) if on
    end

    private

    def closest(candidates, date)
      dated = candidates.select(&:kicks_off_at)
        .map { |match| [ (match.kicks_off_at.to_date - date).abs, match ] }
        .select { |distance, _| distance <= MAX_DATE_DISTANCE }
        .sort_by(&:first)
      return if dated.empty? || (dated.many? && dated[0][0] == dated[1][0])

      dated.first.last
    end
  end
end
