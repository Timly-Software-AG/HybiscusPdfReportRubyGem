module HybiscusPdfReport
  class Config
    attr_accessor :api_key, :api_url, :timeout, :adapter, :stubs

    DEFAULT_API_URL = "https://api.hybiscus.dev/api/v1/".freeze
    DEFAULT_TIMEOUT = 10

    def initialize
      @api_key = ENV["HYBISCUS_API_KEY"]
      @api_url = ENV["HYBISCUS_API_URL"] || DEFAULT_API_URL
      @timeout = DEFAULT_TIMEOUT
      @adapter = Faraday.default_adapter
      @stubs   = nil
    end
  end

  # yields the global configuration
  def self.configure
    yield(config)
  end

  # returns the global config instance
  def self.config
    @config ||= Config.new
  end
end
