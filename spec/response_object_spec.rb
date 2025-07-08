# frozen_string_literal: true

require "spec_helper"

RSpec.describe HybiscusPdfReport::ResponseObject do
  describe "#initialize" do
    it "creates an object with attributes" do
      attributes = { name: "test", value: 123 }
      object = described_class.new(attributes)
      expect(object.instance_variable_get(:@attributes)).to be_a(OpenStruct)
    end

    it "accepts empty hash" do
      object = described_class.new({})
      expect(object.instance_variable_get(:@attributes)).to be_a(OpenStruct)
    end
  end

  describe "dynamic attribute access" do
    let(:attributes) { { name: "test", count: 42, active: true } }
    let(:object) { described_class.new(attributes) }

    it "provides access to attributes as methods" do
      expect(object.name).to eq("test")
      expect(object.count).to eq(42)
      expect(object.active).to be true
    end

    it "returns nil for non-existent attributes" do
      expect(object.non_existent).to be_nil
    end

    it "handles nested hash attributes" do
      nested_object = described_class.new(
        user: { name: "John", age: 30 },
        settings: { theme: "dark" }
      )

      expect(nested_object.user).to be_a(described_class)
      expect(nested_object.user.name).to eq("John")
      expect(nested_object.user.age).to eq(30)
      expect(nested_object.settings.theme).to eq("dark")
    end

    it "handles deeply nested structures" do
      deep_object = described_class.new(
        level1: {
          level2: {
            level3: {
              value: "deep_value"
            }
          }
        }
      )

      expect(deep_object.level1.level2.level3.value).to eq("deep_value")
    end
  end

  describe "#respond_to_missing?" do
    let(:object) { described_class.new(name: "test", count: 42) }

    it "returns true for existing attributes" do
      expect(object.respond_to?(:name)).to be true
      expect(object.respond_to?(:count)).to be true
    end

    it "returns false for non-existent attributes" do
      expect(object.respond_to?(:non_existent)).to be false
    end

    it "delegates to OpenStruct for other methods" do
      expect(object.respond_to?(:to_h)).to be true
    end
  end

  describe "#method_missing" do
    let(:object) { described_class.new(name: "test") }

    it "raises NoMethodError for undefined methods that OpenStruct doesn't handle" do
      expect { object.some_undefined_method("with_arg") }.to raise_error(NoMethodError)
    end

    it "allows calling OpenStruct methods" do
      expect(object.to_h).to eq({ name: "test" })
    end
  end

  describe "edge cases" do
    it "handles nil values" do
      object = described_class.new(nil_value: nil)
      expect(object.nil_value).to be_nil
    end

    it "handles array values" do
      object = described_class.new(items: [1, 2, 3])
      expect(object.items).to eq([1, 2, 3])
    end

    it "handles mixed data types" do
      object = described_class.new(
        string: "text",
        number: 123,
        float: 45.67,
        boolean: true,
        array: [1, 2, 3],
        nested_hash: { nested: "value" }
      )

      expect(object.string).to eq("text")
      expect(object.number).to eq(123)
      expect(object.float).to eq(45.67)
      expect(object.boolean).to be true
      expect(object.array).to eq([1, 2, 3])
      expect(object.nested_hash).to be_a(described_class)
      expect(object.nested_hash.nested).to eq("value")
    end
  end
end
