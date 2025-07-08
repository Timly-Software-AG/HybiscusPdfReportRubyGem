# frozen_string_literal: true

require "json"
require "base64"
require "pry"

module HybiscusPdfReport
  # Request Handler with the individual endpoints handling the communication with the Hybiscus PDF Reports API
  class Request
    attr_reader :client, :response, :last_request_time_counting_against_rate_limit, :last_task_id, :last_task_status

    def initialize(client)
      @client = client
      @response = nil
    end

    # rubocop: disable Naming/AccessorMethodName
    # method names are inline with the Hybiscus API endpoint names. This is more explicit and easier to understand
    # than following rubocop conventions.
    def build_report(report_request_as_json)
      response_body = request(endpoint: "build-report", http_method: :post, body: report_request_as_json)
      ## HANDLE 402 RESPONSE --> PAYMENT REQUIRED
      update_last_request_information(response_body)

      @response = Response.new(response_body)
    end

    # POST
    def preview_report(report_request_as_json)
      response_body = request(endpoint: "preview-report", http_method: :post, body: report_request_as_json)
      update_last_request_information(response_body)
      Response.new(response_body)
    end

    # GET
    def get_task_status(task_id)
      response_body = request(endpoint: "get-task-status", params: { task_id: task_id })
      # The last task status is stored. If this method is called with the same task_id, the last task status is updated
      # in the instance variable
      @last_task_status = response_body["status"] if last_task_id == task_id
      Response.new(response_body)
    end

    def get_last_task_status
      raise ArgumentError, "No task_id available. Please call build_report or preview_report first." unless last_task_id

      get_task_status(last_task_id)
    end

    def get_report(task_id)
      response_body = request(endpoint: "get-report", http_method: :get, params: { task_id: task_id })
      Response.new(report: Base64.encode64(response_body), status: HybiscusPdfReport::HTTP_OK_CODE)
    end

    def get_last_report
      raise ArgumentError, "No task_id available. Please call build_report or preview_report first." unless last_task_id

      get_report(last_task_id)
    end

    def get_remaining_quota
      response_body = request(endpoint: "get-remaining-quota", http_method: :get)

      Response.new response_body
    end
    # rubocop: enable Naming/AccessorMethodName

    private

    def request(endpoint:, http_method: :get, headers: {}, params: {}, body: {})
      raise "Client not defined" unless defined? @client

      retry_wrapper = RequestRetryWrapper.new(logger: defined?(Rails) ? Rails.logger : nil)

      response_body = retry_wrapper.with_retries do
        @response = client.connection.public_send(http_method, endpoint, params.merge(body), headers)
        raise_error unless response_successful? && no_json_error?

        # Return raw body for binary data (no JSON parsing)
        @response.body
      end

      @last_request = Time.now

      response_body
    end

    def update_last_request_information(response_body)
      @last_request_time_counting_against_rate_limit = Time.now
      @last_task_id = response_body["task_id"]
      @last_task_status = response_body["status"]
    end

    def raise_error
      # logger.debug response.body

      raise error_class(response.status), "Code: #{response.status}, response: #{response.reason_phrase}"
    end

    def error_class(status)
      HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[status] || ApiError
    end

    def response_successful?
      response.status == HTTP_OK_CODE
    end

    def no_json_error?
      response.status != HybiscusPdfReport::UnprocessableContentError
    end

    def pretty_print_json_response
      puts "Response Body:"
      puts JSON.pretty_generate(response.body)
    end
  end
end
