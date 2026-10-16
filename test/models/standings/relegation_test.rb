require "test_helper"

class Standings::RelegationTest < ActiveSupport::TestCase
  test "averages current and previous season points per match" do
    season = create_season(relegation_years: 2)
    a, b = create_teams(season, "Alfa", "Ascendido")
    stage = season.stages.create!(name: "Apertura", slug: "apertura", counts_for_annual: true)
    play(stage, a, 0, 1, b)
    play(stage, b, 0, 0, a)
    season.competition.historical_records.create!(team: a, year: 2025, points: 60, matches_played: 30)

    rows = Standings::Relegation.new(season).rows.index_by(&:team)

    assert_equal [ 61, 32 ], [ rows[a].points, rows[a].played ]
    assert_in_delta 1.906, rows[a].average
    assert_in_delta 2.0, rows[b].average # promoted team: only current season
    assert_equal [ b, a ], Standings::Relegation.new(season).rows.map(&:team)
  end
end
