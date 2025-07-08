# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Integration Tests" do
  let(:api_key) { "test_api_key" }
  let(:report_data) do
    {
      template: "invoice",
      data: {
        invoice_number: "INV-001",
        customer: { name: "Test Customer" },
        items: [{ description: "Test Item", amount: 100.0 }]
      }
    }
  end

  describe "complete workflow with stubs" do
    it "successfully completes a full report generation workflow" do
      # Step 1: Build report
      build_stub = stub_request("build-report", method: :post, body: report_data,
                                                response: stub_response(fixture: "build_report_success"))

      client = HybiscusPdfReport::Client.new(api_key: api_key, adapter: :test, stubs: build_stub)
      build_response = client.request.build_report(report_data)

      expect(build_response).to be_a(HybiscusPdfReport::Response)
      expect(build_response.task_id).to eq("bdc69c4d-3ba4-4a51-81c1-3c1aab358843")
      expect(build_response.status).to eq("QUEUED")

      # Verify client state
      expect(client.request.last_task_id).to eq(build_response.task_id)
      expect(client.request.last_task_status).to eq(build_response.status)

      # Step 2: Check task status (simulate completion)
      task_id = build_response.task_id
      status_stub = stub_request("get-task-status?task_id=#{task_id}",
                                 response: stub_response(fixture: "get_task_status_success"))

      client = HybiscusPdfReport::Client.new(api_key: api_key, adapter: :test, stubs: status_stub)
      client.request.instance_variable_set(:@last_task_id, task_id)

      status_response = client.request.get_last_task_status
      expect(status_response.status).to eq("SUCCESS")

      # Step 3: Download report
      pdf_content = "fake_pdf_content"
      report_stub = stub_request("get-report?task_id=#{task_id}",
                                 response: [200, { "Content-Type" => "application/pdf" }, pdf_content])

      client = HybiscusPdfReport::Client.new(api_key: api_key, adapter: :test, stubs: report_stub)
      client.request.instance_variable_set(:@last_task_id, task_id)

      report_response = client.request.get_last_report
      expect(report_response.status).to eq(200)
      expect(report_response.report).to eq(Base64.encode64(pdf_content))
    end
  end

  describe "preview workflow" do
    it "successfully previews a report" do
      preview_stub = stub_request("preview-report", method: :post, body: report_data,
                                                    response: stub_response(fixture: "preview_report_success"))

      client = HybiscusPdfReport::Client.new(api_key: api_key, adapter: :test, stubs: preview_stub)
      preview_response = client.request.preview_report(report_data)

      expect(preview_response).to be_a(HybiscusPdfReport::Response)
      expect(preview_response.task_id).to eq("bdc69c4d-3ba4-4a51-81c1-3c1aab358843")
      expect(preview_response.status).to eq("QUEUED")

      # Verify client state is updated
      expect(client.request.last_task_id).to eq(preview_response.task_id)
      expect(client.request.last_task_status).to eq(preview_response.status)
    end
  end

  describe "quota checking" do
    it "successfully retrieves remaining quota" do
      quota_stub = stub_request("get-remaining-quota",
                                response: stub_response(fixture: "get_remaining_quota_success"))

      client = HybiscusPdfReport::Client.new(api_key: api_key, adapter: :test, stubs: quota_stub)
      quota_response = client.request.get_remaining_quota

      expect(quota_response).to be_a(HybiscusPdfReport::Response)
    end
  end

  describe "error handling integration" do
    it "handles API errors appropriately" do
      error_stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
        path = "#{HybiscusPdfReport.config.api_url}build-report"
        stub_builder.post(path) do
          [401, { "Content-Type" => "application/json" }, { error: "Unauthorized" }.to_json]
        end
      end

      client = HybiscusPdfReport::Client.new(api_key: "invalid_key", adapter: :test, stubs: error_stub)

      expect do
        client.request.build_report(report_data)
      end.to raise_error(HybiscusPdfReport::UnauthorizedError)
    end

    it "retries on rate limit and then succeeds" do
      retry_stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
        path = "#{HybiscusPdfReport.config.api_url}build-report"

        # First call returns rate limit error
        stub_builder.post(path) { raise HybiscusPdfReport::RateLimitError, "Rate limit exceeded" }

        # Second call succeeds
        stub_builder.post(path) { |_env| stub_response(fixture: "build_report_success") }
      end

      client = HybiscusPdfReport::Client.new(api_key: api_key, adapter: :test, stubs: retry_stub)

      # Should not raise error due to retry mechanism
      expect { client.request.build_report(report_data) }.not_to raise_error
    end
  end

  describe "configuration integration" do
    it "works with global configuration" do
      HybiscusPdfReport.configure do |config|
        config.api_key = api_key
        config.timeout = 20
      end

      stub = stub_request("get-remaining-quota",
                          response: stub_response(fixture: "get_remaining_quota_success"))

      client = HybiscusPdfReport::Client.new(adapter: :test, stubs: stub)

      expect(client.api_key).to eq(api_key)
      expect(client.instance_variable_get(:@timeout)).to eq(20)

      response = client.request.get_remaining_quota
      expect(response.remaining_single_page_reports).to eq(95)
    end

    it "parameter configuration overrides global configuration" do
      HybiscusPdfReport.configure do |config|
        config.api_key = "global_key"
        config.timeout = 10
      end

      client = HybiscusPdfReport::Client.new(api_key: "param_key", timeout: 30)

      expect(client.api_key).to eq("param_key")
      expect(client.instance_variable_get(:@timeout)).to eq(30)
    end
  end
end
