# frozen_string_literal: true

require "faraday"
require_relative "api_errors"
require_relative "config"

module HybiscusPdfReport
  # HTTP client for the Hybiscus PDF Reports API.
  #
  # This class handles all HTTP communication with the Hybiscus API, including
  # authentication, connection management, and request routing. It uses Faraday
  # for HTTP requests and supports custom adapters for testing.
  #
  # @example Basic usage
  #   client = HybiscusPdfReport::Client.new(api_key: "your_api_key")
  #   response = client.request.build_report(report_data)
  #
  # @example Using environment variables
  #   ENV["HYBISCUS_API_KEY"] = "your_api_key"
  #   client = HybiscusPdfReport::Client.new
  #
  # @example Custom configuration
  #   client = HybiscusPdfReport::Client.new(
  #     api_key: "your_key",
  #     api_url: "https://api.hybiscus.dev/api/v1/",
  #     timeout: 30
  #   )
  class Client
    attr_reader :api_key, :api_url, :adapter, :last_request

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def initialize(api_key: nil, api_url: nil, timeout: nil, adapter: nil, stubs: nil)
      @api_key = (api_key || config.api_key)&.strip
      if @api_key.nil? || @api_key.empty?
        raise ArgumentError,
              "No API key defined. Set it in config or pass to Client.new."
      end

      @api_url = api_url || config.api_url
      @timeout = timeout || config.timeout

      # param made available for testing purposes: In the rspec tests the following adapter is used: :test
      # https://www.rubydoc.info/gems/faraday/Faraday/Adapter/Test
      @adapter = adapter || config.adapter
      @stubs   = stubs || config.stubs
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def request
      @request ||= Request.new(self)
    end

    def connection(header = {})
      @connection ||= build_connection(header)
    end

    private

    # rubocop:disable Metrics/AbcSize
    def build_connection(header)
      Faraday.new do |conn|
        conn.url_prefix = api_url ## typically the base URL
        conn.request :json
        conn.response :json, content_type: "application/json"
        conn.adapter adapter, @stubs
        conn.headers["X-API-KEY"] = api_key unless api_key.nil? || api_key.empty?
        # adds additional header information to the connection

        header.each { |key, value| conn.headers[key] = value }
        conn.options.timeout = @timeout || 10
      end
    end
    # rubocop:enable Metrics/AbcSize

    def config
      @config ||= HybiscusPdfReport.config
    end
  end
end
