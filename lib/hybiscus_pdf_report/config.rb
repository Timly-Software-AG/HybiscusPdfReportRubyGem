# frozen_string_literal: true

require "faraday"

# Main module for the Hybiscus PDF Report gem
module HybiscusPdfReport
  # Configuration class for the Hybiscus PDF Report gem.
  #
  # This class manages all configuration settings including API credentials,
  # URLs, timeouts, and connection adapters. Configuration can be set through
  # environment variables or programmatically.
  #
  # @example Setting configuration programmatically
  #   HybiscusPdfReport.configure do |config|
  #     config.api_key = "your_api_key"
  #     config.api_url = "https://api.hybiscus.dev/api/v1/"
  #     config.timeout = 30
  #   end
  #
  # @example Using environment variables
  #   ENV["HYBISCUS_API_KEY"] = "your_api_key"
  #   ENV["HYBISCUS_API_URL"] = "https://api.hybiscus.dev/api/v1/"
  class Config
    attr_accessor :api_key, :api_url, :timeout, :adapter, :stubs

    DEFAULT_API_URL = "https://api.hybiscus.dev/api/v1/"
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
