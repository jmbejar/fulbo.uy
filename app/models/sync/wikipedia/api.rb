module Sync
  module Wikipedia
    # Thin wrapper over the es.wikipedia MediaWiki API.
    class Api
      ENDPOINT = "https://es.wikipedia.org/w/api.php"

      def initialize(http)
        @http = http
      end

      def revision_id(title)
        data = call(action: "query", prop: "revisions", rvprop: "ids", titles: title, redirects: 1)
        data.dig("query", "pages")&.first&.dig("revisions", 0, "revid")
      end

      # => { "revid" => Integer, "text" => rendered HTML, "wikitext" => source }
      def parse(title)
        data = call(action: "parse", page: title, prop: "text|wikitext|revid", redirects: 1)
        raise Http::Error, "Wikipedia: #{data.dig("error", "info")} (#{title})" if data["error"]

        data["parse"]
      end

      private

      def call(params)
        JSON.parse(@http.get(ENDPOINT, params.merge(format: "json", formatversion: 2)))
      end
    end
  end
end
