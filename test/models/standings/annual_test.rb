require "test_helper"

class Standings::AnnualTest < ActiveSupport::TestCase
  test "adds up only the stages that count for the annual table" do
    season = create_season
    a, b = create_teams(season, "Alfa", "Beta")
    apertura = season.stages.create!(name: "Apertura", slug: "apertura", counts_for_annual: true)
    clausura = season.stages.create!(name: "Clausura", slug: "clausura", counts_for_annual: true)
    copa = season.stages.create!(name: "Copa", slug: "copa", counts_for_annual: false)
    play(apertura, a, 1, 0, b)
    play(clausura, b, 2, 2, a)
    play(copa, b, 3, 0, a)
    clausura.points_adjustments.create!(team: a, points: -1)

    rows = Standings::Annual.new(season).table.index_by(&:team)

    assert_equal [ 2, 3, 3 ], [ rows[a].played, rows[a].points, rows[a].goals_for ]
    assert_equal [ 2, 1 ], [ rows[b].played, rows[b].points ]
  end
end
