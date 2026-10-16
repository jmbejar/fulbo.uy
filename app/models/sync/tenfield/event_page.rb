module Sync
  module Tenfield
    # Parses a Tenfield match page. Its header block holds the teams, the
    # date and either the score ("0 - 1") or a status such as "Pospuesto".
    class EventPage
      Result = Data.define(:home_goals, :away_goals, :postponed)

      SCORE = /(\d+)\s*-\s*(\d+)/
      POSTPONED = /Pospuesto|Postergado|Aplazado/i

      def self.parse(body)
        header = Nokogiri::HTML(body.dup.force_encoding("UTF-8")).at_css(".sp-template-event-logos")
        text = header&.text.to_s.gsub(/[[:space:]]+/, " ")
        home_goals, away_goals = text.match(SCORE)&.captures&.map(&:to_i)
        Result.new(home_goals: home_goals, away_goals: away_goals, postponed: home_goals.nil? && text.match?(POSTPONED))
      end
    end
  end
end
