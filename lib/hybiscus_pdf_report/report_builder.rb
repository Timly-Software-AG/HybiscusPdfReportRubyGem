# frozen_string_literal: true

require "erb"
require "pathname"

module HybiscusPdfReport
  # Base class for building PDF reports with JSON templates
  #
  # This class allows users to create custom report builders by inheriting from it.
  # It provides a simple way to generate JSON structures for the Hybiscus API using ERB templates.
  #
  # Template files are automatically named based on your class name with .json.erb extension.
  # For example, InvoiceReport will look for invoice_report.json.erb
  #
  # Usage:
  #   class InvoiceReport < HybiscusPdfReport::ReportBuilder
  #     def initialize(invoice:, **options)
  #       @invoice = invoice
  #       super(report_name: "Invoice Report", **options)
  #     end
  #   end
  #
  # Custom template name:
  #   class CustomReport < HybiscusPdfReport::ReportBuilder
  #     def template_base_name
  #       "my_custom_template"  # Will use my_custom_template.json.erb
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
      # Use the path of the file where the subclass is defined
      subclass_file = self.class.instance_method(:initialize).source_location&.first
      base_dir = subclass_file ? File.dirname(subclass_file) : template_dir
      File.join(template_dir, "#{template_name}.json.erb")
    end
    
    def template_name
      underscore(class_name)
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
