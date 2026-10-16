module Sync
  module Wikipedia
    # Builds a cup's fixture from its es.wikipedia page (see CupPage). Unlike
    # the league importer, Wikipedia is the cup's only source: this creates
    # the matches, the group memberships and the teams we don't know yet
    # (interior and Divisional D clubs).
    #
    # Mapping: Season ExternalId "wikipedia_cup" = page title. The season
    # has a groups stage, whose groups are named like the page's headings
    # ("Grupo 1"), and a knockout stage, whose rounds come from KNOCKOUT_ROUNDS.
    # Results are filed as "wikipedia" reports, so Resolver treats them like
    # any other Wikipedia result.
    #
    # Teams: Team ExternalId "wikipedia_cup" = the article title the page
    # links to. An unseen title is matched by name, but never to a team
    # already linked to another title: "[[Club Nacional de Football
    # (Florida)|Nacional]]" is not our Nacional. Titles that match no team
    # create one.
    class CupImporter
      SOURCE = "wikipedia_cup"
      REPORT_SOURCE = Importer::SOURCE

      # The page's phase headings and the knockout round each one holds. The
      # nearest matching heading wins, so "Ruta Amateur" under "Segunda Etapa
      # y Fase final" is round 2.
      KNOCKOUT_ROUNDS = {
        "Fase Eliminatoria" => 1,
        "Segunda Etapa y Fase final" => 2,
        "Octavos de final" => 3,
        "Cuartos de final" => 4,
        "Semifinales" => 5,
        "Final" => 6
      }.freeze
      GROUP = /\AGrupo \d+\z/

      def initialize(full: false, http: Http.new, now: Time.current, cache: Rails.cache)
        @force = full
        @api = Api.new(http)
        @now = now
        @cache = cache
        @summary = Summary.new
      end

      def call
        ExternalId.where(source: SOURCE, identifiable_type: "Season").includes(:identifiable).each do |link|
          season = link.identifiable
          next unless season.current?

          cache_key = "sync/wikipedia_cup/revid/#{link.external_id}"
          revid = @api.revision_id(link.external_id)
          next @summary.count(:unchanged_pages) if !@force && revid && @cache.read(cache_key) == revid

          parsed = @api.parse(link.external_id)
          import(season, CupPage.new(parsed["wikitext"]))
          @cache.write(cache_key, parsed["revid"])
        end
        @summary
      end

      def import(season, page)
        groups_stage = season.stages.find(&:format_groups?)
        knockout = season.stages.find(&:format_knockout?)
        fixtures = page.fixtures
        group_rounds = group_rounds(fixtures)

        Match.transaction do
          fixtures.each do |fixture|
            if (group_name = fixture.headings.reverse.find { _1.match?(GROUP) })
              group = groups_stage&.groups&.find { _1.name == group_name }
              next @summary.unmatched << "#{group_name}: #{label(fixture)}" unless group

              import_fixture(fixture, season, groups_stage, group, group_rounds[fixture])
            elsif (round = fixture.headings.reverse.filter_map { KNOCKOUT_ROUNDS[_1] }.first) && knockout
              import_fixture(fixture, season, knockout, nil, round)
            else
              @summary.unmatched << "#{fixture.headings.join(" > ")}: #{label(fixture)}"
            end
          end
        end
        @summary
      end

      private

      def import_fixture(fixture, season, stage, group, round)
        home, away = team(fixture.home, season), team(fixture.away, season)
        return @summary.unmatched << label(fixture) if home == away

        key = [ stage.slug, group&.name || round, fixture.home.title, fixture.away.title ].join(":")
        match = ExternalId.find_by(source: SOURCE, external_id: key, identifiable_type: "Match")&.identifiable || stage.matches.build
        match.assign_attributes(stage: stage, group: group, round: round, home_team: home, away_team: away)
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
        changed = Resolver.report(match, REPORT_SOURCE, now: @now, **fixture.to_h.slice(*Resolver::RESULT_ATTRIBUTES),
                                  walkover_winner: fixture.walkover_winner, postponed: fixture.postponed)
        @summary.count(:reported) if changed
      end

      # The page doesn't number group rounds. In a group of four, each round
      # is one of the three ways to pair the teams, so a match's round is its
      # pairing's, ordered by the pairing's first kickoff. A postponed match
      # stays in its round.
      def group_rounds(fixtures)
        fixtures.select { |fixture| fixture.headings.any? { _1.match?(GROUP) } }
          .group_by { |fixture| fixture.headings.reverse.find { _1.match?(GROUP) } }
          .each_with_object({}) do |(_, group_fixtures), rounds|
            titles = group_fixtures.flat_map { [ _1.home.title, _1.away.title ] }.uniq
            next unless titles.size == 4

            pairings = group_fixtures.group_by do |fixture|
              pair = [ fixture.home.title, fixture.away.title ]
              [ pair.sort, (titles - pair).sort ].sort
            end
            pairings.sort_by { |_, list| list.filter_map(&:kicks_off_at).min || Time.zone.local(9999) }
              .each_with_index { |(_, list), index| list.each { rounds[_1] = index + 1 } }
          end
      end

      def team(ref, season)
        @teams ||= ExternalId.where(source: SOURCE, identifiable_type: "Team").includes(:identifiable)
          .to_h { [ _1.external_id, _1.identifiable ] }
        team = @teams[ref.title] ||= link_team(ref)
        season.participations.find_or_create_by!(team: team)
        team
      end

      def link_team(ref)
        team = by_name(ref.name)
        team = nil if team && @teams.value?(team)
        team ||= create_team(ref)
        team.external_ids.create!(source: SOURCE, external_id: ref.title)
        team
      end

      def by_name(name)
        @names ||= Team.includes(:team_aliases).each_with_object(Hash.new { |h, k| h[k] = [] }) do |team, index|
          [ team.name, team.short_name, *team.team_aliases.map(&:name) ].compact.map { TeamResolver.normalize(_1) }.uniq
            .each { |key| index[key] << team }
        end
        matches = @names[TeamResolver.normalize(name)]
        matches.first if matches.one?
      end

      # The label names the club unless one of ours already has it; then the
      # article title's disambiguation is added ("Nacional (Florida)").
      def create_team(ref)
        name = ref.name
        if Team.exists?(name: name) || Team.exists?(slug: name.parameterize)
          name = "#{name} (#{ref.title[/\(([^)]+)\)\z/, 1] || ref.title})"
        end
        @summary.count(:teams_created)
        Team.create!(name: name, short_name: name, slug: name.parameterize).tap do |team|
          @names[TeamResolver.normalize(name)] << team
        end
      end

      # Group stages list their teams from memberships, which the fixture implies.
      def add_to_group(group, *teams)
        added = teams.map { |team| group.group_memberships.find_or_create_by!(team: team) }.any?(&:previously_new_record?)
        group.stage.touch if added
      end

      def label(fixture) = "#{fixture.home.name} v #{fixture.away.name}"
    end
  end
end
