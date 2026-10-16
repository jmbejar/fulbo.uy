module Sync
  module Wikipedia
    # Corrects the fixture with what es.wikipedia editors record from AUF
    # rulings: results AUF never entered, walkovers (which AUF shows as 0-0)
    # and points sanctions.
    #
    # Mapping: Stage or Season ExternalId "wikipedia" = page title.
    #
    # Sanctions: for every stage a Football table maps to, Wikipedia owns the
    # stage's PointsAdjustments; they are replaced by the table's
    # ajustar_puntos. A table maps to a group (groups stage) or a round robin
    # stage when its teams are exactly that group's or stage's teams, so
    # aggregate tables such as Primera C's "Tabla general" (whose
    # ajustar_puntos are a weighting, not sanctions) are ignored.
    class Importer
      SOURCE = "wikipedia"

      def initialize(full: false, http: Http.new, now: Time.current, cache: Rails.cache)
        @force = full
        @api = Api.new(http)
        @now = now
        @cache = cache
        @summary = Summary.new
      end

      def call
        ExternalId.where(source: SOURCE, identifiable_type: %w[Stage Season]).includes(:identifiable).each do |link|
          scope = link.identifiable
          season = scope.is_a?(Season) ? scope : scope.season
          next unless season.current?

          cache_key = "sync/wikipedia/revid/#{link.external_id}"
          revid = @api.revision_id(link.external_id)
          next @summary.count(:unchanged_pages) if !@force && revid && @cache.read(cache_key) == revid

          parsed = @api.parse(link.external_id)
          import(scope, season, Page.new(html: parsed["text"], wikitext: parsed["wikitext"], year: season.year))
          @cache.write(cache_key, parsed["revid"])
        end
        @summary
      end

      def import(scope, season, page)
        teams = TeamResolver.new(source: SOURCE, teams: season.teams)
        import_results(scope, page, teams)
        import_adjustments(scope.is_a?(Season) ? season.stages.to_a : [ scope ], page, teams)
        @summary.unresolved_teams.merge(teams.unresolved)
        @summary
      end

      private

      def import_results(scope, page, teams)
        finder = MatchFinder.new(scope.matches.includes(:reports))
        page.results.each do |result|
          next unless result.walkover_winner || result.home_goals

          home, away = teams.resolve(result.home_name), teams.resolve(result.away_name)
          match = finder.find(home, away, round: result.round, on: result.date) if home && away
          next @summary.unmatched << "#{result.home_name} v #{result.away_name} (fecha #{result.round})" unless match

          changed = Resolver.report(match, SOURCE, now: @now, home_goals: result.home_goals, away_goals: result.away_goals,
                                    walkover_winner: result.walkover_winner)
          @summary.count(:reported) if changed
        end
      end

      def import_adjustments(stages, page, teams)
        wanted = Hash.new { |hash, stage| hash[stage] = [] }
        page.tables.each do |rows|
          team_ids = rows.map { |row| teams.resolve(row.name)&.id }
          next if team_ids.include?(nil)

          stage = stage_for(stages, team_ids.to_set) or next
          rows.zip(team_ids).each do |row, team_id|
            wanted[stage] << { team_id: team_id, points: row.adjustment, reason: row.reason } if row.adjustment&.nonzero?
          end
        end
        wanted.each { |stage, adjustments| replace_adjustments(stage, adjustments) }
      end

      def stage_for(stages, team_ids)
        stages.find do |stage|
          if stage.format_groups?
            stage.groups.any? { |group| group.group_memberships.pluck(:team_id).to_set == team_ids }
          else
            # Without matches a round robin stage lists every season team,
            # which an aggregate table would match.
            stage.matches.exists? && stage.teams.pluck(:id).to_set == team_ids
          end
        end
      end

      def replace_adjustments(stage, adjustments)
        current = stage.points_adjustments.map { |a| { team_id: a.team_id, points: a.points, reason: a.reason } }
        key = ->(list) { list.map { |a| [ a[:team_id], a[:points], a[:reason].to_s ] }.sort }
        return if key.(current) == key.(adjustments)

        PointsAdjustment.transaction do
          stage.points_adjustments.destroy_all
          adjustments.each { |attrs| stage.points_adjustments.create!(attrs) }
        end
        @summary.count(:adjustments_replaced)
      end
    end
  end
end
