require "test_helper"

class Sync::WikipediaCupTest < ActiveSupport::TestCase
  TITLE = "Copa AUF Uruguay 2026"

  setup do
    @season = create_season(slug: "copa")
    @penarol, @danubio, @atenas, @bella_vista = %w[Peñarol Danubio Atenas Bella\ Vista].map { Team.create!(name: _1, slug: _1.parameterize) }
    @torque = Team.create!(name: "Montevideo City Torque", short_name: "City Torque", slug: "montevideo-city-torque")
    @terremoto = Team.create!(name: "Terremoto", slug: "terremoto")
    @groups = @season.stages.create!(name: "Fase de grupos", slug: "grupos", format: :groups, position: 1)
    @grupo1 = @groups.groups.create!(name: "Grupo 1", position: 1)
    @knockout = @season.stages.create!(name: "Eliminatorias", slug: "eliminatorias", format: :knockout, position: 2, current: true,
                                       round_names: [ "Primera fase amateur", "Segunda fase", "Octavos de final" ])
    @season.external_ids.create!(source: "wikipedia_cup", external_id: TITLE)
  end

  test "parses every Partidos template with the headings above it" do
    fixtures = page.fixtures

    assert_equal 12, fixtures.size
    first = fixtures.first
    assert_equal [ "Fase Eliminatoria", "Ruta Amateur" ], first.headings
    assert_equal [ "Club Atlético Terremoto", "Terremoto" ], [ first.home.title, first.home.name ]
    assert_equal [ 0, 2, Time.zone.local(2026, 9, 9, 20, 0) ], [ first.home_goals, first.away_goals, first.kicks_off_at ]
    assert_equal [ "Fase Eliminatoria", "Ruta Profesional", "Grupo 1" ], fixtures[1].headings

    gladiador = fixtures.find { _1.home.name == "Gladiador" }
    assert_equal [ "Segunda Etapa y Fase final", "Ruta Amateur" ], gladiador.headings
    assert_equal [ 1, 1, 4, 1 ], [ gladiador.home_goals, gladiador.away_goals, gladiador.home_penalties, gladiador.away_penalties ]

    pending = fixtures.find(&:postponed)
    assert_equal [ nil, nil, "Peñarol" ], [ pending.home_goals, pending.away_goals, pending.home.name ]
  end

  test "reads walkovers from the bold side" do
    wikitext = "{{Partidos\n|local = [[A FC|A]]\n|resultado = w/o\n|visita = '''[[B FC|B]]\n}}"

    fixture = Sync::Wikipedia::CupPage.new(wikitext).fixtures.sole

    assert_equal [ "away", nil ], [ fixture.walkover_winner, fixture.home_goals ]
  end

  test "builds the groups and knockout rounds, creating the teams we don't have" do
    summary = run_import

    assert_equal 11, @season.matches.count
    assert_equal [ @penarol, @danubio, @atenas, @torque ].to_set, @grupo1.teams.to_set
    assert_equal({ 1 => 2, 2 => 2, 3 => 2 }, @groups.matches.group(:round).count)
    first_round = @groups.matches.where(round: 1).map { [ _1.home_team, _1.away_team ] }
    assert_equal [ [ @penarol, @torque ], [ @danubio, @atenas ] ].to_set, first_round.to_set

    amateur = @knockout.matches.find_by!(round: 1)
    assert_equal [ @terremoto, @bella_vista, 0, 2 ], [ amateur.home_team, amateur.away_team, amateur.home_goals, amateur.away_goals ]

    gladiador = Team.find_by!(name: "Gladiador")
    tie = @knockout.matches.find_by!(home_team: gladiador)
    assert_equal [ 2, "finished", 4, 1 ], [ tie.round, tie.status, tie.home_penalties, tie.away_penalties ]
    assert_predicate @knockout.matches.find_by!(home_team: @penarol), :postponed?

    assert_equal 4, summary.counts[:teams_created]
    assert_includes @season.teams, gladiador
    assert_equal [ "Goleadores: Peñarol v Montevideo City Torque" ], summary.unmatched
  end

  test "keys teams on the linked article, so labels that drop the disambiguation still match" do
    run_import

    florida = Team.find_by!(name: "Nacional (Florida)")
    assert_equal 2, florida.matches.count
    assert_equal 3, @atenas.matches.count
  end

  test "never links a team to a second article" do
    nacional = Team.create!(name: "Nacional", slug: "nacional")
    nacional.external_ids.create!(source: "wikipedia_cup", external_id: "Club Nacional de Football")
    wikitext = "== Segunda Etapa y Fase final ==\n{{Partidos\n|local = [[Club Nacional de Football (Florida)|Nacional]]\n" \
               "|resultado = 2:0\n|visita = [[Club Atlético Peñarol|Peñarol]]\n}}"

    Sync::Wikipedia::CupImporter.new(now: now).import(@season, Sync::Wikipedia::CupPage.new(wikitext))

    match = @knockout.matches.sole
    assert_equal "Nacional (Florida)", match.home_team.name
    assert_not_equal nacional, match.home_team
  end

  test "running twice changes nothing and keeps the scores" do
    run_import
    summary = run_import

    assert_equal 11, @season.matches.count
    assert_equal({}, summary.counts.except(:unchanged_pages))
  end

  test "skips the page when its revision did not change" do
    cache = ActiveSupport::Cache::MemoryStore.new
    run_import(cache: cache)
    http = fake_http

    Sync::Wikipedia::CupImporter.new(http: http, cache: cache).call

    assert_equal 1, http.requests.size
  end

  private

  def now = Time.zone.local(2026, 10, 16)

  def wikitext = file_fixture("sync/copa.wiki").read

  def page = Sync::Wikipedia::CupPage.new(wikitext)

  def fake_http
    FakeHttp.new(
      "action=query" => { query: { pages: [ { revisions: [ { revid: 7 } ] } ] } }.to_json,
      "action=parse" => { parse: { revid: 7, text: "", wikitext: wikitext } }.to_json
    )
  end

  def run_import(cache: ActiveSupport::Cache::NullStore.new)
    Sync::Wikipedia::CupImporter.new(http: fake_http, cache: cache, now: now).call
  end
end
