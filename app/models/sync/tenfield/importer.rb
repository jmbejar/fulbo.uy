module Sync
  module Tenfield
    # Reports scores from Tenfield Estadísticas, usually the first source to
    # publish them. It never creates matches: each post is matched to the AUF
    # fixture by teams and kickoff date (Tenfield's matchday numbers don't
    # follow ours).
    #
    # Mapping: Stage or Season ExternalId "tenfield" = season slug
    # ("clausura-2026"; Segunda's "lapro-anual-2026" spans the whole season).
    #
    # The default run only reads the newest feed page of scopes with recent
    # matches; `full: true` walks every page back to the scope's first match.
    class Importer
      SOURCE = "tenfield"
      BASE_URL = "https://estadisticas.tenfield.com.uy/season/"
      RECENT = 3.days
      MAX_PAGES = 40

      def initialize(full: false, http: Http.new, now: Time.current, pause: full ? 0.5 : 0)
        @full = full
        @http = http
        @now = now
        @pause = pause
        @summary = Summary.new
      end

      def call
        ExternalId.where(source: SOURCE, identifiable_type: %w[Stage Season]).includes(:identifiable).each do |link|
          scope = link.identifiable
          season = scope.is_a?(Season) ? scope : scope.season
          next unless season.current?

          matches = scope.matches.includes(:reports).to_a
          next unless @full || recent?(matches)

          import(link.external_id, season, matches)
        end
        @summary
      end

      def import(slug, season, matches)
        teams = TeamResolver.new(source: SOURCE, teams: season.teams)
        finder = MatchFinder.new(matches)
        feed_items(slug, matches).sort_by(&:published_at).each do |item|
          home, away = teams.resolve(item.home_name), teams.resolve(item.away_name)
          match = finder.find(home, away, on: item.published_at.to_date) if home && away
          next @summary.unmatched << "#{slug} #{item.home_name} v #{item.away_name}" unless match
          next if settled?(match)

          sleep @pause if @pause.positive?
          result = EventPage.parse(@http.get(item.url))
          changed = Resolver.report(match, SOURCE, now: @now, **result.to_h)
          @summary.count(:reported) if changed
        end
        @summary.unresolved_teams.merge(teams.unresolved)
        @summary
      end

      private

      def recent?(matches)
        matches.any? { |match| match.kicks_off_at&.between?(@now - RECENT, @now) }
      end

      # Outside full runs, a final score we already have from Tenfield is
      # not fetched again.
      def settled?(match)
        !@full && match.decided? && match.reports.any? { |report| report.source == SOURCE && report.score? }
      end

      def feed_items(slug, matches)
        earliest = matches.filter_map(&:kicks_off_at).min
        (1..(@full ? MAX_PAGES : 1)).each_with_object([]) do |page, items|
          batch = Feed.parse(@http.get("#{BASE_URL}#{slug}/feed/", page > 1 ? { paged: page } : {}))
          # Past the last page the feed drifts into older site-wide posts.
          batch = batch.select { |item| earliest.nil? || item.published_at >= earliest - 7.days }
          break items if batch.empty?

          items.concat(batch)
        end.uniq(&:url)
      end
    end
  end
end
