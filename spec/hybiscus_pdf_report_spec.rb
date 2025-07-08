# frozen_string_literal: true

RSpec.describe HybiscusPdfReport do
  it "has a version number" do
    expect(HybiscusPdfReport::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields the configuration block" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.config)
    end

    it "allows setting configuration options" do
      described_class.configure do |config|
        config.api_key = "test_key"
        config.timeout = 20
      end

      expect(described_class.config.api_key).to eq("test_key")
      expect(described_class.config.timeout).to eq(20)
    end
  end

  describe ".config" do
    it "returns a Config instance" do
      expect(described_class.config).to be_a(HybiscusPdfReport::Config)
    end

    it "returns the same instance on multiple calls" do
      config1 = described_class.config
      config2 = described_class.config
      expect(config1).to be(config2)
    end
  end
end
