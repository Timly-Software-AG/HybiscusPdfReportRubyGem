# frozen_string_literal: true

require "json"
require "base64"
require "pry"

module HybiscusPdfReport
  # Request Handler with the individual endpoints handling the communication with the Hybiscus PDF Reports API
  class Request
    attr_reader :client, :response, :last_request_time_counting_against_rate_limit, :last_task_id, :last_task_status,
                :remaining_single_page_reports, :remaining_multi_page_reports

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
      update_last_request_information

      response = Response.new(response_body.merge(
                                remaining_single_page_reports: @response.headers["x-remaining-single-page-reports"],
                                remaining_multi_page_reports: @response.headers["x-remaining-multi-page-reports"]
                              ))

      update_quota_information(response)
      response
    end

    # POST
    def preview_report(report_request_as_json)
      response_body = request(endpoint: "preview-report", http_method: :post, body: report_request_as_json)
      update_last_request_information
      Response.new(response_body)
    end

    # GET
    def get_task_status(task_id)
      response_body = request(endpoint: "get-task-status", params: { task_id: task_id })
      # The last task status is stored. If this method is called with the same task_id, the last task status is updated
      # in the instance variable
      @last_task_status = response.body["status"] if last_task_id == task_id
      Response.new(response_body)
    end

    def get_last_task_status
      raise ArgumentError, "No task_id available. Please call build_report or preview_report first." unless last_task_id

      get_task_status(last_task_id)
    end

    def get_report(task_id)
      response_body = request(endpoint: "get-report", http_method: :get, params: { task_id: task_id })
      Response.new(report: Base64.encode64(response_body))
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

      @response = client.connection.public_send(http_method, endpoint, params.merge(body), headers)
      raise_error unless response_successful? && no_json_error?

      @last_request = Time.now

      response.body
    end

    def update_last_request_information
      @last_request_time_counting_against_rate_limit = Time.now
      @last_task_id = response.body["task_id"]
      @last_task_status = response.body["status"]
    end

    def update_quota_information(response_object)
      @remaining_single_page_reports = response_object.remaining_single_page_reports
      @remaining_multi_page_reports = response_object.remaining_multi_page_reports
    end

    def raise_error
      pretty_print_json_response

      raise error_class(response.status), "Code: #{response.status}, response: #{response.reason_phrase}"
    end

    # rubocop: disable Metrics/Metrics/MethodLength
    def error_class(status)
      case status
      when HTTP_BAD_REQUEST_CODE
        BadRequestError
      when HTTP_UNAUTHORIZED_CODE
        UnauthorizedError
      when HTTP_NOT_FOUND_CODE, HTTP_FORBIDDEN_CODE
        NotFoundError
      when HTTP_UNPROCESSABLE_ENTITY_CODE
        UnprocessableEntityError
      when HTTP_PAYMENT_REQUIRED_CODE
        PaymentRequiredError
      when HTTP_SERVICE_UNAVAILABLE_CODE
        # Hybiscus API returns 503 when the rate limit is reached
        # https://hybiscus.dev/docs/api/rate-limitting
        RateLimitError
      else
        ApiError
      end
    end
    # rubocop: enable Metrics/Metrics/MethodLength

    def response_successful?
      response.status == HTTP_OK_CODE
    end

    def no_json_error?
      response.status != HTTP_UNPROCESSABLE_CONTENT_CODE
    end

    def pretty_print_json_response
      puts "Response Body:"
      puts JSON.pretty_generate(response.body)
    end
  end
end
