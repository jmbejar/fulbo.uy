module Sync
  module Auf
    # Parses an auf.org.uy "Fixture y Posiciones" page. Every tournament of
    # the division is rendered inline as a pane (#fmuestro_cNNNN), titled by
    # its tab (#tab_cNNNN), with "FECHA n" headings and .item-fixture rows.
    # The standings tables on the page come from COMET and lag behind, so
    # they are ignored: we compute standings from the matches. Each club link
    # carries the club's crest.
    class Page
      Tournament = Data.define(:id, :name, :fixtures)
      Fixture = Data.define(:round, :home_name, :home_slug, :home_crest, :away_name, :away_slug, :away_crest,
                            :home_goals, :away_goals, :home_penalties, :away_penalties, :kicks_off_at)

      RESULT = /\A(?:\((\d+)\)\s*)?(\d+)\s*-\s*(\d+)(?:\s*\((\d+)\))?\z/
      KICKOFF = %r{(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:\s*-\s*(\d{1,2}):(\d{2}))?}

      def self.parse(body) = new(body).tournaments

      def initialize(body)
        html = body.dup.force_encoding("ISO-8859-1").encode("UTF-8")
        @doc = Nokogiri::HTML(html)
      end

      def tournaments
        names = @doc.css("[id^=tab_c]").to_h { |tab| [ tab["id"].delete_prefix("tab_"), squish(tab.text) ] }
        @doc.css("div[id^=fmuestro_c]").map do |pane|
          id = pane["id"].delete_prefix("fmuestro_")
          Tournament.new(id: id, name: names[id], fixtures: fixtures(pane))
        end
      end

      private

      def fixtures(pane)
        pane.css("div[id^=parti_]").flat_map do |round_div|
          round = round_div.xpath("preceding::div[starts-with(@id, 'fixnom_')][1]").text[/\d+/]&.to_i
          round_div.css(".item-fixture").filter_map { |item| fixture(item, round) }
        end
      end

      def fixture(item, round)
        home, away = item.css("a[href]").first(2)
        return unless home && away

        pens_home, home_goals, away_goals, pens_away = squish(item.at_css(".resultado")&.text).match(RESULT)&.captures&.map { _1&.to_i }
        Fixture.new(
          round: round,
          home_name: team_name(home), home_slug: slug(home), home_crest: crest(home),
          away_name: team_name(away), away_slug: slug(away), away_crest: crest(away),
          home_goals: home_goals, away_goals: away_goals, home_penalties: pens_home, away_penalties: pens_away,
          kicks_off_at: kickoff(item.at_css(".fecha_estadio strong")&.text)
        )
      end

      def team_name(link) = squish(link.at_css(".hidden-xs")&.text.presence || link["title"])

      def slug(link) = link["href"].to_s.delete("/").presence

      def crest(link)
        src = link.at_css("img[src]")&.[]("src").presence
        URI.join(Importer::BASE_URL, src).to_s if src
      rescue URI::InvalidURIError
        nil
      end

      def kickoff(text)
        day, month, year, hour, minute = squish(text).match(KICKOFF)&.captures&.map(&:to_i)
        return unless day

        Time.zone.local(year, month, day, hour || 0, minute || 0)
      end

      def squish(text) = text.to_s.gsub(/[[:space:]]+/, " ").strip
    end
  end
end
