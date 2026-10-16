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

  test "home shows the competitions and latest results in Spanish" do
    get root_path

    assert_response :success
    assert_select "h2", "Últimos resultados"
    assert_select "h2", "Próximos partidos"
    assert_select "a", "Primera"
  end

  test "competition page shows the current stage with tabs" do
    get competition_path("primera")

    assert_response :success
    assert_select "nav a", "Tabla Anual"
    assert_select "nav a", "Descenso"
    assert_select "h2", "Posiciones"
    assert_select "span", "Fecha 1"
  end

  test "stage page shows standings and the selected round" do
    get competition_stage_path("primera", "apertura", round: 1)

    assert_response :success
    assert_select "th", "Pts"
    assert_select "li", /2 - 1/
  end

  test "annual and relegation tables" do
    get annual_competition_path("primera")
    assert_select "h2", "Tabla Anual"

    get relegation_competition_path("primera")
    assert_select "h2", "Tabla del descenso"
    assert_select "tr.border-l-red-500", 1
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
