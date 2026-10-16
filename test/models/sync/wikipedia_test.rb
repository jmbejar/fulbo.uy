require "test_helper"

class Sync::WikipediaTest < ActiveSupport::TestCase
  TITLE = "Campeonato de Prueba 2026"

  setup do
    @season = create_season(slug: "amateur")
    @alfa, @beta, @gama, @cooper, @delta, @epsilon = create_teams(@season, "Alfa", "Beta", "Gama", "Cooper", "Delta", "Épsilon")
    @stage = @season.stages.create!(name: "Torneo Inicial", slug: "inicial", format: :groups)
    serie_a = @stage.groups.create!(name: "Serie A")
    serie_b = @stage.groups.create!(name: "Serie B")
    [ @alfa, @beta, @gama, @cooper ].each { serie_a.group_memberships.create!(team: _1) }
    [ @delta, @epsilon ].each { serie_b.group_memberships.create!(team: _1) }
    @season.external_ids.create!(source: "wikipedia", external_id: TITLE)

    @alfa_beta = match(@alfa, @beta, round: 1, on: Date.new(2026, 5, 2))
    @gama_cooper = match(@gama, @cooper, round: 1, on: Date.new(2026, 5, 2))
    @cooper_alfa = match(@cooper, @alfa, round: 2, on: nil)
    @beta_gama = match(@beta, @gama, round: 2, on: nil)
  end

  test "parses results, expanding rowspans and reading walkover winners" do
    results = page.results

    assert_equal 4, results.size
    alfa_beta, walkover, pending, cooper_alfa = results
    assert_equal [ 1, "Alfa", "Beta", 3, 0, Date.new(2026, 5, 2) ],
                 [ alfa_beta.round, alfa_beta.home_name, alfa_beta.away_name, alfa_beta.home_goals, alfa_beta.away_goals, alfa_beta.date ]
    assert_equal [ "home", Date.new(2026, 5, 2), nil ], [ walkover.walkover_winner, walkover.date, walkover.home_goals ]
    assert_nil pending.home_goals
    assert_equal [ 2, 1, 2 ], [ cooper_alfa.round, cooper_alfa.home_goals, cooper_alfa.away_goals ]
  end

  test "parses sanctions from Football tables" do
    serie_a, serie_b, general = page.tables

    alfa = serie_a.find { _1.name == "Alfa" }
    assert_equal -3, alfa.adjustment
    assert_equal "La AUF le quitó los 3 puntos obtenidos ante Beta.", alfa.reason
    assert_equal 3, serie_a.find { _1.name == "Beta" }.adjustment
    assert_equal %w[Alfa Gama Beta Cooper], serie_a.map(&:name)
    assert serie_b.all? { _1.adjustment.nil? }
    assert_equal 6, general.size
  end

  test "reports results and walkovers, and replaces the stage sanctions" do
    @stage.points_adjustments.create!(team: @delta, points: -1, reason: "Vieja")

    run_import

    assert_predicate @gama_cooper.reload, :walkover?
    assert_predicate @gama_cooper, :walkover_winner_home?
    assert_equal [ 1, 2 ], [ @cooper_alfa.reload.home_goals, @cooper_alfa.away_goals ]
    assert_predicate @beta_gama.reload, :scheduled?
    # The general table's +2 for Delta is a weighting, not a sanction.
    assert_equal [ [ @alfa.id, -3 ], [ @beta.id, 3 ] ].to_set,
                 @stage.points_adjustments.pluck(:team_id, :points).to_set
  end

  test "an aggregate table never maps to a round robin stage without matches" do
    final = @season.stages.create!(name: "Torneo Final", slug: "final")

    run_import

    assert_empty final.points_adjustments
  end

  test "walkovers count as wins without goals in the standings" do
    run_import

    gama = Standings::Table.for_stage(@stage, group: @gama_cooper.group).find { _1.team == @gama }
    assert_equal [ 1, 1, 0, 0, 3 ], [ gama.played, gama.won, gama.goals_for, gama.goals_against, gama.points ]
  end

  test "skips pages whose revision did not change" do
    cache = ActiveSupport::Cache::MemoryStore.new
    run_import(cache: cache)
    http = fake_http

    Sync::Wikipedia::Importer.new(http: http, cache: cache).call

    assert_equal 1, http.requests.size
  end

  private

  def match(home, away, round:, on:)
    group = @stage.groups.joins(:group_memberships).find_by(group_memberships: { team_id: home.id })
    @stage.matches.create!(home_team: home, away_team: away, round: round, group: group,
                           kicks_off_at: on&.in_time_zone&.change(hour: 15))
  end

  def page = Sync::Wikipedia::Page.new(html: html, wikitext: wikitext, year: 2026)

  def html = file_fixture("sync/wikipedia.html").read

  def wikitext = file_fixture("sync/wikipedia.wiki").read

  def fake_http
    FakeHttp.new(
      "action=query" => { query: { pages: [ { revisions: [ { revid: 42 } ] } ] } }.to_json,
      "action=parse" => { parse: { revid: 42, text: html, wikitext: wikitext } }.to_json
    )
  end

  def run_import(cache: ActiveSupport::Cache::NullStore.new)
    Sync::Wikipedia::Importer.new(http: fake_http, cache: cache, now: Time.zone.local(2026, 10, 15)).call
  end
end
