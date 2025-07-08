# frozen_string_literal: true

module TestHelpers
  def create_test_client(api_key: "test_key", stubs: nil, **options)
    HybiscusPdfReport::Client.new(
      api_key: api_key,
      adapter: :test,
      stubs: stubs,
      **options
    )
  end

  def sample_report_data
    {
      template: "invoice",
      data: {
        invoice_number: "INV-001",
        customer: {
          name: "Test Customer",
          address: "123 Test St, Test City, TC 12345"
        },
        items: [
          { description: "Test Item 1", quantity: 2, rate: 50.0 },
          { description: "Test Item 2", quantity: 1, rate: 100.0 }
        ],
        total: 200.0
      }
    }
  end

  def sample_build_report_response
    {
      task_id: "bdc69c4d-3ba4-4a51-81c1-3c1aab358843",
      status: "QUEUED",
      remaining_single_page_reports: 20,
      remaining_multi_page_reports: 10
    }
  end

  def sample_task_status_response
    {
      task_id: "bdc69c4d-3ba4-4a51-81c1-3c1aab358843",
      status: "SUCCESS",
      created_at: "2023-01-01T10:00:00Z",
      completed_at: "2023-01-01T10:05:00Z"
    }
  end

  def sample_quota_response
    {
      remaining_single_page_reports: 95,
      remaining_multi_page_reports: 100
    }
  end

  def create_retry_stub(endpoint, error_class, success_response, attempts: 2)
    Faraday::Adapter::Test::Stubs.new do |stub_builder|
      path = "#{HybiscusPdfReport.config.api_url}#{endpoint}"

      (attempts - 1).times do
        stub_builder.post(path) { raise error_class, "Temporary error" }
      end

      stub_builder.post(path) { |_env| success_response }
    end
  end

  def create_error_stub(endpoint, status_code, error_message = "Error")
    Faraday::Adapter::Test::Stubs.new do |stub_builder|
      path = "#{HybiscusPdfReport.config.api_url}#{endpoint}"
      stub_builder.post(path) do
        [status_code, { "Content-Type" => "application/json" }, { error: error_message }.to_json]
      end
    end
  end

  def expect_no_retries(client, endpoint, error_class, &block)
    call_count = 0

    stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
      path = "#{HybiscusPdfReport.config.api_url}#{endpoint}"
      stub_builder.post(path) do
        call_count += 1
        raise error_class, "Permanent error"
      end
    end

    client.instance_variable_set(:@stubs, stub)

    expect(&block).to raise_error(error_class)
    expect(call_count).to eq(1)
  end

  def expect_retries(client, endpoint, error_class, success_response, expected_attempts: 2, &block)
    call_count = 0

    allow_any_instance_of(HybiscusPdfReport::RequestRetryWrapper).to receive(:sleep)

    stub = Faraday::Adapter::Test::Stubs.new do |stub_builder|
      path = "#{HybiscusPdfReport.config.api_url}#{endpoint}"
      stub_builder.post(path) do
        call_count += 1
        raise error_class, "Temporary error" if call_count < expected_attempts

        success_response
      end
    end

    client.instance_variable_set(:@stubs, stub)

    expect(&block).not_to raise_error
    expect(call_count).to eq(expected_attempts)
  end

  def with_env_vars(vars)
    original_values = {}
    vars.each do |key, value|
      original_values[key] = ENV[key]
      ENV[key] = value
    end

    yield
  ensure
    original_values.each do |key, value|
      ENV[key] = value
    end
  end

  def silence_warnings
    original_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = original_verbose
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
