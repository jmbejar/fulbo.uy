module Sync
  module Tenfield
    # Parses the RSS feed of a Tenfield Estadísticas (SportsPress) season.
    # Each match is a post titled "Home — Away", published at kickoff time.
    # The feed also carries other posts (players), which are dropped.
    class Feed
      Item = Data.define(:home_name, :away_name, :url, :published_at)

      SEPARATOR = " — "

      def self.parse(body)
        Nokogiri::XML(body).css("item").filter_map do |item|
          home, away = item.at("title").text.strip.split(SEPARATOR, 2)
          next unless home.present? && away.present?

          Item.new(home_name: home, away_name: away, url: item.at("link").text.strip,
                   published_at: Time.zone.parse(item.at("pubDate").text))
        end
      end
    end
  end
end
