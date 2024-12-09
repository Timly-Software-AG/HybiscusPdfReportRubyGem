# frozen_string_literal: true

require "faraday"
require_relative "errors"

module HybiscusPdfReport
  # Client handling the Faraday connection to the Hybiscus PDF Reports API
  class Client
    attr_reader :api_key, :hibiskus_api_url, :adapter, :last_request, :email

    BASE_URL_API = "https://api.hybiscus.dev/api/v1/"

    def initialize(api_key: ENV["HIBISCUS_API_KEY"],
                   hibiskus_api_url: ENV["HIBISCUS_API_URL"],
                   timeout: nil,
                   adapter: nil,
                   stubs: nil)
      @api_key            = api_key&.strip
      # default to the main Adnexo production account
      raise ArgumentError, "No API key defined. Check documentation on how to set the API key." if @api_key.nil?

      @hibiskus_api_url   = hibiskus_api_url || BASE_URL_API
      # default to the main Adnexo production account
      @timeout            = timeout
      # param made available for testing purposes: In the rspec tests the following adapter is used: :test
      # https://www.rubydoc.info/gems/faraday/Faraday/Adapter/Test
      @adapter            = adapter || Faraday.default_adapter
      @stubs              = stubs
    end

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
        conn.url_prefix = hibiskus_api_url ## typically the base URL
        conn.request :json
        conn.response :json, content_type: "application/json"
        conn.adapter adapter, @stubs
        conn.headers["X-API-KEY"] = api_key.to_s unless api_key.empty?
        # adds additional header information to the connection
        header.each { |key, value| conn.headers[key] = value }
        conn.options.timeout = @timeout || 10
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
