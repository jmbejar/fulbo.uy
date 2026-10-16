module Sync
  module Auf
    # Builds the fixture of every current season from its competition's AUF
    # page. Only tournaments mapped to one of our stages or groups (an
    # ExternalId with source "auf" and the tournament id, e.g. "c1529") are
    # imported, so cups and unmodelled knockout rounds are skipped.
    #
    # Mapping: Competition ExternalId "auf" = page path ("liga-auf-uruguaya"),
    # Stage/Group ExternalId "auf" = tournament id, Team ExternalId "auf" =
    # club slug (learned automatically when the club's name matches).
    class Importer
      SOURCE = "auf"
      BASE_URL = "https://www.auf.org.uy/"

      def initialize(full: false, http: Http.new, now: Time.current)
        @http = http
        @now = now
        @summary = Summary.new
      end

      def call
        ExternalId.where(source: SOURCE, identifiable_type: "Competition").includes(:identifiable).each do |link|
          season = link.identifiable.seasons.find_by(current: true) or next
          import(season, Page.parse(@http.get(URI.join(BASE_URL, "#{link.external_id}/").to_s)))
        end
        @summary
      end

      def import(season, tournaments)
        targets = tournament_targets(season)
        teams = TeamResolver.new(source: SOURCE, teams: season.teams)

        tournaments.each do |tournament|
          target = targets[tournament.id] or next
          stage, group = target.is_a?(Group) ? [ target.stage, target ] : [ target, nil ]
          Match.transaction do
            tournament.fixtures.each { |fixture| import_fixture(fixture, tournament, stage, group, teams) }
          end
        end
        @summary.unresolved_teams.merge(teams.unresolved)
        @summary
      end

      private

      def tournament_targets(season)
        stages = season.stages.includes(:groups).to_a
        records = stages + stages.flat_map(&:groups)
        ExternalId.where(source: SOURCE, identifiable: records).to_h do |link|
          [ link.external_id, records.find { |record| record.class.name == link.identifiable_type && record.id == link.identifiable_id } ]
        end
      end

      def import_fixture(fixture, tournament, stage, group, teams)
        home = teams.resolve(fixture.home_name, external_id: fixture.home_slug)
        away = teams.resolve(fixture.away_name, external_id: fixture.away_slug)
        return @summary.unmatched << "#{tournament.id} #{fixture.home_name} v #{fixture.away_name}" unless home && away && home != away

        key = [ tournament.id, fixture.home_slug, fixture.away_slug ].join(":")
        match = find_or_build(key, stage, home, away)
        match.assign_attributes(stage: stage, group: group, round: fixture.round, home_team: home, away_team: away)
        match.kicks_off_at = fixture.kicks_off_at if fixture.kicks_off_at

        if match.new_record?
          match.save!
          match.external_ids.create!(source: SOURCE, external_id: key)
          @summary.count(:created)
        elsif match.changed?
          match.save!
          Resolver.call(match, now: @now)
          @summary.count(:updated)
        end

        add_to_group(group, home, away) if group
        changed = Resolver.report(match, SOURCE, now: @now, **fixture.to_h.slice(*Resolver::RESULT_ATTRIBUTES))
        @summary.count(:reported) if changed
      end

      def find_or_build(key, stage, home, away)
        ExternalId.find_by(source: SOURCE, external_id: key, identifiable_type: "Match")&.identifiable ||
          stage.matches.where(home_team: home, away_team: away).where.missing(:external_ids).first ||
          stage.matches.build
      end

      # Group stages list their teams from memberships, which AUF implies.
      def add_to_group(group, *teams)
        added = teams.map { |team| group.group_memberships.find_or_create_by!(team: team) }.any?(&:previously_new_record?)
        group.stage.touch if added
      end
    end
  end
end
