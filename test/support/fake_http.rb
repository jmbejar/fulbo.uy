# Stands in for Sync::Http: answers each GET with the first registered body
# whose key is contained in the requested URL (query string included).
class FakeHttp
  attr_reader :requests

  def initialize(responses = {})
    @responses = responses
    @requests = []
  end

  def get(url, params = {})
    full = params.any? ? "#{url}?#{URI.encode_www_form(params)}" : url
    @requests << full
    _, body = @responses.find { |key, _| full.include?(key) }
    raise Sync::Http::Error, "No fake response for #{full}" unless body

    body.respond_to?(:call) ? body.call : body
  end
end
