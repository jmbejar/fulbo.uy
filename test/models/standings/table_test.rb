require "test_helper"

class Standings::TableTest < ActiveSupport::TestCase
  setup do
    @season = create_season
    @a, @b, @c, @d = create_teams(@season, "Alfa", "Beta", "Gama", "Delta")
    @stage = @season.stages.create!(name: "Apertura", slug: "apertura", counts_for_annual: true)
  end

  test "counts points, goals and results" do
    play(@stage, @a, 2, 0, @b)
    play(@stage, @c, 1, 1, @a)

    row = Standings::Table.for_stage(@stage).find { |r| r.team == @a }

    assert_equal [ 2, 1, 1, 0, 3, 1, 2, 4 ],
                 [ row.played, row.won, row.drawn, row.lost, row.goals_for, row.goals_against, row.goal_difference, row.points ]
  end

  test "lists every season team before any match is loaded" do
    assert_equal 4, Standings::Table.for_stage(@stage).count
  end

  test "a round robin stage with matches only lists the teams in its fixture" do
    @stage.matches.create!(home_team: @a, away_team: @b, status: :scheduled)

    assert_equal [ @a, @b ].to_set, Standings::Table.for_stage(@stage).map(&:team).to_set
  end

  test "applies points adjustments" do
    play(@stage, @a, 1, 0, @b)
    play(@stage, @c, 1, 0, @d)
    @stage.points_adjustments.create!(team: @a, points: -1, reason: "Sanción")

    rows = Standings::Table.for_stage(@stage).to_a

    assert_equal @c, rows.first.team
    assert_equal 2, rows.find { |r| r.team == @a }.points
  end

  test "breaks a three-way tie by goal difference, then goals for" do
    # Each of Alfa, Beta and Gama beats one of the others and Delta loses everything.
    play(@stage, @a, 3, 0, @b)
    play(@stage, @b, 2, 0, @c)
    play(@stage, @c, 1, 0, @a)
    play(@stage, @a, 1, 0, @d)
    play(@stage, @b, 2, 0, @d)
    play(@stage, @c, 3, 1, @d)

    # All on 6 pts. GD: Alfa +3, Beta +1, Gama +1. GF: Beta 4, Gama 4 -> head-to-head: Beta beat Gama.
    assert_equal [ @a, @b, @c, @d ], Standings::Table.for_stage(@stage).map(&:team)
  end

  test "uses head-to-head before goal difference when the stage says so" do
    @stage.update!(tiebreakers: %w[head_to_head goal_difference])
    play(@stage, @a, 1, 0, @b)
    play(@stage, @b, 5, 0, @c)

    # Alfa and Beta both 3 pts; Beta has better GD but lost the direct match.
    assert_equal [ @a, @b ], Standings::Table.for_stage(@stage).first(2).map(&:team)
  end

  test "computes each group separately" do
    stage = @season.stages.create!(name: "Intermedio", slug: "intermedio", format: :groups)
    group = stage.groups.create!(name: "Serie A")
    [ @a, @b ].each { |team| group.group_memberships.create!(team: team) }
    stage.matches.create!(group: group, home_team: @a, away_team: @b, home_goals: 0, away_goals: 1, status: :finished)

    assert_equal [ @b, @a ], Standings::Table.for_stage(stage, group: group).map(&:team)
  end

  test "ignores matches that are not finished" do
    @stage.matches.create!(home_team: @a, away_team: @b, status: :scheduled)

    assert Standings::Table.for_stage(@stage).all? { |row| row.played.zero? }
  end
end
