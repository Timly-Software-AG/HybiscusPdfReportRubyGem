# frozen_string_literal: true

# These errors are automatically raised by the client based on HTTP status codes returned
# by the Hybiscus API. Extend or rescue these as needed in application code.

module HybiscusPdfReport
  # rubocop:disable Style/CommentedKeyword
  # Base error class for all Hybiscus PDF Report API errors.
  class ApiError < StandardError
    attr_reader :response, :status_code, :full_message

    def initialize(message = nil, response: nil, status_code: nil, full_message: nil)
      super(message)
      @response = response
      @status_code = status_code
      @full_message = full_message
    end
  end

  class BadRequestError              < ApiError; end # 400
  class UnauthorizedError            < ApiError; end # 401
  class PaymentRequiredError         < ApiError; end # 402
  class ForbiddenError               < ApiError; end # 403
  class NotFoundError                < ApiError; end # 404
  class UnprocessableContentError    < ApiError; end # 422
  class ApiRequestsQuotaReachedError < ApiError; end # 429
  class RateLimitError               < ApiError; end # 503
  # rubocop:enable Style/CommentedKeyword

  HTTP_ERROR_STATUS_CODES = {
    400 => BadRequestError,
    401 => UnauthorizedError,
    402 => PaymentRequiredError,
    403 => ForbiddenError,
    404 => NotFoundError,
    422 => UnprocessableContentError,
    429 => ApiRequestsQuotaReachedError,
    503 => RateLimitError
  }.freeze

  HTTP_OK_CODE = 200
end
