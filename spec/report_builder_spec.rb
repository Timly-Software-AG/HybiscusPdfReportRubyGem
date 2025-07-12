# frozen_string_literal: true

require "spec_helper"

RSpec.describe HybiscusPdfReport::ReportBuilder do
  describe "#initialize" do
    it "accepts report_name and template_dir parameters" do
      builder = described_class.new(
        report_name: "Test Report",
        template_dir: "/tmp",
        custom_param: "value"
      )

      expect(builder.report_name).to eq("Test Report")
      expect(builder.template_dir).to eq("/tmp")
      expect(builder.instance_variable_get(:@custom_param)).to eq("value")
    end

    it "derives report name from class name if not provided" do
      builder = described_class.new
      expect(builder.report_name).to eq("Report Builder")
    end

    it "uses default template directory if not provided" do
      builder = described_class.new
      expect(builder.template_dir).to eq(File.dirname(__FILE__).gsub("/spec", "/lib/hybiscus_pdf_report"))
    end
  end

  describe "#template_path" do
    it "returns the full path to the template file" do
      builder = described_class.new(template_dir: "/tmp")
      expect(builder.template_path).to eq("/tmp/report_builder.json.erb")
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

  describe "#humanize" do
    it "converts CamelCase to human readable format" do
      builder = described_class.new
      expect(builder.send(:humanize, "CamelCase")).to eq("Camel Case")
      expect(builder.send(:humanize, "XMLParser")).to eq("Xml Parser")
    end
  end

  describe "#generate" do
    context "when template file does not exist" do
      it "raises an error" do
        builder = described_class.new(template_dir: "/nonexistent")
        expect { builder.generate }.to raise_error(/Template file not found/)
      end
    end

    context "when template file exists" do
      let(:template_dir) { Dir.mktmpdir }
      let(:template_file) { File.join(template_dir, "report_builder.json.erb") }

      before do
        File.write(template_file, '{"report": "<%= @report_name %>", "value": <%= @test_value %>}')
      end

      after do
        FileUtils.rm_rf(template_dir)
      end

      it "renders the template with instance variables" do
        builder = described_class.new(
          template_dir: template_dir,
          test_value: 42
        )

        result = builder.generate
        expect(result).to eq('{"report": "Report Builder", "value": 42}')
      end
    end
  end

  describe "custom subclass" do
    let(:invoice_report_class) do
      Class.new(described_class) do
        def initialize(invoice:, **options)
          @invoice = invoice
          super(report_name: "Invoice Report", **options)
        end
      end
    end

    it "works with custom subclasses" do
      invoice = { number: "INV-001", total: 100.50 }
      report = invoice_report_class.new(invoice: invoice, customer: "ACME Corp")

      expect(report.report_name).to eq("Invoice Report")
      expect(report.instance_variable_get(:@invoice)).to eq(invoice)
      expect(report.instance_variable_get(:@customer)).to eq("ACME Corp")
    end

    it "supports custom template base names" do
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
      expect(report.template_path).to end_with("my_custom_template.json.erb")
    end
  end
end
