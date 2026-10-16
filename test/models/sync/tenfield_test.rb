require "test_helper"

class Sync::TenfieldTest < ActiveSupport::TestCase
  setup do
    @season = create_season
    @penarol, @nacional, @defensor, @cerro = create_teams(@season, "Peñarol", "Nacional", "Defensor Sporting", "Cerro")
    @stage = @season.stages.create!(name: "Clausura", slug: "clausura")
    @stage.external_ids.create!(source: "tenfield", external_id: "clausura-2026")
    @now = Time.zone.local(2026, 8, 10, 12)
    @http = FakeHttp.new(
      "/season/clausura-2026/feed/" => file_fixture("sync/tenfield_feed.xml").read,
      "/event/penarol-nacional/" => file_fixture("sync/tenfield_event.html").read,
      "/event/defensor-sporting-cerro/" => file_fixture("sync/tenfield_event_postponed.html").read
    )
  end

  test "the feed keeps match posts only" do
    items = Sync::Tenfield::Feed.parse(file_fixture("sync/tenfield_feed.xml").read)

    assert_equal [ [ "Peñarol", "Nacional" ], [ "Defensor Sporting", "Cerro" ] ], items.map { [ _1.home_name, _1.away_name ] }
    assert_equal Time.zone.local(2026, 8, 8, 18, 30, 44), items.first.published_at
  end

  test "an event page gives the score or the postponement" do
    played = Sync::Tenfield::EventPage.parse(file_fixture("sync/tenfield_event.html").read)
    postponed = Sync::Tenfield::EventPage.parse(file_fixture("sync/tenfield_event_postponed.html").read)

    assert_equal [ 3, 1, false ], [ played.home_goals, played.away_goals, played.postponed ]
    assert_equal [ nil, nil, true ], [ postponed.home_goals, postponed.away_goals, postponed.postponed ]
  end

  test "reports scores on the fixture match closest in date" do
    early = match(@penarol, @nacional, Time.zone.local(2026, 3, 1, 18))
    current = match(@penarol, @nacional, Time.zone.local(2026, 8, 8, 18, 30))
    postponed = match(@defensor, @cerro, Time.zone.local(2026, 8, 9, 15))

    Sync::Tenfield::Importer.new(http: @http, now: @now).call

    assert_predicate early.reload, :scheduled?
    assert_equal [ 3, 1 ], [ current.reload.home_goals, current.away_goals ]
    assert_predicate postponed.reload, :postponed?
  end

  test "skips scopes without recent matches unless running fully" do
    match(@penarol, @nacional, Time.zone.local(2026, 3, 1, 18))

    Sync::Tenfield::Importer.new(http: @http, now: @now).call
    assert_empty @http.requests
  end

  test "does not fetch a final score again outside full runs" do
    current = match(@penarol, @nacional, Time.zone.local(2026, 8, 8, 18, 30))
    Sync::Tenfield::Importer.new(http: @http, now: @now).call
    assert_predicate current.reload, :finished?

    @http.requests.clear
    Sync::Tenfield::Importer.new(http: @http, now: @now).call
    assert_not @http.requests.any? { _1.include?("/event/penarol-nacional/") }
  end

  private

  def match(home, away, kickoff) = @stage.matches.create!(home_team: home, away_team: away, kicks_off_at: kickoff)
end
