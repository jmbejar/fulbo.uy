require "net/http"

module Sync
  # Minimal GET client shared by the importers. Tests swap it for a fake
  # that answers from fixture files.
  class Http
    Error = Class.new(StandardError)

    USER_AGENT = ENV.fetch("SYNC_USER_AGENT", "FulboUY/1.0 (+https://fulbo.uy)")
    MAX_REDIRECTS = 3

    def get(url, params = {})
      uri = URI(url)
      uri.query = URI.encode_www_form(params) if params.any?
      fetch(uri, MAX_REDIRECTS)
    end

    private

    def fetch(uri, redirects_left)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.get(uri.request_uri, "User-Agent" => USER_AGENT, "Accept-Encoding" => "identity")
      end

      case response
      when Net::HTTPSuccess then response.body
      when Net::HTTPRedirection
        raise Error, "Too many redirects for #{uri}" if redirects_left.zero?

        fetch(URI.join(uri, response["location"]), redirects_left - 1)
      else
        raise Error, "GET #{uri} returned #{response.code}"
      end
    end
  end
end
