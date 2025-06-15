# frozen_string_literal: true

require "spec_helper"
require "hybiscus_pdf_report/errors"

RSpec.describe HybiscusPdfReport do
  context "HybiscusPdfReport Errors" do
    it "returns the correct error class for known status codes" do
      expect(described_class::HTTP_ERROR_STATUS_CODES[400]).to eq(described_class::BadRequestError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[401]).to eq(described_class::UnauthorizedError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[402]).to eq(described_class::PaymentRequiredError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[403]).to eq(described_class::ForbiddenError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[404]).to eq(described_class::NotFoundError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[422]).to eq(described_class::UnprocessableContentError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[429]).to eq(described_class::ApiRequestsQuotaReachedError)
      expect(described_class::HTTP_ERROR_STATUS_CODES[503]).to eq(described_class::RateLimitError)
    end
  end
end
