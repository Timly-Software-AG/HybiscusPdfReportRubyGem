# frozen_string_literal: true

# These errors are automatically raised by the client based on HTTP status codes returned
# by the Hybiscus API. Extend or rescue these as needed in application code.

module HybiscusPdfReport
  class ApiError < StandardError; end

  # 400
  class BadRequestError              < ApiError; end
  # 401
  class UnauthorizedError            < ApiError; end
  # 402
  class PaymentRequiredError         < ApiError; end
  # 403
  class ForbiddenError               < ApiError; end
  # 404
  class NotFoundError                < ApiError; end
  # 422
  class UnprocessableContentError    < ApiError; end
  # 429
  class ApiRequestsQuotaReachedError < ApiError; end
  # 503
  class RateLimitError               < ApiError; end

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
