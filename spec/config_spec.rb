# frozen_string_literal: true

require "spec_helper"

RSpec.describe HybiscusPdfReport::Config do
  describe "#initialize" do
    context "when environment variables are set" do
      it "sets api_key from HYBISCUS_API_KEY environment variable" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return("env_api_key")
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        config = HybiscusPdfReport::Config.new
        expect(config.api_key).to eq("env_api_key")
      end

      it "sets api_url from HYBISCUS_API_URL environment variable" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return("https://custom.api.url/")

        config = HybiscusPdfReport::Config.new
        expect(config.api_url).to eq("https://custom.api.url/")
      end
    end

    context "when environment variables are not set" do
      it "sets api_key to nil when HYBISCUS_API_KEY is not set" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        config = HybiscusPdfReport::Config.new
        expect(config.api_key).to be_nil
      end

      it "sets api_url to default when HYBISCUS_API_URL is not set" do
        allow(ENV).to receive(:[]).with("HYBISCUS_API_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("HYBISCUS_API_URL").and_return(nil)

        config = HybiscusPdfReport::Config.new
        expect(config.api_url).to eq(HybiscusPdfReport::Config::DEFAULT_API_URL)
      end
    end

    it "sets timeout to default value" do
      config = HybiscusPdfReport::Config.new
      expect(config.timeout).to eq(HybiscusPdfReport::Config::DEFAULT_TIMEOUT)
    end

    it "sets adapter to Faraday default adapter" do
      config = HybiscusPdfReport::Config.new
      expect(config.adapter).to eq(Faraday.default_adapter)
    end

    it "sets stubs to nil" do
      config = HybiscusPdfReport::Config.new
      expect(config.stubs).to be_nil
    end
  end

  describe "constants" do
    it "defines DEFAULT_API_URL" do
      expect(HybiscusPdfReport::Config::DEFAULT_API_URL).to eq("https://api.hybiscus.dev/api/v1/")
    end

    it "defines DEFAULT_TIMEOUT" do
      expect(HybiscusPdfReport::Config::DEFAULT_TIMEOUT).to eq(10)
    end
  end

  describe "attr_accessor" do
    let(:config) { HybiscusPdfReport::Config.new }

    it "allows reading and writing api_key" do
      config.api_key = "new_api_key"
      expect(config.api_key).to eq("new_api_key")
    end

    it "allows reading and writing api_url" do
      config.api_url = "https://new.api.url/"
      expect(config.api_url).to eq("https://new.api.url/")
    end

    it "allows reading and writing timeout" do
      config.timeout = 30
      expect(config.timeout).to eq(30)
    end

    it "allows reading and writing adapter" do
      config.adapter = :test
      expect(config.adapter).to eq(:test)
    end

    it "allows reading and writing stubs" do
      stubs = double("stubs")
      config.stubs = stubs
      expect(config.stubs).to eq(stubs)
    end
  end

  describe ".configure" do
    it "yields the global configuration" do
      expect { |b| HybiscusPdfReport.configure(&b) }.to yield_with_args(HybiscusPdfReport.config)
    end

    it "allows setting configuration through block" do
      HybiscusPdfReport.configure do |c|
        c.api_key = "test_key"
        c.api_url = "https://test.url/"
        c.timeout = 20
      end

      config = HybiscusPdfReport.config
      expect(config.api_key).to eq("test_key")
      expect(config.api_url).to eq("https://test.url/")
      expect(config.timeout).to eq(20)
    end
  end

  describe ".config" do
    it "returns a Config instance" do
      expect(HybiscusPdfReport.config).to be_an_instance_of(HybiscusPdfReport::Config)
    end

    it "returns the same instance on multiple calls (singleton behavior)" do
      config1 = HybiscusPdfReport.config
      config2 = HybiscusPdfReport.config
      expect(config1).to be(config2)
    end

    it "maintains state between calls" do
      HybiscusPdfReport.config.api_key = "persistent_key"
      expect(HybiscusPdfReport.config.api_key).to eq("persistent_key")
    end
  end
end
