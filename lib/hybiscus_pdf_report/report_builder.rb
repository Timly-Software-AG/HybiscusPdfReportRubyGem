# frozen_string_literal: true

require "erb"
require "pathname"

module HybiscusPdfReport
  # Base class for building PDF reports with JSON templates
  #
  # This class allows users to create custom report builders by inheriting from it.
  # It provides a simple way to generate JSON structures for the Hybiscus API using ERB templates.
  #
  # Usage:
  #   class InvoiceReport < HybiscusPdfReport::ReportBuilder
  #     def initialize(invoice:, **options)
  #       @invoice = invoice
  #       super(report_name: "Invoice Report", **options)
  #     end
  #   end
  #
  #   report = InvoiceReport.new(invoice: my_invoice)
  #   json_data = report.generate
  class ReportBuilder
    DEFAULT_TEMPLATE_DIR = File.dirname(__FILE__)

    attr_reader :report_name, :template_dir

    def initialize(report_name: nil, template_dir: nil, **template_params)
      # Set the report name - use provided name or derive from class name
      @report_name = report_name || derive_report_name
      @template_dir = template_dir || DEFAULT_TEMPLATE_DIR

      # Dynamically set all parameters as instance variables
      template_params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    # Main method to generate the report JSON
    # Returns a JSON string that can be sent to the Hybiscus API
    def generate
      render_json
    end

    # Returns the full path to the template file
    def template_path
      File.join(template_dir, template_name)
    end

    # Returns the template filename (can be overridden in subclasses)
    def template_name
      "#{underscore(class_name)}.json.erb"
    end

    def load_configuration_first?
      # By default, we assume the report doesn't require pre-loading configuration.
      # This can be overridden in subclasses if configuration loading is needed.
      false
    end

    private

    # Renders the ERB template with all instance variables available
    def render_json
      unless File.exist?(template_path)
        raise "Template file not found: #{template_path}. " \
              "Create a template file or override the render_json method."
      end

      template_content = File.read(template_path)
      template = ERB.new(template_content)

      # Render the template with all instance variables in scope
      template.result(binding)
    end

    # Derives a report name from the class name
    def derive_report_name
      humanize(class_name)
    end

    # Returns the class name without module prefix
    def class_name
      self.class.name.split("::").last
    end

    # Converts CamelCase to snake_case
    def underscore(string)
      string
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    # Converts CamelCase to human readable format
    def humanize(string)
      underscore(string).tr("_", " ").split.map(&:capitalize).join(" ")
    end
  end
end
