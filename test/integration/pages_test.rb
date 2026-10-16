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

  test "team page lists its matches" do
    get team_path(@a)

    assert_response :success
    assert_select "h1", "Peñarol"
    assert_select "h2", "Partidos"
  end

  test "unknown competition is not found" do
    get competition_path("tercera")

    assert_response :not_found
  end
end
