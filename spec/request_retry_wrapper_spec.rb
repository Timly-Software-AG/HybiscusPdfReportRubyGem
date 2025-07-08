# frozen_string_literal: true

require "spec_helper"
require "logger"

RSpec.describe HybiscusPdfReport::RequestRetryWrapper do
  let(:logger) { instance_double(Logger) }
  let(:wrapper) { described_class.new(logger: logger) }

  describe "#initialize" do
    it "sets default values" do
      wrapper = described_class.new
      expect(wrapper.instance_variable_get(:@max_attempts)).to eq(5)
      expect(wrapper.instance_variable_get(:@base_delay)).to eq(1)
    end

    it "accepts custom configuration" do
      wrapper = described_class.new(max_attempts: 3, base_delay: 2, logger: logger)
      expect(wrapper.instance_variable_get(:@max_attempts)).to eq(3)
      expect(wrapper.instance_variable_get(:@base_delay)).to eq(2)
      expect(wrapper.instance_variable_get(:@logger)).to eq(logger)
    end
  end

  describe "#with_retries" do
    context "successful execution" do
      it "returns the block result when no error occurs" do
        result = wrapper.with_retries { "success" }
        expect(result).to eq("success")
      end

      it "does not retry when block succeeds" do
        call_count = 0
        wrapper.with_retries { call_count += 1 }
        expect(call_count).to eq(1)
      end
    end

    context "with retryable errors" do
      before do
        allow(logger).to receive(:warn)
      end

      it "retries on RateLimitError" do
        call_count = 0

        expect do
          wrapper.with_retries do
            call_count += 1
            raise HybiscusPdfReport::RateLimitError, "Rate limit exceeded" if call_count < 3

            "success"
          end
        end.not_to raise_error

        expect(call_count).to eq(3)
      end

      it "retries on Faraday::TimeoutError" do
        call_count = 0

        expect do
          wrapper.with_retries do
            call_count += 1
            raise Faraday::TimeoutError, "Timeout" if call_count < 2

            "success"
          end
        end.not_to raise_error

        expect(call_count).to eq(2)
      end

      it "retries on Faraday::ConnectionFailed" do
        call_count = 0

        expect do
          wrapper.with_retries do
            call_count += 1
            raise Faraday::ConnectionFailed, "Connection failed" if call_count < 2

            "success"
          end
        end.not_to raise_error

        expect(call_count).to eq(2)
      end

      it "uses exponential backoff" do
        wrapper = described_class.new(max_attempts: 3, base_delay: 1, logger: logger)
        call_count = 0

        expect(wrapper).to receive(:sleep).with(1).ordered
        expect(wrapper).to receive(:sleep).with(2).ordered

        expect do
          wrapper.with_retries do
            call_count += 1
            raise HybiscusPdfReport::RateLimitError, "Rate limit" if call_count < 4

            "success"
          end
        end.to raise_error(HybiscusPdfReport::RateLimitError)
      end

      it "logs retry attempts" do
        wrapper = described_class.new(max_attempts: 3, base_delay: 1, logger: logger)
        call_count = 0

        expect(logger).to receive(:warn).with(/Retry #1 in 1s due to.*RateLimitError/)
        expect(logger).to receive(:warn).with(/Retry #2 in 2s due to.*RateLimitError/)
        expect(logger).to receive(:warn).with(/Retries exhausted after 3 attempts/)

        allow(wrapper).to receive(:sleep)

        expect do
          wrapper.with_retries do
            call_count += 1
            raise HybiscusPdfReport::RateLimitError, "Rate limit exceeded"
          end
        end.to raise_error(HybiscusPdfReport::RateLimitError)
      end

      it "exhausts retries and raises original error" do
        wrapper = described_class.new(max_attempts: 2, logger: logger)
        call_count = 0

        allow(wrapper).to receive(:sleep)
        allow(logger).to receive(:warn)

        expect do
          wrapper.with_retries do
            call_count += 1
            raise HybiscusPdfReport::RateLimitError, "Persistent error"
          end
        end.to raise_error(HybiscusPdfReport::RateLimitError, "Persistent error")

        expect(call_count).to eq(2)
      end
    end

    context "with non-retryable errors" do
      it "does not retry on other errors" do
        call_count = 0

        expect do
          wrapper.with_retries do
            call_count += 1
            raise HybiscusPdfReport::BadRequestError, "Bad request"
          end
        end.to raise_error(HybiscusPdfReport::BadRequestError)

        expect(call_count).to eq(1)
      end

      it "does not retry on standard errors" do
        call_count = 0

        expect do
          wrapper.with_retries do
            call_count += 1
            raise StandardError, "Standard error"
          end
        end.to raise_error(StandardError)

        expect(call_count).to eq(1)
      end

      it "does not retry on ArgumentError" do
        call_count = 0

        expect do
          wrapper.with_retries do
            call_count += 1
            raise ArgumentError, "Invalid argument"
          end
        end.to raise_error(ArgumentError)

        expect(call_count).to eq(1)
      end
    end

    context "without logger" do
      let(:wrapper) { described_class.new(max_attempts: 2) }

      it "uses puts when no logger is provided" do
        call_count = 0

        expect(wrapper).to receive(:puts).with(/\[HybiscusRetry\] Retry #1/)
        expect(wrapper).to receive(:puts).with(/\[HybiscusRetry\] Retries exhausted/)
        allow(wrapper).to receive(:sleep)

        expect do
          wrapper.with_retries do
            call_count += 1
            raise HybiscusPdfReport::RateLimitError, "Rate limit"
          end
        end.to raise_error(HybiscusPdfReport::RateLimitError)
      end
    end
  end

  describe "private methods" do
    describe "#compute_delay" do
      it "calculates exponential backoff correctly" do
        wrapper = described_class.new(base_delay: 2)

        expect(wrapper.send(:compute_delay, 1)).to eq(2)   # 2 * 2^(1-1) = 2 * 1 = 2
        expect(wrapper.send(:compute_delay, 2)).to eq(4)   # 2 * 2^(2-1) = 2 * 2 = 4
        expect(wrapper.send(:compute_delay, 3)).to eq(8)   # 2 * 2^(3-1) = 2 * 4 = 8
        expect(wrapper.send(:compute_delay, 4)).to eq(16)  # 2 * 2^(4-1) = 2 * 8 = 16
      end
    end
  end

  describe "DEFAULT_RETRY_ERRORS" do
    it "includes the expected error classes" do
      expected_errors = [
        HybiscusPdfReport::RateLimitError,
        Faraday::TimeoutError,
        Faraday::ConnectionFailed
      ]

      expect(described_class::DEFAULT_RETRY_ERRORS).to match_array(expected_errors)
    end
  end
end
