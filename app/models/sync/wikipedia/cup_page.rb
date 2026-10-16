module Sync
  module Wikipedia
    # Parses the wikitext of an es.wikipedia cup page ("Copa AUF Uruguay
    # 2026"). Every match is a {{Partidos}} template, placed under the
    # headings of its phase ("Fase Eliminatoria" > "Ruta Amateur",
    # "Grupo 1", "Octavos de final"). The {{OneLegResult}} summaries repeat
    # the same matches and are ignored.
    #
    # Teams are wikilinks ("[[Club Atlético Atenas (San Carlos)|Atenas]]"):
    # the article title identifies the club, the label is how it's called.
    # The winner's side is the one opened with bold (''').
    class CupPage
      Fixture = Data.define(:headings, :home, :away, :home_goals, :away_goals, :home_penalties, :away_penalties,
                            :walkover_winner, :postponed, :kicks_off_at)
      TeamRef = Data.define(:title, :name)

      HEADING = /^(={2,6})\s*(.+?)\s*\1\s*$/
      MATCH = /\{\{Partidos\s*\n(.*?)\n\}\}/m
      SCORE = /\A(\d+)\s*[:\-–]\s*(\d+)/
      WALKOVER = %r{\bw/o\b}i
      POSTPONED = /postergad|suspendid|aplazad/i
      KICKOFF = /\{\{fecha\|(\d{1,2})\|(\d{1,2})\|(\d{4})\}\}(?:\s*,\s*(\d{1,2}):(\d{2}))?/

      def initialize(wikitext)
        @wikitext = wikitext.to_s
      end

      def fixtures
        headings = @wikitext.to_enum(:scan, HEADING).map { [ $~.begin(0), $1.size, clean($2) ] }
        @wikitext.to_enum(:scan, MATCH).filter_map { fixture(params($1), headings_before($~.begin(0), headings)) }
      end

      private

      # The innermost heading of each level above the position, outermost first.
      def headings_before(position, headings)
        headings.take_while { |start, _, _| start < position }.each_with_object([]) do |(_, level, text), path|
          path.reject! { |(other, _)| other >= level }
          path << [ level, text ]
        end.map(&:last)
      end

      # "|name = value" lines; a value runs until the next "|name =" line.
      def params(body)
        body.split(/^\|/).filter_map do |chunk|
          name, value = chunk.split("=", 2)
          [ name.strip, value.to_s.strip ] if value
        end.to_h
      end

      def fixture(params, headings)
        home, away = team(params["local"]), team(params["visita"])
        return unless home && away

        result = clean(params["resultado"])
        home_goals, away_goals = result.match(SCORE)&.captures&.map(&:to_i)
        home_penalties, away_penalties = clean(params["resultado penalti"]).match(SCORE)&.captures&.map(&:to_i)
        walkover = winner_side(params) if result.match?(WALKOVER)
        Fixture.new(headings: headings, home: home, away: away,
                    home_goals: walkover ? nil : home_goals, away_goals: walkover ? nil : away_goals,
                    home_penalties: home_penalties, away_penalties: away_penalties,
                    walkover_winner: walkover, postponed: params["estado"].to_s.match?(POSTPONED),
                    kicks_off_at: kickoff(params["fecha"]))
      end

      def team(value)
        value = value.to_s.gsub(/\[\[(?:Archivo|File|Imagen):[^\]]*\]\]/i, "")
        title, name = value.match(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/)&.captures
        title ||= value[/\{\{AUF\|([^}|]+)/, 1]
        return if title.blank?

        TeamRef.new(title: title.strip, name: clean(name || title))
      end

      def winner_side(params)
        if params["local"].to_s.start_with?("'''") then "home"
        elsif params["visita"].to_s.start_with?("'''") then "away"
        end
      end

      def kickoff(value)
        day, month, year, hour, minute = value.to_s.match(KICKOFF)&.captures&.map(&:to_i)
        Time.zone.local(year, month, day, hour || 0, minute || 0) if day
      rescue ArgumentError
        nil
      end

      def clean(value)
        value.to_s.gsub(/<ref[^>]*\/>|<ref.*?(<\/ref>|\z)|<!--.*?-->/m, "").gsub(/\{\{[^}]*\}\}|'''?/, "")
          .gsub(/\[\[(?:[^\]|]*\|)?([^\]]+)\]\]/, '\1').gsub(/[[:space:]]+/, " ").strip
      end
    end
  end
end
