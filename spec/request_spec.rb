# frozen_string_literal: true

require "faraday"
require "pry"
require "base64"

RSpec.describe HybiscusPdfReport::Request do
  let(:report_json) { JSON.parse File.read("spec/fixtures/reports/report_json_request.json") }
  let(:pdf_sample) { Base64.encode64 File.open("spec/fixtures/reports/just_a_sample.pdf").read }
  context "endpoint build-report" do
    let(:stub_build_report) do
      stub_request("build-report", method: :post, body: report_json,
                                   response: stub_response(fixture: "build_report_success",
                                                           headers: { "Content-Type" => "application/json",
                                                                      "x-remaining-single-page-reports" => 20,
                                                                      "x-remaining-multi-page-reports" => 10 }))
    end
    it "endpoint build-report works" do
      client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub_build_report)
      response = client.request.build_report(report_json)
      expect(response).to be_a HybiscusPdfReport::Response
      expect(response.task_id).to eq "bdc69c4d-3ba4-4a51-81c1-3c1aab358843"
      expect(response.status).to eq "QUEUED"
    end

    it "updates the last request information" do
      client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub_build_report)
      response = client.request.build_report(report_json)
      expect(client.request.last_task_id).to eq response.task_id
      expect(client.request.last_task_status).to eq response.status
    end
  end

  it "endpoint preview-report works" do
    stub = stub_request("preview-report", method: :post, body: report_json,
                                          response: stub_response(fixture: "preview_report_success"))

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.preview_report(report_json)
    expect(response).to be_a HybiscusPdfReport::Response
    expect(response.task_id).to eq "bdc69c4d-3ba4-4a51-81c1-3c1aab358843"
    expect(response.status).to eq "QUEUED"
    expect(client.request.last_task_id).to eq response.task_id
    expect(client.request.last_task_status).to eq response.status
  end

  it "endpoint get-task-status works" do
    stub = stub_request("get-task-status?task_id=1234", response: stub_response(fixture: "get_task_status_success"))

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.get_task_status(1234)
    expect(response).to be_a(HybiscusPdfReport::Response)
    expect(response.status).to eq "SUCCESS"
  end

  it "endpoint get-remaining-quota works" do
    stub = stub_request("get-remaining-quota", response: stub_response(fixture: "get_remaining_quota_success"))

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.get_remaining_quota
    expect(response).to be_a(HybiscusPdfReport::Response)
    expect(response.remaining_single_page_reports).to eq 95
    expect(response.remaining_multi_page_reports).to eq 100
  end

  it "endpoint get-report works" do
    stub = stub_request("get-report?task_id=1234",
                        response: [200, { "Content-Type" => "image/jpeg" }, pdf_sample])

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.get_report(1234)
    expect(response).to be_a HybiscusPdfReport::Response
    expect(response.status).to eq 200
    expect(response.report).to eq Base64.encode64(pdf_sample)
  end

  it "retries on rate limit error for certain errors" do
    stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
      path = "#{HybiscusPdfReport.config.api_url}build-report"

      # First attempt raises an error
      stub_builder.post(path) { raise HybiscusPdfReport::RateLimitError, "Rate limit hit" }

      # Second attempt succeeds
      stub_builder.post(path) { |_env| stub_response(fixture: "build_report_success") }
    end

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)

    response = client.request.build_report(report_json)
    expect(response.status).to eq("QUEUED")
  end

  it "no retries are done for other errors" do
    stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
      path = "#{HybiscusPdfReport.config.api_url}build-report"

      # First attempt raises an error
      stub_builder.post(path) { raise HybiscusPdfReport::ApiRequestsQuotaReachedError }

      # Second attempt succeeds
      stub_builder.post(path) { |_env| stub_response(fixture: "build_report_success") }
    end

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)

    # no retry is done for an ApiRequestsQuotaReachedError. Hence an error is returned
    # from this request
    expect do
      client.request.build_report(report_json)
    end.to raise_error(HybiscusPdfReport::ApiRequestsQuotaReachedError)
  end

  describe "convenience methods" do
    let(:client) { HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub_get_task_status) }
    let(:stub_get_task_status) do
      stub_request("get-task-status?task_id=test_task_id",
                   response: stub_response(fixture: "get_task_status_success"))
    end

    before do
      # Simulate a previous request that set the task_id
      client.request.instance_variable_set(:@last_task_id, "test_task_id")
    end

    describe "#get_last_task_status" do
      it "uses the last task_id automatically" do
        response = client.request.get_last_task_status
        expect(response.status).to eq("SUCCESS")
      end

      it "raises error when no previous task_id exists" do
        client.request.instance_variable_set(:@last_task_id, nil)

        expect { client.request.get_last_task_status }.to raise_error(
          ArgumentError, "No task_id available. Please call build_report or preview_report first."
        )
      end
    end

    describe "#get_last_report" do
      let(:stub_get_report) do
        stub_request("get-report?task_id=test_task_id",
                     response: [200, { "Content-Type" => "application/pdf" }, "pdf_content"])
      end
      let(:client) { HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub_get_report) }

      it "uses the last task_id automatically" do
        response = client.request.get_last_report
        expect(response.status).to eq(200)
      end

      it "raises error when no previous task_id exists" do
        client.request.instance_variable_set(:@last_task_id, nil)

        expect { client.request.get_last_report }.to raise_error(
          ArgumentError, "No task_id available. Please call build_report or preview_report first."
        )
      end
    end
  end

  describe "request state management" do
    let(:report_json) { JSON.parse File.read("spec/fixtures/reports/report_json_request.json") }
    let(:stub_build_report) do
      stub_request("build-report", method: :post, body: report_json,
                                   response: stub_response(fixture: "build_report_success"))
    end
    let(:client) { HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub_build_report) }

    it "updates last_task_id and last_task_status after build_report" do
      response = client.request.build_report(report_json)

      expect(client.request.last_task_id).to eq(response.task_id)
      expect(client.request.last_task_status).to eq(response.status)
    end

    it "updates last_task_id and last_task_status after preview_report" do
      stub = stub_request("preview-report", method: :post, body: report_json,
                                            response: stub_response(fixture: "preview_report_success"))
      client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)

      response = client.request.preview_report(report_json)

      expect(client.request.last_task_id).to eq(response.task_id)
      expect(client.request.last_task_status).to eq(response.status)
    end
  end

  describe "error scenarios" do
    let(:report_json) { JSON.parse File.read("spec/fixtures/reports/report_json_request.json") }

    it "handles timeout errors through retry wrapper" do
      stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
        path = "#{HybiscusPdfReport.config.api_url}build-report"

        # First attempt times out
        stub_builder.post(path) { raise Faraday::TimeoutError, "Request timeout" }

        # Second attempt succeeds
        stub_builder.post(path) { |_env| stub_response(fixture: "build_report_success") }
      end

      client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)

      expect { client.request.build_report(report_json) }.not_to raise_error
    end

    it "handles connection failed errors through retry wrapper" do
      stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
        path = "#{HybiscusPdfReport.config.api_url}build-report"

        # First attempt fails connection
        stub_builder.post(path) { raise Faraday::ConnectionFailed, "Connection failed" }

        # Second attempt succeeds
        stub_builder.post(path) { |_env| stub_response(fixture: "build_report_success") }
      end

      client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)

      expect { client.request.build_report(report_json) }.not_to raise_error
    end
  end

  describe "attribute readers" do
    let(:client) { HybiscusPdfReport::Client.new(api_key: "fake") }
    let(:request) { client.request }

    it "provides access to client" do
      expect(request.client).to eq(client)
    end

    it "initially has nil response" do
      expect(request.response).to be_nil
    end

    it "initially has nil last_task_id" do
      expect(request.last_task_id).to be_nil
    end

    it "initially has nil last_task_status" do
      expect(request.last_task_status).to be_nil
    end
  end
end
