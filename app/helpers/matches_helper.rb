module MatchesHelper
  def match_score(match)
    return t("matches.vs") unless match.score?

    score = "#{match.home_goals} - #{match.away_goals}"
    score += " (#{match.home_penalties} - #{match.away_penalties} #{t('matches.penalties_short')})" if match.penalties?
    score
  end

  def match_date(match)
    return t("matches.to_be_defined") unless match.kicks_off_at

    l(match.kicks_off_at, format: :match)
  end

  def round_label(round)
    t("matches.round", number: round)
  end
end
