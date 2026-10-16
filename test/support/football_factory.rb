module FootballFactory
  def create_season(slug: "primera", year: 2026, **attrs)
    competition = Competition.create!(name: slug.titleize, slug: slug, tier: 1)
    competition.seasons.create!(year: year, current: true, **attrs)
  end

  def create_teams(season, *names)
    names.map do |name|
      Team.create!(name: name, slug: name.parameterize).tap { |team| season.participations.create!(team: team) }
    end
  end

  def play(stage, home, home_goals, away_goals, away, round: 1)
    stage.matches.create!(home_team: home, away_team: away, home_goals: home_goals, away_goals: away_goals,
                          status: :finished, round: round)
  end
end
