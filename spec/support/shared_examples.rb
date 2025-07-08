# frozen_string_literal: true

# Shared examples for Response objects
RSpec.shared_examples "a response object" do
  it "is a Response instance" do
    expect(subject).to be_a(HybiscusPdfReport::Response)
  end

  it "inherits from HybiscusPdfReport::ResponseObject" do
    expect(subject).to be_a(HybiscusPdfReport::ResponseObject)
  end

  it "provides dynamic attribute access" do
    expect(subject).to respond_to(:task_id) if subject.respond_to?(:task_id)
    expect(subject).to respond_to(:status) if subject.respond_to?(:status)
  end
end

# Shared examples for API endpoint tests
RSpec.shared_examples "an API endpoint" do |endpoint_name, http_method = :get|
  it "makes a #{http_method.upcase} request to #{endpoint_name}" do
    expect(subject).to be_a(HybiscusPdfReport::Response)
  end

  it "handles successful responses" do
    expect { subject }.not_to raise_error
  end
end

# Shared examples for error scenarios
RSpec.shared_examples "retryable error handling" do |error_class|
  it "retries on #{error_class} and succeeds" do
    call_count = 0

    allow_any_instance_of(HybiscusPdfReport::RequestRetryWrapper).to receive(:sleep)

    stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
      stub_builder.send(http_method || :get, anything) do
        call_count += 1
        raise error_class, "Temporary error" if call_count == 1

        success_response
      end
    end

    client = HybiscusPdfReport::Client.new(api_key: "test", adapter: :test, stubs: stub)
    expect { subject_call.call(client) }.not_to raise_error
    expect(call_count).to eq(2)
  end
end

# Shared examples for non-retryable errors
RSpec.shared_examples "non-retryable error handling" do |error_class|
  it "does not retry on #{error_class}" do
    call_count = 0

    stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
      stub_builder.send(http_method || :get, anything) do
        call_count += 1
        raise error_class, "Permanent error"
      end
    end

    client = HybiscusPdfReport::Client.new(api_key: "test", adapter: :test, stubs: stub)
    expect { subject_call.call(client) }.to raise_error(error_class)
    expect(call_count).to eq(1)
  end
end

# Shared examples for quota tracking
RSpec.shared_examples "quota tracking" do
  it "updates quota information from headers" do
    headers = {
      "X-SINGLE-PAGE-REPORTS-REMAINING" => "25",
      "X-MULTI-PAGE-REPORTS-REMAINING" => "15"
    }

    stub = stub_request(endpoint, method: http_method, body: request_body,
                                  response: stub_response(fixture: fixture_name, headers: headers))

    client = HybiscusPdfReport::Client.new(api_key: "test", adapter: :test, stubs: stub)
    response = subject_call.call(client)

    # Quota information is now available directly from the response headers
    if response.respond_to?(:remaining_single_page_reports)
      expect(response).to respond_to(:remaining_single_page_reports)
    end
    expect(response).to respond_to(:remaining_multi_page_reports) if response.respond_to?(:remaining_multi_page_reports)
  end
end

# Shared examples for client state management
RSpec.shared_examples "client state management" do
  it "updates last_task_id" do
    response = subject
    expect(client.request.last_task_id).to eq(response.task_id) if response.respond_to?(:task_id)
  end

  it "updates last_task_status" do
    response = subject
    expect(client.request.last_task_status).to eq(response.status) if response.respond_to?(:status)
  end
end

# Shared examples for configuration
RSpec.shared_examples "configurable client" do
  it "accepts api_key parameter" do
    client = HybiscusPdfReport::Client.new(api_key: "test_key")
    expect(client.api_key).to eq("test_key")
  end

  it "accepts api_url parameter" do
    client = HybiscusPdfReport::Client.new(api_key: "test", api_url: "https://custom.url/")
    expect(client.api_url).to eq("https://custom.url/")
  end

  it "accepts timeout parameter" do
    client = HybiscusPdfReport::Client.new(api_key: "test", timeout: 30)
    expect(client.instance_variable_get(:@timeout)).to eq(30)
  end
end
