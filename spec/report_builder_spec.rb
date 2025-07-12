# frozen_string_literal: true

require "spec_helper"

RSpec.describe HybiscusPdfReport::ReportBuilder do
  describe "#initialize" do
    it "accepts template parameters" do
      builder = described_class.new(
        custom_param: "value"
      )

      expect(builder.instance_variable_get(:@custom_param)).to eq("value")
    end
  end

  describe "#template_name" do
    it "returns the correct template name" do
      builder = described_class.new
      expect(builder.template_name).to eq("report_builder")
    end
  end

  describe "#template_path" do
    it "returns the full path to the template file" do
      builder = described_class.new
      expect(builder.send(:full_template_path)).to end_with("report_builder.json.erb")
      expect(builder.send(:full_template_path)).to include("/lib/hybiscus_pdf_report/")
    end
  end

  describe "#template_name" do
    it "can be overridden in subclasses" do
      subclass = Class.new(described_class) do
        def template_name
          "custom_template"
        end
      end

      builder = subclass.new
      expect(builder.template_name).to eq("custom_template")
      expect(builder.send(:full_template_path)).to end_with("custom_template.json.erb")
    end
  end

  describe "#class_name" do
    it "returns the class name without module prefix" do
      builder = described_class.new
      expect(builder.send(:class_name)).to eq("ReportBuilder")
    end
  end

  describe "#underscore" do
    it "converts CamelCase to snake_case" do
      builder = described_class.new
      expect(builder.send(:underscore, "CamelCase")).to eq("camel_case")
      expect(builder.send(:underscore, "XMLParser")).to eq("xml_parser")
      expect(builder.send(:underscore, "HTMLToXMLConverter")).to eq("html_to_xml_converter")
    end
  end

  describe "#generate_json" do
    context "when template file does not exist" do
      it "raises an error" do
        builder = described_class.new
        expect { builder.generate_json }.to raise_error(/Template file not found/)
      end
    end

    context "when template file exists" do
      let(:template_dir) { Dir.mktmpdir }
      let(:template_file) { File.join(template_dir, "report_builder.json.erb") }

      before do
        File.write(template_file, '{"value": <%= @test_value %>}')

        # Mock the template_path to use our test template
        allow_any_instance_of(described_class).to receive(:template_path).and_return(template_dir)
        allow_any_instance_of(described_class).to receive(:send).with(:full_template_path).and_return(template_file)
        allow_any_instance_of(described_class).to receive(:full_template_path).and_return(template_file)
      end

      after do
        FileUtils.rm_rf(template_dir)
      end

      it "renders the template with instance variables" do
        builder = described_class.new(test_value: 42)

        result = builder.generate_json
        expect(result).to eq('{"value": 42}')
      end
    end
  end

  describe "#generate_hash" do
    let(:template_dir) { Dir.mktmpdir }
    let(:template_file) { File.join(template_dir, "report_builder.json.erb") }

    before do
      File.write(template_file, '{"value": <%= @test_value %>}')
      allow_any_instance_of(described_class).to receive(:full_template_path).and_return(template_file)
    end

    after do
      FileUtils.rm_rf(template_dir)
    end

    it "returns parsed JSON as hash" do
      builder = described_class.new(test_value: 42)
      result = builder.generate_hash
      expect(result).to eq({ "value" => 42 })
    end
  end

  describe "custom subclass" do
    let(:invoice_report_class) do
      Class.new(described_class) do
        def initialize(invoice:, **options)
          @invoice = invoice
          super(**options)
        end

        def self.name
          "InvoiceReport"
        end
      end
    end

    it "works with custom subclasses" do
      invoice = { number: "INV-001", total: 100.50 }
      report = invoice_report_class.new(invoice: invoice, customer: "ACME Corp")

      expect(report.instance_variable_get(:@invoice)).to eq(invoice)
      expect(report.instance_variable_get(:@customer)).to eq("ACME Corp")
      expect(report.template_name).to eq("invoice_report")
    end

    it "supports custom template names" do
      custom_class = Class.new(described_class) do
        def self.name
          "CustomTemplateReport" # Provide a class name for the dynamic class
        end

        def template_name
          "my_custom_template"
        end
      end

      report = custom_class.new
      expect(report.template_name).to eq("my_custom_template")
      expect(report.send(:full_template_path)).to end_with("my_custom_template.json.erb")
    end
  end
end
