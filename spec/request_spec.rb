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
      expect(response.class).to eq HybiscusPdfReport::Response
      expect(response.task_id).to eq "bdc69c4d-3ba4-4a51-81c1-3c1aab358843"
      expect(response.status).to eq "QUEUED"
      expect(response.remaining_single_page_reports).to eq 20
      expect(response.remaining_multi_page_reports).to eq 10
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
    expect(response.class).to eq HybiscusPdfReport::Response
    expect(response.task_id).to eq "bdc69c4d-3ba4-4a51-81c1-3c1aab358843"
    expect(response.status).to eq "QUEUED"
    expect(client.request.last_task_id).to eq response.task_id
    expect(client.request.last_task_status).to eq response.status
  end

  it "endpoint get-task-status works" do
    stub = stub_request("get-task-status?task_id=1234", response: stub_response(fixture: "get_task_status_success"))

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.get_task_status(1234)
    expect(response.class).to eq HybiscusPdfReport::Response
    expect(response.status).to eq "SUCCESS"
  end

  it "endpoint get-remaining-quota works" do
    stub = stub_request("get-remaining-quota", response: stub_response(fixture: "get_remaining_quota_success"))

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.get_remaining_quota
    expect(response.class).to eq HybiscusPdfReport::Response
    expect(response.remaining_single_page_reports).to eq 95
    expect(response.remaining_multi_page_reports).to eq 100
  end

  it "endpoint get-report works" do
    stub = stub_request("get-report?task_id=1234",
                        response: [200, { "Content-Type" => "image/jpeg" }, pdf_sample])

    client = HybiscusPdfReport::Client.new(api_key: "fake", adapter: :test, stubs: stub)
    response = client.request.get_report(1234)
    expect(response.class).to eq HybiscusPdfReport::Response
    expect(response.status).to eq 200
    expect(response.report).to eq Base64.encode64(pdf_sample)
  end
end
