# frozen_string_literal: true

require "erb"
require "json"
require "pathname"

module HybiscusPdfReport
  # Base class for building PDF reports with JSON templates
  #
  # This class allows users to create custom report builders by inheriting from it.
  # It provides a simple way to generate JSON structures for the Hybiscus API using ERB templates.
  #
  # Template files are automatically named based on your class name with .json.erb extension.
  # For example, InvoiceReport will look for invoice_report.json.erb in the same directory
  # as your class file.
  #
  # Usage:
  #   class InvoiceReport < HybiscusPdfReport::ReportBuilder
  #     def initialize(invoice:, **options)
  #       @invoice = invoice
  #       super(**options)
  #     end
  #   end
  #
  # Custom template name:
  #   class CustomReport < HybiscusPdfReport::ReportBuilder
  #     def template_name
  #       "my_custom_template"  # Will use my_custom_template.json.erb
  #     end
  #   end
  #
  #   report = InvoiceReport.new(invoice: my_invoice)
  #   json_data = report.generate_json
  class ReportBuilder
    def initialize(**template_params)
      # Dynamically set all parameters as instance variables
      template_params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    # Main method to generate the report JSON
    # Returns a JSON string that can be sent to the Hybiscus API
    def generate_json
      generate
    end

    # Use this method to output and analyze the rendered JSON
    def generate_hash
      JSON.parse(generate_json)
    end

    # As default, the template_path is the same as where the main ruby class is located (which inherits from this class)
    # Override this method in subclasses to use a custom template name
    def template_path
      subclass_file = self.class.instance_method(:initialize).source_location&.first
      File.dirname(subclass_file)
    end

    # As default, the template_name is derived from the ruby class name (from which it inherits).
    # Override this method in subclasses to use a custom template name (without .json.erb extension).
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
    def generate
      unless File.exist?(full_template_path)
        raise "Template file not found: #{full_template_path}. " \
              "Create a template file or override the render_json method."
      end

      template_content = File.read(full_template_path)
      template = ERB.new(template_content)

      # Render the template with all instance variables in scope
      template.result(binding)
    end

    def full_template_path
      File.join(template_path, "#{template_name}.json.erb")
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
  end
end
