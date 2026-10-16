module Sync
  # Counters an importer run reports back (logged, and printed by the rake tasks).
  class Summary
    attr_reader :counts, :unresolved_teams, :unmatched

    def initialize
      @counts = Hash.new(0)
      @unresolved_teams = Set.new
      @unmatched = []
    end

    def count(key, by = 1) = @counts[key] += by

    def to_h
      counts.merge(unresolved_teams: unresolved_teams.to_a, unmatched: unmatched.first(20), unmatched_count: unmatched.size)
        .reject { |_, value| value.respond_to?(:empty?) && value.empty? }
    end
  end
end
