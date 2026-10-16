require "test_helper"

class Sync::ResolverTest < ActiveSupport::TestCase
  setup do
    season = create_season
    @home, @away = create_teams(season, "Alfa", "Beta")
    stage = season.stages.create!(name: "Clausura", slug: "clausura")
    @kickoff = Time.zone.local(2026, 10, 10, 15)
    @match = stage.matches.create!(home_team: @home, away_team: @away, kicks_off_at: @kickoff)
    @later = @kickoff + 1.day
  end

  test "a score makes the match finished" do
    report("auf", home_goals: 2, away_goals: 1)

    assert_predicate @match, :finished?
    assert_equal [ 2, 1 ], [ @match.home_goals, @match.away_goals ]
  end

  test "Tenfield's score wins over Wikipedia's, which wins over AUF's" do
    report("auf", home_goals: 0, away_goals: 0)
    report("wikipedia", home_goals: 1, away_goals: 0)
    assert_equal [ 1, 0 ], [ @match.home_goals, @match.away_goals ]

    report("tenfield", home_goals: 2, away_goals: 0)
    assert_equal [ 2, 0 ], [ @match.home_goals, @match.away_goals ]
  end

  test "a walkover from Wikipedia overrides the score AUF records" do
    report("auf", home_goals: 0, away_goals: 0)
    report("wikipedia", walkover_winner: "away")

    assert_predicate @match, :walkover?
    assert_predicate @match, :walkover_winner_away?
    assert_nil @match.home_goals
  end

  test "a source going blank does not clear its score" do
    report("auf", home_goals: 3, away_goals: 1)
    report("auf", home_goals: nil, away_goals: nil)

    assert_equal [ 3, 1 ], [ @match.home_goals, @match.away_goals ]
  end

  test "an unchanged report is not written again" do
    assert report("auf", home_goals: 1, away_goals: 1)
    assert_not report("auf", home_goals: 1, away_goals: 1)
  end

  test "a score during the match is live, and finished after the window" do
    report("tenfield", now: @kickoff + 30.minutes, home_goals: 1, away_goals: 0)
    assert_predicate @match, :live?

    Sync::Resolver.refresh_live(now: @kickoff + 3.hours)
    assert_predicate @match.reload, :finished?
  end

  test "a postponement without a score marks the match postponed" do
    report("tenfield", postponed: true)
    assert_predicate @match, :postponed?

    report("auf", home_goals: 1, away_goals: 0)
    assert_predicate @match, :finished?
  end

  private

  def report(source, now: @later, **attrs) = Sync::Resolver.report(@match, source, now: now, **attrs)
end
