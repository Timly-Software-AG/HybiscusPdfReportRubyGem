# frozen_string_literal: true

require "spec_helper"

RSpec.describe HybiscusPdfReport::Client do
  describe "#initialize" do
    context "with valid API key" do
      it "initializes successfully with API key parameter" do
        client = described_class.new(api_key: "test_key")
        expect(client.api_key).to eq("test_key")
      end

      it "initializes with environment variable" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return("env_key")
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        # Reset the cached config to pick up the mocked ENV variables
        HybiscusPdfReport.instance_variable_set(:@config, nil)

        client = described_class.new
        expect(client.api_key).to eq("env_key")
      end

      it "parameter takes precedence over environment variable" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return("env_key")
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        # Reset the cached config to pick up the mocked ENV variables
        HybiscusPdfReport.instance_variable_set(:@config, nil)

        client = described_class.new(api_key: "param_key")
        expect(client.api_key).to eq("param_key")
      end

      it "strips whitespace from API key" do
        client = described_class.new(api_key: "  test_key  ")
        expect(client.api_key).to eq("test_key")
      end
    end

    context "without API key" do
      it "raises ArgumentError when no API key is provided" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        # Reset the cached config to pick up the mocked ENV variables
        HybiscusPdfReport.instance_variable_set(:@config, nil)

        expect { described_class.new }.to raise_error(ArgumentError, /No API key defined/)
      end

      it "raises ArgumentError when API key is empty string" do
        expect { described_class.new(api_key: "") }.to raise_error(ArgumentError, /No API key defined/)
      end

      it "raises ArgumentError when API key is only whitespace" do
        expect { described_class.new(api_key: "   ") }.to raise_error(ArgumentError, /No API key defined/)
      end
    end

    context "with custom configuration" do
      it "uses custom API URL" do
        client = described_class.new(api_key: "test", api_url: "https://custom.api.url/")
        expect(client.api_url).to eq("https://custom.api.url/")
      end

      it "uses custom timeout" do
        client = described_class.new(api_key: "test", timeout: 30)
        expect(client.instance_variable_get(:@timeout)).to eq(30)
      end

      it "uses custom adapter" do
        client = described_class.new(api_key: "test", adapter: :net_http)
        expect(client.adapter).to eq(:net_http)
      end

      it "uses test stubs when provided" do
        stubs = double("stubs")
        client = described_class.new(api_key: "test", stubs: stubs)
        expect(client.instance_variable_get(:@stubs)).to eq(stubs)
      end
    end

    context "with environment variables" do
      it "uses HYBISCUS_API_URL from environment" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return("test_key")
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return("https://env.api.url/")

        # Reset the cached config to pick up the mocked ENV variables
        HybiscusPdfReport.instance_variable_set(:@config, nil)

        client = described_class.new
        expect(client.api_url).to eq("https://env.api.url/")
      end

      it "falls back to default API URL when not set in environment" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return("test_key")
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        # Reset the cached config to pick up the mocked ENV variables
        HybiscusPdfReport.instance_variable_set(:@config, nil)

        client = described_class.new
        expect(client.api_url).to eq(HybiscusPdfReport::Config::DEFAULT_API_URL)
      end
    end
  end

  describe "#request" do
    let(:client) { described_class.new(api_key: "test_key") }

    it "returns a Request instance" do
      expect(client.request).to be_a(HybiscusPdfReport::Request)
    end

    it "returns the same Request instance on multiple calls" do
      request1 = client.request
      request2 = client.request
      expect(request1).to be(request2)
    end

    it "passes itself to the Request constructor" do
      request = client.request
      expect(request.client).to be(client)
    end
  end

  describe "#connection" do
    let(:client) { described_class.new(api_key: "test_key") }

    it "returns a Faraday connection" do
      expect(client.connection).to be_a(Faraday::Connection)
    end

    it "sets the correct base URL" do
      connection = client.connection
      expect(connection.url_prefix.to_s).to eq(client.api_url)
    end

    it "includes API key header" do
      connection = client.connection
      expect(connection.headers["X-API-KEY"]).to eq("test_key")
    end

    it "allows custom headers" do
      connection = client.connection("Custom-Header" => "custom_value")
      expect(connection.headers["Custom-Header"]).to eq("custom_value")
    end
  end
end
