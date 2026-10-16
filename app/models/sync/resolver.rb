module Sync
  # Derives a match's result and status from its reports:
  # 1. A walkover reported by Wikipedia wins over everything.
  # 2. Otherwise the score comes from the first source that has one, in
  #    SCORE_PRECEDENCE order. Disagreements are logged.
  # 3. A score means "finished", or "live" during LIVE_WINDOW after kickoff.
  # 4. With no score, a postponement report means "postponed"; else "scheduled".
  class Resolver
    SCORE_PRECEDENCE = %w[tenfield wikipedia auf].freeze
    LIVE_WINDOW = 2.hours
    RESULT_ATTRIBUTES = %i[home_goals away_goals home_penalties away_penalties].freeze

    # Files what a source says about a match and re-resolves it when that
    # changes. A source going blank never clears a score it reported before.
    def self.report(match, source, now: Time.current, **attrs)
      report = match.reports.find { |r| r.source == source } || match.reports.build(source: source)
      attrs = attrs.except(*RESULT_ATTRIBUTES) if report.score? && attrs.values_at(:home_goals, :away_goals).any?(&:nil?)
      report.assign_attributes(attrs)
      return false unless report.new_record? || report.changed?

      report.reported_at = now
      report.save!
      call(match, now: now)
      true
    end

    # Matches left "live" turn "finished" once the window passes.
    def self.refresh_live(now: Time.current)
      Match.live.includes(:reports).find_each { |match| call(match, now: now) }
    end

    def self.call(match, now: Time.current) = new(match, now).call

    def initialize(match, now)
      @match = match
      @now = now
      @reports = match.reports.index_by(&:source)
    end

    def call
      @match.assign_attributes(resolved_attributes)
      @match.save! if @match.changed?
      @match
    end

    private

    def resolved_attributes
      if (walkover = @reports["wikipedia"]&.walkover_winner)
        return blank_result.merge(status: :walkover, walkover_winner: walkover)
      end

      scored = SCORE_PRECEDENCE.filter_map { |source| @reports[source] }.select(&:score?)
      log_conflict(scored) if scored.map(&:score).uniq.many?

      if (best = scored.first)
        RESULT_ATTRIBUTES.to_h { |attr| [ attr, best[attr] ] }.merge(status: played_status, walkover_winner: nil)
      elsif @reports.values.any?(&:postponed)
        blank_result.merge(status: :postponed)
      else
        blank_result.merge(status: @match.suspended? ? :suspended : :scheduled)
      end
    end

    def blank_result = RESULT_ATTRIBUTES.index_with(nil).merge(walkover_winner: nil)

    def played_status
      kickoff = @match.kicks_off_at
      kickoff && kickoff <= @now && @now < kickoff + LIVE_WINDOW ? :live : :finished
    end

    def log_conflict(scored)
      details = scored.map { |report| "#{report.source}=#{report.home_goals}-#{report.away_goals}" }.join(" ")
      Rails.logger.warn("[sync] Score conflict for match #{@match.id} " \
                        "(#{@match.home_team&.name} v #{@match.away_team&.name}): #{details}")
    end
  end
end
