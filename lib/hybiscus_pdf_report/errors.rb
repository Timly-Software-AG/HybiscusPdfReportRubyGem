# frozen_string_literal: true

# Definition of all errors that can be raised by the Hybiscus PDF Reports API
module HybiscusPdfReport
  ApiError = Class.new(StandardError)
  BadRequestError = Class.new(ApiError)
  UnauthorizedError = Class.new(ApiError)
  PaymentRequiredError = Class.new(ApiError)
  ForbiddenError = Class.new(ApiError)
  ApiRequestsQuotaReachedError = Class.new(ApiError)
  NotFoundError = Class.new(ApiError)
  UnprocessableEntityError = Class.new(ApiError)
  RateLimitError = Class.new(ApiError)

  HTTP_OK_CODE                    = 200

  HTTP_BAD_REQUEST_CODE           = 400
  HTTP_UNAUTHORIZED_CODE          = 401
  HTTP_PAYMENT_REQUIRED_CODE      = 402
  HTTP_FORBIDDEN_CODE             = 403
  HTTP_NOT_FOUND_CODE             = 404
  HTTP_UNPROCESSABLE_CONTENT_CODE = 422
  HTTP_UNPROCESSABLE_ENTITY_CODE  = 429
  HTTP_SERVICE_UNAVAILABLE_CODE   = 503
end
