require "test_helper"

class Sync::AufTest < ActiveSupport::TestCase
  setup do
    @body = file_fixture("sync/auf.html").binread
    @season = create_season
    @penarol, @nacional, @defensor, @cerro = create_teams(@season, "Peñarol", "Nacional", "Defensor Sporting", "Cerro")
    @defensor.team_aliases.create!(name: "Def. Sporting")
    @stage = @season.stages.create!(name: "Clausura", slug: "clausura")
    @stage.external_ids.create!(source: "auf", external_id: "c100")
    @season.competition.external_ids.create!(source: "auf", external_id: "liga-auf-uruguaya")
    @http = FakeHttp.new("auf.org.uy/liga-auf-uruguaya/" => @body)
    @now = Time.zone.local(2026, 10, 15, 12)
  end

  test "parses every tournament pane with rounds, scores, penalties and dates" do
    clausura, copa = Sync::Auf::Page.parse(@body)

    assert_equal [ "c100", "CLAUSURA 2026" ], [ clausura.id, clausura.name ]
    assert_equal "c200", copa.id
    first, unscheduled, penalties = clausura.fixtures
    assert_equal [ 1, "Peñarol", "club-atletico-penarol", 2, 1 ],
                 [ first.round, first.home_name, first.home_slug, first.home_goals, first.away_goals ]
    assert_equal Time.zone.local(2026, 8, 8, 18, 30), first.kicks_off_at
    assert_nil unscheduled.kicks_off_at
    assert_nil unscheduled.home_goals
    assert_equal [ 2, 1, 1, 4, 3 ],
                 [ penalties.round, penalties.home_goals, penalties.away_goals, penalties.home_penalties, penalties.away_penalties ]
    assert_equal Time.zone.local(2026, 8, 15), penalties.kicks_off_at
  end

  test "builds the fixture of mapped tournaments only" do
    summary = run_import

    assert_equal 4, @stage.matches.count
    assert_equal 4, summary.counts[:created]
    assert_equal 0, Match.where.not(stage: @stage).count

    match = @stage.matches.find_by!(home_team: @penarol, away_team: @nacional)
    assert_predicate match, :finished?
    assert_equal [ 2, 1, 1 ], [ match.home_goals, match.away_goals, match.round ]
    assert_predicate @stage.matches.find_by!(home_team: @defensor, away_team: @cerro), :scheduled?
  end

  test "remembers club slugs once a name matches" do
    run_import

    assert_equal @defensor, ExternalId.find_by!(source: "auf", external_id: "defensor-sporting-club").identifiable
  end

  test "a second run with the same data changes nothing and keeps the stage cache" do
    run_import
    stamp = @stage.reload.updated_at

    travel 1.hour do
      summary = run_import
      assert_empty summary.counts.except(:unchanged)
      assert_equal stamp, @stage.reload.updated_at
    end
  end

  test "adds group memberships for tournaments mapped to a group" do
    group = @stage.groups.create!(name: "Serie A")
    @stage.update!(format: :groups)
    @stage.external_ids.destroy_all
    group.external_ids.create!(source: "auf", external_id: "c100")

    run_import

    assert_equal [ @penarol, @nacional, @defensor, @cerro ].to_set, group.teams.to_set
    assert @stage.matches.all? { |match| match.group == group }
  end

  test "reports unknown team names instead of guessing" do
    @cerro.update!(name: "Cerro Largo")

    summary = run_import

    assert_includes summary.unresolved_teams, "Cerro"
    assert_equal 2, @stage.matches.count
  end

  private

  def run_import = Sync::Auf::Importer.new(http: @http, now: @now).call
end
