module MatchesHelper
  RELATIVE_DAYS = { -1 => "yesterday", 0 => "today", 1 => "tomorrow" }.freeze

  # "2 – 1", or "vs" before kickoff.
  def match_score(match)
    return "#{match.home_goals} – #{match.away_goals}" if match.score?

    match.walkover? ? "–" : t("matches.vs")
  end

  def match_winner?(match, side)
    return match.walkover_winner == side.to_s if match.walkover?
    return false unless match.finished? && match.score?

    outcome = match.home_goals <=> match.away_goals
    outcome = match.home_penalties <=> match.away_penalties if outcome.zero? && match.penalties?
    side == :home ? outcome.positive? : outcome.negative?
  end

  # Words, not abbreviations: a badge for what needs attention, plain text otherwise.
  def match_status(match)
    case match.status
    when "live"
      tag.span t("matches.status.live"), class: "rounded-md bg-live px-2 py-px font-bold text-on-live"
    when "postponed", "suspended"
      tag.span t("matches.status.#{match.status}"), class: "rounded-md bg-badge px-2 py-px font-bold text-ink"
    when "finished", "walkover"
      tag.span t("matches.status.finished"), class: "font-bold text-ink2"
    else
      tag.span match_time(match), class: "font-bold"
    end
  end

  # AUF gives only the date until the time is set; it arrives as midnight.
  def match_time(match)
    time_known = match.kicks_off_at && match.kicks_off_at != match.kicks_off_at.beginning_of_day
    time_known ? t("matches.time", time: l(match.kicks_off_at, format: :time)) : t("matches.time_to_be_defined")
  end

  def match_note(match)
    if match.walkover?
      winner = match.walkover_winner_home? ? match.home_team : match.away_team
      t("matches.walkover_winner", team: winner.name)
    elsif match.penalties?
      home_won = match.home_penalties > match.away_penalties
      t("matches.penalties_winner", team: (home_won ? match.home_team : match.away_team).name,
        winner: [ match.home_penalties, match.away_penalties ].max, loser: [ match.home_penalties, match.away_penalties ].min)
    end
  end

  # "Sábado 10 de octubre", or "Hoy, jueves 15 de octubre" around today.
  def match_day(date)
    return t("matches.date_to_be_defined") unless date

    day = l(date, format: :day)
    relative = RELATIVE_DAYS[(date - Date.current).to_i]
    relative ? "#{t("matches.#{relative}")}, #{day}" : day.upcase_first
  end

  # A round's matches grouped by day: today and what's coming first, then
  # past days newest first, as on the team page. A cup round can span a
  # month, and its latest results matter more than the first ones.
  def fixture_days(matches)
    days = matches.group_by { |match| match.kicks_off_at&.to_date }
    past, upcoming = days.partition { |date, _| date&.past? }
    upcoming.sort_by { |date, _| date || Date.new(9999) } + past.sort_by { |date, _| date }.reverse
  end

  # "Fecha 3", or the round's name in a knockout stage ("Octavos de final").
  def round_label(round, stage: nil)
    stage&.round_name(round) || t("matches.round", number: round)
  end

  # A tie's status line in the cup bracket: "Terminado · penales 4 a 3",
  # "En juego" or when it's played.
  def tie_status(match)
    case match.status
    when "finished"
      penalties = t("matches.penalties", home: match.home_penalties, away: match.away_penalties) if match.penalties?
      [ t("matches.status.finished"), penalties ].compact.join(" · ")
    when "walkover" then match_note(match)
    when "live", "postponed", "suspended" then t("matches.status.#{match.status}")
    else
      [ match_day(match.kicks_off_at&.to_date), (match_time(match) if match.kicks_off_at) ].compact.join(" · ")
    end
  end
end
