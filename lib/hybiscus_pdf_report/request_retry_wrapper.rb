# frozen_string_literal: true

require "faraday"
require_relative "api_errors"

module HybiscusPdfReport
  # RequestRetryWrapper provides automatic retry logic for transient errors
  # when communicating with the Hybiscus API (e.g., rate limits, timeouts).
  #
  # Usage:
  #   wrapper = HybiscusPdfReport::RequestRetryWrapper.new(max_attempts: 3)
  #   wrapper.with_retries do
  #     api_client.perform_request
  #   end
  #
  # Retries will apply exponential backoff (1s, 2s, 4s, etc.)
  # and will log retry attempts if a logger is provided.
  class RequestRetryWrapper
    DEFAULT_RETRY_ERRORS = [
      RateLimitError,
      Faraday::TimeoutError,
      Faraday::ConnectionFailed
    ].freeze

    def initialize(max_attempts: 5, base_delay: 1, logger: nil)
      @max_attempts = max_attempts
      @base_delay = base_delay
      @logger = logger
    end

    def with_retries
      attempts = 0

      begin
        yield
      rescue *DEFAULT_RETRY_ERRORS => e
        attempts += 1
        handle_retry_or_raise(e, attempts)
        retry
      end
    end

    private

    def handle_retry_or_raise(error, attempts)
      if attempts >= @max_attempts
        log_retry_exhausted(error, attempts)
        raise error
      else
        wait_time = compute_delay(attempts)
        log_retry_attempt(error, attempts, wait_time)
        sleep(wait_time)
      end
    end

    def compute_delay(attempts)
      @base_delay * (2**(attempts - 1))
    end

    def log_retry_attempt(error, attempts, wait_time)
      log("Retry ##{attempts} in #{wait_time}s due to #{error.class}: #{error.message}")
    end

    def log_retry_exhausted(error, attempts)
      log("Retries exhausted after #{attempts} attempts: #{error.class} - #{error.message}")
    end

    def log(message)
      @logger&.warn(message) || puts("[HybiscusRetry] #{message}")
    end
  end
end
