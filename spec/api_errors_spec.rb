# frozen_string_literal: true

require "spec_helper"

RSpec.describe HybiscusPdfReport do
  describe "API Error Classes" do
    describe "HybiscusPdfReport::ApiError" do
      it "is a subclass of StandardError" do
        expect(HybiscusPdfReport::ApiError.superclass).to eq(StandardError)
      end

      it "can be initialized with just a message" do
        error = HybiscusPdfReport::ApiError.new("Test error")
        expect(error.message).to eq("Test error")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "can be initialized with response and status_code" do
        response = double("response")
        error = HybiscusPdfReport::ApiError.new("Test error", response: response, status_code: 400)

        expect(error.message).to eq("Test error")
        expect(error.response).to eq(response)
        expect(error.status_code).to eq(400)
      end

      it "can be initialized with no message" do
        error = HybiscusPdfReport::ApiError.new
        expect(error.message).to eq("HybiscusPdfReport::ApiError")
      end
    end

    describe "specific error classes" do
      it "BadRequestError inherits from ApiError" do
        expect(HybiscusPdfReport::BadRequestError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "BadRequestError can be instantiated without parameters" do
        error = HybiscusPdfReport::BadRequestError.new
        expect(error.message).to eq("HybiscusPdfReport::BadRequestError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "UnauthorizedError inherits from ApiError" do
        expect(HybiscusPdfReport::UnauthorizedError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "UnauthorizedError can be instantiated without parameters" do
        error = HybiscusPdfReport::UnauthorizedError.new
        expect(error.message).to eq("HybiscusPdfReport::UnauthorizedError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "PaymentRequiredError inherits from ApiError" do
        expect(HybiscusPdfReport::PaymentRequiredError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "PaymentRequiredError can be instantiated without parameters" do
        error = HybiscusPdfReport::PaymentRequiredError.new
        expect(error.message).to eq("HybiscusPdfReport::PaymentRequiredError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "ForbiddenError inherits from ApiError" do
        expect(HybiscusPdfReport::ForbiddenError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "ForbiddenError can be instantiated without parameters" do
        error = HybiscusPdfReport::ForbiddenError.new
        expect(error.message).to eq("HybiscusPdfReport::ForbiddenError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "NotFoundError inherits from ApiError" do
        expect(HybiscusPdfReport::NotFoundError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "NotFoundError can be instantiated without parameters" do
        error = HybiscusPdfReport::NotFoundError.new
        expect(error.message).to eq("HybiscusPdfReport::NotFoundError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "UnprocessableContentError inherits from ApiError" do
        expect(HybiscusPdfReport::UnprocessableContentError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "UnprocessableContentError can be instantiated without parameters" do
        error = HybiscusPdfReport::UnprocessableContentError.new
        expect(error.message).to eq("HybiscusPdfReport::UnprocessableContentError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "ApiRequestsQuotaReachedError inherits from ApiError" do
        expect(HybiscusPdfReport::ApiRequestsQuotaReachedError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "ApiRequestsQuotaReachedError can be instantiated without parameters" do
        error = HybiscusPdfReport::ApiRequestsQuotaReachedError.new
        expect(error.message).to eq("HybiscusPdfReport::ApiRequestsQuotaReachedError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end

      it "RateLimitError inherits from ApiError" do
        expect(HybiscusPdfReport::RateLimitError.superclass).to eq(HybiscusPdfReport::ApiError)
      end

      it "RateLimitError can be instantiated without parameters" do
        error = HybiscusPdfReport::RateLimitError.new
        expect(error.message).to eq("HybiscusPdfReport::RateLimitError")
        expect(error.response).to be_nil
        expect(error.status_code).to be_nil
      end
    end

    describe "HTTP_ERROR_STATUS_CODES mapping" do
      it "returns the correct error class for known status codes" do
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[400]).to eq(HybiscusPdfReport::BadRequestError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[401]).to eq(HybiscusPdfReport::UnauthorizedError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[402]).to eq(HybiscusPdfReport::PaymentRequiredError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[403]).to eq(HybiscusPdfReport::ForbiddenError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[404]).to eq(HybiscusPdfReport::NotFoundError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[422]).to eq(HybiscusPdfReport::UnprocessableContentError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[429]).to eq(HybiscusPdfReport::ApiRequestsQuotaReachedError)
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[503]).to eq(HybiscusPdfReport::RateLimitError)
      end

      it "returns nil for unknown status codes" do
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[500]).to be_nil
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES[999]).to be_nil
      end

      it "includes all expected status codes" do
        expected_codes = [400, 401, 402, 403, 404, 422, 429, 503]
        expect(HybiscusPdfReport::HTTP_ERROR_STATUS_CODES.keys).to match_array(expected_codes)
      end
    end

    describe "HTTP_OK_CODE constant" do
      it "is defined as 200" do
        expect(HybiscusPdfReport::HTTP_OK_CODE).to eq(200)
      end
    end

    describe "error instantiation with all parameters" do
      it "creates errors with full context" do
        response = double("response", body: { error: "Invalid request" })

        error = HybiscusPdfReport::BadRequestError.new(
          "Bad request occurred",
          response: response,
          status_code: 400
        )

        expect(error.message).to eq("Bad request occurred")
        expect(error.response).to eq(response)
        expect(error.status_code).to eq(400)
        expect(error).to be_a(HybiscusPdfReport::ApiError)
      end

      it "allows rescue of specific error types" do
        expect do
          raise HybiscusPdfReport::UnauthorizedError, "Invalid API key"
        end.to raise_error(HybiscusPdfReport::UnauthorizedError, "Invalid API key")
      end

      it "allows rescue of base ApiError" do
        expect do
          raise HybiscusPdfReport::PaymentRequiredError, "Payment required"
        end.to raise_error(HybiscusPdfReport::ApiError, "Payment required")
      end
    end
  end
end
