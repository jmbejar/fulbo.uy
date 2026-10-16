require "test_helper"

class PagesTest < ActionDispatch::IntegrationTest
  setup do
    @season = create_season(relegation_years: 2, relegation_zones: [ { "from" => 2, "to" => 2, "zone" => "relegation" } ])
    @a, @b = create_teams(@season, "Peñarol", "Nacional")
    @apertura = @season.stages.create!(name: "Apertura", slug: "apertura", counts_for_annual: true, position: 1)
    @clausura = @season.stages.create!(name: "Clausura", slug: "clausura", counts_for_annual: true, position: 2, current: true)
    play(@apertura, @a, 2, 1, @b, round: 1)
    @clausura.matches.create!(home_team: @b, away_team: @a, round: 1, status: :scheduled)
  end

  test "home shows the top competition's matches" do
    get root_path

    assert_response :success
    assert_select "h1", "Primera"
    assert_select "nav a[aria-current=page]", "Primera"
    assert_select "nav a[aria-current=page]", "Partidos"
    assert_select "turbo-frame#team_search[target=_top]"
    assert_select "strong", "Fecha 1"
  end

  test "navbar links land on each competition's main table" do
    Competition.create!(name: "Segunda", slug: "segunda", tier: 2)
    Competition.create!(name: "Amateur", slug: "amateur", tier: 3)
    get root_path

    assert_select "header nav a[href=?]", competition_stage_path("primera", "clausura", view: "standings"), "Primera"
    assert_select "header nav a[href=?]", annual_competition_path("segunda"), "Segunda"
    assert_select "header nav a[href=?]", competition_stage_path("amateur", "final", view: "standings"), "Amateur"
  end

  test "competition page switches between matches and standings" do
    get competition_path("primera")
    assert_select "h2", "Partidos"
    assert_select "nav a", "Tabla"

    get competition_stage_path("primera", "clausura", view: "standings")
    assert_select "h2", "Tabla de posiciones"
    assert_select "nav a", "Anual"
    assert_select "nav a", "Descenso"
    assert_select "th span", "Puntos"
  end

  test "stage page shows the selected round with the winner in bold" do
    get competition_stage_path("primera", "apertura", round: 1)

    assert_response :success
    assert_select "h2", "Partidos · Apertura"
    assert_select "p", /2 – 1/
    assert_select "span.font-bold", "Peñarol"
    assert_select "p span", "Terminado"
  end

  test "live matches are announced with words" do
    @clausura.matches.first.update!(status: :live, home_goals: 0, away_goals: 0)
    get competition_path("primera")

    assert_select "p", /En juego: 1 partido/
    assert_select "span.bg-live", "En juego"
  end

  test "annual and relegation tables label their zones" do
    get annual_competition_path("primera")
    assert_select "nav a[aria-current=page]", "Anual"

    get relegation_competition_path("primera")
    assert_select "th span", "Promedio"
    assert_select "tr[data-zone=relegation]", 1
    assert_select "th[scope=rowgroup]", /Zona de descenso \(2º\)/
  end

  test "team search ignores accents" do
    get teams_path(q: "penarol")
    assert_select "a[href=?]", team_path(@a)

    get teams_path(q: "defensor")
    assert_select "p", "No encontramos ese equipo."
  end

  test "team page lists upcoming matches before results, newest result first" do
    play(@clausura, @a, 1, 0, @b, round: 2)
    get team_path(@a)

    assert_response :success
    assert_select "h1", "Peñarol"
    assert_select "h2", count: 2 do |headings|
      assert_equal [ "Próximos partidos", "Resultados" ], headings.map(&:text)
    end
    assert_select "section[aria-labelledby=results-heading] h3" do |stages|
      assert_equal [ "Primera · Clausura", "Primera · Apertura" ], stages.map { _1.text.strip }
    end
  end

  test "cup knockout rounds are named and the bracket marks penalty winners" do
    season = create_season(slug: "copa")
    knockout = season.stages.create!(name: "Eliminatorias", slug: "eliminatorias", format: :knockout, current: true,
                                     round_names: [ "Segunda fase", "Octavos de final" ])
    knockout.matches.create!(home_team: @a, away_team: @b, round: 1, status: :finished,
                             home_goals: 1, away_goals: 1, home_penalties: 3, away_penalties: 4)

    get competition_path("copa")
    assert_select "strong", "Segunda fase"
    assert_select "nav a", "Cuadro"

    get competition_stage_path("copa", "eliminatorias", view: "standings")
    assert_select "h2", "Cuadro del torneo"
    assert_select "h3", "Octavos de final"
    assert_select "p", "A definir"
    assert_select "p", "Terminado · penales 3 a 4"
    assert_select "span.font-bold", "Nacional"
  end

  test "unknown competition is not found" do
    get competition_path("tercera")

    assert_response :not_found
  end
end
